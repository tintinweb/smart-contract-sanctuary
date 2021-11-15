pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IDnsClusterMetadataStore {
    function dnsToClusterMetadata(bytes32)
        external
        returns (
            address,
            string memory,
            string memory,
            uint256,
            uint256,
            bool,
            uint256,
            bool
        );

    function addDnsToClusterEntry(
        bytes32 _dns,
        address _clusterOwner,
        string memory ipAddress,
        string memory _whitelistedIps
    ) external;

    function removeDnsToClusterEntry(bytes32 _dns) external;

    function upvoteCluster(bytes32 _dns) external;

    function downvoteCluster(bytes32 _dns) external;

    function markClusterAsDefaulter(bytes32 _dns) external;

    function getClusterOwner(bytes32 clusterDns) external returns (address);
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EscrowStorage.sol";
import "../cluster-metadata/IDnsClusterMetadataStore.sol";
import "../resource-feed/IResourceFeed.sol";
import "./uniswap/IUniswapV2Pair.sol";
import "./uniswap/IUniswapV2Router02.sol";
import "./uniswap/IUniswapV2Factory.sol";
import "../oracle/IPriceOracle.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title BaseEscrow is parent contract of Stack Escrow
/// @notice Serves as base layer contract responsible for all major tasks
contract BaseEscrow is Ownable, EscrowStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event WITHDRAW(
        address accountOwner,
        uint256 amountDeposited,
        uint256 amountWithdrawn,
        uint256 depositedAt
    );

    event DEPOSIT(
        bytes32 clusterDns,
        address indexed owner,
        uint256 totalDeposit,
        uint256 lastTxTime,
        uint256 indexed dripRate
    );

    /*
     * @dev - constructor (being called internally at Stack Escrow contract deployment)
     * @param Address of stackToken deployed contract
     * @param Address of ResourceFeed deployed contract
     * @param Address of Staking deployed contract
     * @param Address of DnsClusterMetadataStore deployed contract
     * @param Factory Contract of DEX
     * @param Router Contract of DEX
     * @param Dao address
     * @param Gov address
     * @param WETH Contract Address
     * @param USDT Contract Address
     * @param Oracle Contract Address
     */
    constructor(
        address _stackToken,
        address _resourceFeed,
        address _staking,
        address _dnsStore,
        IUniswapV2Factory _factory,
        IUniswapV2Router02 _router,
        address _dao,
        address _gov,
        address _weth,
        address _usdt,
        address _oracle
    ) public {
        stackToken = _stackToken;
        resourceFeed = _resourceFeed;
        staking = _staking;
        dnsStore = _dnsStore;
        factory = _factory;
        router = _router;
        weth = _weth;
        dao = _dao;
        gov = _gov;
        usdt = _usdt;
        oracle = _oracle;
    }

    /*
     * @title Update the Platform Variable Fees. These fees are in percentages.
     * @param Updated Platform Governance Fee
     * @param Updated Platform DAO Fee
     * @dev Could only be invoked by the contract owner
     */
    function setVariableFees(uint256 _govFee, uint256 _daoFee)
        public
        onlyOwner
    {
        govFee = _govFee;
        daoFee = _daoFee;
    }

    /*
     * @title Update the Platform fixed Fees. These fees are in USDT value.
     * @param Allocated for DAO or Governance
     * @param ResourcesFees. A list of 8 item that includes fee per resource. Available resources and their order -> resourceVar(id) (1-8)
     * @dev Could only be invoked by the contract owner
     */

    function setFixedFees(
        string memory allocatedFor,
        ResourceFees memory resourceUnits
    ) public onlyOwner {
        ResourceFees storage resourcefees = fixedResourceFee[allocatedFor];
        resourcefees.resourceOneUnitsFee = resourceUnits.resourceOneUnitsFee;
        resourcefees.resourceTwoUnitsFee = resourceUnits.resourceTwoUnitsFee;
        resourcefees.resourceThreeUnitsFee = resourceUnits
        .resourceThreeUnitsFee;
        resourcefees.resourceFourUnitsFee = resourceUnits.resourceFourUnitsFee;
        resourcefees.resourceFiveUnitsFee = resourceUnits.resourceFiveUnitsFee;
        resourcefees.resourceSixUnitsFee = resourceUnits.resourceSixUnitsFee;
        resourcefees.resourceSevenUnitsFee = resourceUnits
        .resourceSevenUnitsFee;
        resourcefees.resourceEightUnitsFee = resourceUnits
        .resourceEightUnitsFee;
    }

    /*
     * @title Update the Platform fee receiver address
     * @param DAO address
     * @param Governance address
     * @dev Could only be invoked by the contract owner
     */

    function setFeeAddress(address _daoAddress, address _govAddress)
        public
        onlyOwner
    {
        dao = _daoAddress;
        gov = _govAddress;
    }

    /*
     * @title Update the Platform Minimum
     * @param Minimum resource purchaise amount.
     * @dev Could only be invoked by the contract owner
     */

    function setMinPurchase(uint256 minStackAmount) public onlyOwner {
        minPurchase = minStackAmount;
    }

    /*
     * @title Withdraw a depositer funds
     * @param Depositer Address
     * @param ClusterDNS that is being settled
     * @dev Could only be invoked by the contract owner
     */
    function withdrawFundsAdmin(address depositer, bytes32 clusterDns)
        public
        onlyOwner
    {
        _settleAndWithdraw(depositer, clusterDns, 0, true);
    }

    /*
     * @title Settle Depositer Account
     * @param Depositer Address
     * @param ClusterDNS that is being settled
     */

    function settleAccounts(address depositer, bytes32 clusterDns) public {
        uint256 utilisedFunds;
        Deposit storage deposit = deposits[depositer][clusterDns];
        uint256 elapsedTime = block.timestamp - deposit.lastTxTime;
        deposit.lastTxTime = block.timestamp;

        (
            address clusterOwner,
            ,
            ,
            ,
            ,
            ,
            uint256 qualityFactor,

        ) = IDnsClusterMetadataStore(dnsStore).dnsToClusterMetadata(clusterDns);

        uint256 MaxPossibleElapsedTime = deposit.totalDeposit /
            IPriceOracle(oracle).usdtToSTACKOracle(
                deposit.totalDripRatePerSecond
            );

        if (elapsedTime > MaxPossibleElapsedTime) {
            elapsedTime = MaxPossibleElapsedTime;
            utilisedFunds = deposit.totalDeposit;
        } else {
            utilisedFunds = elapsedTime * deposit.totalDripRatePerSecond;
            utilisedFunds = IPriceOracle(oracle).usdtToSTACKOracle(
                utilisedFunds
            );
        }

        // Add fees to utilised funds.
        uint256 fixAndVarDaoGovFee = _AddFixedFeesAndDeduct(
            utilisedFunds,
            elapsedTime,
            deposit
        );

        utilisedFunds = utilisedFunds + fixAndVarDaoGovFee;
        if (deposit.notWithdrawable > 0) {
            deposit.notWithdrawable = deposit.notWithdrawable - utilisedFunds;
        }
        if (utilisedFunds >= deposit.totalDeposit) {
            utilisedFunds = deposit.totalDeposit - fixAndVarDaoGovFee;
            reduceClusterCap(clusterDns, depositer);
            delete deposits[depositer][clusterDns];
            removeClusterAddresConnection(
                clusterDns,
                findAddressIndex(clusterDns, depositer)
            );
        } else {
            deposit.totalDeposit = deposit.totalDeposit - utilisedFunds;
            utilisedFunds = utilisedFunds - fixAndVarDaoGovFee;
        }

        _withdraw(utilisedFunds, 0, depositer, clusterOwner, qualityFactor);
    }

    function reduceClusterCap(bytes32 clusterDns, address depositer) internal {
        if (resourceCapacityState[clusterDns].resourceOne > 0)
            resourceCapacityState[clusterDns]
            .resourceOne = resourceCapacityState[clusterDns].resourceOne.sub(
                deposits[depositer][clusterDns].resourceOneUnits
            );
        if (resourceCapacityState[clusterDns].resourceTwo > 0)
            resourceCapacityState[clusterDns]
            .resourceTwo = resourceCapacityState[clusterDns].resourceTwo.sub(
                deposits[depositer][clusterDns].resourceTwoUnits
            );
        if (resourceCapacityState[clusterDns].resourceThree > 0)
            resourceCapacityState[clusterDns]
            .resourceThree = resourceCapacityState[clusterDns]
            .resourceThree
            .sub(deposits[depositer][clusterDns].resourceThreeUnits);
        if (resourceCapacityState[clusterDns].resourceFour > 0)
            resourceCapacityState[clusterDns]
            .resourceFour = resourceCapacityState[clusterDns].resourceFour.sub(
                deposits[depositer][clusterDns].resourceFourUnits
            );
        if (resourceCapacityState[clusterDns].resourceFive > 0)
            resourceCapacityState[clusterDns]
            .resourceFive = resourceCapacityState[clusterDns].resourceFive.sub(
                deposits[depositer][clusterDns].resourceFiveUnits
            );
        if (resourceCapacityState[clusterDns].resourceSix > 0)
            resourceCapacityState[clusterDns]
            .resourceSix = resourceCapacityState[clusterDns].resourceSix.sub(
                deposits[depositer][clusterDns].resourceSixUnits
            );
        if (resourceCapacityState[clusterDns].resourceSeven > 0)
            resourceCapacityState[clusterDns]
            .resourceSeven = resourceCapacityState[clusterDns]
            .resourceSeven
            .sub(deposits[depositer][clusterDns].resourceSevenUnits);
        if (resourceCapacityState[clusterDns].resourceEight > 0)
            resourceCapacityState[clusterDns]
            .resourceEight = resourceCapacityState[clusterDns]
            .resourceEight
            .sub(deposits[depositer][clusterDns].resourceEightUnits);
    }

    /*
     * @title Deduct Fixed and Variable Fees
     * @param Utilised funds in stack
     * @param Time since the last deposit or settelment
     * @param Resource Units.
     * @dev Part of the settelmet functions
     */

    function _AddFixedFeesAndDeduct(
        uint256 utilisedFunds,
        uint256 timeelapsed,
        Deposit memory resourceUnits
    ) internal returns (uint256) {
        uint256 daoFeesFixed = _getFixedFee(resourceUnits, timeelapsed, "dao");
        uint256 govFeesFixed = _getFixedFee(resourceUnits, timeelapsed, "gov");

        (uint256 variableDaoFee, uint256 variableGovFee) = _AddVariablesFees(
            utilisedFunds
        );

        if (daoFeesFixed > 0)
            IERC20(stackToken).transfer(dao, (daoFeesFixed + variableDaoFee));
        if (govFeesFixed > 0)
            IERC20(stackToken).transfer(gov, (govFeesFixed + variableGovFee));
        return
            (daoFeesFixed + variableDaoFee) + (govFeesFixed + variableGovFee);
    }

    /*
     * @title Part of AddFixedFeesAndDeduct
     * @param Utilised funds in stack
     * @dev Part of the settelmet functions
     * @return Variable fees for dao and gov
     */

    function _AddVariablesFees(uint256 utilisedFunds)
        internal
        view
        returns (uint256, uint256)
    {
        // Settle Dao and Gov
        uint256 forDao = (utilisedFunds * daoFee) / 10000;
        uint256 forGov = (utilisedFunds * govFee) / 10000;

        return (forDao, forGov);
    }

    function _getFixedFee(
        Deposit memory resourceUnits,
        uint256 timeelapsed,
        string memory govOrDao
    ) internal view returns (uint256) {
        ResourceFees storage fixedFees = fixedResourceFee[govOrDao];
        return
            _calculateFixedFee(
                resourceUnits.resourceOneUnits,
                fixedFees.resourceOneUnitsFee,
                timeelapsed
            ) +
            _calculateFixedFee(
                resourceUnits.resourceOneUnits,
                fixedFees.resourceOneUnitsFee,
                timeelapsed
            ) +
            _calculateFixedFee(
                resourceUnits.resourceTwoUnits,
                fixedFees.resourceTwoUnitsFee,
                timeelapsed
            ) +
            _calculateFixedFee(
                resourceUnits.resourceThreeUnits,
                fixedFees.resourceThreeUnitsFee,
                timeelapsed
            ) +
            _calculateFixedFee(
                resourceUnits.resourceFourUnits,
                fixedFees.resourceFourUnitsFee,
                timeelapsed
            ) +
            _calculateFixedFee(
                resourceUnits.resourceFiveUnits,
                fixedFees.resourceFiveUnitsFee,
                timeelapsed
            ) +
            _calculateFixedFee(
                resourceUnits.resourceSixUnits,
                fixedFees.resourceSixUnitsFee,
                timeelapsed
            ) +
            _calculateFixedFee(
                resourceUnits.resourceSevenUnits,
                fixedFees.resourceSevenUnitsFee,
                timeelapsed
            ) +
            _calculateFixedFee(
                resourceUnits.resourceEightUnits,
                fixedFees.resourceEightUnitsFee,
                timeelapsed
            );
    }

    function _calculateFixedFee(
        uint256 resourceUnit,
        uint256 FixedFeesForUnit,
        uint256 timeElapsed
    ) internal pure returns (uint256) {
        if (resourceUnit > 0) {
            return (resourceUnit * FixedFeesForUnit * timeElapsed);
        } else {
            return 0;
        }
    }

    /*
     * @title Deposit Stack to start using the cluster
     * @param Cluster DNS
     * @param ResourcesFees. A list of 8 item that includes fee per resource. Available resources and their order -> resourceVar(id) (1-8)
     * @param Amount of Stack to Deposit to use these recources.
     * @param The address of resource buyer.
     * @param is it withdrawable
     * @param Is it a grant
     * @dev Part of the settelmet functions
     */

    function _createDepositInternal(
        bytes32 clusterDns,
        ResourceUnits memory resourceUnits,
        uint256 depositAmount,
        address depositer,
        bool withdrawable,
        bool grant
    ) internal {
        (, , , , , , , bool active) = IDnsClusterMetadataStore(dnsStore)
        .dnsToClusterMetadata(clusterDns);
        require(active == true);

        Deposit storage deposit = deposits[depositer][clusterDns];

        _capacityCheck(clusterDns, resourceUnits);

        deposit.lastTxTime = block.timestamp;
        deposit.resourceOneUnits = resourceUnits.resourceOne; //CPU
        deposit.resourceTwoUnits = resourceUnits.resourceTwo; // diskSpaceUnits
        deposit.resourceThreeUnits = resourceUnits.resourceThree; // bandwidthUnits
        deposit.resourceFourUnits = resourceUnits.resourceFour; // memoryUnits
        deposit.resourceFiveUnits = resourceUnits.resourceFive;
        deposit.resourceSixUnits = resourceUnits.resourceSix;
        deposit.resourceSevenUnits = resourceUnits.resourceSeven;
        deposit.resourceEightUnits = resourceUnits.resourceEight;

        deposit.totalDripRatePerSecond = getResourcesDripRateInUSDT(
            clusterDns,
            resourceUnits
        );

        addClusterAddresConnection(clusterDns, depositer);
        if (grant == false) _pullStackTokens(depositAmount);
        if (withdrawable == false) {
            deposit.notWithdrawable = depositAmount;
        }
        deposit.totalDeposit = deposit.totalDeposit + depositAmount;
    }

    function _capacityCheck(
        bytes32 clusterDns,
        ResourceUnits memory resourceUnits
    ) internal {
        resourceCapacityState[clusterDns].resourceOne =
            resourceCapacityState[clusterDns].resourceOne +
            resourceUnits.resourceOne;
        resourceCapacityState[clusterDns].resourceTwo =
            resourceCapacityState[clusterDns].resourceTwo +
            resourceUnits.resourceTwo;
        resourceCapacityState[clusterDns].resourceThree =
            resourceCapacityState[clusterDns].resourceThree +
            resourceUnits.resourceThree;
        resourceCapacityState[clusterDns].resourceFour =
            resourceCapacityState[clusterDns].resourceFour +
            resourceUnits.resourceFour;
        resourceCapacityState[clusterDns].resourceFive =
            resourceCapacityState[clusterDns].resourceFive +
            resourceUnits.resourceFive;
        resourceCapacityState[clusterDns].resourceSix =
            resourceCapacityState[clusterDns].resourceSix +
            resourceUnits.resourceSix;
        resourceCapacityState[clusterDns].resourceSeven =
            resourceCapacityState[clusterDns].resourceSeven +
            resourceUnits.resourceSeven;
        resourceCapacityState[clusterDns].resourceEight =
            resourceCapacityState[clusterDns].resourceEight +
            resourceUnits.resourceEight;

        bool OverLimit = false;
        if (
            resourceUnits.resourceOne > 1 &&
            resourceUnits.resourceOne >
            IResourceFeed(resourceFeed)
            .getResourceMaxCapacity(clusterDns)
            .resourceOneUnits
        ) OverLimit = true;
        if (
            resourceUnits.resourceTwo > 1 &&
            resourceUnits.resourceTwo >
            IResourceFeed(resourceFeed)
            .getResourceMaxCapacity(clusterDns)
            .resourceTwoUnits
        ) OverLimit = true;
        if (
            resourceUnits.resourceThree > 1 &&
            resourceUnits.resourceThree >
            IResourceFeed(resourceFeed)
            .getResourceMaxCapacity(clusterDns)
            .resourceThreeUnits
        ) OverLimit = true;
        if (
            resourceUnits.resourceFour > 1 &&
            resourceUnits.resourceFour >
            IResourceFeed(resourceFeed)
            .getResourceMaxCapacity(clusterDns)
            .resourceFourUnits
        ) OverLimit = true;
        if (
            resourceUnits.resourceFive > 1 &&
            resourceUnits.resourceFive >
            IResourceFeed(resourceFeed)
            .getResourceMaxCapacity(clusterDns)
            .resourceFiveUnits
        ) OverLimit = true;
        if (
            resourceUnits.resourceSix > 1 &&
            resourceUnits.resourceSix >
            IResourceFeed(resourceFeed)
            .getResourceMaxCapacity(clusterDns)
            .resourceSixUnits
        ) OverLimit = true;
        if (
            resourceUnits.resourceSeven > 1 &&
            resourceUnits.resourceSeven >
            IResourceFeed(resourceFeed)
            .getResourceMaxCapacity(clusterDns)
            .resourceSevenUnits
        ) OverLimit = true;
        if (
            resourceUnits.resourceEight > 1 &&
            resourceUnits.resourceEight >
            IResourceFeed(resourceFeed)
            .getResourceMaxCapacity(clusterDns)
            .resourceEightUnits
        ) OverLimit = true;
        require(OverLimit == false);
    }

    function _rechargeAccountInternal(
        uint256 amount,
        address depositer,
        bytes32 clusterDns,
        bool withdrawable,
        bool grant
    ) internal {
        Deposit storage deposit = deposits[depositer][clusterDns];
        deposit.totalDeposit = deposit.totalDeposit + amount;
        // If fund's given though grant, make them not withdrawable.
        if (withdrawable == false) {
            deposit.notWithdrawable = deposit.notWithdrawable + amount;
        }
        if (grant == false) _pullStackTokens(amount);
    }

    function _settleAndWithdraw(
        address depositer,
        bytes32 clusterDns,
        uint256 amount,
        bool everything
    ) internal {
        uint256 withdrawAmount;
        settleAccounts(depositer, clusterDns);
        Deposit storage deposit = deposits[depositer][clusterDns];
        require(deposit.totalDeposit.sub(deposit.notWithdrawable) > amount);
        (
            address clusterOwner,
            ,
            ,
            ,
            ,
            ,
            uint256 qualityFactor,

        ) = IDnsClusterMetadataStore(dnsStore).dnsToClusterMetadata(clusterDns);
        if (everything == false) {
            require(amount < deposit.totalDeposit);
            deposit.totalDeposit = deposit.totalDeposit - amount;
            withdrawAmount = amount;
        } else {
            withdrawAmount = deposit.totalDeposit.sub(deposit.notWithdrawable);

            if (deposit.notWithdrawable == 0) {
                delete deposits[depositer][clusterDns];
                removeClusterAddresConnection(
                    clusterDns,
                    findAddressIndex(clusterDns, depositer)
                );
            } else {
                deposit.totalDeposit = deposit.totalDeposit.sub(withdrawAmount);
            }
        }

        _withdraw(0, withdrawAmount, depositer, clusterOwner, qualityFactor);
    }

    /*
     * @title Settle multiple accounts in one transaction
     * @param Cluster DNS
     * @param amount of accounts to settle.
     */

    function settleMultipleAccounts(bytes32 clusterDns, uint256 nrOfAccounts)
        public
    {
        for (uint256 i = nrOfAccounts; i > 0; i--) {
            settleAccounts(clusterUsers[clusterDns][i - 1], clusterDns);
        }
    }

    /*
     * @title Find the index for ClusterDNS => Address link
     * @param Cluster DNS
     * @param Depositer Address
     * @dev Part of the settelmet function
     */

    function findAddressIndex(bytes32 clusterDns, address _address)
        internal
        view
        returns (uint256)
    {
        for (uint256 i; i < clusterUsers[clusterDns].length; i++) {
            if (clusterUsers[clusterDns][i] == _address) {
                return i;
            }
        }
    }

    /*
     * @title Remove link between ClusterDNS => Address
     * @param Cluster DNS
     * @param List index
     * @dev Part of the settelmet function
     */

    function removeClusterAddresConnection(bytes32 clusterDns, uint256 index)
        internal
    {
        for (uint256 a = index; a < clusterUsers[clusterDns].length - 1; a++) {
            clusterUsers[clusterDns][a] = clusterUsers[clusterDns][a + 1];
        }
        clusterUsers[clusterDns].pop();
    }

    /*
     * @title Create link between ClusterDNS => Address
     * @param Cluster DNS
     * @param Deployer wallet address
     * @dev Part of deposit function
     */

    function addClusterAddresConnection(bytes32 clusterDns, address _address)
        internal
    {
        clusterUsers[clusterDns].push(_address);
    }

    /*
     * @title Create link between ClusterDNS => Address
     * @param Cluster DNS
     * @param Deployer wallet address
     * @dev Part of deposit function
     */

    function _calcResourceUnitsDripRateUSDT(
        bytes32 clusterDns,
        string memory resourceName,
        uint256 resourceUnits
    ) internal view returns (uint256) {
        uint256 dripRatePerUnit = IResourceFeed(resourceFeed)
        .getResourceDripRateUSDT(clusterDns, resourceName);
        return dripRatePerUnit * resourceUnits;
    }

    function _calcResourceUnitsDripRateSTACK(
        bytes32 clusterDns,
        string memory resourceName,
        uint256 resourceUnits
    ) internal view returns (uint256) {
        uint256 dripRatePerUnit = IResourceFeed(resourceFeed)
        .getResourceDripRateUSDT(clusterDns, resourceName);
        return usdtToSTACK(dripRatePerUnit * resourceUnits);
    }

    function _pullStackTokens(uint256 amount) internal {
        IERC20(stackToken).transferFrom(msg.sender, address(this), amount);
    }

    function _getQuote(
        uint256 _amountIn,
        address _fromTokenAddress,
        address _toTokenAddress
    ) internal view returns (uint256 amountOut) {
        address pair = IUniswapV2Factory(factory).getPair(
            _fromTokenAddress,
            _toTokenAddress
        );
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair)
        .getReserves();
        address token0 = IUniswapV2Pair(pair).token0();
        (uint256 reserveIn, uint256 reserveOut) = token0 == _fromTokenAddress
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        uint256 amountInWithFee = _amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = (numerator / denominator);
    }

    function stackToUSDT(uint256 _stackAmount)
        public
        view
        returns (uint256 USDVALUE)
    {
        uint256 ETHVALUE = _getQuote(_stackAmount, stackToken, weth);
        USDVALUE = _getQuote(ETHVALUE, weth, usdt);
    }

    function usdtToSTACK(uint256 _usdtAmount)
        public
        view
        returns (uint256 STACKVALUE)
    {
        uint256 ETHVALUE = _getQuote(_usdtAmount, usdt, weth);
        STACKVALUE = _getQuote(ETHVALUE, weth, stackToken);
    }

    function stackToTokenRate(address _token, uint256 _stackAmount)
        public
        view
        returns (uint256 TOKENVALUE)
    {
        uint256 ETHVALUE = _getQuote(_stackAmount, stackToken, weth);
        TOKENVALUE = _getQuote(ETHVALUE, weth, _token);
    }

    function _withdraw(
        uint256 utilisedFunds,
        uint256 withdrawAmount,
        address depositer,
        address clusterOwner,
        uint256 qualityFactor
    ) internal {
        // Check the quality Facror and reduce a portion of payout if necessery.
        uint256 utilisedFundsAfterQualityCheck = (qualityFactor *
            (10**18) *
            utilisedFunds) /
            100 /
            (10**18);

        if (utilisedFundsAfterQualityCheck > 0) {
            WithdrawSetting storage withdrawsetup = withdrawSettings[
                clusterOwner
            ];
            if (withdrawsetup.percent > 0) {
                uint256 stacktoToken = (utilisedFundsAfterQualityCheck *
                    withdrawsetup.percent) / 10000;
                uint256 stackWithdraw = utilisedFundsAfterQualityCheck -
                    stacktoToken;

                IERC20(stackToken).approve(
                    address(router),
                    999999999999999999999999999999
                );
                _swapTokens(
                    stackToken,
                    withdrawsetup.token,
                    stacktoToken,
                    stackToTokenRate(withdrawsetup.token, stacktoToken),
                    clusterOwner
                );
                IERC20(stackToken).transfer(clusterOwner, stackWithdraw);
            } else {
                IERC20(stackToken).transfer(
                    clusterOwner,
                    utilisedFundsAfterQualityCheck
                );
            }

            uint256 penalty = utilisedFunds - utilisedFundsAfterQualityCheck;
            if (penalty > 0) {
                IERC20(stackToken).transfer(dao, penalty);
            }
        }

        if (withdrawAmount > 0) {
            IERC20(stackToken).transfer(depositer, withdrawAmount);
        }
    }

    function _swapTokens(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 amountOutMin,
        uint256 amountInMax,
        address forWallet
    ) internal returns (uint256 tokenBought) {
        address[] memory path = new address[](3);
        path[0] = _FromTokenContractAddress;
        path[1] = weth;
        path[2] = _ToTokenContractAddress;

        tokenBought = IUniswapV2Router02(router).swapExactTokensForTokens(
            amountOutMin,
            amountInMax,
            path,
            forWallet,
            block.timestamp + 1200
        )[path.length - 1];
    }

    /*
     * @title Define Recource Strings
     * @param Resource ID from 1 to 8
     * @param Name of the resource.
     */

    function defineResourceVar(uint16 resouceNr, string memory resourceName)
        public
        onlyOwner
    {
        resourceVar[resouceNr] = resourceName;
    }

    /*
     * @title Fetches the cummulative dripRate of Resources
     * @param ResourcesFees. A list of 8 item that includes fee per resource. Available resources and their order -> resourceVar(id) (1-8)
     * @return Total resources drip rate measured in USDT
     */
    function getResourcesDripRateInUSDT(
        bytes32 clusterDns,
        ResourceUnits memory resourceUnits
    ) public view returns (uint256) {
        uint256 amountInUSDT = _calcResourceUnitsDripRateUSDT(
            clusterDns,
            resourceVar[1],
            resourceUnits.resourceOne
        ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[2],
                resourceUnits.resourceTwo
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[3],
                resourceUnits.resourceThree
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[4],
                resourceUnits.resourceFour
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[5],
                resourceUnits.resourceFive
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[6],
                resourceUnits.resourceSix
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[7],
                resourceUnits.resourceSeven
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[8],
                resourceUnits.resourceEight
            );
        return amountInUSDT;
    }
}

