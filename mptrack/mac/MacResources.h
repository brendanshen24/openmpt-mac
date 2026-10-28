#pragma once

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include "windows.h"
#include <string>
#include <vector>
#include <unordered_map>
#include <memory>

struct RCControlDef {
    std::string className;
    std::string title;
    int id = 0;
    int x = 0;
    int y = 0;
    int cx = 0;
    int cy = 0;
    DWORD style = 0;
    DWORD exStyle = 0;
    // AFX_DIALOG_LAYOUT anchoring (0-100% X/Y move/size)
    int moveX = 0, moveY = 0;
    int sizeX = 0, sizeY = 0;
    std::vector<std::string> dlgInitStrings;
};

struct RCDialogDef {
    std::string name;
    int id = 0;
    std::string title;
    std::string fontName;
    int fontSize = 8;
    int x = 0;
    int y = 0;
    int cx = 0;
    int cy = 0;
    DWORD style = 0;
    DWORD exStyle = 0;
    std::vector<RCControlDef> controls;
};

struct RCMenuItemDef {
    std::string text;
    int id = 0;
    DWORD flags = 0;
    std::vector<RCMenuItemDef> subItems;
};

struct RCMenuDef {
    std::string name;
    int id = 0;
    std::vector<RCMenuItemDef> items;
};

class MacResourceManager {
public:
    static MacResourceManager& Instance();

    bool Initialize(const std::string& resourceHPath, const std::string& mptrackRcPath, const std::string& resDirPath);

    const RCDialogDef* GetDialog(int id) const;
    const RCDialogDef* GetDialog(const char* name) const;

    const RCMenuDef* GetMenu(int id) const;
    const RCMenuDef* GetMenu(const char* name) const;

    std::string GetString(int id) const;

    const std::vector<uint8_t>* GetImageData(int id, const char* type = nullptr) const;
    const std::vector<uint8_t>* GetImageData(const char* name, const char* type = nullptr) const;

    int GetIDByName(const std::string& name) const;
    std::string GetNameByID(int id) const;

private:
    MacResourceManager() = default;

    std::unordered_map<std::string, int> m_nameToId;
    std::unordered_map<int, std::string> m_idToName;

    std::unordered_map<int, RCDialogDef> m_dialogsById;
    std::unordered_map<std::string, int> m_dialogsByName;

    std::unordered_map<int, RCMenuDef> m_menusById;
    std::unordered_map<std::string, int> m_menusByName;

    std::unordered_map<int, std::string> m_strings;

    struct ImageEntry {
        std::string filename;
        std::vector<uint8_t> data;
    };
    std::unordered_map<int, ImageEntry> m_imagesById;
    std::unordered_map<std::string, int> m_imagesByName;

    void ParseResourceH(const std::string& path);
    void ParseMptrackRc(const std::string& path, const std::string& resDir);
    void ParseAfxDialogLayout(const std::string& rcContent);
    void ParseDlgInit(const std::string& rcContent);
};
