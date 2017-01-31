#pragma once

#include <vector>
#include <string>

#include "ilib.h"

namespace CinEdit {

class ilib {
public:
    ~ilib();
    
    bool load(const std::string &path);
    bool save() const;
    void setPath(const std::string &path) { m_path = path; }
    const std::string &getPath() const { return m_path; }
    
    BottleItem *getItems();
    const BottleItem *getItems() const { return &m_items.front(); }
    unsigned getNumItems() const { return m_items.size(); }
    void erase(unsigned i);
    void clear();
    
    BottleItem *append();
private:
    std::vector<BottleItem> m_items;
    std::string m_path;
};

} // namespace CinEdit
