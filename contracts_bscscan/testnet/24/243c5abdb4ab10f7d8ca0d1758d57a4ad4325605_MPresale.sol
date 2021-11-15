pragma solidity ^0.5.16;

import "../utils/SafeMath.sol";
import "../utils/Pausable.sol";

contract MPresale is Pausable {
  struct Adopters {
    bool isAdopted;
  }

  using SafeMath for uint256;

  // No Monstas can be adopted after this end date: Tuesday, September 14, 2021 11:05:13 PM GMT+08:00
  uint256 constant public PRESALE_END_TIMESTAMP = 1631631913;
  uint256 constant public INITIAL_PRICE_INCREMENT = 383325347388596 wei; // 0.0003833253473885961 BNB
  uint256 constant public INITIAL_PRICE = 200000000000000000; // 0.2 BNB
  uint256 constant public MAX_TOTAL_ADOPTED_MONSTA = 2088;
  uint256 constant public MAX_TOTAL_GIVEAWAY_MONSTA = 2000;

  uint256 public _currentPrice;
  uint256 public _priceIncrement;
  uint256 public _totalMonstasAdopted;
  uint256 public _totalGiveawayMonstas;
  uint256 public _totalRedeemedMonstas;

  address public redemptionAddress;
  address[] public giveawayAddresses;
  mapping(address => Adopters) public _adopters;

  event MonstaAdopted(address indexed adopter);
  event AdoptedMonstaRedeemed(address indexed receiver);

  modifier onlyRedemptionAddress {
    require(msg.sender == redemptionAddress);
    _;
  }

  constructor() public {
    _priceIncrement = INITIAL_PRICE_INCREMENT;
    _currentPrice = INITIAL_PRICE;
  }

  /**
   * @dev Adopt some Monsta
   */
  function adoptMonsta() public payable whenNotPaused {
    require(now <= PRESALE_END_TIMESTAMP);
    require(!_adopters[msg.sender].isAdopted, "Only can adopt once");
    uint256 _addedTotalMonstasAdopted = _totalMonstasAdopted.add(1);
    require(_addedTotalMonstasAdopted <= MAX_TOTAL_ADOPTED_MONSTA);
    require(msg.value >= _currentPrice);

    uint256 value = msg.value;
    value = _currentPrice.sub(value);
    msg.sender.transfer(value);  // Refund back the remaining to the receiver

    _adopters[msg.sender].isAdopted = true;
    _totalMonstasAdopted = _totalMonstasAdopted.add(1);
     _currentPrice = _currentPrice.add(_priceIncrement);
    emit MonstaAdopted(msg.sender);
  }
  
  function setRedemptionAddress(address _redemptionAddress) external onlyOwner {
    redemptionAddress = _redemptionAddress;
  }

  /**
  * @dev Redeem adopted monsta, onlyRedemptionAddress is a redemption contract address
  * @param receiver Address of the receiver.
  */
  function redeemAdoptedMonsta(address receiver)external onlyRedemptionAddress whenNotPaused returns(uint256) {
     _totalRedeemedMonstas = _totalRedeemedMonstas.add(1);
    emit AdoptedMonstaRedeemed(receiver);
    return _totalRedeemedMonstas;
  }

  /**
  * @dev Giveaway monsta without effecting adopted Monsta counter counter
  */
  function giveAway(address[] calldata _addresses) external onlyOwner whenNotPaused {
    uint256 _addedTotalGiveawayMonsta = _totalGiveawayMonstas.add(_addresses.length);
    require(_addedTotalGiveawayMonsta <= MAX_TOTAL_GIVEAWAY_MONSTA);

    for (uint256 i = 0; i < _addresses.length; i++) {
      require(!_adopters[_addresses[i]].isAdopted, "Only can adopt once");
      _totalGiveawayMonstas = _totalGiveawayMonstas.add(1);
      _adopters[_addresses[i]].isAdopted = true;
      emit MonstaAdopted(_addresses[i]);
    }
  }
  
  /**
  * @dev Transfer all BNB held by the contract to the owner.
  */
  function reclaimBNB() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

pragma solidity ^0.5.16;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address payable public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

pragma solidity ^0.5.16;


import "./Ownable.sol";


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

pragma solidity ^0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

