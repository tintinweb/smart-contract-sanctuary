/**
 *Submitted for verification at BscScan.com on 2021-09-04
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

contract JadeiteSale is ReentrancyGuard, Context, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) internal _contributions;
    mapping (address => bool) internal _earlyInvestor;

    IERC20 public _token;
    address payable public _wallet;
    uint256 public _rate;
    uint256 public _weiRaised;
    uint256 public endSale;
    uint public minPurchase;
    uint public maxPurchase;
    uint public hardCap;
    uint public availableTokensSale;
    uint private previousProcent;
    uint public procent = previousProcent;
    uint256 public endBonus;

    event TokensTransfer(address indexed beneficiary, uint256 amount);
    event earlyInvestor(address _address);
    constructor (uint256 rate, address payable wallet, IERC20 token)  {
        require(rate > 0, "Sale: rate is 0");
        require(wallet != address(0), "Sale: wallet is the zero address");
        require(address(token) != address(0), "Sale: token is the zero address");
        
        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

    //Add early investors wallets
    function bulkAddEarlyInvestors(address[] memory _addresses) public onlyOwner {
        require(_addresses.length != 0);
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0));
            _earlyInvestor[_addresses[i]] = true;
            emit earlyInvestor(_addresses[i]);
        }
    }

    receive () external payable {
        if(endSale > 0 && block.timestamp < endSale){
            buyTokens();
        }
        else{
            revert("Sale is closed");
        }
    }
    
    
    //Start Sale
    function startSale(uint endDate, uint _minPurchase, uint _maxPurchase, uint _hardCap, uint _procent, uint _endBonus) external onlyOwner SaleNotActive() {
        availableTokensSale = _token.balanceOf(address(this));
        require(endDate > block.timestamp, "Duration should be > 0");
        require(availableTokensSale > 0 && availableTokensSale <= _token.totalSupply(), "availableTokens should be > 0 and <= totalSupply");
        require(_minPurchase > 0, "_minPurchase should > 0");
        endSale = endDate;
        endBonus = _endBonus;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        hardCap = _hardCap;
        previousProcent = _procent;
        _weiRaised = 0;
    }
    
    function stopSale() external onlyOwner SaleActive() {
        endSale = 0;
        _forwardFunds();
    }
    
    
    //Buy JDT Tokens 
    function buyTokens() public SaleActive payable {
        uint256 weiAmount = msg.value;
        address beneficiary = msg.sender;
        _preValidatePurchase(beneficiary, weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
        //Bonus allocation round
        if(block.timestamp <= endBonus && procent > 0) {
            if (_earlyInvestor[beneficiary] == true) {
                procent = procent + 5;
                _earlyInvestor[beneficiary] = false;
            }
            uint bonus = procent.mul(weiAmount).div(100);
            uint256 bonusTokens = _getTokenAmount(bonus);
            procent = previousProcent;
            uint256 standardTokens = _getTokenAmount(weiAmount);
            uint256 tokens = bonusTokens+standardTokens;
            availableTokensSale = availableTokensSale - tokens;
            _processPurchase(beneficiary, tokens);
        }
        //Standard Transfer
        else {
            uint256 tokens = _getTokenAmount(weiAmount);
            availableTokensSale = availableTokensSale - tokens;
            _processPurchase(beneficiary, tokens);
        }
        
    }
    
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(_contributions[beneficiary]+weiAmount <= maxPurchase, "Reached maxPurchase");
        require(weiAmount != 0, "WeiAmount is 0");
        require(weiAmount >= minPurchase, "Have to send at least: minPurchase");
        require(weiAmount <= maxPurchase, "Have to send max: maxPurchase");
        require((_weiRaised+weiAmount) <= hardCap, "Hard Cap reached");
        this; 
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount);
        emit TokensTransfer(beneficiary, tokenAmount);
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
    
     function withdraw() external onlyOwner {
         require(address(this).balance > 0, "Contract has no money");
        _wallet.transfer(address(this).balance);
    }
    
    function checkContribution(address _address) public view returns (uint256) {
        return _contributions[_address];
    }
    
    function checkEarlyInvestor(address _address) public view returns (bool) {
        return _earlyInvestor[_address];
    }
    function setRate(uint256 newRate) external onlyOwner {
        _rate = newRate;
    }
    
    function setAvailableTokens(uint256 amount) public onlyOwner SaleNotActive {
        availableTokensSale = amount;
    }
 
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    
    function setWalletReceiver(address payable newWallet) external onlyOwner() {
        _wallet = newWallet;
    }
    
    function setHardCap(uint256 value) external onlyOwner {
        hardCap = value;
    }
    
    function SetProcent(uint256 value) external onlyOwner {
        procent = value;
    }
    
    function setMaxPurchase(uint256 value) external onlyOwner {
        maxPurchase = value;
    }
    
     function setMinPurchase(uint256 value) external onlyOwner {
        minPurchase = value;
    }
    
    function setEndBonus(uint256 value) external onlyOwner {
        endBonus = value;
    }
    
    function takeTokens(IERC20 tokenAddress) external onlyOwner {
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, "BEP-20 balance is 0");
        tokenBEP.transfer(_wallet, tokenAmt);
    }
    
    
    modifier SaleActive() {
        require(endSale > 0 && block.timestamp < endSale && availableTokensSale > 0, "Sale must be active");
        _;
    }
    
    modifier SaleNotActive() {
        require(endSale < block.timestamp, "Sale should not be active");
        _;
    }
    
}