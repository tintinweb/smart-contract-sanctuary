pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface token { 
  function transfer(address, uint) external returns (bool);
  function transferFrom(address, address, uint) external returns (bool); 
  function allowance(address, address) external constant returns (uint256);
  function balanceOf(address) external constant returns (uint256);
}

/** LOGIC DESCRIPTION
 * 11% fees in and out for ETH
 * 11% fees in and out for NOVA
 *
 * ETH fees split: 
 * 6% to nova holders
 * 4% to eth holders
 * 1% to fixed address
 * 
 * NOVA fees split: 
 * 6% to nova holders
 * 4% to eth holders
 * 1% airdrop to a random address based on their nova shares
 * rules: 
 * - you need to have both nova and eth to get dividends
 */

contract NovaBox is Ownable {
  
  using SafeMath for uint;
  token tokenReward;

  
  constructor() public {
    tokenReward = token(0x72FBc0fc1446f5AcCC1B083F0852a7ef70a8ec9f);
  }

  event AirDrop(address to, uint amount, uint randomTicket);

  // ether contributions
  mapping (address => uint) public contributionsEth;
  // token contributions
  mapping (address => uint) public contributionsToken;

  // investors list who have deposited BOTH ether and token
  mapping (address => uint) public indexes;
  mapping (uint => address) public addresses;
  uint256 public lastIndex = 0;

  function addToList(address sender) private {
    // if the sender is not in the list
    if (indexes[sender] == 0) {
      // add the sender to the list
      lastIndex++;
      addresses[lastIndex] = sender;
      indexes[sender] = lastIndex;
    }
  }
  function removeFromList(address sender) private {
    // if the sender is in temp eth list 
    if (indexes[sender] > 0) {
      // remove the sender from temp eth list
      addresses[indexes[sender]] = addresses[lastIndex];
      indexes[addresses[lastIndex]] = indexes[sender];
      indexes[sender] = 0;
      delete addresses[lastIndex];
      lastIndex--;
    }
  }

  // desposit ether
  function () payable public {
    
    uint weiAmount = msg.value;
    address sender = msg.sender;

    // number of ether sent must be greater than 0
    require(weiAmount > 0);

    uint _89percent = weiAmount.mul(89).div(100);
    uint _6percent = weiAmount.mul(6).div(100);
    uint _4percent = weiAmount.mul(4).div(100);
    uint _1percent = weiAmount.mul(1).div(100);


    


    distributeEth(
      _6percent, // to nova investors
      _4percent  // to eth investors
    ); 
    //1% goes to REX Investors
    owner.transfer(_1percent);

    contributionsEth[sender] = contributionsEth[sender].add(_89percent);

    // if the sender has also deposited tokens, add sender to list
    if (contributionsToken[sender]>0) addToList(sender);
  }

  // withdraw ether
  function withdrawEth(uint amount) public {
    address sender = msg.sender;
    require(amount>0 && contributionsEth[sender] >= amount);

    uint _89percent = amount.mul(89).div(100);
    uint _6percent = amount.mul(6).div(100);
    uint _4percent = amount.mul(4).div(100);
    uint _1percent = amount.mul(1).div(100);

    contributionsEth[sender] = contributionsEth[sender].sub(amount);

    // if the sender has withdrawn all their eth
      // remove the sender from list
    if (contributionsEth[sender] == 0) removeFromList(sender);

    sender.transfer(_89percent);
    distributeEth(
      _6percent, // to nova investors
      _4percent  // to eth investors
    );
    owner.transfer(_1percent);
  }

  // deposit tokens
  function depositTokens(address randomAddr, uint randomTicket) public {
   

    address sender = msg.sender;
    uint amount = tokenReward.allowance(sender, address(this));
    
    // number of allowed tokens must be greater than 0
    // if it is then transfer the allowed tokens from sender to the contract
    // if not transferred then throw
    require(amount>0 && tokenReward.transferFrom(sender, address(this), amount));


    uint _89percent = amount.mul(89).div(100);
    uint _6percent = amount.mul(6).div(100);
    uint _4percent = amount.mul(4).div(100);
    uint _1percent = amount.mul(1).div(100);
    
    

    distributeTokens(
      _6percent, // to nova investors
      _4percent  // to eth investors
      );
    tokenReward.transfer(randomAddr, _1percent);
    // 1% for Airdrop
    emit AirDrop(randomAddr, _1percent, randomTicket);

    contributionsToken[sender] = contributionsToken[sender].add(_89percent);
    // if the sender has also contributed ether add sender to list
    if (contributionsEth[sender]>0) addToList(sender);
  }

  // withdraw tokens
  function withdrawTokens(uint amount, address randomAddr, uint randomTicket) public {
    address sender = msg.sender;
    // requested amount must be greater than 0 and 
    // the sender must have contributed tokens no less than `amount`
    require(amount>0 && contributionsToken[sender]>=amount);

    uint _89percent = amount.mul(89).div(100);
    uint _6percent = amount.mul(6).div(100);
    uint _4percent = amount.mul(4).div(100);
    uint _1percent = amount.mul(1).div(100);

    contributionsToken[sender] = contributionsToken[sender].sub(amount);

    // if sender withdrawn all their tokens, remove them from list
    if (contributionsToken[sender] == 0) removeFromList(sender);

    tokenReward.transfer(sender, _89percent);
    distributeTokens(
      _6percent, // to nova investors
      _4percent  // to eth investors
    );
    // airdropToRandom(_1percent);  
    tokenReward.transfer(randomAddr, _1percent);
    emit AirDrop(randomAddr, _1percent, randomTicket);
  }

  function distributeTokens(uint _6percent, uint _4percent) private {
    uint totalTokens = getTotalTokens();
    uint totalWei = getTotalWei();

    // loop over investors (`holders`) list
    for (uint i = 1; i <= lastIndex; i++) {

      address holder = addresses[i];
      // `holder` will get part of 6% fee based on their token shares
      uint _rewardTokens = contributionsToken[holder].mul(_6percent).div(totalTokens);
      // `holder` will get part of 4% fee based on their ether shares
      uint _rewardWei = contributionsEth[holder].mul(_4percent).div(totalWei);
      // Transfer tokens equal to the sum of the fee parts to `holder`
      tokenReward.transfer(holder,_rewardTokens.add(_rewardWei));
    }
  }

  function distributeEth(uint _6percent, uint _4percent) private {
    uint totalTokens = getTotalTokens();
    uint totalWei = getTotalWei();

    // loop over investors (`holders`) list
    for (uint i = 1; i <= lastIndex; i++) {
      address holder = addresses[i];
      // `holder` will get part of 6% fee based on their token shares
      uint _rewardTokens = contributionsToken[holder].mul(_6percent).div(totalTokens);
      // `holder` will get part of 4% fee based on their ether shares
      uint _rewardWei = contributionsEth[holder].mul(_4percent).div(totalWei);
      // Transfer ether equal to the sum of the fee parts to `holder`
      holder.transfer(_rewardTokens.add(_rewardWei));
    }
  }


  // get sum of tokens contributed by the ether investors
  function getTotalTokens() public view returns (uint) {
    uint result;
    for (uint i = 1; i <= lastIndex; i++) {
      result = result.add(contributionsToken[addresses[i]]);
    }
    return result;
  }

  // get the sum of wei contributed by the token investors
  function getTotalWei() public view returns (uint) {
    uint result;
    for (uint i = 1; i <= lastIndex; i++) {
      result = result.add(contributionsEth[addresses[i]]);
    }
    return result;
  }


  // get the list of investors
  function getList() public view returns (address[], uint[]) {
    address[] memory _addrs = new address[](lastIndex);
    uint[] memory _contributions = new uint[](lastIndex);

    for (uint i = 1; i <= lastIndex; i++) {
      _addrs[i-1] = addresses[i];
      _contributions[i-1] = contributionsToken[addresses[i]];
    }
    return (_addrs, _contributions);
  }



}