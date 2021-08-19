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


// File contracts/interfaces/IFortVaultForStaking.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Stake xtoken, earn fort
interface IFortVaultForStaking {

    /// @dev Initialize ore drawing weight
    /// @param xtokens xtoken array
    /// @param cycles cycle array
    /// @param weights weight array
    function batchSetPoolWeight(address[] calldata xtokens, uint96[] calldata cycles, uint[] calldata weights) external;

    /// @dev Get stake channel information
    /// @param xtoken xtoken address (or CNode address)
    /// @return totalStaked Total lock volume of target xtoken
    /// @return fortPerBlock Mining speed, fort per block
    function getChannelInfo(address xtoken, uint96 cycle) external view returns (uint totalStaked, uint fortPerBlock);

    /// @dev Get staked amount of target address
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(address xtoken, uint96 cycle, address addr) external view returns (uint);

    /// @dev Get the number of fort to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return The number of fort to be collected by the target address on the designated transaction lock
    function earned(address xtoken, uint96 cycle, address addr) external view returns (uint);

    /// @dev Stake xtoken to earn fort
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Stake amount
    function stake(address xtoken, uint96 cycle, uint amount) external;

    /// @dev Withdraw xtoken, and claim earned fort
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Withdraw amount
    function withdraw(address xtoken, uint96 cycle, uint amount) external;

    /// @dev Claim fort
    /// @param xtoken xtoken address (or CNode address)
    function getReward(address xtoken, uint96 cycle) external;

