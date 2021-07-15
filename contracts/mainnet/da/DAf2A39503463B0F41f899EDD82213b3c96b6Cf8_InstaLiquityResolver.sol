/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface PriceFeedOracle {
	function fetchPrice() external returns (uint);
}

interface TroveManagerLike {
    function getBorrowingRateWithDecay() external view returns (uint);
    function getTCR(uint _price) external view returns (uint);
    function getCurrentICR(address _borrower, uint _price) external view returns (uint);
    function checkRecoveryMode(uint _price) external view returns (bool);
    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt, 
        uint coll, 
        uint pendingLUSDDebtReward, 
        uint pendingETHReward
    );
}

interface StabilityPoolLike {
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint);
    function getDepositorETHGain(address _depositor) external view returns (uint);
    function getDepositorLQTYGain(address _depositor) external view returns (uint);
}

interface StakingLike {
    function stakes(address owner) external view returns (uint);
    function getPendingETHGain(address _user) external view returns (uint);
    function getPendingLUSDGain(address _user) external view returns (uint);
}

interface PoolLike {
    function getETH() external view returns (uint);
}

interface HintHelpersLike {
    function computeNominalCR(uint _coll, uint _debt) external pure returns (uint);
    function computeCR(uint _coll, uint _debt, uint _price) external pure returns (uint);
    function getApproxHint(uint _CR, uint _numTrials, uint _inputRandomSeed) external view returns (
        address hintAddress,
        uint diff,
        uint latestRandomSeed
    );
    function getRedemptionHints(uint _LUSDamount, uint _price, uint _maxIterations) external view returns (
        address firstHint,
        uint partialRedemptionHintNICR,
        uint truncatedLUSDamount
    );
}

interface SortedTrovesLike {
    function getSize() external view returns (uint256);
    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}

contract Math {
    /* DSMath add */
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }
    
    /* DSMath mul */
    function mul(uint x, uint y) internal pure returns (uint z) {
                require(y == 0 || (z = x * y) / y == x, "math-not-safe");
        }

    /* Uniswap V2 sqrt */
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
            }
        }
}

contract Helpers is Math {
    TroveManagerLike internal constant troveManager =
        TroveManagerLike(0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4bb2);

    StabilityPoolLike internal constant stabilityPool = 
        StabilityPoolLike(0x66017D22b0f8556afDd19FC67041899Eb65a21bb);

    StakingLike internal constant staking =
        StakingLike(0x4f9Fbb3f1E99B56e0Fe2892e623Ed36A76Fc605d);

    PoolLike internal constant activePool =
        PoolLike(0xDf9Eb223bAFBE5c5271415C75aeCD68C21fE3D7F);
    
    PoolLike internal constant defaultPool =
        PoolLike(0x896a3F03176f05CFbb4f006BfCd8723F2B0D741C);

    HintHelpersLike internal constant hintHelpers =
        HintHelpersLike(0xE84251b93D9524E0d2e621Ba7dc7cb3579F997C0);
    
    SortedTrovesLike internal constant sortedTroves =
        SortedTrovesLike(0x8FdD3fbFEb32b28fb73555518f8b361bCeA741A6);

    PriceFeedOracle internal constant priceFeedOracle =
        PriceFeedOracle(0x4c517D4e2C851CA76d7eC94B805269Df0f2201De);

    struct Trove {
        uint collateral;
        uint debt;
        uint icr;
        uint256 price;
    }

    struct StabilityDeposit {
        uint deposit;
        uint ethGain;
        uint lqtyGain;
    }

    struct Stake {
        uint amount;
        uint ethGain;
        uint lusdGain;
    }

    struct Position {
        Trove trove;
        StabilityDeposit stability;
        Stake stake;
    }

    struct System {
        uint borrowFee;
        uint ethTvl;
        uint tcr;
        bool isInRecoveryMode;
        uint256 price;
    }
}


contract Resolver is Helpers {

    function fetchETHPrice() public returns (uint) {
	    return priceFeedOracle.fetchPrice();
    }

    function getTrove(address owner) public returns (Trove memory) {
	      uint oracleEthPrice = fetchETHPrice();
        (uint debt, uint collateral, , ) = troveManager.getEntireDebtAndColl(owner);
        uint icr = troveManager.getCurrentICR(owner, oracleEthPrice);
        return Trove(collateral, debt, icr, oracleEthPrice);
    }

    function getStabilityDeposit(address owner) public view returns (StabilityDeposit memory) {
        uint deposit = stabilityPool.getCompoundedLUSDDeposit(owner);
        uint ethGain = stabilityPool.getDepositorETHGain(owner);
        uint lqtyGain = stabilityPool.getDepositorLQTYGain(owner);
        return StabilityDeposit(deposit, ethGain, lqtyGain);
    }

    function getStake(address owner) public view returns (Stake memory) {
        uint amount = staking.stakes(owner);
        uint ethGain = staking.getPendingETHGain(owner);
        uint lusdGain = staking.getPendingLUSDGain(owner);
        return Stake(amount, ethGain, lusdGain);
    }

    function getPosition(address owner) external returns (Position memory) {
        Trove memory trove = getTrove(owner);
        StabilityDeposit memory stability = getStabilityDeposit(owner);
        Stake memory stake = getStake(owner);
        return Position(trove, stability, stake);
    }

    function getSystemState() external returns (System memory) {
	      uint oracleEthPrice = fetchETHPrice();
        uint borrowFee = troveManager.getBorrowingRateWithDecay();
        uint ethTvl = add(activePool.getETH(), defaultPool.getETH());
        uint tcr = troveManager.getTCR(oracleEthPrice);
        bool isInRecoveryMode = troveManager.checkRecoveryMode(oracleEthPrice);
        return System(borrowFee, ethTvl, tcr, isInRecoveryMode, oracleEthPrice);
    }

    function getTrovePositionHints(uint collateral, uint debt, uint searchIterations, uint randomSeed) external view returns (
        address upperHint,
        address lowerHint
    ) {
        // See: https://github.com/liquity/dev#supplying-hints-to-trove-operations
        uint nominalCr = hintHelpers.computeNominalCR(collateral, debt);
        searchIterations = searchIterations == 0 ? mul(10, sqrt(sortedTroves.getSize())) : searchIterations;
        randomSeed = randomSeed == 0 ? block.number : randomSeed;
        (address hintAddress, ,) = hintHelpers.getApproxHint(nominalCr, searchIterations, randomSeed);
        return sortedTroves.findInsertPosition(nominalCr, hintAddress, hintAddress);
    }

    function getRedemptionPositionHints(uint amount, uint searchIterations, uint randomSeed) external returns (
        uint partialHintNicr,
        address firstHint,
        address upperHint,
        address lowerHint,
        uint256 oracleEthPrice
    ) {
	    oracleEthPrice = fetchETHPrice();
        // See: https://github.com/liquity/dev#hints-for-redeemcollateral
        (firstHint, partialHintNicr, ) = hintHelpers.getRedemptionHints(amount, oracleEthPrice, 0);
        searchIterations = searchIterations == 0 ? mul(10, sqrt(sortedTroves.getSize())) : searchIterations;
        randomSeed = randomSeed == 0 ? block.number : randomSeed;
        (address hintAddress, ,) = hintHelpers.getApproxHint(partialHintNicr, searchIterations, randomSeed);
        (upperHint, lowerHint) = sortedTroves.findInsertPosition(partialHintNicr, hintAddress, hintAddress);
    }
}

contract InstaLiquityResolver is Resolver {
    string public constant name = "Liquity-Resolver-v1";
}