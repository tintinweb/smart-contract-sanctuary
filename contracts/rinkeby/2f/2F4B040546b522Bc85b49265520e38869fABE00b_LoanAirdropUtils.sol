// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IDirectLoanBase.sol";
import "./LoanData.sol";
import "../../../interfaces/IDirectLoanCoordinator.sol";
import "../../../utils/ContractKeys.sol";
import "../../../interfaces/INftfiHub.sol";
import "../../../interfaces/IPermittedPartners.sol";
import "../../../interfaces/IPermittedERC20s.sol";
import "../../../interfaces/IAirdropFlashLoan.sol";
import "../../../interfaces/INftWrapper.sol";
import "../../../airdrop/IAirdropReceiverFactory.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title  LoanAirdropUtils
 * @author NFTfi
 * @notice Helper library for LoanBase
 */
library LoanAirdropUtils {
    /**
     * @notice This event is fired whenever a flashloan is initiated to pull an airdrop
     *
     * @param  loanId - A unique identifier for this particular loan, sourced from the Loan Coordinator.
     * @param  borrower - The address of the borrower.
     * @param  nftCollateralId - The ID within the AirdropReceiver for the NFT being used as collateral for this
     * loan.
     * @param  nftCollateralContract - The ERC721 contract of the NFT collateral
     * @param target - address of the airdropping contract
     * @param data - function selector to be called
     */
    event AirdropPulledFlashloan(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 nftCollateralId,
        address nftCollateralContract,
        address target,
        bytes data
    );

    /**
     * @notice This event is fired whenever the collateral gets wrapped in an airdrop receiver
     *
     * @param  loanId - A unique identifier for this particular loan, sourced from the Loan Coordinator.
     * @param  borrower - The address of the borrower.
     * @param  nftCollateralId - The ID within the AirdropReceiver for the NFT being used as collateral for this
     * loan.
     * @param  nftCollateralContract - The contract of the NFT collateral
     * @param receiverId - id of the created AirdropReceiver, takes the place of nftCollateralId on the loan
     * @param receiverInstance - address of the created AirdropReceiver
     */
    event CollateralWrapped(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 nftCollateralId,
        address nftCollateralContract,
        uint256 receiverId,
        address receiverInstance
    );

    function pullAirdrop(
        uint256 _loanId,
        LoanData.LoanTerms memory _loan,
        address _target,
        bytes calldata _data,
        address _nftAirdrop,
        uint256 _nftAirdropId,
        bool _is1155,
        uint256 _nftAirdropAmount,
        INftfiHub _hub
    ) external {
        IDirectLoanCoordinator loanCoordinator = IDirectLoanCoordinator(
            _hub.getContract(IDirectLoanBase(address(this)).LOAN_COORDINATOR())
        );

        address borrower;

        // scoped to aviod stack too deep
        {
            IDirectLoanCoordinator.Loan memory loanCoordinatorData = loanCoordinator.getLoanData(_loanId);
            uint256 smartNftId = loanCoordinatorData.smartNftId;
            borrower = IERC721(loanCoordinator.obligationReceiptToken()).ownerOf(smartNftId);
        }

        require(msg.sender == borrower, "Only borrower can airdrop");

        {
            IAirdropFlashLoan airdropFlashLoan = IAirdropFlashLoan(_hub.getContract(ContractKeys.AIRDROP_FLASH_LOAN));

            _transferNFT(_loan, address(this), address(airdropFlashLoan));

            airdropFlashLoan.pullAirdrop(
                _loan.nftCollateralContract,
                _loan.nftCollateralId,
                _loan.nftCollateralWrapper,
                _target,
                _data,
                _nftAirdrop,
                _nftAirdropId,
                _is1155,
                _nftAirdropAmount,
                borrower
            );
        }

        // revert if the collateral hasn't been transferred back before it ends
        require(
            INftWrapper(_loan.nftCollateralWrapper).isOwner(
                address(this),
                _loan.nftCollateralContract,
                _loan.nftCollateralId
            ),
            "Collateral should be returned"
        );

        emit AirdropPulledFlashloan(
            _loanId,
            borrower,
            _loan.nftCollateralId,
            _loan.nftCollateralContract,
            _target,
            _data
        );
    }

    function wrapCollateral(
        uint256 _loanId,
        LoanData.LoanTerms storage _loan,
        INftfiHub _hub
    ) external returns (address instance, uint256 receiverId) {
        IDirectLoanCoordinator loanCoordinator = IDirectLoanCoordinator(
            _hub.getContract(IDirectLoanBase(address(this)).LOAN_COORDINATOR())
        );
        // Fetch the current lender of the promissory note corresponding to this overdue loan.
        IDirectLoanCoordinator.Loan memory loanCoordinatorData = loanCoordinator.getLoanData(_loanId);
        uint256 smartNftId = loanCoordinatorData.smartNftId;

        address borrower = IERC721(loanCoordinator.obligationReceiptToken()).ownerOf(smartNftId);

        require(msg.sender == borrower, "Only borrower can wrapp");

        IAirdropReceiverFactory factory = IAirdropReceiverFactory(_hub.getContract(ContractKeys.AIRDROP_FACTORY));
        (instance, receiverId) = factory.createAirdropReceiver(address(this));

        // transfer collateral to airdrop receiver wrapper
        _transferNFTtoAirdropReceiver(_loan, instance, borrower);

        emit CollateralWrapped(
            _loanId,
            borrower,
            _loan.nftCollateralId,
            _loan.nftCollateralContract,
            receiverId,
            instance
        );

        // set the receiver as the new collateral
        _loan.nftCollateralContract = instance;
        _loan.nftCollateralId = receiverId;
    }

    /**
     * @dev Transfers several types of NFTs using a wrapper that knows how to handle each case.
     *
     * @param _loan -
     * @param _sender - Current owner of the NFT
     * @param _recipient - Recipient of the transfer
     */
    function _transferNFT(
        LoanData.LoanTerms memory _loan,
        address _sender,
        address _recipient
    ) internal {
        Address.functionDelegateCall(
            _loan.nftCollateralWrapper,
            abi.encodeWithSelector(
                INftWrapper(_loan.nftCollateralWrapper).transferNFT.selector,
                _sender,
                _recipient,
                _loan.nftCollateralContract,
                _loan.nftCollateralId
            ),
            "NFT not successfully transferred"
        );
    }

    /**
     * @dev Transfers several types of NFTs to an airdrop receiver with an airdrop beneficiary
     * address attached as supplementing data using a wrapper that knows how to handle each case.
     *
     * @param _loan -
     * @param _airdropReceiverInstance - Recipient of the transfer
     * @param _airdropBeneficiary - Beneficiary of the future airdops
     */
    function _transferNFTtoAirdropReceiver(
        LoanData.LoanTerms memory _loan,
        address _airdropReceiverInstance,
        address _airdropBeneficiary
    ) internal {
        Address.functionDelegateCall(
            _loan.nftCollateralWrapper,
            abi.encodeWithSelector(
                INftWrapper(_loan.nftCollateralWrapper).wrapAirdropReceiver.selector,
                _airdropReceiverInstance,
                _loan.nftCollateralContract,
                _loan.nftCollateralId,
                _airdropBeneficiary
            ),
            "NFT was not successfully migrated"
        );
    }
}

