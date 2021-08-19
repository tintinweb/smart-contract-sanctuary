/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// MIT

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


// File @openzeppelin/contracts/utils/[email protected]

// MIT

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
        return msg.data;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// MIT

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
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
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/interfaces/INestPriceFacade.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the methods for price call entry
interface INestPriceFacade {
    
    /// @dev Find the price at block number
    /// @param tokenAddress Destination token address
    /// @param height Destination block number
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        address tokenAddress, 
        uint height, 
        address paybackAddress
    ) external payable returns (uint blockNumber, uint price);

    /// @dev Get the latest trigger price
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(
        address tokenAddress, 
        address paybackAddress
    ) external payable returns (uint blockNumber, uint price);

    // /// @dev Price call entry configuration structure
    // struct Config {

    //     // Single query fee（0.0001 ether, DIMI_ETHER). 100
    //     uint16 singleFee;

    //     // Double query fee（0.0001 ether, DIMI_ETHER). 100
    //     uint16 doubleFee;

    //     // The normal state flag of the call address. 0
    //     uint8 normalFlag;
    // }

    // /// @dev Modify configuration
    // /// @param config Configuration object
    // function setConfig(Config calldata config) external;

    // /// @dev Get configuration
    // /// @return Configuration object
    // function getConfig() external view returns (Config memory);

    // /// @dev Set the address flag. Only the address flag equals to config.normalFlag can the price be called
    // /// @param addr Destination address
    // /// @param flag Address flag
    // function setAddressFlag(address addr, uint flag) external;

    // /// @dev Get the flag. Only the address flag equals to config.normalFlag can the price be called
    // /// @param addr Destination address
    // /// @return Address flag
    // function getAddressFlag(address addr) external view returns(uint);

    // /// @dev Set INestQuery implementation contract address for token
    // /// @param tokenAddress Destination token address
    // /// @param nestQueryAddress INestQuery implementation contract address, 0 means delete
    // function setNestQuery(address tokenAddress, address nestQueryAddress) external;

    // /// @dev Get INestQuery implementation contract address for token
    // /// @param tokenAddress Destination token address
    // /// @return INestQuery implementation contract address, 0 means use default
    // function getNestQuery(address tokenAddress) external view returns (address);

    // /// @dev Get cached fee in fee channel
    // /// @param tokenAddress Destination token address
    // /// @return Cached fee in fee channel
    // function getTokenFee(address tokenAddress) external view returns (uint);

    // /// @dev Settle fee for charge fee channel
    // /// @param tokenAddress tokenAddress of charge fee channel
    // function settle(address tokenAddress) external;
    
    // /// @dev Get the latest trigger price
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // function triggeredPrice(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (uint blockNumber, uint price);

    /// @dev Get the full information of latest trigger price
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(
        address tokenAddress, 
        address paybackAddress
    ) external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ);

    // /// @dev Find the price at block number
    // /// @param tokenAddress Destination token address
    // /// @param height Destination block number
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // function findPrice(
    //     address tokenAddress, 
    //     uint height, 
    //     address paybackAddress
    // ) external payable returns (uint blockNumber, uint price);

    // /// @dev Get the latest effective price
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // function latestPrice(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (uint blockNumber, uint price);

    // /// @dev Get the last (num) effective price
    // /// @param tokenAddress Destination token address
    // /// @param count The number of prices that want to return
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    // function lastPriceList(
    //     address tokenAddress, 
    //     uint count, 
    //     address paybackAddress
    // ) external payable returns (uint[] memory);

    // /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return latestPriceBlockNumber The block number of latest price
    // /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    // /// @return triggeredPriceBlockNumber The block number of triggered price
    // /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    // /// @return triggeredAvgPrice Average price
    // /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    // /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    // /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    // function latestPriceAndTriggeredPriceInfo(address tokenAddress, address paybackAddress) 
    // external 
    // payable 
    // returns (
    //     uint latestPriceBlockNumber, 
    //     uint latestPriceValue,
    //     uint triggeredPriceBlockNumber,
    //     uint triggeredPriceValue,
    //     uint triggeredAvgPrice,
    //     uint triggeredSigmaSQ
    // );

    // /// @dev Returns lastPriceList and triggered price info
    // /// @param tokenAddress Destination token address
    // /// @param count The number of prices that want to return
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    // /// @return triggeredPriceBlockNumber The block number of triggered price
    // /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    // /// @return triggeredAvgPrice Average price
    // /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    // /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    // /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    // function lastPriceListAndTriggeredPriceInfo(
    //     address tokenAddress, 
    //     uint count, 
    //     address paybackAddress
    // ) external payable 
    // returns (
    //     uint[] memory prices,
    //     uint triggeredPriceBlockNumber,
    //     uint triggeredPriceValue,
    //     uint triggeredAvgPrice,
    //     uint triggeredSigmaSQ
    // );

    // /// @dev Get the latest trigger price. (token and ntoken)
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // /// @return ntokenBlockNumber The block number of ntoken price
    // /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    // function triggeredPrice2(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (
    //     uint blockNumber, 
    //     uint price, 
    //     uint ntokenBlockNumber, 
    //     uint ntokenPrice
    // );

    // /// @dev Get the full information of latest trigger price. (token and ntoken)
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // /// @return avgPrice Average price
    // /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    // /// the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447, 
    // /// it means that the volatility has exceeded the range that can be expressed
    // /// @return ntokenBlockNumber The block number of ntoken price
    // /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    // /// @return ntokenAvgPrice Average price of ntoken
    // /// @return ntokenSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    // /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    // /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    // function triggeredPriceInfo2(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (
    //     uint blockNumber, 
    //     uint price, 
    //     uint avgPrice, 
    //     uint sigmaSQ, 
    //     uint ntokenBlockNumber, 
    //     uint ntokenPrice, 
    //     uint ntokenAvgPrice, 
    //     uint ntokenSigmaSQ
    // );

    // /// @dev Get the latest effective price. (token and ntoken)
    // /// @param tokenAddress Destination token address
    // /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    // /// and the excess fees will be returned through this address
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // /// @return ntokenBlockNumber The block number of ntoken price
    // /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    // function latestPrice2(
    //     address tokenAddress, 
    //     address paybackAddress
    // ) external payable returns (
    //     uint blockNumber, 
    //     uint price, 
    //     uint ntokenBlockNumber, 
    //     uint ntokenPrice
    // );
}


