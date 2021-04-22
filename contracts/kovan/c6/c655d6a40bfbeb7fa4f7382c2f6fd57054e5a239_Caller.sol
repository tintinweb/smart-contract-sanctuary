/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.4.24;

    contract Caller {
        
        function someAction(address addr) public pure returns(uint) {
            Callee c = Callee(addr); return c.getValue(100); 
        }
        
        function storeAction(address addr) public returns(uint) {
            Callee c = Callee(addr); 
            c.storeValue(100); 
            return c.getValues();
        }
        
        function someUnsafeAction(address addr) public {
            addr.call(bytes4(keccak256("storeValue(uint256)")), 100); 
            
        } 
        
    } 
    
    contract Callee {
        function getValue(uint initialValue) public pure returns(uint);
        function storeValue(uint value) public;
        function getValues() public view returns(uint) ; 
    }