// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// Interfaces
import "./interfaces/iERC20.sol";
import "./interfaces/iVADER.sol";
import "./interfaces/iUSDV.sol";
import "./interfaces/iROUTER.sol";

//======================================VADER=========================================//
contract Attack {
    bool private inited;
    address public VADER;
    address public USDV;

    //=====================================CREATION=========================================//
    // Constructor
    constructor() {}

    function init(address _vader, address _USDV) public {
        require(inited == false);
        inited = true;
        VADER = _vader;
        USDV = _USDV;
    }

    //========================================iERC20=========================================//
    function attackUSDV(uint256 amount) public {
        iERC20(VADER).approve(USDV, amount);
        iERC20(USDV).approve(USDV, amount);
        iERC20(VADER).transferTo(address(this), amount); // get VADER funds
        iUSDV(USDV).convert(amount); // Convert to USDV back to this address
        iUSDV(USDV).redeem(amount); // Burn USDV back to VADER to this address
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

interface iUSDV {
    function ROUTER() external view returns (address);

    function isMature() external view returns (bool);

    function setParams(uint256 newDelay) external;

    function convert(uint256 amount) external returns (uint256 convertAmount);

    function convertForMember(address member, uint256 amount) external returns (uint256 convertAmount);

    function redeem(uint256 amount) external returns (uint256 redeemAmount);

    function redeemForMember(address member, uint256 amount) external returns (uint256 redeemAmount);
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

