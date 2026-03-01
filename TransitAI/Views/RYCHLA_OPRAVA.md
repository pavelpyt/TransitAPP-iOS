# 🔧 Rychlá oprava - TransitAI

## 📋 Co jsem opravil:

### Původní problémy (13 chyb):
1. ❌ `Invalid redeclaration of 'LineTag'` → ✅ OPRAVENO
2. ❌ `Invalid redeclaration of 'StringMatcher'` → ✅ OPRAVENO  
3. ❌ `Ambiguous use of 'normalize'` → ✅ OPRAVENO
4. ❌ `Ambiguous use of 'findBestMatches'` → ✅ OPRAVENO
5. ❌ Chybějící `formatDuration` funkce → ✅ PŘIDÁNO

---

## 🆕 Vytvořené soubory:

1. **SharedComponents.swift** - Sdílené UI komponenty (LineTag)
2. **StringMatcher.swift** - Utility pro vyhledávání zastávek

---

## ⚡ CO MUSÍŠ UDĚLAT:

### 1️⃣ Přidej nové soubory do projektu:
V Xcode:
- Pravý klik na složku projektu
- "Add Files to TransitAI..."
- Vyber `SharedComponents.swift` a `StringMatcher.swift`
- Zaškrtni "Add to targets: TransitAI"

### 2️⃣ Vyčisti build:
```
Product → Clean Build Folder (Cmd+Shift+K)
```

### 3️⃣ Smaž cache:
Zavři Xcode, pak v Terminalu:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/TransitAI-*
```

### 4️⃣ Build znovu:
```
Product → Build (Cmd+B)
```

---

## ✅ Hotovo!

Aplikace by měla fungovat se všemi 4 obrazovkami:
- 💬 Chat
- 📍 Okolí  
- ❤️ Cesty
- ⚙️ Nastavení

---

**Pokud to nefunguje, zkontroluj Target Membership u nových souborů!**