    /// @dev Calculate dividend data
    /// @param xtoken xtoken address (or CNode address)
    /// @return newReward Amount added since last settlement
    /// @return rewardPerToken New number of unit token dividends
    function calcReward(address xtoken, uint96 cycle) external view returns (
        uint newReward, 
        uint rewardPerToken
    );
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


// File contracts/FortBase2.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
// Router contract to interact with each FortPair, no owner or governance
/// @dev Base contract of Fort
contract FortBase2 is FortBase {

    // Address of FortToken contract
    //address constant FORT_TOKEN_ADDRESS = ;
    address FORT_TOKEN_ADDRESS;

    // Address of NestPriceFacade contract
    address NEST_PRICE_FACADE_ADDRESS;

    // Genesis block number of fort
    // FortToken contract is created at block height 11040156. However, because the mining algorithm of Fort1.0
    // is different from that at present, a new mining algorithm is adopted from Fort2.1. The new algorithm
    // includes the attenuation logic according to the block. Therefore, it is necessary to trace the block
    // where the fort begins to decay. According to the circulation when Fort v1.0 is online, the new mining
    // algorithm is used to deduce and convert the fort, and the new algorithm is used to mine the Fort2.1
    // on-line flow, the actual block is 11040688
    uint constant FORT_GENESIS_BLOCK = 0;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IFortGovernance implementation contract address
    function update(address newGovernance) public override {

        super.update(newGovernance);
        (
            FORT_TOKEN_ADDRESS,//address fortToken,
            ,//address fortDAO,
            ,//address fortEuropeanOption,
            ,//address fortLever,
            ,//address fortVaultForStaking,
            NEST_PRICE_FACADE_ADDRESS //address nestPriceFacade
        ) = IFortGovernance(newGovernance).getBuiltinAddress();
    }
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


// File contracts/FortVaultForStaking.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Stake xtoken, earn fort
contract FortVaultForStaking is FortBase2, IFortVaultForStaking {

    /// @dev Account information
    struct Account {
        // Staked of current account
        uint160 balance;
        // Token dividend value mark of the unit that the account has received
        uint96 rewardCursor;
    }
    
    /// @dev Stake channel information
    struct StakeChannel{

        // Mining amount weight
        uint weight;
        // 结束区块号
        uint endblock;
        // Total staked amount
        uint totalStaked;

        // xtoken global sign
        // Total ore drawing mark of settled transaction
        uint128 tradeReward;
        // Total settled ore output mark
        //uint128 totalReward;
        // The dividend mark that the settled company token can receive
        uint96 rewardPerToken;
        // Settlement block mark
        uint32 blockCursor;

        // Accounts
        // address=>balance
        mapping(address=>Account) accounts;
    }
    
    // // fort mining speed weight base
    // uint constant FORT_WEIGHT_BASE = 1e9;

    // fort mining unit
    uint _fortUnit;

    // staking通道信息xtoken|cycle=>StakeChannel
    mapping(uint=>StakeChannel) _channels;
    
    /// @dev Create FortVaultForStaking
    constructor () {
    }

    /// @dev Modify configuration
    /// @param fortUnit fort mining unit
    function setConfig(uint fortUnit) external onlyGovernance {
        _fortUnit = fortUnit;
    }

    /// @dev Get configuration
    /// @return fortUnit fort mining unit
    function getConfig() external view returns (uint fortUnit) {
        return _fortUnit;
    }

    function _getKey(address xtoken, uint96 cycle) private pure returns (uint){
        return (uint160(xtoken) << 96) | uint(cycle);
    }

    // TODO: 周期改为固定区块
    /// @dev Initialize ore drawing weight
    /// @param xtokens xtoken array
    /// @param cycles cycle array
    /// @param weights weight array
    function batchSetPoolWeight(
        address[] calldata xtokens, 
        uint96[] calldata cycles, 
        uint[] calldata weights
    ) external override onlyGovernance {

        uint cnt = xtokens.length;
        require(cnt == weights.length, "FortVaultForStaking: mismatch len");

        for (uint i = 0; i < cnt; ++i) {
            address xtoken = xtokens[i];
            require(xtoken != address(0), "FortVaultForStaking: invalid xtoken");
            uint key = _getKey(xtoken, cycles[i]);
            StakeChannel storage channel = _channels[key];
            _updateReward(channel);
            channel.weight = weights[i];
            channel.endblock = block.number + cycles[i];
        }
    }

    /// @dev Get stake channel information
    /// @param xtoken xtoken address (or CNode address)
    /// @return totalStaked Total lock volume of target xtoken
    /// @return fortPerBlock Mining speed, fort per block
    function getChannelInfo(
        address xtoken, 
        uint96 cycle
    ) external view override returns (
        uint totalStaked, 
        uint fortPerBlock
    ) {
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        return (channel.totalStaked, uint(channel.weight) * _fortUnit);
    }

    /// @dev Get staked amount of target address
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(address xtoken, uint96 cycle, address addr) external view override returns (uint) {
        return uint(_channels[_getKey(xtoken, cycle)].accounts[addr].balance);
    }

    /// @dev Get the number of fort to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return The number of fort to be collected by the target address on the designated transaction lock
    function earned(address xtoken, uint96 cycle, address addr) external view override returns (uint) {

        // Load staking channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        // Call _calcReward() to calculate new reward
        uint newReward = _calcReward(channel);
        
        // Load account
        Account memory account = channel.accounts[addr];
        uint balance = uint(account.balance);
        // Load total amount of staked
        uint totalStaked = channel.totalStaked;

        // Unit token dividend
        uint rewardPerToken = _decodeFloat(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * 1 ether / totalStaked;
        }
        
        return (rewardPerToken - _decodeFloat(account.rewardCursor)) * balance / 1 ether;
    }

    /// @dev Stake xtoken to earn fort
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Stake amount
    function stake(address xtoken, uint96 cycle, uint amount) external override {

        // Load stake channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        // Settle reward for account
        Account memory account = _getReward(channel, msg.sender);

        // Transfer xtoken from msg.sender to this
        TransferHelper.safeTransferFrom(xtoken, msg.sender, address(this), amount);
        // Update totalStaked
        channel.totalStaked += amount;

        // Update stake balance of account
        account.balance = uint160(uint(account.balance) + amount);
        channel.accounts[msg.sender] = account;
    }

    /// @dev Withdraw xtoken, and claim earned fort
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Withdraw amount
    function withdraw(address xtoken, uint96 cycle, uint amount) external override {

        // Load stake channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        // Settle reward for account
        Account memory account = _getReward(channel, msg.sender);

        // Update totalStaked
        channel.totalStaked -= amount;
        // Update stake balance of account
        account.balance = uint160(uint(account.balance) - amount);
        channel.accounts[msg.sender] = account;

        // Transfer xtoken to msg.sender
        TransferHelper.safeTransfer(xtoken, msg.sender, amount);
    }

    /// @dev Claim fort
    /// @param xtoken xtoken address (or CNode address)
    function getReward(address xtoken, uint96 cycle) external override {
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        channel.accounts[msg.sender] = _getReward(channel, msg.sender);
    }

    // Calculate reward, and settle the target account
    function _getReward(
        StakeChannel storage channel, 
        address to
    ) private returns (Account memory account) {

        // Load account
        account = channel.accounts[to];
        // Update the global dividend information and get the new unit token dividend amount
        uint rewardPerToken = _updateReward(channel);
        
        // Calculate reward for account
        uint balance = uint(account.balance);
        // if (xtoken == CNODE_TOKEN_ADDRESS) {
        //     //balance *= 1 ether;
        // }
        uint reward = (rewardPerToken - _decodeFloat(account.rewardCursor)) * balance / 1 ether;
        
        // Update sign of account
        account.rewardCursor = _encodeFloat(rewardPerToken);
        //channel.accounts[to] = account;

        // Transfer fort to account
        if (reward > 0) {
            FortToken(FORT_TOKEN_ADDRESS).mint(to, reward);
        }
    }

    // Update the global dividend information and return the new unit token dividend amount
    function _updateReward(StakeChannel storage channel) private returns (uint rewardPerToken) {

        // Call _calcReward() to calculate new reward
        uint newReward = _calcReward(channel);

        // Load total amount of staked
        uint totalStaked = channel.totalStaked;
        
        rewardPerToken = _decodeFloat(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * 1 ether / totalStaked;
        }

        // Update the dividend value of unit share
        channel.rewardPerToken = _encodeFloat(rewardPerToken);
        // Update settled block number
        channel.blockCursor = uint32(block.number);
    }

    // Calculate new reward
    function _calcReward(StakeChannel storage channel) private view returns (uint newReward) {

        uint blockNumber = channel.endblock;
        if (blockNumber > block.number) {
            blockNumber = block.number;
        }

        uint blockCursor = uint(channel.blockCursor);
        if (blockNumber > blockCursor) {
            newReward =
                (blockNumber - blockCursor)
                * _reduction(block.number - FORT_GENESIS_BLOCK) 
                * _fortUnit
                * channel.weight
                / 400 ;
        }

        newReward = 0;
    }

    /// @dev Calculate dividend data
    /// @param xtoken xtoken address (or CNode address)
    /// @return newReward Amount added since last settlement
    /// @return rewardPerToken New number of unit token dividends
    function calcReward(address xtoken, uint96 cycle) external view override returns (
        uint newReward, 
        uint rewardPerToken
    ) {

        // Load staking channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        // Call _calcReward() to calculate new reward
        newReward = _calcReward(channel);

        // Load total amount of staked
        uint totalStaked = channel.totalStaked;

        rewardPerToken = _decodeFloat(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * 1 ether / totalStaked;
        }
    }

    // fort ore drawing attenuation interval. 2400000 blocks, about one year
    uint constant FORT_REDUCTION_SPAN = 2400000;
    // The decay limit of fort ore drawing becomes stable after exceeding this interval. 24 million blocks, about 4 years
    uint constant FORT_REDUCTION_LIMIT = 9600000; // FORT_REDUCTION_SPAN * 4;
    // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    uint constant FORT_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;
        // 0
        // | (uint(400 / uint(1)) << (16 * 0))
        // | (uint(400 * 8 / uint(10)) << (16 * 1))
        // | (uint(400 * 8 * 8 / uint(10 * 10)) << (16 * 2))
        // | (uint(400 * 8 * 8 * 8 / uint(10 * 10 * 10)) << (16 * 3))
        // | (uint(400 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10)) << (16 * 4))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10)) << (16 * 5))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10)) << (16 * 6))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 7))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 8))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 9))
        // //| (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 10));
        // | (uint(40) << (16 * 10));

    // Calculation of attenuation gradient
    function _reduction(uint delta) private pure returns (uint) {
        
        if (delta < FORT_REDUCTION_LIMIT) {
            return (FORT_REDUCTION_STEPS >> ((delta / FORT_REDUCTION_SPAN) << 4)) & 0xFFFF;
        }
        return (FORT_REDUCTION_STEPS >> 64) & 0xFFFF;
    }

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function _encodeFloat(uint value) private pure returns (uint96) {

        uint exponent = 0; 
        while (value > 0x3FFFFFFFFFFFFFFFFFFFFFF) {
            value >>= 4;
            ++exponent;
        }
        return uint96((value << 6) | exponent);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function _decodeFloat(uint96 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }
}