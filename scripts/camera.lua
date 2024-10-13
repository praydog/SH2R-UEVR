local function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end

local SHCharacterPlayCameraComponent_c = find_required_object("Class /Script/SHProto.SHCharacterPlayCameraComponent")
local SHGameplaySaveMenuWidget_c = find_required_object("Class /Script/SHProto.SHGameplaySaveMenuWidget")
local SHMapRenderer_c = find_required_object("Class /Script/SHProto.SHMapRenderer")
local SHJumpIntoHole_c = find_required_object("Class /Script/SHProto.SHJumpIntoHole")
local SHItemWeaponMelee_c = find_required_object("Class /Script/SHProto.SHItemWeaponMelee")
local SHItemExecutiveBase_c = find_required_object("Class /Script/SHProto.SHItemExecutiveBase")
local SHCameraAnimationExecutive_c = find_required_object("Class /Script/SHProto.SHCameraAnimationExecutive")
--local SHCharAnimationInstance_c = find_required_object("AnimBlueprintGeneratedClass /Game/Game/Characters/Humans/JamesSunderland/Animation/AnimationBlueprints/CH_JamesAnimBP.CH_JamesAnimBP_C")

--local AnimNode_Fabrik = find_required_object("ScriptStruct /Script/AnimGraphRuntime.AnimNode_Fabrik")
--print(string.format("0x%llx", AnimNode_Fabrik:get_class_default_object():get_address()))

local api = uevr.api
local vr = uevr.params.vr

--[[local BlueprintUpdateAnimation = SHCharAnimationInstance_c:find_function("BlueprintUpdateAnimation")

BlueprintUpdateAnimation:hook_ptr(nil, function(fn, obj, locals, result)
    obj.UseWaponIK = false
end)]]

