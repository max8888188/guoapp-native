#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""对 guoapp 源码应用定制改动（精确字符串匹配，不依赖正则）。"""
import pathlib
import sys

root = pathlib.Path("app")
if not root.is_dir():
    sys.exit("FAIL: app/ not found (cwd=%s)" % pathlib.Path.cwd())

sec = root / "lib/ui/settings/settings_sections.dart"
s = sec.read_text(encoding="utf-8")

old_widgets = (
    "          const _UpdateCheckTile(),\n"
    "          SwitchTile(\n"
    "            title: '启动时检查更新',\n"
    "            subtitle: '有新版本时每次启动都会提示，可在提示里忽略此版本',\n"
    "            value: store.checkUpdates,\n"
    "            onChanged: (value) =>\n"
    "                saveSetting(context, () => store.setCheckUpdates(value)),\n"
    "          ),\n"
    "          SwitchTile(\n"
    "            title: '匿名使用统计',\n"
    "            subtitle: '启动时发送随机编号、版本号、平台和所属版本，用于统计使用人数',\n"
    "            value: store.shareUsage,\n"
    "            onChanged: (value) =>\n"
    "                saveSetting(context, () => store.setShareUsage(value)),\n"
    "          ),\n"
)
if old_widgets not in s:
    sys.exit("FAIL: about widgets anchor not found")
s = s.replace(old_widgets, "", 1)

old_links = (
    "const _links = [\n"
    "  [\n"
    "    ('GitHub · 重建版', String.fromEnvironment('PROJECT_URL')),\n"
    "    ('GitHub · 原作者', 'https://github.com/fish2018'),\n"
    "  ],\n"
    "  [\n"
    "    ('Telegram · 交流群组', String.fromEnvironment('TELEGRAM_GROUP_URL')),\n"
    "    ('Telegram · 更新频道', String.fromEnvironment('TELEGRAM_CHANNEL_URL')),\n"
    "  ],\n"
    "];"
)
new_links = (
    "const _links = [\n"
    "  [\n"
    "    ('小胡短剧胡萝卜版', 'http://sps.yy-gp.com/hgydh/i.html'),\n"
    "    ('小胡音乐.点我去下载', 'https://9h.hk/xhmp3?from=ap'),\n"
    "  ],\n"
    "  [\n"
    "    ('赞赏作者', 'https://9h.hk/xh?from=android1'),\n"
    "    ('联系作者小胡', 'https://9h.hk/Duanxp?from=apk1'),\n"
    "  ],\n"
    "];"
)
if old_links not in s:
    sys.exit("FAIL: _links anchor not found")
s = s.replace(old_links, new_links, 1)
sec.write_text(s, encoding="utf-8")
print("OK settings_sections.dart")

ab = root / "lib/app_build.dart"
t = ab.read_text(encoding="utf-8")
if "const appName = '小果影视';" not in t:
    sys.exit("FAIL: appName anchor not found")
ab.write_text(t.replace("const appName = '小果影视';", "const appName = '萝卜短剧';", 1),
              encoding="utf-8")
print("OK app_build.dart")

bg = root / "android/app/build.gradle.kts"
g = bg.read_text(encoding="utf-8")
if 'manifestPlaceholders["appLabel"] = "小果影视"' not in g:
    sys.exit("FAIL: appLabel anchor not found")
bg.write_text(g.replace('manifestPlaceholders["appLabel"] = "小果影视"',
                        'manifestPlaceholders["appLabel"] = "萝卜短剧"', 1),
              encoding="utf-8")
print("OK build.gradle.kts")

final = sec.read_text(encoding="utf-8")
for bad in ("const _UpdateCheckTile(),", "启动时检查更新", "匿名使用统计"):
    if bad in final:
        sys.exit("FAIL: leftover %s" % bad)
print("VERIFY OK - 3 widgets removed, links replaced")
