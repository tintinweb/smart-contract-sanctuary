// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./interfaces/iERC20.sol";
import "./interfaces/iUTILS.sol";
import "./interfaces/iVADER.sol";
import "./interfaces/iROUTER.sol";
import "./interfaces/iPOOLS.sol";
import "./interfaces/iFACTORY.sol";
import "./interfaces/iSYNTH.sol";

contract Vault {
    bool private inited;
    uint256 public erasToEarn;
    uint256 public minGrantTime;
    uint256 public lastGranted;

    address public VADER;
    address public USDV;
    address public ROUTER;
    address public POOLS;
    address public FACTORY;

    uint256 public minimumDepositTime;
    uint256 public totalWeight;

    mapping(address => uint256) private mapMember_weight;
    mapping(address => mapping(address => uint256)) private mapMemberSynth_deposit;
    mapping(address => mapping(address => uint256)) private mapMemberSynth_lastTime;

    // Events
    event MemberDeposits(
        address indexed synth,
        address indexed member,
        uint256 amount,
        uint256 weight,
        uint256 totalWeight
    );
    event MemberWithdraws(
        address indexed synth,
        address indexed member,
        uint256 amount,
        uint256 weight,
        uint256 totalWeight
    );
    event MemberHarvests(
        address indexed synth,
        address indexed member,
        uint256 amount,
        uint256 weight,
        uint256 totalWeight
    );

    // Only DAO can execute
    modifier onlyDAO() {
        require(msg.sender == DAO(), "Not DAO");
        _;
    }

    constructor() {}

    function init(
        address _vader,
        address _usdv,
        address _router,
        address _factory,
        address _pool
    ) public {
        require(inited == false);
        inited = true;
        POOLS = _pool;
        VADER = _vader;
        USDV = _usdv;
        ROUTER = _router;
        FACTORY = _factory;
        POOLS = _pool;
        erasToEarn = 100;
        minimumDepositTime = 1;
        minGrantTime = 2592000; // 30 days
    }

    //=========================================DAO=========================================//
    // Can set params
    function setParams(
        uint256 newEra,
        uint256 newDepositTime,
        uint256 newGrantTime
    ) external onlyDAO {
        erasToEarn = newEra;
        minimumDepositTime = newDepositTime;
        minGrantTime = newGrantTime;
    }

    // Can issue grants
    function grant(address recipient, uint256 amount) public onlyDAO {
        require((block.timestamp - lastGranted) >= minGrantTime, "not too fast");
        lastGranted = block.timestamp;
        iERC20(USDV).transfer(recipient, amount);
    }

    //======================================DEPOSITS========================================//

    // Deposit USDV or SYNTHS
    function deposit(address synth, uint256 amount) external {
        depositForMember(synth, msg.sender, amount);
    }

    // Wrapper for contracts
    function depositForMember(
        address synth,
        address member,
        uint256 amount
    ) public {
        require((iFACTORY(FACTORY).isSynth(synth)), "Not Synth"); // Only Synths
        getFunds(synth, amount);
        _deposit(synth, member, amount);
    }

    function _deposit(
        address _synth,
        address _member,
        uint256 _amount
    ) internal {
        mapMemberSynth_lastTime[_member][_synth] = block.timestamp; // Time of deposit
        mapMemberSynth_deposit[_member][_synth] += _amount; // Record deposit
        uint256 _weight = iUTILS(UTILS()).calcValueInBase(iSYNTH(_synth).TOKEN(), _amount);
        if (iPOOLS(POOLS).isAnchor(iSYNTH(_synth).TOKEN())) {
            _weight = iROUTER(ROUTER).getUSDVAmount(_weight); // Price in USDV
        }
        mapMember_weight[_member] += _weight; // Total member weight
        totalWeight += _weight; // Total weight
        emit MemberDeposits(_synth, _member, _amount, _weight, totalWeight);
    }

    //====================================== HARVEST ========================================//

    // Harvest, get payment, allocate, increase weight
    function harvest(address synth) external returns (uint256 reward) {
        address _member = msg.sender;
        uint256 _weight;
        address _token = iSYNTH(synth).TOKEN();
        reward = calcCurrentReward(synth, _member); // In USDV
        mapMemberSynth_lastTime[_member][synth] = block.timestamp; // Reset time
        if (iPOOLS(POOLS).isAsset(_token)) {
            iERC20(USDV).transfer(POOLS, reward);
            reward = iPOOLS(POOLS).mintSynth(USDV, _token, address(this));
            _weight = iUTILS(UTILS()).calcValueInBase(_token, reward);
        } else {
            iERC20(VADER).transfer(POOLS, reward);
            reward = iPOOLS(POOLS).mintSynth(VADER, _token, address(this));
            _weight = iROUTER(ROUTER).getUSDVAmount(iUTILS(UTILS()).calcValueInBase(_token, reward));
        }
        mapMemberSynth_deposit[_member][synth] += reward;
        mapMember_weight[_member] += _weight;
        totalWeight += _weight;
        emit MemberHarvests(synth, _member, reward, _weight, totalWeight);
    }

    // Get the payment owed for a member
    function calcCurrentReward(address synth, address member) public view returns (uint256 reward) {
        uint256 _secondsSinceClaim = block.timestamp - mapMemberSynth_lastTime[member][synth]; // Get time since last claim
        uint256 _share = calcReward(synth, member); // Get share of rewards for member
        reward = (_share * _secondsSinceClaim) / iVADER(VADER).secondsPerEra(); // Get owed amount, based on per-day rates
        uint256 _reserve;
        if (iPOOLS(POOLS).isAsset(iSYNTH(synth).TOKEN())) {
            _reserve = reserveUSDV();
        } else {
            _reserve = reserveVADER();
        }
        if (reward >= _reserve) {
            reward = _reserve; // Send full reserve if the last
        }
    }

    function calcReward(address synth, address member) public view returns (uint256 reward) {
        uint256 _weight = mapMember_weight[member];
        if (iPOOLS(POOLS).isAsset(iSYNTH(synth).TOKEN())) {
            uint256 _adjustedReserve = iROUTER(ROUTER).getUSDVAmount(reserveVADER()) + reserveUSDV(); // Aggregrate reserves
            return iUTILS(UTILS()).calcShare(_weight, totalWeight, _adjustedReserve / erasToEarn); // Get member's share of that
        } else {
            uint256 _adjustedReserve = iROUTER(ROUTER).getUSDVAmount(reserveVADER()) + reserveUSDV();
            return iUTILS(UTILS()).calcShare(_weight, totalWeight, _adjustedReserve / erasToEarn);
        }
    }

    //====================================== WITHDRAW ========================================//

    // Members to withdraw
    function withdraw(address synth, uint256 basisPoints) external returns (uint256 redeemedAmount) {
        redeemedAmount = _processWithdraw(synth, msg.sender, basisPoints); // Get amount to withdraw
        sendFunds(synth, msg.sender, redeemedAmount);
    }

    function _processWithdraw(
        address _synth,
        address _member,
        uint256 _basisPoints
    ) internal returns (uint256 redeemedAmount) {
        require((block.timestamp - mapMemberSynth_lastTime[_member][_synth]) >= minimumDepositTime, "DepositTime"); // stops attacks
        redeemedAmount = iUTILS(UTILS()).calcPart(_basisPoints, mapMemberSynth_deposit[_member][_synth]); // Share of deposits
        mapMemberSynth_deposit[_member][_synth] -= redeemedAmount; // Reduce for member
        uint256 _weight = iUTILS(UTILS()).calcPart(_basisPoints, mapMember_weight[_member]); // Find recorded weight to reduce
        mapMember_weight[_member] -= _weight; // Reduce for member
        totalWeight -= _weight; // Reduce for total
        emit MemberWithdraws(_synth, _member, redeemedAmount, _weight, totalWeight); // Event
    }

    //============================== ASSETS ================================//

    function getFunds(address synth, uint256 amount) internal {
        if (tx.origin == msg.sender) {
            require(iERC20(synth).transferTo(address(this), amount));
        } else {
            require(iERC20(synth).transferFrom(msg.sender, address(this), amount));
        }
    }

    function sendFunds(
        address synth,
        address member,
        uint256 amount
    ) internal {
        require(iERC20(synth).transfer(member, amount));
    }

    //============================== HELPERS ================================//

    function reserveUSDV() public view returns (uint256) {
        return iERC20(USDV).balanceOf(address(this)); // Balance
    }

    function reserveVADER() public view returns (uint256) {
        return iERC20(VADER).balanceOf(address(this)); // Balance
    }

    function getMemberDeposit(address synth, address member) external view returns (uint256) {
        return mapMemberSynth_deposit[member][synth];
    }

    function getMemberWeight(address member) external view returns (uint256) {
        return mapMember_weight[member];
    }

    function getMemberLastTime(address synth, address member) external view returns (uint256) {
        return mapMemberSynth_lastTime[member][synth];
    }

    function DAO() public view returns (address) {
        return iVADER(VADER).DAO();
    }

    function UTILS() public view returns (address) {
        return iVADER(VADER).UTILS();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transferTo(address, uint256) external returns (bool);

    function burn(uint256) external;

    function burnFrom(address, uint256) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iFACTORY {
    function deploySynth(address) external returns (address);

    function mintSynth(
        address,
        address,
        uint256
    ) external returns (bool);

    function getSynth(address) external view returns (address);

    function isSynth(address) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iPOOLS {
    function pooledVADER() external view returns (uint256);

    function pooledUSDV() external view returns (uint256);

    function addLiquidity(
        address base,
        address token,
        address member
    ) external returns (uint256 liquidityUnits);

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints
    ) external returns (uint256 outputBase, uint256 outputToken);

    function sync(address token, address pool) external;

    function swap(
        address base,
        address token,
        address member,
        bool toBase
    ) external returns (uint256 outputAmount);

    function deploySynth(address token) external;

    function mintSynth(
        address base,
        address token,
        address member
    ) external returns (uint256 outputAmount);

    function burnSynth(
        address base,
        address token,
        address member
    ) external returns (uint256 outputBase);

    function syncSynth(address token) external;

    function lockUnits(
        uint256 units,
        address token,
        address member
    ) external;

    function unlockUnits(
        uint256 units,
        address token,
        address member
    ) external;

    function isMember(address member) external view returns (bool);

    function isAsset(address token) external view returns (bool);

    function isAnchor(address token) external view returns (bool);

    function getPoolAmounts(address token) external view returns (uint256, uint256);

    function getBaseAmount(address token) external view returns (uint256);

    function getTokenAmount(address token) external view returns (uint256);

    function getUnits(address token) external view returns (uint256);

    function getMemberUnits(address token, address member) external view returns (uint256);

    function getSynth(address token) external returns (address);

    function isSynth(address token) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iROUTER {
    function setParams(
        uint256 newFactor,
        uint256 newTime,
        uint256 newLimit
    ) external;

    function addLiquidity(
        address base,
        uint256 inputBase,
        address token,
        uint256 inputToken
    ) external returns (uint256);

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints
    ) external returns (uint256 amountBase, uint256 amountToken);

    function swap(
        uint256 inputAmount,
        address inputToken,
        address outputToken
    ) external returns (uint256 outputAmount);

    function swapWithLimit(
        uint256 inputAmount,
        address inputToken,
        address outputToken,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function swapWithSynths(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth
    ) external returns (uint256 outputAmount);

    function swapWithSynthsWithLimit(
        uint256 inputAmount,
        address inputToken,
        bool inSynth,
        address outputToken,
        bool outSynth,
        uint256 slipLimit
    ) external returns (uint256 outputAmount);

    function getILProtection(
        address member,
        address base,
        address token,
        uint256 basisPoints
    ) external view returns (uint256 protection);

    function curatePool(address token) external;

    function listAnchor(address token) external;

    function replacePool(address oldToken, address newToken) external;

    function updateAnchorPrice(address token) external;

    function getAnchorPrice() external view returns (uint256 anchorPrice);

    function getVADERAmount(uint256 USDVAmount) external view returns (uint256 vaderAmount);

    function getUSDVAmount(uint256 vaderAmount) external view returns (uint256 USDVAmount);

    function isCurated(address token) external view returns (bool curated);

    function reserveUSDV() external view returns (uint256);

    function reserveVADER() external view returns (uint256);

    function getMemberBaseDeposit(address member, address token) external view returns (uint256);

    function getMemberTokenDeposit(address member, address token) external view returns (uint256);

    function getMemberLastDeposit(address member, address token) external view returns (uint256);

    function getMemberCollateral(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getMemberDebt(
        address member,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256);

    function getSystemCollateral(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemDebt(address collateralAsset, address debtAsset) external view returns (uint256);

    function getSystemInterestPaid(address collateralAsset, address debtAsset) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iSYNTH {
    function mint(address account, uint256 amount) external;

    function TOKEN() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iUTILS {
    function getFeeOnTransfer(uint256 totalSupply, uint256 maxSupply) external pure returns (uint256);

    function assetChecks(address collateralAsset, address debtAsset) external;

    function isBase(address token) external view returns (bool base);

    function calcValueInBase(address token, uint256 amount) external view returns (uint256);

    function calcValueInToken(address token, uint256 amount) external view returns (uint256);

    function calcValueOfTokenInToken(
        address token1,
        uint256 amount,
        address token2
    ) external view returns (uint256);

    function calcSwapValueInBase(address token, uint256 amount) external view returns (uint256);

    function calcSwapValueInToken(address token, uint256 amount) external view returns (uint256);

    function requirePriceBounds(
        address token,
        uint256 bound,
        bool inside,
        uint256 targetPrice
    ) external view;

    function getRewardShare(address token, uint256 rewardReductionFactor) external view returns (uint256 rewardShare);

    function getReducedShare(uint256 amount) external view returns (uint256);

    function getProtection(
        address member,
        address token,
        uint256 basisPoints,
        uint256 timeForFullProtection
    ) external view returns (uint256 protection);

    function getCoverage(address member, address token) external view returns (uint256);

    function getCollateralValueInBase(
        address member,
        uint256 collateral,
        address collateralAsset,
        address debtAsset
    ) external returns (uint256 debt, uint256 baseValue);

    function getDebtValueInCollateral(
        address member,
        uint256 debt,
        address collateralAsset,
        address debtAsset
    ) external view returns (uint256, uint256);

    function getInterestOwed(
        address collateralAsset,
        address debtAsset,
        uint256 timeElapsed
    ) external returns (uint256 interestOwed);

    function getInterestPayment(address collateralAsset, address debtAsset) external view returns (uint256);

    function getDebtLoading(address collateralAsset, address debtAsset) external view returns (uint256);

    function calcPart(uint256 bp, uint256 total) external pure returns (uint256);

    function calcShare(
        uint256 part,
        uint256 total,
        uint256 amount
    ) external pure returns (uint256);

    function calcSwapOutput(
        uint256 x,
        uint256 X,
        uint256 Y
    ) external pure returns (uint256);

    function calcSwapFee(
        uint256 x,
        uint256 X,
        uint256 Y
    ) external pure returns (uint256);

    function calcSwapSlip(uint256 x, uint256 X) external pure returns (uint256);

    function calcLiquidityUnits(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T,
        uint256 P
    ) external view returns (uint256);

    function getSlipAdustment(
        uint256 b,
        uint256 B,
        uint256 t,
        uint256 T
    ) external view returns (uint256);

    function calcSynthUnits(
        uint256 b,
        uint256 B,
        uint256 P
    ) external view returns (uint256);

    function calcAsymmetricShare(
        uint256 u,
        uint256 U,
        uint256 A
    ) external pure returns (uint256);

    function calcCoverage(
        uint256 B0,
        uint256 T0,
        uint256 B1,
        uint256 T1
    ) external pure returns (uint256);

    function sortArray(uint256[] memory array) external pure returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

interface iVADER {
    function UTILS() external view returns (address);

    function DAO() external view returns (address);

    function emitting() external view returns (bool);

    function minting() external view returns (bool);

    function secondsPerEra() external view returns (uint256);

    function flipEmissions() external;

    function flipMinting() external;

    function setParams(uint256 newEra, uint256 newCurve) external;

    function setRewardAddress(address newAddress) external;

    function changeUTILS(address newUTILS) external;

    function changeDAO(address newDAO) external;

    function purgeDAO() external;

    function upgrade(uint256 amount) external;

    function redeem() external returns (uint256);

    function redeemToMember(address member) external returns (uint256);
}

