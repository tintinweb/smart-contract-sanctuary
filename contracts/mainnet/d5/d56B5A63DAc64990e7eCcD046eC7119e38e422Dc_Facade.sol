pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./Interfaces/IOptionsManager.sol";
import "./Interfaces/Interfaces.sol";

/**
 * @author 0mllwntrmt3
 * @title Hegic Protocol V8888 Exerciser Contract
 * @notice The contract that allows to automatically exercise options half an hour before expiration
 **/
contract Exerciser {
    IOptionsManager immutable optionsManager;

    constructor(IOptionsManager manager) {
        optionsManager = manager;
    }

    function exercise(uint256 optionId) external {
        IHegicPool pool = IHegicPool(optionsManager.tokenPool(optionId));
        (, , , , uint256 expired, , ) = pool.options(optionId);
        require(
            block.timestamp > expired - 30 minutes,
            "Facade Error: Automatically exercise for this option is not available yet"
        );
        pool.exercise(optionId);
    }
}

pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @notice The interface for the contract
 *   that tokenizes options as ERC721.
 **/

interface IOptionsManager is IERC721 {
    /**
     * @param holder The option buyer address
     **/
    function createOptionFor(address holder) external returns (uint256);

    /**
     * @param tokenId The ERC721 token ID linked to the option
     **/
    function tokenPool(uint256 tokenId) external returns (address pool);

    /**
     * @param spender The option buyer address or another address
     *   with the granted permission to buy/exercise options on the user's behalf
     * @param tokenId The ERC721 token ID linked to the option
     **/
    function isApprovedOrOwner(address spender, uint256 tokenId)
        external
        view
        returns (bool);
}

pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

// /**
//  * @author 0mllwntrmt3
//  * @title Hegic Protocol V8888 Interface
//  * @notice The interface for the price calculator,
//  *   options, pools and staking contracts.
//  **/

/**
 * @notice The interface fot the contract that calculates
 *   the options prices (the premiums) that are adjusted
 *   through balancing the `ImpliedVolRate` parameter.
 **/
interface IPriceCalculator {
    /**
     * @param period The option period
     * @param amount The option size
     * @param strike The option strike
     **/
    function calculateTotalPremium(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) external view returns (uint256 settlementFee, uint256 premium);
}

/**
 * @notice The interface for the contract that manages pools and the options parameters,
 *   accumulates the funds from the liquidity providers and makes the withdrawals for them,
 *   sells the options contracts to the options buyers and collateralizes them,
 *   exercises the ITM (in-the-money) options with the unrealized P&L and settles them,
 *   unlocks the expired options and distributes the premiums among the liquidity providers.
 **/
interface IHegicPool is IERC721, IPriceCalculator {
    enum OptionState {Invalid, Active, Exercised, Expired}
    enum TrancheState {Invalid, Open, Closed}

    /**
     * @param state The state of the option: Invalid, Active, Exercised, Expired
     * @param strike The option strike
     * @param amount The option size
     * @param lockedAmount The option collateral size locked
     * @param expired The option expiration timestamp
     * @param hedgePremium The share of the premium paid for hedging from the losses
     * @param unhedgePremium The share of the premium paid to the hedged liquidity provider
     **/
    struct Option {
        OptionState state;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 expired;
        uint256 hedgePremium;
        uint256 unhedgePremium;
    }

    /**
     * @param state The state of the liquidity tranche: Invalid, Open, Closed
     * @param share The liquidity provider's share in the pool
     * @param amount The size of liquidity provided
     * @param creationTimestamp The liquidity deposit timestamp
     * @param hedged The liquidity tranche type: hedged or unhedged (classic)
     **/
    struct Tranche {
        TrancheState state;
        uint256 share;
        uint256 amount;
        uint256 creationTimestamp;
        bool hedged;
    }

    /**
     * @param id The ERC721 token ID linked to the option
     * @param settlementFee The part of the premium that
     *   is distributed among the HEGIC staking participants
     * @param premium The part of the premium that
     *   is distributed among the liquidity providers
     **/
    event Acquired(uint256 indexed id, uint256 settlementFee, uint256 premium);

    /**
     * @param id The ERC721 token ID linked to the option
     * @param profit The profits of the option if exercised
     **/
    event Exercised(uint256 indexed id, uint256 profit);

    /**
     * @param id The ERC721 token ID linked to the option
     **/
    event Expired(uint256 indexed id);

    /**
     * @param account The liquidity provider's address
     * @param trancheID The liquidity tranche ID
     **/
    event Withdrawn(
        address indexed account,
        uint256 indexed trancheID,
        uint256 amount
    );

    /**
     * @param id The ERC721 token ID linked to the option
     **/
    function unlock(uint256 id) external;

    /**
     * @param id The ERC721 token ID linked to the option
     **/
    function exercise(uint256 id) external;

    function setLockupPeriod(uint256, uint256) external;

    /**
     * @param value The hedging pool address
     **/
    function setHedgePool(address value) external;

    /**
     * @param trancheID The liquidity tranche ID
     * @return amount The liquidity to be received with
     *   the positive or negative P&L earned or lost during
     *   the period of holding the liquidity tranche considered
     **/
    function withdraw(uint256 trancheID) external returns (uint256 amount);

    function pricer() external view returns (IPriceCalculator);

    /**
     * @return amount The unhedged liquidity size
     *   (unprotected from the losses on selling the options)
     **/
    function unhedgedBalance() external view returns (uint256 amount);

    /**
     * @return amount The hedged liquidity size
     * (protected from the losses on selling the options)
     **/
    function hedgedBalance() external view returns (uint256 amount);

    /**
     * @param account The liquidity provider's address
     * @param amount The size of the liquidity tranche
     * @param hedged The type of the liquidity tranche
     * @param minShare The minimum share in the pool of the user
     **/
    function provideFrom(
        address account,
        uint256 amount,
        bool hedged,
        uint256 minShare
    ) external returns (uint256 share);

    /**
     * @param holder The option buyer address
     * @param period The option period
     * @param amount The option size
     * @param strike The option strike
     **/
    function sellOption(
        address holder,
        uint256 period,
        uint256 amount,
        uint256 strike
    ) external returns (uint256 id);

