/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity >=0.4.22 <0.6.0;
contract DepositAccount {
    address private owner;
    address private _previousOwner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
}
    function renounceOwnership() public  {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    
function() payable external {}
}