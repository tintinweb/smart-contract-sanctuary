/**
 *Submitted for verification at Etherscan.io on 2021-08-09
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
    }
}


contract Resolver is Helpers {

    function fetchEthPrice() public returns (uint) {
	    return priceFeedOracle.fetchPrice();
    }

    function getTrove(address[] memory owners) public returns (Trove[] memory troves) {
        troves = new Trove[](owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            address owner = owners[i];
            (uint debt, uint collateral, , ) = troveManager.getEntireDebtAndColl(owner);
            troves[i] = Trove(collateral, debt);
        }

    }
}

contract InstaLiquityPowerResolver is Resolver {
    string public constant name = "Liquity-Power-Resolver-v1";
}