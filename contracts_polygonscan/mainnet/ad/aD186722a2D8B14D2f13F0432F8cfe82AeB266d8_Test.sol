/**
 *Submitted for verification at polygonscan.com on 2021-08-17
*/

pragma solidity >=0.6.0;

contract Test {
    address public owner;
    address public shower;
    
    modifier onlyOwner(){
        require(msg.sender == owner, "onlyOwner");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }
    
    function setShower(address _shower) external onlyOwner {
        shower = _shower;
    }
}