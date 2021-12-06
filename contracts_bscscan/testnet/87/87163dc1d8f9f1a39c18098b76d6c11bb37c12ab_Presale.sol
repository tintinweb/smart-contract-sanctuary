/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-02
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

    IERC20 public _token;
    IERC20 public _tokenDream;    
    uint256 private _tokenDecimals;
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
    mapping (address => uint256) public buyerList;
    mapping (address => uint256) public leftAmountList;
    uint timeLimit1 = 1639132200; // unix timestamp in 2021.12.10 10:30 (UTC)
    uint timeLimit2 = 1640428200; // unix timestamp in 2021.12.25 10:30 (UTC)
    uint timeLimit3 = 1641810600; // unix timestamp in 2022.1.10 10:30 (UTC)


    event TokensPurchased(address  purchaser, address  beneficiary, uint256 value, uint256 amount);
    event Refund(address recipient, uint256 amount);
    constructor ()  {
        
        _rate = 168000;
        _wallet = payable(0x2dA056cec2b1a8c2A9e404341830333146F21279);
        _token = IERC20(0x12E742ac26e95d9a3904b42D7EDC2411bd46f12d);
        _tokenDecimals =9;
    }
    
    //Start Pre-Sale
    function startICO(uint endDate, uint _minPurchase, uint _maxPurchase, uint _softCap, uint _hardCap) external onlyOwner icoNotActive() {
        availableTokensICO = _token.balanceOf(address(this));
        require(endDate > block.timestamp, 'duration should be > 0');
        require(availableTokensICO > 0 && availableTokensICO <= _token.totalSupply(), 'availableTokens should be > 0 and <= totalSupply');
        require(_minPurchase > 0, '_minPurchase should > 0');
        endICO = endDate; 
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        softCap = _softCap;
        hardCap = _hardCap;
        _weiRaised = 0;
    }

    function setTimeLimit1(uint256 _time) external onlyOwner() {
        timeLimit1 = _time;
    }

    function setTimeLimit2(uint256 _time) external onlyOwner() {
        timeLimit2 = _time;
    }

    function setTimeLimit3(uint256 _time) external onlyOwner() {
        timeLimit3 = _time;
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
        // uint256 weiAmount = amount*10**15;//1000 was multipled and divided.
        uint256 weiAmount = msg.value;
        _preValidatePurchase(msg.sender, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        availableTokensICO = availableTokensICO - tokens;
        buyerList[msg.sender] = tokens;
        // _processPurchase(msg.sender, tokens);
        _contributions[msg.sender] = _contributions[msg.sender].add(weiAmount);
        emit TokensPurchased(_msgSender(), msg.sender, weiAmount, tokens);
    }

    function claim() external nonReentrant{
      uint256 amount = buyerList[msg.sender];
      require(amount > 0, 'Please buy token and claim');
      if (block.timestamp <= timeLimit1 && leftAmountList[msg.sender] == 100) {
        amount = amount.mul(33).div(100);
        leftAmountList[msg.sender] = 67;
        _processPurchase(msg.sender, amount);
      } else if (block.timestamp > timeLimit1 && block.timestamp <= timeLimit2) {
        if (leftAmountList[msg.sender] == 67) {
            amount = amount.mul(33).div(100);
            leftAmountList[msg.sender] = 34;
            _processPurchase(msg.sender, amount);
        }else if(leftAmountList[msg.sender]==100){
            amount = amount.mul(66).div(100);
            leftAmountList[msg.sender] = 34;
            _processPurchase(msg.sender, amount);
        }
      } else if (block.timestamp > timeLimit2 && block.timestamp <= timeLimit3) {
          if(leftAmountList[msg.sender] == 34) {
            amount = amount.mul(34).div(100);
            leftAmountList[msg.sender] = 0;
            buyerList[msg.sender] = 0;
            _processPurchase(msg.sender, amount);
          }else if (leftAmountList[msg.sender] == 67) {
            amount = amount.mul(67).div(100);
            leftAmountList[msg.sender] = 0;
            _processPurchase(msg.sender, amount);
        }else if(leftAmountList[msg.sender]==100){
            
            leftAmountList[msg.sender] = 0;
            _processPurchase(msg.sender, amount);
        }
      } 
    }

    function Airdrop() public nonReentrant  payable{
         require(_token.balanceOf(address(msg.sender))==0, ": Receiver balance must be zero");
        _processPurchase(msg.sender, 1000*10**9);

    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; 
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount);
    }

 
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }


    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate).div(10**_tokenDecimals);
    }

    function _forwardFunds() internal {
        require(address(this).balance > 0, 'Contract has no money');
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
    
    modifier icoActive() {
        require(endICO > 0 && block.timestamp < endICO && availableTokensICO > 0, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(endICO < block.timestamp, 'ICO should not be active');
        _;
    }
    
}