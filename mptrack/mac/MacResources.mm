#import "MacResources.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include <fstream>
#include <sstream>
#include <iostream>
#include <regex>

MacResourceManager& MacResourceManager::Instance() {
    static MacResourceManager s_instance;
    static bool s_initialized = false;
    if (!s_initialized) {
        s_initialized = true;
        NSString* bundleRes = [[NSBundle mainBundle] resourcePath];
        std::string resDir = [bundleRes UTF8String] ? [bundleRes UTF8String] : "";
        std::string rcPath = resDir + "/mptrack.rc";
        std::string hPath = resDir + "/resource.h";
        std::string imgDir = resDir + "/res";

        std::ifstream testRc(rcPath);
        if (testRc.is_open()) {
            s_instance.Initialize(hPath, rcPath, imgDir);
        } else {
            s_instance.Initialize("mptrack/resource.h", "mptrack/mptrack.rc", "mptrack/res");
        }
    }
    return s_instance;
}

static std::string Trim(const std::string& s) {
    auto start = s.find_first_not_of(" \t\r\n");
    if (start == std::string::npos) return "";
    auto end = s.find_last_not_of(" \t\r\n");
    return s.substr(start, end - start + 1);
}

static std::string Unquote(const std::string& s) {
    std::string t = Trim(s);
    if (t.size() >= 2 && t.front() == '"' && t.back() == '"') {
        std::string res;
        for (size_t i = 1; i + 1 < t.size(); ++i) {
            if (t[i] == '"' && t[i + 1] == '"') {
                res += '"';
                ++i;
            } else if (t[i] == '\\' && t[i + 1] == 'n') {
                res += '\n';
                ++i;
            } else if (t[i] == '\\' && t[i + 1] == 't') {
                res += '\t';
                ++i;
            } else {
                res += t[i];
            }
        }
        return res;
    }
    return t;
}

static std::vector<std::string> SplitCSV(const std::string& line);