// File contracts/libs/TransferHelper.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/interfaces/IFortDAO.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the DAO methods
interface IFortDAO {

    /// @dev Application Flag Changed event
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    event ApplicationChanged(address addr, uint flag);
    
    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external;

    /// @dev Check DAO application flag
    /// @param addr DAO application contract address
    /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
    function checkApplication(address addr) external view returns (uint);

    /// @dev Add reward
    /// @param pool Destination pool
    function addETHReward(address pool) external payable;

    /// @dev The function returns eth rewards of specified pool
    /// @param pool Destination pool
    function totalETHRewards(address pool) external view returns (uint);

    /// @dev Settlement
    /// @param pool Destination pool. Indicates which pool to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address pool, address tokenAddress, address to, uint value) external payable;
}


// File contracts/interfaces/IFortMapping.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev The interface defines methods for Fort builtin contract address mapping
interface IFortMapping {

    /// @dev Set the built-in contract address of the system
    /// @param fortToken Address of fort token contract
    /// @param fortDAO IFortDAO implementation contract address
    /// @param fortEuropeanOption IFortEuropeanOption implementation contract address for Fort
    /// @param fortLever IFortLever implementation contract address
    /// @param fortVaultForStaking IFortVaultForStaking implementation contract address
    /// @param nestPriceFacade INestPriceFacade implementation contract address
    function setBuiltinAddress(
        address fortToken,
        address fortDAO,
        address fortEuropeanOption,
        address fortLever,
        address fortVaultForStaking,
        address nestPriceFacade
    ) external;

