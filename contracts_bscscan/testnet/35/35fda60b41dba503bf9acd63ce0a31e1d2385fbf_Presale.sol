/**
 *Submitted for verification at BscScan.com on 2021-07-23
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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

}

contract Presale is ReentrancyGuard, Context, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) public _contributions;
    mapping (address => uint256) internal whitelist;
    mapping (address => uint256) internal _AmountContribution;
    mapping (address => uint256) internal _TokensPurchased;
    mapping (address => bool) public Claimed;
    mapping (address => bool) public enteredPresale;

    IERC20 public _token;
    address payable public _wallet;
    uint256 public _rate;
    uint256 public _weiRaised;
    uint256 public endICO;
    uint public minPurchase;
    uint public maxPurchase;
    uint public hardCap;
    uint public softCap;
    uint public availableTokensICO;
    bool public startRefund = false;
    bool public seale;

    event TokensPurchased(address indexed beneficiary, uint256 amount);
    event AmountContribution(address indexed beneficiary, uint256 value);
    event Refund(address recipient, uint256 amount);
    event Claim(address recipient, uint256 amount);
    event Whitelisted(address indexed addr, uint256 max);
    constructor (uint256 rate, address payable wallet, IERC20 token)  {
        require(rate > 0, "Pre-Sale: rate is 0");
        require(wallet != address(0), "Pre-Sale: wallet is the zero address");
        require(address(token) != address(0), "Pre-Sale: token is the zero address");
        
        _rate = rate;
        _wallet = wallet;
        _token = token;
    }


    receive () external payable {
        if(endICO > 0 && block.timestamp < endICO){
            buyTokens();
        }
        else{
            revert('Pre-Sale is closed');
        }
    }
    
        // Add address to whitelist
    function addtoWhitelist(address addr, uint256 max) public onlyOwner {
        require(!seale);
        require(addr != address(0));
        whitelist[addr] = max;
        emit Whitelisted(addr, max);
    }
    
        // Add bulk to whitelist
    function bulkAddtoWhitelist(address[] memory addrs, uint256[] memory max) public onlyOwner {
        require(!seale);
        require(addrs.length != 0);
        require(addrs.length == max.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            require(addrs[i] != address(0));
            whitelist[addrs[i]] = max[i];
            emit Whitelisted(addrs[i], max[i]);
        }
    }
        // Delete address from whitelist       
    function removefromWhitelist(address addr, uint max) public onlyOwner {
        require(!seale);
        delete whitelist[addr];
        delete max;
        emit Whitelisted(addr, max);
    }

    // After sealing, no more whitelisting is possible
    function seal() public onlyOwner {
        require(!seale);
        seale = true;
    }
    
    function checkWhitelist(address _addr) public view returns(uint256){
        return whitelist[_addr];
    }
    
    function WhitelistedAddress(address _addr) public view returns(bool){
        if(whitelist[_addr] != 0) {
            return true;
        }
        else{
            return false;
        }
    }    
    
    //Start Pre-Sale
    function startICO(uint endDate, uint _minPurchase, uint _maxPurchase, uint _softCap, uint _hardCap) external onlyOwner icoNotActive() {
        availableTokensICO = _token.balanceOf(address(this));
        require(endDate > block.timestamp, 'Duration should be > 0');
        require(availableTokensICO > 0 && availableTokensICO <= _token.totalSupply(), 'availableTokens should be > 0 and <= totalSupply');
        require(_minPurchase > 0, '_minPurchase should > 0');
        endICO = endDate; 
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        softCap = _softCap;
        hardCap = _hardCap;
        _weiRaised = 0;
    }
    
    function stopICO() external onlyOwner icoActive(){
        endICO = 0;
        if(_weiRaised >= softCap) {
            _forwardFunds();
        }
        else{
            startRefund = true;
        }
    }
    
    
    //Pre-Sale 
    function buyTokens() public nonReentrant icoActive payable {
        uint256 weiAmount = msg.value;
        address beneficiary = msg.sender;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        availableTokensICO = availableTokensICO - tokens;
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
        _AmountContribution[beneficiary] = weiAmount;
        _TokensPurchased[beneficiary] = tokens;
        enteredPresale[beneficiary] = true;
        emit AmountContribution(beneficiary, weiAmount);
        emit TokensPurchased(beneficiary, tokens);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(enteredPresale[beneficiary] == false, 'Already entered in presale!');
        require(WhitelistedAddress(beneficiary) == true, "Address not whitelisted");
        require(checkWhitelist(beneficiary) == weiAmount, "Transaction weiAmount is incorrect");
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(weiAmount >= minPurchase, 'Have to send at least: minPurchase');
        require(weiAmount <= maxPurchase, 'Have to send max: maxPurchase');
        require((_weiRaised+weiAmount) < hardCap, 'Hard Cap reached');
        this; 
    }
    
    // Claim tokens
    function claimTokens() public nonReentrant icoNotActive {
        address beneficiary = msg.sender;
        uint256 value = _contributions[msg.sender];
        uint256 tokens = _getTokenAmount(value);
        _preValidateClaim(beneficiary);
        _processPurchase(beneficiary, tokens);
    }
    
    function _preValidateClaim(address beneficiary) internal view {
        uint256 value = _contributions[beneficiary];
        require(startRefund == false);
        require(Claimed[beneficiary] == false, 'Tokens already claimed!');
        require(_TokensPurchased[beneficiary] == _getTokenAmount(value));
        require(_AmountContribution[beneficiary] == _contributions[msg.sender]);
        this;
    }    
 
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount);
        Claimed[beneficiary] = true;
        emit Claim(msg.sender, tokenAmount);
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate).div(10**18);
    }

    function _forwardFunds() internal {
        _wallet.transfer(address(this).balance);
    }
    
     function withdraw() external onlyOwner icoNotActive{
         require(startRefund == false);
         require(address(this).balance > 0, 'Contract has no money');
        _wallet.transfer(address(this).balance);
    }
    
    function checkContribution(address addr) public view returns(uint256){
        return _contributions[addr];
    }
    
    function setRate(uint256 newRate) external onlyOwner icoNotActive{
        _rate = newRate;
    }
    
    function setAvailableTokens(uint256 amount) public onlyOwner icoNotActive{
        availableTokensICO = amount;
    }
 
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    
    function setWalletReceiver(address payable newWallet) external onlyOwner(){
        _wallet = newWallet;
    }
    
    function setHardCap(uint256 value) external onlyOwner{
        hardCap = value;
    }
    
    function setSoftCap(uint256 value) external onlyOwner{
        softCap = value;
    }
    
    function setMaxPurchase(uint256 value) external onlyOwner{
        maxPurchase = value;
    }
    
     function setMinPurchase(uint256 value) external onlyOwner{
        minPurchase = value;
    }
    
    function takeTokens(IERC20 tokenAddress)  public onlyOwner icoNotActive{
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        tokenBEP.transfer(_wallet, tokenAmt);
    }
    
    function refundMe() public icoNotActive{
        require(startRefund == true, 'No refund available');
        uint amount = _contributions[msg.sender];
		if (address(this).balance >= amount) {
			_contributions[msg.sender] = 0;
			if (amount > 0) {
			    address payable recipient = payable(msg.sender);
				recipient.transfer(amount);
				emit Refund(msg.sender, amount);
			}
		}
    }
    
    modifier icoActive() {
        require(endICO > 0 && block.timestamp < endICO && availableTokensICO > 0, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(endICO < block.timestamp, 'ICO should not be active');
        _;
    }
    
}