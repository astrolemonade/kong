local req_dyn_hook = require("kong.dynamic_hook")
local kproto = require("resty.kong.kproto")

local ngx_get_phase = ngx.get_phase

local kproto_new = kproto.new
local kproto_free = kproto.free
local kproto_enter_span = kproto.enter_span
local kproto_add_string_attribute = kproto.add_string_attribute
local kproto_add_bool_attribute = kproto.add_int64_attribute
local kproto_add_int64_attribute = kproto.add_int64_attribute
local kproto_add_double_attribute = kproto.add_double_attribute
local kproto_exit_span = kproto.exit_span
local _kproto_get_serialized_data = kproto.get_serialized_data


local _M = {}

local VALID_PHASES = {
    rewrite       = true,
    balancer      = true,
    access        = true,
    header_filter = true,
    body_filter   = true,
    log           = true,
}


function _M.globalpatches()
    require("kong.etrace.hooks").globalpatches(_M)

    req_dyn_hook.hook("etrace", "before:rewrite", function(ctx)
        local tr = kproto_new()
        ctx.tr = tr

        kproto_enter_span(tr, "rewrite")
    end)

    req_dyn_hook.hook("etrace", "after:rewrite", function(ctx)
        kproto_exit_span(ctx.tr)
    end)

    req_dyn_hook.hook("etrace", "before:balancer", function(ctx)
        kproto_enter_span(ctx.tr, "balancer")
    end)

    req_dyn_hook.hook("etrace", "after:balancer", function(ctx)
        kproto_exit_span(ctx.tr)
    end)

    req_dyn_hook.hook("etrace", "before:access", function(ctx)
        kproto_enter_span(ctx.tr, "access")
    end)

    req_dyn_hook.hook("etrace", "after:access", function(ctx)
        kproto_exit_span(ctx.tr)
    end)

    req_dyn_hook.hook("etrace", "before:response", function(ctx)
        kproto_enter_span(ctx.tr, "response")
    end)

    req_dyn_hook.hook("etrace", "after:response", function(ctx)
        kproto_exit_span(ctx.tr)
    end)

    req_dyn_hook.hook("etrace", "before:header_filter", function(ctx)
        kproto_enter_span(ctx.tr, "header_filter")
    end)

    req_dyn_hook.hook("etrace", "after:header_filter", function(ctx)
        kproto_exit_span(ctx.tr)
    end)

    req_dyn_hook.hook("etrace", "before:body_filter", function(ctx)
        kproto_enter_span(ctx.tr, "body_filter")
    end)

    req_dyn_hook.hook("etrace", "after:body_filter", function(ctx)
        kproto_exit_span(ctx.tr)
    end)

    req_dyn_hook.hook("etrace", "before:log", function(ctx)
        kproto_enter_span(ctx.tr, "log")
    end)

    req_dyn_hook.hook("etrace", "after:log", function(ctx)
        kproto_exit_span(ctx.tr)

        -- local serialized_data = _kproto_get_serialized_data(ctx.tr)
        -- local fp = assert(io.open("/tmp/etrace.bin", "w"))
        -- assert(fp:write(serialized_data))
        -- assert(fp:close())

        kproto_free(ctx.tr)
    end)

    req_dyn_hook.hook("etrace", "before:plugin_iterator", function(ctx)
        kproto_enter_span(assert(ctx.tr), "plugin_iterator")
    end)

    req_dyn_hook.hook("etrace", "after:plugin_iterator", function(ctx)
        kproto_exit_span(assert(ctx.tr)) -- plugin_iterator
    end)

    req_dyn_hook.hook("etrace", "before:a_plugin", function(ctx, plugin_name, plugin_id)
        kproto_enter_span(assert(ctx.tr), plugin_name)
        kproto_add_string_attribute(ctx.tr, "plugin_id", plugin_id)
    end)

    req_dyn_hook.hook("etrace", "after:a_plugin", function(ctx)
        kproto_exit_span(assert(ctx.tr)) -- plugin_name
    end)

    req_dyn_hook.hook("etrace", "before:router", function(ctx)
        kproto_enter_span(ctx.tr, "router")
    end)

    req_dyn_hook.hook("etrace", "after:router", function(ctx)
        kproto_exit_span(ctx.tr)
    end)
end


function _M.init_worker()
    req_dyn_hook.always_enable("etrace")
    ngx.log(ngx.ERR, "etrace init_worker")
end


function _M.enter_span(name)
    if not VALID_PHASES[ngx_get_phase()] then
        return
    end

    kproto_enter_span(ngx.ctx.tr, name)
end


function _M.add_string_attribute(key, value)
    if not VALID_PHASES[ngx_get_phase()] then
        return
    end

    kproto_add_string_attribute(ngx.ctx.tr, key, value)
end


function _M.add_bool_attribute(key, value)
    if not VALID_PHASES[ngx_get_phase()] then
        return
    end

    kproto_add_bool_attribute(ngx.ctx.tr, key, value)
end


function _M.add_int64_attribute(key, value)
    if not VALID_PHASES[ngx_get_phase()] then
        return
    end

    kproto_add_int64_attribute(ngx.ctx.tr, key, value)
end


function _M.add_double_attribute(key, value)
    if not VALID_PHASES[ngx_get_phase()] then
        return
    end

    kproto_add_double_attribute(ngx.ctx.tr, key, value)
end


function _M.exit_span()
    if not VALID_PHASES[ngx_get_phase()] then
        return
    end

    kproto_exit_span(ngx.ctx.tr)
end


return _M
