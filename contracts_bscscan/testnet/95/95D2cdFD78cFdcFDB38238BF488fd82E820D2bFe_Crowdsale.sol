// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './COC.sol';
import './IBEP20.sol';
import './utils/Ownable.sol';


contract Crowdsale is Ownable {
    address tokenContract;
    
    uint salesIndex;
    mapping(uint => Sale) private sales;
    
    event NewSale(uint salesIndex, uint startDate, uint endDate, uint quantity, uint price);
    event Buy(address buyer, uint quantity, uint price);

    struct Sale {
        uint startDate;
        uint endDate;
        uint quantity;
        uint price;
    }

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
        salesIndex = 0;
    }

    function changeTokenContract
    (
        address _tokenContract
    ) 
        public
        onlyOwner
        returns (bool)
    {
        tokenContract = _tokenContract;
        return true;
    }

    function createSale(
        uint _startDate, 
        uint _endDate, 
        uint _quantity, 
        uint _price
    ) 
        public 
        onlyOwner
        returns (bool) 
    {
        require(_startDate < block.timestamp, "start date is in the past");
        require(_endDate < block.timestamp, "end date is in the past");
        require(_startDate < _endDate, "starting date should be lower than end date");
        if(salesIndex != 0) {
            require(block.timestamp < sales[salesIndex].endDate, "Previous sale is not closed yet");
        }
        require(IBEP20(tokenContract).allowance(msg.sender, address(this)) <= _quantity, "not enough allowance");
        require(IBEP20(tokenContract).transferFrom(msg.sender, address(this), _quantity));
        salesIndex == salesIndex++;
        Sale storage c = sales[salesIndex];
        c.startDate = _startDate;
        c.endDate = _endDate;
        c.quantity = _quantity;
        c.price = _price;
        emit NewSale(salesIndex, _startDate, _endDate, _quantity, _price);
        return true;
    }

    function buy(
        uint _amount
    )
        public
        payable 
        returns (bool)
    {
        Sale storage c = sales[salesIndex];
        require(msg.value == _amount * c.price, "Price doesn't match quantity");
        require(block.timestamp > c.startDate, "Sale didn't start yet.");
        require(block.timestamp < c.endDate, "Sale is already closed.");
        require(_amount < c.quantity, "Amount over the limit");
        uint amount = _amount * c.price;
        IBEP20(tokenContract).transfer(msg.sender, amount);
        emit Buy(msg.sender, amount, c.price);
        return true;
    }

    function forceClose()
        public
        onlyOwner
        returns (bool)
    {
        // TODO: add requirements
        Sale storage c = sales[salesIndex];
        require(c.endDate > block.timestamp, "sale is already closed");
        c.endDate = block.timestamp;
        // address payable to = payable(msg.sender);
        address to = msg.sender;
        IBEP20(tokenContract).transfer(to, c.quantity);
        return true;
    }

    function getBalance() 
        internal 
        view 
        returns(uint) 
    {
        return address(this).balance;
    }

    function withdrawToken(uint _salesIndex) 
        public
        onlyOwner
        returns (bool)
    {
        Sale storage c = sales[_salesIndex];
        require(c.endDate > block.timestamp, "sale is not closed yet");
        require(c.quantity > 0, "no tokens to withdraw");
        address payable to = payable(msg.sender);
        IBEP20(tokenContract).transfer(to, c.quantity);
        return true;
    }

    function withdrawBNB() 
        public
        onlyOwner
        returns (bool)
    {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
        return true;
    }


}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import "./utils/SafeMath.sol";
import "./IBEP20.sol";
import "./utils/Context.sol";

