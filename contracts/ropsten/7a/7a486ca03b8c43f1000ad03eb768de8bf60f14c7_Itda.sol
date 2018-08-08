pragma solidity ^0.4.0;
contract Itda {
 
    uint256 private uintField1 = 0;
    uint256 private uintField2 = 0;
    uint256 private uintField3 = 0;
    string  private strField1 = "";
    string  private strField2 = "";
    string  private strField3 = "";
    bool private boolField1 = false;
    bool private boolField2 = false;
    bool private boolField3 = false;
    
    int private intField1 = 0;
    int private intField2 = 0;
    int private intField3 = 0;
    address private addressField1 = 0;
    address private addressField2 = 0;
    address private addressField3 = 0;
    int[] private arrIntField1 ;
    int[] private arrIntField2 ;
    int[] private arrIntField3 ;
    uint[] private arrUintField1 ;
    uint[] private arrUintField2 ;
    uint[] private arrUintField3 ;
    bool[] private arrBoolField1 ;
    bool[] private arrBoolField2 ;
    bool[] private arrBoolField3 ;
    
    function getIntField1() public constant returns (int) {
        return intField1;
    }
    
    function getIntField2() public constant returns (int) {
        return intField2;
    }
    
    function getIntField3() public constant returns (int) {
        return intField3;
    }
    
     
    function getAddressField1() public constant returns (address) {
        return addressField1;
    }
    
    function getAddressField2() public constant returns (address) {
        return addressField2;
    }
    
    function getAddressField3() public constant returns (address) {
        return addressField3;
    }
     
    function getArrIntField1() public constant returns (int[]) {
        return arrIntField1;
    }
    
    function getArrIntField2() public constant returns (int[]) {
        return arrIntField2;
    }
    
    function getArrIntField3() public constant returns (int[]) {
        return arrIntField3;
    }
     
    function getArrUintField1() public constant returns (uint[]) {
        return arrUintField1;
    }
    
    function getArrUintField2() public constant returns (uint[]) {
        return arrUintField2;
    }
    
    function getArrUintField3() public constant returns (uint[]) {
        return arrUintField3;
    }
    
    function getArrBoolField1() public constant returns (bool[]) {
        return arrBoolField1;
    }
    
    function getArrBoolField2() public constant returns (bool[]) {
        return arrBoolField2;
    }
    
    function getArrBoolField3() public constant returns (bool[]) {
        return arrBoolField3;
    }
    
    
    
    
    
    function setUintF1IntF3AddressF3(uint256 f1, int f2, address f3) public {
        uintField1 = f1;
        intField3 = f2;
        addressField3 = f3;
    }
    
    function setBoolF1UintF1StrF2Intf3(bool f1, uint256 f2, string f3, int f4 ) public {
        boolField1 = f1;
        uintField1 = f2;
        strField2  = f3;
        intField3  = f4;
    }
    
    function setStrF1IntF2StrF2UintF2(string f1, int f2, string f3, uint256 f4) public {
        strField1 = f1;
        intField2 = f2;
        strField2 = f3;
        uintField2 = f4;
    }
    function setArrIntF2ArrUintF3ArrBoolF1(int[] f1, uint256[] f2, bool[] f3) public {
        arrIntField2 = f1;
        arrUintField3 = f2;
        arrBoolField1 = f3;
    }
    function setArrIntF1StrF2(int[] f1, string f2) public {
        arrIntField1 = f1;
        strField2 = f2;
    }
    function setIntF1ArrBoolF2AddressF1(int f1, bool[] f2,address f3) public {
        intField1 = f1;
        arrBoolField2 = f2;
        addressField1 = f3;
    }
    

    
    
    
    
    
    
    
    
    
    
    
    
    function getUintField2() public constant returns (uint256) {
        return uintField2;
    }
    
    function getUintField3() public constant returns (uint256) {
        return uintField3;
    }
    
    function getStrField1() public constant returns (string) {
        return strField1;
    }
    
    function getStrField2() public constant returns (string) {
        return strField2;
    }
    
    function getStrField3() public constant returns (string) {
        return strField3;
    }
    
    
    function getBoolField1() public constant returns (bool) {
        return boolField1;
    }
    
    function getBoolField2() public constant returns (bool) {
        return boolField2;
    }
    
    function getBoolField3() public constant returns (bool) {
        return boolField3;
    }
    
    function setUintF1(uint256 f1) public {
        uintField1 = f1;
    }
    
    function setUintF1F2(uint256 f1, uint256 f2) public {
        uintField1 = f1;
        uintField2 = f2;
    }
    
    
    function setUintF1F2F3(uint256 f1, uint256 f2, uint256 f3) public {
        uintField1 = f1;
        uintField2 = f2;
        uintField3 = f3;
    }
    
    
    function setStrF1(string f1) public {
        strField1 = f1;
    }
    
    function setStrF1F2(string f1, string f2) public {
        strField1 = f1;
        strField2 = f2;
    }
    
    
    function setStrF1F2F3(string f1, string f2, string f3) public {
        strField1 = f1;
        strField2 = f2;
        strField3 = f3;
    }
    
    function setBoolF1(bool f1) public {
        boolField1 = f1;
    }
    
    
    function setIntF1(int f1) public {
        intField1 = f1;
    }
    
    
    function setIntF1F2(int f1, int f2) public {
        intField1 = f1;
        intField2 = f2;
    }
    
    
    function setAddressF1(address f1) public {
        addressField1 = f1;   
    }
    
    
    function setAddressF1F2(address f1, address f2) public {
        addressField1 = f1;
        addressField2 = f2;
        
    }
    
    function setArrIntField1(int[] f1) public {
        arrIntField1 = f1;   
    }
    
    function setArrUintField1(uint256[] f1) public {
        arrUintField1 = f1;   
    }
    function setArrBoolField1(bool[] f1) public {
        arrBoolField1 = f1;   
    }
    

    
    function setBoolF1F2(bool f1, bool f2) public {
        boolField1 = f1;
        boolField2 = f2;
    }
    
    
    function setBoolF1F2F3(bool f1, bool f2, bool f3) public {
        boolField1 = f1;
        boolField2 = f2;
        boolField3 = f3;
    }
}