// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
pragma solidity 0.8.10;

import {IERC20} from "IERC20.sol";
import {IERC721} from "IERC721.sol";

interface IFinancialInstrument is IERC721 {
    function principal(uint256 instrumentId) external view returns (uint256);

    function underlyingToken(uint256 instrumentId) external view returns (IERC20);

    function recipient(uint256 instrumentId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IFinancialInstrument} from "IFinancialInstrument.sol";

interface IDebtInstrument is IFinancialInstrument {
    function endDate(uint256 instrumentId) external view returns (uint256);

    function repay(uint256 instrumentId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "IERC20.sol";
import {IDebtInstrument} from "IDebtInstrument.sol";

enum BulletLoanStatus {
    Issued,
    FullyRepaid,
    Defaulted,
    Resolved
}

interface IBulletLoans is IDebtInstrument {
    struct LoanMetadata {
        IERC20 underlyingToken;
        BulletLoanStatus status;
        uint256 principal;
        uint256 totalDebt;
        uint256 amountRepaid;
        uint256 duration;
        uint256 repaymentDate;
        address recipient;
    }

    function loans(uint256 id)
        external
        view
        returns (
            IERC20,
            BulletLoanStatus,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address
        );

    function createLoan(
        IERC20 _underlyingToken,
        uint256 principal,
        uint256 totalDebt,
        uint256 duration,
        address recipient
    ) external returns (uint256);

    function markLoanAsDefaulted(uint256 instrumentId) external;

    function markLoanAsResolved(uint256 instrumentId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "IERC20.sol";

interface IERC20WithDecimals is IERC20 {
    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IProtocolConfig {
    function protocolFee() external view returns (uint256);

    function protocolAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
pragma solidity 0.8.10;

import {IERC20Upgradeable} from "IERC20Upgradeable.sol";
import {IERC20WithDecimals} from "IERC20WithDecimals.sol";

interface IPortfolio is IERC20Upgradeable {
    function endDate() external view returns (uint256);

    function underlyingToken() external view returns (IERC20WithDecimals);

    function value() external view returns (uint256);

    function deposit(uint256 amount, bytes memory metadata) external;

    function withdraw(uint256 amount, bytes memory metadata) external returns (uint256 withdrawnAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ILenderVerifier {
    function isAllowed(
        address lender,
        uint256 amount,
        bytes memory signature
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20WithDecimals} from "IERC20WithDecimals.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {IPortfolio} from "IPortfolio.sol";
import {IBulletLoans} from "IBulletLoans.sol";
import {ILenderVerifier} from "ILenderVerifier.sol";

enum ManagedPortfolioStatus {
    Open,
    Frozen,
    Closed
}

interface IManagedPortfolio is IPortfolio {
    function initialize(
        string memory __name,
        string memory __symbol,
        address _manager,
        IERC20WithDecimals _underlyingToken,
        IBulletLoans _bulletLoans,
        IProtocolConfig _protocolConfig,
        ILenderVerifier _lenderVerifier,
        uint256 _duration,
        uint256 _maxSize,
        uint256 _managerFee
    ) external;

    function managerFee() external view returns (uint256);

    function maxSize() external view returns (uint256);

    function createBulletLoan(
        uint256 loanDuration,
        address borrower,
        uint256 principalAmount,
        uint256 repaymentAmount
    ) external;

    function setEndDate(uint256 newEndDate) external;

    function markLoanAsDefaulted(uint256 instrumentId) external;

    function getStatus() external view returns (ManagedPortfolioStatus);

    function getOpenLoanIds() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "IERC20.sol";
import {IBulletLoans, BulletLoanStatus} from "IBulletLoans.sol";
import {IManagedPortfolio} from "IManagedPortfolio.sol";

struct LoanFrontendData {
    IERC20 token;
    BulletLoanStatus status;
    uint256 principal;
    uint256 totalDebt;
    uint256 amountRepaid;
    uint256 duration;
    uint256 repaymentDate;
    address recipient;
    uint256 loanId;
}

contract LoansReader {
    function getLoans(address bulletLoans, address portfolio) external view returns (LoanFrontendData[] memory) {
        uint256[] memory ids = IManagedPortfolio(portfolio).getOpenLoanIds();
        LoanFrontendData[] memory _loans = new LoanFrontendData[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            (
                IERC20 token,
                BulletLoanStatus status,
                uint256 principal,
                uint256 totalDebt,
                uint256 amountRepaid,
                uint256 duration,
                uint256 repaymentDate,
                address recipient
            ) = IBulletLoans(bulletLoans).loans(ids[i]);
            _loans[i] = LoanFrontendData(
                token,
                status,
                principal,
                totalDebt,
                amountRepaid,
                duration,
                repaymentDate,
                recipient,
                ids[i]
            );
        }
        return _loans;
    }
}