/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: Unlicensed

/**
   #AutoCoin(Hard)
   2% fee auto add brn
   2% fee auto distribute com  
   2% fee auto moved dev
*/

pragma solidity ^0.8.3;

library SafeMath {
    
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    

}


contract HARCoin {
   using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    
    address[] private _excluded;
    address private _devWalletAddress = 0x57Ce40D617fb2d35BA0C1B351b9EcD4411248315;
    address private _comWalletAddress = 0x17475d218eC245bEC724025dC1F5b3032F90D44B;
    address private _burnWalledAddress =0xAac0f0e1A632EeD215C3d1D97B9950cd409a1224;
    uint256 private constant MAX = ~uint256(0);
    uint256 public _tTotal = 1000000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string public _name = "HARCoin";
    string public _symbol = "HAR";
    uint8 public _decimals = 18;
    
    uint256 public _burnFee = 2;
    uint256 private _previousburnFee = _burnFee;
    
    uint256 public _devFee = 2;
    uint256 private _previousDevFee = _devFee;
    uint256 public _comFee = 2;
    uint256 private _previousComFee = _comFee;

    uint256 public _maxTxAmount = 5000000 * 10**6 * 10**9;
    
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
    
    
    function owner() public returns (address) {
        return _owner = 0x0Dccf7ce6BCd2426f23E974e89684E9580413b7c;
    }
     
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
   /* constructor () {
       _rOwned[owner()] = _rTotal;
        emit OwnershipTransferred(address(0), _owner);
    }*/
    constructor () {
         
        _rOwned[owner()] = _rTotal;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), owner(), _tTotal);
    }
 /**0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
     * @dev Returns the address of the current owner.
     * 0x0Dccf7ce6BCd2426f23E974e89684E9580413b7c MM
     */
   

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _tOwned[account];
        
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

   

  
    
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) internal view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) internal view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
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
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
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
        uint256 tTransferAmount = tAmount.sub(tBurn).sub(tCom).sub(tDev);
        return (tTransferAmount,tBurn, tCom, tDev);
    }

    function _getRValues(uint256 tAmount, uint256 tBurn, uint256 tCom, uint256 tDev, uint256 currentRate) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rCom = tCom.mul(currentRate);
        uint256 rDev = tDev.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rBurn).sub(rCom).sub(rDev);
        return (rAmount, rTransferAmount);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    
    function _takeCom(uint256 tCom) private {
        uint256 currentRate =  _getRate();
        uint256 rCom = tCom.mul(currentRate);
        _rOwned[_comWalletAddress] = _rOwned[_comWalletAddress].add(rCom);
        if(_isExcluded[_comWalletAddress])
            _tOwned[_comWalletAddress] = _tOwned[_comWalletAddress].add(tCom);
    }
    
    
    function _takeDev(uint256 tDev) private {
        uint256 currentRate =  _getRate();
        uint256 rDev = tDev.mul(currentRate);
        _rOwned[_devWalletAddress] = _rOwned[_devWalletAddress].add(rDev);
        if(_isExcluded[_devWalletAddress])
            _tOwned[_devWalletAddress] = _tOwned[_devWalletAddress].add(tDev);
    }
     function _takeBurn(uint256 tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[_burnWalledAddress] = _rOwned[_burnWalledAddress].add(rBurn);
        if(_isExcluded[_burnWalledAddress])
            _tOwned[_burnWalledAddress] = _tOwned[_burnWalledAddress].add(tBurn);
    }
    
    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**2
        );
    }

    function calculateDevFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_devFee).div(
            10**2
        );
    }

    function calculateComFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_comFee).div(
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
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount);
    }

   
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        
            _transferStandard(sender, recipient, amount);
        }
        
       

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tBurn, uint256 tCom, uint256 tDev) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeCom(tCom);
        _takeDev(tDev);
        _takeBurn(tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}