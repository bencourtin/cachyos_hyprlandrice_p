#!/usr/bin/env bash
# ClimaClock.sh — módulo waybar: hora + clima en la barra.
# Backend estilo serpantinum: Open-Meteo (sin API key) + geolocalización por IP
# en cascada (ipapi.co → ip-api.com → ipwho.is). Luna calculada local (awk).
# Salidas:
#   - stdout JSON para waybar (sólo text de barra; sin tooltip)
#   - $CACHE_DIR/state.json  → estructurado, lo consume la isla de quickshell
# Deps: curl + jq + awk
set -u

# --------------------------- CONFIG ---------------------------
CITY_FIXED="Shanghai, China"   # 2ª ciudad del tooltip/isla. "" = desactivar.
UNIT="metric"                  # metric | imperial
GEO_TTL=86400                  # cache de geolocalización (s)
WX_TTL=900                     # cache de clima (s)  — Open-Meteo no tiene rate-limit, igual seamos prolijos
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-clima"
# -----------------------------------------------------------

mkdir -p "$CACHE_DIR"
export LC_TIME="${LC_TIME:-es_CL.UTF-8}"
GEO_F="$CACHE_DIR/geo.json"
GEO_CITY_F="$CACHE_DIR/geo_city.json"
WX_HOME_F="$CACHE_DIR/wx_home.json"
WX_CITY_F="$CACHE_DIR/wx_city.json"
STATE_F="$CACHE_DIR/state.json"

case "$UNIT" in
    imperial) U_T="fahrenheit"; U_W="mph"; SYM="°F"; WUN="mph"  ;;
    *)        U_T="celsius";    U_W="kmh"; SYM="°C"; WUN="km/h" ;;
esac

fresh() { [ -f "$1" ] && [ $(( $(date +%s) - $(stat -c %Y "$1") )) -lt "$2" ]; }
urlenc() { jq -sRr @uri; }

# --refresh : limpia cache de clima y avisa a waybar + isla
if [ "${1:-}" = "--refresh" ]; then
    rm -f "$WX_HOME_F" "$WX_CITY_F"
    pkill -RTMIN+8 waybar 2>/dev/null
    exit 0
fi

