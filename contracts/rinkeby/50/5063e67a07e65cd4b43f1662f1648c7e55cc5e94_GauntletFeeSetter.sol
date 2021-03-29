/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity ^0.7.0;

contract PoolTest {
    uint public fee;
    function setSwapFee(uint _fee) public {
        fee = _fee;
    }
}

contract GauntletFeeSetter {
    function getFee(address addr) public view returns(uint) {
        PoolTest c = PoolTest(addr);
        return c.fee();
    }
    
    function setSwapFee(address addr, uint _fee) public {
        PoolTest c = PoolTest(addr);
        c.setSwapFee(_fee);
    }
    
    function setFees(address[] calldata addr, uint256[] calldata _fee) public {
        for (uint i = 0; i < addr.length; i++) {
            PoolTest c = PoolTest(addr[i]);
            c.setSwapFee(_fee[i]);
        }
    }
}