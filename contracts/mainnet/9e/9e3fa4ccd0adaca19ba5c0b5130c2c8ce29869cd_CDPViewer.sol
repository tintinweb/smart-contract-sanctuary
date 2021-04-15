/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// File: contracts/interfaces/IVaultParameters.sol

interface IVaultParameters {
    function canModifyVault ( address ) external view returns ( bool );
    function foundation (  ) external view returns ( address );
    function isManager ( address ) external view returns ( bool );
    function isOracleTypeEnabled ( uint256, address ) external view returns ( bool );
    function liquidationFee ( address ) external view returns ( uint256 );
    function setCollateral ( address asset, uint256 stabilityFeeValue, uint256 liquidationFeeValue, uint256 usdpLimit, uint256[] calldata oracles ) external;
    function setFoundation ( address newFoundation ) external;
    function setLiquidationFee ( address asset, uint256 newValue ) external;
    function setManager ( address who, bool permit ) external;
    function setOracleType ( uint256 _type, address asset, bool enabled ) external;
    function setStabilityFee ( address asset, uint256 newValue ) external;
    function setTokenDebtLimit ( address asset, uint256 limit ) external;
    function setVaultAccess ( address who, bool permit ) external;
    function stabilityFee ( address ) external view returns ( uint256 );
    function tokenDebtLimit ( address ) external view returns ( uint256 );
    function vault (  ) external view returns ( address );
    function vaultParameters (  ) external view returns ( address );
}

// File: contracts/interfaces/IVaultManagerParameters.sol

interface IVaultManagerParameters {
    function devaluationPeriod ( address ) external view returns ( uint256 );
    function initialCollateralRatio ( address ) external view returns ( uint256 );
    function liquidationDiscount ( address ) external view returns ( uint256 );
    function liquidationRatio ( address ) external view returns ( uint256 );
    function maxColPercent ( address ) external view returns ( uint256 );
    function minColPercent ( address ) external view returns ( uint256 );
    function setColPartRange ( address asset, uint256 min, uint256 max ) external;
    function setCollateral (
        address asset,
        uint256 stabilityFeeValue,
        uint256 liquidationFeeValue,
        uint256 initialCollateralRatioValue,
        uint256 liquidationRatioValue,
        uint256 liquidationDiscountValue,
        uint256 devaluationPeriodValue,
        uint256 usdpLimit,
        uint256[] calldata oracles,
        uint256 minColP,
        uint256 maxColP
    ) external;
    function setDevaluationPeriod ( address asset, uint256 newValue ) external;
    function setInitialCollateralRatio ( address asset, uint256 newValue ) external;
    function setLiquidationDiscount ( address asset, uint256 newValue ) external;
    function setLiquidationRatio ( address asset, uint256 newValue ) external;
    function vaultParameters (  ) external view returns ( address );
}

// File: contracts/interfaces/IVault.sol

