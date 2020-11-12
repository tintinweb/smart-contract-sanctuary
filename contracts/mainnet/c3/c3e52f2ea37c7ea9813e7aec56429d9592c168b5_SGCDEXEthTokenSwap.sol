pragma solidity ^0.5.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract ERC20 {
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);
}

contract SGCDEXEthTokenSwap {

  using SafeMath for uint;

  address public owner;
  address payable exchangeFeeAddress;
  uint256 exchangeFee;
  uint256 SafeTime = 2 hours; 

  struct Swap {
    address token;
    bytes32 secret;
    bytes20 secretHash;
    uint256 createdAt;
    uint256 balance;
  }

  mapping(address => mapping(address => Swap)) public swaps;

  constructor () public {
    owner = msg.sender;
    exchangeFee = 1000;
    exchangeFeeAddress = 0x7BC4E25bdB535294F59646ff6c31f356888d5053;
  }

  function updateExchangeFeeAddress (address payable newAddress) public returns (bool status) {
    require(owner == msg.sender);
    exchangeFeeAddress = newAddress;
    return true;
  }

  function updateExchangeFee (uint256 newExchangeFee) public returns (bool status) {
    require(owner == msg.sender);
    exchangeFee = newExchangeFee;
    return true;
  }

  event CreateSwap(uint256 createdAt);

  function createSwap(bytes20 _secretHash, address _participantAddress, uint256 _value, address _token) public {
    require(_value > 0);
    require(swaps[msg.sender][_participantAddress].balance == uint256(0));
    require(ERC20(_token).transferFrom(msg.sender, address(this), _value));

    swaps[msg.sender][_participantAddress] = Swap(
      _token,
      bytes32(0),
      _secretHash,
      now,
      _value
    );

    emit CreateSwap(now);
  }

  function getBalance(address _ownerAddress) public view returns (uint256) {
    return swaps[_ownerAddress][msg.sender].balance;
  }

  event Withdraw();

  function withdraw(bytes32 _secret, address _ownerAddress) public {
    Swap memory swap = swaps[_ownerAddress][msg.sender];

    require(swap.secretHash == ripemd160(abi.encodePacked(_secret)));
    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) > now);

    require(swap.secretHash == ripemd160(abi.encodePacked(_secret)));
    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) > now);

    uint256 actualValue = swap.balance;

    uint256 tradeFee = actualValue.div(exchangeFee);
    uint256 balanceAfterDeduction = actualValue.sub(tradeFee);

    ERC20(swap.token).transfer(msg.sender, balanceAfterDeduction);
    ERC20(swap.token).transfer(exchangeFeeAddress, tradeFee);
    
    swaps[_ownerAddress][msg.sender].balance = 0;
    swaps[_ownerAddress][msg.sender].secret = _secret;

    emit Withdraw();
  }

  function getSecret(address _participantAddress) public view returns (bytes32) {
    return swaps[msg.sender][_participantAddress].secret;
  }

  event Refund();

  function refund(address _participantAddress) public {
    Swap memory swap = swaps[msg.sender][_participantAddress];

    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) < now);

    ERC20(swap.token).transfer(msg.sender, swap.balance);
    clean(msg.sender, _participantAddress);

    emit Refund();
  }

  function clean(address _ownerAddress, address _participantAddress) internal {
    delete swaps[_ownerAddress][_participantAddress];
  }
}