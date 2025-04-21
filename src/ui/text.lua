-- src/ui/text.lua
local Text = {}

-- Text wrapper that handles explicit newlines and width limit
function Text.wrapText(font, text, limit)
    local wrappedLines = {}
    local totalLines = 0
    local space_width = font:getWidth(" ")

    -- Split the input text by explicit newline characters
    for original_line in string.gmatch(text, "[^\n]+") do
        local current_sub_line = ""
        local current_sub_line_width = 0

        -- Apply width wrapping to this specific line segment
        for word in string.gmatch(original_line .. " ", "(%S*)%s") do -- Add space to catch last word
            local word_width = font:getWidth(word)

            -- Handle case where a single word exceeds the limit
            if word_width > limit and current_sub_line_width == 0 then
                 -- Insert the long word on its own line (it will overflow visually)
                 table.insert(wrappedLines, word)
                 totalLines = totalLines + 1
                 -- Reset for next word (although this word already broke the line)
                 current_sub_line = ""
                 current_sub_line_width = 0
            elseif current_sub_line_width == 0 then -- First word on the sub-line
                current_sub_line = word
                current_sub_line_width = word_width
            elseif current_sub_line_width + space_width + word_width <= limit then -- Word fits
                current_sub_line = current_sub_line .. " " .. word
                current_sub_line_width = current_sub_line_width + space_width + word_width
            else -- Word doesn't fit, start new sub-line
                table.insert(wrappedLines, current_sub_line)
                totalLines = totalLines + 1
                current_sub_line = word
                current_sub_line_width = word_width
            end
        end
        -- Add the last sub-line being built for this original line
        if current_sub_line ~= "" then
             table.insert(wrappedLines, current_sub_line)
             totalLines = totalLines + 1
        end
    end

    return table.concat(wrappedLines, "\n"), totalLines
end

return Text