contract COC is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    uint256 private _GRANULARITY = 100;
    uint256 _TAX_FEE;
    uint256 private _PREVIOUS_TAX_FEE = _TAX_FEE;
    uint256 _BURN_FEE;
    uint256 private _PREVIOUS_BURN_FEE = _BURN_FEE;

    uint256 private constant _MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;

    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcludedFromReward;
    address[] private _excludedFromReward;

    constructor(string memory name_, string memory symbol_, uint256 decimals_, uint256 taxFee_, uint256 burnFee_){
        _name = name_;
        _symbol = symbol_;
        _decimals = uint8(decimals_);
        _TAX_FEE = taxFee_ * _GRANULARITY;
        _BURN_FEE = burnFee_ * _GRANULARITY;

        _tTotal = 10000000000000000 * (10 ** _decimals);
        _rTotal = (_MAX - (_MAX % _tTotal));

        //exclude owner and this contract from fee
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;

        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0),_msgSender(), _tTotal);
    }

    /**
    * @dev Returns the token name.
    */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    /**
    * @dev Returns the tax fee
    */
    function getTaxFee() public view returns (uint256) {
        return _TAX_FEE / _GRANULARITY;
    }

    /**
    * @dev Returns the burn fee
    */
    function getBurnFee() public view returns (uint256) {
        return _BURN_FEE / _GRANULARITY;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "BEP20: transfer amount must be greater than zero");

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
            removeAllFee();
        }

        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee)
            restoreAllFee();

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
    * @dev Add the address from the list of addresses excluded from rewards
    * Can only be called by the current owner.
    * Requirements:
    *
    * - `account` is not already excluded
    */
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    /**
    * @dev Removes the address from the list of addresses excluded from rewards
    * Can only be called by the current owner.
    *
    * Requirements:
    *
    * - `account` is excluded
    */
    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }

    /**
    * @dev Returns if the address is excluded from reward
    */
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    /**
    * @dev Set address of account as excluded from fee
    * Can only be called by the current owner.
    */
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    /**
    * @dev Set address of account as included from fee
    * Can only be called by the current owner.
    */
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**
    * @dev Returns if the address is excluded from fee
    */
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function removeAllFee() private {
        if(_TAX_FEE == 0 && _BURN_FEE == 0) return;

        _PREVIOUS_TAX_FEE = _TAX_FEE;
        _PREVIOUS_BURN_FEE = _BURN_FEE;

        _TAX_FEE = 0;
        _BURN_FEE = 0;
    }

    function restoreAllFee() private {
        _TAX_FEE = _PREVIOUS_TAX_FEE;
        _BURN_FEE = _PREVIOUS_BURN_FEE;
    }

    function _reflectFee(uint256 rFee_, uint256 rBurn_, uint256 tFee_, uint256 tBurn_) private {
        _rTotal = _rTotal.sub(rFee_).sub(rBurn_);
        _tTotal = _tTotal.sub(tBurn_);
        _tFeeTotal = _tFeeTotal.add(tFee_).add(tBurn_);
        _tBurnTotal = _tBurnTotal.add(tBurn_);
        emit Transfer(address(this), address(0), tBurn_);
    }

    /**
    * @dev Returns fee total value
    */
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    /**
    * @dev Returns burn total value
    */
    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }

    function _transferStandard(address sender_, address recipient_, uint256 tAmount_) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn, , uint256 tFee, uint256 tBurn) = _getTransferValues(tAmount_);

        _rOwned[sender_] = _rOwned[sender_].sub(rAmount);
        _rOwned[recipient_] = _rOwned[recipient_].add(rTransferAmount);

        _reflectFee(rFee, rBurn, tFee, tBurn);
    }

    function _transferFromExcluded(address sender_, address recipient_, uint256 tAmount_) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn, , uint256 tFee, uint256 tBurn) = _getTransferValues(tAmount_);
        _tOwned[sender_] = _tOwned[sender_].sub(tAmount_);
        _rOwned[sender_] = _rOwned[sender_].sub(rAmount);
        _rOwned[recipient_] = _rOwned[recipient_].add(rTransferAmount);
        _reflectFee(rFee, rBurn, tFee, tBurn);
    }

    function _transferToExcluded(address sender_, address recipient_, uint256 tAmount_) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getTransferValues(tAmount_);
        _rOwned[sender_] = _rOwned[sender_].sub(rAmount);
        _tOwned[recipient_] = _tOwned[recipient_].add(tTransferAmount);
        _rOwned[recipient_] = _rOwned[recipient_].add(rTransferAmount);
        _reflectFee(rFee, rBurn, tFee, tBurn);
    }

    function _transferBothExcluded(address sender_, address recipient_, uint256 tAmount_) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getTransferValues(tAmount_);
        _tOwned[sender_] = _tOwned[sender_].sub(tAmount_);
        _rOwned[sender_] = _rOwned[sender_].sub(rAmount);
        _tOwned[recipient_] = _tOwned[recipient_].add(tTransferAmount);
        _rOwned[recipient_] = _rOwned[recipient_].add(rTransferAmount);
        _reflectFee(rFee, rBurn, tFee, tBurn);
    }

    function _getTransferValues(uint256 tAmount_) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tFee, uint256 tBurn) = _getFee(tAmount_);
        uint256 tTransferAmount = tAmount_.sub(tFee).sub(tBurn);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn) = _getRValues(tAmount_, tFee , tBurn, _getRate());
        return (rAmount, rTransferAmount, rFee, rBurn, tTransferAmount, tFee, tBurn);
    }

    function _getFee(uint256 tAmount_) private view returns (uint256, uint256) {
        uint256 tFee = ((tAmount_.mul(_TAX_FEE)).div(_GRANULARITY)).div(100);
        uint256 tBurn = ((tAmount_.mul(_BURN_FEE)).div(_GRANULARITY)).div(100);
        return (tFee, tBurn);
    }

    function _getRValues(uint256 tAmount_, uint256 tFee_, uint256 tBurn_, uint256 currentRate_) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 rAmount = tAmount_.mul(currentRate_);
        uint256 rFee = tFee_.mul(currentRate_);
        uint256 rBurn = tBurn_.mul(currentRate_);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn);
        return (rAmount, rTransferAmount, rFee, rBurn);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_rOwned[_excludedFromReward[i]] > rSupply || _tOwned[_excludedFromReward[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excludedFromReward[i]]);
            tSupply = tSupply.sub(_tOwned[_excludedFromReward[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    /**
    * @dev Return value of token from value token reflection
    *
    * Requirements:
    *
    * - `rAmount` must be less than total reflection
    */
    function tokenFromReflection(uint256 rAmount_) public view returns(uint256) {
        require(rAmount_ <= _rTotal, "BEP20: amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount_.div(currentRate);
    }

    /**
    * @dev Return value of reflection from token amount
    *
    * Requirements:
    *
        * - `tAmount` must be less than total supply
    */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getTransferValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getTransferValues(tAmount);
            return rTransferAmount;
        }
    }

    /**
    * @dev Set new tax fee for every transaction
    * Can only be called by the current owner.
    */
    function setTaxFeePercent(uint256 taxFee_) external onlyOwner() {
        _TAX_FEE = taxFee_;
    }

    /**
    * @dev Set new burn fee for every transaction
    * Can only be called by the current owner.
    */
    function setBurnFeePercent(uint256 burnFee_) external onlyOwner() {
        _BURN_FEE = burnFee_;
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IBEP20 {

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: UNLICENSED

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}