// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/iERC20.sol";
import "./interfaces/iUTILS.sol";
import "./interfaces/iVADER.sol";
import "./interfaces/iFACTORY.sol";

contract Pools {
    // Parameters
    bool private inited;
    uint256 public pooledVADER;
    uint256 public pooledUSDV;

    address public VADER;
    address public USDV;
    address public ROUTER;
    address public FACTORY;

    mapping(address => bool) _isMember;
    mapping(address => bool) _isAsset;
    mapping(address => bool) _isAnchor;

    mapping(address => uint256) public mapToken_Units;
    mapping(address => mapping(address => uint256)) public mapTokenMember_Units;
    mapping(address => uint256) public mapToken_baseAmount;
    mapping(address => uint256) public mapToken_tokenAmount;

    // Events
    event AddLiquidity(
        address indexed member,
        address indexed base,
        uint256 baseAmount,
        address indexed token,
        uint256 tokenAmount,
        uint256 liquidityUnits
    );
    event RemoveLiquidity(
        address indexed member,
        address indexed base,
        uint256 baseAmount,
        address indexed token,
        uint256 tokenAmount,
        uint256 liquidityUnits,
        uint256 totalUnits
    );
    event Swap(
        address indexed member,
        address indexed inputToken,
        uint256 inputAmount,
        address indexed outputToken,
        uint256 outputAmount,
        uint256 swapFee
    );
    event Sync(address indexed token, address indexed pool, uint256 addedAmount);
    event SynthSync(address indexed token, uint256 burntSynth, uint256 deletedUnits);

    //=====================================CREATION=========================================//
    // Constructor
    constructor() {}

    // Init
    function init(
        address _vader,
        address _usdv,
        address _router,
        address _factory
    ) public {
        require(inited == false);
        inited = true;
        VADER = _vader;
        USDV = _usdv;
        ROUTER = _router;
        FACTORY = _factory;
    }

    //====================================LIQUIDITY=========================================//

    function addLiquidity(
        address base,
        address token,
        address member
    ) external returns (uint256 liquidityUnits) {
        require(token != USDV && token != VADER); // Prohibited
        uint256 _actualInputBase;
        if (base == VADER) {
            if (!isAnchor(token)) {
                // If new Anchor
                _isAnchor[token] = true;
            }
            _actualInputBase = getAddedAmount(VADER, token);
        } else if (base == USDV) {
            if (!isAsset(token)) {
                // If new Asset
                _isAsset[token] = true;
            }
            _actualInputBase = getAddedAmount(USDV, token);
        }
        uint256 _actualInputToken = getAddedAmount(token, token);
        liquidityUnits = iUTILS(UTILS()).calcLiquidityUnits(
            _actualInputBase,
            mapToken_baseAmount[token],
            _actualInputToken,
            mapToken_tokenAmount[token],
            mapToken_Units[token]
        );
        mapTokenMember_Units[token][member] += liquidityUnits; // Add units to member
        mapToken_Units[token] += liquidityUnits; // Add in total
        mapToken_baseAmount[token] += _actualInputBase; // Add BASE
        mapToken_tokenAmount[token] += _actualInputToken; // Add token
        emit AddLiquidity(member, base, _actualInputBase, token, _actualInputToken, liquidityUnits);
    }

    function removeLiquidity(
        address base,
        address token,
        uint256 basisPoints
    ) external returns (uint256 outputBase, uint256 outputToken) {
        return _removeLiquidity(base, token, basisPoints, tx.origin); // Because this contract is wrapped by a router
    }

    function removeLiquidityDirectly(
        address base,
        address token,
        uint256 basisPoints
    ) external returns (uint256 outputBase, uint256 outputToken) {
        return _removeLiquidity(base, token, basisPoints, msg.sender); // If want to interact directly
    }

    function _removeLiquidity(
        address base,
        address token,
        uint256 basisPoints,
        address member
    ) internal returns (uint256 outputBase, uint256 outputToken) {
        require(base == USDV || base == VADER);
        uint256 _units = iUTILS(UTILS()).calcPart(basisPoints, mapTokenMember_Units[token][member]);
        outputBase = iUTILS(UTILS()).calcShare(_units, mapToken_Units[token], mapToken_baseAmount[token]);
        outputToken = iUTILS(UTILS()).calcShare(_units, mapToken_Units[token], mapToken_tokenAmount[token]);
        mapToken_Units[token] -= _units;
        mapTokenMember_Units[token][member] -= _units;
        mapToken_baseAmount[token] -= outputBase;
        mapToken_tokenAmount[token] -= outputToken;
        emit RemoveLiquidity(member, base, outputBase, token, outputToken, _units, mapToken_Units[token]);
        transferOut(base, outputBase, member);
        transferOut(token, outputToken, member);
        return (outputBase, outputToken);
    }

    //=======================================SWAP===========================================//

    // Designed to be called by a router, but can be called directly
    function swap(
        address base,
        address token,
        address member,
        bool toBase
    ) external returns (uint256 outputAmount) {
        if (toBase) {
            uint256 _actualInput = getAddedAmount(token, token);
            outputAmount = iUTILS(UTILS()).calcSwapOutput(
                _actualInput,
                mapToken_tokenAmount[token],
                mapToken_baseAmount[token]
            );
            uint256 _swapFee =
                iUTILS(UTILS()).calcSwapFee(_actualInput, mapToken_tokenAmount[token], mapToken_baseAmount[token]);
            mapToken_tokenAmount[token] += _actualInput;
            mapToken_baseAmount[token] -= outputAmount;
            emit Swap(member, token, _actualInput, base, outputAmount, _swapFee);
            transferOut(base, outputAmount, member);
        } else {
            uint256 _actualInput = getAddedAmount(base, token);
            outputAmount = iUTILS(UTILS()).calcSwapOutput(
                _actualInput,
                mapToken_baseAmount[token],
                mapToken_tokenAmount[token]
            );
            uint256 _swapFee =
                iUTILS(UTILS()).calcSwapFee(_actualInput, mapToken_baseAmount[token], mapToken_tokenAmount[token]);
            mapToken_baseAmount[token] += _actualInput;
            mapToken_tokenAmount[token] -= outputAmount;
            emit Swap(member, base, _actualInput, token, outputAmount, _swapFee);
            transferOut(token, outputAmount, member);
        }
    }

    // Add to balances directly (must send first)
    function sync(address token, address pool) external {
        uint256 _actualInput = getAddedAmount(token, pool);
        if (token == VADER || token == USDV) {
            mapToken_baseAmount[pool] += _actualInput;
        } else {
            mapToken_tokenAmount[pool] += _actualInput;
            // } else if(isSynth()){
            //     //burnSynth && deleteUnits
        }
        emit Sync(token, pool, _actualInput);
    }

    //======================================SYNTH=========================================//

    // Should be done with intention, is gas-intensive
    function deploySynth(address token) external {
        require(token != VADER || token != USDV);
        iFACTORY(FACTORY).deploySynth(token);
    }

    // Mint a Synth against its own pool
    function mintSynth(
        address base,
        address token,
        address member
    ) external returns (uint256 outputAmount) {
        require(iFACTORY(FACTORY).isSynth(getSynth(token)), "!synth");
        uint256 _actualInputBase = getAddedAmount(base, token); // Get input
        uint256 _synthUnits =
            iUTILS(UTILS()).calcSynthUnits(_actualInputBase, mapToken_baseAmount[token], mapToken_Units[token]); // Get Units
        outputAmount = iUTILS(UTILS()).calcSwapOutput(
            _actualInputBase,
            mapToken_baseAmount[token],
            mapToken_tokenAmount[token]
        ); // Get output
        mapTokenMember_Units[token][address(this)] += _synthUnits; // Add units for self
        mapToken_Units[token] += _synthUnits; // Add supply
        mapToken_baseAmount[token] += _actualInputBase; // Add BASE
        emit AddLiquidity(member, base, _actualInputBase, token, 0, _synthUnits); // Add Liquidity Event
        iFACTORY(FACTORY).mintSynth(getSynth(token), member, outputAmount); // Ask factory to mint to member
    }

    // Burn a Synth to get out BASE
    function burnSynth(
        address base,
        address token,
        address member
    ) external returns (uint256 outputBase) {
        uint256 _actualInputSynth = iERC20(getSynth(token)).balanceOf(address(this)); // Get input
        uint256 _unitsToDelete =
            iUTILS(UTILS()).calcShare(
                _actualInputSynth,
                iERC20(getSynth(token)).totalSupply(),
                mapTokenMember_Units[token][address(this)]
            ); // Pro rata
        iERC20(getSynth(token)).burn(_actualInputSynth); // Burn it
        mapTokenMember_Units[token][address(this)] -= _unitsToDelete; // Delete units for self
        mapToken_Units[token] -= _unitsToDelete; // Delete units
        outputBase = iUTILS(UTILS()).calcSwapOutput(
            _actualInputSynth,
            mapToken_tokenAmount[token],
            mapToken_baseAmount[token]
        ); // Get output
        mapToken_baseAmount[token] -= outputBase; // Remove BASE
        emit RemoveLiquidity(member, base, outputBase, token, 0, _unitsToDelete, mapToken_Units[token]); // Remove liquidity event
        transferOut(base, outputBase, member); // Send BASE to member
    }

    // Remove a synth, make other LPs richer
    function syncSynth(address token) external {
        uint256 _actualInputSynth = iERC20(getSynth(token)).balanceOf(address(this)); // Get input
        uint256 _unitsToDelete =
            iUTILS(UTILS()).calcShare(
                _actualInputSynth,
                iERC20(getSynth(token)).totalSupply(),
                mapTokenMember_Units[token][address(this)]
            ); // Pro rata
        iERC20(getSynth(token)).burn(_actualInputSynth); // Burn it
        mapTokenMember_Units[token][address(this)] -= _unitsToDelete; // Delete units for self
        mapToken_Units[token] -= _unitsToDelete; // Delete units
        emit SynthSync(token, _actualInputSynth, _unitsToDelete);
    }

    //======================================LENDING=========================================//

    // Assign units to callee (ie, a LendingRouter)
    function lockUnits(
        uint256 units,
        address token,
        address member
    ) external {
        mapTokenMember_Units[token][member] -= units;
        mapTokenMember_Units[token][msg.sender] += units; // Assign to protocol
    }

    // Assign units to callee (ie, a LendingRouter)
    function unlockUnits(
        uint256 units,
        address token,
        address member
    ) external {
        mapTokenMember_Units[token][msg.sender] -= units;
        mapTokenMember_Units[token][member] += units;
    }

    //======================================HELPERS=========================================//

    // Safe adds
    function getAddedAmount(address _token, address _pool) internal returns (uint256 addedAmount) {
        uint256 _balance = iERC20(_token).balanceOf(address(this));
        if (_token == VADER && _pool != VADER) {
            // Want to know added VADER
            addedAmount = _balance - pooledVADER;
            pooledVADER = pooledVADER + addedAmount;
        } else if (_token == USDV) {
            // Want to know added USDV
            addedAmount = _balance - pooledUSDV;
            pooledUSDV = pooledUSDV + addedAmount;
        } else {
            // Want to know added Asset/Anchor
            addedAmount = _balance - mapToken_tokenAmount[_pool];
        }
    }

    function transferOut(
        address _token,
        uint256 _amount,
        address _recipient
    ) internal {
        if (_token == VADER) {
            pooledVADER = pooledVADER - _amount; // Accounting
        } else if (_token == USDV) {
            pooledUSDV = pooledUSDV - _amount; // Accounting
        }
        if (_recipient != address(this)) {
            iERC20(_token).transfer(_recipient, _amount);
        }
    }

    function isMember(address member) public view returns (bool) {
        return _isMember[member];
    }

    function isAsset(address token) public view returns (bool) {
        return _isAsset[token];
    }

    function isAnchor(address token) public view returns (bool) {
        return _isAnchor[token];
    }

    function getPoolAmounts(address token) external view returns (uint256, uint256) {
        return (getBaseAmount(token), getTokenAmount(token));
    }

    function getBaseAmount(address token) public view returns (uint256) {
        return mapToken_baseAmount[token];
    }

    function getTokenAmount(address token) public view returns (uint256) {
        return mapToken_tokenAmount[token];
    }

    function getUnits(address token) external view returns (uint256) {
        return mapToken_Units[token];
    }

    function getMemberUnits(address token, address member) external view returns (uint256) {
        return mapTokenMember_Units[token][member];
    }

    function getSynth(address token) public view returns (address) {
        return iFACTORY(FACTORY).getSynth(token);
    }

    function isSynth(address token) public view returns (bool) {
        return iFACTORY(FACTORY).isSynth(token);
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

