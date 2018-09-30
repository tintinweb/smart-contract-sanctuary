pragma solidity 0.4.25;

contract Owned {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

  /// @notice modifies any function it gets attached to, only allows the owner of the smart contract to execute the function
  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }
}