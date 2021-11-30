pragma solidity ^0.7.6;
pragma abicoder v2;

import { DSMath } from "../../../utils/dsmath.sol";

import  "./interface.sol";

contract Helpers is DSMath {

    address constant internal universeReslover = 0x7466420dC366DF67b55daeDf19f8d37a346Fa7C8;

    function _depositAmount(
        address universeVault,
        uint256 amount0,
        uint256 amount1
    ) internal view returns(uint256, uint256){
        return IVaultV3(universeVault).getShares(amount0, amount1);
    }

    function _withdrawAmount(
        address universeVault,
        uint256 share0,
        uint256 share1
    ) internal view returns(uint256, uint256){
        return IVaultV3(universeVault).getBals(share0, share1);
    }

    function _userShareAmount(
        address universeVault,
        address user
    ) internal view returns(uint256, uint256) {
        return IVaultV3(universeVault).getUserShares(user);
    }

    struct VaultData {
        address token0;
        address token1;
        uint256 maxToken0Amt;
        uint256 maxToken1Amt;
        uint256 maxSingeDepositAmt0;
        uint256 maxSingeDepositAmt1;
        uint256 total0;
        uint256 total1;
        uint256 utilizationRate0;
        uint256 utilizationRate1;
    }

    function _vaultDetail(address universeVault) internal view returns (VaultData memory vaultData) {
        IVaultV3 vault = IVaultV3(universeVault);
        vaultData.token0 = vault.token0();
        vaultData.token1 = vault.token1();
        IVaultV3.MaxShares memory maxShare = vault.maxShares();
        vaultData.maxToken0Amt = maxShare.maxToken0Amt;
        vaultData.maxToken1Amt = maxShare.maxToken1Amt;
        vaultData.maxSingeDepositAmt0 = maxShare.maxSingeDepositAmt0;
        vaultData.maxSingeDepositAmt1 = maxShare.maxSingeDepositAmt1;
        (uint256 total0, uint256 total1, , , uint256 utilizationRate0, uint256 utilizationRate1) = vault.getTotalAmounts();
        vaultData.total0 = total0;
        vaultData.total1 = total1;
        vaultData.utilizationRate0 = utilizationRate0;
        vaultData.utilizationRate1 = utilizationRate1;
    }

    function _officialVaults() internal view returns(address[] memory vaults) {
        return IUniverseResolver(universeReslover).getAllVaultAddress();
    }

}

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IUniverseAdapter {

    function depositProxy(
        address universeVault,
        uint256 amount0,
        uint256 amount1
    ) external returns(uint256, uint256);

}

interface IUniverseResolver {

    function getAllVaultAddress() external view returns(address[] memory vaults);

    function checkUniverseVault(address universeVault) external view returns(bool status);

}

interface IVaultV3 {

    function getShares(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external view returns (uint256 share0, uint256 share1);

    function getBals(
        uint256 share0,
        uint256 share1
    ) external view returns (uint256 amount0, uint256 amount1);

    function getUserShares(address user) external view returns (uint256 share0, uint256 share1);

    function token0() external view returns (address);

    function token1() external view returns (address);

    struct MaxShares {
        uint256 maxToken0Amt;
        uint256 maxToken1Amt;
        uint256 maxSingeDepositAmt0;
        uint256 maxSingeDepositAmt1;
    }

    function maxShares() external view returns (MaxShares memory);

    function getTotalAmounts() external view returns (
        uint256 total0,
        uint256 total1,
        uint256 free0,
        uint256 free1,
        uint256 utilizationRate0,
        uint256 utilizationRate1
    );

    function getPNL() external view returns (uint256 rate, uint256 param);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Helpers} from "./helpers.sol";

abstract contract UniverseFinanceResolver is Helpers {

    /**
     * @notice get all Universe Working Vaults
     * @return address list
     */
    function getAllVault() external view returns(address[] memory) {
        return _officialVaults();
    }

    /**
     * @notice get universe vault detail info
     * @param universeVault the Universe Vault Address
     * @return [token0Address, token1Address, vaultMaxToken0Amount, vaultMaxToken1Amount, maxSingleDepositFofToken0,
     maxSingleDepositFofToken1, totalToken0Amount, totalTotal1Amount, utilizationOfToken0, utilizationOfToken1]
     */
    function getVaultDetail(address universeVault) external view returns(VaultData memory) {
        return _vaultDetail(universeVault);
    }

    /**
     * @notice get user share info
     * @param universeVault the Universe Vault Address
     * @param user the user address
     * @return shareToken0Amount and shareToken1Amount
     */
    function getUserShareAmount(address universeVault, address user) external view returns(uint256, uint256) {
        return _userShareAmount(universeVault, user);
    }

    /**
    * @notice get user share info list
    * @param universeVaults the Universe Vault Address arrays
    * @param user the user address
    */
    function getUserShareAmountList(address[] memory universeVaults, address user) external view returns(uint256[2][] memory data) {
        uint len = universeVaults.length;
        if(len > 0){
            data = new uint256[2][](len);
            for(uint i; i < len; i++){
                (uint256 share0, uint256 share1) = _userShareAmount(universeVaults[i], user);
                data[i] = [share0, share1];
            }
        }
    }

    /**
     * @notice get user can withdraw amount
     * @param universeVault the Universe Vault Address
     * @param user the user address
     * @return token0Amount  token1Amount
     */
    function getUserWithdrawAmount(address universeVault, address user) external view returns(uint256, uint256) {
        (uint256 share0, uint256 share1) = _userShareAmount(universeVault, user);
        return _withdrawAmount(universeVault, share0, share1);
    }

    /**
     * @notice get user can get share when deposit amount0 and amount1
     * @param universeVault the Universe Vault Address
     * @param amount0 the token0 amount
     * @param amount1 the token1 amount
     * @return shareToken0Amount and shareToken1Amount
     */
    function getUserDepositAmount(
        address universeVault,
        uint256 amount0,
        uint256 amount1
    ) external view returns(uint256, uint256) {
        return _depositAmount(universeVault, amount0, amount1);
    }

}

contract ResolverV2UniverseFinance is UniverseFinanceResolver {
    string public constant name = "UniverseFinance-v1";
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y <= x ? x - y : 0;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    uint256 internal constant WAD = 10**18;
    uint256 internal constant RAY = 10**27;

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
}