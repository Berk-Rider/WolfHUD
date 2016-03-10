if string.lower(RequiredScript) == "lib/managers/menumanager" then
	function MenuCallbackHandler:is_dlc_latest_locked(check_dlc) return false end
elseif string.lower(RequiredScript) == "lib/managers/menu/blackmarketgui" then 
	-- Show Mod Icons of all Mods in Inventory Boxxes
	local orig_blackmarket_gui_slot_item_select = BlackMarketGuiSlotItem.select
	function BlackMarketGuiSlotItem:select(instant, no_sound)
		self._data.hide_unselected_mini_icons = false
		return orig_blackmarket_gui_slot_item_select(self, instant, no_sound)
	end

	local orig_blackmarket_gui_slot_item_deselect = BlackMarketGuiSlotItem.deselect
	function BlackMarketGuiSlotItem:deselect(instant)
		self._data.hide_unselected_mini_icons = false
		return orig_blackmarket_gui_slot_item_deselect(self, instant)
	end

	-- Remove free Buckshot ammo, if you own Gage Shotty DLC
	local populate_mods_original = BlackMarketGui.populate_mods
	function BlackMarketGui:populate_mods(data, ...)
		if managers.dlc:has_dlc("gage_pack_shotgun") then
			for index, mod_t in ipairs(data.on_create_data) do
				if mod_t[1] == "wpn_fps_upg_a_custom_free"  then
					table.remove(data.on_create_data, index)
					break
				end
			end
		end

		return populate_mods_original(self, data, ...)
	end

	-- Show all Weapon Names in Inventory Boxxes
	local orig_blackmarket_gui_slot_item_init = BlackMarketGuiSlotItem.init
	function BlackMarketGuiSlotItem:init(main_panel, data, x, y, w, h)
		data.custom_name_text = data.custom_name_text or not data.mid_text and data.name_localized
		orig_blackmarket_gui_slot_item_init(self, main_panel, data, x, y, w, h)
	end
elseif string.lower(RequiredScript) == "lib/tweak_data/guitweakdata" then
	local GuiTweakData_init_orig = GuiTweakData.init
	function GuiTweakData:init()
		GuiTweakData_init_orig(self)
		self.rename_max_letters = 30
		self.rename_skill_set_max_letters = 24
	end
elseif string.lower(RequiredScript) == "core/lib/managers/menu/items/coremenuitemslider" then
	core:module("CoreMenuItemSlider")
	core:import("CoreMenuItem")
	local init_actual = ItemSlider.init
	local highlight_row_item_actual = ItemSlider.highlight_row_item
	function ItemSlider:init(data_node, parameters)
		init_actual(self, data_node, parameters)
		self._show_slider_text = true
	end
	
	function ItemSlider:highlight_row_item(node, row_item, mouse_over)
		highlight_row_item_actual(self, node, row_item, mose_over)
		row_item.gui_slider_gfx:set_gradient_points({
		0, _G.tweak_data.screen_colors.button_stage_2:with_alpha(0.6),
		1, _G.tweak_data.screen_colors.button_stage_2:with_alpha(0.6)
	})
		return true
	end
elseif string.lower(RequiredScript) == "lib/states/ingamewaitingforplayers" then
	local update_original = IngameWaitingForPlayersState.update
	function IngameWaitingForPlayersState:update(...)
		update_original(self, ...)
		
		if self._skip_promt_shown and WolfHUD.settings.skip_blackscreen then
			self:_skip()
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/stageendscreengui" then
	local update_original = StageEndScreenGui.update
	local SKIP_STAT_SCREEN_DELAY = WolfHUD.settings.stat_screen_delay
	function StageEndScreenGui:update(t, ...)
		update_original(self, t, ...)
		if not self._button_not_clickable and SKIP_STAT_SCREEN_DELAY >= 0 then
			self._auto_continue_t = self._auto_continue_t or (t + SKIP_STAT_SCREEN_DELAY)
			if t >= self._auto_continue_t then
				managers.menu_component:post_event("menu_enter")
				game_state_machine:current_state()._continue_cb()
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/lootdropscreengui" then
	local SKIP_LOOT_SCREEN_DELAY = WolfHUD.settings.loot_screen_delay
	local update_original = LootDropScreenGui.update
	function LootDropScreenGui:update(t, ...)
		update_original(self, t, ...)

		if not self._card_chosen then
			self:_set_selected_and_sync(math.random(3))
			self:confirm_pressed()
		end
		
		if not self._button_not_clickable and SKIP_LOOT_SCREEN_DELAY >= 0 then
			self._auto_continue_t = self._auto_continue_t or (t + SKIP_LOOT_SCREEN_DELAY)
			if t >= self._auto_continue_t then
				self:continue_to_lobby()
			end
		end
	end