    /**
     * @param trancheID The liquidity tranche ID
     * @return amount The amount to be received after the withdrawal
     **/
    function withdrawWithoutHedge(uint256 trancheID)
        external
        returns (uint256 amount);

    /**
     * @return amount The total liquidity provided into the pool
     **/
    function totalBalance() external view returns (uint256 amount);

    /**
     * @return amount The total liquidity locked in the pool
     **/
    function lockedAmount() external view returns (uint256 amount);

    function token() external view returns (IERC20);

    /**
     * @return state The state of the option: Invalid, Active, Exercised, Expired
     * @return strike The option strike
     * @return amount The option size
     * @return lockedAmount The option collateral size locked
     * @return expired The option expiration timestamp
     * @return hedgePremium The share of the premium paid for hedging from the losses
     * @return unhedgePremium The share of the premium paid to the hedged liquidity provider
     **/
    function options(uint256 id)
        external
        view
        returns (
            OptionState state,
            uint256 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 expired,
            uint256 hedgePremium,
            uint256 unhedgePremium
        );

    /**
     * @return state The state of the liquidity tranche: Invalid, Open, Closed
     * @return share The liquidity provider's share in the pool
     * @return amount The size of liquidity provided
     * @return creationTimestamp The liquidity deposit timestamp
     * @return hedged The liquidity tranche type: hedged or unhedged (classic)
     **/
    function tranches(uint256 id)
        external
        view
        returns (
            TrancheState state,
            uint256 share,
            uint256 amount,
            uint256 creationTimestamp,
            bool hedged
        );
}

/**
 * @notice The interface for the contract that stakes HEGIC tokens
 *   through buying microlots (any amount of HEGIC tokens per microlot)
 *   and staking lots (888,000 HEGIC per lot), accumulates the staking
 *   rewards (settlement fees) and distributes the staking rewards among
 *   the microlots and staking lots holders (should be claimed manually).
 **/
interface IHegicStaking {
    event Claim(address indexed account, uint256 amount);
    event Profit(uint256 amount);
    event MicroLotsAcquired(address indexed account, uint256 amount);
    event MicroLotsSold(address indexed account, uint256 amount);

    function claimProfits(address account) external returns (uint256 profit);

    function buyStakingLot(uint256 amount) external;

    function sellStakingLot(uint256 amount) external;

    function distributeUnrealizedRewards() external;

