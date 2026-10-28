#pragma once
// Extracts the file extensions from an MFC file-dialog filter ("Desc|*.a;*.b|Desc 2|*.c||").
// Wildcard-only patterns ("*.*", "*") are skipped, so "All Files" entries do not widen the choice.

#include <string>
#include <vector>

inline std::vector<std::wstring> MacFilterExtensions(const std::wstring &filter)
{
	std::vector<std::wstring> extensions;
	std::vector<std::wstring> fields;
	std::wstring field;
	for(wchar_t c : filter)
	{
		if(c == L'|' || c == L'\0')
		{
			fields.push_back(field);
			field.clear();
		} else
		{
			field += c;
		}
	}
	fields.push_back(field);
	// Fields alternate description, pattern list.
	for(size_t i = 1; i < fields.size(); i += 2)
	{
		std::wstring patterns = fields[i] + L";";
		std::wstring pattern;
		for(wchar_t c : patterns)
		{
			if(c != L';')
			{
				pattern += c;
				continue;
			}
			const auto dot = pattern.rfind(L'.');
			// Only "*.ext" patterns name a type; "*.*", "*" and Amiga-style "mod.*" prefixes cannot be expressed as one.
			if(dot != std::wstring::npos && pattern.compare(0, dot, L"*") == 0 && dot + 1 < pattern.size() && pattern[dot + 1] != L'*')
			{
				std::wstring ext = pattern.substr(dot + 1);
				for(auto &ch : ext) ch = static_cast<wchar_t>(towlower(ch));
				bool known = false;
				for(const auto &e : extensions) known = known || e == ext;
				if(!known) extensions.push_back(ext);
			}
			pattern.clear();
		}
	}
	return extensions;
}
