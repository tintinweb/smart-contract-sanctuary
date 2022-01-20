/**
 *Submitted for verification at FtmScan.com on 2022-01-19
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

contract Whitelisted is Ownable {
    mapping(address=>bool) isWhiteListed;

    function whitelist(address _user) public onlyOwner {
        require(!isWhiteListed[_user], "user already whitelisted");
        isWhiteListed[_user] = true;
        // emit events as well
    }
    
    function removeFromWhitelist(address _user) public onlyOwner {
        require(isWhiteListed[_user], "user not whitelisted");
        isWhiteListed[_user] = false;
        // emit events as well
    }
    
    function checkAddress(address _to) public view returns (bool) {
        return isWhiteListed[_to];
    }
}

contract WhitelistController is Ownable {
    Whitelisted private Whitelist = new Whitelisted();

    event AddedToWhitelist(address indexed _addr);
    event RemovedFromWhitelist(address indexed _addr);

    function canSwap(address addr) public view returns (bool) {
        return isWhiteListed(addr);
    }

    function AddToWhitelist(address addr) public onlyOwner returns (bool) {
        Whitelist.whitelist(addr);
        emit AddedToWhitelist(addr);
        return true;
    }

    function RemoveFromWhitelist(address addr) public onlyOwner returns (bool) {
        Whitelist.removeFromWhitelist(addr);
        emit RemovedFromWhitelist(addr);
        return true;
    }

    function isWhiteListed(address addr) public view returns (bool) {
        return Whitelist.checkAddress(addr);
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

    address public _token;
    uint256 private _tokenDecimals;
    address payable public _wallet;
    uint256 public _rate; // rate / 10
    uint256 public _weiRaised;
    uint256 public endLBE;
    uint public minPurchase;
    uint public maxPurchase;
    uint public hardCap;
    uint public softCap;
    uint public availableTokensLBE;
    bool public startRefund = false;
    uint256 public refundStartDate;

    WhitelistController public _whitelistController;

    event TokensPurchased(address  purchaser, address  beneficiary, uint256 value, uint256 amount);
    event Refund(address recipient, uint256 amount);
    constructor (uint256 rate, address payable wallet, address token, uint256 tokenDecimals, address whitelistControllerAddress)  {
        require(rate > 0, "Pre-Sale: rate is 0");
        require(wallet != address(0), "Pre-Sale: wallet is the zero address");
        require(address(token) != address(0), "Pre-Sale: token is the zero address");
        require(whitelistControllerAddress != address(0), "Invalid whitelistController");
        
        _rate = rate; // rate / 10
        _wallet = wallet;
        _token = token;
        _tokenDecimals = 18 - tokenDecimals;
        _whitelistController = WhitelistController(whitelistControllerAddress);
    }


    receive() external payable {
        if(endLBE > 0 && block.timestamp < endLBE){
            buyTokens(_msgSender());
        }
        else{
            endLBE = 0;
            revert('Pre-Sale is closed');
        }
    }
    
    
    //Start Pre-Sale
    function startLBE(uint endDate, uint _minPurchase, uint _maxPurchase, uint _softCap, uint _hardCap) external onlyOwner lbeNotActive() {
        startRefund = false;
        refundStartDate = 0;
        availableTokensLBE = IERC20(_token).balanceOf(address(this));
        require(endDate > block.timestamp, 'duration should be > 0');
        require(_softCap < _hardCap, "Softcap must be lower than Hardcap");
        require(_minPurchase < _maxPurchase, "minPurchase must be lower than maxPurchase");
        require(availableTokensLBE > 0 , 'availableTokens must be > 0');
        require(_minPurchase > 0, '_minPurchase should > 0');
        endLBE = endDate; 
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        softCap = _softCap;
        hardCap = _hardCap;
        _weiRaised = 0;
    }
    
    function stopLBE() external onlyOwner lbeActive(){
        endLBE = 0;
        if(_weiRaised >= softCap) {
            _forwardFunds();
        }
        else{
            startRefund = true;
            refundStartDate = block.timestamp;
        }
    }
    
    
    //Pre-Sale 
    function buyTokens(address beneficiary) public nonReentrant lbeActive payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 tokens = getTokenAmount(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        availableTokensLBE = availableTokensLBE - tokens;
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(_whitelistController.isWhiteListed(beneficiary), "Address is not whitelisted!");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(weiAmount >= minPurchase, 'have to send at least: minPurchase');
        require(_contributions[beneficiary].add(weiAmount)<= maxPurchase, 'can\'t buy more than: maxPurchase');
        require((_weiRaised+weiAmount) <= hardCap, 'Hard Cap reached');
        this; 
    }

    function claimTokens() external lbeNotActive{
        require(startRefund == false);
        uint256 tokensAmt = getTokenAmount(_contributions[msg.sender]);
        _contributions[msg.sender] = 0;
        IERC20(_token).transfer(msg.sender, tokensAmt);
    }


    function getTokenAmount(uint256 weiAmount) public view returns (uint256) {
        return (weiAmount.mul(_rate).div(1000**_tokenDecimals)).div(100); // rate / 1000
    }

    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
    
     function withdraw() external onlyOwner lbeNotActive{
         require(startRefund == false || (refundStartDate + 3 days) < block.timestamp);
         require(address(this).balance > 0, 'Contract has no money');
        _wallet.transfer(address(this).balance);    
    }
    
    function checkContribution(address addr) public view returns(uint256){
        return _contributions[addr];
    }
    
    function setRate(uint256 newRate) external onlyOwner lbeNotActive{
        _rate = newRate;
    }
    
    function setAvailableTokens(uint256 amount) public onlyOwner lbeNotActive{
        availableTokensLBE = amount;
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
    
    function takeTokens(address tokenAddress)  public onlyOwner lbeNotActive{
        uint256 tokenAmt = IERC20(tokenAddress).balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        IERC20(tokenAddress).transfer(_wallet, tokenAmt);
    }
    
    function refundMe() public lbeNotActive{
        require(startRefund == true, 'no refund available');
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
    
    modifier lbeActive() {
        require(endLBE > 0 && block.timestamp < endLBE && availableTokensLBE > 0, "LBE must be active");
        _;
    }
    
    modifier lbeNotActive() {
        require(endLBE < block.timestamp, 'LBE should not be active');
        _;
    }
    
}