    function profitOf(address account) external view returns (uint256);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Interfaces/Interfaces.sol";

/**
 * @author 0mllwntrmt3
 * @title Hegic Protocol V8888 Staking Contract
 * @notice The contract that stakes the HEGIC tokens through
 * buying the microlots (any amount of HEGIC tokens per microlot)
 * and the staking lots (888,000 HEGIC per lot), accumulates the staking
 * rewards (settlement fees) and distributes the staking rewards among
 * the microlots and staking lots holders (should be claimed manually).
 **/

contract HegicStaking is ERC20, IHegicStaking {
    using SafeERC20 for IERC20;

    IERC20 public immutable HEGIC;
    IERC20 public immutable token;

    uint256 public constant STAKING_LOT_PRICE = 888_000e18;
    uint256 internal constant ACCURACY = 1e30;
    uint256 internal realisedBalance;

    uint256 public microLotsTotal = 0;
    mapping(address => uint256) public microBalance;

    uint256 public totalProfit = 0;
    mapping(address => uint256) internal lastProfit;

    uint256 public microLotsProfits = 0;
    mapping(address => uint256) internal lastMicroLotProfits;

    mapping(address => uint256) internal savedProfit;

    uint256 public classicLockupPeriod = 1 days;
    uint256 public microLockupPeriod = 1 days;

    mapping(address => uint256) public lastBoughtTimestamp;
    mapping(address => uint256) public lastMicroBoughtTimestamp;
    mapping(address => bool) public _revertTransfersInLockUpPeriod;

    constructor(
        ERC20 _hegic,
        ERC20 _token,
        string memory name,
        string memory short
    ) ERC20(name, short) {
        HEGIC = _hegic;
        token = _token;
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    /**
     * @notice Used by the HEGIC microlots holders
     * or staking lots holders for claiming
     * the accumulated staking rewards.
     **/
    function claimProfits(address account)
        external
        override
        returns (uint256 profit)
    {
        saveProfits(account);
        profit = savedProfit[account];
        require(profit > 0, "Zero profit");
        savedProfit[account] = 0;
        realisedBalance -= profit;
        token.safeTransfer(account, profit);
        emit Claim(account, profit);
    }

    /**
     * @notice Used for staking any amount of the HEGIC tokens
     * higher than zero in the form of buying the microlot
     * for receiving a pro rata share of 20% of the total staking
     * rewards (settlement fees) generated by the protocol.
     **/
    function buyMicroLot(uint256 amount) external {
        require(amount > 0, "Amount is zero");
        saveProfits(msg.sender);
        lastMicroBoughtTimestamp[msg.sender] = block.timestamp;
        microLotsTotal += amount;
        microBalance[msg.sender] += amount;
        HEGIC.safeTransferFrom(msg.sender, address(this), amount);
        emit MicroLotsAcquired(msg.sender, amount);
    }

    /**
     * @notice Used for unstaking the HEGIC tokens
     * in the form of selling the microlot.
     **/
    function sellMicroLot(uint256 amount) external {
        require(amount > 0, "Amount is zero");
        require(
            lastMicroBoughtTimestamp[msg.sender] + microLockupPeriod <
                block.timestamp,
            "The action is suspended due to the lockup"
        );
        saveProfits(msg.sender);
        microLotsTotal -= amount;
        microBalance[msg.sender] -= amount;
        HEGIC.safeTransfer(msg.sender, amount);
        emit MicroLotsSold(msg.sender, amount);
    }

    /**
     * @notice Used for staking the fixed amount of 888,000 HEGIC
     * tokens in the form of buying the staking lot (transferrable)
     * for receiving a pro rata share of 80% of the total staking
     * rewards (settlement fees) generated by the protocol.
     **/
    function buyStakingLot(uint256 amount) external override {
        lastBoughtTimestamp[msg.sender] = block.timestamp;
        require(amount > 0, "Amount is zero");
        _mint(msg.sender, amount);
        HEGIC.safeTransferFrom(
            msg.sender,
            address(this),
            amount * STAKING_LOT_PRICE
        );
    }

    /**
     * @notice Used for unstaking 888,000 HEGIC
     * tokens in the form of selling the staking lot.
     **/
    function sellStakingLot(uint256 amount) external override lockupFree {
        _burn(msg.sender, amount);
        HEGIC.safeTransfer(msg.sender, amount * STAKING_LOT_PRICE);
    }

    function revertTransfersInLockUpPeriod(bool value) external {
        _revertTransfersInLockUpPeriod[msg.sender] = value;
    }

    /**
     * @notice Returns the amount of unclaimed staking rewards.
     **/
    function profitOf(address account)
        external
        view
        override
        returns (uint256)
    {
        (uint256 profit, uint256 micro) = getUnsavedProfits(account);
        return savedProfit[account] + profit + micro;
    }

    /**
     * @notice Used for calculating the amount of accumulated
     * staking rewards before the share of the staking participant
     * changes higher (buying more microlots or staking lots)
     * or lower (selling more microlots or staking lots).
     **/
    function getUnsavedProfits(address account)
        internal
        view
        returns (uint256 total, uint256 micro)
    {
        total =
            ((totalProfit - lastProfit[account]) * balanceOf(account)) /
            ACCURACY;
        micro =
            ((microLotsProfits - lastMicroLotProfits[account]) *
                microBalance[account]) /
            ACCURACY;
    }

    /**
     * @notice Used for saving the amount of accumulated
     * staking rewards before the staking participant's share
     * changes higher (buying more microlots or staking lots)
     * or lower (selling more microlots or staking lots).
     **/
    function saveProfits(address account) internal {
        (uint256 unsaved, uint256 micro) = getUnsavedProfits(account);
        lastProfit[account] = totalProfit;
        lastMicroLotProfits[account] = microLotsProfits;
        savedProfit[account] += unsaved;
        savedProfit[account] += micro;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override {
        if (from != address(0)) saveProfits(from);
        if (to != address(0)) saveProfits(to);
        if (
            lastBoughtTimestamp[from] + classicLockupPeriod > block.timestamp &&
            lastBoughtTimestamp[from] > lastBoughtTimestamp[to]
        ) {
            require(
                !_revertTransfersInLockUpPeriod[to],
                "The recipient does not agree to accept the locked funds"
            );
            lastBoughtTimestamp[to] = lastBoughtTimestamp[from];
        }
    }

    /**
     * @notice Used for distributing the staking rewards
     * among the microlots and staking lots holders.
     **/
    function distributeUnrealizedRewards() external override {
        uint256 amount = token.balanceOf(address(this)) - realisedBalance;
        realisedBalance += amount;
        uint256 _totalSupply = totalSupply();
        if (microLotsTotal + _totalSupply > 0) {
            if (microLotsTotal == 0) {
                totalProfit += (amount * ACCURACY) / _totalSupply;
            } else if (_totalSupply == 0) {
                microLotsProfits += (amount * ACCURACY) / microLotsTotal;
            } else {
                uint256 microAmount = amount / 5;
                uint256 baseAmount = amount - microAmount;
                microLotsProfits += (microAmount * ACCURACY) / microLotsTotal;
                totalProfit += (baseAmount * ACCURACY) / _totalSupply;
            }
            emit Profit(amount);
        }
    }

    modifier lockupFree {
        require(
            lastBoughtTimestamp[msg.sender] + classicLockupPeriod <=
                block.timestamp,
            "The action is suspended due to the lockup"
        );
        _;
    }
}

pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "../Interfaces/IOptionsManager.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @author 0mllwntrmt3
 * @title Hegic Protocol V8888 Options Manager Contract
 * @notice The contract that buys the options contracts for the options holders
 * as well as checks whether the contract that is used for buying/exercising
 * options has been been granted with the permission to do it on the user's behalf.
 **/

contract OptionsManager is
    IOptionsManager,
    ERC721("Hegic V8888 Options (Tokenized)", "HOT8888"),
    AccessControl
{
    bytes32 public constant HEGIC_POOL_ROLE = keccak256("HEGIC_POOL_ROLE");
    uint256 public nextTokenId = 0;
    mapping(uint256 => address) public override tokenPool;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev See EIP-165: ERC-165 Standard Interface Detection
     * https://eips.ethereum.org/EIPS/eip-165
     **/
    function createOptionFor(address holder)
        public
        override
        onlyRole(HEGIC_POOL_ROLE)
        returns (uint256 id)
    {
        id = nextTokenId++;
        tokenPool[id] = msg.sender;
        _safeMint(holder, id);
    }

    /**
     * @dev See EIP-165: ERC-165 Standard Interface Detection
     * https://eips.ethereum.org/EIPS/eip-165
     **/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IOptionsManager).interfaceId ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }

    /**
     * @notice Used for checking whether the user has approved
     * the contract to buy/exercise the options on her behalf.
     * @param spender The address of the contract
     * that is used for exercising the options
     * @param tokenId The ERC721 token ID that is linked to the option
     **/
    function isApprovedOrOwner(address spender, uint256 tokenId)
        external
        view
        virtual
        override
        returns (bool)
    {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "../Interfaces/Interfaces.sol";
import "../Interfaces/IOptionsManager.sol";
import "../Interfaces/Interfaces.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @author 0mllwntrmt3
 * @title Hegic Protocol V8888 Main Pool Contract
 * @notice One of the main contracts that manages the pools and the options parameters,
 * accumulates the funds from the liquidity providers and makes the withdrawals for them,
 * sells the options contracts to the options buyers and collateralizes them,
 * exercises the ITM (in-the-money) options with the unrealized P&L and settles them,
 * unlocks the expired options and distributes the premiums among the liquidity providers.
 **/
abstract contract HegicPool is
    IHegicPool,
    ERC721,
    AccessControl,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    uint256 public constant INITIAL_RATE = 1e20;
    IOptionsManager public immutable optionsManager;
    AggregatorV3Interface public immutable priceProvider;
    IPriceCalculator public override pricer;
    uint256 public lockupPeriodForHedgedTranches = 60 days;
    uint256 public lockupPeriodForUnhedgedTranches = 30 days;
    uint256 public hedgeFeeRate = 80;
    uint256 public maxUtilizationRate = 80;
    uint256 public collateralizationRatio = 50;
    uint256 public override lockedAmount;
    uint256 public maxDepositAmount = type(uint256).max;
    uint256 public maxHedgedDepositAmount = type(uint256).max;

    uint256 public unhedgedShare = 0;
    uint256 public hedgedShare = 0;
    uint256 public override unhedgedBalance = 0;
    uint256 public override hedgedBalance = 0;
    IHegicStaking public settlementFeeRecipient;
    address public hedgePool;

    Tranche[] public override tranches;
    mapping(uint256 => Option) public override options;
    IERC20 public override token;

    constructor(
        IERC20 _token,
        string memory name,
        string memory symbol,
        IOptionsManager manager,
        IPriceCalculator _pricer,
        IHegicStaking _settlementFeeRecipient,
        AggregatorV3Interface _priceProvider
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        priceProvider = _priceProvider;
        settlementFeeRecipient = _settlementFeeRecipient;
        pricer = _pricer;
        token = _token;
        hedgePool = _msgSender();
        optionsManager = manager;
    }

    /**
     * @notice Used for setting the liquidity lock-up periods during which
     * the liquidity providers who deposited the funds into the pools contracts
     * won't be able to withdraw them. Note that different lock-ups could
     * be set for the hedged and unhedged — classic — liquidity tranches.
     * @param hedgedValue Hedged liquidity tranches lock-up in seconds
     * @param unhedgedValue Unhedged (classic) liquidity tranches lock-up in seconds
     **/
    function setLockupPeriod(uint256 hedgedValue, uint256 unhedgedValue)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            hedgedValue <= 60 days,
            "The lockup period for hedged tranches is too long"
        );
        require(
            unhedgedValue <= 30 days,
            "The lockup period for unhedged tranches is too long"
        );
        lockupPeriodForHedgedTranches = hedgedValue;
        lockupPeriodForUnhedgedTranches = unhedgedValue;
    }

