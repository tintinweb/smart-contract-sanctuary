/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// SPDX-License-Identifier: Unlicensed

/**
   #HorrorToken(HT)
   2% fee auto add to a burn address and will be reduced from total supply
   2% fee auto add to community wallet
   2% fee auto moved to development aaccount
*/

pragma solidity ^0.8.3;
contract HorribeToken {
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    
    address[] private _excluded;
   
    address public _devWalletAddress = 0xd5665F306126648161eDA31597B36Ee66d63f5C1;
    address public _comWalletAddress = 0x8Af4D704E58f6f0ed62913f2c12ab27D25db239f;
    address private _burnWalledAddress = 0x8D994a6D2BB18f40432435F17a7235A0c1692cb6;
    uint256 private constant MAX = ~uint256(0);
    uint256 public _tTotal = 1000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
     string public _name = "HorribeToken";
     string public _symbol = "HrT";
     uint public _decimals = 18;
    
    uint256 public _burnFee = 2;
    uint256 private _previousBurnFee = _burnFee;
    
    uint256 public _devFee = 2;
    uint256 private _previousDevFee = _devFee;
    uint256 public _comFee = 2;
    uint256 private _previousComFee = _comFee;

 
    
    address private _owner;
     
    event Transfer(address indexed sender, address indexed recipient, uint256 value);
    event Approval(address indexed _msgSender, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    
    
    function owner() private view returns (address) {
        return _owner;
    }
     
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
  
         
    constructor () {
       
       _owner = 0x92bF0a96F5F82Da3420e807e68e261e8f9f036dB;
        emit OwnershipTransferred(address(0), _owner);
       
       _rOwned[owner()] = _rTotal;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

   function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

   function allowance(address _who, address _to) public view returns (uint256) {
        return _allowances[_who][_to];
    }
    
    function totalFees() internal view returns (uint256) {
        return _tFeeTotal;
    }
    
    function reflectionFromToken(uint256 tAmount) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
           
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }
     function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tBurn, uint256 tCom, uint256 tDev) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);        
        _takeCom(tCom);
        _takeDev(tDev);
        _takeBurn(tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    
    }
   
      function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }

    function setDevFeePercent(uint256 devFee) external onlyOwner() {
        _devFee = devFee;
    }
    
    function setComFeePercent(uint256 comFee) external onlyOwner() {
        _comFee = comFee;
    }
   //transaction
   
    

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - (rFee);
        _tFeeTotal = _tFeeTotal + (tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tBurn, uint256 tCom, uint256 tDev) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, tBurn, tCom, tDev, _getRate());
        return (rAmount, rTransferAmount,tTransferAmount, tBurn, tCom, tDev);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tCom = calculateComFee(tAmount);
        uint256 tDev = calculateDevFee(tAmount);
        uint256 tTransferAmount = tAmount - (tBurn + tCom + tDev);
        return (tTransferAmount,tBurn, tCom, tDev);
    }

    function _getRValues(uint256 tAmount, uint256 tBurn, uint256 tCom, uint256 tDev, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rBurn = tBurn * currentRate;
        uint256 rCom = tCom * currentRate;
        uint256 rDev = tDev * currentRate;
        uint256 rTransferAmount = rAmount - (rBurn + rCom + rDev);
        return (rAmount, rTransferAmount);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - (_rOwned[_excluded[i]]);
            tSupply = tSupply - (_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    
    function _takeCom(uint256 tCom) private {
        uint256 currentRate =  _getRate();
        uint256 rCom = tCom * currentRate;
        _rOwned[_comWalletAddress] = _rOwned[_comWalletAddress] + (rCom);
        if(_isExcluded[_comWalletAddress])
            _tOwned[_comWalletAddress] = _tOwned[_comWalletAddress] + (tCom);
    }
    
    
    function _takeDev(uint256 tDev) private {
        uint256 currentRate =  _getRate();
        uint256 rDev = tDev * currentRate;
        _rOwned[_devWalletAddress] = _rOwned[_devWalletAddress] + (rDev);
        if(_isExcluded[_devWalletAddress])
            _tOwned[_devWalletAddress] = _tOwned[_devWalletAddress] + (tDev);
    }
     function _takeBurn(uint256 tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn * currentRate;
        _rOwned[_burnWalledAddress] = _rOwned[_burnWalledAddress] + (rBurn);
        
        if(_isExcluded[_burnWalledAddress])
            _tOwned[_burnWalledAddress] = _tOwned[_burnWalledAddress] + (tBurn);
           
    }
    
    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return (_amount *_burnFee)/
        10**2
            
        ;
    }
   
    function calculateDevFee(uint256 _amount) private view returns (uint256) {
        return (_amount *_devFee)/(
        10**2
            
        );
    }

    function calculateComFee(uint256 _amount) private view returns (uint256) {
        return (_amount *_comFee)/(
            10**2
        );
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

   

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) public {
        require(amount > 0, "Transfer amount must be greater than zero");
        

        
        
        bool takeFee = true;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        
        _tokenTransfer(from,to,amount,takeFee);
    }
     function removeAllFee() private {
       _previousBurnFee = _burnFee;
        _previousDevFee = _devFee;
        _previousComFee =  _comFee;
        
        _burnFee = 0;
        _devFee = 0;
        _comFee = 0;
    }
    
    function restoreAllFee() private {
        _burnFee = _previousBurnFee;
        _devFee = _previousDevFee;
        _comFee = _previousComFee;
    }
   
    
   function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }
       

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tBurn, uint256 tCom, uint256 tDev) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeCom(tCom);
        _takeDev(tDev);
        _takeBurn(tBurn);
        _tTotal = _tTotal - tBurn;
        emit Transfer(sender, recipient, tTransferAmount);
    }
    

   

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tBurn, uint256 tCom, uint256 tDev) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);          
        _takeCom(tCom);
        _takeDev(tDev);
        _takeBurn(tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tBurn, uint256 tCom, uint256 tDev) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);   
        _takeCom(tCom);
        _takeDev(tDev);
        _takeBurn(tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

}