elseif string.lower(RequiredScript) == "lib/managers/menu/renderers/menunodeskillswitchgui" then
	local _create_menu_item=MenuNodeSkillSwitchGui._create_menu_item
	function MenuNodeSkillSwitchGui:_create_menu_item(row_item)
		_create_menu_item(self, row_item)
		if row_item.type~="divider" and row_item.name~="back" then
			local gd=Global.skilltree_manager.skill_switches[row_item.name]
			row_item.status_gui:set_text( managers.localization:to_upper_text( ("menu_st_spec_%d"):format( managers.skilltree:digest_value(gd.specialization, false, 1) or 1 ) ) )
			if row_item.skill_points_gui:text()==managers.localization:to_upper_text("menu_st_points_all_spent_skill_switch") then
				local pts, pt, pp, st, sp=0, 1, 0, 2, 0
				for i=1, #gd.trees do
					pts=Application:digest_value(gd.trees[i].points_spent, false)
					if pts>pp then
						sp, st, pp, pt=pp, pt, pts, i
					elseif pts>sp then
						sp, st=pts, i
					end
				end
				row_item.skill_points_gui:set_text(	managers.localization:to_upper_text( tweak_data.skilltree.trees[pt].name_id	) .." / "..	managers.localization:to_upper_text( tweak_data.skilltree.trees[st].name_id	) )
			end
		end
	end
elseif RequiredScript == "lib/managers/missionassetsmanager" then
	function MissionAssetsManager:mission_has_preplanning()
		return tweak_data.preplanning.locations[Global.game_settings and Global.game_settings.level_id] ~= nil
	end

	function MissionAssetsManager:asset_is_buyable(asset)
		return asset.id ~= "buy_all_assets" and asset.show and not asset.unlocked and ((Network:is_server() and asset.can_unlock) or (Network:is_client() and self:get_asset_can_unlock_by_id(asset.id)))
	end

	local MissionAssetsManager__setup_mission_assets_orig = MissionAssetsManager._setup_mission_assets
	function MissionAssetsManager._setup_mission_assets(self, ...)
		MissionAssetsManager__setup_mission_assets_orig(self, ...)
		if not self:mission_has_preplanning() then
			self:insert_buy_all_assets_asset()
			self:check_all_assets()
		end
	end

	function MissionAssetsManager.update_buy_all_assets_asset_cost(self)
		self._tweak_data.buy_all_assets.money_lock = 0
		for _, asset in ipairs(self._global.assets) do
			if self:asset_is_buyable(asset) then
				self._tweak_data.buy_all_assets.money_lock = self._tweak_data.buy_all_assets.money_lock + (self._tweak_data[asset.id].money_lock or 0)
			end
		end
	end

	function MissionAssetsManager.insert_buy_all_assets_asset(self)
		if not self._tweak_data.gage_assignment then
			return
		end

		self._tweak_data.buy_all_assets = clone(self._tweak_data.gage_assignment)
		self._tweak_data.buy_all_assets.name_id = "menu_buy_all_assets"
		self._tweak_data.buy_all_assets.unlock_desc_id = "menu_buy_all_assets_desc"
		self._tweak_data.buy_all_assets.visible_if_locked = true
		self._tweak_data.buy_all_assets.no_mystery = true
		self:update_buy_all_assets_asset_cost()
		for _, asset in ipairs(self._global.assets) do
			if asset.id == "gage_assignment" then
				self._gage_saved = deep_clone(asset)
				asset.id = "buy_all_assets"
				asset.unlocked = false
				asset.can_unlock = true
				asset.no_mystery = true
				break
			end
		end
		self:check_all_assets()
	end

	function MissionAssetsManager.check_all_assets(self)
		if game_state_machine then
			for _, asset in ipairs(self._global.assets) do
				if self:asset_is_buyable(asset) then
					return
				end
			end
			if not self._all_assets_bought then
				self._tweak_data.buy_all_assets.money_lock = 0
				self._all_assets_bought = true
				MissionAssetsManager_unlock_asset_orig(self, "buy_all_assets")
			end
		end
	end
	local MissionAssetsManager_sync_unlock_asset_orig = MissionAssetsManager.sync_unlock_asset
	function MissionAssetsManager.sync_unlock_asset(self, ...)
		MissionAssetsManager_sync_unlock_asset_orig(self, ...)
		self:update_buy_all_assets_asset_cost()
		self:check_all_assets()
	end

	if not MissionAssetsManager_unlock_asset_orig then MissionAssetsManager_unlock_asset_orig = MissionAssetsManager.unlock_asset end
	function MissionAssetsManager.unlock_asset(self, asset_id)
		if asset_id ~= "buy_all_assets" or not game_state_machine or not self:is_unlock_asset_allowed() then
			return MissionAssetsManager_unlock_asset_orig(self, asset_id)
		end
		for _, asset in ipairs(self._global.assets) do
			if self:asset_is_buyable(asset) then
				MissionAssetsManager_unlock_asset_orig(self, asset.id)
			end
		end
		self:check_all_assets()
	end

	local MissionAssetsManager_sync_save_orig = MissionAssetsManager.sync_save
	function MissionAssetsManager.sync_save(self, data)
		if self:mission_has_preplanning() then
			return MissionAssetsManager_sync_save_orig(self, data)
		end
		local _global = clone(self._global)
		_global.assets = clone(_global.assets)
		for id, asset in ipairs(_global.assets) do
			if asset.id == "buy_all_assets" then
				_global.assets[id] = self._gage_saved
				break
			end
		end
		data.MissionAssetsManager = _global
	end

	local MissionAssetsManager_sync_load_orig = MissionAssetsManager.sync_load
	function MissionAssetsManager.sync_load(self, _ARG_1_, ...)
		if not self:mission_has_preplanning() then
			self._global = _ARG_1_.MissionAssetsManager
			self:insert_buy_all_assets_asset()
			self:check_all_assets()
		end
		MissionAssetsManager_sync_load_orig(self, _ARG_1_, ...)
	end