# ---------------------- geolocalización IP ----------------------
geo_ipapi() {
    curl -s --max-time 5 -H "User-Agent: rice-clima/1.0" https://ipapi.co/json/ 2>/dev/null \
    | jq -ce 'select((.error|not) and .latitude and .longitude)
        | {lat:.latitude, lon:.longitude, city:(.city//"?"), region:(.region//""),
           country:(.country_name//""), tz:(.timezone//"auto"), src:"ipapi.co"}' 2>/dev/null
}
geo_ipapicom() {
    curl -s --max-time 5 "http://ip-api.com/json/?fields=status,lat,lon,city,regionName,country,timezone" 2>/dev/null \
    | jq -ce 'select(.status=="success")
        | {lat:.lat, lon:.lon, city:(.city//"?"), region:(.regionName//""),
           country:(.country//""), tz:(.timezone//"auto"), src:"ip-api.com"}' 2>/dev/null
}
geo_ipwho() {
    curl -s --max-time 5 https://ipwho.is/ 2>/dev/null \
    | jq -ce 'select(.success==true)
        | {lat:.latitude, lon:.longitude, city:(.city//"?"), region:(.region//""),
           country:(.country//""), tz:(.timezone.id//"auto"), src:"ipwho.is"}' 2>/dev/null
}
get_geo() {
    fresh "$GEO_F" "$GEO_TTL" && return 0
    local r; r="$(geo_ipapi)"; [ -z "$r" ] && r="$(geo_ipapicom)"; [ -z "$r" ] && r="$(geo_ipwho)"
    [ -n "$r" ] && printf '%s\n' "$r" > "$GEO_F"
}

# geocodificar la ciudad fija (Open-Meteo geocoding)
get_geo_city() {
    [ -n "$CITY_FIXED" ] || return 1
    fresh "$GEO_CITY_F" "$GEO_TTL" && return 0
    local name r
    name="$(printf '%s' "${CITY_FIXED%%,*}" | urlenc)"
    r="$(curl -sf --max-time 6 "https://geocoding-api.open-meteo.com/v1/search?name=${name}&count=1&language=es" 2>/dev/null \
        | jq -ce '.results[0] | {lat:.latitude, lon:.longitude, city:.name, region:(.admin1//""),
                  country:(.country//""), tz:(.timezone//"auto"), src:"open-meteo"}' 2>/dev/null)"
    [ -n "$r" ] && printf '%s\n' "$r" > "$GEO_CITY_F"
}

# ---------------------- clima (Open-Meteo) ----------------------
fetch_wx() {  # $1 = geo file, $2 = salida wx file
    local gf="$1" of="$2" lat lon tz url r
    fresh "$of" "$WX_TTL" && return 0
    [ -f "$gf" ] || return 1
    lat=$(jq -r '.lat' "$gf"); lon=$(jq -r '.lon' "$gf"); tz=$(jq -r '.tz // "auto"' "$gf")
    url="https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&timezone=$(printf '%s' "$tz" | urlenc)"
    url="${url}&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day,wind_speed_10m,wind_direction_10m"
    url="${url}&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset&forecast_days=1"
    url="${url}&temperature_unit=${U_T}&wind_speed_unit=${U_W}"
    r="$(curl -sf --max-time 8 "$url" 2>/dev/null)" || return 1
    printf '%s' "$r" | jq -e '.current.temperature_2m' >/dev/null 2>&1 || return 1
    printf '%s\n' "$r" > "$of"
}

get_geo
get_geo_city
fetch_wx "$GEO_F" "$WX_HOME_F" || true
fetch_wx "$GEO_CITY_F" "$WX_CITY_F" || true

# ---------------------- helpers de render ----------------------
esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

# WMO weather_code -> "glifo_NF|desc|hex"   ($2 = 1 día / 0 noche)
wmo() {
    local c="$1" d="${2:-1}" g des hex
    case "$c" in
        0)     if [ "$d" = 1 ]; then g=$''; hex="#f9e2af"; else g=$''; hex="#cba6f7"; fi; des="Despejado" ;;
        1|2)   if [ "$d" = 1 ]; then g=$''; else g=$''; fi; des="Parcial nublado"; hex="#bac2de" ;;
        3)     g=$''; des="Nublado"; hex="#bac2de" ;;
        45|48) g=$''; des="Niebla"; hex="#84afdb" ;;
        51|53|55|56|57|61|63|65|66|67|80|81|82) g=$''; des="Lluvia"; hex="#74c7ec" ;;
        71|73|75|77|85|86)                      g=$''; des="Nieve";  hex="#cdd6f4" ;;
        95|96|99)                               g=$''; des="Tormenta"; hex="#f9e2af" ;;
        *)     g=$''; des="s/d"; hex="#cdd6f4" ;;
    esac
    printf '%s|%s|%s' "$g" "$des" "$hex"
}

hm_to_min() { case "$1" in ""|*[Nn]o*) echo -1; return;; esac; date -d "$1" +%H:%M 2>/dev/null | awk -F: '{print $1*60+$2}'; }

# ---------------------- luna (cálculo local) ----------------------
# imprime: idx illum waxing alt az dir trend   (idx 0-7, illum %, waxing 1/0,
# alt/az en grados, dir compás, trend +1 subiendo / -1 bajando)
moon_local() {
    local lat lon
    lat=$(jq -r '.lat // empty' "$GEO_F" 2>/dev/null); lon=$(jq -r '.lon // empty' "$GEO_F" 2>/dev/null)
    [ -z "$lat" ] && { echo "0 0 1 -99 0 - 0"; return; }
    awk -v LAT="$lat" -v LON="$lon" -v NOW="$(date -u +%s)" '
    function rad(x){return x*0.0174532925199433}
    function deg(x){return x*57.2957795130823}
    function rev(x){x=x-int(x/360)*360; return x<0?x+360:x}
    function sd(x){return sin(rad(x))} function cd(x){return cos(rad(x))}
    function a2d(y,x){return deg(atan2(y,x))}
    function moonstate(now,  d,UT,ws,Ms,Ls,N,i,w,a,e,Mm,E,x,y,r,v,xh,yh,zh,lo,la,ecl,xe,ye,ze,xq,yq,zq,RA,Dec,GMST0,LST,HA,s,alt,az,elong) {
        d = now/86400.0 + 2440587.5 - 2451545.0
        UT = (now%86400)/3600.0
        ws = 282.9404 + 4.70935e-5*d
        Ms = rev(356.0470 + 0.9856002585*d)
        Ls = rev(ws + Ms)
        N  = rev(125.1228 - 0.0529538083*d)
        i  = 5.1454
        w  = rev(318.0634 + 0.1643573223*d)
        a  = 60.2666; e = 0.054900
        Mm = rev(115.3654 + 13.0649929509*d)
        E  = Mm + deg(e)*sd(Mm)*(1+e*cd(Mm))
        E  = E - (E - deg(e)*sd(E) - Mm)/(1 - e*cd(E))
        x = a*(cd(E)-e); y = a*sqrt(1-e*e)*sd(E)
        r = sqrt(x*x+y*y); v = rev(a2d(y,x))
        xh = r*( cd(N)*cd(v+w) - sd(N)*sd(v+w)*cd(i) )
        yh = r*( sd(N)*cd(v+w) + cd(N)*sd(v+w)*cd(i) )
        zh = r*( sd(v+w)*sd(i) )
        lo = rev(a2d(yh,xh))
        la = a2d(zh, sqrt(xh*xh+yh*yh))
        ecl = 23.4393 - 3.563e-7*d
        xe = cd(lo)*cd(la); ye = sd(lo)*cd(la); ze = sd(la)
        xq = xe
        yq = ye*cd(ecl) - ze*sd(ecl)
        zq = ye*sd(ecl) + ze*cd(ecl)
        RA  = rev(a2d(yq,xq))
        Dec = a2d(zq, sqrt(xq*xq+yq*yq))
        GMST0 = rev(Ls + 180)
        LST = rev(GMST0 + UT*15.04107 + LON)
        HA  = rev(LST - RA); if (HA>180) HA-=360
        s = sd(LAT)*sd(Dec) + cd(LAT)*cd(Dec)*cd(HA)
        alt = deg(atan2(s, sqrt(1-s*s)))
        az  = rev( a2d( sd(HA), cd(HA)*sd(LAT) - (sd(Dec)/cd(Dec))*cd(LAT) ) + 180 )
        elong = rev(lo - Ls)
        _alt=alt; _az=az; _elong=elong
    }
    BEGIN{
        split("N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW", D, " ")
        moonstate(NOW);  a1=_alt; az=_az; el=_elong
        moonstate(NOW+1800); a2=_alt
        illum = (1 - cd(el))/2 * 100
        idx = int(el/45 + 0.5) % 8
        wax = (el < 180) ? 1 : 0
        trend = (a2 > a1) ? 1 : -1
        di = int(az/22.5 + 0.5) % 16
        printf "%d %.0f %d %.0f %.0f %s %d\n", idx, illum, wax, a1, az, D[di+1], trend
    }'
}

moon_name() { # idx -> emoji + nombre ES
    case "$1" in
        0) echo "🌑 Luna nueva";; 1) echo "🌒 Creciente iluminante";;
        2) echo "🌓 Cuarto creciente";; 3) echo "🌔 Gibosa creciente";;
        4) echo "🌕 Luna llena";; 5) echo "🌖 Gibosa menguante";;
        6) echo "🌗 Cuarto menguante";; 7) echo "🌘 Creciente menguante";;
        *) echo "🌙 Luna";;
    esac
}

