pragma solidity ^0.5.16;

contract SGCDEXETHSwap {

  using SafeMath for uint;

  address public owner;
  address payable exchangeFeeAddress;
  uint256 exchangeFee;
  uint256 SafeTime = 2 hours; // atomic swap timeOut

  struct Swap {
    address payable targetWallet;
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
    exchangeFee = 1000;
    exchangeFeeAddress = 0x264Ea0F0edCf7D471b41c12540183bc38236Aec6;
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

  event CreateSwap(address _buyer, address _seller, uint256 _value, bytes20 _secretHash, uint256 createdAt);

  // ETH Owner creates Swap with secretHash
  // ETH Owner make Ether deposit
  function createSwap(bytes20 _secretHash, address payable _participantAddress) public payable {
    require(msg.value > 0);
    require(swaps[msg.sender][_participantAddress].balance == uint256(0));

    swaps[msg.sender][_participantAddress] = Swap(
      _participantAddress,
      bytes32(0),
      _secretHash,
      now,
      msg.value
    );

    emit CreateSwap(_participantAddress, msg.sender, msg.value, _secretHash, now);
  }

  // ETH Owner creates Swap with secretHash
  // ETH Owner make Ether deposit
  function createSwapTarget(bytes20 _secretHash, address payable _participantAddress, address payable _targetWallet) public payable {
    require(msg.value > 0);
    require(swaps[msg.sender][_participantAddress].balance == uint256(0));

    swaps[msg.sender][_participantAddress] = Swap(
      _targetWallet,
      bytes32(0),
      _secretHash,
      now,
      msg.value
    );

    emit CreateSwap(_participantAddress, msg.sender, msg.value, _secretHash, now);
  }

  function getBalance(address _ownerAddress) public view returns (uint256) {
    return swaps[_ownerAddress][msg.sender].balance;
  }

  // Get target wallet (buyer check)
  function getTargetWallet(address _ownerAddress) public view returns (address) {
      return swaps[_ownerAddress][msg.sender].targetWallet;
  }

  event Withdraw(address _buyer, address _seller, bytes20 _secretHash, uint256 withdrawnAt);

  // BTC Owner withdraw money and adds secret key to swap
  // BTC Owner receive +1 reputation
  function withdraw(bytes32 _secret, address _ownerAddress) public {
    Swap memory swap = swaps[_ownerAddress][msg.sender];

    require(swap.secretHash == ripemd160(abi.encodePacked(_secret)));
    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) > now);

    uint256 actualValue = swap.balance;
    uint256 tradeFee = actualValue.div(exchangeFee);
    uint256 balanceAfterDeduction = actualValue.sub(tradeFee);

    swap.targetWallet.transfer(balanceAfterDeduction);
    exchangeFeeAddress.transfer(tradeFee);

    swaps[_ownerAddress][msg.sender].balance = 0;
    swaps[_ownerAddress][msg.sender].secret = _secret;

    emit Withdraw(msg.sender, _ownerAddress, swap.secretHash, now);
  }
  // BTC Owner withdraw money and adds secret key to swap
  // BTC Owner receive +1 reputation
  function withdrawNoMoney(bytes32 _secret, address participantAddress) public {
    Swap memory swap = swaps[msg.sender][participantAddress];

    require(swap.secretHash == ripemd160(abi.encodePacked(_secret)));
    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) > now);

    uint256 actualValue = swap.balance;
    uint256 tradeFee = actualValue.div(10**2).mul(exchangeFee);
    uint256 balanceAfterDeduction = actualValue.sub(tradeFee);

    swap.targetWallet.transfer(balanceAfterDeduction);
    exchangeFeeAddress.transfer(tradeFee);

    swaps[msg.sender][participantAddress].balance = 0;
    swaps[msg.sender][participantAddress].secret = _secret;

    emit Withdraw(participantAddress, msg.sender, swap.secretHash, now);
  }
  // BTC Owner withdraw money and adds secret key to swap
  // BTC Owner receive +1 reputation
  function withdrawOther(bytes32 _secret, address _ownerAddress, address participantAddress) public {
    Swap memory swap = swaps[_ownerAddress][participantAddress];

    require(swap.secretHash == ripemd160(abi.encodePacked(_secret)));
    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) > now);

    uint256 actualValue = swap.balance;
    
    uint256 tradeFee = actualValue.div(exchangeFee);
    uint256 balanceAfterDeduction = actualValue.sub(tradeFee);

    swap.targetWallet.transfer(balanceAfterDeduction);
    exchangeFeeAddress.transfer(tradeFee);

    swaps[_ownerAddress][participantAddress].balance = 0;
    swaps[_ownerAddress][participantAddress].secret = _secret;

    emit Withdraw(participantAddress, _ownerAddress, swap.secretHash, now);
  }

  // ETH Owner receive secret
  function getSecret(address _participantAddress) public view returns (bytes32) {
    return swaps[msg.sender][_participantAddress].secret;
  }

  event Close(address _buyer, address _seller);



  event Refund(address _buyer, address _seller, bytes20 _secretHash);

  // ETH Owner refund money
  // BTC Owner gets -1 reputation
  function refund(address _participantAddress) public {
    Swap memory swap = swaps[msg.sender][_participantAddress];

    require(swap.balance > uint256(0));
    require(swap.createdAt.add(SafeTime) < now);

    msg.sender.transfer(swap.balance);

    clean(msg.sender, _participantAddress);

    emit Refund(_participantAddress, msg.sender, swap.secretHash);
  }

  function clean(address _ownerAddress, address _participantAddress) internal {
    delete swaps[_ownerAddress][_participantAddress];
    delete participantSigns[_ownerAddress][_participantAddress];
  }
}

library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}