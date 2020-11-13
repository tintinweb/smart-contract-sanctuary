pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../oracle/implementation/ContractCreator.sol";
import "../../common/implementation/Testable.sol";
import "../../common/implementation/AddressWhitelist.sol";
import "../../common/implementation/Lockable.sol";
import "./ExpiringMultiPartyLib.sol";


/**
 * @title Expiring Multi Party Contract creator.
 * @notice Factory contract to create and register new instances of expiring multiparty contracts.
 * Responsible for constraining the parameters used to construct a new EMP. This creator contains a number of constraints
 * that are applied to newly created expiring multi party contract. These constraints can evolve over time and are
 * initially constrained to conservative values in this first iteration. Technically there is nothing in the
 * ExpiringMultiParty contract requiring these constraints. However, because `createExpiringMultiParty()` is intended
 * to be the only way to create valid financial contracts that are registered with the DVM (via _registerContract),
  we can enforce deployment configurations here.
 */
contract ExpiringMultiPartyCreator is ContractCreator, Testable, Lockable {
    using FixedPoint for FixedPoint.Unsigned;

    /****************************************
     *     EMP CREATOR DATA STRUCTURES      *
     ****************************************/

    struct Params {
        uint256 expirationTimestamp;
        address collateralAddress;
        bytes32 priceFeedIdentifier;
        string syntheticName;
        string syntheticSymbol;
        FixedPoint.Unsigned collateralRequirement;
        FixedPoint.Unsigned disputeBondPct;
        FixedPoint.Unsigned sponsorDisputeRewardPct;
        FixedPoint.Unsigned disputerDisputeRewardPct;
        FixedPoint.Unsigned minSponsorTokens;
        uint256 withdrawalLiveness;
        uint256 liquidationLiveness;
        address excessTokenBeneficiary;
    }
    // - Address of TokenFactory to pass into newly constructed ExpiringMultiParty contracts
    address public tokenFactoryAddress;

    event CreatedExpiringMultiParty(address indexed expiringMultiPartyAddress, address indexed deployerAddress);

    /**
     * @notice Constructs the ExpiringMultiPartyCreator contract.
     * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
     * @param _tokenFactoryAddress ERC20 token factory used to deploy synthetic token instances.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     */
    constructor(
        address _finderAddress,
        address _tokenFactoryAddress,
        address _timerAddress
    ) public ContractCreator(_finderAddress) Testable(_timerAddress) nonReentrant() {
        tokenFactoryAddress = _tokenFactoryAddress;
    }

    /**
     * @notice Creates an instance of expiring multi party and registers it within the registry.
     * @param params is a `ConstructorParams` object from ExpiringMultiParty.
     * @return address of the deployed ExpiringMultiParty contract.
     */
    function createExpiringMultiParty(Params memory params) public nonReentrant() returns (address) {
        address derivative = ExpiringMultiPartyLib.deploy(_convertParams(params));

        _registerContract(new address[](0), address(derivative));

        emit CreatedExpiringMultiParty(address(derivative), msg.sender);

        return address(derivative);
    }

    /****************************************
     *          PRIVATE FUNCTIONS           *
     ****************************************/

    // Converts createExpiringMultiParty params to ExpiringMultiParty constructor params.
    function _convertParams(Params memory params)
        private
        view
        returns (ExpiringMultiParty.ConstructorParams memory constructorParams)
    {
        // Known from creator deployment.
        constructorParams.finderAddress = finderAddress;
        constructorParams.tokenFactoryAddress = tokenFactoryAddress;
        constructorParams.timerAddress = timerAddress;

        // Enforce configuration constraints.
        require(bytes(params.syntheticName).length != 0, "Missing synthetic name");
        require(bytes(params.syntheticSymbol).length != 0, "Missing synthetic symbol");
        require(params.withdrawalLiveness != 0, "Withdrawal liveness cannot be 0");
        require(params.liquidationLiveness != 0, "Liquidation liveness cannot be 0");
        require(params.excessTokenBeneficiary != address(0), "Token Beneficiary cannot be 0x0");
        require(params.expirationTimestamp > now, "Invalid expiration time");
        _requireWhitelistedCollateral(params.collateralAddress);

        // We don't want EMP deployers to be able to intentionally or unintentionally set
        // liveness periods that could induce arithmetic overflow, but we also don't want
        // to be opinionated about what livenesses are "correct", so we will somewhat
        // arbitrarily set the liveness upper bound to 100 years (5200 weeks). In practice, liveness
        // periods even greater than a few days would make the EMP unusable for most users.
        require(params.withdrawalLiveness < 5200 weeks, "Withdrawal liveness too large");
        require(params.liquidationLiveness < 5200 weeks, "Liquidation liveness too large");

        // Input from function call.
        constructorParams.expirationTimestamp = params.expirationTimestamp;
        constructorParams.collateralAddress = params.collateralAddress;
        constructorParams.priceFeedIdentifier = params.priceFeedIdentifier;
        constructorParams.syntheticName = params.syntheticName;
        constructorParams.syntheticSymbol = params.syntheticSymbol;
        constructorParams.collateralRequirement = params.collateralRequirement;
        constructorParams.disputeBondPct = params.disputeBondPct;
        constructorParams.sponsorDisputeRewardPct = params.sponsorDisputeRewardPct;
        constructorParams.disputerDisputeRewardPct = params.disputerDisputeRewardPct;
        constructorParams.minSponsorTokens = params.minSponsorTokens;
        constructorParams.withdrawalLiveness = params.withdrawalLiveness;
        constructorParams.liquidationLiveness = params.liquidationLiveness;
        constructorParams.excessTokenBeneficiary = params.excessTokenBeneficiary;
    }
}