# HOOK eventos del día — cuando tengas calendario, que imprima una línea por evento.
#   gcalcli --nocolor agenda "$(date +%F)" "$(date -d tomorrow +%F)" | sed '1d;/^$/d'
#   khal list today today --format '{start-time}  {title}'
get_events() { return 0; }

# ---------------------- parseo de datos ----------------------
# read_wx <geo file> <wx file> <prefijo>
read_wx() {
    local gf="$1" wf="$2" p="$3" cur='.current' day='.daily'
    [ -f "$wf" ] || return 1
    eval "${p}CITY=\$(jq -r '.city // \"?\"' '$gf' 2>/dev/null)"
    eval "${p}REGION=\$(jq -r '.region // \"\"' '$gf' 2>/dev/null)"
    eval "${p}COUNTRY=\$(jq -r '.country // \"\"' '$gf' 2>/dev/null)"
    eval "${p}TEMP=\$(jq -r '($cur.temperature_2m|round) // empty' '$wf')"
    eval "${p}FEELS=\$(jq -r '($cur.apparent_temperature|round) // empty' '$wf')"
    eval "${p}HUM=\$(jq -r '$cur.relative_humidity_2m // empty' '$wf')"
    eval "${p}WIND=\$(jq -r '($cur.wind_speed_10m|round) // empty' '$wf')"
    eval "${p}WDEG=\$(jq -r '$cur.wind_direction_10m // 0' '$wf')"
    eval "${p}CODE=\$(jq -r '$cur.weather_code // empty' '$wf')"
    eval "${p}ISDAY=\$(jq -r '$cur.is_day // 1' '$wf')"
    eval "${p}MAX=\$(jq -r '($day.temperature_2m_max[0]|round) // empty' '$wf')"
    eval "${p}MIN=\$(jq -r '($day.temperature_2m_min[0]|round) // empty' '$wf')"
    eval "${p}SUNR=\$(jq -r '$day.sunrise[0] // empty' '$wf' | sed 's/.*T//')"
    eval "${p}SUNS=\$(jq -r '$day.sunset[0] // empty' '$wf' | sed 's/.*T//')"
}

