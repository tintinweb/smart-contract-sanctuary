pragma solidity ^0.4.24;

library SafeMath {
   function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {  return 0;} c = a * b; assert(c / a == b);return c;}
   function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;}
   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a); return a - b; }
   function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b; assert(c >= a); return c; }}
contract cryptoToken {
   string public constant name = "Crypto";
   string public constant symbol ="CPT";
   uint32 public constant decimals = 2;
   uint32 public version = 1.0;   }
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender)
    public view returns (uint256);
  function transferFrom(address from, address to, uint256 value)
    public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value);}
contract basicToken {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  uint256 totalSupply_;
  function totalSupply() public view returns (uint256) {return totalSupply_;}}
contract purchaceCrypto {
  using SafeMath for uint256;
  ERC20 public token;
  address public wallet = 0xF07028ea85Fb8993d349Eb0D29A2f3D893865dA1;
  uint256 public initialrate = 1 finney;
  uint256 public rate = weiRaised;
  uint256 public weiRaised;
event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount);
    constructor (uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));
    rate = _rate;
    wallet = _wallet;
    token = _token;  }
  function () external payable {
    buyTokens(msg.sender);  }
    function buyTokens(address _beneficiary) public payable {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);
     uint256 tokens = _getTokenAmount(weiAmount);
     weiRaised = weiRaised.add(weiAmount);
     _processPurchase(_beneficiary, tokens);
    emit TokenPurchase( msg.sender, _beneficiary,weiAmount,tokens);
    _updatePurchasingState(_beneficiary, weiAmount);_forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);  }
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount  ) internal {require(_beneficiary != address(0));
    require(_weiAmount != 0); }
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount  ) internal { }
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount); }
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount )internal {_deliverTokens(_beneficiary, _tokenAmount);}
   function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount )  internal { }
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256) { return _weiAmount.mul(rate);}
  function _forwardFunds() internal {
    wallet.transfer(msg.value);}
}