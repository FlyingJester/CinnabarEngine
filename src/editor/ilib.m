:- module ilib.
% AUTOGENERATED, DO NOT EDIT
% Created by libbottle generate.py, 2017-02-05
:- interface.

:- import_module buffer.

:- use_module io.

:- type armor.
:- type consumable.
:- type junk.
:- type weapon.
:- type item_data --->
    armor(armor) ;
    consumable(consumable) ;
    junk(junk) ;
    weapon(weapon).
:- type item_type ---> 
    armor ;
    consumable ;
    junk ;
    weapon.

:- type item ---> item(item_data, int, string, string, string, int, int).

:- type armor ---> armor(armor_type, int).

:- type consumable ---> consumable.

:- type book.
:- type gem.
:- type junk_data --->
    book(book) ;
    gem(gem).
:- type junk_type ---> 
    book ;
    gem.

:- type junk ---> junk(junk_data).

:- type weapon ---> weapon(int, int, weapon_type).

:- type armor_type ---> 
    boots ;
    chestplate ;
    helmet.

:- type book ---> book(string).

:- type gem ---> gem.

:- type weapon_type ---> 
    axe ;
    sword.


:- func item_type(item_data) = item_type.
:- pred examine_item(item_data, int, string, string, string, int, int, item).
:- mode examine_item(in,in,in,in,in,in,in,out) is det.
:- mode examine_item(out,out,out,out,out,out,out,in) is det.
:- pred write_item(item::in, io.io::di, io.io::uo) is det.

% read_item(Buffer, !ByteIndex, Result).
:- pred read_item(buffer::in, int::in, int::out, item::out) is semidet.

:- pred examine_armor(armor_type, int, armor).
:- mode examine_armor(in,in,out) is det.
:- mode examine_armor(out,out,in) is det.
:- func junk_type(junk_data) = junk_type.
:- pred examine_junk(junk_data, junk).
:- mode examine_junk(in,out) is det.
:- mode examine_junk(out,in) is det.
:- pred examine_weapon(int, int, weapon_type, weapon).
:- mode examine_weapon(in,in,in,out) is det.
:- mode examine_weapon(out,out,out,in) is det.
:- pred write_armor(armor::in, io.io::di, io.io::uo) is det.

% read_armor(Buffer, !ByteIndex, Result).
:- pred read_armor(buffer::in, int::in, int::out, armor::out) is semidet.

:- pred write_consumable(consumable::in, io.io::di, io.io::uo) is det.

% read_consumable(Buffer, !ByteIndex, Result).
:- pred read_consumable(buffer::in, int::in, int::out, consumable::out) is det.

:- pred write_junk(junk::in, io.io::di, io.io::uo) is det.

% read_junk(Buffer, !ByteIndex, Result).
:- pred read_junk(buffer::in, int::in, int::out, junk::out) is semidet.

:- pred examine_book(string, book).
:- mode examine_book(in,out) is det.
:- mode examine_book(out,in) is det.
:- pred write_book(book::in, io.io::di, io.io::uo) is det.

% read_book(Buffer, !ByteIndex, Result).
:- pred read_book(buffer::in, int::in, int::out, book::out) is semidet.

:- pred write_gem(gem::in, io.io::di, io.io::uo) is det.

% read_gem(Buffer, !ByteIndex, Result).
:- pred read_gem(buffer::in, int::in, int::out, gem::out) is det.

:- pred write_weapon(weapon::in, io.io::di, io.io::uo) is det.

% read_weapon(Buffer, !ByteIndex, Result).
:- pred read_weapon(buffer::in, int::in, int::out, weapon::out) is semidet.


:- pred item_armor(item_data, armor).
:- mode item_armor(in, out) is semidet.
:- mode item_armor(out, in) is det.

:- pred item_consumable(item_data, consumable).
:- mode item_consumable(in, out) is semidet.
:- mode item_consumable(out, in) is det.

:- pred item_junk(item_data, junk).
:- mode item_junk(in, out) is semidet.
:- mode item_junk(out, in) is det.

:- pred item_weapon(item_data, weapon).
:- mode item_weapon(in, out) is semidet.
:- mode item_weapon(out, in) is det.

:- pred junk_book(junk_data, book).
:- mode junk_book(in, out) is semidet.
:- mode junk_book(out, in) is det.

:- pred junk_gem(junk_data, gem).
:- mode junk_gem(in, out) is semidet.
:- mode junk_gem(out, in) is det.


:- implementation.

:- import_module int.
:- use_module string.
:- use_module list.
:- use_module char.


