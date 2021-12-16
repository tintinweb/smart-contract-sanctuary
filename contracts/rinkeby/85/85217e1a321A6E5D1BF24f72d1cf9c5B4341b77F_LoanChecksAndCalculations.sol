// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IDirectLoanBase.sol";
import "./LoanData.sol";
import "../../../interfaces/IDirectLoanCoordinator.sol";
import "../../../utils/ContractKeys.sol";
import "../../../interfaces/INftfiHub.sol";
import "../../../interfaces/IPermittedPartners.sol";
import "../../../interfaces/IPermittedERC20s.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title  LoanChecksAndCalculations
 * @author NFTfi
 * @notice Helper library for LoanBase
 */
library LoanChecksAndCalculations {
    uint16 private constant HUNDRED_PERCENT = 10000;

    /**
     * @dev Function that performs some validation checks before trying to repay a loan
     *
     * @param _loanId - The id of the loan being repaid
     */
    function payBackChecks(uint256 _loanId, INftfiHub _hub) external view {
        checkLoanIdValidity(_loanId, _hub);
        // Sanity check that payBackLoan() and liquidateOverdueLoan() have never been called on this loanId.
        // Depending on how the rest of the code turns out, this check may be unnecessary.
        require(!IDirectLoanBase(address(this)).loanRepaidOrLiquidated(_loanId), "Loan already repaid/liquidated");

        // Fetch loan details from storage, but store them in memory for the sake of saving gas.
        (, , , , , , uint64 loanStartTime, uint32 loanDuration, , ) = IDirectLoanBase(address(this)).loanIdToLoan(
            _loanId
        );

        // When a loan exceeds the loan term, it is expired. At this stage the Lender can call Liquidate Loan to resolve
        // the loan.
        require(block.timestamp <= (uint256(loanStartTime) + uint256(loanDuration)), "Loan is expired");
    }

    function checkLoanIdValidity(uint256 _loanId, INftfiHub _hub) public view {
        require(
            IDirectLoanCoordinator(_hub.getContract(IDirectLoanBase(address(this)).LOAN_COORDINATOR())).isValidLoanId(
                _loanId,
                address(this)
            ),
            "invalid loanId"
        );
    }

    /**
     * @dev Function that the partner is permitted and returns its shared percent.
     *
     * @param _revenueSharePartner - Partner's address
     *
     * @return The revenue share percent for the partner.
     */
    function getRevenueSharePercent(address _revenueSharePartner, INftfiHub _hub) external view returns (uint16) {
        // return soon if no partner is set to avoid a public call
        if (_revenueSharePartner == address(0)) {
            return 0;
        }

        uint16 revenueSharePercent = IPermittedPartners(_hub.getContract(ContractKeys.PERMITTED_PARTNERS))
        .getPartnerPermit(_revenueSharePartner);

        return revenueSharePercent;
    }

    /**
     * @dev Performs some validation checks over loan parameters
     *
     */
    function loanSanityChecks(
        LoanData.Offer memory _offer,
        address nftWrapper,
        INftfiHub _hub
    ) external view {
        require(
            IPermittedERC20s(_hub.getContract(ContractKeys.PERMITTED_ERC20S)).getERC20Permit(
                _offer.loanERC20Denomination
            ),
            "Currency denomination is not permitted"
        );
        require(nftWrapper != address(0), "NFT collateral contract is not permitted");
        require(
            uint256(_offer.loanDuration) <= IDirectLoanBase(address(this)).maximumLoanDuration(),
            "Loan duration exceeds maximum loan duration"
        );
        require(uint256(_offer.loanDuration) != 0, "Loan duration cannot be zero");
        require(
            _offer.loanAdminFeeInBasisPoints == IDirectLoanBase(address(this)).adminFeeInBasisPoints(),
            "The admin fee has changed since this order was signed."
        );
    }

    /**
     * @dev Function that performs some validation checks over loan parameters when accepting an offer
     *
     */
    function loanSanityChecksOffer(LoanData.Offer memory _offer) external pure {
        require(
            _offer.maximumRepaymentAmount >= _offer.loanPrincipalAmount,
            "Negative interest rate loans are not allowed."
        );
    }

    /**
     * @dev Performs some validation checks before trying to renegotiate a loan.
     * Needed to avoid stack too deep.
     *
     * @param _loan - The main Loan Terms struct.
     * @param _loanId - The unique identifier for the loan to be renegotiated
     * @param _newLoanDuration - The new amount of time (measured in seconds) that can elapse before the lender can
     * liquidate the loan and seize the underlying collateral NFT.
     * @param _newMaximumRepaymentAmount - The new maximum amount of money that the borrower would be required to
     * retrieve their collateral, measured in the smallest units of the ERC20 currency used for the loan. The
     * borrower will always have to pay this amount to retrieve their collateral, regardless of whether they repay
     * early.
     * @param _lenderNonce - The nonce referred to here is not the same as an Ethereum account's nonce. We are
     * referring instead to nonces that are used by both the lender and the borrower when they are first signing
     * off-chain NFTfi orders. These nonces can be any uint256 value that the user has not previously used to sign an
     * off-chain order. Each nonce can be used at most once per user within NFTfi, regardless of whether they are the
     * lender or the borrower in that situation. This serves two purposes:
     * - First, it prevents replay attacks where an attacker would submit a user's off-chain order more than once.
     * - Second, it allows a user to cancel an off-chain order by calling NFTfi.cancelLoanCommitmentBeforeLoanHasBegun()
     , which marks the nonce as used and prevents any future loan from using the user's off-chain order that contains
     * that nonce.
     * @return Borrower and Lender addresses
     */
    function renegotiationChecks(
        LoanData.LoanTerms memory _loan,
        uint256 _loanId,
        uint32 _newLoanDuration,
        uint256 _newMaximumRepaymentAmount,
        uint256 _lenderNonce,
        INftfiHub _hub
    ) external view returns (address, address) {
        checkLoanIdValidity(_loanId, _hub);
        IDirectLoanCoordinator loanCoordinator = IDirectLoanCoordinator(
            _hub.getContract(IDirectLoanBase(address(this)).LOAN_COORDINATOR())
        );
        uint256 smartNftId = loanCoordinator.getLoanData(_loanId).smartNftId;

        address borrower = IERC721(loanCoordinator.obligationReceiptToken()).ownerOf(smartNftId);

        require(msg.sender == borrower, "Only borrower can initiate");
        require(block.timestamp <= (uint256(_loan.loanStartTime) + _newLoanDuration), "New duration already expired");
        require(
            uint256(_newLoanDuration) <= IDirectLoanBase(address(this)).maximumLoanDuration(),
            "New duration exceeds maximum loan duration"
        );
        require(!IDirectLoanBase(address(this)).loanRepaidOrLiquidated(_loanId), "Loan already repaid/liquidated");
        require(
            _newMaximumRepaymentAmount >= _loan.loanPrincipalAmount,
            "Negative interest rate loans are not allowed."
        );

        // Fetch current owner of loan promissory note.
        address lender = IERC721(loanCoordinator.promissoryNoteToken()).ownerOf(smartNftId);

        require(
            !IDirectLoanBase(address(this)).getWhetherNonceHasBeenUsedForUser(lender, _lenderNonce),
            "Lender nonce invalid"
        );

        return (borrower, lender);
    }

    /**
     * @dev Performs some validation checks over loan parameters when accepting a listing
     *
     */
    function bindingTermsSanityChecks(LoanData.ListingTerms memory _listingTerms, LoanData.Offer memory _offer)
        external
        pure
    {
        // offer vs listing validations
        require(_offer.loanERC20Denomination == _listingTerms.loanERC20Denomination, "Invalid loanERC20Denomination");
        require(
            _offer.loanPrincipalAmount >= _listingTerms.minLoanPrincipalAmount &&
                _offer.loanPrincipalAmount <= _listingTerms.maxLoanPrincipalAmount,
            "Invalid loanPrincipalAmount"
        );
        uint256 maxRepaymentLimit = _offer.loanPrincipalAmount +
            (_offer.loanPrincipalAmount * _listingTerms.maxInterestRateForDurationInBasisPoints) /
            HUNDRED_PERCENT;
        require(_offer.maximumRepaymentAmount <= maxRepaymentLimit, "maxInterestRateForDurationInBasisPoints violated");

        require(
            _offer.loanDuration >= _listingTerms.minLoanDuration &&
                _offer.loanDuration <= _listingTerms.maxLoanDuration,
            "Invalid loanDuration"
        );
    }

    /**
     * @notice A convenience function computing the revenue share taken from the admin fee to transferr to the permitted
     * partner.
     *
     * @param _adminFee - The quantity of ERC20 currency (measured in smalled units of that ERC20 currency) that is due
     * as an admin fee.
     * @param _revenueShareInBasisPoints - The percent (measured in basis points) of the admin fee amount that will be
     * taken as a revenue share for a the partner, at the moment the loan is begun.
     *
     * @return The quantity of ERC20 currency (measured in smalled units of that ERC20 currency) that should be sent to
     * the `revenueSharePartner`.
     */
    function computeRevenueShare(uint256 _adminFee, uint256 _revenueShareInBasisPoints)
        external
        pure
        returns (uint256)
    {
        return (_adminFee * _revenueShareInBasisPoints) / HUNDRED_PERCENT;
    }

    /**
     * @notice A convenience function computing the adminFee taken from a specified quantity of interest.
     *
     * @param _interestDue - The amount of interest due, measured in the smallest quantity of the ERC20 currency being
     * used to pay the interest.
     * @param _adminFeeInBasisPoints - The percent (measured in basis points) of the interest earned that will be taken
     * as a fee by the contract admins when the loan is repaid. The fee is stored in the loan struct to prevent an
     * attack where the contract admins could adjust the fee right before a loan is repaid, and take all of the interest
     * earned.
     *
     * @return The quantity of ERC20 currency (measured in smalled units of that ERC20 currency) that is due as an admin
     * fee.
     */
    function computeAdminFee(uint256 _interestDue, uint256 _adminFeeInBasisPoints) external pure returns (uint256) {
        return (_interestDue * _adminFeeInBasisPoints) / HUNDRED_PERCENT;
    }

    /**
     * @notice A convenience function computing the referral fee taken from the loan principal amount to transferr to
     * the referrer.
     *
     * @param _loanPrincipalAmount - The original sum of money transferred from lender to borrower at the beginning of
     * the loan, measured in loanERC20Denomination's smallest units.
     * @param _referralFeeInBasisPoints - The percent (measured in basis points) of the loan principal amount that will
     * be taken as a fee to pay to the referrer, 0 if the lender is not paying referral fee.
     * @param _referrer - The address of the referrer who found the lender matching the listing, Zero address to signal
     * that there is no referrer.
     *
     * @return The quantity of ERC20 currency (measured in smalled units of that ERC20 currency) that should be sent to
     * the referrer.
     */
    function computeReferralFee(
        uint256 _loanPrincipalAmount,
        uint256 _referralFeeInBasisPoints,
        address _referrer
    ) external pure returns (uint256) {
        if (_referralFeeInBasisPoints == 0 || _referrer == address(0)) {
            return 0;
        }
        return (_loanPrincipalAmount * _referralFeeInBasisPoints) / HUNDRED_PERCENT;
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