module IOUtils

using JSON
using Logging

"""
    read_file(path::String) -> String

Считывает весь текст из файла по указанному пути.
Если файл не существует или не доступен — выбрасывает ошибку.
"""
function read_file(path::String)::String
    @info("Чтение файла: \$(path)")
    open(path, "r") do io
        return read(io, String)
    end
end

"""
    write_lp_json(path::String, lp_content::String)

Сохраняет сформулированную задачу ЛП в JSON-файл.
Структура:
{
  "lp": <строка-формулировка>
}
"""
function write_lp_json(path::String, lp_content::String)
    @info("Запись LP-формулировки в JSON: \$(path)")
    data = Dict("lp" => lp_content)
    open(path, "w") do io
        JSON.print(io, data)
    end
end

end # module