    /// @dev Get the built-in contract address of the system
    /// @return fortToken Address of fort token contract
    /// @return fortDAO IFortDAO implementation contract address
    /// @return fortEuropeanOption IFortEuropeanOption implementation contract address for Fort
    /// @return fortLever IFortLever implementation contract address
    /// @return fortVaultForStaking IFortVaultForStaking implementation contract address
    /// @return nestPriceFacade INestPriceFacade implementation contract address
    function getBuiltinAddress() external view returns (
        address fortToken,
        address fortDAO,
        address fortEuropeanOption,
        address fortLever,
        address fortVaultForStaking,
        address nestPriceFacade
    );

    /// @dev Get address of fort token contract
    /// @return Address of fort token contract
    function getFortTokenAddress() external view returns (address);

    /// @dev Get IFortDAO implementation contract address
    /// @return IFortDAO implementation contract address
    function getFortDAOAddress() external view returns (address);

    /// @dev Get IFortEuropeanOption implementation contract address for Fort
    /// @return IFortEuropeanOption implementation contract address for Fort
    function getFortEuropeanOptionAddress() external view returns (address);

    /// @dev Get IFortLever implementation contract address
    /// @return IFortLever implementation contract address
    function getFortLeverAddress() external view returns (address);

    /// @dev Get IFortVaultForStaking implementation contract address
    /// @return IFortVaultForStaking implementation contract address
    function getFortVaultForStakingAddress() external view returns (address);

    /// @dev Get INestPriceFacade implementation contract address
    /// @return INestPriceFacade implementation contract address
    function getNestPriceFacade() external view returns (address);

    /// @dev Registered address. The address registered here is the address accepted by Fort system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string calldata key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string calldata key) external view returns (address);
}


// File contracts/interfaces/IFortGovernance.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This interface defines the governance methods
interface IFortGovernance is IFortMapping {

    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight 
    /// to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}


// File contracts/FortBase.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
// Router contract to interact with each FortPair, no owner or governance
/// @dev Base contract of Fort
contract FortBase {

    /// @dev IFortGovernance implementation contract address
    address public _governance;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IFortGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "Fort:!initialize");
        _governance = governance;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IFortGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || IFortGovernance(governance).checkGovernance(msg.sender, 0), "Fort:!gov");
        _governance = newGovernance;
    }

    /// @dev Migrate funds from current contract to FortDAO
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = IFortGovernance(_governance).getFortDAOAddress();
        if (tokenAddress == address(0)) {
            IFortDAO(to).addETHReward { value: value } (address(0));
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(IFortGovernance(_governance).checkGovernance(msg.sender, 0), "Fort:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "Fort:!contract");
        _;
    }
}


// File contracts/FortToken.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Fort代币
contract FortToken is FortBase, ERC20("Fort", "Fort") {

    // 保存挖矿权限地址
    mapping(address=>uint) _minters;

    constructor() {
    }

    modifier onlyMinter {
        require(_minters[msg.sender] == 1, "FortToken: not minter");
        _;
    }

    /// @dev 设置挖矿权限
    /// @param account 目标账号
    /// @param flag 挖矿权限标记，只有1表示可以挖矿
    function setMinter(address account, uint flag) external onlyGovernance {
        _minters[account] = flag;
    }

    function checkMinter(address account) external view returns (uint) {
        return _minters[account];
    }

    /// @dev 挖矿
    /// @param to 接受地址
    /// @param amount 挖矿数量
    function mint(address to, uint amount) external onlyMinter {
        //require(msg.sender == _owner, "FortToken: not owner");
        _mint(to, amount);
    }

    /// @dev 销毁
    /// @param from 目标地址
    /// @param amount 销毁数量
    function burn(address from, uint amount) external onlyMinter {
        //require(msg.sender == _owner, "FortToken: not owner");
        _burn(from, amount);
    }
}