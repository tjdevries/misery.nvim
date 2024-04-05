local scheduler = require "misery.scheduler"
local flip = require "misery.tasks.flip"
local tablet_keyboard = require "misery.tasks.tablet-keyboard"
local typeracer = require "misery.tasks.typeracer"
local no_going_back = require "misery.tasks.no-going-back"
local fog_of_war = require "misery.tasks.fog-of-war"
local invisaline = require "misery.tasks.invisaline"
local rtl = require "misery.tasks.right-to-left"
local upside = require "misery.tasks.screen-upside-down"
local hide_cursor = require "misery.tasks.hide-cursor"
local vsc_de = require "misery.tasks.vs-c*de"
local emacs = require "misery.tasks.emacs"
local ed = require "misery.tasks.ed"
local libre_office = require "misery.tasks.libre-office"

print "oh ya, libre-office"

-- upside({}, scheduler.add_task)
-- hide_cursor({}, scheduler.add_task)

-- print "hello world" -- yup, this is a comment, i am writing it backwards
-- print "hello world"

-- flip({ timeout = 15 * 1000 }, scheduler.add_task)
-- typeracer({ timeout = 15 * 1000 }, scheduler.add_task)
-- typeracer({}, scheduler.add_task)

-- pencil({}, scheduler.add_task)
-- no_going_back({ timeout = 15 * 1000 }, scheduler.add_task)
-- fog_of_war({ timeout = 15 * 1000 }, scheduler.add_task)
-- invisaline({ timeout = 15 * 1000 }, scheduler.add_task)

-- vsc_de({ timeout = 5 * 1000 }, scheduler.add_task)

libre_office({}, scheduler.add_task)
scheduler.start()