local find_static_class = function(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end

local SHCharacterStatics = find_static_class("Class /Script/SHProto.SHCharacterStatics")
local Statics = find_static_class("Class /Script/Engine.GameplayStatics")

local SHCrosshairWidget_c = find_required_object("Class /Script/SHProto.SHCrosshairWidget")
local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local empty_hitresult = StructObject.new(hitresult_c)
local reusable_hit_result = StructObject.new(hitresult_c)

local function find_camera_component()
    local components = SHCharacterPlayCameraComponent_c:get_objects_matching(false)
    if components == nil or #components == 0 then
        return nil
    end

    for _, component in ipairs(components) do
        if component.OwnerCharacter ~= nil then
            return component
        end
    end

    return nil
end

local function find_save_menu_widget()
    local widgets = SHGameplaySaveMenuWidget_c:get_objects_matching(false)
    if widgets == nil or #widgets == 0 then
        return nil
    end

    for _, widget in ipairs(widgets) do
        if widget.OwnerCharacter ~= nil then
            return widget
        end
    end

    return nil
end

local function is_save_menu_open()
    local widget = find_save_menu_widget()
    if widget == nil then
        return false
    end

    return widget:IsVisible() and widget:IsRendered()
end


local function find_map_renderer()
    local renderers = SHMapRenderer_c:get_objects_matching(false)

    if renderers == nil or #renderers == 0 then
        return nil
    end

    for _, renderer in ipairs(renderers) do
        if renderer.Owner ~= nil then
            return renderer
        end
    end

    return nil
end

local function is_map_open()
    local renderer = find_map_renderer()
    if renderer == nil then
        return false
    end

    return true
end

local function find_jump_into_hole(pawn)
    if pawn == nil then return nil end

    local holes = SHJumpIntoHole_c:get_objects_matching(false)

    if holes == nil or #holes == 0 then
        return nil
    end

    for _, hole in ipairs(holes) do
        local InteractingCharacter = hole.InteractingCharacter
        if InteractingCharacter == pawn then
            return hole
        end
    end

    return nil
end

local function is_jumping_into_hole(pawn)
    local hole = find_jump_into_hole(pawn)
    if hole == nil then
        return false
    end

    return hole:IsInInteraction()
end

local function get_investigating_item(pawn)
    if pawn == nil then return nil end

    local items = pawn.Items
    if items == nil then return nil end

    local item_executive = items.ItemExecutive
    if item_executive == nil then return nil end

    local item_context = item_executive.ItemContext
    if item_context == nil then return nil end

    return item_context
end

local SHFlashlight_c = find_required_object("Class /Script/SHProto.SHFlashlight")

local function get_flashlight(pawn)
    if pawn == nil then return nil end

    local items = pawn.Items
    if items == nil then return nil end

    local equipment_actors = items.EquipmentActors
    if equipment_actors == nil then return nil end
    if #equipment_actors == 0 then return nil end

    for _, actor in ipairs(equipment_actors) do
        if actor:is_a(SHFlashlight_c) then
            return actor
        end
    end

    return nil
end

local function attach_flashlight(pawn, should_detach)
    should_detach = should_detach or false
    local flashlight = get_flashlight(pawn)
    if flashlight == nil then return end

    local mesh = flashlight.Mesh
    if mesh == nil then return end

    if should_detach then
        UEVR_UObjectHook.remove_motion_controller_state(mesh)
    else
        local mesh_state = UEVR_UObjectHook.get_or_add_motion_controller_state(mesh)
        mesh_state:set_hand(0) -- Left hand
        mesh_state:set_permanent(false)
        mesh_state:set_rotation_offset(Vector3f.new(0.175, -1.665, -0.007))
        mesh_state:set_location_offset(Vector3f.new(2.376, 5.972, 0.9))
    end

    local light = flashlight.LightMain
    if light == nil then return end

    if should_detach then
        UEVR_UObjectHook.remove_motion_controller_state(light)
    else
        local light_state = UEVR_UObjectHook.get_or_add_motion_controller_state(light)
        light_state:set_hand(0) -- Left hand
        light_state:set_rotation_offset(Vector3f.new(0.0, -0.130, 0.0))
        light_state:set_permanent(false)
    end

    local light_shaft = flashlight.Lightshaft
    if light_shaft == nil then return end

    if should_detach then
        UEVR_UObjectHook.remove_motion_controller_state(light_shaft)
    else
        local light_shaft_state = UEVR_UObjectHook.get_or_add_motion_controller_state(light_shaft)
        light_shaft_state:set_hand(0) -- Left hand
        light_shaft_state:set_permanent(false)
        light_shaft_state:set_rotation_offset(Vector3f.new(1.527, -1.723, -1.647))
        light_shaft_state:set_location_offset(Vector3f.new(-2.066, -6.140, -5.218))
    end
end

local enqueue_detach_flashlight = false

local function detach_flashlight(pawn)
    --attach_flashlight(pawn, true)
    enqueue_detach_flashlight = true
end

local last_rot = nil
local last_pos = Vector3d.new(0, 0, 0)

local kismet_string_library = find_static_class("Class /Script/Engine.KismetStringLibrary")
local kismet_math_library = find_static_class("Class /Script/Engine.KismetMathLibrary")
local kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")

local head_fname = kismet_string_library:Conv_StringToName("Face")
local root_fname = kismet_string_library:Conv_StringToName("root")
local muzzle_fx_fname = kismet_string_library:Conv_StringToName("FX_muzzle")


local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
local widget_component_c = find_required_object("Class /Script/UMG.WidgetComponent")
local scene_component_c = find_required_object("Class /Script/Engine.SceneComponent")
local actor_c = find_required_object("Class /Script/Engine.Actor")
local ftransform_c = find_required_object("ScriptStruct /Script/CoreUObject.Transform")
local temp_transform = StructObject.new(ftransform_c)

local color_c = find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")
local zero_color = StructObject.new(color_c)

local crosshair_actor = nil
local hmd_actor = nil -- The purpose of the HMD actor is to accurately track the HMD's world transform
local left_hand_actor = nil
local right_hand_actor = nil
local left_hand_component = nil
local right_hand_component = nil
local hmd_component = nil

local LegacyCameraShake_c = find_required_object("Class /Script/GameplayCameras.LegacyCameraShake")

-- Disable camera shake 1
local BlueprintUpdateCameraShake = LegacyCameraShake_c:find_function("BlueprintUpdateCameraShake")

if BlueprintUpdateCameraShake ~= nil then
    BlueprintUpdateCameraShake:set_function_flags(BlueprintUpdateCameraShake:get_function_flags() | 0x400) -- Mark as native
    BlueprintUpdateCameraShake:hook_ptr(function(fn, obj, locals, result)
        obj.ShakeScale = 0.0
        
        return false
    end)
end

-- Disable camera shake 2
local ReceivePlayShake = LegacyCameraShake_c:find_function("ReceivePlayShake")

if ReceivePlayShake ~= nil then
    ReceivePlayShake:set_function_flags(ReceivePlayShake:get_function_flags() | 0x400) -- Mark as native
    ReceivePlayShake:hook_ptr(function(fn, obj, locals, result)
        obj.ShakeScale = 0.0
        return false
    end)
end

local function spawn_actor(world_context, actor_class, location, collision_method, owner)
    temp_transform.Translation = location
    temp_transform.Rotation.W = 1.0
    temp_transform.Scale3D = Vector3d.new(1.0, 1.0, 1.0)

    local actor = Statics:BeginDeferredActorSpawnFromClass(world_context, actor_class, temp_transform, collision_method, owner)

    if actor == nil then
        print("Failed to spawn actor")
        return nil
    end

    Statics:FinishSpawningActor(actor, temp_transform)
    print("Spawned actor")

    return actor
end

local function reset_crosshair_actor()
    if crosshair_actor ~= nil and UEVR_UObjectHook.exists(crosshair_actor) then
        pcall(function() 
            if crosshair_actor.K2_DestroyActor ~= nil then
                crosshair_actor:K2_DestroyActor()
            end
        end)
    end

    crosshair_actor = nil
end

local function reset_crosshair_actor_if_deleted()
    if crosshair_actor ~= nil and not UEVR_UObjectHook.exists(crosshair_actor) then
        crosshair_actor = nil
    end
end

local function setup_crosshair_actor(pawn, crosshair_widget)
    local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)

    local viewport = game_engine.GameViewport
    if viewport == nil then
        print("Viewport is nil")
        return
    end

    local world = viewport.World
    if world == nil then
        print("World is nil")
        return
    end

    reset_crosshair_actor()

    local pos = pawn:K2_GetActorLocation()
    crosshair_actor = spawn_actor(world, actor_c, pos, 1, nil)

    if crosshair_actor == nil then
        print("Failed to spawn actor")
        return
    end

    print("Spawned actor")

    temp_transform.Translation = pos
    temp_transform.Rotation.W = 1.0
    temp_transform.Scale3D = Vector3d.new(1.0, 1.0, 1.0)
    local widget_component = crosshair_actor:AddComponentByClass(widget_component_c, false, temp_transform, false)

    if widget_component == nil then
        print("Failed to add widget component")
        return
    end

    print("Added widget component")

    -- Add crosshair widget to the widget component
    crosshair_widget:RemoveFromViewport()


    --local wanted_mat_name = "Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough"
    local wanted_mat_name = "Material /Engine/EngineMaterials/GizmoMaterial.GizmoMaterial"
    local wanted_mat = api:find_uobject(wanted_mat_name)

    widget_component:SetWidget(crosshair_widget)
    widget_component:SetVisibility(true)
    widget_component:SetHiddenInGame(false)
    widget_component:SetCollisionEnabled(0)

    --crosshair_widget:AddToViewport(0)

    widget_component:SetRenderCustomDepth(true)
    widget_component:SetCustomDepthStencilValue(100)
    widget_component:SetCustomDepthStencilWriteMask(1)
    widget_component:SetRenderInDepthPass(false)

    if wanted_mat then
        wanted_mat.bDisableDepthTest = true
        wanted_mat.BlendMode = 2
        --wanted_mat.MaterialDomain = 0
        --wanted_mat.ShadingModel = 0
        widget_component:SetMaterial(1, wanted_mat)
    end
    
    widget_component.BlendMode = 2

    crosshair_actor:FinishAddComponent(widget_component, false, temp_transform)
    widget_component:SetWidget(crosshair_widget)

    -- Disable depth testing
    --[[widget_component:SetRenderCustomDepth(true)
    widget_component:SetCustomDepthStencilValue(100)
    widget_component:SetCustomDepthStencilWriteMask(1)
    widget_component:SetRenderCustomDepth(true)
    widget_component:SetRenderInDepthPass(false)]]
    --widget_component.BlendMode = 2
    widget_component:SetTwoSided(true)


    print("Widget space: " .. tostring(widget_component.Space))
    print("Widget draw size: X=" .. widget_component.DrawSize.X .. ", Y=" .. widget_component.DrawSize.Y)
    print("Widget visibility: " .. tostring(widget_component:IsVisible()))