elseif string.lower(RequiredScript) == "lib/managers/chatmanager" then
	if not WolfHUD.settings.spam_filter then return end
	ChatManager._SUB_TABLE = {
			[utf8.char(57364)] = "<SKULL>",
			[utf8.char(57363)] = "<GHOST>",
			[utf8.char(139)] = "<LC>",
	}

	ChatManager._BLOCK_PATTERNS = {
	  ".- replenished health by .-%%.+",
	  --healed up
	  ".- lost a minion to .+",
	  --lost a minion text
	  ".- converted a .+",
	  --converted cop
	  ".-A .- has less than 10 seconds left.",
	  --drill? old ? r379?
	  ".- was downed",
	  --downed
	  ".- Used Pistol messiah, .-",
	  --pistol messiah
	  ".+ has been downed .+",
	  --downed and needs to patch up
	  ".+ is in custody!",
	  --jail time
	  ".-<PocoHud³ r.-> <SKULL>Crew: .+",
	  --general after heist kills r380+
	  ".-<.-> .- .-<SKULL>.+",
	  --kills and the likes for r380+ users
	  ".-<LC>PocoHud³ r.-  <SKULL>.+",
	  --end game stats r379 users
	  ".-<LC>-- PocoHud³ : More info @ steam group .-pocomods.+",
	  --end game plug
	  ".-A .- is done",
	  --drill is done
	  ".-A .- on a .+ < 10s left",
	  --drill on a thing is nearly done
	  ".-A .- < 10s left",
	  --nearly done drill
	  ".-An .- < 10s left",
	  -- nearly done hacking
	  ".-An .- is done",
	  --hacking things done
	  ".-An .- has been captured .+",
	  --captured a dom 1
	   ".-a .- has been captured .+",
	  --captured a dom 2
	  ".-[NGBTO]:.+"
	  --NGBTO info blocker Should work since its mass spam.
	}

	local _receive_message_original = ChatManager._receive_message

	function ChatManager:_receive_message(channel_id, name, message, ...)
			for key, subst in pairs(ChatManager._SUB_TABLE) do
					message2 = message:gsub(key, subst)
			end

			for _, pattern in ipairs(ChatManager._BLOCK_PATTERNS) do
					if message2:match("^" .. pattern .. "$") then
							return
					end
			end

			return _receive_message_original(self, channel_id, name, message, ...)
	end
elseif string.lower(RequiredScript) == "lib/managers/menumanagerdialogs" then
	local function expect_yes(self, params) params.yes_func() end
	MenuManager.show_confirm_buy_premium_contract = expect_yes
	MenuManager.show_confirm_blackmarket_buy_mask_slot = expect_yes
	MenuManager.show_confirm_blackmarket_buy_weapon_slot = expect_yes
	MenuManager.show_confirm_mission_asset_buy = expect_yes
end