// Evaluates an rc style expression such as "WS_TABSTOP | ES_AUTOHSCROLL | NOT WS_VISIBLE" on top of the defaults.
static DWORD ParseStyle(const std::string& expr, DWORD defaults) {
#define STYLE(x) {#x, (DWORD)(x)}
    static const std::unordered_map<std::string, DWORD> names = {
        STYLE(WS_BORDER), STYLE(WS_CAPTION), STYLE(WS_CHILD), STYLE(WS_CLIPSIBLINGS), STYLE(WS_CLIPCHILDREN), STYLE(WS_DISABLED),
        STYLE(WS_GROUP), STYLE(WS_HSCROLL), STYLE(WS_VSCROLL), STYLE(WS_MINIMIZEBOX), STYLE(WS_MAXIMIZEBOX), STYLE(WS_POPUP),
        STYLE(WS_SYSMENU), STYLE(WS_TABSTOP), STYLE(WS_THICKFRAME), STYLE(WS_VISIBLE), STYLE(WS_OVERLAPPED), STYLE(WS_DLGFRAME),
        STYLE(WS_EX_ACCEPTFILES), STYLE(WS_EX_APPWINDOW), STYLE(WS_EX_CLIENTEDGE), STYLE(WS_EX_CONTROLPARENT), STYLE(WS_EX_NOACTIVATE),
        STYLE(WS_EX_STATICEDGE), STYLE(WS_EX_TOOLWINDOW), STYLE(WS_EX_TRANSPARENT),
        STYLE(BS_3STATE), STYLE(BS_AUTOCHECKBOX), STYLE(BS_AUTORADIOBUTTON), STYLE(BS_CENTER), STYLE(BS_FLAT), STYLE(BS_LEFT),
        STYLE(BS_MULTILINE), STYLE(BS_OWNERDRAW), STYLE(BS_PUSHLIKE), STYLE(BS_VCENTER), STYLE(BS_CHECKBOX), STYLE(BS_PUSHBUTTON),
        STYLE(BS_DEFPUSHBUTTON), STYLE(BS_GROUPBOX), STYLE(BS_RADIOBUTTON), STYLE(BS_AUTO3STATE), STYLE(BS_RIGHT), STYLE(BS_TOP), STYLE(BS_BOTTOM),
        STYLE(CBS_DROPDOWN), STYLE(CBS_DROPDOWNLIST), STYLE(CBS_SORT), STYLE(CBS_SIMPLE), STYLE(CBS_AUTOHSCROLL), STYLE(CBS_HASSTRINGS),
        STYLE(DS_3DLOOK), STYLE(DS_CENTER), STYLE(DS_CENTERMOUSE), STYLE(DS_CONTROL), STYLE(DS_FIXEDSYS), STYLE(DS_MODALFRAME),
        STYLE(DS_SETFONT), STYLE(DS_SETFOREGROUND),
        STYLE(ES_AUTOHSCROLL), STYLE(ES_AUTOVSCROLL), STYLE(ES_CENTER), STYLE(ES_MULTILINE), STYLE(ES_NUMBER), STYLE(ES_READONLY),
        STYLE(ES_RIGHT), STYLE(ES_WANTRETURN), STYLE(ES_LEFT), STYLE(ES_PASSWORD), STYLE(ES_UPPERCASE), STYLE(ES_LOWERCASE),
        STYLE(LBS_EXTENDEDSEL), STYLE(LBS_HASSTRINGS), STYLE(LBS_MULTIPLESEL), STYLE(LBS_NOINTEGRALHEIGHT), STYLE(LBS_OWNERDRAWFIXED),
        STYLE(LBS_SORT), STYLE(LBS_NOTIFY),
        STYLE(LVS_ALIGNLEFT), STYLE(LVS_NOSORTHEADER), STYLE(LVS_REPORT), STYLE(LVS_SHOWSELALWAYS), STYLE(LVS_SINGLESEL), STYLE(LVS_SORTASCENDING),
        STYLE(SBS_VERT), STYLE(SBS_HORZ),
        STYLE(SS_BLACKFRAME), STYLE(SS_BLACKRECT), STYLE(SS_CENTERIMAGE), STYLE(SS_ETCHEDFRAME), STYLE(SS_ETCHEDHORZ), STYLE(SS_ETCHEDVERT),
        STYLE(SS_GRAYRECT), STYLE(SS_LEFTNOWORDWRAP), STYLE(SS_NOPREFIX), STYLE(SS_NOTIFY), STYLE(SS_PATHELLIPSIS), STYLE(SS_REALSIZEIMAGE),
        STYLE(SS_SUNKEN), STYLE(SS_WHITERECT), STYLE(SS_LEFT), STYLE(SS_CENTER), STYLE(SS_RIGHT), STYLE(SS_ICON),
        STYLE(TBS_AUTOTICKS), STYLE(TBS_BOTH), STYLE(TBS_NOTICKS), STYLE(TBS_TOOLTIPS), STYLE(TBS_TOP), STYLE(TBS_VERT),
        STYLE(TVS_DISABLEDRAGDROP), STYLE(TVS_HASBUTTONS), STYLE(TVS_HASLINES), STYLE(TVS_SHOWSELALWAYS), STYLE(TVS_LINESATROOT),
        STYLE(UDS_ALIGNRIGHT), STYLE(UDS_ARROWKEYS), STYLE(UDS_AUTOBUDDY), STYLE(UDS_NOTHOUSANDS), STYLE(UDS_SETBUDDYINT), STYLE(UDS_WRAP),
    };
#undef STYLE
    DWORD style = defaults;
    std::string token;
    std::istringstream ss(expr);
    while (std::getline(ss, token, '|')) {
        token = Trim(token);
        bool negate = false;
        if (token.rfind("NOT ", 0) == 0) {
            negate = true;
            token = Trim(token.substr(4));
        }
        if (token.empty()) continue;
        DWORD value = 0;
        if (auto it = names.find(token); it != names.end()) value = it->second;
        else value = (DWORD)std::strtoul(token.c_str(), nullptr, 0);
        style = negate ? (style & ~value) : (style | value);
    }
    return style;
}