end

local function reset_hand_actors()
    -- We are using pcall on this because for some reason the actors are not always valid
    -- even if exists returns true
    if left_hand_actor ~= nil and UEVR_UObjectHook.exists(left_hand_actor) then
        pcall(function()
            if left_hand_actor.K2_DestroyActor ~= nil then
                left_hand_actor:K2_DestroyActor()
            end
        end)
    end

    if right_hand_actor ~= nil and UEVR_UObjectHook.exists(right_hand_actor) then
        pcall(function()
            if right_hand_actor.K2_DestroyActor ~= nil then
                right_hand_actor:K2_DestroyActor()
            end
        end)
    end

    if hmd_actor ~= nil and UEVR_UObjectHook.exists(hmd_actor) then
        pcall(function()
            if hmd_actor.K2_DestroyActor ~= nil then
                hmd_actor:K2_DestroyActor()
            end
        end)
    end

    left_hand_actor = nil
    right_hand_actor = nil
    hmd_actor = nil
end

local function reset_hand_actors_if_deleted()
    if left_hand_actor ~= nil and not UEVR_UObjectHook.exists(left_hand_actor) then
        left_hand_actor = nil
        left_hand_component = nil
    end

    if right_hand_actor ~= nil and not UEVR_UObjectHook.exists(right_hand_actor) then
        right_hand_actor = nil
        right_hand_component = nil
    end

    if hmd_actor ~= nil and not UEVR_UObjectHook.exists(hmd_actor) then
        hmd_actor = nil
        hmd_component = nil
    end
end

