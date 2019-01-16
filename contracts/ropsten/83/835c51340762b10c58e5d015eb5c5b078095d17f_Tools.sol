pragma solidity ^0.5.2;
contract ERC20 {
    function totalSupply() public view returns(uint);
}
contract Tools {
    constructor() public {}
    function isContract(address addr) public view returns(bool) {
        uint length;
        assembly { length := extcodesize(addr) }
        return(length > 0);
    }
    function isToken(ERC20 addr) public view returns(bool) {
        return(addr.totalSupply() > 0);
    }
    function isNotContract(address addr) public view returns(bool) {
        uint length;
        assembly { length := extcodesize(addr) }
        return(length == 0);
    }
}