    /**
     * @notice Used for setting the total maximum amount
     * that could be deposited into the pools contracts.
     * Note that different total maximum amounts could be set
     * for the hedged and unhedged — classic — liquidity tranches.
     * @param total Maximum amount of assets in the pool
     * in hedged and unhedged (classic) liquidity tranches combined
     * @param hedged Maximum amount of assets in the pool
     * in hedged liquidity tranches only
     **/
    function setMaxDepositAmount(uint256 total, uint256 hedged)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            total >= hedged,
            "Pool Error: The total amount shouldn't be lower than the hedged amount"
        );
        maxDepositAmount = total;
        maxHedgedDepositAmount = hedged;
    }

    /**
     * @notice Used for setting the maximum share of the pool
     * size that could be utilized as a collateral in the options.
     *
     * Example: if `MaxUtilizationRate` = 50, then only 50%
     * of liquidity on the pools contracts would be used for
     * collateralizing options while 50% will be sitting idle
     * available for withdrawals by the liquidity providers.
     * @param value The utilization ratio in a range of 50% — 100%
     **/
    function setMaxUtilizationRate(uint256 value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            50 <= value && value <= 100,
            "Pool error: Wrong utilization rate limitation value"
        );
        maxUtilizationRate = value;
    }

    /**
     * @notice Used for setting the collateralization ratio for the option
     * collateral size that will be locked at the moment of buying them.
     *
     * Example: if `CollateralizationRatio` = 50, then 50% of an option's
     * notional size will be locked in the pools at the moment of buying it:
     * say, 1 ETH call option will be collateralized with 0.5 ETH (50%).
     * Note that if an option holder's net P&L USD value (as options
     * are cash-settled) will exceed the amount of the collateral locked
     * in the option, she will receive the required amount at the moment
     * of exercising the option using the pool's unutilized (unlocked) funds.
     * @param value The collateralization ratio in a range of 30% — 100%
     **/
    function setCollateralizationRatio(uint256 value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            30 <= value && value <= 100,
            "Pool Error: Wrong collateralization ratio value"
        );
        collateralizationRatio = value;
    }

    /**
     * @dev See EIP-165: ERC-165 Standard Interface Detection
     * https://eips.ethereum.org/EIPS/eip-165.
     **/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IHegicPool).interfaceId ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }

    /**
     * @notice Used for changing the hedging pool address
     * that will be accumulating the hedging premiums paid
     * as a share of the total premium redirected to this address.
     * @param value The address for receiving hedging premiums
     **/
    function setHedgePool(address value)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(value != address(0));
        hedgePool = value;
    }

    /**
     * @notice Used for selling the options contracts
     * with the parameters chosen by the option buyer
     * such as the period of holding, option size (amount),
     * strike price and the premium to be paid for the option.
     * @param holder The option buyer address
     * @param period The option period
     * @param amount The option size
     * @param strike The option strike
     * @return id ID of ERC721 token linked to the option
     **/
    function sellOption(
        address holder,
        uint256 period,
        uint256 amount,
        uint256 strike
    ) external override returns (uint256 id) {
        if (strike == 0) strike = _currentPrice();
        uint256 balance = totalBalance();
        uint256 amountToBeLocked = _calculateLockedAmount(amount);

        require(period >= 1 days, "Pool Error: The period is too short");
        require(period <= 90 days, "Pool Error: The period is too long");
        require(
            (lockedAmount + amountToBeLocked) * 100 <=
                balance * maxUtilizationRate,
            "Pool Error: The amount is too large"
        );

        (uint256 settlementFee, uint256 premium) =
            _calculateTotalPremium(period, amount, strike);
        uint256 hedgedPremiumTotal = (premium * hedgedBalance) / balance;
        uint256 hedgeFee = (hedgedPremiumTotal * hedgeFeeRate) / 100;
        uint256 hedgePremium = hedgedPremiumTotal - hedgeFee;
        uint256 unhedgePremium = premium - hedgedPremiumTotal;

        lockedAmount += amountToBeLocked;
        id = optionsManager.createOptionFor(holder);
        options[id] = Option(
            OptionState.Active,
            strike,
            amount,
            amountToBeLocked,
            block.timestamp + period,
            hedgePremium,
            unhedgePremium
        );

        token.safeTransferFrom(
            _msgSender(),
            address(this),
            premium + settlementFee
        );
        token.safeTransfer(address(settlementFeeRecipient), settlementFee);
        settlementFeeRecipient.distributeUnrealizedRewards();
        if (hedgeFee > 0) token.safeTransfer(hedgePool, hedgeFee);
        emit Acquired(id, settlementFee, premium);
    }

    /**
     * @notice Used for setting the price calculator
     * contract that will be used for pricing the options.
     * @param pc A new price calculator contract address
     **/
    function setPriceCalculator(IPriceCalculator pc)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pricer = pc;
    }

    /**
     * @notice Used for exercising the ITM (in-the-money)
     * options contracts in case of having the unrealized profits
     * accrued during the period of holding the option contract.
     * @param id ID of ERC721 token linked to the option
     **/
    function exercise(uint256 id) external override {
        Option storage option = options[id];
        uint256 profit = _profitOf(option);
        require(
            optionsManager.isApprovedOrOwner(_msgSender(), id),
            "Pool Error: msg.sender can't exercise this option"
        );
        require(
            option.expired > block.timestamp,
            "Pool Error: The option has already expired"
        );
        require(
            profit > 0,
            "Pool Error: There are no unrealized profits for this option"
        );
        _unlock(option);
        option.state = OptionState.Exercised;
        _send(optionsManager.ownerOf(id), profit);
        emit Exercised(id, profit);
    }

    function _send(address to, uint256 transferAmount) private {
        require(to != address(0));
        uint256 hedgeLoss = (transferAmount * hedgedBalance) / totalBalance();
        uint256 unhedgeLoss = transferAmount - hedgeLoss;
        hedgedBalance -= hedgeLoss;
        unhedgedBalance -= unhedgeLoss;
        token.safeTransfer(to, transferAmount);
    }

    /**
     * @notice Used for unlocking the expired OTM (out-of-the-money)
     * options contracts in case if there was no unrealized P&L
     * accrued during the period of holding a particular option.
     * Note that the `unlock` function releases the liquidity that
     * was locked in the option when it was active and the premiums
     * that are distributed pro rata among the liquidity providers.
     * @param id ID of ERC721 token linked to the option
     **/
    function unlock(uint256 id) external override {
        Option storage option = options[id];
        require(
            option.expired < block.timestamp,
            "Pool Error: The option has not expired yet"
        );
        _unlock(option);
        option.state = OptionState.Expired;
        emit Expired(id);
    }

    function _unlock(Option storage option) internal {
        require(
            option.state == OptionState.Active,
            "Pool Error: The option with such an ID has already been exercised or expired"
        );
        lockedAmount -= option.lockedAmount;
        hedgedBalance += option.hedgePremium;
        unhedgedBalance += option.unhedgePremium;
    }

    function _calculateLockedAmount(uint256 amount)
        internal
        virtual
        returns (uint256)
    {
        return (amount * collateralizationRatio) / 100;
    }

    /**
     * @notice Used for depositing the funds into the pool
     * and minting the liquidity tranche ERC721 token
     * which represents the liquidity provider's share
     * in the pool and her unrealized P&L for this tranche.
     * @param account The liquidity provider's address
     * @param amount The size of the liquidity tranche
     * @param hedged The type of the liquidity tranche
     * @param minShare The minimum share in the pool for the user
     **/
    function provideFrom(
        address account,
        uint256 amount,
        bool hedged,
        uint256 minShare
    ) external override nonReentrant returns (uint256 share) {
        uint256 totalShare = hedged ? hedgedShare : unhedgedShare;
        uint256 balance = hedged ? hedgedBalance : unhedgedBalance;
        share = totalShare > 0 && balance > 0
            ? (amount * totalShare) / balance
            : amount * INITIAL_RATE;
        uint256 limit =
            hedged
                ? maxHedgedDepositAmount - hedgedBalance
                : maxDepositAmount - hedgedBalance - unhedgedBalance;
        require(share >= minShare, "Pool Error: The mint limit is too large");
        require(share > 0, "Pool Error: The amount is too small");
        require(
            amount <= limit,
            "Pool Error: Depositing into the pool is not available"
        );

        if (hedged) {
            hedgedShare += share;
            hedgedBalance += amount;
        } else {
            unhedgedShare += share;
            unhedgedBalance += amount;
        }

        uint256 trancheID = tranches.length;
        tranches.push(
            Tranche(TrancheState.Open, share, amount, block.timestamp, hedged)
        );
        _safeMint(account, trancheID);
        token.safeTransferFrom(_msgSender(), address(this), amount);
    }

    /**
     * @notice Used for withdrawing the funds from the pool
     * plus the net positive P&L earned or
     * minus the net negative P&L lost on
     * providing liquidity and selling options.
     * @param trancheID The liquidity tranche ID
     * @return amount The amount received after the withdrawal
     **/
    function withdraw(uint256 trancheID)
        external
        override
        nonReentrant
        returns (uint256 amount)
    {
        address owner = ownerOf(trancheID);
        Tranche memory t = tranches[trancheID];
        amount = _withdraw(owner, trancheID);
        if (t.hedged && amount < t.amount) {
            token.safeTransferFrom(hedgePool, owner, t.amount - amount);
            amount = t.amount;
        }
        emit Withdrawn(owner, trancheID, amount);
    }

    /**
     * @notice Used for withdrawing the funds from the pool
     * by the hedged liquidity tranches providers
     * in case of an urgent need to withdraw the liquidity
     * without receiving the loss compensation from
     * the hedging pool: the net difference between
     * the amount deposited and the withdrawal amount.
     * @param trancheID ID of liquidity tranche
     * @return amount The amount received after the withdrawal
     **/
    function withdrawWithoutHedge(uint256 trancheID)
        external
        override
        nonReentrant
        returns (uint256 amount)
    {
        address owner = ownerOf(trancheID);
        amount = _withdraw(owner, trancheID);
        emit Withdrawn(owner, trancheID, amount);
    }

    function _withdraw(address owner, uint256 trancheID)
        internal
        returns (uint256 amount)
    {
        Tranche storage t = tranches[trancheID];
        uint256 lockupPeriod =
            t.hedged
                ? lockupPeriodForHedgedTranches
                : lockupPeriodForUnhedgedTranches;
        require(t.state == TrancheState.Open);
        require(_isApprovedOrOwner(_msgSender(), trancheID));
        require(
            block.timestamp > t.creationTimestamp + lockupPeriod,
            "Pool Error: The withdrawal is locked up"
        );

        t.state = TrancheState.Closed;
        if (t.hedged) {
            amount = (t.share * hedgedBalance) / hedgedShare;
            hedgedShare -= t.share;
            hedgedBalance -= amount;
        } else {
            amount = (t.share * unhedgedBalance) / unhedgedShare;
            unhedgedShare -= t.share;
            unhedgedBalance -= amount;
        }

        token.safeTransfer(owner, amount);
    }

    /**
     * @return balance Returns the amount of liquidity available for withdrawing
     **/
    function availableBalance() public view returns (uint256 balance) {
        return totalBalance() - lockedAmount;
    }

    /**
     * @return balance Returns the total balance of liquidity provided to the pool
     **/
    function totalBalance() public view override returns (uint256 balance) {
        return hedgedBalance + unhedgedBalance;
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256 id
    ) internal view override {
        require(
            tranches[id].state == TrancheState.Open,
            "Pool Error: The closed tranches can not be transferred"
        );
    }

    /**
     * @notice Returns the amount of unrealized P&L of the option
     * that could be received by the option holder in case
     * if she exercises it as an ITM (in-the-money) option.
     * @param id ID of ERC721 token linked to the option
     **/
    function profitOf(uint256 id) external view returns (uint256) {
        return _profitOf(options[id]);
    }

    function _profitOf(Option memory option)
        internal
        view
        virtual
        returns (uint256 amount);

    /**
     * @notice Used for calculating the `TotalPremium`
     * for the particular option with regards to
     * the parameters chosen by the option buyer
     * such as the period of holding, size (amount)
     * and strike price.
     * @param period The period of holding the option
     * @param period The size of the option
     **/
    function calculateTotalPremium(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) external view override returns (uint256 settlementFee, uint256 premium) {
        return _calculateTotalPremium(period, amount, strike);
    }

    function _calculateTotalPremium(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) internal view virtual returns (uint256 settlementFee, uint256 premium) {
        (settlementFee, premium) = pricer.calculateTotalPremium(
            period,
            amount,
            strike
        );
        require(
            settlementFee + premium > amount / 1000,
            "HegicPool: The option's price is too low"
        );
    }

    /**
     * @notice Used for changing the `settlementFeeRecipient`
     * contract address for distributing the settlement fees
     * (staking rewards) among the staking participants.
     * @param recipient New staking contract address
     **/
    function setSettlementFeeRecipient(IHegicStaking recipient)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(address(recipient) != address(0));
        settlementFeeRecipient = recipient;
    }

    function _currentPrice() internal view returns (uint256 price) {
        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        price = uint256(latestPrice);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./HegicPool.sol";

/**
 * @author 0mllwntrmt3
 * @title Hegic Protocol V8888 Put Liquidity Pool Contract
 * @notice The Put Liquidity Pool Contract
 **/

contract HegicPUT is HegicPool {
    uint256 private immutable SpotDecimals; // 1e18
    uint256 private constant TokenDecimals = 1e6; // 1e6

    /**
     * @param name The pool contract name
     * @param symbol The pool ticker for the ERC721 options
     **/

    constructor(
        IERC20 _token,
        string memory name,
        string memory symbol,
        IOptionsManager manager,
        IPriceCalculator _pricer,
        IHegicStaking _settlementFeeRecipient,
        AggregatorV3Interface _priceProvider,
        uint8 spotDecimals
    )
        HegicPool(
            _token,
            name,
            symbol,
            manager,
            _pricer,
            _settlementFeeRecipient,
            _priceProvider
        )
    {
        SpotDecimals = 10**spotDecimals;
    }

    function _profitOf(Option memory option)
        internal
        view
        override
        returns (uint256 amount)
    {
        uint256 currentPrice = _currentPrice();
        if (currentPrice > option.strike) return 0;
        return
            ((option.strike - currentPrice) * option.amount * TokenDecimals) /
            SpotDecimals /
            1e8;
    }

    function _calculateLockedAmount(uint256 amount)
        internal
        view
        override
        returns (uint256)
    {
        return
            (amount *
                collateralizationRatio *
                _currentPrice() *
                TokenDecimals) /
            SpotDecimals /
            1e8 /
            100;
    }

    function _calculateTotalPremium(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) internal view override returns (uint256 settlementFee, uint256 premium) {
        uint256 currentPrice = _currentPrice();
        (settlementFee, premium) = pricer.calculateTotalPremium(
            period,
            amount,
            strike
        );
        settlementFee =
            (settlementFee * currentPrice * TokenDecimals) /
            1e8 /
            SpotDecimals;
        premium = (premium * currentPrice * TokenDecimals) / 1e8 / SpotDecimals;
    }
}

pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "../Interfaces/Interfaces.sol";
import "../Interfaces/IOptionsManager.sol";

/**
 * @author 0mllwntrmt3
 * @title Hegic Protocol V8888 Facade Contract
 * @notice The contract that calculates the options prices,
 * conducts the process of buying options, converts the premiums
 * into the token that the pool is denominated in and grants
 * permissions to the contracts such as GSN (Gas Station Network).
 **/

contract Facade is Ownable {
    using SafeERC20 for IERC20;

    IWETH public immutable WETH;
    IUniswapV2Router01 public immutable exchange;
    IOptionsManager public immutable optionsManager;
    address public _trustedForwarder;

    constructor(
        IWETH weth,
        IUniswapV2Router01 router,
        IOptionsManager manager,
        address trustedForwarder
    ) {
        WETH = weth;
        exchange = router;
        _trustedForwarder = trustedForwarder;
        optionsManager = manager;
    }

    /**
     * @notice Used for calculating the option price (the premium) and using
     * the swap router (if needed) to convert the tokens with which the user
     * pays the premium into the token in which the pool is denominated.
     * @param period The option period
     * @param amount The option size
     * @param strike The option strike
     * @param total The total premium
     * @param baseTotal The part of the premium that
     * is distributed among the liquidity providers
     * @param settlementFee The part of the premium that
     * is distributed among the HEGIC staking participants
     **/
    function getOptionPrice(
        IHegicPool pool,
        uint256 period,
        uint256 amount,
        uint256 strike,
        address[] calldata swappath
    )
        public
        view
        returns (
            uint256 total,
            uint256 baseTotal,
            uint256 settlementFee,
            uint256 premium
        )
    {
        (uint256 _baseTotal, uint256 baseSettlementFee, uint256 basePremium) =
            getBaseOptionCost(pool, period, amount, strike);
        if (swappath.length > 1)
            total = exchange.getAmountsIn(_baseTotal, swappath)[0];
        else total = _baseTotal;

        baseTotal = _baseTotal;
        settlementFee = (total * baseSettlementFee) / baseTotal;
        premium = (total * basePremium) / baseTotal;
    }

    /**
     * @notice Used for calculating the option price (the premium)
     * in the token in which the pool is denominated.
     * @param period The option period
     * @param amount The option size
     * @param strike The option strike
     **/
    function getBaseOptionCost(
        IHegicPool pool,
        uint256 period,
        uint256 amount,
        uint256 strike
    )
        public
        view
        returns (
            uint256 total,
            uint256 settlementFee,
            uint256 premium
        )
    {
        (settlementFee, premium) = pool.calculateTotalPremium(
            period,
            amount,
            strike
        );
        total = premium + settlementFee;
    }

    /**
     * @notice Used for approving the pools contracts addresses.
     **/
    function poolApprove(IHegicPool pool) external {
        pool.token().safeApprove(address(pool), 0);
        pool.token().safeApprove(address(pool), type(uint256).max);
    }

    /**
     * @notice Used for buying the option contract and converting
     * the buyer's tokens (the total premium) into the token
     * in which the pool is denominated.
     * @param period The option period
     * @param amount The option size
     * @param strike The option strike
     * @param acceptablePrice The highest acceptable price
     **/
    function createOption(
        IHegicPool pool,
        uint256 period,
        uint256 amount,
        uint256 strike,
        address[] calldata swappath,
        uint256 acceptablePrice
    ) external {
        address buyer = _msgSender();
        (uint256 optionPrice, uint256 rawOptionPrice, , ) =
            getOptionPrice(pool, period, amount, strike, swappath);
        require(
            optionPrice <= acceptablePrice,
            "Facade Error: The option price is too high"
        );
        IERC20 paymentToken = IERC20(swappath[0]);
        paymentToken.safeTransferFrom(buyer, address(this), optionPrice);
        if (swappath.length > 1) {
            if (
                paymentToken.allowance(address(this), address(exchange)) <
                optionPrice
            ) {
                paymentToken.safeApprove(address(exchange), 0);
                paymentToken.safeApprove(address(exchange), type(uint256).max);
            }

            exchange.swapTokensForExactTokens(
                rawOptionPrice,
                optionPrice,
                swappath,
                address(this),
                block.timestamp
            );
        }
        pool.sellOption(buyer, period, amount, strike);
    }

    /**
     * @notice Used for converting the liquidity provider's Ether (ETH)
     * into Wrapped Ether (WETH) and providing the funds into the pool.
     * @param hedged The liquidity tranche type: hedged or unhedged (classic)
     **/
    function provideEthToPool(
        IHegicPool pool,
        bool hedged,
        uint256 minShare
    ) external payable returns (uint256) {
        WETH.deposit{value: msg.value}();
        if (WETH.allowance(address(this), address(pool)) < msg.value)
            WETH.approve(address(pool), type(uint256).max);
        return pool.provideFrom(msg.sender, msg.value, hedged, minShare);
    }

    /**
     * @notice Unlocks the array of options.
     * @param optionIDs The array of options
     **/
    function unlockAll(IHegicPool pool, uint256[] calldata optionIDs) external {
        uint256 arrayLength = optionIDs.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            pool.unlock(optionIDs[i]);
        }
    }

    /**
     * @notice Used for granting the GSN (Gas Station Network) contract
     * the permission to pay the gas (transaction) fees for the users.
     * @param forwarder GSN (Gas Station Network) contract address
     **/
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function claimAllStakingProfits(
        IHegicStaking[] calldata stakings,
        address account
    ) external {
        uint256 arrayLength = stakings.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            IHegicStaking s = stakings[i];
            if (s.profitOf(account) > 0) s.claimProfits(account);
        }
    }

    function _msgSender() internal view override returns (address signer) {
        signer = msg.sender;
        if (msg.data.length >= 20 && isTrustedForwarder(signer)) {
            assembly {
                signer := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        }
    }

    function exercise(uint256 optionId) external {
        require(
            optionsManager.isApprovedOrOwner(_msgSender(), optionId),
            "Facade Error: _msgSender is not eligible to exercise the option"
        );
        IHegicPool(optionsManager.tokenPool(optionId)).exercise(optionId);
    }

    function versionRecipient() external pure returns (string memory) {
        return "2.2.2";
    }
}

pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./HegicPool.sol";

/**
 * @author 0mllwntrmt3
 * @title Hegic Protocol V8888 Call Liquidity Pool Contract
 * @notice The Call Liquidity Pool Contract
 **/
contract HegicCALL is HegicPool {
    /**
     * @param name The pool contract name
     * @param symbol The pool ticker for the ERC721 options
     **/
    constructor(
        IERC20 _token,
        string memory name,
        string memory symbol,
        IOptionsManager manager,
        IPriceCalculator _pricer,
        IHegicStaking _settlementFeeRecipient,
        AggregatorV3Interface _priceProvider
    )
        HegicPool(
            _token,
            name,
            symbol,
            manager,
            _pricer,
            _settlementFeeRecipient,
            _priceProvider
        )
    {}

    function _profitOf(Option memory option)
        internal
        view
        override
        returns (uint256 amount)
    {
        uint256 currentPrice = _currentPrice();
        if (currentPrice < option.strike) return 0;
        return ((currentPrice - option.strike) * option.amount) / currentPrice;
    }
}

pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    uint8 private immutable _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 __decimals
    ) ERC20(name, symbol) {
        _decimals = __decimals;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mintTo(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}

pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./ERC20Mock.sol";

contract WETHMock is ERC20Mock("WETH", "Wrapped Ether", 18) {
    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
}

pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "./ERC20Mock.sol";
import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";

contract UniswapRouterMock {
    ERC20Mock public immutable WBTC;
    ERC20Mock public immutable USDC;
    AggregatorV3Interface public immutable WBTCPriceProvider;
    AggregatorV3Interface public immutable ETHPriceProvider;

    constructor(
        ERC20Mock _wbtc,
        ERC20Mock _usdc,
        AggregatorV3Interface wpp,
        AggregatorV3Interface epp
    ) {
        WBTC = _wbtc;
        USDC = _usdc;
        WBTCPriceProvider = wpp;
        ETHPriceProvider = epp;
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 /*deadline*/
    ) external payable returns (uint256[] memory amounts) {
        require(path.length == 2, "UniswapMock: wrong path");
        require(
            path[1] == address(USDC) || path[1] == address(WBTC),
            "UniswapMock: too small value"
        );
        amounts = getAmountsIn(amountOut, path);
        require(msg.value >= amounts[0], "UniswapMock: too small value");
        if (msg.value > amounts[0])
            payable(msg.sender).transfer(msg.value - amounts[0]);
        ERC20Mock(path[1]).mintTo(to, amountOut);
    }

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        public
        view
        returns (uint256[] memory amounts)
    {
        require(path.length == 2, "UniswapMock: wrong path");
        uint256 amount;
        if (path[1] == address(USDC)) {
            (, int256 ethPrice, , , ) = ETHPriceProvider.latestRoundData();
            amount = (amountOut * 1e8) / uint256(ethPrice);
        } else if (path[1] == address(WBTC)) {
            (, int256 ethPrice, , , ) = ETHPriceProvider.latestRoundData();
            (, int256 wbtcPrice, , , ) = WBTCPriceProvider.latestRoundData();
            amount = (amountOut * uint256(wbtcPrice)) / uint256(ethPrice);
        } else {
            revert("UniswapMock: wrong path");
        }
        amounts = new uint256[](2);
        amounts[0] = (amount * 103) / 100;
        amounts[1] = amountOut;
    }
}

pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

import "../Interfaces/Interfaces.sol";
import "../utils/Math.sol";

/**
 * @author 0mllwntrmt3
 * @title Hegic Protocol V8888 Price Calculator Contract
 * @notice The contract that calculates the options prices (the premiums)
 * that are adjusted through the `ImpliedVolRate` parameter.
 **/

contract PriceCalculator is IPriceCalculator, Ownable {
    using HegicMath for uint256;

    uint256 public impliedVolRate;
    uint256 internal constant PRICE_DECIMALS = 1e8;
    uint256 internal constant PRICE_MODIFIER_DECIMALS = 1e8;
    uint256 public utilizationRate = 0;
    AggregatorV3Interface public priceProvider;
    IHegicPool pool;

    constructor(
        uint256 initialRate,
        AggregatorV3Interface _priceProvider,
        IHegicPool _pool
    ) {
        pool = _pool;
        priceProvider = _priceProvider;
        impliedVolRate = initialRate;
    }

    /**
     * @notice Used for adjusting the options prices (the premiums)
     * while balancing the asset's implied volatility rate.
     * @param value New IVRate value
     **/
    function setImpliedVolRate(uint256 value) external onlyOwner {
        impliedVolRate = value;
    }

    /**
     * @notice Used for updating utilizationRate value
     * @param value New utilizationRate value
     **/
    function setUtilizationRate(uint256 value) external onlyOwner {
        utilizationRate = value;
    }

    /**
     * @notice Used for calculating the options prices
     * @param period The option period in seconds (1 days <= period <= 90 days)
     * @param amount The option size
     * @param strike The option strike
     * @return settlementFee The part of the premium that
     * is distributed among the HEGIC staking participants
     * @return premium The part of the premium that
     * is distributed among the liquidity providers
     **/
    function calculateTotalPremium(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) public view override returns (uint256 settlementFee, uint256 premium) {
        uint256 currentPrice = _currentPrice();
        if (strike == 0) strike = currentPrice;
        require(
            strike == currentPrice,
            "Only ATM options are currently available"
        );
        uint256 total = _calculatePeriodFee(amount, period);
        settlementFee = total / 5;
        premium = total - settlementFee;
    }

    /**
     * @notice Calculates and prices in the time value of the option
     * @param amount Option size
     * @param period The option period in seconds (1 days <= period <= 90 days)
     * @return fee The premium size to be paid
     **/
    function _calculatePeriodFee(uint256 amount, uint256 period)
        internal
        view
        returns (uint256 fee)
    {
        return
            (amount * _priceModifier(amount, period, pool)) /
            PRICE_DECIMALS /
            PRICE_MODIFIER_DECIMALS;
    }

    /**
     * @notice Calculates `periodFee` of the option
     * @param amount The option size
     * @param period The option period in seconds (1 days <= period <= 90 days)
     **/
    function _priceModifier(
        uint256 amount,
        uint256 period,
        IHegicPool pool
    ) internal view returns (uint256 iv) {
        uint256 poolBalance = pool.totalBalance();
        require(poolBalance > 0, "Pool Error: The pool is empty");
        iv = impliedVolRate * period.sqrt();

        uint256 lockedAmount = pool.lockedAmount() + amount;
        uint256 utilization = (lockedAmount * 100e8) / poolBalance;

        if (utilization > 40e8) {
            iv += (iv * (utilization - 40e8) * utilizationRate) / 40e16;
        }
    }

    /**
     * @notice Used for requesting the current price of the asset
     * using the ChainLink data feeds contracts.
     * See https://feeds.chain.link/
     * @return price Price
     **/
    function _currentPrice() internal view returns (uint256 price) {
        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        price = uint256(latestPrice);
    }
}

pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2021 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

library HegicMath {
    /**
     * @dev Calculates a square root of the number.
     * Responds with an "invalid opcode" at uint(-1).
     **/
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        result = x;
        uint256 k = (x >> 1) + 1;
        while (k < result) (result, k) = (k, (x / k + k) >> 1);
    }
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

