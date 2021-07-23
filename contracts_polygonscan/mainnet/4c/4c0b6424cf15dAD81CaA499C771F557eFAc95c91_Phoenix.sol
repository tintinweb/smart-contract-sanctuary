/**
 *Submitted for verification at polygonscan.com on 2021-07-22
*/

pragma solidity 0.8.6;

contract Phoenix {
    address owner;
    
    constructor(address _address) {
        owner = _address;
    }
    
    function destroy() public {
        require(msg.sender == owner);
        selfdestruct(payable(owner));
    }
}