:- pred write_string(string::in, int::in, int::in, io.io::di, io.io::uo) is det.
write_string(Str, I, N, !IO) :-
    ( I = N ->
        true
    ;
        string.det_index(Str, I, Ch),
        char.to_int(Ch, CodePoint),
        io.write_byte(CodePoint, !IO),
        write_string(Str, I + 1, N, !IO)
    ).
:- pred float_to_bytes(float::in, int::out, int::out, int::out, int::out) is det.
:- pred bytes_to_float(float::out, int::in, int::in, int::in, int::in) is det.
:- pred int_to_bytes(int::in, int::out, int::out, int::out, int::out) is det.
:- pred bytes_to_int(int::out, int::in, int::in, int::in, int::in) is det.
:- pragma foreign_proc("C", float_to_bytes(In::in, O0::out, O1::out, O2::out, O3::out),
    [promise_pure, thread_safe, does_not_affect_liveness, will_not_call_mercury, will_not_throw_exception],
    "const float f=In;const unsigned char *const uc=(unsigned char*)&f;
    O0=uc[0];O1=uc[1];O2=uc[2];O3=uc[3];    ").
:- pragma foreign_proc("C", bytes_to_float(Out::out, I0::in, I1::in, I2::in, I3::in),
    [promise_pure, thread_safe, does_not_affect_liveness, will_not_call_mercury, will_not_throw_exception],
    "float f;unsigned char *const uc=(unsigned char*)&f;
    uc[0]=I0;uc[1]=I1;uc[2]=I2;uc[3]=I3;    Out = f;
    ").
:- pragma foreign_proc("C", int_to_bytes(In::in, O0::out, O1::out, O2::out, O3::out),
    [promise_pure, thread_safe, does_not_affect_liveness, will_not_call_mercury, will_not_throw_exception],
    "const int i=In;const unsigned char *const uc=(unsigned char*)&i;
    O0=uc[0];O1=uc[1];O2=uc[2];O3=uc[3];    ").
:- pragma foreign_proc("C", bytes_to_int(Out::out, I0::in, I1::in, I2::in, I3::in),
    [promise_pure, thread_safe, does_not_affect_liveness, will_not_call_mercury, will_not_throw_exception],
    "int i;unsigned char *const uc=(unsigned char*)&i;
    uc[0]=I0;uc[1]=I1;uc[2]=I2;uc[3]=I3;    Out = i;
    ").

:- pragma foreign_export("C", item_type(in) = (out), "Ilib_GetItemType").

:- pragma foreign_decl("C",
    "enum EnumItemTypeType{
    eArmor,
    eConsumable,
    eJunk,
    eWeapon
};").

:- pragma foreign_enum("C",item_type/0,[
    armor - "eArmor",
    consumable - "eConsumable",
    junk - "eJunk",
    weapon - "eWeapon"]).

examine_item(ItemData0, Int1, String2, String3, String4, Int5, Int6, item(ItemData0, Int1, String2, String3, String4, Int5, Int6)).

:- pragma foreign_export("C", examine_item(in,in,in,in,in,in,in,out), "Ilib_CreateItem").

:- pragma foreign_export("C", examine_item(out,out,out,out,out,out,out,in), "Ilib_GetItem").

examine_armor(ArmorType0, Int1, armor(ArmorType0, Int1)).

:- pragma foreign_export("C", examine_armor(in,in,out), "Ilib_CreateArmor").

:- pragma foreign_export("C", examine_armor(out,out,in), "Ilib_GetArmor").

:- pragma foreign_export("C", junk_type(in) = (out), "Ilib_GetJunkType").

:- pragma foreign_decl("C",
    "enum EnumJunkTypeType{
    eBook,
    eGem
};").

:- pragma foreign_enum("C",junk_type/0,[
    book - "eBook",
    gem - "eGem"]).

examine_junk(JunkData0, junk(JunkData0)).

:- pragma foreign_export("C", examine_junk(in,out), "Ilib_CreateJunk").

:- pragma foreign_export("C", examine_junk(out,in), "Ilib_GetJunk").

examine_weapon(Int0, Int1, WeaponType2, weapon(Int0, Int1, WeaponType2)).

:- pragma foreign_export("C", examine_weapon(in,in,in,out), "Ilib_CreateWeapon").

:- pragma foreign_export("C", examine_weapon(out,out,out,in), "Ilib_GetWeapon").

:- pragma foreign_decl("C",
    "enum EnumArmorTypeType{
    eBoots,
    eChestplate,
    eHelmet
};").

:- pragma foreign_enum("C",armor_type/0,[
    boots - "eBoots",
    chestplate - "eChestplate",
    helmet - "eHelmet"]).

examine_book(String0, book(String0)).

:- pragma foreign_export("C", examine_book(in,out), "Ilib_CreateBook").

:- pragma foreign_export("C", examine_book(out,in), "Ilib_GetBook").

:- pragma foreign_decl("C",
    "enum EnumWeaponTypeType{
    eAxe,
    eSword
};").

:- pragma foreign_enum("C",weapon_type/0,[
    axe - "eAxe",
    sword - "eSword"]).

item_type(armor(_)) = armor.
item_armor(armor(That), That).
:- pragma foreign_export("C", item_armor(in, out), "Ilib_GetItemArmor").
:- pragma foreign_export("C", item_armor(out, in), "Ilib_CreateItemArmor").

item_type(consumable(_)) = consumable.
item_consumable(consumable(That), That).
:- pragma foreign_export("C", item_consumable(in, out), "Ilib_GetItemConsumable").
:- pragma foreign_export("C", item_consumable(out, in), "Ilib_CreateItemConsumable").

item_type(junk(_)) = junk.
item_junk(junk(That), That).
:- pragma foreign_export("C", item_junk(in, out), "Ilib_GetItemJunk").
:- pragma foreign_export("C", item_junk(out, in), "Ilib_CreateItemJunk").

item_type(weapon(_)) = weapon.
item_weapon(weapon(That), That).
:- pragma foreign_export("C", item_weapon(in, out), "Ilib_GetItemWeapon").
:- pragma foreign_export("C", item_weapon(out, in), "Ilib_CreateItemWeapon").

junk_type(book(_)) = book.
junk_book(book(That), That).
:- pragma foreign_export("C", junk_book(in, out), "Ilib_GetJunkBook").
:- pragma foreign_export("C", junk_book(out, in), "Ilib_CreateJunkBook").

junk_type(gem(_)) = gem.
junk_gem(gem(That), That).
:- pragma foreign_export("C", junk_gem(in, out), "Ilib_GetJunkGem").
:- pragma foreign_export("C", junk_gem(out, in), "Ilib_CreateJunkGem").


read_item(Buffer, I0, IOut, Out) :- 
    get_8(Buffer, I0, ByteI0),
    (
        ByteI0 = 0,
        read_armor(Buffer, I0+1, I1, Child_armor),
        Child = armor(Child_armor)
    ;
        ByteI0 = 1,
        read_consumable(Buffer, I0+1, I1, Child_consumable),
        Child = consumable(Child_consumable)
    ;
        ByteI0 = 2,
        read_junk(Buffer, I0+1, I1, Child_junk),
        Child = junk(Child_junk)
    ;
        ByteI0 = 3,
        read_weapon(Buffer, I0+1, I1, Child_weapon),
        Child = weapon(Child_weapon)
    ),
    get_byte_32(Buffer, I1, Durability),
    I2 - 4 = I1,
    get_8(Buffer, I2, TextSizeI2),
    get_ascii_string(Buffer, I2+1, TextSizeI2, Icon),
    I3 - 1 = TextSizeI2 + I2,
    get_8(Buffer, I3, TextSizeI3),
    get_ascii_string(Buffer, I3+1, TextSizeI3, Model),
    I4 - 1 = TextSizeI3 + I3,
    get_8(Buffer, I4, TextSizeI4),
    get_ascii_string(Buffer, I4+1, TextSizeI4, Name),
    I5 - 1 = TextSizeI4 + I4,
    get_byte_32(Buffer, I5, Value),
    I6 - 4 = I5,
    get_byte_32(Buffer, I6, Weight),
    I7 - 4 = I6,
    IOut = I7,
    Out = item(Child, Durability, Icon, Model, Name, Value, Weight).

write_item(item(Child, Durability, Icon, Model, Name, Value, Weight), !IO) :-
    (
        Child = armor(ChildArmor), io.write_byte(0, !IO),
        write_armor(ChildArmor, !IO)
    ;
        Child = consumable(ChildConsumable), io.write_byte(1, !IO),
        write_consumable(ChildConsumable, !IO)
    ;
        Child = junk(ChildJunk), io.write_byte(2, !IO),
        write_junk(ChildJunk, !IO)
    ;
        Child = weapon(ChildWeapon), io.write_byte(3, !IO),
        write_weapon(ChildWeapon, !IO)
    ),
    int_to_bytes(Durability,Durability0,Durability1,Durability2,Durability3),
    io.write_byte(Durability0, !IO),
    io.write_byte(Durability1, !IO),
    io.write_byte(Durability2, !IO),
    io.write_byte(Durability3, !IO),
    string.length(Icon) = 0+LenIcon,
    io.write_byte(LenIcon, !IO),
    write_string(Icon, 0, LenIcon, !IO),
    string.length(Model) = 0+LenModel,
    io.write_byte(LenModel, !IO),
    write_string(Model, 0, LenModel, !IO),
    string.length(Name) = 0+LenName,
    io.write_byte(LenName, !IO),
    write_string(Name, 0, LenName, !IO),
    int_to_bytes(Value,Value0,Value1,Value2,Value3),
    io.write_byte(Value0, !IO),
    io.write_byte(Value1, !IO),
    io.write_byte(Value2, !IO),
    io.write_byte(Value3, !IO),
    int_to_bytes(Weight,Weight0,Weight1,Weight2,Weight3),
    io.write_byte(Weight0, !IO),
    io.write_byte(Weight1, !IO),
    io.write_byte(Weight2, !IO),
    io.write_byte(Weight3, !IO),
    true.

read_armor(Buffer, I0, IOut, Out) :- 
    get_byte_8(Buffer, I0, IntI0),
    (
        IntI0 = 0,
        Atype = helmet
    ;
        IntI0 = 1,
        Atype = chestplate
    ;
        IntI0 = 2,
        Atype = boots
    ),
    I1 - 1 = I0,
    get_byte_32(Buffer, I1, Defense),
    I2 - 4 = I1,
    IOut = I2,
    Out = armor(Atype, Defense).

write_armor(armor(Atype, Defense), !IO) :-
    (
        Atype = helmet, io.write_byte(0, !IO)
    ;
        Atype = chestplate, io.write_byte(1, !IO)
    ;
        Atype = boots, io.write_byte(2, !IO)
    ),
    int_to_bytes(Defense,Defense0,Defense1,Defense2,Defense3),
    io.write_byte(Defense0, !IO),
    io.write_byte(Defense1, !IO),
    io.write_byte(Defense2, !IO),
    io.write_byte(Defense3, !IO),
    true.

read_consumable(_, !I, consumable).

write_consumable(_, !IO).

read_junk(Buffer, I0, IOut, Out) :- 
    get_8(Buffer, I0, ByteI0),
    (
        ByteI0 = 0,
        read_book(Buffer, I0+1, I1, Child_book),
        Child = book(Child_book)
    ;
        ByteI0 = 1,
        read_gem(Buffer, I0+1, I1, Child_gem),
        Child = gem(Child_gem)
    ),
    IOut = I1,
    Out = junk(Child).

write_junk(junk(Child), !IO) :-
    (
        Child = book(ChildBook), io.write_byte(0, !IO),
        write_book(ChildBook, !IO)
    ;
        Child = gem(ChildGem), io.write_byte(1, !IO),
        write_gem(ChildGem, !IO)
    ),
    true.

read_book(Buffer, I0, IOut, Out) :- 
    get_8(Buffer, I0, TextSizeI0),
    get_ascii_string(Buffer, I0+1, TextSizeI0, Text),
    I1 - 1 = TextSizeI0 + I0,
    IOut = I1,
    Out = book(Text).

write_book(book(Text), !IO) :-
    string.length(Text) = 0+LenText,
    io.write_byte(LenText, !IO),
    write_string(Text, 0, LenText, !IO),
    true.

read_gem(_, !I, gem).

write_gem(_, !IO).

read_weapon(Buffer, I0, IOut, Out) :- 
    get_byte_32(Buffer, I0, Attack),
    I1 - 4 = I0,
    get_byte_32(Buffer, I1, Speed),
    I2 - 4 = I1,
    get_byte_8(Buffer, I2, IntI2),
    (
        IntI2 = 0,
        Wtype = sword
    ;
        IntI2 = 1,
        Wtype = axe
    ),
    I3 - 1 = I2,
    IOut = I3,
    Out = weapon(Attack, Speed, Wtype).

write_weapon(weapon(Attack, Speed, Wtype), !IO) :-
    int_to_bytes(Attack,Attack0,Attack1,Attack2,Attack3),
    io.write_byte(Attack0, !IO),
    io.write_byte(Attack1, !IO),
    io.write_byte(Attack2, !IO),
    io.write_byte(Attack3, !IO),
    int_to_bytes(Speed,Speed0,Speed1,Speed2,Speed3),
    io.write_byte(Speed0, !IO),
    io.write_byte(Speed1, !IO),
    io.write_byte(Speed2, !IO),
    io.write_byte(Speed3, !IO),
    (
        Wtype = sword, io.write_byte(0, !IO)
    ;
        Wtype = axe, io.write_byte(1, !IO)
    ),
    true.


