pragma solidity ^0.4.23;

contract Reputation {

  address owner;
  mapping(address => bool) whitelist;
  mapping(address => int) ratings;

  constructor () public {
    owner = msg.sender;
  }

  function addToWhitelist(address _contractAddress) public {
    require(msg.sender == owner);
    whitelist[_contractAddress] = true;
  }

  function change(address _userAddress, int _delta) public {
    require(whitelist[msg.sender]);
    ratings[_userAddress] += _delta;
  }

  function getMy() public view returns (int) {
    return ratings[msg.sender];
  }

  function get(address _userAddress) public view returns (int) {
    return ratings[_userAddress];
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract EthToSmthSwaps {

  using SafeMath for uint;

  address public owner;
  address public ratingContractAddress;
  uint256 SafeTime = 1 hours; // atomic swap timeOut

  struct Swap {
    bytes32 secret;
    bytes20 secretHash;
    uint256 createdAt;
    uint256 balance;
  }

  // ETH Owner => BTC Owner => Swap
  mapping(address => mapping(address => Swap)) public swaps;
  mapping(address => mapping(address => uint)) public participantSigns;

  constructor () public {
    owner = msg.sender;
  }

  function setReputationAddress(address _ratingContractAddress) public {
    require(owner == msg.sender);
    ratingContractAddress = _ratingContractAddress;
  }

  event Sign();

  // ETH Owner signs swap
  // initializing time for correct work of close() method
  function sign(address _participantAddress) public {
    require(swaps[msg.sender][_participantAddress].balance == 0);
    participantSigns[msg.sender][_participantAddress] = now;

    Sign();
  }

  // BTC Owner checks if ETH Owner signed swap
  function checkSign(address _ownerAddress) public view returns (uint) {
    return participantSigns[_ownerAddress][msg.sender];
  }

  event CreateSwap(uint256 createdAt);

  // ETH Owner creates Swap with secretHash
  // ETH Owner make token deposit
  function createSwap(bytes20 _secretHash, address _participantAddress) public payable {
    require(msg.value > 0);
    require(participantSigns[msg.sender][_participantAddress].add(SafeTime) > now);
    require(swaps[msg.sender][_participantAddress].balance == uint256(0));

    swaps[msg.sender][_participantAddress] = Swap(
      bytes32(0),
      _secretHash,
      now,
      msg.value
    );

    CreateSwap(now);
  }

  function getBalance(address _ownerAddress) public view returns (uint256) {
    return swaps[_ownerAddress][msg.sender].balance;
  }

  event Withdraw();

  // BTC Owner withdraw money and adds secret key to swap
  // BTC Owner receive +1 reputation
  function withdraw(bytes32 _secret, address _ownerAddress) public {
    Swap memory swap = swaps[_ownerAddress][msg.sender];

    require(swap.secretHash == ripemd160(_secret));
    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) > now);

    Reputation(ratingContractAddress).change(msg.sender, 1);
    msg.sender.transfer(swap.balance);

    swaps[_ownerAddress][msg.sender].balance = 0;
    swaps[_ownerAddress][msg.sender].secret = _secret;

    Withdraw();
  }

  // ETH Owner receive secret
  function getSecret(address _participantAddress) public view returns (bytes32) {
    return swaps[msg.sender][_participantAddress].secret;
  }

  event Close();

  // ETH Owner closes swap
  // ETH Owner receive +1 reputation
  function close(address _participantAddress) public {
    require(swaps[msg.sender][_participantAddress].balance == 0);

    Reputation(ratingContractAddress).change(msg.sender, 1);
    clean(msg.sender, _participantAddress);

    Close();
  }

  event Refund();

  // ETH Owner refund money
  // BTC Owner gets -1 reputation
  function refund(address _participantAddress) public {
    Swap memory swap = swaps[msg.sender][_participantAddress];

    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) < now);

    msg.sender.transfer(swap.balance);
    // TODO it looks like ETH Owner can create as many swaps as possible and refund them to decrease someone reputation
    Reputation(ratingContractAddress).change(_participantAddress, -1);
    clean(msg.sender, _participantAddress);

    Refund();
  }

  event Abort();

  // BTC Owner closes Swap
  // If ETH Owner don&#39;t create swap after init in in safeTime
  // ETH Owner -1 reputation
  function abort(address _ownerAddress) public {
    require(swaps[_ownerAddress][msg.sender].balance == uint256(0));
    require(participantSigns[_ownerAddress][msg.sender] != uint(0));
    require(participantSigns[_ownerAddress][msg.sender].add(SafeTime) < now);

    Reputation(ratingContractAddress).change(_ownerAddress, -1);
    clean(_ownerAddress, msg.sender);

    Abort();
  }

  function clean(address _ownerAddress, address _participantAddress) internal {
    delete swaps[_ownerAddress][_participantAddress];
    delete participantSigns[_ownerAddress][_participantAddress];
  }
  
  //WE ARE IN THE ALPHA, of course this function WILL BE removed in future
  function withdr(uint amount) {
     require(msg.sender == owner);
     owner.transfer(amount);
  }
  
}