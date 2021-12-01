// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./PawnNFTModel.sol";
import "./PawnNFTLib.sol";
import "./IPawnNFT.sol";
import "./ILoanNFT.sol";

// import "../reputation/IReputation.sol";
// import "./IPawnNFT.sol";
// import "../exchange/Exchange_NFT.sol";

contract PawnNFTContractV2 is PawnNFTModel, ILoanNFT {
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CollateralLib_NFT for Collateral_NFT;
    using OfferLib_NFT for Offer_NFT;
    /** ======================================= EVENT ================================== */

    event CollateralEvent_NFT(
        uint256 nftCollateralId,
        Collateral_NFT data,
        uint256 UID
    );

    //create offer & cancel
    event OfferEvent_NFT(
        uint256 offerId,
        uint256 nftCollateralId,
        Offer_NFT data,
        uint256 UID
    );

    //accept offer
    event LoanContractCreatedEvent_NFT(
        address fromAddress,
        uint256 contractId,
        Contract_NFT data,
        uint256 UID
    );

    //repayment
    event PaymentRequestEvent_NFT(uint256 contractId, PaymentRequest_NFT data);

    event RepaymentEvent_NFT(
        uint256 contractId,
        uint256 paidPenaltyAmount,
        uint256 paidInterestAmount,
        uint256 paidLoanAmount,
        uint256 paidPenaltyFeeAmount,
        uint256 paidInterestFeeAmount,
        uint256 prepaidAmount,
        uint256 UID
    );

    //liquidity & defaul
    event ContractLiquidedEvent_NFT(
        uint256 contractId,
        uint256 liquidedAmount,
        uint256 feeAmount,
        ContractLiquidedReasonType_NFT reasonType
    );

    event LoanContractCompletedEvent_NFT(uint256 contractId);

    event CancelOfferEvent_NFT(
        uint256 offerId,
        uint256 nftCollateralId,
        address offerOwner,
        uint256 UID
    );

    address abc;

    // Total collateral
    CountersUpgradeable.Counter public numberCollaterals;

    // Mapping collateralId => Collateral
    mapping(uint256 => Collateral_NFT) public collaterals;

    // Total offer
    CountersUpgradeable.Counter public numberOffers;

    // Mapping collateralId => list offer of collateral
    mapping(uint256 => CollateralOfferList_NFT) public collateralOffersMapping;

    // Total contract
    uint256 public numberContracts;

    // Mapping contractId => Contract
    mapping(uint256 => Contract_NFT) public contracts;

    // Mapping contract Id => array payment request
    mapping(uint256 => PaymentRequest_NFT[])
        public contractPaymentRequestMapping;

    /**
     * @dev create collateral function, collateral will be stored in this contract
     * @param _nftContract is address NFT token collection
     * @param _nftTokenId is token id of NFT
     * @param _loanAmount is amount collateral
     * @param _loanAsset is address of loan token
     * @param _nftTokenQuantity is quantity NFT token
     * @param _expectedDurationQty is expected duration
     * @param _durationType is expected duration type
     * @param _UID is UID pass create collateral to event collateral
     */

    function createCollateral(
        address _nftContract,
        uint256 _nftTokenId,
        uint256 _loanAmount,
        address _loanAsset,
        uint256 _nftTokenQuantity,
        uint256 _expectedDurationQty,
        LoanDurationType_NFT _durationType,
        uint256 _UID
    ) external whenNotPaused nonReentrant {
        /**
        TODO: Implementation

        Chú ý: Kiểm tra bên Physical NFT, so khớp số NFT quantity với _nftTokenQuantity
        Chỉ cho phép input <= amount của NFT
        */

        // Check white list nft contract

        // require(
        //     HubInterface(abc).PawnNFTConfig.whitelistedCollateral[
        //         _nftContract
        //     ] == 1,
        //     "0"
        // );

        require(
            HubInterface(hubContract).getWhitelistCollateral_NFT(
                _nftContract
            ) == 1,
            "0"
        );
        //   require(whitelistCollateral[_nftContract] == 1, "0");

        // Check loan amount
        require(_loanAmount > 0 && _expectedDurationQty > 0, "1");

        // Check loan asset
        require(_loanAsset != address(0), "2");

        // Create Collateral Id
        uint256 collateralId = numberCollaterals.current();

        // Transfer token
        PawnNFTLib.safeTranferNFTToken(
            _nftContract,
            msg.sender,
            address(this),
            _nftTokenId,
            _nftTokenQuantity
        );

        // Create collateral
        Collateral_NFT storage _collateral = collaterals[collateralId];

        _collateral.create(
            _nftContract,
            _nftTokenId,
            _loanAmount,
            _loanAsset,
            _nftTokenQuantity,
            _expectedDurationQty,
            _durationType
        );

        // Update number colaterals
        numberCollaterals.increment();

        emit CollateralEvent_NFT(collateralId, collaterals[collateralId], _UID);

        // Adjust reputation score
        // reputation.adjustReputationScore(
        //     msg.sender,
        //     IReputation.ReasonType.BR_CREATE_COLLATERAL
        // );
        IReputation(getReputation()).adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.BR_CREATE_COLLATERAL
        );
    }

    function withdrawCollateral(uint256 _nftCollateralId, uint256 _UID)
        external
        whenNotPaused
    {
        Collateral_NFT storage _collateral = collaterals[_nftCollateralId];

        // Check owner collateral
        require(
            _collateral.owner == msg.sender &&
                _collateral.status == CollateralStatus_NFT.OPEN,
            "0"
        );

        // Return NFT token to owner
        PawnNFTLib.safeTranferNFTToken(
            _collateral.nftContract,
            address(this),
            _collateral.owner,
            _collateral.nftTokenId,
            _collateral.nftTokenQuantity
        );

        // Remove relation of collateral and offers
        CollateralOfferList_NFT
            storage collateralOfferList = collateralOffersMapping[
                _nftCollateralId
            ];
        if (collateralOfferList.isInit == true) {
            for (
                uint256 i = 0;
                i < collateralOfferList.offerIdList.length;
                i++
            ) {
                uint256 offerId = collateralOfferList.offerIdList[i];
                Offer_NFT storage offer = collateralOfferList.offerMapping[
                    offerId
                ];
                emit CancelOfferEvent_NFT(
                    offerId,
                    _nftCollateralId,
                    offer.owner,
                    _UID
                );
            }
            delete collateralOffersMapping[_nftCollateralId];
        }

        // Update collateral status
        _collateral.status = CollateralStatus_NFT.CANCEL;

        emit CollateralEvent_NFT(_nftCollateralId, _collateral, _UID);

        delete collaterals[_nftCollateralId];

        // Adjust reputation score
        // reputation.adjustReputationScore(
        //     msg.sender,
        //     IReputation.ReasonType.BR_CANCEL_COLLATERAL
        // );
        IReputation(getReputation()).adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.BR_CANCEL_COLLATERAL
        );
    }

    /**
     * @dev create offer to collateral
     * @param _nftCollateralId is id collateral
     * @param _repaymentAsset is address token repayment
     * @param _loanToValue is LTV token of loan
     * @param _loanAmount is amount token of loan
     * @param _interest is interest of loan
     * @param _duration is duration of loan
     * @param _liquidityThreshold is liquidity threshold of loan
     * @param _loanDurationType is duration type of loan
     * @param _repaymentCycleType is repayment type of loan
     */
    function createOffer(
        uint256 _nftCollateralId,
        address _repaymentAsset,
        uint256 _loanToValue,
        uint256 _loanAmount,
        uint256 _interest,
        uint256 _duration,
        uint256 _liquidityThreshold,
        LoanDurationType_NFT _loanDurationType,
        LoanDurationType_NFT _repaymentCycleType,
        uint256 _UID
    ) external whenNotPaused {
        // Get collateral
        Collateral_NFT storage _collateral = collaterals[_nftCollateralId];

        // Check owner collateral
        require(
            _collateral.owner != msg.sender &&
                _collateral.status == CollateralStatus_NFT.OPEN,
            "0"
        ); // You can not offer.

        // Check approve
        require(
            IERC20Upgradeable(_collateral.loanAsset).allowance(
                msg.sender,
                address(this)
            ) >= _loanAmount,
            "1"
        ); // You not approve.

        // Check repayment asset
        require(_repaymentAsset != address(0), "2"); // Address repayment asset must be different address(0).

        // Check loan amount
        require(
            _loanToValue > 0 &&
                _loanAmount > 0 &&
                _interest > 0 &&
                _liquidityThreshold > _loanToValue,
            "3"
        ); // Loan to value must be grean that 0.

        // Gennerate Offer Id
        uint256 offerId = numberOffers.current();

        // Get offers of collateral
        CollateralOfferList_NFT
            storage _collateralOfferList = collateralOffersMapping[
                _nftCollateralId
            ];

        if (!_collateralOfferList.isInit) {
            _collateralOfferList.isInit = true;
        }

        Offer_NFT storage _offer = _collateralOfferList.offerMapping[offerId];

        _offer.create(
            _repaymentAsset,
            _loanToValue,
            _loanAmount,
            _interest,
            _duration,
            _liquidityThreshold,
            _loanDurationType,
            _repaymentCycleType
        );

        _collateralOfferList.offerIdList.push(offerId);

        _collateralOfferList.isInit = true;

        // Update number offer
        numberOffers.increment();

        emit OfferEvent_NFT(
            offerId,
            _nftCollateralId,
            _collateralOfferList.offerMapping[offerId],
            _UID
        );

        // Adjust reputation score
        // reputation.adjustReputationScore(
        //     msg.sender,
        //     IReputation.ReasonType.LD_CREATE_OFFER
        // );

        IReputation(getReputation()).adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.LD_CREATE_OFFER
        );
    }

    function cancelOffer(
        uint256 _offerId,
        uint256 _nftCollateralId,
        uint256 _UID
    ) external whenNotPaused {
        // Get offer
        CollateralOfferList_NFT
            storage _collateralOfferList = collateralOffersMapping[
                _nftCollateralId
            ];

        // Check Offer Collater isnit
        require(_collateralOfferList.isInit == true, "0");

        // Get offer
        Offer_NFT storage _offer = _collateralOfferList.offerMapping[_offerId];

        address offerOwner = _offer.owner;

        _offer.cancel(
            _offerId,
            collaterals[_nftCollateralId].owner,
            _collateralOfferList
        );

        //reject Offer
        if (msg.sender == collaterals[_nftCollateralId].owner) {
            emit CancelOfferEvent_NFT(
                _offerId,
                _nftCollateralId,
                offerOwner,
                _UID
            );
        }

        // cancel offer
        if (msg.sender == offerOwner) {
            emit CancelOfferEvent_NFT(
                _offerId,
                _nftCollateralId,
                msg.sender,
                _UID
            );

            // Adjust reputation score
            // reputation.adjustReputationScore(
            //     msg.sender,
            //     IReputation.ReasonType.LD_CANCEL_OFFER
            // );
            IReputation(getReputation()).adjustReputationScore(
                msg.sender,
                IReputation.ReasonType.LD_CANCEL_OFFER
            );
        }
    }

    function acceptOffer(
        uint256 _nftCollateralId,
        uint256 _offerId,
        uint256 _UID
    ) external whenNotPaused {
        Collateral_NFT storage collateral = collaterals[_nftCollateralId];
        // Check owner of collateral
        require(msg.sender == collateral.owner, "0");
        // Check for collateralNFT status is OPEN
        require(collateral.status == CollateralStatus_NFT.OPEN, "1");

        CollateralOfferList_NFT
            storage collateralOfferList = collateralOffersMapping[
                _nftCollateralId
            ];
        require(collateralOfferList.isInit == true, "2");
        // Check for offer status is PENDING
        Offer_NFT storage offer = collateralOfferList.offerMapping[_offerId];

        require(offer.status == OfferStatus_NFT.PENDING, "3");

        // uint256 exchangeRate = exchange.exchangeRateOfOffer_NFT(
        //     collateral.loanAsset,
        //     offer.repaymentAsset
        // );
        uint256 exchangeRate = Exchange(getExchange()).exchangeRateOfOffer_NFT(
            collateral.loanAsset,
            offer.repaymentAsset
        );

        ContractRawData_NFT memory contractData = ContractRawData_NFT(
            _nftCollateralId,
            collateral,
            _offerId,
            offer.loanAmount,
            offer.owner,
            offer.repaymentAsset,
            offer.interest,
            offer.loanDurationType,
            offer.liquidityThreshold,
            exchangeRate
        );

        //   LoanContract_NFT.createContract(contractData, _UID);
        IPawnNFT(getLoanContractNFT()).createContract(contractData, _UID);
        // uint256 contractId = createContract(
        //     _nftCollateralId,
        //     collateral,
        //     _offerId,
        //     offer.loanAmount,
        //     offer.owner,
        //     offer.repaymentAsset,
        //     offer.interest,
        //     offer.loanDurationType,
        //     offer.liquidityThreshold
        // );
        // Contract_NFT storage newContract = contracts[contractId];
        // Change status of offer and collateral
        offer.status = OfferStatus_NFT.ACCEPTED;
        collateral.status = CollateralStatus_NFT.DOING;

        // Cancel other offer sent to this collateral
        for (uint256 i = 0; i < collateralOfferList.offerIdList.length; i++) {
            uint256 thisOfferId = collateralOfferList.offerIdList[i];
            if (thisOfferId != _offerId) {
                //Offer storage thisOffer = collateralOfferList.offerMapping[thisOfferId];
                emit CancelOfferEvent_NFT(
                    thisOfferId,
                    _nftCollateralId,
                    offer.owner,
                    _UID
                );
                delete collateralOfferList.offerMapping[thisOfferId];
            }
        }
        delete collateralOfferList.offerIdList;
        collateralOfferList.offerIdList.push(_offerId);

        // Transfer loan asset to collateral owner
        PawnNFTLib.safeTransfer(
            collateral.loanAsset,
            offer.owner,
            collateral.owner,
            offer.loanAmount
        );

        PawnNFTLib.safeTranferNFTToken(
            collateral.nftContract,
            address(this),
            address(getLoanContractNFT()),
            collateral.nftTokenId,
            collateral.nftTokenQuantity
        );

        // Adjust reputation score
        // reputation.adjustReputationScore(
        //     msg.sender,
        //     IReputation.ReasonType.BR_ACCEPT_OFFER
        // );
        // reputation.adjustReputationScore(
        //     offer.owner,
        //     IReputation.ReasonType.LD_ACCEPT_OFFER
        // );

        IReputation(getReputation()).adjustReputationScore(
            msg.sender,
            IReputation.ReasonType.BR_ACCEPT_OFFER
        );

        IReputation(getReputation()).adjustReputationScore(
            offer.owner,
            IReputation.ReasonType.LD_ACCEPT_OFFER
        );
    }

    function _validateCollateral(uint256 _collateralId)
        private
        view
        returns (Collateral_NFT storage collateral)
    {
        collateral = collaterals[_collateralId];
        require(collateral.status == CollateralStatus_NFT.DOING, "1"); // invalid collateral
    }

    function updateCollateralStatus(
        uint256 _collateralId,
        CollateralStatus_NFT _status
    ) external override whenNotPaused {
        _isValidCaller();
        Collateral_NFT storage collateral = _validateCollateral(_collateralId);

        collateral.status = _status;
    }

    function _isValidCaller() private view {
        require(
            msg.sender == getLoanContractNFT() ||
                IAccessControlUpgradeable(hubContract).hasRole(
                    HubRoleLib.OPERATOR_ROLE,
                    msg.sender
                ) ||
                IAccessControlUpgradeable(hubContract).hasRole(
                    HubRoleLib.DEFAULT_ADMIN_ROLE,
                    msg.sender
                ),
            "0"
        ); // caller not allowed
    }

    /** ================================ ACCEPT OFFER ============================= */
    /**
 

    /** ==================== Loan Contract functions & states ==================== */
    // IPawnNFT public LoanContract_NFT;

    // function setPawnLoanContract(address _pawnLoanAddress)
    //     external
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     LoanContract_NFT = IPawnNFT(_pawnLoanAddress);
    // }
    /** ==== Reputation =======*/

    function signature() public view override returns (bytes4) {
        return type(ILoanNFT).interfaceId;
    }

    function RegistrywithHubContract() external {
        HubInterface(hubContract).registerContract(signature(), address(this));
    }

    function getReputation() internal view returns (address) {
        return
            HubInterface(hubContract).getContractAddress(
                type(IReputation).interfaceId
            );
    }

    /**=== Exchange======= */
    function getExchange() internal view returns (address) {
        return
            HubInterface(hubContract).getContractAddress(
                type(IExchange).interfaceId
            );
    }

    /**============get Loan Contract ================ */

    function getLoanContractNFT() internal view returns (address) {
        return
            HubInterface(hubContract).getContractAddress(
                type(IPawnNFT).interfaceId
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
//import "../access/DFY-AccessControl.sol";
import "../nft/IDFY_Physical_NFTs.sol";
import "../evaluation/EvaluationContract.sol";
import "../evaluation/IBEP20.sol";
import "../reputation/IReputation.sol";
import "../pawn-nft-v2/PawnNFTLib.sol";
import "../exchange/Exchange.sol";
import "../hub/Hub.sol";
import "../hub/HubInterface.sol";
import "../hub/HubLib.sol";
import "../exchange/IExchange.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract PawnNFTModel is
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC165Upgradeable
{
    // AssetEvaluation assetEvaluation;

    // mapping(address => uint256) public whitelistCollateral;
    // address public feeWallet;
    // uint256 public penaltyRate;
    // uint256 public systemFeeRate;
    // uint256 public lateThreshold;
    // uint256 public prepaidFeeRate;

    // uint256 public ZOOM;

    // address public admin;
    // address public operator;

    // DFY_Physical_NFTs dfy_physical_nfts;
    // AssetEvaluation assetEvaluation;

    function initialize(address _hubContract) public initializer {
        __Pausable_init();
        __UUPSUpgradeable_init();
        hubContract = _hubContract;

        // admin = address(msg.sender);
        // ZOOM = _zoom;
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // function setOperator(address _newOperator)
    //     external
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     // operator = _newOperator;
    //     operator = _newOperator;
    //     grantRole(OPERATOR_ROLE, _newOperator);
    // }

    // function setFeeWallet(address _newFeeWallet)
    //     external
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     feeWallet = _newFeeWallet;
    // }

    // function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    //     _pause();
    // }

    // function unPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    //     _unpause();
    // }

    // /**
    //  * @dev set fee for each token
    //  * @param _feeRate is percentage of tokens to pay for the transaction
    //  */
    // function setSystemFeeRate(uint256 _feeRate)
    //     external
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     systemFeeRate = _feeRate;
    // }

    // /**
    //  * @dev set fee for each token
    //  * @param _feeRate is percentage of tokens to pay for the penalty
    //  */
    // function setPenaltyRate(uint256 _feeRate)
    //     external
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     penaltyRate = _feeRate;
    // }

    // /**
    //  * @dev set fee for each token
    //  * @param _threshold is number of time allowed for late repayment
    //  */
    // function setLateThreshold(uint256 _threshold)
    //     external
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     lateThreshold = _threshold;
    // }

    // function setPrepaidFeeRate(uint256 _feeRate)
    //     external
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     prepaidFeeRate = _feeRate;
    // }

    // function setWhitelistCollateral(address _token, uint256 _status)
    //     external
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     whitelistCollateral[_token] = _status;
    // }

    function emergencyWithdraw(address _token) external whenPaused onlyAdmin {
        PawnNFTLib.safeTransfer(
            _token,
            address(this),
            msg.sender,
            PawnNFTLib.calculateAmount(_token, address(this))
        );
    }

    // /** ===================================== REPUTATION FUNCTIONS & STATES ===================================== */

    // IReputation public reputation;

    // function setReputationContract(address _reputationAddress)
    //     external
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     reputation = IReputation(_reputationAddress);
    // }

    // /**==========================   ExchangeRate   ========================= */
    // Exchange public exchange;

    // function setExchangeRate(address _exchange)
    //     external
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     exchange = Exchange(_exchange);
    // }

    address hubContract;

    function setContractHub(address _contractHubAddress) external onlyAdmin {
        hubContract = _contractHubAddress;
    }

    modifier onlyAdmin() {
        // (, , address _admin, ) = HubInterface(hubContract).getSystemConfig();
        // require(_admin == msg.sender, "is not admin");
        require(
            IAccessControlUpgradeable(hubContract).hasRole(
                HubRoleLib.DEFAULT_ADMIN_ROLE,
                msg.sender
            )
        );

        _;
    }

    modifier onlyOperator() {
        // (, , , address _operator) = HubInterface(hubContract).getSystemConfig();
        // require(_operator == msg.sender, "is not operator");
        require(
            IAccessControlUpgradeable(hubContract).hasRole(
                HubRoleLib.OPERATOR_ROLE,
                msg.sender
            )
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/** ==================================Collateral============================ */

// Enum
enum LoanDurationType_NFT {
    WEEK,
    MONTH
}
enum CollateralStatus_NFT {
    OPEN,
    DOING,
    COMPLETED,
    CANCEL
}
enum OfferStatus_NFT {
    PENDING,
    ACCEPTED,
    COMPLETED,
    CANCEL
}
enum ContractStatus_NFT {
    ACTIVE,
    COMPLETED,
    DEFAULT
}
enum PaymentRequestStatusEnum_NFT {
    ACTIVE,
    LATE,
    COMPLETE,
    DEFAULT
}
enum PaymentRequestTypeEnum_NFT {
    INTEREST,
    OVERDUE,
    LOAN
}
enum ContractLiquidedReasonType_NFT {
    LATE,
    RISK,
    UNPAID
}

struct Collateral_NFT {
    address owner;
    address nftContract;
    uint256 nftTokenId;
    uint256 loanAmount;
    address loanAsset;
    uint256 nftTokenQuantity;
    uint256 expectedDurationQty;
    LoanDurationType_NFT durationType;
    CollateralStatus_NFT status;
}

/** =========================================OFFER==================================== */

struct CollateralOfferList_NFT {
    //offerId => Offer
    mapping(uint256 => Offer_NFT) offerMapping;
    uint256[] offerIdList;
    bool isInit;
}

struct Offer_NFT {
    address owner;
    address repaymentAsset;
    uint256 loanToValue;
    uint256 loanAmount;
    uint256 interest;
    uint256 duration;
    OfferStatus_NFT status;
    LoanDurationType_NFT loanDurationType;
    LoanDurationType_NFT repaymentCycleType;
    uint256 liquidityThreshold;
}

/** ==========================================Contract==================================== */
struct ContractTerms_NFT {
    address borrower;
    address lender;
    uint256 nftTokenId;
    address nftCollateralAsset;
    uint256 nftCollateralAmount;
    address loanAsset;
    uint256 loanAmount;
    address repaymentAsset;
    uint256 interest;
    LoanDurationType_NFT repaymentCycleType;
    uint256 liquidityThreshold;
    uint256 contractStartDate;
    uint256 contractEndDate;
    uint256 lateThreshold;
    uint256 systemFeeRate;
    uint256 penaltyRate;
    uint256 prepaidFeeRate;
}

struct Contract_NFT {
    uint256 nftCollateralId;
    uint256 offerId;
    ContractTerms_NFT terms;
    ContractStatus_NFT status;
    uint8 lateCount;
}

/**====================================REPAYMENT======================= */
struct PaymentRequest_NFT {
    uint256 requestId;
    PaymentRequestTypeEnum_NFT paymentRequestType;
    uint256 remainingLoan;
    uint256 penalty;
    uint256 interest;
    uint256 remainingPenalty;
    uint256 remainingInterest;
    uint256 dueDateTimestamp;
    bool chargePrepaidFee;
    PaymentRequestStatusEnum_NFT status;
}

struct ContractRawData_NFT {
    uint256 _nftCollateralId;
    Collateral_NFT _collateral;
    uint256 _offerId;
    uint256 _loanAmount;
    address _lender;
    address _repaymentAsset;
    uint256 _interest;
    LoanDurationType_NFT _repaymentCycleType;
    uint256 _liquidityThreshold;
    uint256 exchangeRate;
}

struct ContractLiquidationData_NFT {
    uint256 contractId;
    uint256 tokenEvaluationExchangeRate;
    uint256 loanExchangeRate;
    uint256 repaymentExchangeRate;
    uint256 rateUpdateTime;
    ContractLiquidedReasonType_NFT reasonType;
}

struct RepaymentEventData_NFT {
    uint256 contractId;
    uint256 paidPenaltyAmount;
    uint256 paidInterestAmount;
    uint256 paidLoanAmount;
    uint256 paidPenaltyFeeAmount;
    uint256 paidInterestFeeAmount;
    uint256 prepaidAmount;
    uint256 requestId;
    uint256 UID;
}

library PawnNFTLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev safe transfer BNB or ERC20
     * @param  asset is address of the cryptocurrency to be transferred
     * @param  from is the address of the transferor
     * @param  to is the address of the receiver
     * @param  amount is transfer amount
     */
    function safeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (asset == address(0)) {
            require(from.balance >= amount, "not-enough-balance");
            // Handle BNB
            if (to == address(this)) {
                // Send to this contract
            } else if (from == address(this)) {
                // Send from this contract
                (bool success, ) = to.call{value: amount}("");
                require(success, "fail-transfer-bnb");
            } else {
                // Send from other address to another address
                require(false, "not-allow-transfer");
            }
        } else {
            // Handle ERC20
            uint256 prebalance = IERC20Upgradeable(asset).balanceOf(to);
            require(
                IERC20Upgradeable(asset).balanceOf(from) >= amount,
                "not-enough-balance"
            );
            if (from == address(this)) {
                // transfer direct to to
                IERC20Upgradeable(asset).safeTransfer(to, amount);
            } else {
                require(
                    IERC20Upgradeable(asset).allowance(from, address(this)) >=
                        amount,
                    "not-enough-allowance"
                );
                IERC20Upgradeable(asset).safeTransferFrom(from, to, amount);
            }
            require(
                IERC20Upgradeable(asset).balanceOf(to) - amount == prebalance,
                "not-transfer-enough"
            );
        }
    }

    function safeTranferNFTToken(
        address _nftToken,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) internal {
        // check address token
        require(
            _nftToken != address(0),
            "Address token must be different address(0)."
        );

        // check address from
        require(
            _from != address(0),
            "Address from must be different address(0)."
        );

        // check address from
        require(_to != address(0), "Address to must be different address(0).");

        // Check amount token
        //        require(_amount > 0, "Amount must be grean than 0.");

        // Check balance of from,
        require(
            IERC721(_nftToken).balanceOf(_from) >= _amount,
            "Your balance not enough."
        );

        // Transfer token
        IERC721(_nftToken).safeTransferFrom(_from, _to, _id, "");
    }

    /**
     * @dev Calculate the duration of the contract
     * @param  durationType is loan duration type of contract (WEEK/MONTH)
     * @param  duration is duration of contract
     */
    function calculateContractDuration(
        LoanDurationType_NFT durationType,
        uint256 duration
    ) internal pure returns (uint256 inSeconds) {
        if (durationType == LoanDurationType_NFT.WEEK) {
            // inSeconds = 7 * 24 * 3600 * duration;
            inSeconds = 600 * duration; //test
        } else {
            // inSeconds = 30 * 24 * 3600 * duration;
            inSeconds = 900 * duration; // test
        }
    }

    function isPrepaidChargeRequired(
        LoanDurationType_NFT durationType,
        uint256 startDate,
        uint256 endDate
    ) internal pure returns (bool) {
        uint256 week = 600;
        uint256 month = 900;

        if (durationType == LoanDurationType_NFT.WEEK) {
            // if loan contract only lasts one week
            if ((endDate - startDate) <= week) {
                return false;
            } else {
                return true;
            }
        } else {
            // if loan contract only lasts one month
            if ((endDate - startDate) <= month) {
                return false;
            } else {
                return true;
            }
        }
    }

    function calculatedueDateTimestampInterest(
        LoanDurationType_NFT durationType
    ) internal pure returns (uint256 duedateTimestampInterest) {
        if (durationType == LoanDurationType_NFT.WEEK) {
            duedateTimestampInterest = 180;
        } else {
            duedateTimestampInterest = 300;
        }
    }

    function calculatedueDateTimestampPenalty(LoanDurationType_NFT durationType)
        internal
        pure
        returns (uint256 duedateTimestampInterest)
    {
        if (durationType == LoanDurationType_NFT.WEEK) {
            duedateTimestampInterest = 600 - 180;
        } else {
            duedateTimestampInterest = 900 - 300;
        }
    }

    /**
     * @dev Calculate balance of wallet address
     * @param  _token is address of token
     * @param  from is address wallet
     */
    function calculateAmount(address _token, address from)
        internal
        view
        returns (uint256 _amount)
    {
        if (_token == address(0)) {
            // BNB
            _amount = from.balance;
        } else {
            // ERC20
            _amount = IERC20Upgradeable(_token).balanceOf(from);
        }
    }

    /**
     * @dev Calculate fee of system
     * @param  amount amount charged to the system
     * @param  feeRate is system fee rate
     */
    function calculateSystemFee(
        uint256 amount,
        uint256 feeRate,
        uint256 zoom
    ) internal pure returns (uint256 feeAmount) {
        feeAmount = (amount * feeRate) / (zoom * 100);
    }
}

library CollateralLib_NFT {
    function create(
        Collateral_NFT storage self,
        address _nftContract,
        uint256 _nftTokenId,
        uint256 _loanAmount,
        address _loanAsset,
        uint256 _nftTokenQuantity,
        uint256 _expectedDurationQty,
        LoanDurationType_NFT _durationType
    ) internal {
        self.owner = msg.sender;
        self.nftContract = _nftContract;
        self.nftTokenId = _nftTokenId;
        self.loanAmount = _loanAmount;
        self.loanAsset = _loanAsset;
        self.nftTokenQuantity = _nftTokenQuantity;
        self.expectedDurationQty = _expectedDurationQty;
        self.durationType = _durationType;
        self.status = CollateralStatus_NFT.OPEN;
    }
}

library OfferLib_NFT {
    function create(
        Offer_NFT storage self,
        address _repaymentAsset,
        uint256 _loanToValue,
        uint256 _loanAmount,
        uint256 _interest,
        uint256 _duration,
        uint256 _liquidityThreshold,
        LoanDurationType_NFT _loanDurationType,
        LoanDurationType_NFT _repaymentCycleType
    ) internal {
        self.owner = msg.sender;
        self.repaymentAsset = _repaymentAsset;
        self.loanToValue = _loanToValue;
        self.loanAmount = _loanAmount;
        self.interest = _interest;
        self.duration = _duration;
        self.status = OfferStatus_NFT.PENDING;
        self.loanDurationType = LoanDurationType_NFT(_loanDurationType);
        self.repaymentCycleType = LoanDurationType_NFT(_repaymentCycleType);
        self.liquidityThreshold = _liquidityThreshold;
    }

    function cancel(
        Offer_NFT storage self,
        uint256 _id,
        address _collateralOwner,
        CollateralOfferList_NFT storage _collateralOfferList
    ) internal {
        require(_collateralOfferList.isInit == true, "1"); // offer-col
        require(
            self.owner == msg.sender || _collateralOwner == msg.sender,
            "2"
        ); // owner
        require(self.status == OfferStatus_NFT.PENDING, "3"); // offer

        delete _collateralOfferList.offerMapping[_id];
        for (uint256 i = 0; i < _collateralOfferList.offerIdList.length; i++) {
            if (_collateralOfferList.offerIdList[i] == _id) {
                _collateralOfferList.offerIdList[i] = _collateralOfferList
                    .offerIdList[_collateralOfferList.offerIdList.length - 1];
                break;
            }
        }
        delete _collateralOfferList.offerIdList[
            _collateralOfferList.offerIdList.length - 1
        ];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./PawnNFTLib.sol";
import "../../base/BaseInterface.sol";

interface IPawnNFT is BaseInterface {
    function createContract(
        ContractRawData_NFT memory _contractData,
        uint256 _UID
    ) external returns (uint256 _idx);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./PawnNFTLib.sol";
import "../../base/BaseInterface.sol";

interface ILoanNFT is BaseInterface {
    function updateCollateralStatus(
        uint256 _collateralId,
        CollateralStatus_NFT _status
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDFY_Physical_NFTs {
    
    struct NFTEvaluation{
        address evaluationContract;
        uint256 evaluationId;
    }

    function mint(
        address _assetOwner, 
        address _evaluator, 
        uint256 _evaluatontId, 
        uint256 _amount, 
        string memory _cid, 
        bytes memory _data
    ) 
        external
        returns (uint256 tokenId);

    function getEvaluationOfToken(uint256 _tokenId) 
        external 
        returns (address evaluationAddress, uint256 evaluationId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../access/DFY-AccessControl.sol";
import "../nft/IDFY_Physical_NFTs.sol";
import "./IBEP20.sol";

contract AssetEvaluation is
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC1155HolderUpgradeable,
    PausableUpgradeable,
    DFYAccessControl
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    // Total asset
    CountersUpgradeable.Counter public totalAssets;

    // DFY Token;
    IBEP20 public ibepDFY;

    // NFT Token;
    IDFY_Physical_NFTs public dfy_physical_nfts;

    // Address admin
    address private addressAdmin;

    // Assuming _assetBaseUri = "https://ipfs.io/ipfs"
    string private _assetBaseUri;

    // Mapping list asset
    // AssetId => Asset
    mapping(uint256 => Asset) public assetList;

    // Mapping from creator to asset
    // Creator => listAssetId
    mapping(address => uint256[]) public assetListByCreator;

    // Mapping from creator address to assetId in his/her possession
    // Creator => (assetId => bool)
    mapping(address => mapping(uint256 => bool)) private _assetsOfCreator;

    // Total evaluation
    CountersUpgradeable.Counter public totalEvaluation;

    // Mapping list evaluation
    // EvaluationId => evaluation
    mapping(uint256 => Evaluation) public evaluationList;

    // Mapping from asset to list evaluation
    // AssetId => listEvaluationId
    mapping(uint256 => uint256[]) public evaluationByAsset;

    // Mapping from evaluator to evaluation
    // Evaluator => listEvaluation
    mapping(address => uint256[]) public evaluationListByEvaluator;

    // Mapping tokenId to asset
    // TokenId => asset
    mapping(uint256 => Asset) public tokenIdByAsset;

    // Mapping tokenId to evaluation
    // TokenId => evaluation
    mapping(uint256 => Evaluation) public tokenIdByEvaluation; // Should be changed to Evaluation by tokenId

    // Mintting NFT fee
    uint256 public _mintingNFTFee;

    function initialize(
        string memory _uri,
        address _dfy1155_physical_nft_address,
        address _ibep20_DFY_address
    ) public initializer {
        __ERC1155Holder_init();
        __DFYAccessControl_init();
        __Pausable_init();

        _setAssetBaseURI(_uri);

        _setNFTAddress(_dfy1155_physical_nft_address);

        _setTokenIBEP20Address(_ibep20_DFY_address);

        _setAddressAdmin(msg.sender);

        _setMintingNFTFee(50 * 10**18);
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    // Enum status asset
    enum AssetStatus {
        OPEN,
        EVALUATED,
        NFT_CREATED
    }

    // Asset
    struct Asset {
        string assetDataCID;
        address creator;
        AssetStatus status;
    }

    // Enum status evaluation
    enum EvaluationStatus {
        EVALUATED,
        EVALUATION_ACCEPTED,
        EVALUATION_REJECTED,
        NFT_CREATED
    }

    // Evaluation
    struct Evaluation {
        uint256 assetId;
        string evaluationCID;
        uint256 depreciationRate;
        address evaluator;
        address token;
        uint256 price;
        EvaluationStatus status;
    }

    event AssetCreated(uint256 assetId, Asset asset);

    event AssetEvaluated(
        uint256 evaluationId,
        uint256 assetId,
        Asset asset,
        Evaluation evaluation
    );

    event ApproveEvaluator(address evaluator);

    // Modifier check address call function
    modifier OnlyEOA() {
        require(!msg.sender.isContract(), "Calling from a contract");
        _;
    }

    // Function set base uri
    function setBaseURI(string memory _uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setAssetBaseURI(_uri);
    }

    // Function set asset base uri
    function _setAssetBaseURI(string memory _uri) internal {
        require(bytes(_uri).length > 0, "Empty asset URI");
        _assetBaseUri = _uri;
    }

    // Function
    function assetURI(uint256 _assetId) external view returns (string memory) {
        return
            bytes(_assetBaseUri).length > 0
                ? string(
                    abi.encodePacked(
                        _assetBaseUri,
                        assetList[_assetId].assetDataCID
                    )
                )
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Set the current NFT contract address to a new address
     * @param _newAddress is the address of the new NFT contract
     */
    function setNftContractAddress(address _newAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Verify if the new address is a contract or not
        require(_newAddress.isContract(), "Not a contract");

        _setNFTAddress(_newAddress);
    }

    function _setNFTAddress(address _newAddress) internal {
        dfy_physical_nfts = IDFY_Physical_NFTs(_newAddress);
    }

    /**
     * @dev Set the current NFT contract address to a new address
     * @param _newAddress is the address of the new NFT contract
     */
    function setTokenIBEP20Address(address _newAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Verify if the new address is a contract or not
        require(_newAddress.isContract(), "Not a contract");

        _setTokenIBEP20Address(_newAddress);
    }

    function _setTokenIBEP20Address(address _newAddress) internal {
        ibepDFY = IBEP20(_newAddress);
    }

    function setFeeWallet(address _feeWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setAddressAdmin(_feeWallet);
    }

    function feeWallet() external view returns (address) {
        return addressAdmin;
    }

    function _setAddressAdmin(address _newAddress) internal {
        addressAdmin = _newAddress;
    }

    function setMintingNFTFee(uint256 _fee)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Verify if the new address is a contract or not
        require(_fee > 0, "Not_Enough");

        _setMintingNFTFee(_fee);
    }

    function _setMintingNFTFee(uint256 _fee) internal {
        _mintingNFTFee = _fee;
    }

    /**
     * @dev Asset creation request by customer
     * @dev msg.sender is the asset creator's address
     * @param _cid is the CID string of the asset's JSON file stored on IFPS
     */
    function createAssetRequest(string memory _cid) external OnlyEOA {
        // msg.sender must not be a contract address

        // Require length _cid >0
        require(bytes(_cid).length > 0, "Asset CID must not be empty.");

        // Create asset id
        uint256 _assetId = totalAssets.current();

        // Add asset from asset list
        assetList[_assetId] = Asset({
            assetDataCID: _cid,
            creator: msg.sender,
            status: AssetStatus.OPEN
        });

        // Add asset id from list asset id of owner
        assetListByCreator[msg.sender].push(_assetId);

        // Update status from asset id of owner
        _assetsOfCreator[msg.sender][_assetId] = true;

        // Update total asset
        totalAssets.increment();

        emit AssetCreated(_assetId, assetList[_assetId]);
    }

    /**
     * @dev Return a list of asset created by _creator
     * @param _creator address representing the creator / owner of the assets.
     */
    function getAssetsByCreator(address _creator)
        external
        view
        returns (uint256[] memory)
    {
        require(
            _creator != address(0),
            "There is no asset associated with the zero address"
        );

        return assetListByCreator[_creator];
    }

    // Function check asset of creator
    function _isAssetOfCreator(address _creator, uint256 _assetId)
        internal
        view
        returns (bool)
    {
        return _assetsOfCreator[_creator][_assetId];
    }

    /**
     * @dev Asset evaluation by evaluator
     * @dev msg.sender is evaluator address
     * @param _assetId is the ID of the asset in AssetList
     * @param _currency is address of the token who create the asset
     * @param _price value of the asset, given by the Evaluator
     * @param _evaluationCID is Evaluation CID
     * @param _depreciationRate is depreciation rate of asset
     */
    function evaluateAsset(
        uint256 _assetId,
        address _currency,
        uint256 _price,
        string memory _evaluationCID,
        uint256 _depreciationRate
    ) external OnlyEOA onlyRole(EVALUATOR_ROLE) {
        // TODO
        // Require validation of msg.sender
        require(
            msg.sender != address(0),
            "Caller address different address(0)."
        );

        // Check evaluation CID
        require(
            bytes(_evaluationCID).length > 0,
            "Evaluation CID not be empty."
        );

        // Require address currency is contract except BNB - 0x0000000000000000000000000000000000000000
        if (_currency != address(0)) {
            require(_currency.isContract(), "Address token is not defined.");
        }

        // Require validation is creator asset
        require(
            !_isAssetOfCreator(msg.sender, _assetId),
            "You cant evaluted your asset."
        );

        // Require validation of asset via _assetId
        require(_assetId >= 0, "Asset does not exist.");

        // Get asset to asset id;
        Asset memory _asset = assetList[_assetId];

        // Check asset is exists
        require(
            bytes(_asset.assetDataCID).length > 0,
            "Asset does not exists."
        );

        // check status asset
        require(_asset.status == AssetStatus.OPEN, "This asset evaluated.");

        // Create evaluation id
        uint256 _evaluationId = totalEvaluation.current();

        // Add evaluation to evaluationList
        evaluationList[_evaluationId] = Evaluation({
            assetId: _assetId,
            evaluationCID: _evaluationCID,
            depreciationRate: _depreciationRate,
            evaluator: msg.sender,
            token: _currency,
            price: _price,
            status: EvaluationStatus.EVALUATED
        });

        // Add evaluation id to list evaluation of asset
        evaluationByAsset[_assetId].push(_evaluationId);

        // Add evaluation id to list evaluation of evaluator
        evaluationListByEvaluator[msg.sender].push(_evaluationId);

        // Update total evaluation
        totalEvaluation.increment();

        emit AssetEvaluated(
            _evaluationId,
            _assetId,
            _asset,
            evaluationList[_evaluationId]
        );
    }

    /**
     * @dev this function is check data when customer accept or reject evaluation
     * @param _assetId is the ID of the asset in AssetList
     * @param _evaluationId is the look up index of the Evaluation data in EvaluationsByAsset list
     */
    function _checkDataAcceptOrReject(uint256 _assetId, uint256 _evaluationId)
        internal
        view
        returns (bool)
    {
        // Check creator is address 0
        require(msg.sender != address(0), "ZERO_ADDRESS"); // msg.sender must not be the zero address

        // Check asset id
        require(_assetId >= 0, "INVALID_ASSET"); // assetId must not be zero

        // Check evaluation index
        require(_evaluationId >= 0, "INVALID_EVA"); // evaluationID must not be zero

        // Get asset to asset id;
        Asset memory _asset = assetList[_assetId];

        // Check asset to creator
        require(_asset.creator == msg.sender, "NOT_THE_OWNER"); // msg.sender must be the creator of the asset

        // Check asset is exists
        require(_asset.status == AssetStatus.OPEN, "EVA_NOT_ALLOWED"); // asset status must be Open

        // approve an evaluation by looking for its index in the array.
        Evaluation memory _evaluation = evaluationList[_evaluationId];

        // Check status evaluation
        require(
            _evaluation.status == EvaluationStatus.EVALUATED,
            "ASSET_NOT_EVALUATED"
        ); // evaluation status must be Evaluated

        return true;
    }

    /**
     * @dev This function is customer accept an evaluation
     * @param _assetId is id of asset
     * @param _evaluationId is id evaluation of asset
     */
    function acceptEvaluation(uint256 _assetId, uint256 _evaluationId)
        external
        OnlyEOA
    {
        // Check data
        require(_checkDataAcceptOrReject(_assetId, _evaluationId));

        // Get asset
        Asset storage _asset = assetList[_assetId];

        // Get evaluation
        Evaluation storage _evaluation = evaluationList[_evaluationId];

        // Update status evaluation
        _evaluation.status = EvaluationStatus.EVALUATION_ACCEPTED;

        // Reject all other evaluation of asset
        for (uint256 i = 0; i < evaluationByAsset[_assetId].length; i++) {
            if (evaluationByAsset[_assetId][i] != _evaluationId) {
                uint256 _evaluationIdReject = evaluationByAsset[_assetId][i];

                // Get evaluation
                Evaluation storage _otherEvaluation = evaluationList[
                    _evaluationIdReject
                ];

                // Update status evaluation
                _otherEvaluation.status = EvaluationStatus.EVALUATION_REJECTED;

                emit AssetEvaluated(
                    _evaluationId,
                    _assetId,
                    _asset,
                    _otherEvaluation
                );
            }
        }

        // Update status asset
        _asset.status = AssetStatus.EVALUATED;

        emit AssetEvaluated(_evaluationId, _assetId, _asset, _evaluation);
    }

    /**
     * @dev This function is customer reject an evaluation
     * @param _assetId is id of asset
     * @param _evaluationId is id evaluation of asset
     */
    function rejectEvaluation(uint256 _assetId, uint256 _evaluationId)
        external
        OnlyEOA
    {
        // Check data
        require(_checkDataAcceptOrReject(_assetId, _evaluationId));

        // Get asset
        Asset storage _asset = assetList[_assetId];

        // Get evaluation
        Evaluation storage _evaluation = evaluationList[_evaluationId];

        // Update status evaluation
        _evaluation.status = EvaluationStatus.EVALUATION_REJECTED;

        emit AssetEvaluated(_evaluationId, _assetId, _asset, _evaluation);
    }

    /**
     * @dev After an evaluation is approved, the Evaluator who submit
     * @dev evaluation data will call this function to generate an NFT token
     * @dev and transfer its ownership to Asset Creator's address.
     *
     * @param _assetId is the ID of the asset being converted to NFT token
     * @param _evaluationId is the look up index of the Evaluation data in the EvaluationsByAsset list
     * @param _nftCID is the NFT CID when mint token
     */

    function createNftToken(
        uint256 _assetId,
        uint256 _evaluationId,
        string memory _nftCID
    ) external OnlyEOA onlyRole(EVALUATOR_ROLE) nonReentrant {
        // Check nft CID
        require(bytes(_nftCID).length > 0, "NFT CID not be empty.");

        // Check asset id
        require(_assetId >= 0, "Asset does not exists.");

        // Get asset
        Asset storage _asset = assetList[_assetId];

        // Check asset CID
        require(bytes(_asset.assetDataCID).length > 0, "Asset does not exists");

        // Check status asset
        require(
            _asset.status == AssetStatus.EVALUATED,
            "Asset have not evaluation."
        );

        // Check evaluationId
        require(_evaluationId >= 0, "Evaluation does not exists.");

        // Get evaluation
        Evaluation storage _evaluation = evaluationList[_evaluationId];

        // Check evaluation CID
        require(
            bytes(_evaluation.evaluationCID).length > 0,
            "Evaluation does not exists"
        );

        // Check status evaluation
        require(
            _evaluation.status == EvaluationStatus.EVALUATION_ACCEPTED,
            "Evaluation is not acceptable."
        );

        // Check evaluator
        require(
            msg.sender == _evaluation.evaluator,
            "Evaluator address does not match."
        );

        // Check balance
        require(
            ibepDFY.balanceOf(msg.sender) >= (_mintingNFTFee),
            "Your balance is not enough."
        );

        require(
            ibepDFY.allowance(msg.sender, address(this)) >= (_mintingNFTFee),
            "You have not approve DFY."
        );

        // Create NFT
        uint256 mintedTokenId = dfy_physical_nfts.mint(
            _asset.creator,
            msg.sender,
            _evaluationId,
            1,
            _nftCID,
            ""
        );

        // Tranfer minting fee to admin
        ibepDFY.transferFrom(msg.sender, addressAdmin, _mintingNFTFee);

        // Update status asset
        _asset.status = AssetStatus.NFT_CREATED;

        // Update status evaluation
        _evaluation.status = EvaluationStatus.NFT_CREATED;

        // Add token id to list asset of owner
        tokenIdByAsset[mintedTokenId] = _asset;

        // Add token id to list nft of evaluator
        tokenIdByEvaluation[mintedTokenId] = _evaluation;
    }

    /**
     * @dev Add an Evaluator to Whitelist and grant him Minter role.
     * @param _account is the address of an Evaluator
     */
    function addEvaluator(address _account) external onlyRole(OPERATOR_ROLE) {
        // Grant Evaluator role
        grantRole(EVALUATOR_ROLE, _account);

        // Approve
        emit ApproveEvaluator(_account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "../../base/BaseInterface.sol";

interface IReputation is BaseInterface {
    // Reason for Reputation point adjustment
    /**
     * @dev Reputation points in correspondence with ReasonType
     * LD_CREATE_PACKAGE         : +3    (0)
     * LD_CANCEL_PACKAGE         : -3    (1)
     * LD_REOPEN_PACKAGE         : +3    (2)
     * LD_GENERATE_CONTRACT      : +1    (3)
     * LD_CREATE_OFFER           : +2    (4)
     * LD_CANCEL_OFFER           : -2    (5)
     * LD_ACCEPT_OFFER           : +1    (6)
     * BR_CREATE_COLLATERAL      : +3    (7)
     * BR_CANCEL_COLLATERAL      : -3    (8)
     * BR_ONTIME_PAYMENT         : +1    (9)
     * BR_LATE_PAYMENT           : -1    (10)
     * BR_ACCEPT_OFFER           : +1    (11)
     * BR_CONTRACT_COMPLETE      : +5    (12)
     * BR_CONTRACT_DEFAULTED     : -5    (13)
     * LD_REVIEWED_BY_BORROWER_1 : +1    (14)
     * LD_REVIEWED_BY_BORROWER_2 : +2    (15)
     * LD_REVIEWED_BY_BORROWER_3 : +3    (16)
     * LD_REVIEWED_BY_BORROWER_4 : +4    (17)
     * LD_REVIEWED_BY_BORROWER_5 : +5    (18)
     * LD_KYC                    : +5    (19)
     * BR_REVIEWED_BY_LENDER_1   : +1    (20)
     * BR_REVIEWED_BY_LENDER_2   : +2    (21)
     * BR_REVIEWED_BY_LENDER_3   : +3    (22)
     * BR_REVIEWED_BY_LENDER_4   : +4    (23)
     * BR_REVIEWED_BY_LENDER_5   : +5    (24)
     * BR_KYC                    : +5    (25)
     */

    enum ReasonType {
        LD_CREATE_PACKAGE,
        LD_CANCEL_PACKAGE,
        LD_REOPEN_PACKAGE,
        LD_GENERATE_CONTRACT,
        LD_CREATE_OFFER,
        LD_CANCEL_OFFER,
        LD_ACCEPT_OFFER,
        BR_CREATE_COLLATERAL,
        BR_CANCEL_COLLATERAL,
        BR_ONTIME_PAYMENT,
        BR_LATE_PAYMENT,
        BR_ACCEPT_OFFER,
        BR_CONTRACT_COMPLETE,
        BR_CONTRACT_DEFAULTED,
        LD_REVIEWED_BY_BORROWER_1,
        LD_REVIEWED_BY_BORROWER_2,
        LD_REVIEWED_BY_BORROWER_3,
        LD_REVIEWED_BY_BORROWER_4,
        LD_REVIEWED_BY_BORROWER_5,
        LD_KYC,
        BR_REVIEWED_BY_LENDER_1,
        BR_REVIEWED_BY_LENDER_2,
        BR_REVIEWED_BY_LENDER_3,
        BR_REVIEWED_BY_LENDER_4,
        BR_REVIEWED_BY_LENDER_5,
        BR_KYC
    }

    /**
     * @dev Get the reputation score of an account
     */
    function getReputationScore(address _address)
        external
        view
        returns (uint32);

    function adjustReputationScore(address _user, ReasonType _reasonType)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../pawn-p2p-v2/PawnLib.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "./IExchange.sol";
import "../pawn-nft-v2/PawnNFTLib.sol";

import "../hub/HubInterface.sol";
import "../hub/HubLib.sol";

contract Exchange is
    Initializable,
    UUPSUpgradeable,
    IExchange,
    ERC165Upgradeable
{
    mapping(address => address) public ListCryptoExchange;
    address hubContract;

    function initialize(address _HubContractAddress) public initializer {
        __UUPSUpgradeable_init();
        hubContract = _HubContractAddress;

        // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setContractHub(address _contractHubAddress) external onlyAdmin {
        hubContract = _contractHubAddress;
    }

    modifier onlyAdmin() {
        // (, , address _admin, ) = HubInterface(hubContract).getSystemConfig();
        // require(_admin == msg.sender, "is not admin");
        require(
            IAccessControlUpgradeable(hubContract).hasRole(
                HubRoleLib.DEFAULT_ADMIN_ROLE,
                msg.sender
            )
        );

        _;
    }

    function _authorizeUpgrade(address) internal override onlyAdmin {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165Upgradeable, ERC165Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // set dia chi cac token ( crypto) tuong ung voi dia chi chuyen doi ra USD tren chain link
    function setCryptoExchange(
        address _cryptoAddress,
        address _latestPriceAddress
    ) external override onlyAdmin {
        ListCryptoExchange[_cryptoAddress] = _latestPriceAddress;
    }

    function getLatestRoundData(AggregatorV3Interface getPriceToUSD)
        internal
        view
        returns (uint256, uint256)
    {
        (, int256 _price, , uint256 _timeStamp, ) = getPriceToUSD
            .latestRoundData();

        require(_price > 0, "Negative or zero rate");

        return (uint256(_price), _timeStamp);
    }

    // lay gia cua dong BNB
    function RateBNBwithUSD() internal view returns (uint256 price) {
        AggregatorV3Interface getPriceToUSD = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );

        (price, ) = getLatestRoundData(getPriceToUSD);
    }

    // lay ti gia dong BNB + timestamp
    function RateBNBwithUSDAttimestamp()
        internal
        view
        returns (uint256 price, uint256 timeStamp)
    {
        AggregatorV3Interface getPriceToUSD = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );

        (price, timeStamp) = getLatestRoundData(getPriceToUSD);
    }

    // lay gia cua cac crypto va token khac da duoc them vao ListcryptoExchange
    function getLatesPriceToUSD(address _adcrypto)
        internal
        view
        returns (uint256 price)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            ListCryptoExchange[_adcrypto]
        );

        (price, ) = getLatestRoundData(priceFeed);
    }

    // lay ti gia va timestamp cua cac crypto va token da duoc them vao ListcryptoExchange
    function getRateAndTimestamp(address _adcrypto)
        internal
        view
        returns (uint256 price, uint256 timeStamp)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            ListCryptoExchange[_adcrypto]
        );

        (price, timeStamp) = getLatestRoundData(priceFeed);
    }

    function calculateLoanAmountAndExchangeRate(
        Collateral memory _col,
        PawnShopPackage memory _pkg
    ) external view returns (uint256 loanAmount, uint256 exchangeRate) {
        (loanAmount, exchangeRate, , , ) = calcLoanAmountAndExchangeRate(
            _col.collateralAddress,
            _col.amount,
            _col.loanAsset,
            _pkg.loanToValue,
            _pkg.repaymentAsset
        );
    }

    function calcLoanAmountAndExchangeRate(
        address collateralAddress,
        uint256 amount,
        address loanAsset,
        uint256 loanToValue,
        address repaymentAsset
    )
        public
        view
        returns (
            uint256 loanAmount,
            uint256 exchangeRate,
            uint256 collateralToUSD,
            uint256 rateLoanAsset,
            uint256 rateRepaymentAsset
        )
    {
        if (collateralAddress == address(0)) {
            // If collateral address is address(0), check BNB exchange rate with USD
            // collateralToUSD = (uint256(RateBNBwithUSD()) * loanToValue * amount) / (100 * 10**5);
            (, uint256 ltvAmount) = SafeMathUpgradeable.tryMul(
                loanToValue,
                amount
            );
            (, uint256 collRate) = SafeMathUpgradeable.tryMul(
                ltvAmount,
                uint256(RateBNBwithUSD())
            );
            (, uint256 collToUSD) = SafeMathUpgradeable.tryDiv(
                collRate,
                (100 * 10**5)
            );

            collateralToUSD = collToUSD;
        } else {
            // If collateral address is not BNB, get latest price in USD of collateral crypto
            // collateralToUSD = (uint256(getLatesPriceToUSD(collateralAddress))  * loanToValue * amount) / (100 * 10**5);
            (, uint256 ltvAmount) = SafeMathUpgradeable.tryMul(
                loanToValue,
                amount
            );
            (, uint256 collRate) = SafeMathUpgradeable.tryMul(
                ltvAmount,
                getLatesPriceToUSD(collateralAddress)
            );
            (, uint256 collToUSD) = SafeMathUpgradeable.tryDiv(
                collRate,
                (100 * 10**5)
            );

            collateralToUSD = collToUSD;
        }

        if (loanAsset == address(0)) {
            // get price of BNB in USD
            rateLoanAsset = RateBNBwithUSD();
        } else {
            // get price in USD of crypto as loan asset
            rateLoanAsset = getLatesPriceToUSD(loanAsset);
        }

        (, uint256 lAmount) = SafeMathUpgradeable.tryDiv(
            collateralToUSD,
            rateLoanAsset
        );
        // loanAmount = collateralToUSD / rateLoanAsset;
        // uint256 tempLoamAmount = lAmount / 10**13;
        // loanAmount = tempLoamAmount * 10**13;
        loanAmount = DivRound(lAmount);

        if (repaymentAsset == address(0)) {
            // get price in USD of BNB as repayment asset
            rateRepaymentAsset = RateBNBwithUSD();
        } else {
            // get latest price in USD of crypto as repayment asset
            rateRepaymentAsset = getLatesPriceToUSD(repaymentAsset);
        }

        // calculate exchange rate
        (, uint256 xchange) = SafeMathUpgradeable.tryDiv(
            rateLoanAsset * 10**18,
            rateRepaymentAsset
        );
        exchangeRate = xchange;
    }

    // calculate Rate of LoanAsset with repaymentAsset
    function exchangeRateofOffer(address _adLoanAsset, address _adRepayment)
        external
        view
        returns (uint256 exchangeRateOfOffer)
    {
        //  exchangeRateOffer = loanAsset / repaymentAsset
        if (_adLoanAsset == address(0)) {
            // if LoanAsset is address(0) , check BNB exchange rate with BNB
            (, uint256 exRate) = SafeMathUpgradeable.tryDiv(
                RateBNBwithUSD() * 10**18,
                getLatesPriceToUSD(_adRepayment)
            );
            exchangeRateOfOffer = exRate;
        } else {
            // all LoanAsset and repaymentAsset are crypto or token is different BNB
            (, uint256 exRate) = SafeMathUpgradeable.tryDiv(
                (getLatesPriceToUSD(_adLoanAsset) * 10**18),
                getLatesPriceToUSD(_adRepayment)
            );
            exchangeRateOfOffer = exRate;
        }
    }

    //===========================================Tinh interest =======================================
    // tinh tien lai cua moi ky: interest = loanAmount * interestByLoanDurationType
    //(interestByLoanDurationType = % lãi * số kì * loại kì / (365*100))

    function calculateInterest(
        uint256 _remainingLoan,
        Contract memory _contract
    ) external view returns (uint256 interest) {
        uint256 _interestToUSD;
        uint256 _repaymentAssetToUSD;
        uint256 _interestByLoanDurationType;

        // tien lai
        if (_contract.terms.loanAsset == address(0)) {
            // neu loanAsset la dong BNB
            // interestToUSD = (uint256(RateBNBwithUSD()) *_contract.terms.loanAmount) * _contract.terms.interest;
            (, uint256 interestToAmount) = SafeMathUpgradeable.tryMul(
                _contract.terms.interest,
                _remainingLoan
            );
            (, uint256 interestRate) = SafeMathUpgradeable.tryMul(
                interestToAmount,
                RateBNBwithUSD()
            );
            (, uint256 itrestRate) = SafeMathUpgradeable.tryDiv(
                interestRate,
                (100 * 10**5)
            );
            _interestToUSD = itrestRate;
        } else {
            // Neu loanAsset la cac dong crypto va token khac BNB
            // interestToUSD = (uint256(getLatesPriceToUSD(_contract.terms.loanAsset)) * _contract.terms.loanAmount) * _contractterms.interest;
            (, uint256 interestToAmount) = SafeMathUpgradeable.tryMul(
                _contract.terms.interest,
                _remainingLoan
            );
            (, uint256 interestRate) = SafeMathUpgradeable.tryMul(
                interestToAmount,
                getLatesPriceToUSD(_contract.terms.loanAsset)
            );
            (, uint256 itrestRate) = SafeMathUpgradeable.tryDiv(
                interestRate,
                (100 * 10**5)
            );
            _interestToUSD = itrestRate;
        }

        // tinh tien lai cho moi ky thanh toan
        if (_contract.terms.repaymentCycleType == LoanDurationType.WEEK) {
            // neu thoi gian vay theo tuan thì L = loanAmount * interest * 7 /365
            (, uint256 _interest) = SafeMathUpgradeable.tryDiv(
                (_interestToUSD * 7),
                365
            );
            _interestByLoanDurationType = _interest;
        } else {
            // thoi gian vay theo thang thi  L = loanAmount * interest * 30 /365
            //  _interestByLoanDurationType =(_contract.terms.interest * 30) / 365);
            (, uint256 _interest) = SafeMathUpgradeable.tryDiv(
                (_interestToUSD * 30),
                365
            );
            _interestByLoanDurationType = _interest;
        }

        // tinh Rate cua dong repayment
        if (_contract.terms.repaymentAsset == address(0)) {
            // neu dong tra la BNB
            _repaymentAssetToUSD = RateBNBwithUSD();
        } else {
            // neu dong tra kha BNB
            _repaymentAssetToUSD = getLatesPriceToUSD(
                _contract.terms.repaymentAsset
            );
        }

        // tien lai theo moi kỳ tinh ra dong tra
        (, uint256 saInterest) = SafeMathUpgradeable.tryDiv(
            _interestByLoanDurationType,
            _repaymentAssetToUSD
        );
        // uint256 tempInterest = saInterest / 10**13;
        // interest = tempInterest * 10**13;
        interest = DivRound(saInterest);
    }

    //=============================== Tinh penalty =====================================

    //  p = (p(n-1)) + (p(n-1) *(L)) + (L(n-1)*(p))

    function calculatePenalty(
        PaymentRequest memory _paymentrequest,
        Contract memory _contract,
        uint256 _penaltyRate
    ) external pure returns (uint256 valuePenalty) {
        uint256 _interestOfPenalty;
        if (_contract.terms.repaymentCycleType == LoanDurationType.WEEK) {
            // neu ky vay theo tuan thi (L) = interest * 7 /365
            //_interestByLoanDurationType =(_contract.terms.interest * 7) / (100 * 365);
            (, uint256 saInterestByLoanDurationType) = SafeMathUpgradeable
                .tryDiv((_contract.terms.interest * 7), 365);
            (, uint256 saPenaltyOfInterestRate) = SafeMathUpgradeable.tryMul(
                _paymentrequest.remainingPenalty,
                saInterestByLoanDurationType
            );
            (, uint256 saPenaltyOfInterest) = SafeMathUpgradeable.tryDiv(
                saPenaltyOfInterestRate,
                (100 * 10**5)
            );
            _interestOfPenalty = saPenaltyOfInterest;
        } else {
            // _interestByLoanDurationType =(_contract.terms.interest * 30) /(100 * 365);
            (, uint256 saInterestByLoanDurationType) = SafeMathUpgradeable
                .tryDiv(_contract.terms.interest * 30, 365);
            (, uint256 saPenaltyOfInterestRate) = SafeMathUpgradeable.tryMul(
                _paymentrequest.remainingPenalty,
                saInterestByLoanDurationType
            );
            (, uint256 saPenaltyOfInterest) = SafeMathUpgradeable.tryDiv(
                saPenaltyOfInterestRate,
                (100 * 10**5)
            );
            _interestOfPenalty = saPenaltyOfInterest;
        }
        // valuePenalty =(_paymentrequest.remainingPenalty +_paymentrequest.remainingPenalty *_interestByLoanDurationType +_paymentrequest.remainingInterest *_penaltyRate);
        //  uint256 penalty = _paymentrequest.remainingInterest * _penaltyRate;
        (, uint256 penalty) = SafeMathUpgradeable.tryDiv(
            (_paymentrequest.remainingInterest * _penaltyRate),
            (100 * 10**5)
        );
        uint256 _penalty = _paymentrequest.remainingPenalty +
            _interestOfPenalty +
            penalty;
        // uint256 tempPenalty = _penalty / 10**13;
        // valuePenalty = tempPenalty * 10**13;
        valuePenalty = DivRound(_penalty);
    }

    // lay Rate va thoi gian cap nhat ti gia do
    function RateAndTimestamp(Contract memory _contract)
        external
        view
        returns (
            uint256 _collateralExchangeRate,
            uint256 _loanExchangeRate,
            uint256 _repaymemtExchangeRate,
            uint256 _rateUpdateTime
        )
    {
        // Get exchange rate of collateral token
        if (_contract.terms.collateralAsset == address(0)) {
            (
                _collateralExchangeRate,
                _rateUpdateTime
            ) = RateBNBwithUSDAttimestamp();
        } else {
            (_collateralExchangeRate, _rateUpdateTime) = getRateAndTimestamp(
                _contract.terms.collateralAsset
            );
        }

        // Get exchange rate of loan token
        if (_contract.terms.loanAsset == address(0)) {
            (_loanExchangeRate, _rateUpdateTime) = RateBNBwithUSDAttimestamp();
        } else {
            (_loanExchangeRate, _rateUpdateTime) = getRateAndTimestamp(
                _contract.terms.loanAsset
            );
        }

        // Get exchange rate of repayment token
        if (_contract.terms.repaymentAsset == address(0)) {
            (
                _repaymemtExchangeRate,
                _rateUpdateTime
            ) = RateBNBwithUSDAttimestamp();
        } else {
            (_repaymemtExchangeRate, _rateUpdateTime) = getRateAndTimestamp(
                _contract.terms.repaymentAsset
            );
        }
    }

    // tinh ti gia cua repayment / collateralAsset  va   loanAsset / collateralAsset
    function collateralPerRepaymentAndLoanTokenExchangeRate(
        Contract memory _contract
    )
        external
        view
        returns (
            uint256 _collateralPerRepaymentTokenExchangeRate,
            uint256 _collateralPerLoanAssetExchangeRate
        )
    {
        uint256 priceRepaymentAset;
        uint256 priceLoanAsset;
        uint256 priceCollateralAsset;

        if (_contract.terms.repaymentAsset == address(0)) {
            // neu repaymentAsset la BNB
            priceRepaymentAset = RateBNBwithUSD();
        } else {
            // neu la cac dong khac
            priceRepaymentAset = getLatesPriceToUSD(
                _contract.terms.repaymentAsset
            );
        }

        if (_contract.terms.loanAsset == address(0)) {
            // neu dong loan asset la BNB
            priceLoanAsset = RateBNBwithUSD();
        } else {
            // cac dong khac
            priceLoanAsset = getLatesPriceToUSD(_contract.terms.loanAsset);
        }

        if (_contract.terms.collateralAsset == address(0)) {
            // neu collateralAsset la bnb
            priceCollateralAsset = RateBNBwithUSD();
        } else {
            // la cac dong khac
            priceCollateralAsset = getLatesPriceToUSD(
                _contract.terms.collateralAsset
            );
        }

        bool success;
        // tempCollateralPerRepaymentTokenExchangeRate = priceRepaymentAsset / priceCollateralAsset
        (
            success,
            _collateralPerRepaymentTokenExchangeRate
        ) = SafeMathUpgradeable.tryDiv(
            (priceRepaymentAset * 10**10),
            priceCollateralAsset
        );
        require(success, "Safe math: division by zero");

        // _collateralPerRepaymentTokenExchangeRate = tempCollateralPerRepaymentTokenExchangeRate;

        // tempCollateralPerLoanAssetExchangeRate = priceLoanAsset / priceCollateralAsset
        (success, _collateralPerLoanAssetExchangeRate) = SafeMathUpgradeable
            .tryDiv((priceLoanAsset * 10**10), priceCollateralAsset);

        require(success, "Safe math: division by zero");

        // _collateralPerLoanAssetExchangeRate = tempCollateralPerLoanAssetExchangeRate;
    }

    /**======================   NFT =========================================== */

    /** ========== exchange Rate Of Offer   ===================== */
    // exchangeRate offer
    function exchangeRateOfOffer_NFT(address _adLoanAsset, address _adRepayment)
        external
        view
        returns (uint256 exchangeRate)
    {
        // exchangeRate = loan / repayment
        if (_adLoanAsset == address(0)) {
            // if LoanAsset is address(0) , check BNB exchange rate with BNB
            (, uint256 exRate) = SafeMathUpgradeable.tryDiv(
                RateBNBwithUSD() * 10**18,
                getLatesPriceToUSD(_adRepayment)
            );
            exchangeRate = exRate;
        } else {
            // all LoanAsset and repaymentAsset are crypto or token is different BNB
            (, uint256 exRate) = SafeMathUpgradeable.tryDiv(
                (getLatesPriceToUSD(_adLoanAsset) * 10**18),
                getLatesPriceToUSD(_adRepayment)
            );
            exchangeRate = exRate;
        }
    }

    /** ======== Tinh interest ===================== */

    function calculateInterest_NFT(
        uint256 _remainingLoan,
        Contract_NFT memory _contract
    ) external view returns (uint256 interest) {
        uint256 _interestToUSD;
        uint256 _repaymentAssetToUSD;
        uint256 _interestByLoanDurationType;

        // tinh tien lai
        if (_contract.terms.loanAsset == address(0)) {
            // if loanAsset is BNB
            (, uint256 interestToAmount) = SafeMathUpgradeable.tryMul(
                _contract.terms.interest,
                _remainingLoan
            );
            (, uint256 interestRate) = SafeMathUpgradeable.tryMul(
                interestToAmount,
                RateBNBwithUSD()
            );
            (, uint256 itrestRate) = SafeMathUpgradeable.tryDiv(
                interestRate,
                (100 * 10**5)
            );
            _interestToUSD = itrestRate;
        } else {
            // Neu loanAsset la cac dong crypto va token khac BNB
            // interestToUSD = (uint256(getLatesPriceToUSD(_contract.terms.loanAsset)) * _contract.terms.loanAmount) * _contractterms.interest;
            (, uint256 interestToAmount) = SafeMathUpgradeable.tryMul(
                _contract.terms.interest,
                _remainingLoan
            );
            (, uint256 interestRate) = SafeMathUpgradeable.tryMul(
                interestToAmount,
                getLatesPriceToUSD(_contract.terms.loanAsset)
            );
            (, uint256 itrestRate) = SafeMathUpgradeable.tryDiv(
                interestRate,
                (100 * 10**5)
            );
            _interestToUSD = itrestRate;
        }

        // tinh tien lai cho moi ky thanh toan
        if (_contract.terms.repaymentCycleType == LoanDurationType_NFT.WEEK) {
            // neu thoi gian vay theo tuan thì L = loanAmount * interest * 7 /365
            (, uint256 _interest) = SafeMathUpgradeable.tryDiv(
                (_interestToUSD * 7),
                365
            );
            _interestByLoanDurationType = _interest;
        } else {
            // thoi gian vay theo thang thi  L = loanAmount * interest * 30 /365
            //  _interestByLoanDurationType =(_contract.terms.interest * 30) / 365);
            (, uint256 _interest) = SafeMathUpgradeable.tryDiv(
                (_interestToUSD * 30),
                365
            );
            _interestByLoanDurationType = _interest;
        }

        // tinh Rate cua dong repayment
        if (_contract.terms.repaymentAsset == address(0)) {
            // neu dong tra la BNB
            _repaymentAssetToUSD = RateBNBwithUSD();
        } else {
            // neu dong tra kha BNB
            _repaymentAssetToUSD = getLatesPriceToUSD(
                _contract.terms.repaymentAsset
            );
        }

        // tien lai theo moi kỳ tinh ra dong tra
        (, uint256 saInterest) = SafeMathUpgradeable.tryDiv(
            _interestByLoanDurationType,
            _repaymentAssetToUSD
        );
        // uint256 tempInterest = saInterest / 10**13;
        // interest = tempInterest * 10**13;
        interest = DivRound(saInterest);
    }

    /** =========== Tinh penalty ================ */

    function calculatePenalty_NFT(
        PaymentRequest_NFT memory _paymentrequest,
        Contract_NFT memory _contract,
        uint256 _penaltyRate
    ) external pure returns (uint256 valuePenalty) {
        uint256 _interestOfPenalty;
        if (_contract.terms.repaymentCycleType == LoanDurationType_NFT.WEEK) {
            // neu ky vay theo tuan thi (L) = interest * 7 /365
            //_interestByLoanDurationType =(_contract.terms.interest * 7) / (100 * 365);
            (, uint256 saInterestByLoanDurationType) = SafeMathUpgradeable
                .tryDiv((_contract.terms.interest * 7), 365);
            (, uint256 saPenaltyOfInterestRate) = SafeMathUpgradeable.tryMul(
                _paymentrequest.remainingPenalty,
                saInterestByLoanDurationType
            );
            (, uint256 saPenaltyOfInterest) = SafeMathUpgradeable.tryDiv(
                saPenaltyOfInterestRate,
                (100 * 10**5)
            );
            _interestOfPenalty = saPenaltyOfInterest;
        } else {
            // _interestByLoanDurationType =(_contract.terms.interest * 30) /(100 * 365);
            (, uint256 saInterestByLoanDurationType) = SafeMathUpgradeable
                .tryDiv(_contract.terms.interest * 30, 365);
            (, uint256 saPenaltyOfInterestRate) = SafeMathUpgradeable.tryMul(
                _paymentrequest.remainingPenalty,
                saInterestByLoanDurationType
            );
            (, uint256 saPenaltyOfInterest) = SafeMathUpgradeable.tryDiv(
                saPenaltyOfInterestRate,
                (100 * 10**5)
            );
            _interestOfPenalty = saPenaltyOfInterest;
        }
        // valuePenalty =(_paymentrequest.remainingPenalty +_paymentrequest.remainingPenalty *_interestByLoanDurationType +_paymentrequest.remainingInterest *_penaltyRate);
        //  uint256 penalty = _paymentrequest.remainingInterest * _penaltyRate;
        (, uint256 penalty) = SafeMathUpgradeable.tryDiv(
            (_paymentrequest.remainingInterest * _penaltyRate),
            (100 * 10**5)
        );
        uint256 _penalty = _paymentrequest.remainingPenalty +
            _interestOfPenalty +
            penalty;
        // uint256 tempPenalty = _penalty / 10**13;
        // valuePenalty = tempPenalty * 10**13;
        valuePenalty = DivRound(_penalty);
    }

    /** ======================= Tinh Rate cho moi lan vo no vi ti gia   =================== */

    // tinh ti gia cua repayment / collateralAsset  va   loanAsset / collateralAsset
    function collateralPerRepaymentAndLoanTokenExchangeRate_NFT(
        Contract_NFT memory _contract,
        address _adEvaluationAsset
    )
        external
        view
        returns (
            uint256 _collateralPerRepaymentTokenExchangeRate,
            uint256 _collateralPerLoanAssetExchangeRate
        )
    {
        uint256 priceRepaymentAset;
        uint256 priceLoanAsset;
        uint256 priceCollateralAsset;

        if (_contract.terms.repaymentAsset == address(0)) {
            // neu repaymentAsset la BNB
            priceRepaymentAset = RateBNBwithUSD();
        } else {
            // neu la cac dong khac
            priceRepaymentAset = getLatesPriceToUSD(
                _contract.terms.repaymentAsset
            );
        }

        if (_contract.terms.loanAsset == address(0)) {
            // neu dong loan asset la BNB
            priceLoanAsset = RateBNBwithUSD();
        } else {
            // cac dong khac
            priceLoanAsset = getLatesPriceToUSD(_contract.terms.loanAsset);
        }

        if (_adEvaluationAsset == address(0)) {
            // neu collateralAsset la bnb
            priceCollateralAsset = RateBNBwithUSD();
        } else {
            // la cac dong khac
            priceCollateralAsset = getLatesPriceToUSD(_adEvaluationAsset);
        }

        bool success;
        // tempCollateralPerRepaymentTokenExchangeRate = priceRepaymentAsset / priceCollateralAsset
        (
            success,
            _collateralPerRepaymentTokenExchangeRate
        ) = SafeMathUpgradeable.tryDiv(
            (priceRepaymentAset * 10**10),
            priceCollateralAsset
        );
        require(success, "Safe math: division by zero");

        // _collateralPerRepaymentTokenExchangeRate = tempCollateralPerRepaymentTokenExchangeRate;

        // tempCollateralPerLoanAssetExchangeRate = priceLoanAsset / priceCollateralAsset
        (success, _collateralPerLoanAssetExchangeRate) = SafeMathUpgradeable
            .tryDiv((priceLoanAsset * 10**10), priceCollateralAsset);

        require(success, "Safe math: division by zero");

        // _collateralPerLoanAssetExchangeRate = tempCollateralPerLoanAssetExchangeRate;
    }

    /** ============ Tinh rate va thoi gian cap nhat Rate do ======================== */
    // lay Rate va thoi gian cap nhat ti gia do
    function RateAndTimestamp_NFT(
        Contract_NFT memory _contract,
        address _adEvaluationAsset
    )
        external
        view
        returns (
            uint256 _collateralExchangeRate,
            uint256 _loanExchangeRate,
            uint256 _repaymemtExchangeRate,
            uint256 _rateUpdateTime
        )
    {
        // Get exchange rate of collateral token
        if (_adEvaluationAsset == address(0)) {
            (
                _collateralExchangeRate,
                _rateUpdateTime
            ) = RateBNBwithUSDAttimestamp();
        } else {
            (_collateralExchangeRate, _rateUpdateTime) = getRateAndTimestamp(
                _adEvaluationAsset
            );
        }

        // Get exchange rate of loan token
        if (_contract.terms.loanAsset == address(0)) {
            (_loanExchangeRate, _rateUpdateTime) = RateBNBwithUSDAttimestamp();
        } else {
            (_loanExchangeRate, _rateUpdateTime) = getRateAndTimestamp(
                _contract.terms.loanAsset
            );
        }

        // Get exchange rate of repayment token
        if (_contract.terms.repaymentAsset == address(0)) {
            (
                _repaymemtExchangeRate,
                _rateUpdateTime
            ) = RateBNBwithUSDAttimestamp();
        } else {
            (_repaymemtExchangeRate, _rateUpdateTime) = getRateAndTimestamp(
                _contract.terms.repaymentAsset
            );
        }
    }

    /** =================================== ROUNDING    ============================= */

    function DivRound(uint256 a) private pure returns (uint256) {
        // kiem tra so du khi chia 10**13. Neu lon hon 5 *10**12 khi chia xong thi lam tron len(+1) roi nhan lai voi 10**13
        //con nho hon thi giu nguyen va nhan lai voi 10**13

        uint256 tmp = a % 10**13;
        uint256 tm;
        if (tmp < 5 * 10**12) {
            tm = a / 10**13;
        } else {
            tm = a / 10**13 + 1;
        }
        uint256 rouding = tm * 10**13;
        return rouding;
    }

    /**============  signature ====================*/

    function signature() public view override returns (bytes4) {
        return type(IExchange).interfaceId;
    }

    function RegistrywithHubContract() external {
        HubInterface(hubContract).registerContract(signature(), address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
// import "../access/DFY-AccessControl.sol";
import "../libs/CommonLib.sol";
import "./HubLib.sol";
import "./HubInterface.sol";

contract Hub is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    HubInterface
{
    using AddressUpgradeable for address;

    mapping(bytes4 => address) public ContractRegistry;

    SystemConfig public systemConfig;
    PawnConfig public pawnConfig;
    PawnNFTConfig public pawnNFTConfig;

    // TODO: New state variables must go below this line -----------------------------
    NFTCollectionConfig public nftCollectionConfig;
    NFTMarketConfig public nftMarketConfig;

    /** ==================== Contract initializing & configuration ==================== */
    function initialize(
        address feeWallet,
        address feeToken,
        address operator
    ) public initializer {
        __UUPSUpgradeable_init();
        __Pausable_init();
        __AccessControl_init();

        _setupRole(HubRoleLib.DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(HubRoleLib.OPERATOR_ROLE, operator);
        _setupRole(HubRoleLib.PAUSER_ROLE, msg.sender);
        _setupRole(HubRoleLib.EVALUATOR_ROLE, msg.sender);

        // Set OPERATOR_ROLE as EVALUATOR_ROLE's Admin Role
        _setRoleAdmin(HubRoleLib.EVALUATOR_ROLE, HubRoleLib.OPERATOR_ROLE);

        systemConfig.systemFeeWallet = feeWallet;
        systemConfig.systemFeeToken = feeToken;
    }

    function setOperator(address _newOperator)
        external
        onlyRole(HubRoleLib.DEFAULT_ADMIN_ROLE)
    {
        // operator = _newOperator;

        grantRole(HubRoleLib.OPERATOR_ROLE, _newOperator);
    }

    function setPauseRole(address _newPauseRole)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(HubRoleLib.PAUSER_ROLE, _newPauseRole);
    }

    function setEvaluationRole(address _newEvaluationRole) external {
        grantRole(HubRoleLib.EVALUATOR_ROLE, _newEvaluationRole);
    }

    modifier whenContractNotPaused() {
        _whenNotPaused();
        _;
    }

    function _whenNotPaused() private view {
        require(!paused(), "Pausable: paused");
    }

    function pause() external onlyRole(HubRoleLib.PAUSER_ROLE) {
        _pause();
    }

    function unPause() external onlyRole(HubRoleLib.PAUSER_ROLE) {
        _unpause();
    }

    function AdminRole() public pure override returns (bytes32) {
        return HubRoleLib.DEFAULT_ADMIN_ROLE;
    }

    function OperatorRole() public pure override returns (bytes32) {
        return HubRoleLib.OPERATOR_ROLE;
    }

    function PauserRole() public pure override returns (bytes32) {
        return HubRoleLib.PAUSER_ROLE;
    }

    function EvaluatorRole() public pure override returns (bytes32) {
        return HubRoleLib.EVALUATOR_ROLE;
    }

    /** ==================== Standard interface function implementations ==================== */

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** ==================== Hub operation functions ==================== */
    uint256 public numContract;

    function registerContract(bytes4 signature, address contractAddress)
        external
        override
        onlyRole(HubRoleLib.DEFAULT_ADMIN_ROLE)
    {
        ContractRegistry[signature] = contractAddress;
        numContract++;
    }

    function setSystemConfig(address _FeeWallet, address _FeeToken)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_FeeWallet != address(0)) {
            systemConfig.systemFeeWallet = _FeeWallet;
        }

        if (_FeeToken != address(0)) {
            systemConfig.systemFeeToken = _FeeToken;
        }
    }

    function getSystemConfig()
        external
        view
        override
        returns (address _FeeWallet, address _FeeToken)
    {
        _FeeWallet = systemConfig.systemFeeWallet;
        _FeeToken = systemConfig.systemFeeToken;
    }

    function getContractAddress(bytes4 signature)
        external
        view
        override
        returns (address contractAddress)
    {
        contractAddress = ContractRegistry[signature];
    }

    /** ================= config PAWN NFT ============== */
    function setEvaluationContract(address _evaluationContract, uint256 _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pawnNFTConfig.whitelistedEvaluationContract[
            _evaluationContract
        ] = _status;
    }

    function getEvaluationContract(address _evaluationContractAddress)
        external
        view
        override
        returns (uint256 _status)
    {
        _status = pawnNFTConfig.whitelistedEvaluationContract[
            _evaluationContractAddress
        ];
    }

    function setWhitelistCollateral_NFT(address _token, uint256 _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pawnNFTConfig.whitelistedCollateral[_token] = _status;
    }

    function getWhitelistCollateral_NFT(address _token)
        external
        view
        override
        returns (uint256 _status)
    {
        _status = pawnNFTConfig.whitelistedCollateral[_token];
    }

    function setPawnNFTConfig(
        int256 _zoom,
        int256 _FeeRate,
        int256 _penaltyRate,
        int256 _prepaidFeedRate,
        int256 _lateThreshold
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_zoom >= 0) {
            pawnNFTConfig.ZOOM = CommonLib.abs(_zoom);
        }

        if (_FeeRate >= 0) {
            pawnNFTConfig.systemFeeRate = CommonLib.abs(_FeeRate);
        }

        if (_penaltyRate >= 0) {
            pawnNFTConfig.penaltyRate = CommonLib.abs(_penaltyRate);
        }

        if (_prepaidFeedRate >= 0) {
            pawnNFTConfig.prepaidFeeRate = CommonLib.abs(_prepaidFeedRate);
        }

        if (_lateThreshold >= 0) {
            pawnNFTConfig.lateThreshold = CommonLib.abs(_lateThreshold);
        }
    }

    function getPawnNFTConfig()
        external
        view
        override
        returns (
            uint256 _zoom,
            uint256 _FeeRate,
            uint256 _penaltyRate,
            uint256 _prepaidFeedRate,
            uint256 _lateThreshold
        )
    {
        _zoom = pawnNFTConfig.ZOOM;
        _FeeRate = pawnNFTConfig.systemFeeRate;
        _penaltyRate = pawnNFTConfig.penaltyRate;
        _prepaidFeedRate = pawnNFTConfig.prepaidFeeRate;
        _lateThreshold = pawnNFTConfig.lateThreshold;
    }

    /** =================== ConFIg PAWN crypto ===================*/

    function setWhitelistCollateral(address _token, uint256 _status)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pawnConfig.whitelistedCollateral[_token] = _status;
    }

    function getWhitelistCollateral(address _token)
        external
        view
        override
        returns (uint256 _status)
    {
        _status = pawnConfig.whitelistedCollateral[_token];
    }

    function setPawnConfig(
        int256 _zoom,
        int256 _FeeRate,
        int256 _penaltyRate,
        int256 _prepaidFeedRate,
        int256 _lateThreshold
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_zoom >= 0) {
            pawnNFTConfig.ZOOM = CommonLib.abs(_zoom);
        }

        if (_FeeRate >= 0) {
            pawnNFTConfig.systemFeeRate = CommonLib.abs(_FeeRate);
        }

        if (_penaltyRate >= 0) {
            pawnNFTConfig.penaltyRate = CommonLib.abs(_penaltyRate);
        }

        if (_prepaidFeedRate >= 0) {
            pawnNFTConfig.prepaidFeeRate = CommonLib.abs(_prepaidFeedRate);
        }

        if (_lateThreshold >= 0) {
            pawnNFTConfig.lateThreshold = CommonLib.abs(_lateThreshold);
        }
    }

    function getPawnConfig()
        external
        view
        override
        returns (
            uint256 _zoom,
            uint256 _FeeRate,
            uint256 _penaltyRate,
            uint256 _prepaidFeeRate,
            uint256 _lateThreshold
        )
    {
        _zoom = pawnConfig.ZOOM;
        _FeeRate = pawnConfig.systemFeeRate;
        _penaltyRate = pawnConfig.penaltyRate;
        _prepaidFeeRate = pawnConfig.prepaidFeeRate;
        _lateThreshold = pawnConfig.lateThreshold;
    }

    /** =================== Config NFT Collection & Market ===================*/

    function setNFTConfiguration(
        int256 collectionCreatingFee,
        int256 mintingFee
    ) external onlyRole(HubRoleLib.DEFAULT_ADMIN_ROLE) {
        if (collectionCreatingFee >= 0) {
            nftCollectionConfig.collectionCreatingFee = CommonLib.abs(
                collectionCreatingFee
            );
        }
        if (mintingFee >= 0) {
            nftCollectionConfig.mintingFee = CommonLib.abs(mintingFee);
        }
    }

    function setNFTMarketConfig(
        int256 zoom,
        int256 marketFeeRate,
        address marketFeeWallet
    ) external onlyRole(HubRoleLib.DEFAULT_ADMIN_ROLE) {
        if (zoom >= 0) {
            nftMarketConfig.ZOOM = CommonLib.abs(zoom);
        }
        if (marketFeeRate >= 0) {
            nftMarketConfig.marketFeeRate = CommonLib.abs(marketFeeRate);
        }
        if (marketFeeWallet != address(0) && !marketFeeWallet.isContract()) {
            nftMarketConfig.marketFeeWallet = marketFeeWallet;
        }
    }

    function getNFTCollectionConfig()
        external
        view
        override
        returns (uint256 collectionCreatingFee, uint256 mintingFee)
    {
        collectionCreatingFee = nftCollectionConfig.collectionCreatingFee;
        mintingFee = nftCollectionConfig.mintingFee;
    }

    function getNFTMarketConfig()
        external
        view
        override
        returns (
            uint256 zoom,
            uint256 marketFeeRate,
            address marketFeeWallet
        )
    {
        zoom = nftMarketConfig.ZOOM;
        marketFeeRate = nftMarketConfig.marketFeeRate;
        marketFeeWallet = nftMarketConfig.marketFeeWallet;
    }

    /**======================= */

    event ContractAdminChanged(address from, address to);

    /**
     * @dev change contract's admin to a new address
     */
    function changeContractAdmin(address newAdmin)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Check if the new Admin address is a contract address
        require(!newAdmin.isContract(), "New admin must not be a contract");

        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());

        emit ContractAdminChanged(_msgSender(), newAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface HubInterface {
    struct SystemConfig {
        address systemFeeWallet;
        address systemFeeToken;
        // address Admin;
        // address Operator;
    }

    struct PawnConfig {
        uint256 ZOOM;
        uint256 systemFeeRate;
        uint256 penaltyRate;
        uint256 prepaidFeeRate;
        uint256 lateThreshold;
        mapping(address => uint256) whitelistedCollateral;
    }

    struct PawnNFTConfig {
        uint256 ZOOM;
        uint256 systemFeeRate;
        uint256 penaltyRate;
        uint256 prepaidFeeRate;
        uint256 lateThreshold;
        mapping(address => uint256) whitelistedEvaluationContract;
        mapping(address => uint256) whitelistedCollateral;
    }

    struct NFTCollectionConfig {
        uint256 collectionCreatingFee;
        uint256 mintingFee;
    }

    struct NFTMarketConfig {
        uint256 ZOOM;
        uint256 marketFeeRate;
        address marketFeeWallet;
    }

    /** Functions */
    /** ROLES */
    function AdminRole() external pure returns (bytes32);
    function OperatorRole() external pure returns (bytes32);
    function PauserRole() external pure returns (bytes32);
    function EvaluatorRole() external pure returns (bytes32);

    function registerContract(bytes4 nameContract, address contractAddress)
        external;

    function getContractAddress(bytes4 signature)
        external
        view
        returns (address contractAddres);

    function getSystemConfig()
        external
        view
        returns (address feeWallet, address feeToken);

    function getEvaluationContract(address _evaluationContractAddress)
        external
        view
        returns (uint256 _status);

    function getWhitelistCollateral_NFT(address _token)
        external
        view
        returns (uint256 _status);

    function getPawnNFTConfig()
        external
        view
        returns (
            uint256 _zoom,
            uint256 _FeeRate,
            uint256 _penaltyRate,
            uint256 _prepaidFeedRate,
            uint256 _lateThreshold
        );

    function getWhitelistCollateral(address _token)
        external
        view
        returns (uint256 _status);

    function getPawnConfig()
        external
        view
        returns (
            uint256 _zoom,
            uint256 _FeeRate,
            uint256 _penaltyRate,
            uint256 _prepaidFeeRate,
            uint256 _lateThreshold
        );

    function getNFTCollectionConfig()
        external
        view
        returns (uint256 collectionCreatingFee, uint256 mintingFee);

    function getNFTMarketConfig()
        external
        view
        returns (
            uint256 zoom,
            uint256 marketFeeRate,
            address marketFeeWallet
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library HubRoleLib {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    /**
     * @dev OPERATOR_ROLE: those who have this role can assigne EVALUATOR_ROLE to others
     */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @dev PAUSER_ROLE: those who can pause the contract
     * by default this role is assigned to the contract creator
     *
     * NOTE: The main contract must inherit `Pausable` or this ROLE doesn't make sense
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev EVALUATOR_ROLE: Whitelisted Evaluators who can mint NFT token after evaluation has been accepted.
     */
    bytes32 public constant EVALUATOR_ROLE = keccak256("EVALUATOR_ROLE");
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "../../base/BaseInterface.sol";
import "../pawn-nft-v2/PawnNFTLib.sol";
import "../pawn-p2p-v2/PawnLib.sol";

interface IExchange is BaseInterface {
    // lay gia cua dong BNB

    function setCryptoExchange(
        address _cryptoAddress,
        address _latestPriceAddress
    ) external;

    function calculateLoanAmountAndExchangeRate(
        Collateral memory _col,
        PawnShopPackage memory _pkg
    ) external view returns (uint256 loanAmount, uint256 exchangeRate);

    function calcLoanAmountAndExchangeRate(
        address collateralAddress,
        uint256 amount,
        address loanAsset,
        uint256 loanToValue,
        address repaymentAsset
    )
        external
        view
        returns (
            uint256 loanAmount,
            uint256 exchangeRate,
            uint256 collateralToUSD,
            uint256 rateLoanAsset,
            uint256 rateRepaymentAsset
        );

    function exchangeRateofOffer(address _adLoanAsset, address _adRepayment)
        external
        view
        returns (uint256 exchangeRateOfOffer);

    function calculateInterest(
        uint256 _remainingLoan,
        Contract memory _contract
    ) external view returns (uint256 interest);

    function calculatePenalty(
        PaymentRequest memory _paymentrequest,
        Contract memory _contract,
        uint256 _penaltyRate
    ) external pure returns (uint256 valuePenalty);

    function RateAndTimestamp(Contract memory _contract)
        external
        view
        returns (
            uint256 _collateralExchangeRate,
            uint256 _loanExchangeRate,
            uint256 _repaymemtExchangeRate,
            uint256 _rateUpdateTime
        );

    function collateralPerRepaymentAndLoanTokenExchangeRate(
        Contract memory _contract
    )
        external
        view
        returns (
            uint256 _collateralPerRepaymentTokenExchangeRate,
            uint256 _collateralPerLoanAssetExchangeRate
        );

    function exchangeRateOfOffer_NFT(address _adLoanAsset, address _adRepayment)
        external
        view
        returns (uint256 exchangeRate);

    function calculateInterest_NFT(
        uint256 _remainingLoan,
        Contract_NFT memory _contract
    ) external view returns (uint256 interest);

    function calculatePenalty_NFT(
        PaymentRequest_NFT memory _paymentrequest,
        Contract_NFT memory _contract,
        uint256 _penaltyRate
    ) external pure returns (uint256 valuePenalty);

    function collateralPerRepaymentAndLoanTokenExchangeRate_NFT(
        Contract_NFT memory _contract,
        address _adEvaluationAsset
    )
        external
        view
        returns (
            uint256 _collateralPerRepaymentTokenExchangeRate,
            uint256 _collateralPerLoanAssetExchangeRate
        );

    function RateAndTimestamp_NFT(
        Contract_NFT memory _contract,
        address _adEvaluationAsset
    )
        external
        view
        returns (
            uint256 _collateralExchangeRate,
            uint256 _loanExchangeRate,
            uint256 _repaymemtExchangeRate,
            uint256 _rateUpdateTime
        );
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
interface IERC165Upgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract DFYAccessControl is AccessControlUpgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev OPERATOR_ROLE: those who have this role can assigne EVALUATOR_ROLE to others
     */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @dev PAUSER_ROLE: those who can pause the contract
     * by default this role is assigned to the contract creator
     *
     * NOTE: The main contract must inherit `Pausable` or this ROLE doesn't make sense
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev EVALUATOR_ROLE: Whitelisted Evaluators who can mint NFT token after evaluation has been accepted.
     */
    bytes32 public constant EVALUATOR_ROLE = keccak256("EVALUATOR_ROLE");

    function __DFYAccessControl_init() internal initializer {
        __AccessControl_init();

        __DFYAccessControl_init_unchained();
    }

    function __DFYAccessControl_init_unchained() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);

        // Set OPERATOR_ROLE as EVALUATOR_ROLE's Admin Role
        _setRoleAdmin(EVALUATOR_ROLE, OPERATOR_ROLE);
    }

    event ContractAdminChanged(address from, address to);

    /**
     * @dev change contract's admin to a new address
     */
    function changeContractAdmin(address newAdmin)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Check if the new Admin address is a contract address
        require(!newAdmin.isContract(), "New admin must not be a contract");

        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());

        emit ContractAdminChanged(_msgSender(), newAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

interface BaseInterface is IERC165Upgradeable {
    function signature() external view returns (bytes4);
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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
// import "./IPawn.sol";

enum LoanDurationType {
    WEEK,
    MONTH
}
enum CollateralStatus {
    OPEN,
    DOING,
    COMPLETED,
    CANCEL
}
struct Collateral {
    address owner;
    uint256 amount;
    address collateralAddress;
    address loanAsset;
    uint256 expectedDurationQty;
    LoanDurationType expectedDurationType;
    CollateralStatus status;
}

enum OfferStatus {
    PENDING,
    ACCEPTED,
    COMPLETED,
    CANCEL
}
struct CollateralOfferList {
    mapping(uint256 => Offer) offerMapping;
    uint256[] offerIdList;
    bool isInit;
}

struct Offer {
    address owner;
    address repaymentAsset;
    uint256 loanAmount;
    uint256 interest;
    uint256 duration;
    OfferStatus status;
    LoanDurationType loanDurationType;
    LoanDurationType repaymentCycleType;
    uint256 liquidityThreshold;
    bool isInit;
}

enum PawnShopPackageStatus {
    ACTIVE,
    INACTIVE
}
enum PawnShopPackageType {
    AUTO,
    SEMI_AUTO
}
struct Range {
    uint256 lowerBound;
    uint256 upperBound;
}

struct PawnShopPackage {
    address owner;
    PawnShopPackageStatus status;
    PawnShopPackageType packageType;
    address loanToken;
    Range loanAmountRange;
    address[] collateralAcceptance;
    uint256 interest;
    uint256 durationType;
    Range durationRange;
    address repaymentAsset;
    LoanDurationType repaymentCycleType;
    uint256 loanToValue;
    uint256 loanToValueLiquidationThreshold;
}

enum LoanRequestStatus {
    PENDING,
    ACCEPTED,
    REJECTED,
    CONTRACTED,
    CANCEL
}
struct LoanRequestStatusStruct {
    bool isInit;
    LoanRequestStatus status;
}
struct CollateralAsLoanRequestListStruct {
    mapping(uint256 => LoanRequestStatusStruct) loanRequestToPawnShopPackageMapping; // Mapping from package to status
    uint256[] pawnShopPackageIdList;
    bool isInit;
}

enum ContractStatus {
    ACTIVE,
    COMPLETED,
    DEFAULT
}
struct ContractTerms {
    address borrower;
    address lender;
    address collateralAsset;
    uint256 collateralAmount;
    address loanAsset;
    uint256 loanAmount;
    address repaymentAsset;
    uint256 interest;
    LoanDurationType repaymentCycleType;
    uint256 liquidityThreshold;
    uint256 contractStartDate;
    uint256 contractEndDate;
    uint256 lateThreshold;
    uint256 systemFeeRate;
    uint256 penaltyRate;
    uint256 prepaidFeeRate;
}
struct Contract {
    uint256 collateralId;
    int256 offerId;
    int256 pawnShopPackageId;
    ContractTerms terms;
    ContractStatus status;
    uint8 lateCount;
}

enum PaymentRequestStatusEnum {
    ACTIVE,
    LATE,
    COMPLETE,
    DEFAULT
}
enum PaymentRequestTypeEnum {
    INTEREST,
    OVERDUE,
    LOAN
}
struct PaymentRequest {
    uint256 requestId;
    PaymentRequestTypeEnum paymentRequestType;
    uint256 remainingLoan;
    uint256 penalty;
    uint256 interest;
    uint256 remainingPenalty;
    uint256 remainingInterest;
    uint256 dueDateTimestamp;
    bool chargePrepaidFee;
    PaymentRequestStatusEnum status;
}

enum ContractLiquidedReasonType {
    LATE,
    RISK,
    UNPAID
}

struct ContractRawData {
    uint256 collateralId;
    address borrower;
    address loanAsset;
    address collateralAsset;
    uint256 collateralAmount;
    int256 packageId;
    int256 offerId;
    uint256 exchangeRate;
    uint256 loanAmount;
    address lender;
    address repaymentAsset;
    uint256 interest;
    LoanDurationType repaymentCycleType;
    uint256 liquidityThreshold;
    uint256 loanDurationQty;
}

struct ContractLiquidationData {
    uint256 contractId;
    uint256 liquidAmount;
    uint256 systemFeeAmount;
    uint256 collateralExchangeRate;
    uint256 loanExchangeRate;
    uint256 repaymentExchangeRate;
    uint256 rateUpdateTime;
    ContractLiquidedReasonType reasonType;
}

struct DataRepaymentEvent {
    uint256 contractId;
    uint256 paidPenaltyAmount;
    uint256 paidInterestAmount;
    uint256 paidLoanAmount;
    uint256 feePenalty;
    uint256 feeInterest;
    uint256 prepaidFee;
    uint256 requestId;
    uint256 UID;
}

library PawnLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function safeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (asset == address(0)) {
            require(from.balance >= amount, "0"); // balance
            // Handle BNB
            if (to == address(this)) {
                // Send to this contract
            } else if (from == address(this)) {
                // Send from this contract
                (bool success, ) = to.call{value: amount}("");
                require(success, "1"); //fail-trans-bnb
            } else {
                // Send from other address to another address
                require(false, "2"); //not-allow-transfer
            }
        } else {
            // Handle ERC20
            uint256 prebalance = IERC20Upgradeable(asset).balanceOf(to);
            require(
                IERC20Upgradeable(asset).balanceOf(from) >= amount,
                "3" //not-enough-balance
            );
            if (from == address(this)) {
                // transfer direct to to
                IERC20Upgradeable(asset).safeTransfer(to, amount);
            } else {
                require(
                    IERC20Upgradeable(asset).allowance(from, address(this)) >=
                        amount,
                    "4" //not-allowance
                );
                IERC20Upgradeable(asset).safeTransferFrom(from, to, amount);
            }
            require(
                IERC20Upgradeable(asset).balanceOf(to) - amount == prebalance,
                "5" //not-trans-enough
            );
        }
    }

    function calculateAmount(address _token, address from)
        internal
        view
        returns (uint256 _amount)
    {
        if (_token == address(0)) {
            // BNB
            _amount = from.balance;
        } else {
            // ERC20
            _amount = IERC20Upgradeable(_token).balanceOf(from);
        }
    }

    function calculateSystemFee(
        uint256 amount,
        uint256 feeRate,
        uint256 zoom
    ) internal pure returns (uint256 feeAmount) {
        feeAmount = (amount * feeRate) / (zoom * 100);
    }

    function calculateContractDuration(
        LoanDurationType durationType,
        uint256 duration
    ) internal pure returns (uint256 inSeconds) {
        if (durationType == LoanDurationType.WEEK) {
            inSeconds = 7 * 24 * 3600 * duration;
        } else {
            inSeconds = 30 * 24 * 3600 * duration;
        }
    }

    function isPrepaidChargeRequired(
        LoanDurationType durationType,
        uint256 startDate,
        uint256 endDate
    ) internal pure returns (bool) {
        // uint256 week = 600; // define week duration
        // uint256 month = 900; // define month duration
        uint256 week = 7 * 24 * 3600;
        uint256 month = 30 * 24 * 3600;

        if (durationType == LoanDurationType.WEEK) {
            // if loan contract only lasts one week
            if ((endDate - startDate) <= week) {
                return false;
            } else {
                return true;
            }
        } else {
            // if loan contract only lasts one month
            if ((endDate - startDate) <= month) {
                return false;
            } else {
                return true;
            }
        }
    }

    function calculatedueDateTimestampInterest(LoanDurationType durationType)
        internal
        pure
        returns (uint256 duedateTimestampInterest)
    {
        if (durationType == LoanDurationType.WEEK) {
            duedateTimestampInterest = 3 * 24 * 3600;
            // duedateTimestampInterest = 180; // test
        } else {
            duedateTimestampInterest = 7 * 24 * 3600;
            // duedateTimestampInterest = 300; // test
        }
    }

    function calculatedueDateTimestampPenalty(LoanDurationType durationType)
        internal
        pure
        returns (uint256 duedateTimestampInterest)
    {
        if (durationType == LoanDurationType.WEEK) {
            duedateTimestampInterest = (7 - 3) * 24 * 3600;
            // duedateTimestampInterest = 600 - 180; // test
        } else {
            duedateTimestampInterest = (30 - 7) * 24 * 3600;
            // duedateTimestampInterest = 900 - 300; // test
        }
    }

    function checkLenderAccount(
        uint256 loanAmount,
        address loanToken,
        address owner,
        address spender
    ) internal view {
        // Check if lender has enough balance and allowance for lending
        uint256 lenderCurrentBalance = IERC20Upgradeable(loanToken).balanceOf(
            owner
        );
        require(lenderCurrentBalance >= loanAmount, "4"); // insufficient balance

        uint256 lenderCurrentAllowance = IERC20Upgradeable(loanToken).allowance(
            owner,
            spender
        );
        require(lenderCurrentAllowance >= loanAmount, "5"); // allowance not enough
    }

    /**
     * @dev Return the absolute value of a signed integer
     * @param _input is any signed integer
     * @return an unsigned integer that is the absolute value of _input
     */
    function abs(int256 _input) internal pure returns (uint256) {
        return _input >= 0 ? uint256(_input) : uint256(_input * -1);
    }
}

library CollateralLib {
    function create(
        Collateral storage self,
        address _collateralAddress,
        uint256 _amount,
        address _loanAsset,
        uint256 _expectedDurationQty,
        LoanDurationType _expectedDurationType
    ) internal {
        self.owner = msg.sender;
        self.amount = _amount;
        self.collateralAddress = _collateralAddress;
        self.loanAsset = _loanAsset;
        self.status = CollateralStatus.OPEN;
        self.expectedDurationQty = _expectedDurationQty;
        self.expectedDurationType = _expectedDurationType;
    }

    function submitToLoanPackage(
        Collateral storage self,
        uint256 _packageId,
        CollateralAsLoanRequestListStruct storage _loanRequestListStruct
    ) internal {
        if (!_loanRequestListStruct.isInit) {
            _loanRequestListStruct.isInit = true;
        }

        LoanRequestStatusStruct storage statusStruct = _loanRequestListStruct
            .loanRequestToPawnShopPackageMapping[_packageId];
        require(statusStruct.isInit == false);
        statusStruct.isInit = true;
        statusStruct.status = LoanRequestStatus.PENDING;

        _loanRequestListStruct.pawnShopPackageIdList.push(_packageId);
    }

    function removeFromLoanPackage(
        Collateral storage self,
        uint256 _packageId,
        CollateralAsLoanRequestListStruct storage _loanRequestListStruct
    ) internal {
        delete _loanRequestListStruct.loanRequestToPawnShopPackageMapping[
            _packageId
        ];

        uint256 lastIndex = _loanRequestListStruct
            .pawnShopPackageIdList
            .length - 1;

        for (uint256 i = 0; i <= lastIndex; i++) {
            if (_loanRequestListStruct.pawnShopPackageIdList[i] == _packageId) {
                _loanRequestListStruct.pawnShopPackageIdList[
                        i
                    ] = _loanRequestListStruct.pawnShopPackageIdList[lastIndex];
                break;
            }
        }
    }

    function checkCondition(
        Collateral storage self,
        uint256 _packageId,
        PawnShopPackage storage _pawnShopPackage,
        CollateralAsLoanRequestListStruct storage _loanRequestListStruct,
        CollateralStatus _requiredCollateralStatus,
        LoanRequestStatus _requiredLoanRequestStatus
    ) internal view returns (LoanRequestStatusStruct storage _statusStruct) {
        // Check for owner of packageId
        // _pawnShopPackage = pawnShopPackages[_packageId];
        require(_pawnShopPackage.status == PawnShopPackageStatus.ACTIVE, "0"); // pack

        // Check for collateral status is open
        // _collateral = collaterals[_collateralId];
        require(self.status == _requiredCollateralStatus, "1"); // col

        // Check for collateral-package status is PENDING (waiting for accept)
        // _loanRequestListStruct = collateralAsLoanRequestMapping[_collateralId];
        require(_loanRequestListStruct.isInit == true, "2"); // col-loan-req
        _statusStruct = _loanRequestListStruct
            .loanRequestToPawnShopPackageMapping[_packageId];
        require(_statusStruct.isInit == true, "3"); // col-loan-req-pack
        require(_statusStruct.status == _requiredLoanRequestStatus, "4"); // stt
    }
}

library OfferLib {
    function create(
        Offer storage self,
        address _repaymentAsset,
        uint256 _loanAmount,
        uint256 _duration,
        uint256 _interest,
        uint8 _loanDurationType,
        uint8 _repaymentCycleType,
        uint256 _liquidityThreshold
    ) internal {
        self.isInit = true;
        self.owner = msg.sender;
        self.loanAmount = _loanAmount;
        self.interest = _interest;
        self.duration = _duration;
        self.loanDurationType = LoanDurationType(_loanDurationType);
        self.repaymentAsset = _repaymentAsset;
        self.repaymentCycleType = LoanDurationType(_repaymentCycleType);
        self.liquidityThreshold = _liquidityThreshold;
        self.status = OfferStatus.PENDING;
    }

    function cancel(
        Offer storage self,
        uint256 _id,
        address _collateralOwner,
        CollateralOfferList storage _collateralOfferList
    ) internal {
        require(self.isInit == true, "1"); // offer-col
        require(
            self.owner == msg.sender || _collateralOwner == msg.sender,
            "2"
        ); // owner
        require(self.status == OfferStatus.PENDING, "3"); // offer

        delete _collateralOfferList.offerMapping[_id];
        uint256 lastIndex = _collateralOfferList.offerIdList.length - 1;
        for (uint256 i = 0; i <= lastIndex; i++) {
            if (_collateralOfferList.offerIdList[i] == _id) {
                _collateralOfferList.offerIdList[i] = _collateralOfferList
                    .offerIdList[lastIndex];
                break;
            }
        }

        delete _collateralOfferList.offerIdList[lastIndex];
    }
}

library PawnPackageLib {
    function create(
        PawnShopPackage storage self,
        PawnShopPackageType _packageType,
        address _loanToken,
        Range calldata _loanAmountRange,
        address[] calldata _collateralAcceptance,
        uint256 _interest,
        uint256 _durationType,
        Range calldata _durationRange,
        address _repaymentAsset,
        LoanDurationType _repaymentCycleType,
        uint256 _loanToValue,
        uint256 _loanToValueLiquidationThreshold
    ) internal {
        self.owner = msg.sender;
        self.status = PawnShopPackageStatus.ACTIVE;
        self.packageType = _packageType;
        self.loanToken = _loanToken;
        self.loanAmountRange = _loanAmountRange;
        self.collateralAcceptance = _collateralAcceptance;
        self.interest = _interest;
        self.durationType = _durationType;
        self.durationRange = _durationRange;
        self.repaymentAsset = _repaymentAsset;
        self.repaymentCycleType = _repaymentCycleType;
        self.loanToValue = _loanToValue;
        self.loanToValueLiquidationThreshold = _loanToValueLiquidationThreshold;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

enum DurationType {
    HOUR,
    DAY
}

library CommonLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using SafeCastUpgradeable for uint256;

    /**
     * @dev safe transfer BNB or ERC20
     * @param  asset is address of the cryptocurrency to be transferred
     * @param  from is the address of the transferor
     * @param  to is the address of the receiver
     * @param  amount is transfer amount
     */

    function safeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (asset == address(0)) {
            require(from.balance >= amount, "0"); // balance
            // Handle BNB
            if (to == address(this)) {
                // Send to this contract
            } else if (from == address(this)) {
                // Send from this contract
                (bool success, ) = to.call{value: amount}("");
                require(success, "1"); //fail-trans-bnb
            } else {
                // Send from other address to another address
                require(false, "2"); //not-allow-transfer
            }
        } else {
            // Handle ERC20
            uint256 prebalance = IERC20Upgradeable(asset).balanceOf(to);
            require(
                IERC20Upgradeable(asset).balanceOf(from) >= amount,
                "3" //not-enough-balance
            );
            if (from == address(this)) {
                // transfer direct to to
                IERC20Upgradeable(asset).safeTransfer(to, amount);
            } else {
                require(
                    IERC20Upgradeable(asset).allowance(from, address(this)) >=
                        amount,
                    "4" //not-allowance
                );
                IERC20Upgradeable(asset).safeTransferFrom(from, to, amount);
            }
            require(
                IERC20Upgradeable(asset).balanceOf(to) - amount == prebalance,
                "5" //not-trans-enough
            );
        }
    }

    /**
     * @dev Calculate fee of system
     * @param  amount amount charged to the system
     * @param  feeRate is system fee rate
     */
    function calculateSystemFee(
        uint256 amount,
        uint256 feeRate,
        uint256 zoom
    ) internal pure returns (uint256 feeAmount) {
        feeAmount = (amount * feeRate) / (zoom * 100);
    }

    /**
     * @dev Return the absolute value of a signed integer
     * @param _input is any signed integer
     * @return an unsigned integer that is the absolute value of _input
     */
    function abs(int256 _input) internal pure returns (uint256) {
        return _input >= 0 ? uint256(_input) : uint256(_input * -1);
    }

    // event getTime(uint256 startTime);

    function getSecondsOfDuration(DurationType durationType, uint256 duration)
        internal
        pure
        returns (uint256 inSeconds)
    {
        if (durationType == DurationType.HOUR) {
            inSeconds = duration * 5; // For testing 1 hour = 5 seconds
        } else if (durationType == DurationType.DAY) {
            inSeconds = duration * 120; // For testing 1 day = 120 seconds
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}