local function spawn_hand_actors()
    local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)

    local viewport = game_engine.GameViewport
    if viewport == nil then
        print("Viewport is nil")
        return
    end

    local world = viewport.World
    if world == nil then
        print("World is nil")
        return
    end

    reset_hand_actors()

    local pawn = api:get_local_pawn(0)

    if pawn == nil then
        --print("Pawn is nil")
        return
    end

    local pos = pawn:K2_GetActorLocation()

    left_hand_actor = spawn_actor(world, actor_c, pos, 1, nil)

    if left_hand_actor == nil then
        print("Failed to spawn left hand actor")
        return
    end

    right_hand_actor = spawn_actor(world, actor_c, pos, 1, nil)

    if right_hand_actor == nil then
        print("Failed to spawn right hand actor")
        return
    end

    hmd_actor = spawn_actor(world, actor_c, pos, 1, nil)

    if hmd_actor == nil then
        print("Failed to spawn hmd actor")
        return
    end

    print("Spawned hand actors")

    -- Add scene components to the hand actors
    left_hand_component = left_hand_actor:AddComponentByClass(scene_component_c, false, temp_transform, false)
    right_hand_component = right_hand_actor:AddComponentByClass(scene_component_c, false, temp_transform, false)
    hmd_component = hmd_actor:AddComponentByClass(scene_component_c, false, temp_transform, false)

    if left_hand_component == nil then
        print("Failed to add left hand scene component")
        return
    end

    if right_hand_component == nil then
        print("Failed to add right hand scene component")
        return
    end

    if hmd_component == nil then
        print("Failed to add hmd scene component")
        return
    end

    print("Added scene components")

    left_hand_actor:FinishAddComponent(left_hand_component, false, temp_transform)
    right_hand_actor:FinishAddComponent(right_hand_component, false, temp_transform)
    hmd_actor:FinishAddComponent(hmd_component, false, temp_transform)

    local leftstate = UEVR_UObjectHook.get_or_add_motion_controller_state(left_hand_component)

    if leftstate then
        leftstate:set_hand(0) -- Left hand
        leftstate:set_permanent(true)
    end

    local rightstate = UEVR_UObjectHook.get_or_add_motion_controller_state(right_hand_component)

    if rightstate then
        rightstate:set_hand(1) -- Right hand
        rightstate:set_permanent(true)
    end

    local hmdstate = UEVR_UObjectHook.get_or_add_motion_controller_state(hmd_component)

    if hmdstate then
        hmdstate:set_hand(2) -- HMD
        hmdstate:set_permanent(true)
    end
end

local camera_component = nil
local my_pawn = nil
local is_paused = false
local is_in_cutscene = false
local mesh = nil
local movement_component = nil
local head_pos = nil
local pawn_pos = nil
local anim_instance = nil
local is_in_full_body_anim = false
local last_crosshair_widget = nil
local investigating_item = nil

vr.set_mod_value("VR_RoomscaleMovement", "false")
vr.set_mod_value("VR_AimMethod", 0)

local function should_vr_mode()
    anim_instance = nil
    movement_component = nil
    my_pawn = api:get_local_pawn(0)

    if not my_pawn then
        mesh = nil
        investigating_item = nil

        if last_crosshair_widget then
            last_crosshair_widget:AddToViewport(0)
            last_crosshair_widget = nil
        end

        return false
    end

    mesh = my_pawn.Mesh

    if not mesh then
        return false
    end

    movement_component = my_pawn.Movement
    investigating_item = get_investigating_item(my_pawn)

    if not vr.is_hmd_active() then
        if last_crosshair_widget then
            last_crosshair_widget:AddToViewport(0)
            last_crosshair_widget = nil
        end

        return false
    end

    -- This means we're pushing something
    -- if roomscale movement is on during this it will softlock the game
    if movement_component.PushableComponent then
        return false
    end

    if is_jumping_into_hole(my_pawn) then
        return false
    end

    camera_component = find_camera_component()
    if not camera_component then
        return false
    end

    is_paused = Statics:IsGamePaused(camera_component)

    if is_paused then
        return false
    end

    is_in_cutscene = SHCharacterStatics:IsCharacterInCutscene(my_pawn)

    if is_in_cutscene then
        return false
    end

    local animation = my_pawn.Animation

    if animation then
        anim_instance = animation.AnimInstance

        --[[if anim_instance and anim_instance:IsAnyMontagePlaying() then
            return false
        end]]
    end

    if my_pawn.bHidden == true then return false end

    if is_save_menu_open() then
        return false
    end

    local traversal = my_pawn.Traversal

    -- Like jumping over objects and crawling under stuff
    if traversal and traversal.CurrentlyPlayingTraversal ~= nil then
        return false
    end

    local controller = my_pawn:GetController()

    if controller ~= nil then
        local camera_manager = controller.PlayerCameraManager

        if camera_manager ~= nil then
            local view_target_struct = camera_manager.ViewTarget

            if view_target_struct ~= nil then
                local target = view_target_struct.Target

                if target ~= nil and target ~= my_pawn then
                    local allowed = {
                        SHItemExecutiveBase_c -- Looking at map, items, etc
                    }

                    local any = false

                    for _, klass in ipairs(allowed) do
                        if target:is_a(klass) then
                            any = true
                            break
                        end
                    end

                    if not any then
                        return false
                    end
                end
            end
        end
    end

    return true
end

local is_allowing_vr_mode = false
local last_roomscale_value = false
local forward = nil
local last_delta = 1.0
local last_level = nil

