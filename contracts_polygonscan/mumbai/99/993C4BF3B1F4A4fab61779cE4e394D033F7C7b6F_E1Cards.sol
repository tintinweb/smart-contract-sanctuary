/**
 *Submitted for verification at polygonscan.com on 2022-01-25
*/

pragma solidity >=0.8.11 <0.9.0;
// SPDX-License-Identifier: UNLICENSED
interface IB62 {
    //function toBase(uint val) external pure returns (string memory);
    function toDec(string memory val) external pure returns (uint);
    //function fromBase(string memory val) external pure returns (uint);
}
interface ISWU {
    function toString(uint256 value) external pure returns (string memory);
    //function trim(string memory str) external pure returns (string memory);
    function substring(string memory str, uint begin, uint end) external pure returns (string memory);
}

contract E1Cards {
    address internal constant B62Addr = 0x9f22E8494Abac1Ed098D6dB688d6DdF3ce175749;
    address internal constant SWUAddr = 0x64DC2863476c004B77100935C6C77F574ddfc8f3;
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
        return string(bytes.concat('{"Epoch":', bytes(ISWU(SWUAddr).toString(Epoch(Id))), ', "Id":', bytes(ISWU(SWUAddr).toString(cId(Id))), ', "Rarity":"', bytes(ISWU(SWUAddr).toString(Rarity(Id))), '", "Res1":"', bytes(ISWU(SWUAddr).toString(Res1(Id))), '", "Res2":"', bytes(ISWU(SWUAddr).toString(Res2(Id))), '", "Epoc Restriction":"', bytes(ISWU(SWUAddr).toString(EpocRes(Id))), '", "Type":"', bytes(ISWU(SWUAddr).toString(Type(Id))), '", "Class":"', bytes(ISWU(SWUAddr).toString(Class(Id))), '", "Heart":', bytes(ISWU(SWUAddr).toString(Heart(Id))), ', "Agi":', bytes(ISWU(SWUAddr).toString(Agi(Id))), ', "Int":', bytes(ISWU(SWUAddr).toString(Int(Id))), ', "Mana":', bytes(ISWU(SWUAddr).toString(Mana(Id))), ' }'));
    }
    function _Card(uint Id) internal pure returns (string memory) {
        string[125] memory _Cards = ["1 100  001 4 3 2 1","1 201 c101 4 3 2 1","1 302 1202 3 4 1 2","1 403 2302 3 4 1 2","1 504 3403 2 1 4 3","1 605 a503 2 1 4 3","1 706 b604 1 2 3 4","1 807 c704 1 2 3 4","1 918 d801 8 6 4 2","1 a19 a901 8 6 4 2","1 b1a ba02 6 8 2 4","1 c1b c002 6 8 2 4","1 d1c d003 4 2 8 6","1 e1d  003 4 2 8 6","1 f10  004 2 4 6 8","1 g10  004 2 4 6 8","1 h20  001 c 9 6 3","1 i20  001 c 9 6 3","1 j20  002 9 c 3 6","1 k20  002 8 c 4 6","1 l20  003 6 3 c 9","1 m20  003 5 3 c a","1 n20  004 4 5 9 c","1 o20  004 3 6 9 c","1 p30  001 g c 8 4","1 q30  001 f d 8 4","1 r30  002 d f 4 8","1 s30  002 c g 4 8","1 t30  003 8 4 g c","1 u30  003 7 5 g c","1 v30  004 4 8 b f","1 w30  004 4 8 c g","1 x40  001 k f a 5","1 y40  001 i g b 5","1 z40  002 g j 5 a","1 A40  002 f k 5 a","1 B40  003 a 5 k f","1 C40  003 9 6 k f","1 D40  004 5 a g j","1 E40  004 5 a f k","1 F00  020 4 0 0 0","1 G00  001 4 3 2 1","1 H00  001 4 3 2 1","1 I00  002 3 4 1 2","1 J00  002 3 4 1 2","1 K00  003 2 1 4 3","1 L00  003 2 1 4 3","1 M00  004 1 2 3 4","1 N00  004 1 2 3 4","1 O10  001 8 6 4 2","1 P10  001 8 6 4 2","1 Q10  002 6 8 2 4","1 R10  002 6 8 2 4","1 S10  003 4 2 8 6","1 T10  003 4 2 8 6","1 U10  004 2 4 6 8","1 V10  004 2 4 6 8","1 W20  001 c 9 6 3","1 X20  001 c 9 6 3","1 Y20  002 9 c 3 6","1 Z20  002 8 c 4 6","11020  003 6 3 c 9","11120  003 5 3 c a","11220  004 4 5 9 c","11320  004 3 6 9 c","11430  001 g c 8 4","11530  001 f d 8 4","11630  002 d f 4 8","11730  002 c g 4 8","11830  003 8 4 g c","11930  003 7 5 g c","11a30  004 4 8 b f","11b30  004 4 8 c g","11c40  001 k f a 5","11d40  001 i g b 5","11e40  002 g j 5 a","11f40  002 f k 5 a","11g40  003 a 5 k f","11h40  003 9 6 k f","11i40  004 5 a g j","11j40  004 5 a f k","11k00  020 4 0 0 0","11l00  001 4 3 2 1","11m00  001 4 3 2 1","11n00  002 3 4 1 2","11o00  002 3 4 1 2","11p00  003 2 1 4 3","11q00  003 2 1 4 3","11r00  004 1 2 3 4","11s00  004 1 2 3 4","11t10  001 8 6 4 2","11u10  001 8 6 4 2","11v10  002 6 8 2 4","11w10  002 6 8 2 4","11x10  003 4 2 8 6","11y10  003 4 2 8 6","11z10  004 2 4 6 8","11A10  004 2 4 6 8","11B20  001 c 9 6 3","11C20  001 c 9 6 3","11D20  002 9 c 3 6","11E20  002 8 c 4 6","11F20  003 6 3 c 9","11G20  003 5 3 c a","11H20  004 4 5 9 c","11I20  004 3 6 9 c","11J30  001 g c 8 4","11K30  001 f d 8 4","11L30  002 d f 4 8","11M30  002 c g 4 8","11N30  003 8 4 g c","11O30  003 7 5 g c","11P30  004 4 8 b f","11Q30  004 4 8 c g","11R40  001 k f a 5","11S40  001 i g b 5","11T40  002 g j 5 a","11U40  002 f k 5 a","11V40  003 a 5 k f","11W40  003 9 6 k f","11X40  004 5 a g j","11Y40  004 5 a f k","11Z00  020 4 0 0 0","12000  020 4 0 0 0","12100  020 4 0 0 0"];
        if (Id < 1) { Id = 1; }
        if (Id > _Cards.length) { Id = _Cards.length; }
        return _Cards[(Id - 1)];
    }
    function _Value(uint Id, uint i,uint e) internal pure returns (uint) {
        return IB62(B62Addr).toDec(ISWU(SWUAddr).substring(_Card(Id), i, e));
    }
}