/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
  
   CASH TOKEN contract v1.01
   
   CASH Token features:
   0.8% total transaction fee, of which:
   
     0.4% fee: automatically destroyed (burned)
     0.4% fee: automatically and instantly distributed to all CASH token holders

   (c) Copyright 2021 cash.cx  
    
 */

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

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the provided address as the initial owner.
     */
    constructor (address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

}


contract TestToken is Context, IBEP20, Ownable {

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;

    address[] private _excluded;

    string private     _name = "Cash Token";
    string private   _symbol = "CCX";
    uint8 private  _decimals = 18;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000 * 10 ** _decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;


    uint256 public          _taxFee = 4;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public          _burnFee = 4;
    uint256 private _previousBurnFee = _burnFee;

    address private _burnWallet = 0x000000000000000000000000000000000000dEaD;


    constructor (address cOwner) Ownable(cOwner) {
        _rOwned[cOwner] = _rTotal;
        _tOwned[cOwner] = _tTotal;

        _isExcluded[owner()]       = true;
        _excluded.push(owner());
        _isExcluded[address(this)] = true;
        _excluded.push(address(this));
        _isExcluded[_burnWallet] = true;
        _excluded.push(_burnWallet);

        emit Transfer(address(0), cOwner, _tTotal);
    }
    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    /**
     * @dev See {IERC20-balanceOf}.
     */

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    /**
     * @dev See {IERC20-transfer}.
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
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    /**
     * @dev See {IERC20-approve}.
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
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + subtractedValue);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Returns true if address doesn't pay any fees, false otherwise
     */
    function isWhiteListed(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /**
     * @dev Returns total amount of collected fees
     */
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    /**
     * @dev Converts token amount to reflected token amount.
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;

        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    /**
     * @dev Converts reflected token amount to token amount.
     */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    /**
     * @dev Adds specified address to a whitelist, thus making it not subject to any fees or rewards
     */
    function addToWhiteList(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already in whitelist");
        require(account != _burnWallet, "Burn wallet is not allowed");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    /**
     * @dev Removes specified address from a whitelist. Then wallet starts receiving rewards and paying fees on transfers
     */
    function removeFromWhiteList(address account) external onlyOwner {
        require(_isExcluded[account], "Account is anot in whitelist");
        require(account != _burnWallet, "Burn wallet is not allowed");
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

    /**
     * @dev Sets tax fee
     * Requirements:
     *
     * _fee is rounded to deciles:
     *  10% = 100
     *  1% = 10
     *  0.1% = 1
     * _fee + _burnFee must be less, than 1000
     */
    function setTaxFee(uint256 _fee) external onlyOwner {
        require(_fee <= 1000 - _burnFee, "Tax fee too high");
        _previousTaxFee = _taxFee;
        _taxFee = _fee;
    }

    /**
     * @dev Sets burn fee
     * Requirements:
     *
     * _fee is rounded to deciles:
     *  10% = 100
     *  1% = 10
     *  0.1% = 1
     * _fee + _taxFee must be less, than 1000
     */
    function setBurnFee(uint256 _fee) external onlyOwner {
        require(_fee <= 1000 - _taxFee, "Burn fee too high");
        _previousBurnFee = _burnFee;
        _burnFee = _fee;
    }

    /**
     * @dev Distributes tax fee among holders.
     * Is being called internaly upon each transaction
     */
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    /**
     * @dev Burns certain amount of tokens
     * Is being called internaly upon each transaction
     */

    function _reflectBurn(uint256 rBurn, uint256 tBurn, address account) private {
        _rOwned[_burnWallet] = _rOwned[_burnWallet] + rBurn;
        if (_isExcluded[_burnWallet]) {
            _tOwned[_burnWallet] = _tOwned[_burnWallet] + tBurn;
        }

        emit Transfer(account, _burnWallet, tBurn);
    }


    /**
     * @dev Calculates fee amounts based on token transfer amount and fee
     * Is being called internaly upon each transaction
     */

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn) = _getRValues(tAmount, tFee, tBurn, _getRate());
        return (rAmount, rTransferAmount, rFee, rBurn, tTransferAmount, tFee, tBurn);
    }

    /**
     * @dev Calculates token amounts based on token transfer amount and fee
     * Is being called internaly upon each transaction
     */

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tBurn;
        return (tTransferAmount, tFee, tBurn);
    }

    /**
     * @dev Calculates reflected token amounts based on token transfer amount and fee
     * Is being called internaly upon each transaction
     */

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rBurn = tBurn * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rBurn;
        return (rAmount, rTransferAmount, rFee, rBurn);
    }

    /**
     * @dev Calculates ratio between tokens and reflected tokens
     */

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    /**
     * @dev Returns total supply in tokens and reflected tokens
     */

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply -_rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }


    /**
     * @dev Returns amount of tokens to be distributed between holders based on transaction tokens amount
     */

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount * _taxFee / 1000;
    }

    /**
     * @dev Returns amount of tokens to be burnt based on transaction tokens amount
     */

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount * _burnFee / 1000;
    }


    /**
     * @dev Disables all fees.
     */
    function removeAllFee() private {
        if (_taxFee == 0 && _burnFee == 0) return;
        _previousTaxFee       = _taxFee;
        _previousBurnFee       = _burnFee;
        _taxFee       = 0;
        _burnFee       = 0;
    }


    /**
     * @dev Restores all fees to previously used values
     */
    function restoreAllFee() private {
        _taxFee       = _previousTaxFee;
        _burnFee       = _previousBurnFee;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(to != _burnWallet, "BEP20: transfer to dead address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;
        if (_isExcluded[from] || _isExcluded[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);

    }

    /**
     * @dev Internally called by _transfer function
     * Disables fees and rewards if neccessary, depending on whether sender or recepient is whitelisted.
     */
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
        }

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

        if (!takeFee) {
            restoreAllFee();
        }
    }

    /**
     * @dev Transfers tokens between two non-whitelisted accounts
     */
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender]    = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        if (tFee > 0) {
            _reflectFee(rFee, tFee);
        }

        if (tBurn > 0) {
            _reflectBurn(rBurn, tBurn, sender);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @dev Transfers tokens between two whitelisted accounts
     */

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn,uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;


        if (tFee > 0) {
            _reflectFee(rFee, tFee);
        }

        if (tBurn > 0) {
            _reflectBurn(rBurn, tBurn, sender);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @dev Transfers tokens from non-whitelisted account to whitelisted account
     */
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        if (tFee > 0) {
            _reflectFee(rFee, tFee);
        }

        if (tBurn > 0) {
            _reflectBurn(rBurn, tBurn, sender);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @dev Transfers tokens from whitelisted account to non-whitelisted account
     */

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rBurn, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        if (tFee > 0) {
            _reflectFee(rFee, tFee);
        }

        if (tBurn > 0) {
            _reflectBurn(rBurn, tBurn, sender);
        }

        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
     * @dev Sends BNB from contract balance to provided address
     */
    function retriveBNB(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Zero address prohibited");
        uint256 contractBalance = address(this).balance;
        require(amount <= contractBalance, "Insufficient contract BNB balance");
        to.transfer(amount);
    }


}