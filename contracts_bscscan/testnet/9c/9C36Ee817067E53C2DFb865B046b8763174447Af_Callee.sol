/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity ^0.4.11;

contract Callee { 
    event log_uint(uint _size);
    event log_address(address _address);
    event log(bytes bb,address _contract);
    uint[] public values; 

    function getValue(uint initial) public pure returns(uint) {
        return initial + 150;
    }
    function storeValue(uint value) public {
        values.push(value);
    }
    function getValues() public view returns(uint) {
        return values.length;
    }
    function getAddresss() public view returns(address) {
        return tx.origin;
    }
    
    function bet() public {
          
        
       //emit log_address(0xd6CA26a25b77e95B860fD8a9E26904aBCE6E8707); 
        
        uint size;
        assembly { size := codesize() }
        emit log_uint(size);

        address ad = 0xd6CA26a25b77e95B860fD8a9E26904aBCE6E8707;
        assembly { size := extcodesize(ad) }
        emit log_uint(size);
        
         
        
    }
    
}