deg_to_dir() { awk -v d="${1:-0}" 'BEGIN{split("N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW",A," "); print A[int(d/22.5+0.5)%16+1]}'; }

read_wx "$GEO_F" "$WX_HOME_F" A_ || true
HAVE_CITY=0
[ -n "$CITY_FIXED" ] && read_wx "$GEO_CITY_F" "$WX_CITY_F" C_ && HAVE_CITY=1

read -r MI MILL MWAX MALT MAZ MDIR MTREND <<<"$(moon_local)"
MOON_LABEL="$(moon_name "${MI:-8}")"
MHORIZ="—"; [ "${MALT:-"-99"}" != "-99" ] && { awk "BEGIN{exit !(${MALT:-0} > 0)}" && MHORIZ="sobre el horizonte" || MHORIZ="bajo el horizonte"; }
MTRENDTXT=""; [ "${MTREND:-0}" = "1" ] && MTRENDTXT="subiendo"; [ "${MTREND:-0}" = "-1" ] && MTRENDTXT="bajando"

# ---------------------- texto de barra ----------------------
IFS='|' read -r A_ICON A_DESC A_HEX <<<"$(wmo "${A_CODE:-}" "${A_ISDAY:-1}")"
CLK="$(LC_TIME=C date '+%l:%M %p' | sed 's/^ *//')"
if [ -n "${A_TEMP:-}" ]; then
    TEXT="$(printf ' %s   %s %s°' "$CLK" "$A_ICON" "$A_TEMP")"
    CLASS="clima"
else
    TEXT="$(printf ' %s' "$CLK")"
    CLASS="clima nodata"
fi

# encabezado de fecha en español (lo usa state.json / la isla)
DATE_HDR="$(date '+%A, %d de %B de %Y')"
DATE_HDR="$(printf '%s' "${DATE_HDR:0:1}" | tr '[:lower:]' '[:upper:]')${DATE_HDR:1}"

# ---------------------- state.json (para la isla quickshell) ----------------------
jq -n \
  --arg gen "$(date -Iseconds)" \
  --arg clk "$CLK" \
  --arg date_hdr "$DATE_HDR" \
  --argjson home "$( [ -f "$WX_HOME_F" ] && jq -c '{current, daily}' "$WX_HOME_F" || echo null )" \
  --argjson city "$( [ "$HAVE_CITY" = 1 ] && jq -c '{current, daily}' "$WX_CITY_F" || echo null )" \
  --argjson geo_home "$( [ -f "$GEO_F" ] && cat "$GEO_F" || echo null )" \
  --argjson geo_city "$( [ -f "$GEO_CITY_F" ] && cat "$GEO_CITY_F" || echo null )" \
  --arg home_desc "$A_DESC" --arg home_icon "$A_ICON" --arg home_hex "$A_HEX" \
  --argjson moon "$(jq -n --argjson idx "${MI:-0}" --argjson illum "${MILL:-0}" \
        --argjson wax "${MWAX:-1}" --argjson alt "${MALT:-0}" --argjson az "${MAZ:-0}" \
        --arg dir "${MDIR:-}" --arg horiz "$MHORIZ" --arg trend "$MTRENDTXT" --arg label "$MOON_LABEL" \
        '{idx:$idx, illum:$illum, waxing:($wax==1), alt:$alt, az:$az, dir:$dir, horizon:$horiz, trend:$trend, label:$label}')" \
  --argjson events "$(get_events | jq -R . | jq -s .)" \
  '{generated_at:$gen, clock:$clk, date_header:$date_hdr,
    home:{geo:$geo_home, wx:$home, desc:$home_desc, icon:$home_icon, hex:$home_hex},
    city:{geo:$geo_city, wx:$city},
    moon:$moon, events:$events}' > "$STATE_F" 2>/dev/null || true

# ---------------------- salida waybar (sin tooltip: la info va en la isla) ----------------------
jq -cn --arg t "$TEXT" --arg c "$CLASS" '{text:$t, class:$c}'
