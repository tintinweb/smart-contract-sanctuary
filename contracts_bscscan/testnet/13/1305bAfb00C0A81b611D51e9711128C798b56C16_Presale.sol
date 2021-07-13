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
    
    mapping (address => uint256) private _contributions;

    IERC20 public token;
    uint256 private tokenDecimals;
    address payable public wallet;
    uint256 public rate;
    uint256 public weiRaised;
    uint256 public endICO;
    uint public maxPurchase;
    uint public hardCap;
    uint public softCap;
    uint public availableTokensICO;
    bool public startRefund;
    uint public contributorsRewarded;
    bool public presaleStarted;
    bool public presaleSuccess;
    address public pancakePair;
    uint public numOfContributors;

    event TokensPurchased(address  purchaser, address  beneficiary, uint256 value, uint256 amount);
    event Refund(address recipient, uint256 amount);
    constructor (uint256 _rate, address payable _wallet, IERC20 _token, uint256 _tokenDecimals, address _pancakePair)  {
        require(_rate > 0, "Pre-Sale: rate is 0");
        require(_wallet != address(0), "Pre-Sale: wallet is the zero address");
        require(address(_token) != address(0), "Pre-Sale: token is the zero address");
        rate = _rate;
        wallet = _wallet;
        token = _token;
        tokenDecimals = 18 - _tokenDecimals;
        pancakePair = _pancakePair;
    }


    receive () external payable {
            buyTokens(msg.sender);
    }
    
    
    //Start Pre-Sale
    function startICO(uint hours_duration, uint _maxPurchase, uint _softCap, uint _hardCap) external onlyOwner icoNotActive() {
        require(!presaleStarted);
        uint amountToBeTranferred = _hardCap.mul(rate);
        availableTokensICO = amountToBeTranferred;
        token.transferFrom(msg.sender,address(this), amountToBeTranferred);
        require(hours_duration > 0, 'duration should be > 0');
        require(availableTokensICO > 0 && availableTokensICO <= token.totalSupply(), 'availableTokens should be > 0 and <= totalSupply');
        require(_maxPurchase>0, '_maxPurchase should be > 0');
        endICO = block.timestamp.add(hours_duration.mul(3600)); 
        maxPurchase = _maxPurchase;
        softCap = _softCap;
        hardCap = _hardCap;
        weiRaised = 0;
        presaleStarted = true;
    }
    function getICOFunds() external onlyOwner icoNotActive() {
        require( presaleStarted);
        endICO = 0;
        presaleSuccess = weiRaised >= softCap;
        if(presaleSuccess) {
        wallet.transfer(address(this).balance);
        }
        else{
            startRefund = true;
        }
    }
    
    
    //Pre-Sale 
    function buyTokens(address beneficiary) public nonReentrant icoActive payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        availableTokensICO = availableTokensICO.sub(tokens);
        if(_contributions[beneficiary]==0 && weiAmount>0)
        {
            numOfContributors = numOfContributors.add(1);
        }
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(presaleStarted && endICO > 0 && block.timestamp < endICO, 'Pre-Sale is closed');
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(_contributions[beneficiary].add(weiAmount)<= maxPurchase, 'can\'t buy more than: maxPurchase');
        require((weiRaised.add(weiAmount)) <= hardCap, 'Hard Cap reached');
        this; 
    }
        
    function claim() external icoNotActive {
        
        require(token.balanceOf(pancakePair)>0, "Liquidity not added yet!");
        require(_contributions[msg.sender]>0, "You don't have anything to claim");
        uint256 tokens = _getTokenAmount(_contributions[msg.sender]);
        _contributions[msg.sender] = 0;
        contributorsRewarded = contributorsRewarded.add(1);
        token.transfer(msg.sender, tokens);
    }
        

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(rate).div(10**tokenDecimals);
    }
    
    function checkContribution(address addr) public view returns(uint256){
        return _contributions[addr];
    }

    function recoverTokensStuck(IERC20 tokenAddress)  public onlyOwner icoNotActive{
        require(tokenAddress != token);
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        tokenBEP.transfer(wallet, tokenAmt);
    }
    
    function refundMe() public icoNotActive{
        
        if(!startRefund && weiRaised < softCap && presaleStarted)
        {
            startRefund = true;
        }
        require(startRefund, 'no refund available');
        uint amount = _contributions[msg.sender];
        require(amount > 0, "You don't have anything to claim");
		require(address(this).balance >= amount && amount > 0, "balance of the contract is not sufficient");
		_contributions[msg.sender] = 0;
		address payable recipient = payable(msg.sender);
		recipient.transfer(amount);
		emit Refund(msg.sender, amount);
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