// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPriceAdapter.sol";


contract LiquidityCoin is Ownable, IERC20 {
    string private _name = "LiquidityCoin";
    string private _symbol = "LC";
    uint8 public _decimals = 18;
    uint256 private constant MAX = 0x0fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 public _tTotal = 10000 * 10**_decimals; //10000 * 10**18;
    uint256 public _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public liquidityCoinPriceLevel;
    address public baseToken;
    address public liquidityCoin;
    address public priceAdapterAddress;
    address public holoswapFactory;
    address[] private _excluded;
    
    uint256 percentage = 5;
    uint256 _previousPercentage = percentage;
    uint256 public _maxTxAmount = 5000000 * 10**6 * 10**9;
    address public bondAddress;
    address public stakingAddress;
    
    
    mapping (address => mapping(address => uint256)) private _allowances;
    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) private _rOwned;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;

    constructor (
        address _baseToken,
        address _liquidityCoin,  
        address _holoswapFactory, 
        address _priceAdapterAddress,
        uint256 _liquidityCoinPriceLevel
        ) {
            baseToken = _baseToken;
            //replace _liquidityCoin with the address (this) will not work,
            //because there is no pool with this token yet
            //liquidityCoin = address(this);
            liquidityCoin = _liquidityCoin;
            holoswapFactory = _holoswapFactory;
            priceAdapterAddress = _priceAdapterAddress;
            liquidityCoinPriceLevel = _liquidityCoinPriceLevel;
            _rOwned[msg.sender] = _rTotal;
            _isExcludedFromFee[msg.sender] = true;
            _isExcludedFromFee[address(this)] = true;           
    }

    modifier onlyBondOrStaking() {
        require(msg.sender == bondAddress || msg.sender == stakingAddress, '!bondOrStakingContract');
        _;
    }

    function setStakingAddress(address _stakingAddress) external onlyOwner {
        if (isExcludedFromFee(stakingAddress)) {
            _isExcludedFromFee[stakingAddress] = false;
        }
        stakingAddress = _stakingAddress;
        _isExcludedFromFee[stakingAddress] = true;
    }

    function setBondAddress(address _bondAddress) external onlyOwner {
        if (isExcludedFromFee(bondAddress)) {
            _isExcludedFromFee[bondAddress] = false;
        }
        bondAddress = _bondAddress;
        _isExcludedFromFee[bondAddress] = true;
    }

    function setLiquidityCoinPriceLevel(uint256 _liquidityCoinPriceLevel) external onlyOwner {
        liquidityCoinPriceLevel = _liquidityCoinPriceLevel;
    }

    function setBaseToken(address _baseToken) external onlyOwner {
        baseToken = _baseToken;
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

    function totalSupply() external view override returns (uint256) {
            return _tTotal;
    }

    function balanceOf(address account) external view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function transfer(
        address recipient, 
        uint256 amount
    ) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner, 
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(
        address spender, 
        uint256 addedValue
    ) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender, 
        uint256 subtractedValue
    ) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromReward(address account) external onlyOwner {
        require(!_isExcluded[account], "Account already excluded from reward");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account already included in reward");
        for (uint256 i = 0; i < _excluded.length; i++) { 
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;  
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) external onlyOwner {
        require(!_isExcludedFromFee[account], "Account already excluded from fee");
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        require(_isExcludedFromFee[account], "Account already included in fee");
        _isExcludedFromFee[account] = false;
    }

    function removeAllFee() private {
        if(percentage == 0) return;
        _previousPercentage = percentage;
        percentage = 0;
    }
    
    function restoreAllFee() private {
        percentage = _previousPercentage;
    }

    function deliver(uint256 tAmount) public {
        require(!_isExcluded[msg.sender], "Excluded addresses cannot call this function");
        (uint rAmount,,,,) = _getValues(tAmount);
        _rOwned[msg.sender] = _rOwned[msg.sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return(rAmount, rTransferAmount, rFee / 2, tTransferAmount, tFee / 2);
    }

    function _getTValues (uint256 tAmount) private view returns (uint256, uint256) {
        //multiplied by 10 for 0.5%
        uint256 tFee = (tAmount * percentage) / (100 * 10); 
        uint256 tTransferAmount = tAmount - tFee;
        return (tTransferAmount, tFee);
    }
    
    function _getPrice() public view returns (uint256 poolPrice, uint256 priceLevel){
        poolPrice = IPriceAdapter(priceAdapterAddress).getPrice(baseToken, /* address(this), */liquidityCoin, holoswapFactory);
        return (poolPrice, liquidityCoinPriceLevel);
    }

    function _getPercentage() public view returns (uint256 precentage) {
        (uint256 poolPrice, uint256 _liquidityCoinPriceLevel)= _getPrice();
        if (poolPrice >= _liquidityCoinPriceLevel) {
            return 5;
        } else if (poolPrice < _liquidityCoinPriceLevel) {
            return 5 + (((_liquidityCoinPriceLevel - poolPrice) * 100) / ( _liquidityCoinPriceLevel));
        }     
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rTransferAmount = rAmount - rFee;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        percentage = _getPercentage();

        bool takeFee = true;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
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
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function mint(address account, uint256 tAmount) external onlyBondOrStaking {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        uint256 currentRate =  _getRate();
        uint256 rAmount = tAmount * currentRate;
        _tTotal = tSupply + tAmount;
        _rTotal = rSupply + rAmount;
        _rOwned[account] = _rOwned[account] + rAmount;
    }

    function burn(address account, uint256 tAmount) external onlyBondOrStaking {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        uint256 currentRate =  _getRate();
        uint256 rAmount = tAmount * currentRate;
        _tTotal = tSupply - tAmount;
        _rTotal = rSupply - rAmount;
        _rOwned[account] = _rOwned[account] - rAmount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPriceAdapter {
    function getPrice(address baseToken, address quoteToken, address _holoswapFactory) external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}