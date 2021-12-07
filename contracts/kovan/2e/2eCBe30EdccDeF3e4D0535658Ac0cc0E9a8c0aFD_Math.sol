// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Math is Initializable {
    function getOddsFromBanks(
        uint256 fund1Bank_,
        uint256 fund2Bank_,
        uint256 amount_,
        uint256 team_,
        uint256 marginality_,
        uint256 decimals_
    ) public pure returns (uint256) {
        if (team_ == 1) {
            uint256 pe1 = ((fund1Bank_ + amount_) * decimals_) /
                (fund1Bank_ + fund2Bank_ + amount_);
            uint256 ps1 = (fund1Bank_ * decimals_) / (fund1Bank_ + fund2Bank_);
            uint256 cAmount = ceil(
                ((amount_ * decimals_) / (fund1Bank_ / 100)),
                decimals_,
                decimals_
            ) / decimals_; // step
            if (cAmount == 1) {
                return addMargin((decimals_**2) / ps1, marginality_, decimals_);
            }
            uint256 odds = (decimals_**3) /
                (((pe1 * cAmount + ps1 * 2 - pe1 * 2) * decimals_) / cAmount);
            return addMargin(odds, marginality_, decimals_);
        }

        if (team_ == 2) {
            uint256 pe2 = ((fund2Bank_ + amount_) * decimals_) /
                (fund1Bank_ + fund2Bank_ + amount_);
            uint256 ps2 = (fund2Bank_ * decimals_) / (fund1Bank_ + fund2Bank_);
            uint256 cAmount = ceil(
                ((amount_ * decimals_) / (fund2Bank_ / 100)),
                decimals_,
                decimals_
            ) / decimals_;
            if (cAmount == 1) {
                return addMargin((decimals_**2) / ps2, marginality_, decimals_);
            }
            uint256 odds = (decimals_**3) /
                (((pe2 * cAmount + ps2 * 2 - pe2 * 2) * decimals_) / cAmount);
            return addMargin(odds, marginality_, decimals_);
        }
        return 0;
    }

    function ceil(
        uint256 a,
        uint256 m,
        uint256 decimals
    ) public pure returns (uint256) {
        if (a < decimals) return decimals;
        return ((a + m - 1) / m) * m;
    }

    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function addMargin(
        uint256 odds,
        uint256 marginality,
        uint256 decimals
    ) public pure returns (uint256 newOdds) {
        //console.log("Odds %s, margin %s", odds, marginality);
        //console.log("1 - 1/kef   ", decimals - decimals**2 / odds);
        uint256 revertOdds = decimals**2 / (decimals - decimals**2 / odds);
        //console.log("revert odds", revertOdds);
        uint256 marginEUR = decimals + marginality; // decimals
        //console.log("marginEUR odds", marginEUR);
        uint256 a = (marginEUR * (revertOdds - decimals)) / (odds - decimals);
        //console.log("a ", a);
        uint256 b = ((((revertOdds - decimals) * decimals) /
            (odds - decimals)) *
            marginality +
            decimals *
            marginality) / decimals;
        //console.log("b ", b);
        uint256 c = (2 * decimals - marginEUR);
        //console.log("c ", c);
        newOdds =
            ((sqrt(b**2 + 4 * a * c) - b) * decimals) /
            (2 * a) +
            decimals;
        return newOdds;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}