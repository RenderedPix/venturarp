-- Clientside New Life Rule by Tyguy --
net.Receive("startednlr", function(length, client)
chat.AddText(Color(255, 0, 0, 255), "[NLR]", color_white, " New Life Rule has now started, don't go back!")
end )

net.Receive("brokenlr", function(length, client)
local mywarnings = net.ReadString()
local banwarnings = net.ReadString()
chat.AddText(Color(255, 0, 0, 255), "[NLR]", color_white, " You broke New Life Rule! (Warnings ", Color(255, 0, 0, 255), mywarnings, color_white, " out of ", Color(255, 0, 0, 255), banwarnings, color_white, ")")
end )

net.Receive("playerbanned", function(length, client)
local name = net.ReadString()
local warnings = net.ReadString()
chat.AddText(Color(255, 0, 0, 255), "[NLR]", color_white, " Player ", Color(255, 0, 0, 255), name, color_white, " has been banned for breaking new life rule ", Color(255, 0, 0, 255), warnings, color_white, " times!")
end )

net.Receive("endnlr", function(length, client)
chat.AddText(Color(255, 0, 0, 255), "[NLR]", color_white, " New Life Rule is now over!")
end )

net.Receive("nlralreadyon", function(length, client)
chat.AddText(Color(255, 0, 0, 255), "[NLR]", color_white, " New Life Rule is already on, ignoring")
end )

net.Receive("nlrprotectionstart", function(length, client)
chat.AddText(Color(255, 0, 0, 255), "[NLR]", color_white, " Your New Life Rule spawn protection has started!")
end )

net.Receive("nlrprotectionend", function(length, client)
chat.AddText(Color(255, 0, 0, 255), "[NLR]", color_white, " Your New Life Rule spawn protection has ended!")
end )