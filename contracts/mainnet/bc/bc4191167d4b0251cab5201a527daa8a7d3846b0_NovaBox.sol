pragma solidity ^0.4.25;

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
  event DividendsTransferred(address to, uint ethAmount, uint novaAmount);


  // ether contributions
  mapping (address => uint) public contributionsEth;
  // token contributions
  mapping (address => uint) public contributionsToken;

  // investors list who have deposited BOTH ether and token
  mapping (address => uint) public indexes;
  mapping (uint => address) public addresses;
  uint256 public lastIndex = 0;

  mapping (address => bool) public addedToList;
  uint _totalTokens = 0;
  uint _totalWei = 0;

  uint pointMultiplier = 1e18;

  mapping (address => uint) public last6EthDivPoints;
  uint public total6EthDivPoints = 0;
  // uint public unclaimed6EthDivPoints = 0;

  mapping (address => uint) public last4EthDivPoints;
  uint public total4EthDivPoints = 0;
  // uint public unclaimed4EthDivPoints = 0;

  mapping (address => uint) public last6TokenDivPoints;
  uint public total6TokenDivPoints = 0;
  // uint public unclaimed6TokenDivPoints = 0;

  mapping (address => uint) public last4TokenDivPoints;
  uint public total4TokenDivPoints = 0;
  // uint public unclaimed4TokenDivPoints = 0;

  function ethDivsOwing(address _addr) public view returns (uint) {
    return eth4DivsOwing(_addr).add(eth6DivsOwing(_addr));
  }

  function eth6DivsOwing(address _addr) public view returns (uint) {
    if (!addedToList[_addr]) return 0;
    uint newEth6DivPoints = total6EthDivPoints.sub(last6EthDivPoints[_addr]);

    return contributionsToken[_addr].mul(newEth6DivPoints).div(pointMultiplier);
  }

  function eth4DivsOwing(address _addr) public view returns (uint) {
    if (!addedToList[_addr]) return 0;
    uint newEth4DivPoints = total4EthDivPoints.sub(last4EthDivPoints[_addr]);
    return contributionsEth[_addr].mul(newEth4DivPoints).div(pointMultiplier);
  }

  function tokenDivsOwing(address _addr) public view returns (uint) {
    return token4DivsOwing(_addr).add(token6DivsOwing(_addr));    
  }

  function token6DivsOwing(address _addr) public view returns (uint) {
    if (!addedToList[_addr]) return 0;
    uint newToken6DivPoints = total6TokenDivPoints.sub(last6TokenDivPoints[_addr]);
    return contributionsToken[_addr].mul(newToken6DivPoints).div(pointMultiplier);
  }

  function token4DivsOwing(address _addr) public view returns (uint) {
    if (!addedToList[_addr]) return 0;

    uint newToken4DivPoints = total4TokenDivPoints.sub(last4TokenDivPoints[_addr]);
    return contributionsEth[_addr].mul(newToken4DivPoints).div(pointMultiplier);
  }

  function updateAccount(address account) private {
    uint owingEth6 = eth6DivsOwing(account);
    uint owingEth4 = eth4DivsOwing(account);
    uint owingEth = owingEth4.add(owingEth6);

    uint owingToken6 = token6DivsOwing(account);
    uint owingToken4 = token4DivsOwing(account);
    uint owingToken = owingToken4.add(owingToken6);

    if (owingEth > 0) {
      // send ether dividends to account
      account.transfer(owingEth);
    }

    if (owingToken > 0) {
      // send token dividends to account
      tokenReward.transfer(account, owingToken);
    }

    last6EthDivPoints[account] = total6EthDivPoints;
    last4EthDivPoints[account] = total4EthDivPoints;
    last6TokenDivPoints[account] = total6TokenDivPoints;
    last4TokenDivPoints[account] = total4TokenDivPoints;

    emit DividendsTransferred(account, owingEth, owingToken);

  }



  function addToList(address sender) private {
    addedToList[sender] = true;
    // if the sender is not in the list
    if (indexes[sender] == 0) {
      _totalTokens = _totalTokens.add(contributionsToken[sender]);
      _totalWei = _totalWei.add(contributionsEth[sender]);

      // add the sender to the list
      lastIndex++;
      addresses[lastIndex] = sender;
      indexes[sender] = lastIndex;
    }
  }
  function removeFromList(address sender) private {
    addedToList[sender] = false;
    // if the sender is in temp eth list 
    if (indexes[sender] > 0) {
      _totalTokens = _totalTokens.sub(contributionsToken[sender]);
      _totalWei = _totalWei.sub(contributionsEth[sender]);

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
    address sender = msg.sender;
    // size of code at target address
    uint codeLength;

    // get the length of code at the sender address
    assembly {
      codeLength := extcodesize(sender)
    }

    // don&#39;t allow contracts to deposit ether
    require(codeLength == 0);
    
    uint weiAmount = msg.value;
    

    updateAccount(sender);

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
    // if the sender is in list
    if (indexes[sender]>0) {
      // increase _totalWei
      _totalWei = _totalWei.add(_89percent);
    }

    // if the sender has also deposited tokens, add sender to list
    if (contributionsToken[sender]>0) addToList(sender);
  }

  // withdraw ether
  function withdrawEth(uint amount) public {
    address sender = msg.sender;
    require(amount>0 && contributionsEth[sender] >= amount);

    updateAccount(sender);

    uint _89percent = amount.mul(89).div(100);
    uint _6percent = amount.mul(6).div(100);
    uint _4percent = amount.mul(4).div(100);
    uint _1percent = amount.mul(1).div(100);

    contributionsEth[sender] = contributionsEth[sender].sub(amount);
    // if sender is in list
    if (indexes[sender]>0) {
      // decrease total wei
      _totalWei = _totalWei.sub(amount);
    }

    // if the sender has withdrawn all their eth
      // remove the sender from list
    if (contributionsEth[sender] == 0) removeFromList(sender);

    sender.transfer(_89percent);
    distributeEth(
      _6percent, // to nova investors
      _4percent  // to eth investors
    );
    owner.transfer(_1percent);  //1% goes to REX Investors
  }

  // deposit tokens
  function depositTokens(address randomAddr, uint randomTicket) public {
    updateAccount(msg.sender);
    

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

    // if sender is in list
    if (indexes[sender]>0) {
      // increase totaltokens
      _totalTokens = _totalTokens.add(_89percent);
    }

    // if the sender has also contributed ether add sender to list
    if (contributionsEth[sender]>0) addToList(sender);
  }

  // withdraw tokens
  function withdrawTokens(uint amount, address randomAddr, uint randomTicket) public {
    address sender = msg.sender;
    updateAccount(sender);
    // requested amount must be greater than 0 and 
    // the sender must have contributed tokens no less than `amount`
    require(amount>0 && contributionsToken[sender]>=amount);

    uint _89percent = amount.mul(89).div(100);
    uint _6percent = amount.mul(6).div(100);
    uint _4percent = amount.mul(4).div(100);
    uint _1percent = amount.mul(1).div(100);

    contributionsToken[sender] = contributionsToken[sender].sub(amount);
    // if sender is in list
    if (indexes[sender]>0) {
      // decrease total tokens
      _totalTokens = _totalTokens.sub(amount);
    }

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

    if (totalWei == 0 || totalTokens == 0) return; 

    total4TokenDivPoints = total4TokenDivPoints.add(_4percent.mul(pointMultiplier).div(totalWei));
    // unclaimed4TokenDivPoints = unclaimed4TokenDivPoints.add(_4percent);

    total6TokenDivPoints = total6TokenDivPoints.add(_6percent.mul(pointMultiplier).div(totalTokens));
    // unclaimed6TokenDivPoints = unclaimed6TokenDivPoints.add(_6percent);
    
  }

  function distributeEth(uint _6percent, uint _4percent) private {
    uint totalTokens = getTotalTokens();
    uint totalWei = getTotalWei();

    if (totalWei ==0 || totalTokens == 0) return;

    total4EthDivPoints = total4EthDivPoints.add(_4percent.mul(pointMultiplier).div(totalWei));
    // unclaimed4EthDivPoints += _4percent;

    total6EthDivPoints = total6EthDivPoints.add(_6percent.mul(pointMultiplier).div(totalTokens));
    // unclaimed6EthDivPoints += _6percent;

  }


  // get sum of tokens contributed by the ether investors
  function getTotalTokens() public view returns (uint) {
    return _totalTokens;
  }

  // get the sum of wei contributed by the token investors
  function getTotalWei() public view returns (uint) {
    return _totalWei;
  }

  function withdrawDivs() public {
    updateAccount(msg.sender);
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