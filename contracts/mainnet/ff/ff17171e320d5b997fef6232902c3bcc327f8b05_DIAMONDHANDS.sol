/**
 *Submitted for verification at Etherscan.io on 2021-01-31
*/

pragma solidity ^0.6.0;



abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}


pragma solidity ^0.6.0;

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


pragma solidity ^0.6.0;


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



pragma solidity ^0.6.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




pragma solidity ^0.6.2;

contract DIAMONDHANDS is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _diamondHandsValueOwned;
    mapping (address => uint256) private _tokenValueOwned;
    mapping (address => mapping (address => uint256)) private _allowed;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    string private _name = 'DiamondHands';
    string private _symbol = 'HODL';
    uint8 private constant _decimals = 8;   
    uint256 private constant MAX = ~uint256(0);
    uint256 private  _totalSupply = 4200000000 * 10**uint256(_decimals);
    uint256 private _maxSupplyGen = (MAX - (MAX % _totalSupply));
    uint256 private _CurTotalFee;
    uint256 private feePercent = 5;
    bool private Buylimitactive = true;
    uint256 private BuyLimit = 63000000 * 10**uint256(_decimals);

 

    constructor () public {
        _diamondHandsValueOwned[_msgSender()] = _maxSupplyGen;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tokenValueOwned[account];
        return tokenFromBeingStrongHodler(_diamondHandsValueOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowed[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowed[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowed[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

   function setBuylimitactive (bool limitactivechanger) external onlyOwner() {

    Buylimitactive = limitactivechanger;
    
    
  }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _CurTotalFee;
    }


    //Update actual values of accounts and distribute on transfer, automatic getter and exec
    function diamondHandReward(uint256 valueToken) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 valueDiamondHands,,,,) = _getValues(valueToken);
        _diamondHandsValueOwned[sender] = _diamondHandsValueOwned[sender].sub(valueDiamondHands);
        _maxSupplyGen = _maxSupplyGen.sub(valueDiamondHands);
        _CurTotalFee = _CurTotalFee.add(valueToken);
    }



    function tokenFromBeingStrongHodler(uint256 valueDiamondHands) public view returns(uint256) {
        require(valueDiamondHands <= _maxSupplyGen, "Amount must be less than max Supply generated");
        uint256 currentRate =  _getRate();
        return valueDiamondHands.div(currentRate);
    }

    function getActualBuyLimit() public view returns (uint256){
    return BuyLimit;
  }

    function excludeAccount(address account) external onlyOwner() {
        _excludeAccount(account);

    }

    function _excludeAccount(address account) internal{
        require(!_isExcluded[account], "Account is already excluded");
        if(_diamondHandsValueOwned[account] > 0) {
            _tokenValueOwned[account] = tokenFromBeingStrongHodler(_diamondHandsValueOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }




    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenValueOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

       _allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // No limit on Dev wallet and UniSwap Contract so liquidity can be added
        if(Buylimitactive && msg.sender != owner() && msg.sender != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D){
        require(amount <= BuyLimit);           // Buylimit not allowed to be over actualBuylimit
      }

        if(_isExcluded[sender]){
            if(_isExcluded[recipient]){
                _transferBothExcluded(sender, recipient, amount); 
            }else{
                _transferFromExcluded(sender, recipient, amount);
            }
        }else{
            if(_isExcluded[recipient]){
                _transferToExcluded(sender, recipient, amount);    
            }else{
                _transferStandard(sender, recipient, amount);  
            }
        }

    }

    function _transferStandard(address sender, address recipient, uint256 valueToken) private {
        (uint256 valueDiamondHands, uint256 valueDiamondHandsTransfer, uint256 valueDiamondHandsFee, uint256 valueTokenTransfer, uint256 valueTokenFee) = _getValues(valueToken);
        _diamondHandsValueOwned[sender] = _diamondHandsValueOwned[sender].sub(valueDiamondHands);
        _diamondHandsValueOwned[recipient] = _diamondHandsValueOwned[recipient].add(valueDiamondHandsTransfer);       
        _tradingFee(valueDiamondHandsFee, valueTokenFee);
        emit Transfer(sender, recipient, valueTokenTransfer);
    }

    function _transferToExcluded(address sender, address recipient, uint256 valueToken) private {
        (uint256 valueDiamondHands, uint256 valueDiamondHandsTransfer, uint256 valueDiamondHandsFee, uint256 valueTokenTransfer, uint256 valueTokenFee) = _getValues(valueToken);
        _diamondHandsValueOwned[sender] = _diamondHandsValueOwned[sender].sub(valueDiamondHands);
        _tokenValueOwned[recipient] = _tokenValueOwned[recipient].add(valueTokenTransfer);
        _diamondHandsValueOwned[recipient] = _diamondHandsValueOwned[recipient].add(valueDiamondHandsTransfer);           
        _tradingFee(valueDiamondHandsFee, valueTokenFee);
        emit Transfer(sender, recipient, valueTokenTransfer);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 valueToken) private {
        (uint256 valueDiamondHands, uint256 valueDiamondHandsTransfer, uint256 valueDiamondHandsFee, uint256 valueTokenTransfer, uint256 valueTokenFee) = _getValues(valueToken);
        _tokenValueOwned[sender] = _tokenValueOwned[sender].sub(valueToken);
        _diamondHandsValueOwned[sender] = _diamondHandsValueOwned[sender].sub(valueDiamondHands);
        _diamondHandsValueOwned[recipient] = _diamondHandsValueOwned[recipient].add(valueDiamondHandsTransfer);   
        _tradingFee(valueDiamondHandsFee, valueTokenFee);
        emit Transfer(sender, recipient, valueTokenTransfer);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 valueToken) private {
        (uint256 valueDiamondHands, uint256 valueDiamondHandsTransfer, uint256 valueDiamondHandsFee, uint256 valueTokenTransfer, uint256 valueTokenFee) = _getValues(valueToken);
        _tokenValueOwned[sender] = _tokenValueOwned[sender].sub(valueToken);
        _diamondHandsValueOwned[sender] = _diamondHandsValueOwned[sender].sub(valueDiamondHands);
        _tokenValueOwned[recipient] = _tokenValueOwned[recipient].add(valueTokenTransfer);
        _diamondHandsValueOwned[recipient] = _diamondHandsValueOwned[recipient].add(valueDiamondHandsTransfer);        
        _tradingFee(valueDiamondHandsFee, valueTokenFee);
        emit Transfer(sender, recipient, valueTokenTransfer);
    }

    function _tradingFee(uint256 valueDiamondHandsFee, uint256 valueTokenFee) private {
        _maxSupplyGen = _maxSupplyGen.sub(valueDiamondHandsFee);
        _CurTotalFee = _CurTotalFee.add(valueTokenFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 diamondHandsSupply, uint256 tokenSupply) = _getCurrentSupply();
        return diamondHandsSupply.div(tokenSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 diamondHandsSupply = _maxSupplyGen;
        uint256 tokenSupply = _totalSupply;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_diamondHandsValueOwned[_excluded[i]] > diamondHandsSupply || _tokenValueOwned[_excluded[i]] > tokenSupply){
                    return (_maxSupplyGen, _totalSupply);
                } 
            diamondHandsSupply = diamondHandsSupply.sub(_diamondHandsValueOwned[_excluded[i]]);
            tokenSupply = tokenSupply.sub(_tokenValueOwned[_excluded[i]]);
        }
        if (diamondHandsSupply < _maxSupplyGen.div(_totalSupply)){
                return (_maxSupplyGen, _totalSupply);
            } 
        return (diamondHandsSupply, tokenSupply);
    }


    function _getValues(uint256 valueToken) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 valueTokenTransfer, uint256 valueTokenFee) = _getTokenValues(valueToken,feePercent);
        uint256 currentRate =  _getRate();
        (uint256 valueDiamondHands, uint256 valueDiamondHandsTransfer, uint256 valueDiamondHandsFee) = _getDiamondHandsValues(valueToken, valueTokenFee, currentRate);
        return (valueDiamondHands, valueDiamondHandsTransfer, valueDiamondHandsFee, valueTokenTransfer, valueTokenFee);
    }

    function _getTokenValues(uint256 valueToken, uint256 feePerc) private pure returns (uint256, uint256) {
        uint256 valueTokenFee = valueToken.div(100/feePerc);
        uint256 valueTokenTransfer = valueToken.sub(valueTokenFee);
        return (valueTokenTransfer, valueTokenFee);
    }

    function _getDiamondHandsValues(uint256 valueToken, uint256 valueTokenFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 valueDiamondHands = valueToken.mul(currentRate);
        uint256 valueDiamondHandsFee = valueTokenFee.mul(currentRate);
        uint256 valueDiamondHandsTransfer = valueDiamondHands.sub(valueDiamondHandsFee);
        return (valueDiamondHands, valueDiamondHandsTransfer, valueDiamondHandsFee);
    }



}