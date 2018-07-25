pragma solidity ^0.4.24;
// This is based on https://github.com/OpenZeppelin/openzeppelin-solidity.
// We announced each .sol file and omitted the verbose comments.
// Gas limit : 3,000,000

library SafeMath {                             //SafeMath.sol
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) { return 0; }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract QurozToken { // pulbic functions of Token
  function transfer(address _to, uint256 _value) public returns (bool) {}
}

contract QforaSale {
  using SafeMath for uint256;                         //RefundableCrowdsale.sol
  uint256 public goal;                                //RefundableCrowdsale.sol, goal of wei
  uint256 public rate;                                //Crowdsale.sol, Token = wei * rate
  uint256 public openingTime;                         //TimedCrowdsale.sol
  uint256 public closingTime;                         //TimedCrowdsale.sol
  uint256 public weiRaised;                           //Crowdsale.sol
  uint256 public tokenSold;          //new
  uint256 public threshold;          //new
  uint256 public hardCap;            //new
  uint256 public bonusRate;          // new, 20 means 20% 
  address public wallet;                              //RefundVault.sol
  address public owner;                               //Ownable.sol
  bool public isFinalized;                     //FinalizableCrowdsale.sol
  mapping(address => uint256) public balances;       //PostDeliveryCrowdsale.sol, info for withdraw
  mapping(address => uint256) public deposited;      //RefundVault.sol,           info for refund
  mapping(address => bool) public whitelist;          //WhitelistedCrowdsale.sol
  enum State { Active, Refunding, Closed }            //RefundVault.sol
  State public state;                                 //RefundVault.sol
  QurozToken public token;

  event Closed();                                     //RefundVault.sol
  event RefundsEnabled();                             //RefundVault.sol
  event Refunded(address indexed beneficiary, uint256 weiAmount);   //RefundVault.sol
  event Finalized();                                      //FinalizableCrowdsale.sol
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);  //Ownable.sol
  event TokenPurchase(address indexed purchaser,address indexed beneficiary,uint256 value,uint256 amount); //Crowdsale

  constructor(address _wallet, QurozToken _token) public {
    require(_wallet != address(0) && _token != address(0));
    owner = msg.sender;
    wallet = _wallet;
    token = _token;
    goal = 5000e18;
    rate = 10000;
    threshold = 100e18;
    hardCap = 50000e18;
    bonusRate = 20;
    openingTime = now.add(3 hours + 5 minutes);
    closingTime = openingTime.add(28 days);
    require(block.timestamp <= openingTime && openingTime <= closingTime);
  }

  modifier onlyOwner() {require(msg.sender == owner); _;}            //Ownable.sol
  modifier isWhitelisted(address _beneficiary) {require(whitelist[_beneficiary]); _;}  //WhitelistedCrowdsale.sol

  function addToWhitelist(address _beneficiary) public onlyOwner {      //WhitelistedCrowdsale.sol (external to public)
    whitelist[_beneficiary] = true;
  }

  function addManyToWhitelist(address[] _beneficiaries) public onlyOwner { //WhitelistedCrowdsale.sol (external to public)
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  function removeFromWhitelist(address _beneficiary) public onlyOwner { //WhitelistedCrowdsale.sol (external to public)
    whitelist[_beneficiary] = false;
  }

  function () external payable {                                            //Crowdsale.sol
    require(openingTime <= block.timestamp && block.timestamp <= closingTime);      // new
    require(whitelist[msg.sender]);        // new
    require(msg.value >= threshold );      // new
    require(weiRaised.add(msg.value) <= hardCap );      // new
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {                           //Crowdsale.sol
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);
    uint256 tokens = _getTokenAmount(weiAmount);
    uint256 totalTokens = tokens.mul(100 + bonusRate).div(100);
    weiRaised = weiRaised.add(weiAmount);
    tokenSold = tokenSold.add(totalTokens);          // new
    _processPurchase(_beneficiary, totalTokens);     // changed parameter to totalTokens
    deposit(_beneficiary, msg.value);           // new
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
//    _updatePurchasingState(_beneficiary, weiAmount);
//    _forwardFunds();                                // masking for refund
//    _postValidatePurchase(_beneficiary, weiAmount);
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {    
      //Crowdsale.sol, WhitelistedCrowdsale.sol
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {        //Crowdsale.sol
    return _weiAmount.mul(rate);
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {      //PostDeliveryCrowdsale.sol
//    _deliverTokens(_beneficiary, _tokenAmount);  //Crowdsale.sol
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);  // new

  }

  function hasClosed() public view returns (bool) {               //TimedCrowdsale.sol
    return block.timestamp > closingTime;
  }

  function deposit(address investor, uint256 value) internal {  //RefundVault.sol (liternal, no payable, add value)
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(value);
  }

  function goalReached() public view returns (bool) {    //RefundableCrowdsale.sol
    return weiRaised >= goal;
  }

  function finalize() onlyOwner public {          //FinalizableCrowdsale.sol
    require(!isFinalized);
    require(hasClosed());   // finalizing after timeout
    finalization();
    emit Finalized();
    isFinalized = true;
  }

  function finalization() internal {                     //RefundableCrowdsale.sol (change state)
    if (goalReached()) { close(); } 
    else               { enableRefunds(); }
    //super.finalization();
  }

  function close() onlyOwner public {   //RefundVault.sol (Active -> Closed if goal reached)
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public { //RefundVault.sol (Active -> Refunding if goal not reached)
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  function claimRefund() public {                         //RefundableCrowdsale.sol
    require(isFinalized);
    require(!goalReached());
    refund(msg.sender);
  }

  function refund(address investor) public {       //RefundVault.sol
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    balances[investor] = 0;                                                                             // new
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }

  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {       //Crowdsale.sol
    token.transfer(_beneficiary, _tokenAmount);
  }

  function withdrawTokens() public {                              //PostDeliveryCrowdsale.sol
    require(hasClosed());
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    balances[msg.sender] = 0;
    _deliverTokens(msg.sender, amount);
    deposited[msg.sender] = 0;                        //new
  }

  function transferOwnership(address _newOwner) public onlyOwner { //Ownable.sol
    _transferOwnership(_newOwner);
  }

  function _transferOwnership(address _newOwner) internal {       //Ownable.sol
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
    
  function destroyAndSend(address _recipient) onlyOwner public {   //Destructible.sol
    selfdestruct(_recipient);
  }

/* new functions */
  function transferToken(address to, uint256 value) onlyOwner public { 
    token.transfer(to, value);
  }
  
  function setBonusRate(uint256 _bonusRate) public onlyOwner{
    _setBonusRate(_bonusRate);
  }

  function _setBonusRate(uint256 _bonusRate) internal {
    bonusRate = _bonusRate;
  }
  
  function getWeiBalance() public view returns(uint256) {
    return address(this).balance;
  }

  function getBalanceOf(address investor) public view returns(uint256) {
    return balances[investor];
  }

  function getDepositedOf(address investor) public view returns(uint256) {
    return deposited[investor];
  }

  function getWeiRaised() public view returns(uint256) {
    return weiRaised;
  }

  function getTokenSold() public view returns(uint256) {
    return tokenSold;
  }

  function setSmallInvestor(address _beneficiary, uint256 weiAmount, uint256 totalTokens) public onlyOwner {
    require(whitelist[_beneficiary]); 
    require(weiAmount >= 1 ether ); 
    require(weiRaised.add(weiAmount) <= hardCap ); 
    weiRaised = weiRaised.add(weiAmount);
    tokenSold = tokenSold.add(totalTokens); 
    _processPurchase(_beneficiary, totalTokens);     
    deposit(_beneficiary, weiAmount);
  }

}