/**
 *Submitted for verification at polygonscan.com on 2022-01-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.11 <0.9.0;
library SWUtils {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) { return "0"; }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    function trim(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory res = new bytes(strBytes.length);
        uint i1 = 0;
        for(uint i2 = 0; i2 < strBytes.length; i2++) {
            if(strBytes[i2] != " ") {
                res[i1] = strBytes[i2];
                i1++;
            }
        }
        bytes memory res2 = new bytes(i1);
        for(uint i3 = 0; i3 < i1; i3++) { res2[i3] = res[i3]; }
        return string(res2);
    }
    function substring(string memory str, uint begin, uint end) internal pure returns (string memory) {
        bytes memory a = new bytes(end - begin + 1);
        for(uint i = 0; i <= (end - begin); i++){
            a[i] = bytes(str)[i+begin-1];
        }
        return string(a);    
    }
}
library Base62Library {
    using SWUtils for *;
    string internal constant __B62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    function _radix62(uint val) internal pure returns (uint ) {
        for (uint i = 1; i <= 43; i++) {
            if (val < (62**i)) { return uint(i); }
        }
        return uint(32);
    }
    function toBase(uint val) public pure returns (string memory) {
        uint r = _radix62(val);
        bytes memory res = new bytes(r);
        if (val == 0) { return "0"; }
        else {
            bytes memory strBytes = bytes(__B62);
            for (uint i = 0; i < r; i++) {
                res[r - (i + 1)] = strBytes[(val % 62)];
                val = (val / 62);
            }
        }
        return string(res);
    }
    function toDec(string memory val) public pure returns (uint) { return fromBase(val); }
    function fromBase(string memory val) internal pure returns (uint) {
        val = val.trim();
        bytes memory valB = bytes(val);
        uint res = 0;
        for (uint i = 0; i < valB.length; i++) {
            bytes memory strBytes = bytes(__B62);
            for (uint i2 = 0; i2 < strBytes.length; i2++) {
                if(strBytes[i2] == valB[i]) {
                    res = (res * 62) + i2;
                }
            }
         }
         return res;
    }
}
contract _Base62 {
    using Base62Library for *;
    function toBase(uint val) public pure returns (string memory) { return val.toBase(); }
    function toDec(string memory val) public pure returns (uint) { return val.toDec(); }
    function fromBase(string memory val) public pure returns (uint)  { return val.fromBase(); }
}
contract E1Cards {
    using SWUtils for *;
    using Base62Library for *;
    _Base62 private Base62;
    function Epoch(uint Id) public pure returns (uint) {    //1b
        return _Value(Id, 0, 1);
    }
    function cId(uint Id) public pure returns (uint) {   //2b
        return _Value(Id, 1, 3);
    }
    function Rarity(uint Id) public pure returns (uint) {   //1b
        return _Value(Id, 3, 4);
    }
    function Res1(uint Id) public pure returns (uint) {    //1b  //LimitId
        return _Value(Id, 4, 5);
    }
    function Res2(uint Id) public pure returns (uint) {    //2b  //SubId
        return _Value(Id, 5, 7);
    }
    function EpocRes(uint Id) public pure returns (uint) { //1b //EpocRestriction
        return _Value(Id, 7, 8);
    }
    function Type(uint Id) public pure returns (uint) {     //1b
        return _Value(Id, 8, 9);
    }
    function Class(uint Id) public pure returns (uint) {    //1b
        return _Value(Id, 9, 10);
    }
    function Heart(uint Id) public pure returns (uint) {   //2b
        return _Value(Id, 10, 12);
    }
    function Agi(uint Id) public pure returns (uint) {     //2b
        return _Value(Id, 12, 14);
    }
    function Int(uint Id) public pure returns (uint) {     //2b
        return _Value(Id, 14, 16);
    }
    function Mana(uint Id) public pure returns (uint) {    //2b
        return _Value(Id, 16, 18);
    }
    function toJson(uint Id) public pure returns (string memory) { //3b
        return string(bytes.concat('{"Epoch":', bytes(Epoch(Id).toString()), ', "Id":', bytes(cId(Id).toString()), ', "Rarity":"', bytes(Rarity(Id).toString()), '", "Res1":"', bytes(Res1(Id).toString()), '", "Res2":"', bytes(Res2(Id).toString()), '", "Epoc Restriction":"', bytes(EpocRes(Id).toString()), '", "Type":"', bytes(Type(Id).toString()), '", "Class":"', bytes(Class(Id).toString()), '", "Heart":', bytes(Heart(Id).toString()), ', "Agi":', bytes(Agi(Id).toString()), ', "Int":', bytes(Int(Id).toString()), ', "Mana":', bytes(Mana(Id).toString()), ' }'));
    }
    function _Card(uint Id) internal pure returns (string memory) {
        string[125] memory _Cards = ["1 100  001 4 3 2 1","1 201 c101 4 3 2 1","1 302 1202 3 4 1 2","1 403 2302 3 4 1 2","1 504 3403 2 1 4 3","1 605 a503 2 1 4 3","1 706 b604 1 2 3 4","1 807 c704 1 2 3 4","1 918 d801 8 6 4 2","1 a19 a901 8 6 4 2","1 b1a ba02 6 8 2 4","1 c1b c002 6 8 2 4","1 d1c d003 4 2 8 6","1 e1d  003 4 2 8 6","1 f10  004 2 4 6 8","1 g10  004 2 4 6 8","1 h20  001 c 9 6 3","1 i20  001 c 9 6 3","1 j20  002 9 c 3 6","1 k20  002 8 c 4 6","1 l20  003 6 3 c 9","1 m20  003 5 3 c a","1 n20  004 4 5 9 c","1 o20  004 3 6 9 c","1 p30  001 g c 8 4","1 q30  001 f d 8 4","1 r30  002 d f 4 8","1 s30  002 c g 4 8","1 t30  003 8 4 g c","1 u30  003 7 5 g c","1 v30  004 4 8 b f","1 w30  004 4 8 c g","1 x40  001 k f a 5","1 y40  001 i g b 5","1 z40  002 g j 5 a","1 A40  002 f k 5 a","1 B40  003 a 5 k f","1 C40  003 9 6 k f","1 D40  004 5 a g j","1 E40  004 5 a f k","1 F00  020 4 0 0 0","1 G00  001 4 3 2 1","1 H00  001 4 3 2 1","1 I00  002 3 4 1 2","1 J00  002 3 4 1 2","1 K00  003 2 1 4 3","1 L00  003 2 1 4 3","1 M00  004 1 2 3 4","1 N00  004 1 2 3 4","1 O10  001 8 6 4 2","1 P10  001 8 6 4 2","1 Q10  002 6 8 2 4","1 R10  002 6 8 2 4","1 S10  003 4 2 8 6","1 T10  003 4 2 8 6","1 U10  004 2 4 6 8","1 V10  004 2 4 6 8","1 W20  001 c 9 6 3","1 X20  001 c 9 6 3","1 Y20  002 9 c 3 6","1 Z20  002 8 c 4 6","11020  003 6 3 c 9","11120  003 5 3 c a","11220  004 4 5 9 c","11320  004 3 6 9 c","11430  001 g c 8 4","11530  001 f d 8 4","11630  002 d f 4 8","11730  002 c g 4 8","11830  003 8 4 g c","11930  003 7 5 g c","11a30  004 4 8 b f","11b30  004 4 8 c g","11c40  001 k f a 5","11d40  001 i g b 5","11e40  002 g j 5 a","11f40  002 f k 5 a","11g40  003 a 5 k f","11h40  003 9 6 k f","11i40  004 5 a g j","11j40  004 5 a f k","11k00  020 4 0 0 0","11l00  001 4 3 2 1","11m00  001 4 3 2 1","11n00  002 3 4 1 2","11o00  002 3 4 1 2","11p00  003 2 1 4 3","11q00  003 2 1 4 3","11r00  004 1 2 3 4","11s00  004 1 2 3 4","11t10  001 8 6 4 2","11u10  001 8 6 4 2","11v10  002 6 8 2 4","11w10  002 6 8 2 4","11x10  003 4 2 8 6","11y10  003 4 2 8 6","11z10  004 2 4 6 8","11A10  004 2 4 6 8","11B20  001 c 9 6 3","11C20  001 c 9 6 3","11D20  002 9 c 3 6","11E20  002 8 c 4 6","11F20  003 6 3 c 9","11G20  003 5 3 c a","11H20  004 4 5 9 c","11I20  004 3 6 9 c","11J30  001 g c 8 4","11K30  001 f d 8 4","11L30  002 d f 4 8","11M30  002 c g 4 8","11N30  003 8 4 g c","11O30  003 7 5 g c","11P30  004 4 8 b f","11Q30  004 4 8 c g","11R40  001 k f a 5","11S40  001 i g b 5","11T40  002 g j 5 a","11U40  002 f k 5 a","11V40  003 a 5 k f","11W40  003 9 6 k f","11X40  004 5 a g j","11Y40  004 5 a f k","11Z00  020 4 0 0 0","12000  020 4 0 0 0","12100  020 4 0 0 0"];
        if (Id < 1) { Id = 1; }
        if (Id > _Cards.length) { Id = _Cards.length; }
        return _Cards[(Id - 1)];
    }
    function _Value(uint Id, uint i,uint e) internal pure returns (uint) {
        //return _Card(Id).toDec().substring(i, e);
        return _Card(Id).substring(i, e).toDec();
    }
}
contract E1Cards_Des {
    using SWUtils for *;
    E1Cards private cds;
    function Epoch(uint Id) public view returns (uint) { return cds.Epoch(Id); }
    function cId(uint Id) public view returns (uint) { return cds.cId(Id); }
    function Rarity(uint Id) public view returns (uint) { return cds.Rarity(Id); }
    function Res1(uint Id) public view returns (uint) { return cds.Res1(Id); }
    function Res2(uint Id) public view returns (uint) { return cds.Res2(Id); }
    function EpocRes(uint Id) public view returns (uint) { return cds.EpocRes(Id); }
    function Type(uint Id) public view returns (uint) { return cds.Type(Id); }
    function Class(uint Id) public view returns (uint) { return cds.Class(Id); }
    function Heart(uint Id) public view returns (uint) { return cds.Heart(Id); }
    function Agi(uint Id) public view returns (uint) { return cds.Agi(Id); }
    function Int(uint Id) public view returns (uint) { return cds.Int(Id); }
    function Mana(uint Id) public view returns (uint) { return cds.Mana(Id); }
    function Rarity_Des(uint Id) public pure returns (string memory) {
        string[5] memory _Rarities = ["Common","Uncommon","Rare","Epic","Legendary"];
        return _Rarities[Id];
    }
    function Type_Des(uint Id) public pure returns (string memory) {
        string[6] memory _Types = ["Shibatar","Equip","Artifact","Special Action","Land","Building"];
        return _Types[Id];
    }
    function Class_Des(uint Id) public pure returns (string memory) {
        string[6] memory _Classes = ["None","Fighter","Explorer","Scientist","Wizard","Fluid"];
        return _Classes[Id];
    }
    function Stat_Des(uint Id) public pure returns (string memory) {
        string[4] memory _Stats = ["Heart","Agi","Int","Mana"];
        return _Stats[Id];
    }
    function EpocRes_Des(uint Id) public view returns (string memory) {
        uint E = cds.EpocRes(Id);  //ToDo: ...
        return E == 0 ? "All Epoch" : string(bytes.concat("Only Epoch ", bytes(E.toString()) ) );
    }
    function Restriction(uint Id) public view returns (string memory) { //3b
        string[3] memory _Restrictions = ["None","Only Card:","Only"];
        uint d1 = cds.Res1(Id); //LimitId
        uint d2 = cds.Res2(Id); //SubId
        if (d1 == 0) {
            return _Restrictions[0];
        } else if (d1 == 1) {
            return string(bytes.concat(bytes(_Restrictions[1]), " ", bytes( d2.toString() ) ) );
            //return _Restrictions[1] + string(d2);
        } else if (d1 == 2) {
            return string(bytes.concat(bytes(_Restrictions[2]), " ", bytes(Rarity_Des(d2))));
            //return _Restrictions[2] + Rarity_Des[d2];
        } else if (d1 == 3) {
            return string(bytes.concat(bytes(_Restrictions[2]), " ", bytes(Type_Des(d2))));
            //return _Restrictions[2] + Type_Des[d2];
        } else if (d1 == 4) {
            return string(bytes.concat(bytes(_Restrictions[2]), " ", bytes(Class_Des(d2))));
            //return _Restrictions[2] + Class_Des[d2];
        } else if (d1 > 4 && d1 < 9) {
            return string(bytes.concat(bytes(_Restrictions[2]), bytes(Stat_Des(d1 - 5)), " > ", bytes(d2.toString()) ) );
            //return _Restrictions[2] + Stat_Des[(d1 - 5)] + " > " + string(d2);
        } else if (d1 > 8 && d1 < 13) {
            return string(bytes.concat(bytes(_Restrictions[2]), bytes(Stat_Des(d1 - 9)), " > ", bytes(d2.toString()) ) );
            //return _Restrictions[2] + Stat_Des[(d1 - 9)] + " < " + string(d2);
        } else { return _Restrictions[0]; } //Unhandled value
    }
    function toJson_Des(uint Id) public view returns (string memory) { //3b
        return string(bytes.concat('{"Epoch":', bytes(cds.Epoch(Id).toString()), ', "Id":', bytes(cds.cId(Id).toString()), ', "Rarity":"', bytes(Rarity_Des(Id)), '", "Restriction":"', bytes(Restriction(Id)), '", "Epoc Restriction":"', bytes(EpocRes_Des(Id)), '", "Type":"', bytes(Type_Des(Id)), '", "Class":"', bytes(Class_Des(Id)), '", "Heart":', bytes(cds.Heart(Id).toString()), ', "Agi":', bytes(cds.Agi(Id).toString()), ', "Int":', bytes(cds.Int(Id).toString()), ', "Mana":', bytes(cds.Mana(Id).toString()), ' }'));
    }
    // function Concat(string memory a, string memory b) internal pure returns (string memory) {
    //     return string(bytes.concat(bytes(a), "-", bytes(b)));
    // }
}