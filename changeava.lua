-- [[ GUI CONFIGURATION ]]
local Library = {}
local SG = game:GetService("StarterGui")
local P = game:GetService("Players")
local LP = P.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Mencegah GUI menumpuk jika di-execute berkali-kali
if CoreGui:FindFirstChild("CloneAvatarGui") then
	CoreGui.CloneAvatarGui:Destroy()
end

-- Membuat UI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local InputField = Instance.new("TextBox")
local ChangeButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local UICorner2 = Instance.new("UICorner")
local UICorner3 = Instance.new("UICorner")

-- Properti UI
ScreenGui.Name = "CloneAvatarGui"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -75)
MainFrame.Size = UDim2.new(0, 200, 0, 150)
MainFrame.Active = true
MainFrame.Draggable = true

UICorner.Parent = MainFrame

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Font = Enum.Font.GothamBold
Title.Text = "CLONE AVATAR"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18

InputField.Name = "InputField"
InputField.Parent = MainFrame
InputField.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
InputField.Position = UDim2.new(0.1, 0, 0.35, 0)
InputField.Size = UDim2.new(0.8, 0, 0, 30)
InputField.Font = Enum.Font.Gotham
InputField.PlaceholderText = "Nama Player/ID"
InputField.Text = ""
InputField.TextColor3 = Color3.fromRGB(255, 255, 255)
InputField.TextSize = 14

UICorner2.Parent = InputField

ChangeButton.Name = "ChangeButton"
ChangeButton.Parent = MainFrame
ChangeButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
ChangeButton.Position = UDim2.new(0.1, 0, 0.65, 0)
ChangeButton.Size = UDim2.new(0.8, 0, 0, 35)
ChangeButton.Font = Enum.Font.GothamBold
ChangeButton.Text = "CHANGE MORPH"
ChangeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ChangeButton.TextSize = 14

UICorner3.Parent = ChangeButton

-- [[ LOGIC INTEGRATION ]]

local function ExecuteMorph(targetName)
	xpcall(function()
		local G = game
		local ENV = getgenv and getgenv() or _G

		local User = targetName .. "," .. LP.Name

		local s = User:split(",")
		local fake = s[1]:match("^%s*(.-)%s*$")
		local victim = s[2] and s[2]:match("^%s*(.-)%s*$") or LP.Name
		local KEY = victim .. "_" .. fake

		if ENV.LAST_MORPH == KEY then return end
		ENV.LAST_MORPH = KEY

		if ENV.MORPH_CONN then
			for _, conn in ENV.MORPH_CONN do pcall(conn.Disconnect, conn) end
		end
		ENV.MORPH_CONN = {}
		ENV.MORPH_DATA = {}

		local fid = tonumber(fake)
		local fn = fid and P:GetNameFromUserIdAsync(fid) or P:GetUserIdFromNameAsync(fake)
		if not fid then fid = P:GetUserIdFromNameAsync(fake) end
		fn = P:GetNameFromUserIdAsync(fid)

		local vp = P:FindFirstChild(LP.Name)
		if not vp then return end

		-- Ambil data deskripsi target dari server SEBELUM mengubah apa pun
		local desc = P:GetHumanoidDescriptionFromUserId(fid)
		local thumb = "rbxthumb://type=Avatar&id=" .. fid .. "&w=420&h=420"

		local d = {}
		d[LP.UserId] = {
			vn = LP.Name,
			dn = LP.DisplayName,
			fn = fn,
			fid = fid,
			vid = LP.UserId,
			desc = desc,
			thumb = thumb
		}
		ENV.MORPH_DATA = d

		local function applyMorph(c, dat)
			task.spawn(function()
				xpcall(function()
					local h = c:WaitForChild("Humanoid", 10)
					if not h then return end

					-- [FIX]: Bersihkan SEMUA sisa avatar asli (Baju, Celana, Aksesoris)
					-- Dilakukan tepat sebelum ApplyDescription agar tidak ada delay telanjang
					for _, v in c:GetDescendants() do
						if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh") or v:IsA("BodyColors") then
							v:Destroy()
						end
					end
					
					-- Menerapkan penampilan target seketika
					if h.ApplyDescriptionClientServer then
						h:ApplyDescriptionClientServer(dat.desc)
					else
						h:ApplyDescription(dat.desc)
					end
					
					h.DisplayName = dat.fn
				end, warn)
			end)
		end

		if vp.Character then applyMorph(vp.Character, d[LP.UserId]) end
		
		local conn = vp.CharacterAdded:Connect(function(c)
			-- Beri sedikit jeda saat baru respawn agar karakter load sepenuhnya
			task.wait(0.5) 
			applyMorph(c, d[LP.UserId])
		end)
		table.insert(ENV.MORPH_CONN, conn)

		SG:SetCore("SendNotification", {
			Title = "Clone Success",
			Text = "Successfully imitated " .. fn,
			Icon = thumb,
			Duration = 5
		})
	end, function(e)
		warn("[CLONE ERROR]: " .. tostring(e))
	end)
end

-- Button Click Event
ChangeButton.MouseButton1Click:Connect(function()
	if InputField.Text ~= "" then
		ExecuteMorph(InputField.Text)
	else
		SG:SetCore("SendNotification", {
			Title = "Error",
			Text = "Masukkan nama player dulu!",
			Duration = 3
		})
	end
end)
