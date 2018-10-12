pragma solidity ^0.4.23;

contract Ownable {

  address public owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract RootInBlocks is Ownable {

  mapping(string => uint) map;

  event Added(
    string hash,
    uint time
  );

  function put(string hash) public onlyOwner {
    require(map[hash] == 0);
    map[hash] = block.timestamp;
    emit Added(hash, block.timestamp);
  }

  function get(string hash) public constant returns(uint) {
    return map[hash];
  }

}