pragma solidity ^0.6.12;
import "./uniswap/IUniswapV2Factory.sol";
import "./uniswap/IUniswapV2Router02.sol";

contract EscrowStorage {
    address public stackToken;
    address public resourceFeed;
    address public staking;
    address public dao;
    address public gov;
    uint256 public govFee;
    uint256 public daoFee;
    uint256 public communityDeposits;
    address public dnsStore;
    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    address internal weth;
    address internal usdt;
    address internal oracle;
    uint256 internal minPurchase;

    struct ResourceFees {
        uint256 resourceOneUnitsFee; // cpuCoresUnits
        uint256 resourceTwoUnitsFee; // diskSpaceUnits
        uint256 resourceThreeUnitsFee; // bandwidthUnits
        uint256 resourceFourUnitsFee; // memoryUnits
        uint256 resourceFiveUnitsFee;
        uint256 resourceSixUnitsFee;
        uint256 resourceSevenUnitsFee;
        uint256 resourceEightUnitsFee;
    }

    // Address of Token contract.
    // What percentage is exchanged to this token on withdrawl.
    struct WithdrawSetting {
        address token;
        uint256 percent;
    }

    struct ResourceUnits {
        uint256 resourceOne; // cpuCoresUnits
        uint256 resourceTwo; // diskSpaceUnits
        uint256 resourceThree; // bandwidthUnits
        uint256 resourceFour; // memoryUnits
        uint256 resourceFive;
        uint256 resourceSix;
        uint256 resourceSeven;
        uint256 resourceEight;
    }

    struct Deposit {
        uint256 resourceOneUnits; // cpuCoresUnits
        uint256 resourceTwoUnits; // diskSpaceUnits
        uint256 resourceThreeUnits; // bandwidthUnits
        uint256 resourceFourUnits; // memoryUnits
        uint256 resourceFiveUnits;
        uint256 resourceSixUnits;
        uint256 resourceSevenUnits;
        uint256 resourceEightUnits;
        uint256 totalDeposit;
        uint256 lastTxTime;
        uint256 totalDripRatePerSecond;
        uint256 notWithdrawable;
    }

    mapping(uint16 => string) public resourceVar;
    mapping(bytes32 => ResourceUnits) public resourceCapacityState;
    mapping(string => ResourceFees) public fixedResourceFee;
    mapping(address => WithdrawSetting) internal withdrawSettings;
    mapping(address => mapping(bytes32 => Deposit)) public deposits;
    mapping(bytes32 => address[]) public clusterUsers;
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "./BaseEscrow.sol";

// /// @title StackEscrow is derived from the BaseEscrow Contract
// /// @notice Major contract responsible for user to purchase or update StackOS's resources from Stack Token
contract StackEscrow is BaseEscrow {
    /*
     * @dev - constructor (being called at contract deployment)
     * @param Address of stackToken deployed contract
     * @param Address of ResourceFeed deployed contract
     * @param Address of Staking deployed contract
     * @param Address of DnsClusterMetadataStore deployed contract
     * @param Factory Contract of DEX
     * @param Router Contract of DEX
     * @param DAO Address
     * @param Governance Address
     * @param WETH Contract Address
     * @param USDT Contract Address
     * @param Oracle Contract Address
     */
    constructor(
        address _stackToken,
        address _resourceFeed,
        address _staking,
        address _dnsStore,
        IUniswapV2Factory _factory,
        IUniswapV2Router02 _router,
        address _dao,
        address _gov,
        address _weth,
        address _usdt,
        address _oracle
    )
        public
        BaseEscrow(
            _stackToken,
            _resourceFeed,
            _staking,
            _dnsStore,
            _factory,
            _router,
            _dao,
            _gov,
            _weth,
            _usdt,
            _oracle
        )
    {
        stackToken = _stackToken;
    }

    /*
     * @title Update the user's resources from STACK token
     * @param DNS Cluster
     * @param Resources being boight. A list of 8 item. List of available resources and their order -> resourceVar(id) (1-8)
     * @dev User should have the Amount of Stack Token in his wallet that will be used for the resources he/she is accesseing
     */
    function updateResourcesFromStack(
        bytes32 clusterDns,
        ResourceUnits memory resourceUnits,
        uint256 depositAmount
    ) public {
        {
            Deposit storage deposit = deposits[msg.sender][clusterDns];
            if (deposit.lastTxTime > 0) {
                settleAccounts(msg.sender, clusterDns);
                reduceClusterCap(clusterDns, msg.sender);
            } else {
                require(minPurchase >= 0);
            }
        }

        _createDepositInternal(
            clusterDns,
            resourceUnits,
            depositAmount,
            msg.sender,
            true,
            false
        );
    }

    /*
     * @title Cluster Owner send a rebate in stack tokens to developers
     * @param Amount of Stack
     * @param Address for whom the rebate is being done
     * @param ClusterDNS to whom the rebate will be credited
     * @param Specify if the funds are withdrawable
     */

    function rebateAccount(
        uint256 amount,
        address account,
        bytes32 clusterDns,
        bool withdrawable
    ) public {
        address clusterOwner = IDnsClusterMetadataStore(dnsStore)
        .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender);
        _rechargeAccountInternal(
            amount,
            account,
            clusterDns,
            withdrawable,
            false
        );
    }

    /*
     * @title Fetches the cummulative dripRate of Resources in STACK
     * @param Resources being boight. A list of 8 item. List of available resources and their order -> resourceVar(id) (1-8)
     * @return Total resources drip rate measured in STACK
     * @param Cluster DNS that will be checked for prices.
     */
    function getResourcesDripRateInSTACK(
        bytes32 clusterDns,
        ResourceUnits memory resourceUnits
    ) public view returns (uint256) {
        uint256 amountInUSDT = getResourcesDripRateInUSDT(
            clusterDns,
            resourceUnits
        );
        uint256 amountInSTACK = usdtToSTACK(amountInUSDT);
        return amountInSTACK;
    }

    /*
     * @title TopUp the user's Account with input Amount
     * @param Amount of Stack Token to TopUp the account with
     * @param Cluster DNS where the balance will be added to.
     */
    function rechargeAccount(uint256 amount, bytes32 clusterDns) public {
        _rechargeAccountInternal(amount, msg.sender, clusterDns, true, false);
    }

    /*
     * @title Withdraw user total deposited Funds & settles his pending balances
     */
    function withdrawFunds(bytes32 clusterDns) public {
        _settleAndWithdraw(msg.sender, clusterDns, 0, true);
    }

    /*
     * @title Set portion and token that will be recived when settelment happens that is not stack.
     * @param Address of Token user wants to receive.
     * @param Porton of token in relation to stack in %
     */

    function setWithdrawTokenPortion(address token, uint256 percent) public {
        require(percent <= 10000);
        WithdrawSetting storage withdrawsetup = withdrawSettings[msg.sender];
        withdrawsetup.token = token;
        withdrawsetup.percent = percent;
    }

    /*
     * @title Withdraw user deposited Funds partially
     * @param Amount of Stack Token user wants to withdraw
     * @param Cluster DNS where the withdraw should be done from
     */
    function withdrawFundsPartial(uint256 amount, bytes32 clusterDns) public {
        _settleAndWithdraw(msg.sender, clusterDns, amount, false);
    }

    /*
     * @title Contrubute Stack tokens for issuing grants
     * @param Amount of Stack
     */

    function communityDeposit(uint256 amount) public {
        _pullStackTokens(amount);
        communityDeposits = communityDeposits.add(amount);
    }

    /*
     * @title Issuing a grant to a new account
     * @param address of grant reciever
     * @param Amount of Stack issued as grant
     * @param Resources being boight. A list of 8 item. List of available resources and their order -> resourceVar(id) (1-8)
     */

    function issueGrantNewAccount(
        address developer,
        uint256 amount,
        bytes32 clusterDns,
        ResourceUnits memory resourceUnits
    ) public onlyOwner {
        require(amount <= communityDeposits);
        Deposit storage deposit = deposits[developer][clusterDns];
        require(deposit.lastTxTime == 0);
        require(deposit.totalDeposit == 0);
        require(amount > 0);
        communityDeposits = communityDeposits - amount;
        _createDepositInternal(
            clusterDns,
            resourceUnits,
            amount,
            developer,
            false,
            true
        );
    }

    /*
     * @title Issue a grant to an existing account.
     * @param Address of grant reciever
     * @param Amount of Stack issued as grant
     * @param ClusterDNS
     */

    function issueGrantRechargeAccount(
        address developer,
        uint256 amount,
        bytes32 clusterDns
    ) public onlyOwner {
        require(amount <= communityDeposits);
        communityDeposits = communityDeposits - amount;
        _rechargeAccountInternal(amount, developer, clusterDns, false, true);
    }
}

//SPDX-License-Identifier: 
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

//SPDX-License-Identifier: 
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

//SPDX-License-Identifier: 
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

//SPDX-License-Identifier: 
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.6.12;

interface IPriceOracle {
    function update(address tokenA, address tokenB) external virtual;

    function usdtToSTACKOracle(uint256 amountIn)
        external
        view
        virtual
        returns (uint256);
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IResourceFeed {
    struct ResourceCapacity {
        uint256 resourceOneUnits; // cpuCoresUnits
        uint256 resourceTwoUnits; // diskSpaceUnits
        uint256 resourceThreeUnits; // bandwidthUnits
        uint256 resourceFourUnits; // memoryUnits
        uint256 resourceFiveUnits;
        uint256 resourceSixUnits;
        uint256 resourceSevenUnits;
        uint256 resourceEightUnits;
    }

    function getResourcePriceUSDT(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function getResourceDripRateUSDT(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function getResourceVotingWeight(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function USDToken() external view returns (address);

    function getResourceMaxCapacity(bytes32 clusterDns)
        external
        returns (ResourceCapacity memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

