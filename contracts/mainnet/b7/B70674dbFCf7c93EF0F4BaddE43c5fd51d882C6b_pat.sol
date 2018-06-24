pragma solidity ^0.4.23;

contract PTC {
    function balanceOf(address _owner) constant public returns (uint256);
}

contract pat {
    address public ptc_addr = 0xeCa906474016f727D1C2Ec096046C03eAc4Aa085;
    PTC ptc_ins = PTC(ptc_addr);
    
    constructor() public{
        
    }
    
    function get_ptc_count(address addr) constant public returns(uint256) {
        return ptc_ins.balanceOf(addr);
    }
}