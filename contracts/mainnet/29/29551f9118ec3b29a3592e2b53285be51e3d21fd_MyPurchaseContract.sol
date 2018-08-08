pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
   function Ownable() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {

  function allowance(address owner, address spender) public view returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner,address indexed spender,uint256 value);
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token,address from,address to,uint256 value) internal{
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}


contract PurchaseAdmin is Ownable{
    
  address public purchaseAdmin;
  
  bool public purchaseEnable = true;
  
  bool public grantEnable = true;
  
  //申购开始时间
  uint256 public startAt;

  //停止申购时间
  uint256 public stopAt;

  //发放时间
  uint256 public grantAt;
  
  event PurchaseEnable(address indexed from, bool enable);
  
  event GrantEnable(address indexed from, bool enable);

  function PurchaseAdmin() public{
    purchaseAdmin = msg.sender;
  }

  function setPurchaseAdmin(address _purchaseAdmin) onlyOwner public {
    purchaseAdmin = _purchaseAdmin;
  }

  modifier onlyPurchaseAdmin() {
    require(msg.sender == purchaseAdmin);
    _;
  }
  
  function setEnablePurchase(bool enable ) onlyPurchaseAdmin public {
    purchaseEnable = enable;
    emit PurchaseEnable(msg.sender,enable);
  }
  
  modifier checkPurchaseEnable() {
    require(purchaseEnable);
     require(block.timestamp >= startAt && block.timestamp <= stopAt);//要求在申购期内
    _;
  }

  function setGrantEnable(bool enable ) onlyOwner public {
    grantEnable = enable;
    emit GrantEnable(msg.sender,enable);
  }

   modifier checkGrantEnable() {
    require(grantEnable);
    require(block.timestamp >= grantAt);
    _;
  }
}


//申购合约
contract MyPurchaseContract is Ownable,PurchaseAdmin{

  using SafeMath for uint256;

  using SafeERC20 for ERC20;

  ERC20 public token;

  //可申购总量
  uint256 public totalAllocatedPurchase;

  //剩余可申购数量
  uint256 public remainingPurchaseAmount;

  //以太币申购兑换代币的比例为1ether = 500UHT 
  uint256 public buyPrice =  (10 ** uint256(18)) / (500* (10 ** uint256(6)));
  
  //单个地址申购代币总额度有限制，申购代币不能超过100000个UHT
  uint256 public maxPurchase = 100000;

  //每次申购代币最多申购代币5000个UHT
  uint256 public maxPurchaseOnce = 50000;

  //每次申购代币最少申购代币100个UHT
  uint256 public minPurchaseOnce = 1000;

  //发放数次
  uint256 grantCount = 0;

  struct PurchaseData{
    //已申购数量
    uint256 amount;
    
    //已发放代币
    bool grantDone;
  }

  //申购详情
  mapping (address => PurchaseData) public purchasedDatas;

  //申购申购者钱包地址
  address[]  public purchasedWallets;

  event Purchase(address indexed from, uint256 value);

  event Grant(address indexed to, uint256 value);

  function MyPurchaseContract(address _token) public {
    token = ERC20(_token);
    totalAllocatedPurchase = token.totalSupply().mul(30).div(100);//可申购总发行量的30%;
    remainingPurchaseAmount = totalAllocatedPurchase;
    startAt = block.timestamp;//申购开始时间
    stopAt = block.timestamp + 60;//停止申购时间
    grantAt = block.timestamp + 120;//发放时间
  }

  //申购  
  function buyTokens()  payable checkPurchaseEnable public returns(uint256){
      
    require(msg.value > 0);

    require(remainingPurchaseAmount > 0);//剩余可申购的总额度

    require(purchasedDatas[msg.sender].amount < maxPurchase);//尚未超出单个地址申购代币总额度限制
    
    uint256 hopeAmount = msg.value.div(buyPrice);//计算用户期望申购的数量

    //首次购买，必须最少申购minPurchaseOnce个代币
    if (purchasedDatas[msg.sender].amount == 0 && hopeAmount < minPurchaseOnce) {
      msg.sender.transfer(msg.value);//不成交，原路退还以太币
      return 0;
    }

    uint256 currentAmount = hopeAmount;

    //不能超出单次最大申购额度
    if (hopeAmount >= maxPurchaseOnce) {
       currentAmount = maxPurchaseOnce;
    } 

    //不能超出剩余可申购额度
    if (currentAmount >= remainingPurchaseAmount) {
       currentAmount = remainingPurchaseAmount;
    } 

    //首次申购，记录钱包地址
    if (purchasedDatas[msg.sender].amount == 0){
       purchasedWallets.push(msg.sender);
    }

    purchasedDatas[msg.sender].amount = purchasedDatas[msg.sender].amount.add(currentAmount);
    
    remainingPurchaseAmount = remainingPurchaseAmount.sub(currentAmount);
    
    emit Purchase(msg.sender,currentAmount);  

    if (hopeAmount > currentAmount){
      //超出申购额度的ether返回给用户
      uint256 out = hopeAmount.sub(currentAmount);
      //计算需要退还的ether
      uint256 retwei = out.mul(buyPrice);
      //退还ether
      msg.sender.transfer(retwei);
    }

    return currentAmount;
  }


  //发放
  function grantTokens(address _purchaser) onlyPurchaseAdmin checkGrantEnable public returns(bool){
      
    require(_purchaser  != address(0));
    
    require(purchasedDatas[_purchaser].grantDone);
    
    uint256 amount = purchasedDatas[_purchaser].amount;
    
    token.safeTransfer(_purchaser,amount);
    
    purchasedDatas[_purchaser].grantDone = true;
    
    grantCount = grantCount.add(1);

    emit Grant(_purchaser,amount);
    
    return true;
  }


  function claimETH() onlyPurchaseAdmin public returns(bool){

    require(block.timestamp > grantAt);

    require(grantCount == purchasedWallets.length);
    
    msg.sender.transfer(address(this).balance);
    
    return true;
  }
}