local function on_level_changed(new_level)
    -- All actors can be assumed to be deleted when the level changes
    print("Level changed")
    if new_level then
        print("New level: " .. new_level:get_full_name())
    end
    crosshair_actor = nil
    left_hand_actor = nil
    right_hand_actor = nil
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine_voidptr, delta)
    local engine = game_engine_class:get_first_object_matching(false)
    if not engine then
        return
    end

    local viewport = engine.GameViewport

    if viewport then
        local world = viewport.World

        if world then
            local level = world.PersistentLevel

            if last_level ~= level then
                on_level_changed(level)
            end

            last_level = level
        end
    end

    last_delta = delta
    reset_crosshair_actor_if_deleted()
    reset_hand_actors_if_deleted()

    if left_hand_actor == nil or right_hand_actor == nil then
        spawn_hand_actors()
    end

    if not vr.is_hmd_active() then
        reset_crosshair_actor()
        --reset_hand_actors()
        return
    end

    local pawn = api:get_local_pawn(0)

    if not pawn then
        reset_crosshair_actor()
        return
    end

    local combat = pawn.Combat

    if combat then
        local defence_settings = combat.DefenceSettings

        if defence_settings then
            defence_settings.bDodgeUseViewSnapOnEnemy = false -- Stops dodging from jarringly moving the camera
        end
    end

    local crosshair_widgets = SHCrosshairWidget_c:get_objects_matching(false)

    -- Find first widget that has a valid OwnerCharacter
    local crosshair_widget = nil
    for _, widget in ipairs(crosshair_widgets) do
        if widget.OwnerCharacter ~= nil then
            crosshair_widget = widget
            break
        end
    end

    if crosshair_widget == nil then
        reset_crosshair_actor()
        return
    end

    if crosshair_actor == nil or last_crosshair_widget ~= crosshair_widget then
        setup_crosshair_actor(pawn, crosshair_widget)
    end

    last_crosshair_widget = crosshair_widget
end)

-- Might not be needed?
local function should_display_mesh()
    if not my_pawn or not mesh then
        return false
    end

    if investigating_item ~= nil or is_map_open() then
        return false
    end

    if SHCharacterStatics:IsCharacterInCutscene(my_pawn) == true then
        return true
    end

    if is_save_menu_open() or is_jumping_into_hole(my_pawn) then
        return true
    end

    if my_pawn.Traversal then
        return true
    end

    if my_pawn.Movement and my_pawn.Movement.PushableComponent then
        return true
    end

    if my_pawn.bHidden == true then
        return false
    end

    return false
end

local last_camera_x = 0.0
local last_camera_y = 0.0
local last_head_z = nil
local is_using_two_handed_weapon = false
local is_using_melee_weapon = false
local should_attach_flashlight = true

local item_flip_map = {}

local MAX_LERP_DIST = 500.0

uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
    is_allowing_vr_mode = should_vr_mode()

    if not is_allowing_vr_mode then
        UEVR_UObjectHook.set_disabled(true)
        last_camera_x = position.x
        last_camera_y = position.y
        last_head_z = position.z -- So we dont get weird lerping from across the map when we re-enable VR mode

        if last_roomscale_value == true then
            if my_pawn ~= nil then
                detach_flashlight(my_pawn)
            end

            vr.set_mod_value("VR_RoomscaleMovement", "false")
            vr.set_mod_value("VR_AimMethod", "0")

            if is_save_menu_open() then
                vr.set_mod_value("VR_DecoupledPitch", "false")
            end

            last_roomscale_value = false

            --if mesh and should_display_mesh() then
            if my_pawn and mesh then
                mesh:SetRenderInMainPass(true)
                mesh:SetRenderInDepthPass(true)
                mesh:SetRenderCustomDepth(true)
            end
        end

        return
    end

    if not mesh then
        return
    end

    local back_offset = 0.0
    local using_map = is_map_open()

    UEVR_UObjectHook.set_disabled(false)

    should_attach_flashlight = true

    if investigating_item ~= nil then
        should_attach_flashlight = false
        detach_flashlight(my_pawn)

        mesh:SetRenderInMainPass(false)
        mesh:SetRenderInDepthPass(false)
        mesh:SetRenderCustomDepth(false)

        if using_map then
            -- Realistic two handed map holding
            local right_hand_pos = right_hand_component:K2_GetComponentLocation()
            local left_hand_pos = left_hand_component:K2_GetComponentLocation()
            local dir_to_right_hand = (right_hand_pos - left_hand_pos):normalized()
            local average_hand_up = ((left_hand_component:GetUpVector() + right_hand_component:GetUpVector()) * 0.5):normalized()
            local rotation = kismet_math_library:MakeRotFromXZ(dir_to_right_hand, average_hand_up * -1.0)
            
            local rotation_q = kismet_math_library:Conv_RotatorToQuaternion(rotation)

            local tilt_angle = 45
            local tilt_q = kismet_math_library:Quat_MakeFromEuler(Vector3d.new(tilt_angle, 0, 0))
            rotation_q = kismet_math_library:Multiply_QuatQuat(rotation_q, tilt_q)
            rotation = kismet_math_library:Quat_Rotator(rotation_q)

            investigating_item:K2_SetActorRotation(rotation, false, empty_hitresult, false)
            
            local average_hand_pos = (right_hand_pos + left_hand_pos) * 0.5
            investigating_item:K2_SetActorLocation(average_hand_pos, false, empty_hitresult, false)
        else
            -- Simplistic right handed item holding
            local right_hand_pos = right_hand_component:K2_GetComponentLocation()
            local right_hand_rot = right_hand_component:K2_GetComponentRotation()
            local rotation_q = kismet_math_library:Conv_RotatorToQuaternion(right_hand_rot)
            local tilt_angle = 90
            local flip_angle = 0
            local item_mesh = investigating_item.Mesh

            -- Calculate flip angle
            if item_mesh then
                local anim_script_instance = item_mesh.AnimScriptInstance

                if anim_script_instance then
                    -- First we need to find the ItemFlipCurrentProgress property
                    -- We do this because it has random numbers in the name
                    local c = anim_script_instance:get_class()
                    local caddr = c:get_address()
                    if item_flip_map[caddr] == nil then
                        local parent = c
                        local found = false
                        while parent ~= nil do
                            local prop = parent:get_child_properties()
                            while prop ~= nil do
                                if prop:get_fname():to_string():find("ItemFlipCurrentProgress") then
                                    item_flip_map[caddr] = { result = prop:get_fname():to_string() }
                                    found = true
                                    print("Found flip property: " .. prop:get_fname():to_string())
                                    break
                                end
                                prop = prop:get_next()
                            end
                            
                            if found then break end
                            parent = parent:get_super()
                        end

                        if not found then
                            print("Could not find flip property in class " .. c:get_full_name())
                            item_flip_map[caddr] = { result = nil }
                        end
                    end

                    local flip_prop = item_flip_map[caddr].result

                    if flip_prop ~= nil then
                        local flip_progress = anim_script_instance[flip_prop]
                        if flip_progress then
                            flip_angle = flip_progress * 180
                        end
                    end
                end
            end

            local tilt_q = kismet_math_library:Quat_MakeFromEuler(Vector3d.new(0, flip_angle, tilt_angle))
            rotation_q = kismet_math_library:Multiply_QuatQuat(rotation_q, tilt_q)
            right_hand_rot = kismet_math_library:Quat_Rotator(rotation_q)
            investigating_item:K2_SetActorLocation(right_hand_pos, false, empty_hitresult, false)
            investigating_item:K2_SetActorRotation(right_hand_rot, false, empty_hitresult, false)
        end

        --back_offset = -25.0
        vr.set_mod_value("VR_RoomscaleMovement", "false")
        last_roomscale_value = false
    else
        if last_roomscale_value == false then
            vr.set_mod_value("VR_RoomscaleMovement", "true")
            vr.set_mod_value("VR_DecoupledPitch", "true")
            vr.set_mod_value("VR_AimMethod", "0")
            last_roomscale_value = true
        end

        -- Hide mesh always
        if my_pawn and mesh then
            mesh:SetRenderInMainPass(false)
            mesh:SetRenderInDepthPass(false)
            mesh:SetRenderCustomDepth(false)
        end
    end
    
    local head_rot = mesh:GetSocketRotation(head_fname)
    forward = kismet_math_library:Conv_RotatorToVector(head_rot)
    forward = kismet_math_library:RotateAngleAxis(forward, 90, Vector3d.new(0, 0, 1))

    pawn_pos = my_pawn:K2_GetActorLocation()
    head_pos = mesh:GetSocketLocation(head_fname)
    head_pos.Z = pawn_pos.Z + 60.0
    --[[position.x = head_pos.X + (forward.X * 10)
    position.y = head_pos.Y + (forward.Y * 10)
    position.z = head_pos.Z + (forward.Z * 10)]]
    if not last_head_z then
        last_head_z = head_pos.Z
    end

    local wanted_x = pawn_pos.X + (back_offset * forward.X)
    local wanted_y = pawn_pos.Y + (back_offset * forward.Y)
    local wanted_z = head_pos.Z
    local camera_x = last_camera_x + ((wanted_x - last_camera_x) * (last_delta * 4))
    local camera_y = last_camera_y + ((wanted_y - last_camera_y) * (last_delta * 4))
    local head_z = last_head_z + ((wanted_z - last_head_z) * (last_delta * 2))
    position.x = camera_x
    position.y = camera_y
    position.z = head_z

    if view_index == 1 then
        if math.abs(wanted_x - camera_x) > MAX_LERP_DIST or math.abs(wanted_y - camera_y) > MAX_LERP_DIST then
            last_camera_x = wanted_x
            last_camera_y = wanted_y
        else
            last_camera_x = camera_x
            last_camera_y = camera_y
        end
        
        if math.abs(wanted_z - head_z) > MAX_LERP_DIST then
            last_head_z = wanted_z
        else
            last_head_z = head_z
        end
    end

    if view_index == 1 then
        local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)

        local viewport = game_engine.GameViewport
        if viewport == nil then
            print("Viewport is nil")
            return
        end
    
        local world = viewport.World
        if world == nil then
            print("World is nil")
            return
        end

        -- This is the real game render rotation before any VR modifications
        last_rot = Vector3d.new(rotation.x, rotation.y, rotation.z)
        last_pos = Vector3d.new(position.x, position.y, position.z)

        -- This is where we attach the weapons to the motion controllers
        if anim_instance then
            local equipped_weapon = anim_instance:GetEquippedWeapon()

            if not equipped_weapon then
                is_using_melee_weapon = false
            end

            if equipped_weapon then
                is_using_melee_weapon = equipped_weapon:is_a(SHItemWeaponMelee_c)
                if is_using_melee_weapon then
                    is_using_two_handed_weapon = true
                end

                -- Disables auto aim basically
                if equipped_weapon.AutoAimMaxRange ~= nil then
                    equipped_weapon.AutoAimMaxRange = 1.0
                end

                local weapon_name = equipped_weapon:get_fname():to_string()

                -- Crosshair widget
                if crosshair_actor then
                    local ignore_actors = {my_pawn, equipped_weapon, crosshair_actor}

                    local root = equipped_weapon.RootComponent
                    local fire_point = equipped_weapon.FirePoint
                    local weapon_pos = fire_point:K2_GetComponentLocation()
                    local forward_vector = root:GetForwardVector()

                    if weapon_name:find("Shotgun") or weapon_name:find("Rifle") then
                        -- Rotate forward vector by 90 deg on Z axis
                        forward_vector = kismet_math_library:RotateAngleAxis(forward_vector, 90, root:GetUpVector())
                    end

                    local end_pos = weapon_pos + (forward_vector * 8192.0)
                    local hit = kismet_system_library:LineTraceSingle(world, weapon_pos, end_pos, 15, true, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
                    local hit_location = nil

                    if hit then
                        hit_location = weapon_pos + (forward_vector * (reusable_hit_result.Distance * 0.9))
                    else
                        hit_location = weapon_pos + (forward_vector * 8192.0)
                    end

                    local delta = weapon_pos - hit_location
                    local len = math.max(0.1, delta:length() * 0.001)
                    
                    crosshair_actor:SetActorScale3D(Vector3d.new(len, len, len))

                    local rot = kismet_math_library:Conv_VectorToRotator(forward_vector)
                    rot.Yaw = rot.Yaw + 180
                    rot.Roll = 0
                    rot.Pitch = -rot.Pitch
                    crosshair_actor:K2_SetActorLocationAndRotation(hit_location, rot, false, empty_hitresult, false)
                end

                -- Attach the weapon to the right hand
                local root_component = equipped_weapon.RootComponent

                if root_component then
                    local state = UEVR_UObjectHook.get_or_add_motion_controller_state(root_component)

                    if state then
                        state:set_hand(1) -- Right hand
                        state:set_permanent(true)

                        --print("Equipped weapon: " .. equipped_weapon:get_fname():to_string())
                        local name = equipped_weapon:get_fname():to_string()

                        if name:find("Pistol") then
                            state:set_rotation_offset(Vector3f.new(0.149, 0.084, 0.077))
                            state:set_location_offset(Vector3f.new(-2.982, -10.160, 4.038))
                            is_using_two_handed_weapon = false
                        elseif name:find("Shotgun") then
                            state:set_rotation_offset(Vector3f.new(0.037, 1.556, -0.022)) -- Euler (radians)
                            state:set_location_offset(Vector3f.new(-7.967, -5.752, -0.255))
                            is_using_two_handed_weapon = true
                        elseif name:find("Rifle") then
                            state:set_rotation_offset(Vector3f.new(0.037, 1.556, -0.022)) -- Euler (radians)
                            state:set_location_offset(Vector3f.new(-30.942, -6.758, 0.017))
                            is_using_two_handed_weapon = true
                        --elseif name:find("IronPipe") then
                        elseif is_using_melee_weapon then
                            if name:find("Chainsaw") then
                                state:set_rotation_offset(Vector3f.new(-0.737, -0.090, 0.096))
                                state:set_location_offset(Vector3f.new(0.257, 2.007, 31.583))
                            else
                                state:set_rotation_offset(Vector3f.new(0.495, 1.928, 0.004)) -- Euler (radians)
                                state:set_location_offset(Vector3f.new(-1.444, 30.221, -0.914))
                            end
                            is_using_two_handed_weapon = true -- It's two handed but it's a melee weapon
                        else
                            is_using_two_handed_weapon = not is_using_melee_weapon
                        end
                    end
                end
            end
        end
    end
end)


uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
    if not camera_component then
        return
    end

    if not is_allowing_vr_mode then
        return
    end

    if view_index ~= 1 then
        return
    end

    if hmd_component and last_roomscale_value == true then
        local hmd_pos = hmd_component:K2_GetComponentLocation()
        local hmd_delta = hmd_pos - last_pos

        -- Reset the delta if it's too large
        if hmd_delta:length() > MAX_LERP_DIST then
            hmd_delta = Vector3d.new(0, 0, 0)
        end

        last_camera_x = last_camera_x + hmd_delta.X
        last_camera_y = last_camera_y + hmd_delta.Y
    end


    -- Using the map and some other things
    if anim_instance and anim_instance.bWholeBodyAnimation then
        return
    end

    --local camera_delta_to_head = Vector3d.new(position.x - head_pos.X, position.y - head_pos.Y, position.z - head_pos.Z) - (forward * 10)
    --camera_delta_to_head.z = 0
    --local mesh_pos = mesh:K2_GetComponentLocation()
    --mesh:K2_SetWorldLocation(Vector3d.new(mesh_pos.X + camera_delta_to_head.x, mesh_pos.Y + camera_delta_to_head.y, mesh_pos.Z), false, empty_hitresult, false)
    --mesh:K2_AddWorldOffset(camera_delta_to_head, false, empty_hitresult, false)

    local hmdrot = hmd_component:K2_GetComponentRotation()
    local rotdelta = hmdrot - last_rot
    --local rotdelta = rotation - last_rot

    -- Fix up the rotation delta
    if rotdelta.x > 180 then
        rotdelta.x = rotdelta.x - 360
    elseif rotdelta.x < -180 then
        rotdelta.x = rotdelta.x + 360
    end

    if rotdelta.y > 180 then
        rotdelta.y = rotdelta.y - 360
    elseif rotdelta.y < -180 then
        rotdelta.y = rotdelta.y + 360
    end

    if rotdelta.z > 180 then
        rotdelta.z = rotdelta.z - 360
    elseif rotdelta.z < -180 then
        rotdelta.z = rotdelta.z + 360
    end

    local has_look_operation = false

    local attach_parent = camera_component.AttachParent -- Spring arm
    if attach_parent then
        attach_parent.bEnableCameraRotationLag = false
        attach_parent.bEnableCameraLag = false

        -- View component
        local attach_parent_parent = attach_parent.AttachParent

        if attach_parent_parent then
            attach_parent_parent:SetRotationScale(1.0, nil)

            local operation_events = attach_parent_parent.LookOperation.OperationEvents
            if operation_events ~= nil then
                operation_events.CurrentSettings.bIsSecuredOperation = false -- Dont want this forcing camera control
                attach_parent_parent:ResetLookOperation(nil)
                has_look_operation = true
            else
                -- this is how we make the internal camera aim towards the HMD rotation
                attach_parent_parent:AddToControlRotation(rotdelta, nil)
                vr.recenter_view()
                --attach_parent_parent:OverrideControlRotation(hmdrot, nil)
            end
        end
    end

    if anim_instance then
        local equipped_weapon = anim_instance:GetEquippedWeapon()

        -- Two handed weapon aiming (like rifles and shotguns)
        if equipped_weapon and is_using_two_handed_weapon and anim_instance:IsAimingWeapon() then
            local left_hand_pos = left_hand_component:K2_GetComponentLocation()
            local right_hand_pos = right_hand_component:K2_GetComponentLocation()
            local dir_to_left_hand = (left_hand_pos - right_hand_pos):normalized()
            local right_hand_rotation = right_hand_component:K2_GetComponentRotation()

            local root = equipped_weapon.RootComponent
            local weapon_up_vector = root:GetUpVector()
            local new_direction_rot = kismet_math_library:MakeRotFromXZ(dir_to_left_hand, weapon_up_vector)

            local dir_to_left_hand_q = kismet_math_library:Conv_RotatorToQuaternion(new_direction_rot)
            local right_hand_q = kismet_math_library:Conv_RotatorToQuaternion(right_hand_rotation)

            local delta_q = kismet_math_library:Quat_Inversed(kismet_math_library:Multiply_QuatQuat(right_hand_q, kismet_math_library:Quat_Inversed(dir_to_left_hand_q)))
            
            local original_grip_position = right_hand_pos
            local delta_to_grip = original_grip_position - root:K2_GetComponentLocation()
            local delta_rotated_q = kismet_math_library:Quat_RotateVector(delta_q, delta_to_grip)

            local current_rotation = root:K2_GetComponentRotation()
            local current_rot_q = kismet_math_library:Conv_RotatorToQuaternion(current_rotation)
            local new_rot_q = kismet_math_library:Multiply_QuatQuat(delta_q, current_rot_q)

            current_rotation = kismet_math_library:Quat_Rotator(new_rot_q)
            root:K2_SetWorldRotation(current_rotation, false, empty_hitresult, false)

            local new_weapon_position = original_grip_position - delta_rotated_q
            root:K2_SetWorldLocation(new_weapon_position, false, empty_hitresult, false)

            --detach_flashlight(my_pawn) -- Not gonna detach... for now
        else
            if should_attach_flashlight and not enqueue_detach_flashlight then
                attach_flashlight(my_pawn)
            end
        end
    end

    -- TODO: make IK better
    --[[local ik = SHAnimIKHandIKSubcomp_c:get_first_object_matching(false)

    if ik then
        if anim_instance then
            ik:SetRightHandLocation(right_hand_component:K2_GetComponentLocation(), 1.0, true)
            ik:SetLeftHandLocation(left_hand_component:K2_GetComponentLocation(), 1.0, true)
        end
    end]]
end)

uevr.sdk.callbacks.on_post_engine_tick(function()
    -- We do this here so UObjectHook can reset the position back correctly
    if enqueue_detach_flashlight then
        local pawn = api:get_local_pawn(0)

        if pawn then
            attach_flashlight(pawn, true) -- the true means detach
        end

        enqueue_detach_flashlight = false
    end
end)

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if not is_allowing_vr_mode then return end

    -- If right stick Y is down, press the B button
    local max_int16 = 0x7FFF
    if state.Gamepad.sThumbRY <= -max_int16 * 0.75 and investigating_item == nil then
        state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_B
    end
end)

uevr.sdk.callbacks.on_script_reset(function()
    print("Resetting")

    reset_crosshair_actor()
    reset_hand_actors()

    if BlueprintUpdateCameraShake ~= nil then
        BlueprintUpdateCameraShake:set_function_flags(BlueprintUpdateCameraShake:get_function_flags() & ~0x400) -- Unmark as native
    end

    if ReceivePlayShake ~= nil then
        ReceivePlayShake:set_function_flags(ReceivePlayShake:get_function_flags() & ~0x400) -- Unmark as native
    end
end)