static std::vector<std::string> SplitCSV(const std::string& line) {
    std::vector<std::string> parts;
    std::string cur;
    bool inQuote = false;
    for (size_t i = 0; i < line.size(); ++i) {
        char c = line[i];
        if (c == '"') {
            inQuote = !inQuote;
            cur += c;
        } else if (c == ',' && !inQuote) {
            parts.push_back(Trim(cur));
            cur.clear();
        } else {
            cur += c;
        }
    }
    parts.push_back(Trim(cur));
    return parts;
}

void MacResourceManager::ParseResourceH(const std::string& path) {
    std::ifstream file(path);
    if (!file.is_open()) return;

    std::string line;
    std::regex defRegex(R"(^\s*#define\s+([A-Za-z0-9_]+)\s+([0-9]+|0x[0-9A-Fa-f]+|\([0-9]+\))\s*$)");
    std::smatch match;

    while (std::getline(file, line)) {
        if (std::regex_match(line, match, defRegex)) {
            std::string name = match[1];
            std::string valStr = match[2];
            if (!valStr.empty() && valStr.front() == '(' && valStr.back() == ')') {
                valStr = valStr.substr(1, valStr.size() - 2);
            }
            int val = (int)std::strtol(valStr.c_str(), nullptr, 0);
            m_nameToId[name] = val;
            m_idToName[val] = name;
        }
    }
}

int MacResourceManager::GetIDByName(const std::string& name) const {
    auto it = m_nameToId.find(name);
    if (it != m_nameToId.end()) return it->second;
    char* end = nullptr;
    long v = std::strtol(name.c_str(), &end, 0);
    if (end != name.c_str() && *end == '\0') return (int)v;
    return 0;
}

std::string MacResourceManager::GetNameByID(int id) const {
    auto it = m_idToName.find(id);
    return (it != m_idToName.end()) ? it->second : "";
}

