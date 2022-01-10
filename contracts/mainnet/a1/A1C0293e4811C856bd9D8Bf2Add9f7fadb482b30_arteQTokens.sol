/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ERC1155Supply.sol";
import "./IarteQTokens.sol";
import "./IarteQTaskFinalizer.sol";

/// @author Kam Amini <[email protected]> <[email protected]> <[email protected]> <[email protected]>
///
/// Reviewed and revised by: Masoud Khosravi <masoud_at_2b.team> <mkh_at_arteq.io>
///                          Ali Jafari <ali_at_2b.team> <aj_at_arteq.io>
///
/// @title This contract keeps track of the tokens used in artèQ Investment
/// Fund ecosystem. It also contains the logic used for profit distribution.
///
/// @notice Use at your own risk
contract arteQTokens is ERC1155Supply, IarteQTokens {

    /// The main artèQ token
    uint256 public constant ARTEQ = 1;

    /// The governance token of artèQ Investment Fund
    uint256 public constant gARTEQ = 2;

    // The mapping from token IDs to their respective Metadata URIs
    mapping (uint256 => string) private _tokenMetadataURIs;

    // The admin smart contract
    address private _adminContract;

    // Treasury account responsible for asset-token ratio appreciation.
    address private _treasuryAccount;

    // This can be a Uniswap V1/V2 exchange (pool) account created for ARTEQ token,
    // or any other exchange account. Treasury contract uses these pools to buy
    // back or sell tokens. In case of buy backs, the tokens must be delivered to
    // treasury account from these contracts. Otherwise, the profit distribution
    // logic doesn't get triggered.
    address private _exchange1Account;
    address private _exchange2Account;
    address private _exchange3Account;
    address private _exchange4Account;
    address private _exchange5Account;

    // All the profits accumulated since the deployment of the contract. This is
    // used as a marker to facilitate the caluclation of every eligible account's
    // share from the profits in a given time range.
    uint256 private _allTimeProfit;

    // The actual number of profit tokens transferred to accounts
    uint256 private _profitTokensTransferredToAccounts;

    // The percentage of the bought back tokens which is considered as profit for gARTEQ owners
    // Default value is 20% and only admin contract can change that.
    uint private _profitPercentage;

    // In order to caluclate the share of each elgiible account from the profits,
    // and more importantly, in order to do this efficiently (less gas usage),
    // we need this mapping to remember the "all time profit" when an account
    // is modified (receives tokens or sends tokens).
    mapping (address => uint256) private _profitMarkers;

    // A timestamp indicating when the ramp-up phase gets expired.
    uint256 private _rampUpPhaseExpireTimestamp;

    // Indicates until when the address cannot send any tokens
    mapping (address => uint256) private _lockedUntilTimestamps;

    /// Emitted when the admin contract is changed.
    event AdminContractChanged(address newContract);

    /// Emitted when the treasury account is changed.
    event TreasuryAccountChanged(address newAccount);

    /// Emitted when the exchange account is changed.
    event Exchange1AccountChanged(address newAccount);
    event Exchange2AccountChanged(address newAccount);
    event Exchange3AccountChanged(address newAccount);
    event Exchange4AccountChanged(address newAccount);
    event Exchange5AccountChanged(address newAccount);

    /// Emitted when the profit percentage is changed.
    event ProfitPercentageChanged(uint newPercentage);

    /// Emitted when a token distribution occurs during the ramp-up phase
    event RampUpPhaseTokensDistributed(address to, uint256 amount, uint256 lockedUntilTimestamp);

    /// Emitted when some buy back tokens are received by the treasury account.
    event ProfitTokensCollected(uint256 amount);

    /// Emitted when a share holder receives its tokens from the buy back profits.
    event ProfitTokensDistributed(address to, uint256 amount);

    // Emitted when profits are caluclated because of a manual buy back event
    event ManualBuyBackWithdrawalFromTreasury(uint256 amount);

    modifier adminApprovalRequired(uint256 adminTaskId) {
        _;
        // This must succeed otherwise the tx gets reverted
        IarteQTaskFinalizer(_adminContract).finalizeTask(msg.sender, adminTaskId);
    }

    modifier validToken(uint256 tokenId) {
        require(tokenId == ARTEQ || tokenId == gARTEQ, "arteQTokens: non-existing token");
        _;
    }

    modifier onlyRampUpPhase() {
        require(block.timestamp < _rampUpPhaseExpireTimestamp, "arteQTokens: ramp up phase is finished");
        _;
    }

    constructor(address adminContract) {
        _adminContract = adminContract;

        /// Must be set later
        _treasuryAccount = address(0);

        /// Must be set later
        _exchange1Account = address(0);
        _exchange2Account = address(0);
        _exchange3Account = address(0);
        _exchange4Account = address(0);
        _exchange5Account = address(0);

        string memory arteQURI = "ipfs://QmfBtH8BSztaYn3QFnz2qvu2ehZgy8AZsNMJDkgr3pdqT8";
        string memory gArteQURI = "ipfs://QmRAXmU9AymDgtphh37hqx5R2QXSS2ngchQRDFtg6XSD7w";
        _tokenMetadataURIs[ARTEQ] = arteQURI;
        emit URI(arteQURI, ARTEQ);
        _tokenMetadataURIs[gARTEQ] = gArteQURI;
        emit URI(gArteQURI, gARTEQ);

        /// 10 billion
        _initialMint(_adminContract, ARTEQ, 10 ** 10, "");
        /// 1 million
        _initialMint(_adminContract, gARTEQ, 10 ** 6, "");

        /// Obviously, no profit at the time of deployment
        _allTimeProfit = 0;

        _profitPercentage = 20;

        /// Tuesday, February 1, 2022 12:00:00 AM
        _rampUpPhaseExpireTimestamp = 1643673600;
    }

    /// See {ERC1155-uri}
    function uri(uint256 tokenId) external view virtual override validToken(tokenId) returns (string memory) {
        return _tokenMetadataURIs[tokenId];
    }

    function setURI(
        uint256 adminTaskId,
        uint256 tokenId,
        string memory newUri
    ) external adminApprovalRequired(adminTaskId) validToken(tokenId) {
        _tokenMetadataURIs[tokenId] = newUri;
        emit URI(newUri, tokenId);
    }

    /// Returns the set treasury account
    /// @return The set treasury account
    function getTreasuryAccount() external view returns (address) {
        return _treasuryAccount;
    }

    /// Sets a new treasury account. Just after deployment, treasury account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new treasury address
    function setTreasuryAccount(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for treasury account");
        _treasuryAccount = newAccount;
        emit TreasuryAccountChanged(newAccount);
    }

    /// Returns the 1st exchange account
    /// @return The 1st exchnage account
    function getExchange1Account() external view returns (address) {
        return _exchange1Account;
    }

    /// Returns the 2nd exchange account
    /// @return The 2nd exchnage account
    function getExchange2Account() external view returns (address) {
        return _exchange2Account;
    }

    /// Returns the 3rd exchange account
    /// @return The 3rd exchnage account
    function getExchange3Account() external view returns (address) {
        return _exchange3Account;
    }

    /// Returns the 4th exchange account
    /// @return The 4th exchnage account
    function getExchange4Account() external view returns (address) {
        return _exchange4Account;
    }

    /// Returns the 5th exchange account
    /// @return The 5th exchnage account
    function getExchange5Account() external view returns (address) {
        return _exchange5Account;
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange1Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange1Account = newAccount;
        emit Exchange1AccountChanged(newAccount);
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange2Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange2Account = newAccount;
        emit Exchange2AccountChanged(newAccount);
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange3Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange3Account = newAccount;
        emit Exchange3AccountChanged(newAccount);
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange4Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange4Account = newAccount;
        emit Exchange4AccountChanged(newAccount);
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange5Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange5Account = newAccount;
        emit Exchange5AccountChanged(newAccount);
    }

    /// Returns the profit percentage
    /// @return The set treasury account
    function getProfitPercentage() external view returns (uint) {
        return _profitPercentage;
    }

    /// Sets a new profit percentage. This is the percentage of bought-back tokens which is considered
    /// as profit for gARTEQ owners. The value can be between 10% and 50%.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newPercentage new exchange address
    function setProfitPercentage(uint256 adminTaskId, uint newPercentage) external adminApprovalRequired(adminTaskId) {
        require(newPercentage >= 10 && newPercentage <= 50, "arteQTokens: invalid value for profit percentage");
        _profitPercentage = newPercentage;
        emit ProfitPercentageChanged(newPercentage);
    }

    /// Transfer from admin contract
    function transferFromAdminContract(
        uint256 adminTaskId,
        address to,
        uint256 id,
        uint256 amount
    ) external adminApprovalRequired(adminTaskId) {
        _safeTransferFrom(_msgSender(), _adminContract, to, id, amount, "");
    }

    /// A token distribution mechanism, only valid in ramp-up phase, valid till the end of Jan 2022.
    function rampUpPhaseDistributeToken(
        uint256 adminTaskId,
        address[] memory tos,
        uint256[] memory amounts,
        uint256[] memory lockedUntilTimestamps
    ) external adminApprovalRequired(adminTaskId) onlyRampUpPhase {
        require(tos.length == amounts.length, "arteQTokens: inputs have incorrect lengths");
        for (uint256 i = 0; i < tos.length; i++) {
            require(tos[i] != _treasuryAccount, "arteQTokens: cannot transfer to treasury account");
            require(tos[i] != _adminContract, "arteQTokens: cannot transfer to admin contract");
            _safeTransferFrom(_msgSender(), _adminContract, tos[i], ARTEQ, amounts[i], "");
            if (lockedUntilTimestamps[i] > 0) {
                _lockedUntilTimestamps[tos[i]] = lockedUntilTimestamps[i];
            }
            emit RampUpPhaseTokensDistributed(tos[i], amounts[i], lockedUntilTimestamps[i]);
        }
    }

    function balanceOf(address account, uint256 tokenId) public view virtual override validToken(tokenId) returns (uint256) {
        if (tokenId == gARTEQ) {
            return super.balanceOf(account, tokenId);
        }
        return super.balanceOf(account, tokenId) + _calcUnrealizedProfitTokens(account);
    }

    function allTimeProfit() external view returns (uint256) {
        return _allTimeProfit;
    }

    function totalCirculatingGovernanceTokens() external view returns (uint256) {
        return totalSupply(gARTEQ) - balanceOf(_adminContract, gARTEQ);
    }

    function profitTokensTransferredToAccounts() external view returns (uint256) {
        return _profitTokensTransferredToAccounts;
    }

    function compatBalanceOf(address /* origin */, address account, uint256 tokenId) external view virtual override returns (uint256) {
        return balanceOf(account, tokenId);
    }

    function compatTotalSupply(address /* origin */, uint256 tokenId) external view virtual override returns (uint256) {
        return totalSupply(tokenId);
    }

    function compatTransfer(address origin, address to, uint256 tokenId, uint256 amount) external virtual override {
        address from = origin;
        _safeTransferFrom(origin, from, to, tokenId, amount, "");
    }

    function compatTransferFrom(address origin, address from, address to, uint256 tokenId, uint256 amount) external virtual override {
        require(
            from == origin || isApprovedForAll(from, origin),
            "arteQTokens: caller is not owner nor approved "
        );
        _safeTransferFrom(origin, from, to, tokenId, amount, "");
    }

    function compatAllowance(address /* origin */, address account, address operator) external view virtual override returns (uint256) {
        if (isApprovedForAll(account, operator)) {
            return 2 ** 256 - 1;
        }
        return 0;
    }

    function compatApprove(address origin, address operator, uint256 amount) external virtual override {
        _setApprovalForAll(origin, operator, amount > 0);
    }

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueTokens(uint256 adminTaskId, IERC20 foreignToken, address to) external adminApprovalRequired(adminTaskId) {
        foreignToken.transfer(to, foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTRescue(uint256 adminTaskId, IERC721 foreignNFT, address to) external adminApprovalRequired(adminTaskId) {
        foreignNFT.setApprovalForAll(to, true);
    }

    // In case of any manual buy back event which is not processed through DEX contracts, this function
    // helps admins distribute the profits. This function must be called only when the bought back tokens
    // have been successfully transferred to treasury account.
    function processManualBuyBackEvent(uint256 adminTaskId, uint256 boughtBackTokensAmount) external adminApprovalRequired(adminTaskId) {
        uint256 profit = (boughtBackTokensAmount * _profitPercentage) / 100;
        if (profit > 0) {
            _balances[ARTEQ][_treasuryAccount] -= profit;
            emit ManualBuyBackWithdrawalFromTreasury(profit);
            _allTimeProfit += profit;
            emit ProfitTokensCollected(profit);
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        // We have to call the super function in order to have the total supply correct.
        // It is actually needed by the first two _initialMint calls only. After that, it is
        // a no-op function.
        super._beforeTokenTransfer(operator, from, to, id, amounts, data);

        // this is one of the two first _initialMint calls
        if (from == address(0)) {
            return;
        }

        // This is a buy-back callback from exchange account
        if ((
                from == _exchange1Account ||
                from == _exchange2Account ||
                from == _exchange3Account ||
                from == _exchange4Account ||
                from == _exchange5Account
        ) && to == _treasuryAccount) {
            require(amounts.length == 2 && id == ARTEQ, "arteQTokens: invalid transfer from exchange");
            uint256 profit = (amounts[0] * _profitPercentage) / 100;
            amounts[1] = amounts[0] - profit;
            if (profit > 0) {
                _allTimeProfit += profit;
                emit ProfitTokensCollected(profit);
            }
            return;
        }

        // Ensures that the locked accounts cannot send their ARTEQ tokens
        if (id == ARTEQ) {
            require(_lockedUntilTimestamps[from] == 0 || block.timestamp > _lockedUntilTimestamps[from], "arteQTokens: account cannot send tokens");
        }

        // Realize/Transfer the accumulated profit of 'from' account and make it spendable
        if (from != _adminContract &&
            from != _treasuryAccount &&
            from != _exchange1Account &&
            from != _exchange2Account &&
            from != _exchange3Account &&
            from != _exchange4Account &&
            from != _exchange5Account) {
            _realizeAccountProfitTokens(from);
        }

        // Realize/Transfer the accumulated profit of 'to' account and make it spendable
        if (to != _adminContract &&
            to != _treasuryAccount &&
            to != _exchange1Account &&
            to != _exchange2Account &&
            to != _exchange3Account &&
            to != _exchange4Account &&
            to != _exchange5Account) {
            _realizeAccountProfitTokens(to);
        }
    }

    function _calcUnrealizedProfitTokens(address account) internal view returns (uint256) {
        if (account == _adminContract ||
            account == _treasuryAccount ||
            account == _exchange1Account ||
            account == _exchange2Account ||
            account == _exchange3Account ||
            account == _exchange4Account ||
            account == _exchange5Account) {
            return 0;
        }
        uint256 profitDifference = _allTimeProfit - _profitMarkers[account];
        uint256 totalGovTokens = totalSupply(gARTEQ) - balanceOf(_adminContract, gARTEQ);
        if (totalGovTokens == 0) {
            return 0;
        }
        uint256 tokensToTransfer = (profitDifference * balanceOf(account, gARTEQ)) / totalGovTokens;
        return tokensToTransfer;
    }

    // This function actually transfers the unrealized accumulated profit tokens of an account
    // and make them spendable by that account. The balance should not differ after the
    // trasnfer as the balance already includes the unrealized tokens.
    function _realizeAccountProfitTokens(address account) internal {
        bool updateProfitMarker = true;
        // If 'account' has some governance tokens then calculate the accumulated profit since the last distribution
        if (balanceOf(account, gARTEQ) > 0) {
            uint256 tokensToTransfer = _calcUnrealizedProfitTokens(account);
            // If the profit is too small and no token can be transferred, then don't update the profit marker and
            // let the account wait for the next round of profit distribution
            if (tokensToTransfer == 0) {
                updateProfitMarker = false;
            } else {
                _balances[ARTEQ][account] += tokensToTransfer;
                _profitTokensTransferredToAccounts += tokensToTransfer;
                emit ProfitTokensDistributed(account, tokensToTransfer);
            }
        }
        if (updateProfitMarker) {
            _profitMarkers[account] = _allTimeProfit;
        }
    }

    receive() external payable {
        revert("arteQTokens: cannot accept ether");
    }

    fallback() external payable {
        revert("arteQTokens: cannot accept ether");
    }
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

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0
// Based on OpenZeppelin Contracts v4.3.2 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity 0.8.0;

import "./ERC1155.sol";

/**
 * @author Modified by Kam Amini <[email protected]> <[email protected]> <[email protected]>
 *
 * @notice Use at your own risk
 *
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 *
 * Note: 2B has modified the original code to cover its needs as
 * part of artèQ Investment Fund ecosystem
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, id, amounts, data);

        if (from == address(0)) {
            _totalSupply[id] += amounts[0];
        }

        if (to == address(0)) {
            _totalSupply[id] -= amounts[0];
        }
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

/// @author Kam Amini <[email protected]> <[email protected]> <[email protected]>
///
/// @title An interface which allows ERC-20 tokens to interact with the
/// main ERC-1155 contract
///
/// @notice Use at your own risk
interface IarteQTokens {
    function compatBalanceOf(address origin, address account, uint256 tokenId) external view returns (uint256);
    function compatTotalSupply(address origin, uint256 tokenId) external view returns (uint256);
    function compatTransfer(address origin, address to, uint256 tokenId, uint256 amount) external;
    function compatTransferFrom(address origin, address from, address to, uint256 tokenId, uint256 amount) external;
    function compatAllowance(address origin, address account, address operator) external view returns (uint256);
    function compatApprove(address origin, address operator, uint256 amount) external;
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

/// @author Kam Amini <[email protected]> <[email protected]> <[email protected]>
/// @title The interface for finalizing tasks. Mainly used by artèQ contracts to
/// perform administrative tasks in conjuction with admin contract.
interface IarteQTaskFinalizer {

    event TaskFinalized(address finalizer, address origin, uint256 taskId);

    function finalizeTask(address origin, uint256 taskId) external;
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

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0
// Based on OpenZeppelin Contracts v4.3.2 (token/ERC1155/ERC1155.sol)

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

 /**
  * @author Modified by Kam Amini <[email protected]> <[email protected]> <[email protected]>
  *
  * @notice Use at your own risk
  *
  * Note: 2B has modified the original code to cover its needs as
  * part of artèQ Investment Fund ecosystem
  */
abstract contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    // arteQ: we made this field public in order to distribute profits in the token contract
    mapping(uint256 => mapping(address => uint256)) public _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev See {_setURI}.
     */
    constructor() {
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved "
        );
        _safeTransferFrom(_msgSender(), from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address /* from */,
        address /* to */,
        uint256[] memory /* ids */,
        uint256[] memory /* amounts */,
        bytes memory /* data */
    ) public virtual override {
        revert("ERC1155: not implemented");
    }

    function _safeTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        // arteQ: we have to read the returned amount again as it can change in the function
        uint256[] memory amounts = _asArray(amount, 2);
        _beforeTokenTransfer(operator, from, to, id, amounts, data);
        uint256 fromAmount = amounts[0];
        uint256 toAmount = amounts[1];

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= fromAmount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - fromAmount;
        }
        _balances[id][to] += toAmount;

        emit TransferSingle(operator, from, to, id, amount);
    }

    function _initialMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, id, _asArray(amount, 2), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(
        address /* operator */,
        address /* from */,
        address /* to */,
        uint256 /* id */,
        uint256[] memory /* amounts */,
        bytes memory /* data */
    ) internal virtual {}

    function _asArray(uint256 element, uint len) private pure returns (uint256[] memory) {
        if (len == 1) {
            uint256[] memory array = new uint256[](1);
            array[0] = element;
            return array;
        } else if (len == 2) {
            uint256[] memory array = new uint256[](2);
            array[0] = element;
            array[1] = element;
            return array;
        }
        revert("ERC1155: length must be 1 or 2");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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