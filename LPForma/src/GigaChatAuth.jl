module GigaChatAuth

using HTTP
using JSON
using UUIDs
using Logging

"""
function get_access_token(; oauth_url::String, basic_token::String)

Получает OAuth2‑токен доступа из GigaChat.
- oauth_url: URL эндпоинта для получения токена.
- basic_token: значение HTTP Basic Token (из lp.env GIGACHAT_BASIC_TOKEN).

Возвращает строку access_token.
Ошибка, если ответ от сервера не 200 или нет поля "access_token".
"""
function get_access_token(; oauth_url::String, basic_token::String)
    @info("Запрашивается OAuth токен от \$(oauth_url)")

    if isempty(basic_token)
        error("Токен API модели не установлен.")
    end
    
    headers = [
        "Content-Type" => "application/x-www-form-urlencoded",
        "Accept" => "application/json",
        "Authorization" => "Basic $basic_token",
        "RqUID"=> "2080266b-b3e5-4bbb-bf63-efb5cb5fb6c9"
    ]

    body = "scope=GIGACHAT_API_PERS"

    resp = HTTP.request(
        "POST", oauth_url, headers,
        body, require_ssl_verification=false
    )

    if resp.status != 200
        error("OAuth запрос провалился (\$(resp.status)): \$(String(resp.body))")
    end

    data = JSON.parse(String(resp.body))
    if !haskey(data, "access_token")
        error("Отсутствует 'access_token' в ответе OAuth: \$(data)")
    end

    return data["access_token"]
end

end # module