interface IVault {
    function DENOMINATOR_1E2 (  ) external view returns ( uint256 );
    function DENOMINATOR_1E5 (  ) external view returns ( uint256 );
    function borrow ( address asset, address user, uint256 amount ) external returns ( uint256 );
    function calculateFee ( address asset, address user, uint256 amount ) external view returns ( uint256 );
    function changeOracleType ( address asset, address user, uint256 newOracleType ) external;
    function chargeFee ( address asset, address user, uint256 amount ) external;
    function col (  ) external view returns ( address );
    function colToken ( address, address ) external view returns ( uint256 );
    function collaterals ( address, address ) external view returns ( uint256 );
    function debts ( address, address ) external view returns ( uint256 );
    function depositCol ( address asset, address user, uint256 amount ) external;
    function depositEth ( address user ) external payable;
    function depositMain ( address asset, address user, uint256 amount ) external;
    function destroy ( address asset, address user ) external;
    function getTotalDebt ( address asset, address user ) external view returns ( uint256 );
    function lastUpdate ( address, address ) external view returns ( uint256 );
    function liquidate ( address asset, address positionOwner, uint256 mainAssetToLiquidator, uint256 colToLiquidator, uint256 mainAssetToPositionOwner, uint256 colToPositionOwner, uint256 repayment, uint256 penalty, address liquidator ) external;
    function liquidationBlock ( address, address ) external view returns ( uint256 );
    function liquidationFee ( address, address ) external view returns ( uint256 );
    function liquidationPrice ( address, address ) external view returns ( uint256 );
    function oracleType ( address, address ) external view returns ( uint256 );
    function repay ( address asset, address user, uint256 amount ) external returns ( uint256 );
    function spawn ( address asset, address user, uint256 _oracleType ) external;
    function stabilityFee ( address, address ) external view returns ( uint256 );
    function tokenDebts ( address ) external view returns ( uint256 );
    function triggerLiquidation ( address asset, address positionOwner, uint256 initialPrice ) external;
    function update ( address asset, address user ) external;
    function usdp (  ) external view returns ( address );
    function vaultParameters (  ) external view returns ( address );
    function weth (  ) external view returns ( address payable );
    function withdrawCol ( address asset, address user, uint256 amount ) external;
    function withdrawEth ( address user, uint256 amount ) external;
    function withdrawMain ( address asset, address user, uint256 amount ) external;
}

// File: contracts/interfaces/IToken.sol

interface IToken {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
}

// File: contracts/interfaces/IOracleRegistry.sol

pragma abicoder v2;


interface IOracleRegistry {

    struct Oracle {
        uint oracleType;
        address oracleAddress;
    }

    function WETH (  ) external view returns ( address );
    function getKeydonixOracleTypes (  ) external view returns ( uint256[] memory );
    function getOracles (  ) external view returns ( Oracle[] memory foundOracles );
    function keydonixOracleTypes ( uint256 ) external view returns ( uint256 );
    function maxOracleType (  ) external view returns ( uint256 );
    function oracleByAsset ( address asset ) external view returns ( address );
    function oracleByType ( uint256 ) external view returns ( address );
    function oracleTypeByAsset ( address ) external view returns ( uint256 );
    function oracleTypeByOracle ( address ) external view returns ( uint256 );
    function setKeydonixOracleTypes ( uint256[] memory _keydonixOracleTypes ) external;
    function setOracle ( uint256 oracleType, address oracle ) external;
    function setOracleTypeForAsset ( address asset, uint256 oracleType ) external;
    function setOracleTypeForAssets ( address[] memory assets, uint256 oracleType ) external;
    function unsetOracle ( uint256 oracleType ) external;
    function unsetOracleForAsset ( address asset ) external;
    function unsetOracleForAssets ( address[] memory assets ) external;
    function vaultParameters (  ) external view returns ( address );
}

// File: contracts/helpers/IUniswapV2PairFull.sol

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

