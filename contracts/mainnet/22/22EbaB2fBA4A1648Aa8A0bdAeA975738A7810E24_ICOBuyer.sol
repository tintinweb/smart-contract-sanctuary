pragma solidity ^0.4.11;

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract ICOBuyer is Ownable {

  // Contract allows Ether to be paid into it
  // Contract allows tokens / Ether to be extracted only to owner account
  // Contract allows executor address or owner address to trigger ICO purtchase

  //Notify on economic events
  event EtherReceived(address indexed _contributor, uint256 _amount);
  event EtherWithdrawn(uint256 _amount);
  event TokensWithdrawn(uint256 _balance);
  event ICOPurchased(uint256 _amount);

  //Notify on contract updates
  event ICOStartBlockChanged(uint256 _icoStartBlock);
  event ICOStartTimeChanged(uint256 _icoStartTime);
  event ExecutorChanged(address _executor);
  event CrowdSaleChanged(address _crowdSale);
  event TokenChanged(address _token);
  event PurchaseCapChanged(uint256 _purchaseCap);

  // only owner can change these
  // Earliest block number contract is allowed to buy into the crowdsale.
  uint256 public icoStartBlock;
  // Earliest time contract is allowed to buy into the crowdsale.
  uint256 public icoStartTime;
  // The crowdsale address.
  address public crowdSale;
  // The address that can trigger ICO purchase (may be different to owner)
  address public executor;
  // The amount for each ICO purchase
  uint256 public purchaseCap;

  modifier onlyExecutorOrOwner() {
    require((msg.sender == executor) || (msg.sender == owner));
    _;
  }

  function ICOBuyer(address _executor, address _crowdSale, uint256 _icoStartBlock, uint256 _icoStartTime, uint256 _purchaseCap) {
    executor = _executor;
    crowdSale = _crowdSale;
    icoStartBlock = _icoStartBlock;
    icoStartTime = _icoStartTime;
    purchaseCap = _purchaseCap;
  }

  function changeCrowdSale(address _crowdSale) onlyOwner {
    crowdSale = _crowdSale;
    CrowdSaleChanged(crowdSale);
  }

  function changeICOStartBlock(uint256 _icoStartBlock) onlyExecutorOrOwner {
    icoStartBlock = _icoStartBlock;
    ICOStartBlockChanged(icoStartBlock);
  }

  function changeICOStartTime(uint256 _icoStartTime) onlyExecutorOrOwner {
    icoStartTime = _icoStartTime;
    ICOStartTimeChanged(icoStartTime);
  }

  function changePurchaseCap(uint256 _purchaseCap) onlyOwner {
    purchaseCap = _purchaseCap;
    PurchaseCapChanged(purchaseCap);
  }

  function changeExecutor(address _executor) onlyOwner {
    executor = _executor;
    ExecutorChanged(_executor);
  }

  // function allows all Ether to be drained from contract by owner
  function withdrawEther() onlyOwner {
    require(this.balance != 0);
    owner.transfer(this.balance);
    EtherWithdrawn(this.balance);
  }

  // function allows all tokens to be transferred to owner
  function withdrawTokens(address _token) onlyOwner {
    ERC20Basic token = ERC20Basic(_token);
    // Retrieve current token balance of contract.
    uint256 contractTokenBalance = token.balanceOf(address(this));
    // Disallow token withdrawals if there are no tokens to withdraw.
    require(contractTokenBalance != 0);
    // Send the funds.  Throws on failure to prevent loss of funds.
    assert(token.transfer(owner, contractTokenBalance));
    TokensWithdrawn(contractTokenBalance);
  }

  // Buys tokens in the crowdsale and rewards the caller, callable by anyone.
  function buyICO() onlyExecutorOrOwner {
    // Short circuit to save gas if the earliest block number hasn&#39;t been reached.
    if ((icoStartBlock != 0) && (getBlockNumber() < icoStartBlock)) return;
    // Short circuit to save gas if the earliest buy time hasn&#39;t been reached.
    if ((icoStartTime != 0) && (getNow() < icoStartTime)) return;
    // Return if no balance
    if (this.balance == 0) return;

    // Purchase tokens from ICO contract (assuming call to ICO fallback function)
    uint256 purchaseAmount = Math.min256(this.balance, purchaseCap);
    assert(crowdSale.call.value(purchaseAmount)());
    ICOPurchased(purchaseAmount);
  }

  // Fallback function accepts ether and logs this.
  // Can be called by anyone to fund contract.
  function () payable {
    EtherReceived(msg.sender, msg.value);
  }

  //Function is mocked for tests
  function getBlockNumber() internal constant returns (uint256) {
    return block.number;
  }

  //Function is mocked for tests
  function getNow() internal constant returns (uint256) {
    return now;
  }

}