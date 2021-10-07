/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}


abstract contract ReentrancyGuard {
   
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

   
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns(uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}



contract Presale is ReentrancyGuard, Context, Ownable {

    mapping (address => uint256) public _contributions;
    mapping (address => bool) public _whitelisted;
    
    IERC20 public _token;
    uint256 private _tokenDecimals;
    address public _wallet;
    uint256 public _rate;
    uint256 public _weiRaised;
    uint256 public endICO;
    uint public minPurchase;
    uint public maxPurchase;
    uint public hardcap;
    uint public purchasedTokens;
    
    address[] private whitelistAddresses;

    event TokensPurchased(address  purchaser, uint256 value, uint256 amount);
    event Refund(address recipient, uint256 amount);
    constructor (uint256 rate, address wallet, IERC20 token)  {
        require(rate > 0, "Pre-Sale: rate is 0");
        require(wallet != address(0), "Pre-Sale: wallet is the zero address");
        require(address(token) != address(0), "Pre-Sale: token is the zero address");
        
        _rate = rate;
        _wallet = wallet;
        _token = token;
        _tokenDecimals = 18 - _token.decimals();
    }
    
    function setWhitelist(address[] memory recipients) public onlyOwner{
        for(uint256 i = 0; i < recipients.length; i++){
            _whitelisted[recipients[i]] = true;
        }
        whitelistAddresses = recipients;
    }
    
    function whitelistAccount(address account, bool value) external onlyOwner{
        _whitelisted[account] = value;
    }
    
    
    //Start Pre-Sale
    function startICO(uint endDate, uint _minPurchase, uint _maxPurchase, uint256 _hardcap) external onlyOwner icoNotActive() {
        require(whitelistAddresses.length > 0, 'Whitelist not set yet');
        require(endDate > block.timestamp, 'duration should be > 0');
        require(_minPurchase > 0, '_minPurchase should > 0');
        endICO = endDate; 
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        hardcap = _hardcap;
        _weiRaised = 0;
    }
    
    function stopICO() external onlyOwner icoActive(){
        endICO = 0;
    }
    
    //Pre-Sale 
    function buyTokens() public nonReentrant icoActive payable{
        uint256 weiAmount = msg.value;
        uint256 tokens = _getTokenAmount(weiAmount);
        _preValidatePurchase(msg.sender, weiAmount);
        _weiRaised = _weiRaised + weiAmount;
        purchasedTokens += tokens;
        _contributions[msg.sender] = _contributions[msg.sender] + weiAmount;
        emit TokensPurchased(msg.sender, weiAmount, tokens);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Presale: beneficiary is the zero address");
        require(_whitelisted[beneficiary], "You are not in whitelist");
        require(weiAmount != 0, "Presale: weiAmount is 0");
        require(weiAmount >= minPurchase, 'have to send at least: minPurchase');
        require(_weiRaised + weiAmount <= hardcap, "Exceeding hardcap");
        require(_contributions[beneficiary] + weiAmount <= maxPurchase, "can't buy more than: maxPurchase");
    }
    

    function checkWhitelist(address account) external view returns(bool){
        return _whitelisted[account];
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount * _rate / 10**_tokenDecimals;
    }

    function _forwardFunds(uint256 amount) external onlyOwner {
        payable(_wallet).transfer(amount);
    }
    
    function checkContribution(address addr) public view returns(uint256){
        uint256 tokensBought = _getTokenAmount(_contributions[addr]);
        return (tokensBought);
    }

    
    function setRate(uint256 newRate) external onlyOwner icoNotActive{
        _rate = newRate;
    }
    
    function setWalletReceiver(address newWallet) external onlyOwner(){
        _wallet = newWallet;
    }
    
    function setMaxPurchase(uint256 value) external onlyOwner{
        maxPurchase = value;
    }
    
     function setMinPurchase(uint256 value) external onlyOwner{
        minPurchase = value;
    }
    
    function setHardcap(uint256 value) external onlyOwner{
        hardcap = value;
    }
    
    function takeTokens(IERC20 tokenAddress) public onlyOwner{
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        tokenBEP.transfer(_wallet, tokenAmt);
    }
    
    modifier icoActive() {
        require(endICO > 0 && block.timestamp < endICO && _weiRaised < hardcap, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(endICO < block.timestamp, 'ICO should not be active');
        _;
    }
    
}