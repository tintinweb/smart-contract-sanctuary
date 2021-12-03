/**
 *Submitted for verification at snowtrace.io on 2021-12-02
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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


// File contracts/Reflectx.sol

pragma solidity ^0.8.0;



contract Reflectx is Context, IERC20, Ownable {
    string private constant TOKEN_NAME = "KIOO";
    string private constant TOKEN_SYMBOL = "KIOO";
    uint256 private constant TOKEN_DECIMALS = 18;
    uint256 private constant MAX_SUPPLY = 72_000_000_000e18;
    uint256 private constant MAX = ~uint256(0);
    uint128 private constant FEES_PERCENT = 3;
    uint128 private constant BURN_PERCENT = 1;

    uint256 private _reflectSupply = (MAX - (MAX % MAX_SUPPLY));
    uint256 private _totalSupply = MAX_SUPPLY;
    uint256 private _totalFees = 0;
    uint256 private _totalBurn = 0;
    uint256 private _balanceLimit = 0;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _balances[_msgSender()] = _reflectSupply;
        emit Transfer(address(0), _msgSender(), MAX_SUPPLY);
    }

    function name() public pure returns (string memory) {
        return TOKEN_NAME;
    }

    function symbol() public pure returns (string memory) {
        return TOKEN_SYMBOL;
    }

    function decimals() public pure returns (uint256) {
        return TOKEN_DECIMALS;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address theOwner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[theOwner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = _balances[account];
        require(balance <= _reflectSupply, "K.balanceOf: ! <= total reflect");
        uint256 currentRate = _getRate();
        require(currentRate > 0, "K.balanceOf: current rate ! > 0");
        return balance / currentRate;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "K.transferFrom: tx > allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "K.decreaseAllowance: < zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function totalBurn() external view returns (uint256) {
        return _totalBurn;
    }

    function totalFees() external view returns (uint256) {
        return _totalFees;
    }

    function balanceLimit() external view returns (uint256) {
        return _balanceLimit;
    }

    function setBalanceLimit(uint256 amount) external onlyOwner {
        require(msg.sender != address(0), "K.setBalanceLimit: error addr(0)");
        _balanceLimit = amount;
    }

    function reflect(uint256 amount) external {
        address sender = _msgSender();
        (uint256 reflectAmount, , , , , , ) = _getAmounts(amount);
        require(
            _balances[sender] >= reflectAmount,
            "K.reflect: insuffisant balance"
        );
        _balances[sender] -= reflectAmount;
        _reflectSupply -= reflectAmount;
        _totalFees += amount;
    }

    function _reflectFeeBurn(
        uint256 reflectFees,
        uint256 fees,
        uint256 reflectBurn,
        uint256 burn
    ) private {
        _reflectSupply -= (reflectFees + reflectBurn);
        _totalFees += fees;
        _totalBurn += burn;
        _totalSupply -= burn;
    }

    function _approve(
        address theOwner,
        address spender,
        uint256 amount
    ) private {
        require(theOwner != address(0), "K._approve: from the address(0)");
        require(spender != address(0), "K._approve: to the address(0)");
        _allowances[theOwner][spender] = amount;
        emit Approval(theOwner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "K._transfer: from address(0)");
        require(recipient != address(0), "K._transfer: to the address(0)");
        require(amount > 0, "K._transfer: amount ! > 0");
        require(balanceOf(sender) >= amount, "K._transfer: amount > balance");
        require(
            _balanceLimit == 0 ||
                (balanceOf(recipient) + amount) <= _balanceLimit,
            "K._transfer: balance > limit"
        );
        (
            uint256 reflectAmount,
            uint256 reflectAmountToTransfer,
            uint256 reflectFees,
            uint256 reflectBurn,
            uint256 amountToTransfer,
            uint256 fees,
            uint256 burn
        ) = _getAmounts(amount);
        _balances[sender] -= reflectAmount;
        _balances[recipient] += reflectAmountToTransfer;
        _reflectFeeBurn(reflectFees, fees, reflectBurn, burn);
        emit Transfer(sender, recipient, amountToTransfer);
    }

    function _getAmounts(uint256 amount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 amountToTransfer,
            uint256 fees,
            uint256 burn
        ) = _getTransferAmounts(amount);
        (
            uint256 reflectAmount,
            uint256 reflectAmountToTransfer,
            uint256 reflectFees,
            uint256 reflectBurn
        ) = _getReflectAmounts(amount, fees, burn);
        return (
            reflectAmount,
            reflectAmountToTransfer,
            reflectFees,
            reflectBurn,
            amountToTransfer,
            fees,
            burn
        );
    }

    function _getTransferAmounts(uint256 amount)
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 fees = (amount * FEES_PERCENT) / 100;
        uint256 burn = (amount * BURN_PERCENT) / 100;
        uint256 amountToTransfer = amount - (fees + burn);
        return (amountToTransfer, fees, burn);
    }

    function _getReflectAmounts(
        uint256 amount,
        uint256 fees,
        uint256 burn
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentRate = _getRate();
        uint256 reflectFees = fees * currentRate;
        uint256 reflectBurn = burn * currentRate;
        uint256 reflectAmount = amount * currentRate;
        uint256 reflectAmountToTransfer = reflectAmount -
            (reflectFees + reflectBurn);
        return (
            reflectAmount,
            reflectAmountToTransfer,
            reflectFees,
            reflectBurn
        );
    }

    function _getRate() private view returns (uint256) {
        return _reflectSupply / _totalSupply;
    }
}