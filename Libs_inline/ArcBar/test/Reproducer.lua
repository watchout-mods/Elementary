local duration = 2.0;
local width = 20;

local frame = CreateFrame("frame", UIParent);
frame:SetPoint("CENTER", 0, 0)
frame:SetWidth(width);
frame:SetHeight(width * 2);

local tex = frame:CreateTexture();
tex:SetColorTexture(0, 1, 0, .2);
tex:SetAllPoints(frame);

local ag = frame:CreateAnimationGroup();

local rot0 = ag:CreateAnimation("Rotation");
rot0:SetDegrees(45);
rot0:SetDuration(duration);
rot0:SetEndDelay(duration);
rot0:SetOrigin("TOPLEFT", 0, 0);
rot0:HookScript("OnFinished", function(...) ag:Pause(); end);

ag:Play();
