//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { Helpers } from "./helpers.sol";

abstract contract UniverseFinanceResolver is Helpers {
    /**
     * @notice get all Universe Working Vaults
     * @return address list
     */
    function getAllVault() public view returns (address[] memory) {
        return _officialVaults();
    }

    /**
     * @notice get universe vault detail info
     * @param universeVaults the Universe Vault Address
     * @return [token0Address, token1Address, vaultMaxToken0Amount, vaultMaxToken1Amount, maxSingleDepositFofToken0,
     maxSingleDepositFofToken1, totalToken0Amount, totalTotal1Amount, utilizationOfToken0, utilizationOfToken1]
     */
    function getVaultDetail(address[] memory universeVaults) public view returns (VaultData[] memory) {
        return _vaultData(universeVaults);
    }

    /**
     * @notice get user share info
     * @param universeVault the Universe Vault Address
     * @param user the user address
     * @return shareToken0Amount and shareToken1Amount
     */
    function getUserShareAmount(address universeVault, address user) external view returns (uint256, uint256) {
        return _userShareAmount(universeVault, user);
    }

    /**
     * @notice get user share info list
     * @param universeVaults the Universe Vault Address arrays
     * @param user the user address
     */
    function getUserShareAmountList(address[] memory universeVaults, address user)
        external
        view
        returns (uint256[2][] memory data)
    {
        uint256 len = universeVaults.length;
        if (len > 0) {
            data = new uint256[2][](len);
            for (uint256 i; i < len; i++) {
                (uint256 share0, uint256 share1) = _userShareAmount(universeVaults[i], user);
                data[i] = [share0, share1];
            }
        }
    }

    /**
     * @notice get user withdraw amount
     * @param universeVault the Universe Vault Address
     * @param user the user address
     * @return token0Amount  token1Amount
     */
    function getUserWithdrawAmount(address universeVault, address user) external view returns (uint256, uint256) {
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
    ) external view returns (uint256, uint256) {
        return _depositAmount(universeVault, amount0, amount1);
    }

    /**
     * @notice get token decimals of a vault
     * @param vault the vault address
     * @return token decimals
     */
    function decimals(address vault) external view returns (uint8, uint8) {
        return _decimals(vault);
    }

    /**
     * @notice get token decimals of a vault
     * @param universeVault the vault's address
     * @param user the user's address
     */
    function position(address[] memory universeVault, address user) public view returns (Position[] memory) {
        Position[] memory userPosition = new Position[](universeVault.length);
        for (uint256 i = 0; i < universeVault.length; i++) {
            userPosition[i] = _position(universeVault[i], user);
        }

        return userPosition;
    }

    /**
     * @notice returns vaults data & users position
     * @param universeVault the vault's address array
     * @param user the user's address
     */
    function positionByVault(address[] memory universeVault, address user)
        external
        view
        returns (Position[] memory userPosition, VaultData[] memory data)
    {
        userPosition = position(universeVault, user);
        data = getVaultDetail(universeVault);
    }

    /**
     * @notice returns vaults data & users position
     * @param user the user's address
     */
    function positionByAddress(address user)
        external
        view
        returns (Position[] memory userPosition, VaultData[] memory data)
    {
        userPosition = position(getAllVault(), user);
        data = getVaultDetail(getAllVault());
    }
}

contract ResolverV2UniverseFinance is UniverseFinanceResolver {
    string public constant name = "UniverseFinance-v1";
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { DSMath } from "../../../utils/dsmath.sol";
import "./interface.sol";

contract Helpers is DSMath {
    address internal constant universeReslover = 0x7466420dC366DF67b55daeDf19f8d37a346Fa7C8;
    uint8 internal constant vaultVersion = 1;

    function _depositAmount(
        address universeVault,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint256, uint256) {
        return IVaultV3(universeVault).getShares(amount0, amount1);
    }

    function _withdrawAmount(
        address universeVault,
        uint256 share0,
        uint256 share1
    ) internal view returns (uint256, uint256) {
        return IVaultV3(universeVault).getBals(share0, share1);
    }

    function _userShareAmount(address universeVault, address user) internal view returns (uint256, uint256) {
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
        uint256 version;
    }

    struct Position {
        uint256 share0;
        uint256 share1;
        uint256 amount0;
        uint256 amount1;
        uint256 version;
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
        (uint256 total0, uint256 total1, , , uint256 utilizationRate0, uint256 utilizationRate1) = vault
            .getTotalAmounts();
        vaultData.total0 = total0;
        vaultData.total1 = total1;
        vaultData.utilizationRate0 = utilizationRate0;
        vaultData.utilizationRate1 = utilizationRate1;
        vaultData.version = vaultVersion;
    }

    function _officialVaults() internal view returns (address[] memory vaults) {
        return IUniverseResolver(universeReslover).getAllVaultAddress();
    }

    function _vaultData(address[] memory universeVaults) internal view returns (VaultData[] memory) {
        VaultData[] memory data = new VaultData[](universeVaults.length);
        for (uint256 i = 0; i < universeVaults.length; i++) {
            data[i] = _vaultDetail(universeVaults[i]);
        }
        return data;
    }

    function _decimals(address vault) internal view returns (uint8 decimal0, uint8 decimal1) {
        address token0 = IVaultV3(vault).token0();
        address token1 = IVaultV3(vault).token1();
        decimal0 = IERC20(token0).decimals();
        decimal1 = IERC20(token1).decimals();
    }

    function _position(address vault, address user) internal view returns (Position memory userPosition) {
        (userPosition.share0, userPosition.share1) = _userShareAmount(vault, user);
        (userPosition.amount0, userPosition.amount1) = _withdrawAmount(vault, userPosition.share0, userPosition.share1);
        userPosition.version = vaultVersion;
    }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IUniverseAdapter {
    function depositProxy(
        address universeVault,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256, uint256);
}

interface IUniverseResolver {
    function getAllVaultAddress() external view returns (address[] memory vaults);

    function checkUniverseVault(address universeVault) external view returns (bool status);
}

interface IVaultV3 {
    function getShares(uint256 amount0Desired, uint256 amount1Desired)
        external
        view
        returns (uint256 share0, uint256 share1);

    function getBals(uint256 share0, uint256 share1) external view returns (uint256 amount0, uint256 amount1);

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

    function getTotalAmounts()
        external
        view
        returns (
            uint256 total0,
            uint256 total1,
            uint256 free0,
            uint256 free1,
            uint256 utilizationRate0,
            uint256 utilizationRate1
        );

    function getPNL() external view returns (uint256 rate, uint256 param);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}