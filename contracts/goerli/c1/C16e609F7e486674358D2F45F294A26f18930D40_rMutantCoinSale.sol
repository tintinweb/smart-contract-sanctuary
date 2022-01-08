// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IrMutantCoin.sol

pragma solidity ^0.8.0;

interface IrMutantCoin {
    function mint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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
    function decimals() external view returns (uint8);
}

// File: contracts/rMutantCoinSale.sol

pragma solidity ^0.8.0;

contract rMutantCoinSale {
    address public _dao;
    address public _depositToken;
    address public _mintToken;
    uint256 public _mintTokenPrice;
    mapping(address => uint256) public _totalUserDeposit;
    uint256 public _maxUserDeposit;
    uint256 public _totalGlobalDeposit;
    uint256 public _maxGlobalDeposit;

    constructor(address dao_, address depositToken_, address mintToken_, uint256 mintTokenPrice_, uint256 maxUserDeposit_, uint256 maxGlobalDeposit_) {
        _dao = dao_;
        _depositToken = depositToken_;
        _mintToken = mintToken_;
        _mintTokenPrice = mintTokenPrice_;
        _maxUserDeposit = maxUserDeposit_;
        _maxGlobalDeposit = maxGlobalDeposit_;
    }

    function deposit(uint256 depositAmount_) external {
        _totalUserDeposit[msg.sender] += depositAmount_;
        require(_totalUserDeposit[msg.sender] <= _maxUserDeposit, "user deposit limit exceeded");
        _totalGlobalDeposit += depositAmount_;
        require(_totalGlobalDeposit <= _maxGlobalDeposit, "global deposit limit exceeded");

        IERC20(_depositToken).transferFrom(msg.sender, _dao, depositAmount_);

        uint256 mintAmount = depositAmount_ * 10 ** IERC20Metadata(_mintToken).decimals() / _mintTokenPrice;
        IrMutantCoin(_mintToken).mint(msg.sender, mintAmount);
    }
}