void MacResourceManager::ParseMptrackRc(const std::string& path, const std::string& resDir) {
    std::ifstream file(path);
    if (!file.is_open()) return;

    std::stringstream buffer;
    buffer << file.rdbuf();
    std::string content = buffer.str();

    std::istringstream stream(content);
    std::string line;

    enum State {
        None,
        InDialog,
        InMenu,
        InStringTable
    } state = None;

    RCDialogDef currentDialog;
    RCMenuDef currentMenu;
    std::vector<RCMenuItemDef> menuStack;

    while (std::getline(stream, line)) {
        // RC statements continue on the next line after a trailing ',' or '|' (or a leading one).
        std::string next;
        while (!Trim(line).empty() && (Trim(line).back() == ',' || Trim(line).back() == '|') && std::getline(stream, next)) {
            line = Trim(line) + " " + Trim(next);
        }
        std::string trimmed = Trim(line);
        if (trimmed.empty() || trimmed.rfind("//", 0) == 0) continue;

        if (state == None) {
            // Check for Images/Icons/Cursors: NAME TYPE "path"
            std::regex imgRegex(R"re(^([A-Za-z0-9_]+)\s+(BITMAP|PNG|ICON|CURSOR)\s+"([^"]+)"\s*$)re");
            std::smatch imgMatch;
            if (std::regex_match(trimmed, imgMatch, imgRegex)) {
                std::string name = imgMatch[1];
                std::string type = imgMatch[2];
                std::string relPath = imgMatch[3];
                // Replace Windows backslashes
                std::replace(relPath.begin(), relPath.end(), '\\', '/');
                size_t pos = relPath.find("res/");
                if (pos != std::string::npos) relPath = relPath.substr(pos + 4);

                int id = GetIDByName(name);
                std::string fullPath = resDir + "/" + relPath;
                std::ifstream imgFile(fullPath, std::ios::binary);
                if (imgFile.is_open()) {
                    std::vector<uint8_t> data((std::istreambuf_iterator<char>(imgFile)), std::istreambuf_iterator<char>());
                    m_imagesById[id] = {relPath, std::move(data)};
                    m_imagesByName[name] = id;
                }
                continue;
            }

            // Check for DIALOG / DIALOGEX
            std::regex dlgRegex(R"(^([A-Za-z0-9_]+)\s+DIALOG(EX)?\s+([0-9]+)\s*,\s*([0-9]+)\s*,\s*([0-9]+)\s*,\s*([0-9]+)\s*$)");
            std::smatch dlgMatch;
            if (std::regex_match(trimmed, dlgMatch, dlgRegex)) {
                state = InDialog;
                currentDialog = RCDialogDef{};
                currentDialog.name = dlgMatch[1];
                currentDialog.id = GetIDByName(currentDialog.name);
                currentDialog.x = std::stoi(dlgMatch[3]);
                currentDialog.y = std::stoi(dlgMatch[4]);
                currentDialog.cx = std::stoi(dlgMatch[5]);
                currentDialog.cy = std::stoi(dlgMatch[6]);
                continue;
            }

            // Check for MENU
            std::regex menuRegex(R"(^([A-Za-z0-9_]+)\s+MENU\s*$)");
            std::smatch menuMatch;
            if (std::regex_match(trimmed, menuMatch, menuRegex)) {
                state = InMenu;
                currentMenu = RCMenuDef{};
                menuStack.clear();
                currentMenu.name = menuMatch[1];
                currentMenu.id = GetIDByName(currentMenu.name);
                continue;
            }

            // Check for STRINGTABLE
            if (trimmed.rfind("STRINGTABLE", 0) == 0) {
                state = InStringTable;
                continue;
            }
        } else if (state == InDialog) {
            if (trimmed == "END") {
                m_dialogsById[currentDialog.id] = currentDialog;
                m_dialogsByName[currentDialog.name] = currentDialog.id;
                state = None;
                continue;
            }
            if (trimmed.rfind("CAPTION", 0) == 0) {
                currentDialog.title = Unquote(trimmed.substr(7));
            } else if (trimmed.rfind("FONT", 0) == 0) {
                auto parts = SplitCSV(trimmed.substr(4));
                if (!parts.empty()) currentDialog.fontSize = std::atoi(parts[0].c_str());
                if (parts.size() > 1) currentDialog.fontName = Unquote(parts[1]);
            } else if (trimmed.rfind("STYLE", 0) == 0) {
                currentDialog.style = ParseStyle(trimmed.substr(5), 0);
            } else if (trimmed.rfind("EXSTYLE", 0) == 0) {
                currentDialog.exStyle = ParseStyle(trimmed.substr(7), 0);
            } else if (trimmed.rfind("MENU", 0) == 0 || trimmed.rfind("CLASS", 0) == 0 || trimmed == "BEGIN") {
                // not used
            } else {
                std::istringstream ss(trimmed);
                std::string type;
                ss >> type;
                std::string rest;
                std::getline(ss, rest);
                const auto args = SplitCSV(rest);
                RCControlDef ctrl;
                // Default styles per resource statement, as documented for rc.exe.
                constexpr DWORD base = WS_CHILD | WS_VISIBLE;
                auto rect = [&](size_t i) {
                    ctrl.x = std::atoi(args[i].c_str());
                    ctrl.y = std::atoi(args[i + 1].c_str());
                    ctrl.cx = std::atoi(args[i + 2].c_str());
                    ctrl.cy = std::atoi(args[i + 3].c_str());
                };
                auto optionalStyles = [&](size_t i, DWORD defaults) {
                    ctrl.style = args.size() > i ? ParseStyle(args[i], defaults) : defaults;
                    ctrl.exStyle = args.size() > i + 1 ? ParseStyle(args[i + 1], 0) : 0;
                };
                if (type == "CONTROL" && args.size() >= 8) {
                    ctrl.title = Unquote(args[0]);
                    ctrl.id = GetIDByName(args[1]);
                    ctrl.className = Unquote(args[2]);
                    ctrl.style = ParseStyle(args[3], base);
                    rect(4);
                    ctrl.exStyle = args.size() > 8 ? ParseStyle(args[8], 0) : 0;
                } else if ((type == "EDITTEXT" || type == "COMBOBOX" || type == "LISTBOX" || type == "SCROLLBAR") && args.size() >= 5) {
                    ctrl.id = GetIDByName(args[0]);
                    rect(1);
                    if (type == "EDITTEXT") { ctrl.className = "EDIT"; optionalStyles(5, base | ES_LEFT | WS_BORDER | WS_TABSTOP); }
                    else if (type == "COMBOBOX") { ctrl.className = "COMBOBOX"; optionalStyles(5, base | CBS_SIMPLE | WS_TABSTOP); }
                    else if (type == "LISTBOX") { ctrl.className = "LISTBOX"; optionalStyles(5, base | LBS_NOTIFY | WS_BORDER); }
                    else { ctrl.className = "SCROLLBAR"; optionalStyles(5, base | SBS_HORZ); }
                } else if (type == "ICON" && args.size() >= 4) {
                    ctrl.title = Unquote(args[0]);
                    ctrl.id = GetIDByName(args[1]);
                    ctrl.className = "STATIC";
                    ctrl.x = std::atoi(args[2].c_str());
                    ctrl.y = std::atoi(args[3].c_str());
                    ctrl.style = base | SS_ICON;
                } else if (args.size() >= 6) {
                    ctrl.title = Unquote(args[0]);
                    ctrl.id = GetIDByName(args[1]);
                    rect(2);
                    if (type == "PUSHBUTTON") { ctrl.className = "BUTTON"; optionalStyles(6, base | BS_PUSHBUTTON | WS_TABSTOP); }
                    else if (type == "DEFPUSHBUTTON") { ctrl.className = "BUTTON"; optionalStyles(6, base | BS_DEFPUSHBUTTON | WS_TABSTOP); }
                    else if (type == "GROUPBOX") { ctrl.className = "BUTTON"; optionalStyles(6, base | BS_GROUPBOX); }
                    else if (type == "CHECKBOX") { ctrl.className = "BUTTON"; optionalStyles(6, base | BS_CHECKBOX | WS_TABSTOP); }
                    else if (type == "AUTOCHECKBOX") { ctrl.className = "BUTTON"; optionalStyles(6, base | BS_AUTOCHECKBOX | WS_TABSTOP); }
                    else if (type == "RADIOBUTTON") { ctrl.className = "BUTTON"; optionalStyles(6, base | BS_RADIOBUTTON); }
                    else if (type == "AUTORADIOBUTTON") { ctrl.className = "BUTTON"; optionalStyles(6, base | BS_AUTORADIOBUTTON); }
                    else if (type == "LTEXT") { ctrl.className = "STATIC"; optionalStyles(6, base | SS_LEFT | WS_GROUP); }
                    else if (type == "CTEXT") { ctrl.className = "STATIC"; optionalStyles(6, base | SS_CENTER | WS_GROUP); }
                    else if (type == "RTEXT") { ctrl.className = "STATIC"; optionalStyles(6, base | SS_RIGHT | WS_GROUP); }
                    else continue;
                } else {
                    continue;
                }
                currentDialog.controls.push_back(ctrl);
            }
        } else if (state == InMenu) {
            // Popups nest; each one is collected on the stack until its END.
            auto appendItem = [&](RCMenuItemDef item) {
                if (!menuStack.empty()) menuStack.back().subItems.push_back(std::move(item));
                else currentMenu.items.push_back(std::move(item));
            };
            if (trimmed == "END") {
                if (!menuStack.empty()) {
                    RCMenuItemDef popup = std::move(menuStack.back());
                    menuStack.pop_back();
                    appendItem(std::move(popup));
                } else {
                    m_menusById[currentMenu.id] = currentMenu;
                    m_menusByName[currentMenu.name] = currentMenu.id;
                    state = None;
                }
                continue;
            }
            auto parseFlags = [](const std::vector<std::string>& args, size_t first) {
                DWORD flags = 0;
                for (size_t i = first; i < args.size(); ++i) {
                    const std::string flag = Trim(args[i]);
                    if (flag == "GRAYED") flags |= MF_GRAYED;
                    else if (flag == "INACTIVE") flags |= MF_DISABLED;
                    else if (flag == "CHECKED") flags |= MF_CHECKED;
                    else if (flag == "MENUBARBREAK") flags |= MF_MENUBARBREAK;
                    else if (flag == "MENUBREAK") flags |= MF_MENUBREAK;
                }
                return flags;
            };
            if (trimmed.rfind("POPUP", 0) == 0) {
                auto args = SplitCSV(Trim(trimmed.substr(5)));
                RCMenuItemDef popup;
                popup.text = args.empty() ? std::string() : Unquote(args[0]);
                popup.flags = MF_POPUP | parseFlags(args, 1);
                menuStack.push_back(std::move(popup));
            } else if (trimmed.rfind("MENUITEM", 0) == 0) {
                std::string rest = Trim(trimmed.substr(8));
                RCMenuItemDef item;
                if (rest.rfind("SEPARATOR", 0) == 0) {
                    item.flags = MF_SEPARATOR;
                } else {
                    auto args = SplitCSV(rest);
                    if (args.size() < 2) continue;
                    item.text = Unquote(args[0]);
                    const std::string idStr = Trim(args[1]);
                    item.id = std::isdigit((unsigned char)idStr[0]) ? std::atoi(idStr.c_str()) : GetIDByName(idStr);
                    item.flags = parseFlags(args, 2);
                }
                appendItem(std::move(item));
            }
        } else if (state == InStringTable) {
            if (trimmed == "END") {
                state = None;
                continue;
            }
            if (trimmed == "BEGIN") continue;

            auto pos = trimmed.find_first_of(" \t");
            if (pos != std::string::npos) {
                std::string idStr = Trim(trimmed.substr(0, pos));
                std::string strVal = Unquote(trimmed.substr(pos + 1));
                int id = GetIDByName(idStr);
                if (id != 0) {
                    m_strings[id] = strVal;
                }
            }
        }
    }

    ParseAfxDialogLayout(content);
    ParseDlgInit(content);
}

void MacResourceManager::ParseAfxDialogLayout(const std::string& rcContent) {
    std::regex layoutBlockRegex(R"(([A-Za-z0-9_]+)\s+AFX_DIALOG_LAYOUT\s*[\r\n]+BEGIN([\s\S]*?)END)");
    auto words_begin = std::sregex_iterator(rcContent.begin(), rcContent.end(), layoutBlockRegex);
    auto words_end = std::sregex_iterator();

    for (std::sregex_iterator i = words_begin; i != words_end; ++i) {
        std::smatch match = *i;
        std::string dlgName = match[1];
        std::string body = match[2];

        int dlgId = GetIDByName(dlgName);
        auto dlgIt = m_dialogsById.find(dlgId);
        if (dlgIt == m_dialogsById.end()) continue;

        // Parse pairs of numbers in body: AFX_DIALOG_LAYOUT has 0, {moveX, moveY, sizeX, sizeY} per control
        std::istringstream ss(body);
        std::string line;
        size_t ctrlIndex = 0;
        while (std::getline(ss, line)) {
            std::string t = Trim(line);
            if (t.empty()) continue;
            auto parts = SplitCSV(t);
            if (parts.size() >= 4 && ctrlIndex < dlgIt->second.controls.size()) {
                dlgIt->second.controls[ctrlIndex].moveX = std::atoi(parts[0].c_str());
                dlgIt->second.controls[ctrlIndex].moveY = std::atoi(parts[1].c_str());
                dlgIt->second.controls[ctrlIndex].sizeX = std::atoi(parts[2].c_str());
                dlgIt->second.controls[ctrlIndex].sizeY = std::atoi(parts[3].c_str());
                ++ctrlIndex;
            }
        }
    }
}

void MacResourceManager::ParseDlgInit(const std::string& rcContent) {
    std::regex dlgInitRegex(R"(([A-Za-z0-9_]+)\s+DLGINIT\s*[\r\n]+BEGIN([\s\S]*?)END)");
    auto words_begin = std::sregex_iterator(rcContent.begin(), rcContent.end(), dlgInitRegex);
    auto words_end = std::sregex_iterator();

    for (std::sregex_iterator i = words_begin; i != words_end; ++i) {
        std::smatch match = *i;
        std::string dlgName = match[1];
        std::string body = match[2];

        int dlgId = GetIDByName(dlgName);
        auto dlgIt = m_dialogsById.find(dlgId);
        if (dlgIt == m_dialogsById.end()) continue;

        std::istringstream ss(body);
        std::string line;
        while (std::getline(ss, line)) {
            std::string t = Trim(line);
            if (t.empty()) continue;
            auto parts = SplitCSV(t);
            if (parts.size() >= 3) {
                int ctrlId = GetIDByName(parts[0]);
                std::string str = Unquote(parts[2]);
                for (auto& c : dlgIt->second.controls) {
                    if (c.id == ctrlId && !str.empty()) {
                        c.dlgInitStrings.push_back(str);
                    }
                }
            }
        }
    }
}

bool MacResourceManager::Initialize(const std::string& resourceHPath, const std::string& mptrackRcPath, const std::string& resDirPath) {
    // IDs that .rc files use without resource.h defining them (winuser.h / afxres.h).
    static const std::pair<const char*, int> standardIds[] = {
        {"IDOK", IDOK}, {"IDCANCEL", IDCANCEL}, {"IDABORT", IDABORT}, {"IDRETRY", IDRETRY},
        {"IDIGNORE", IDIGNORE}, {"IDYES", IDYES}, {"IDNO", IDNO}, {"IDCLOSE", 8}, {"IDHELP", 9},
        {"IDC_STATIC", -1},
    };
    for (const auto& [name, id] : standardIds) m_nameToId[name] = id;
    ParseResourceH(resDirPath + "/afxres.h");
    ParseResourceH(resourceHPath);
    ParseMptrackRc(mptrackRcPath, resDirPath);
    return true;
}

const RCDialogDef* MacResourceManager::GetDialog(int id) const {
    auto it = m_dialogsById.find(id);
    return (it != m_dialogsById.end()) ? &it->second : nullptr;
}

const RCDialogDef* MacResourceManager::GetDialog(const char* name) const {
    if (!name) return nullptr;
    if (IS_INTRESOURCE(name)) return GetDialog((int)(uintptr_t)name);
    auto it = m_dialogsByName.find(name);
    return (it != m_dialogsByName.end()) ? GetDialog(it->second) : nullptr;
}

const RCMenuDef* MacResourceManager::GetMenu(int id) const {
    auto it = m_menusById.find(id);
    return (it != m_menusById.end()) ? &it->second : nullptr;
}

const RCMenuDef* MacResourceManager::GetMenu(const char* name) const {
    if (!name) return nullptr;
    if (IS_INTRESOURCE(name)) return GetMenu((int)(uintptr_t)name);
    auto it = m_menusByName.find(name);
    return (it != m_menusByName.end()) ? GetMenu(it->second) : nullptr;
}

std::string MacResourceManager::GetString(int id) const {
    auto it = m_strings.find(id);
    return (it != m_strings.end()) ? it->second : "";
}

const std::vector<uint8_t>* MacResourceManager::GetImageData(int id, const char* type) const {
    (void)type;
    auto it = m_imagesById.find(id);
    return (it != m_imagesById.end()) ? &it->second.data : nullptr;
}

const std::vector<uint8_t>* MacResourceManager::GetImageData(const char* name, const char* type) const {
    if (!name) return nullptr;
    if (IS_INTRESOURCE(name)) return GetImageData((int)(uintptr_t)name, type);
    auto it = m_imagesByName.find(name);
    return (it != m_imagesByName.end()) ? GetImageData(it->second, type) : nullptr;
}

// C-linkage Win32 Resource APIs
HRSRC WINAPI FindResourceA(HMODULE hModule, LPCSTR lpName, LPCSTR lpType) {
    (void)hModule;
    int id = 0;
    if (IS_INTRESOURCE(lpName)) id = (int)(uintptr_t)lpName;
    else id = MacResourceManager::Instance().GetIDByName(lpName);
    return id ? (HRSRC)(uintptr_t)id : nullptr;
}

HRSRC WINAPI FindResourceW(HMODULE hModule, LPCWSTR lpName, LPCWSTR lpType) {
    (void)hModule;
    if (IS_INTRESOURCE(lpName)) return (HRSRC)lpName;
    char buf[256] = {};
    WideCharToMultiByte(CP_UTF8, 0, lpName, -1, buf, sizeof(buf), nullptr, nullptr);
    return FindResourceA(hModule, buf, (LPCSTR)lpType);
}

HGLOBAL WINAPI LoadResource(HMODULE hModule, HRSRC hResInfo) {
    (void)hModule;
    return (HGLOBAL)hResInfo;
}

// Win32 RT_BITMAP resources start at the BITMAPINFOHEADER; our .bmp files also carry the 14-byte BITMAPFILEHEADER.
static size_t ResourceDataOffset(const std::vector<uint8_t>& data) {
    return (data.size() > 14 && data[0] == 'B' && data[1] == 'M') ? 14 : 0;
}

LPVOID WINAPI LockResource(HGLOBAL hResData) {
    int id = (int)(uintptr_t)hResData;
    const auto* data = MacResourceManager::Instance().GetImageData(id);
    return data ? (LPVOID)(data->data() + ResourceDataOffset(*data)) : nullptr;
}

DWORD WINAPI SizeofResource(HMODULE hModule, HRSRC hResInfo) {
    (void)hModule;
    int id = (int)(uintptr_t)hResInfo;
    const auto* data = MacResourceManager::Instance().GetImageData(id);
    return data ? (DWORD)(data->size() - ResourceDataOffset(*data)) : 0;
}

int WINAPI LoadStringA(HINSTANCE hInstance, UINT uID, LPSTR lpBuffer, int cchBufferMax) {
    (void)hInstance;
    std::string s = MacResourceManager::Instance().GetString((int)uID);
    if (s.empty()) return 0;
    if (lpBuffer && cchBufferMax > 0) {
        strncpy(lpBuffer, s.c_str(), (size_t)cchBufferMax - 1);
        lpBuffer[cchBufferMax - 1] = '\0';
        return (int)strlen(lpBuffer);
    }
    return (int)s.length();
}

int WINAPI LoadStringW(HINSTANCE hInstance, UINT uID, LPWSTR lpBuffer, int cchBufferMax) {
    (void)hInstance;
    std::string s = MacResourceManager::Instance().GetString((int)uID);
    if (s.empty()) return 0;
    int wlen = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, lpBuffer, cchBufferMax);
    return (wlen > 0) ? (wlen - 1) : 0;
}
