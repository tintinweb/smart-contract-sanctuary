pragma solidity ^0.4.19;
contract Doug{
    mapping (bytes32 => uint) public contracts;
    function Doug() {
        contracts[&#39;hww&#39;] = 1;
        contracts[&#39;brian&#39;] = 2;
        contracts[&#39;zzy&#39;] = 7;
    }
    
    function getDougName(string _name) public view returns(string) {
        return _name;
    }
    
     function getDougAge(uint _age) public pure returns(uint) {
        return 3 ** _age;
    }
}