// SPDX-License-Identifier: MIT

import "./LoanData.sol";

pragma solidity 0.8.4;

interface IDirectLoanBase {
    function maximumLoanDuration() external view returns (uint256);

    function adminFeeInBasisPoints() external view returns (uint16);

    // solhint-disable-next-line func-name-mixedcase
    function LOAN_COORDINATOR() external view returns (bytes32);

    function loanIdToLoan(uint256)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            address,
            address,
            uint256,
            uint64,
            uint32,
            uint16,
            uint16
        );

    function loanRepaidOrLiquidated(uint256) external view returns (bool);

    function getWhetherNonceHasBeenUsedForUser(address _user, uint256 _nonce) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @title  LoanData
 * @author NFTfi
 * @notice A convenience contract containg the main Loan struct shared by Direct Loans types.
 */
abstract contract LoanData {
    /* ********** */
    /* DATA TYPES */
    /* ********** */

    /**
     * @notice The main Loan Terms struct. This data is saved upon loan creation.
     *
     * @param loanERC20Denomination - The address of the ERC20 contract of the currency being used as principal/interest
     * for this loan.
     * @param loanPrincipalAmount - The original sum of money transferred from lender to borrower at the beginning of
     * the loan, measured in loanERC20Denomination's smallest units.
     * @param maximumRepaymentAmount - The maximum amount of money that the borrower would be required to retrieve their
     * collateral, measured in the smallest units of the ERC20 currency used for the loan. The borrower will always have
     * to pay this amount to retrieve their collateral, regardless of whether they repay early.
     * @param nftCollateralContract - The address of the the NFT collateral contract.
     * @param nftCollateralWrapper - The NFTfi wrapper of the NFT collateral contract.
     * @param nftCollateralId - The ID within the NFTCollateralContract for the NFT being used as collateral for this
     * loan. The NFT is stored within this contract during the duration of the loan.
     * @param loanStartTime - The block.timestamp when the loan first began (measured in seconds).
     * @param loanDuration - The amount of time (measured in seconds) that can elapse before the lender can liquidate
     * the loan and seize the underlying collateral NFT.
     * @param loanInterestRateForDurationInBasisPoints - This is the interest rate (measured in basis points, e.g.
     * hundreths of a percent) for the loan, that must be repaid pro-rata by the borrower at the conclusion of the loan
     * or risk seizure of their nft collateral. Note if the type of the loan is fixed then this value  is not used and
     * is irrelevant so it should be set to 0.
     * @param loanAdminFeeInBasisPoints - The percent (measured in basis points) of the interest earned that will be
     * taken as a fee by the contract admins when the loan is repaid. The fee is stored in the loan struct to prevent an
     * attack where the contract admins could adjust the fee right before a loan is repaid, and take all of the interest
     * earned.
     */
    struct LoanTerms {
        address loanERC20Denomination;
        uint256 loanPrincipalAmount;
        uint256 maximumRepaymentAmount;
        address nftCollateralContract;
        address nftCollateralWrapper;
        uint256 nftCollateralId;
        uint64 loanStartTime;
        uint32 loanDuration;
        uint16 loanInterestRateForDurationInBasisPoints;
        uint16 loanAdminFeeInBasisPoints;
    }

    /**
     * @notice Some extra Loan's settings struct. This data is saved upon loan creation.
     * We need this to avoid stack too deep errors.
     *
     * @param revenueSharePartner - The address of the partner that will receive the revenue share.
     * @param revenueShareInBasisPoints - The percent (measured in basis points) of the admin fee amount that will be
     * taken as a revenue share for a t
     * @param referralFeeInBasisPoints - The percent (measured in basis points) of the loan principal amount that will
     * be taken as a fee to pay to the referrer, 0 if the lender is not paying referral fee.he partner, at the moment
     * the loan is begun.
     */
    struct LoanExtras {
        address revenueSharePartner;
        uint16 revenueShareInBasisPoints;
        uint16 referralFeeInBasisPoints;
    }

    /**
     * @notice The offer made by the lender. Used as parameter on both acceptOffer (initiated by the borrower) and
     * acceptListing (initiated by the lender).
     *
     * @param loanERC20Denomination - The address of the ERC20 contract of the currency being used as principal/interest
     * for this loan.
     * @param loanPrincipalAmount - The original sum of money transferred from lender to borrower at the beginning of
     * the loan, measured in loanERC20Denomination's smallest units.
     * @param maximumRepaymentAmount - The maximum amount of money that the borrower would be required to retrieve their
     *  collateral, measured in the smallest units of the ERC20 currency used for the loan. The borrower will always
     * have to pay this amount to retrieve their collateral, regardless of whether they repay early.
     * @param nftCollateralContract - The address of the ERC721 contract of the NFT collateral.
     * @param nftCollateralId - The ID within the NFTCollateralContract for the NFT being used as collateral for this
     * loan. The NFT is stored within this contract during the duration of the loan.
     * @param referrer - The address of the referrer who found the lender matching the listing, Zero address to signal
     * this there is no referrer.
     * @param loanDuration - The amount of time (measured in seconds) that can elapse before the lender can liquidate
     * the loan and seize the underlying collateral NFT.
     * @param loanAdminFeeInBasisPoints - The percent (measured in basis points) of the interest earned that will be
     * taken as a fee by the contract admins when the loan is repaid. The fee is stored in the loan struct to prevent an
     * attack where the contract admins could adjust the fee right before a loan is repaid, and take all of the interest
     * earned.
     */
    struct Offer {
        address loanERC20Denomination;
        uint256 loanPrincipalAmount;
        uint256 maximumRepaymentAmount;
        address nftCollateralContract;
        uint256 nftCollateralId;
        address referrer;
        uint32 loanDuration;
        uint16 loanAdminFeeInBasisPoints;
    }

    /**
     * @notice Signature related params. Used as parameter on both acceptOffer (containing borrower signature) and
     * acceptListing (containing lender signature).
     *
     * @param signer - The address of the signer. The borrower for `acceptOffer` the lender for `acceptListing`.
     * @param nonce - The nonce referred here is not the same as an Ethereum account's nonce.
     * We are referring instead to a nonce that is used by the lender or the borrower when they are first signing
     * off-chain NFTfi orders. These nonce can be any uint256 value that the user has not previously used to sign an
     * off-chain order. Each nonce can be used at most once per user within NFTfi, regardless of whether they are the
     * lender or the borrower in that situation. This serves two purposes:
     * - First, it prevents replay attacks where an attacker would submit a user's off-chain order more than once.
     * - Second, it allows a user to cancel an off-chain order by calling NFTfi.cancelLoanCommitmentBeforeLoanHasBegun()
     * , which marks the nonce as used and prevents any future loan from using the user's off-chain order that contains
     * that nonce.
     * @param expiry - Date when the signature expires
     * @param signature - The ECDSA signature of the borrower or the lender, obtained off-chain ahead of time, signing
     * the following combination of parameters:
     * - Borrower
     *   - ListingTerms.loanERC20Denomination,
     *   - ListingTerms.minLoanPrincipalAmount,
     *   - ListingTerms.maxLoanPrincipalAmount,
     *   - ListingTerms.nftCollateralContract,
     *   - ListingTerms.nftCollateralId,
     *   - ListingTerms.revenueSharePartner,
     *   - ListingTerms.minLoanDuration,
     *   - ListingTerms.maxLoanDuration,
     *   - ListingTerms.maxInterestRateForDurationInBasisPoints,
     *   - ListingTerms.referralFeeInBasisPoints,
     *   - Signature.signer,
     *   - Signature.nonce,
     *   - Signature.expiry,
     *   - address of the loan type contract
     *   - chainId
     * - Lender:
     *   - Offer.loanERC20Denomination
     *   - Offer.loanPrincipalAmount
     *   - Offer.maximumRepaymentAmount
     *   - Offer.nftCollateralContract
     *   - Offer.nftCollateralId
     *   - Offer.referrer
     *   - Offer.loanDuration
     *   - Offer.loanAdminFeeInBasisPoints
     *   - Signature.signer,
     *   - Signature.nonce,
     *   - Signature.expiry,
     *   - address of the loan type contract
     *   - chainId
     */
    struct Signature {
        address signer;
        uint256 nonce;
        uint256 expiry;
        bytes signature;
    }

    /**
     * @notice Some extra parameters that the borrower needs to set when accepting an offer.
     *
     * @param revenueSharePartner - The address of the partner that will receive the revenue share.
     * @param referralFeeInBasisPoints - The percent (measured in basis points) of the loan principal amount that will
     * be taken as a fee to pay to the referrer, 0 if the lender is not paying referral fee.
     */
    struct BorrowerSettings {
        address revenueSharePartner;
        uint16 referralFeeInBasisPoints;
    }

    /**
     * @notice Terms the borrower set off-chain and is willing to accept automatically when fulfiled by a lender's
     * offer.
     *
     * @param loanERC20Denomination - The address of the ERC20 contract of the currency being used as principal/interest
     * for this loan.
     * @param minLoanPrincipalAmount - The minumum sum of money transferred from lender to borrower at the beginning of
     * the loan, measured in loanERC20Denomination's smallest units.
     * @param maxLoanPrincipalAmount - The  sum of money transferred from lender to borrower at the beginning of
     * the loan, measured in loanERC20Denomination's smallest units.
     * @param maximumRepaymentAmount - The maximum amount of money that the borrower would be required to retrieve their
     * collateral, measured in the smallest units of the ERC20 currency used for the loan. The borrower will always have
     * to pay this amount to retrieve their collateral, regardless of whether they repay early.
     * @param nftCollateralContract - The address of the ERC721 contract of the NFT collateral.
     * @param nftCollateralId - The ID within the NFTCollateralContract for the NFT being used as collateral for this
     * loan. The NFT is stored within this contract during the duration of the loan.
     * @param revenueSharePartner - The address of the partner that will receive the revenue share.
     * @param minLoanDuration - The minumum amount of time (measured in seconds) that can elapse before the lender can
     * liquidate the loan and seize the underlying collateral NFT.
     * @param maxLoanDuration - The maximum amount of time (measured in seconds) that can elapse before the lender can
     * liquidate the loan and seize the underlying collateral NFT.
     * @param maxInterestRateForDurationInBasisPoints - This is maximum the interest rate (measured in basis points,
     * e.g. hundreths of a percent) for the loan.
     * @param referralFeeInBasisPoints - The percent (measured in basis points) of the loan principal amount that will
     * be taken as a fee to pay to the referrer, 0 if the lender is not paying referral fee.
     */
    struct ListingTerms {
        address loanERC20Denomination;
        uint256 minLoanPrincipalAmount;
        uint256 maxLoanPrincipalAmount;
        address nftCollateralContract;
        uint256 nftCollateralId;
        address revenueSharePartner;
        uint32 minLoanDuration;
        uint32 maxLoanDuration;
        uint16 maxInterestRateForDurationInBasisPoints;
        uint16 referralFeeInBasisPoints;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @title IDirectLoanCoordinator
 * @author NFTfi
 * @dev DirectLoanCoordinator interface.
 */
interface IDirectLoanCoordinator {
    enum StatusType {
        NOT_EXISTS,
        NEW,
        RESOLVED
    }

    /**
     * @notice This struct contains data related to a loan
     *
     * @param smartNftId - The id of both the promissory note and obligation receipt.
     * @param status - The status in which the loan currently is.
     * @param loanContract - Address of the LoanType contract that created the loan.
     */
    struct Loan {
        uint256 smartNftId;
        StatusType status;
        address loanContract;
    }

    function registerLoan(
        address _lender,
        address _borrower,
        bytes32 _loanType
    ) external returns (uint256);

    function resolveLoan(uint256 _loanId) external;

    function promissoryNoteToken() external view returns (address);

    function obligationReceiptToken() external view returns (address);

    function getLoanData(uint256 _loanId) external view returns (Loan memory);

    function isValidLoanId(uint256 _loanId, address _loanContract) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @title ContractKeys
 * @author NFTfi
 * @dev Common library for contract keys
 */
library ContractKeys {
    bytes32 public constant PERMITTED_ERC20S = bytes32("PERMITTED_ERC20S");
    bytes32 public constant PERMITTED_NFTS = bytes32("PERMITTED_NFTS");
    bytes32 public constant PERMITTED_PARTNERS = bytes32("PERMITTED_PARTNERS");
    bytes32 public constant NFT_TYPE_REGISTRY = bytes32("NFT_TYPE_REGISTRY");
    bytes32 public constant LOAN_REGISTRY = bytes32("LOAN_REGISTRY");
    bytes32 public constant PERMITTED_SNFT_RECEIVER = bytes32("PERMITTED_SNFT_RECEIVER");
    bytes32 public constant PERMITTED_BUNDLE_ERC20S = bytes32("PERMITTED_BUNDLE_ERC20S");
    bytes32 public constant PERMITTED_AIRDROPS = bytes32("PERMITTED_AIRDROPS");
    bytes32 public constant AIRDROP_RECEIVER = bytes32("AIRDROP_RECEIVER");
    bytes32 public constant AIRDROP_FACTORY = bytes32("AIRDROP_FACTORY");
    bytes32 public constant AIRDROP_FLASH_LOAN = bytes32("AIRDROP_FLASH_LOAN");
    bytes32 public constant NFTFI_BUNDLER = bytes32("NFTFI_BUNDLER");

    string public constant AIRDROP_WRAPPER_STRING = "AirdropWrapper";

    /**
     * @notice Returns the bytes32 representation of a string
     * @param _key the string key
     * @return id bytes32 representation
     */
    function getIdFromStringKey(string memory _key) external pure returns (bytes32 id) {
        require(bytes(_key).length <= 32, "invalid key");

        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := mload(add(_key, 32))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @title INftfiHub
 * @author NFTfi
 * @dev NftfiHub interface
 */
interface INftfiHub {
    function setContract(string calldata _contractKey, address _contractAddress) external;

    function getContract(bytes32 _contractKey) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IPermittedPartners {
    function getPartnerPermit(address _partner) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IPermittedERC20s {
    function getERC20Permit(address _erc20) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IAirdropFlashLoan {
    function pullAirdrop(
        address _nftCollateralContract,
        uint256 _nftCollateralId,
        address _nftWrapper,
        address _target,
        bytes calldata _data,
        address _nftAirdrop,
        uint256 _nftAirdropId,
        bool _is1155,
        uint256 _nftAirdropAmount,
        address _beneficiary
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @title INftTypeRegistry
 * @author NFTfi
 * @dev Interface for NFT Wrappers.
 */
interface INftWrapper {
    function transferNFT(
        address from,
        address to,
        address nftContract,
        uint256 tokenId
    ) external returns (bool);

    function isOwner(
        address owner,
        address nftContract,
        uint256 tokenId
    ) external view returns (bool);

    function wrapAirdropReceiver(
        address _recipient,
        address _nftContract,
        uint256 _nftId,
        address _beneficiary
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @title IAirdropReceiver
 * @author NFTfi
 * @dev
 */
interface IAirdropReceiverFactory {
    function createAirdropReceiver(address _to) external returns (address, uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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