interface IUniswapV2PairFull {
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

// File: contracts/helpers/CDPViewer.sol

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;









/**
 * @notice Views collaterals in one request to save node requests and speed up dapps.
 */
contract CDPViewer {

    IVault public vault;
    IVaultParameters public  vaultParameters;
    IVaultManagerParameters public  vaultManagerParameters;
    IOracleRegistry public  oracleRegistry;

    struct CDP {
        address owner;

        // Collateral amount
        uint128 collateral;

        // Debt amount
        uint128 debt;

        // Percentage with 3 decimals
        uint32 stabilityFee;

        // Percentage with 0 decimals
        uint16 liquidationFee;
    }

    struct CollateralParameters {

        address asset;

        // Percentage with 3 decimals
        uint32 stabilityFee;

        // Percentage with 0 decimals
        uint16 liquidationFee;

        // Percentage with 0 decimals
        uint16 initialCollateralRatio;

        // Percentage with 0 decimals
        uint16 liquidationRatio;

        // Percentage with 3 decimals
        uint32 liquidationDiscount;

        // Devaluation period in blocks
        uint32 devaluationPeriod;

        // USDP mint limit
        uint128 tokenDebtLimit;

        // USDP mint limit
        uint128 tokenDebt;

        // Oracle types enabled for this asset
        uint16 oracleType;

        CDP cdp;
    }

    struct TokenDetails {
        address[2] lpUnderlyings;
        uint balance;
    }


    constructor() {
         IVaultManagerParameters vmp = IVaultManagerParameters(0x203153522B9EAef4aE17c6e99851EE7b2F7D312E);
         vaultManagerParameters = vmp;
         IVaultParameters vp = IVaultParameters(vmp.vaultParameters());
         vaultParameters = vp;
         vault = IVault(vp.vault());
         IOracleRegistry or = IOracleRegistry(0x75fBFe26B21fd3EA008af0C764949f8214150C8f);
         oracleRegistry = or;
    }
    
    function sliceUint(bytes memory bs, uint start)
        internal pure
        returns (uint)
    {
        require(bs.length >= start + 32, "slicing out of range");
        uint x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }
    
    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /**
     * @notice Get parameters of one asset
     * @param asset asset address
     * @param owner owner address
     */
    function getCollateralParameters(address asset, address owner)
        public
        view
        returns (CollateralParameters memory r)
    {
        r.asset = asset;
        r.stabilityFee = uint32(vaultParameters.stabilityFee(asset));
        r.liquidationFee = uint16(vaultParameters.liquidationFee(asset));
        r.initialCollateralRatio = uint16(vaultManagerParameters.initialCollateralRatio(asset));
        r.liquidationRatio = uint16(vaultManagerParameters.liquidationRatio(asset));
        r.liquidationDiscount = uint32(vaultManagerParameters.liquidationDiscount(asset));
        r.devaluationPeriod = uint32(vaultManagerParameters.devaluationPeriod(asset));

        r.tokenDebtLimit = uint128(vaultParameters.tokenDebtLimit(asset));
        r.tokenDebt = uint128(vault.tokenDebts(asset));
        r.oracleType = uint16(oracleRegistry.oracleByAsset(asset));

        if (owner == address(0)) return r;

        r.cdp.owner = owner;
        r.cdp.stabilityFee = uint32(vault.stabilityFee(asset, owner));
        r.cdp.liquidationFee = uint16(vault.liquidationFee(asset, owner));
        r.cdp.debt = uint128(vault.debts(asset, owner));
        r.cdp.collateral = uint128(vault.collaterals(asset, owner));
    }

    /**
     * @notice Get details of one token
     * @param asset token address
     * @param owner owner address
     */
    function getTokenDetails(address asset, address owner)
        public
        view
        returns (TokenDetails memory r)
    {
        try IUniswapV2PairFull(asset).token0() returns(address token0) {
            r.lpUnderlyings[0] = token0;
            r.lpUnderlyings[1] = IUniswapV2PairFull(asset).token1();
        } catch (bytes memory) { }

        if (owner == address(0)) return r;
        r.balance = IToken(asset).balanceOf(owner);
    }

    /**
     * @notice Get parameters of many collaterals
     * @param assets asset addresses
     * @param owner owner address
     */
    function getMultiAssetParameters(address[] calldata assets, address owner)
        external
        view
        returns (CollateralParameters[] memory r)
    {
        uint length = assets.length;
        r = new CollateralParameters[](length);
        for (uint i = 0; i < length; ++i) {
            r[i] = getCollateralParameters(assets[i], owner);
        }
    }

    /**
     * @notice Get details of many token
     * @param assets token addresses
     * @param owner owner address
     */
    function getMultiTokenDetails(address[] calldata assets, address owner)
        external
        view
        returns (TokenDetails[] memory r)
    {
        uint length = assets.length;
        r = new TokenDetails[](length);
        for (uint i = 0; i < length; ++i) {
            r[i] = getTokenDetails(assets[i], owner);
        }
    }
}