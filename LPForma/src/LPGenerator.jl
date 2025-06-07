module LPGenerator

using HTTP
using JSON
using Logging

const DEFAULT_API_URL = get(ENV, "GIGACHAT_API_URL",
    "https://gigachat.devices.sberbank.ru/api/v1/chat/completions")

"""
    generate_lp(problem_text::String, base_prompt::String;
                api_url::String, access_token::String)

Отправляет запрос в GigaChat для получения структурированной задачи ЛП.
- problem_text: текст задачи (например, содержимое problem.txt).
- base_prompt: шаблон подсказки (base_prompt.txt), описывающий формат вывода.
- api_url: URL API GigaChat.
- access_token: OAuth токен для авторизации.

Возвращает строку с ответом модели — готовую формулировку ЛП.
"""
function generate_lp(; problem_text::String, base_prompt::String,
                     api_url::String=DEFAULT_API_URL,
                     access_token::String, model::String)
    @info("Генерация ЛП через API GigaChat...")

    if isempty(access_token)
        error("Пустой токен доступа. Вызывающий код должен получить его через GigaChatAuth.get_access_token().")
    end

    prompt = base_prompt * problem_text

    payload = Dict(
        "model" => model,
        "messages" => [Dict("role" => "user", "content" => prompt)],
        "stream" => false,
        "repetition_penalty" => 1
    )

    headers = [
        "Content-Type"  => "application/json",
        "Accept"        => "application/json",
        "Authorization" => "Bearer $access_token"
    ]

    resp = HTTP.request(
        "POST", api_url,
        headers,
        JSON.json(payload),
        require_ssl_verification=false
    )

    if resp.status != 200
        error("Запрос к API провален (\$(resp.status)): \$(String(resp.body))")
    end

    response_data = JSON.parse(String(resp.body))

    content = response_data["choices"][1]["message"]["content"]
    return content
end

end # module