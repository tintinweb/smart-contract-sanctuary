/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

pragma solidity ^ 0.5.0;

contract Calculator {
    uint256 public number;
    address public sender;
    
    constructor() public {
        number = 0;
    }
    
    function add(uint256 _x) public returns(uint256, address)  {
        require(_x > 0 && _x <10, "error");
        sender = msg.sender;
        number = _x;
        return (number, sender);
    }
}