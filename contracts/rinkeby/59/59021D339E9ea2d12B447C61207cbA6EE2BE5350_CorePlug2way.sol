// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

//import "hardhat/console.sol";
import "./Libraries/Math.sol";
import "./interface/ICOREplug.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract CorePlug2way is OwnableUpgradeable, ICOREplug, Math {
    function initialize(address _owner) public virtual initializer {
        __Ownable_init();
        transferOwnership(_owner);
    }

    function calculateOdds(
        uint256 amount,
        uint256 outcomeWin,
        uint256[] calldata fundBank,
        uint256 marginality,
        uint256 DECIMALS
    ) external pure override returns (uint256) {
        uint256 rate = Math.getRateFromBanks(
            fundBank[0],
            fundBank[1],
            amount,
            outcomeWin,
            marginality,
            DECIMALS
        );
        return rate;
    }

    /**
     * internal view, used resolve prize and ezternal views
     
     */

    function viewPrize(
        bool currentBetPayed,
        uint256 currentBetOutcome,
        uint256 currentBetRate,
        uint256 currentBetAmount,
        uint256 conditionOutcomeWin,
        uint256 DECIMALS
    ) external pure override returns (bool success, uint256 amount) {
        if (
            !currentBetPayed &&
            (conditionOutcomeWin == 1) &&
            (currentBetOutcome == 1)
        ) {
            uint256 winAmount = (currentBetRate * currentBetAmount) / DECIMALS;
            return (true, winAmount);
        }

        if (
            !currentBetPayed &&
            (conditionOutcomeWin == 2) &&
            (currentBetOutcome == 2)
        ) {
            uint256 winAmount = (currentBetRate * currentBetAmount) / DECIMALS;
            return (true, winAmount);
        }
        return (false, 0);
    }

    function checkOutcome(uint256 outcomeWin)
        external
        pure
        override
        returns (bool)
    {
        return (outcomeWin == 1 || outcomeWin == 2);
    }

    function checkFunds(uint256[] calldata conditionfundBank)
        external
        pure
        override
        returns (bool)
    {
        //console.log("checkFunds %s ", conditionfundBank.length, conditionfundBank[0], conditionfundBank[1]);
        return (conditionfundBank[1] / conditionfundBank[0] < 10000 &&
            conditionfundBank[0] / conditionfundBank[1] < 10000);
    }

    function calcFundBank(
        uint256[] calldata rates,
        uint256 conditionalReinforcementFix
    ) external pure override returns (uint256[] memory) {
        uint256[] memory fundBanks = new uint256[](rates.length);
        //console.log("conditionalReinforcementFix ", conditionalReinforcementFix, rates[0], rates[1]);
        fundBanks[0] = ((conditionalReinforcementFix * rates[0]) /
            (rates[0] + rates[1]));
        fundBanks[1] = ((conditionalReinforcementFix * rates[1]) /
            (rates[0] + rates[1]));
        //console.log("fundBanks[0] %s fundBanks[1] %s", fundBanks[0], fundBanks[1]);
        return fundBanks;
    }

    function calcPrizing(uint256[] calldata prizing, uint256 outcomeWin)
        external
        pure
        override
        returns (uint256)
    {
        return (outcomeWin == 1 ? prizing[0] : prizing[1]);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Math {
    function getRateFromBanks(
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
            ) / decimals_; // step?
            uint256 rate = (decimals_**3) /
                (((pe1 * cAmount + ps1 * 2 - pe1 * 2) * decimals_) / cAmount);
            return addMarginality(rate, marginality_, decimals_);
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
            uint256 rate = (decimals_**3) /
                (((pe2 * cAmount + ps2 * 2 - pe2 * 2) * decimals_) / cAmount);
            return addMarginality(rate, marginality_, decimals_);
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

    function addMarginality(
        uint256 rate,
        uint256 marginality,
        uint256 decimals
    ) public pure returns (uint256 newRate) {
        //console.log("Rate %s, margin %s", rate, marginality);
        //console.log("1 - 1/kef   ", decimals - decimals**2 / rate);
        uint256 revertRate = decimals**2 / (decimals - decimals**2 / rate);
        //console.log("revert rate", revertRate);
        uint256 marginEUR = decimals + marginality; // decimals
        //console.log("marginEUR rate", marginEUR);
        uint256 a = (marginEUR * (revertRate - decimals)) / (rate - decimals);
        //console.log("a ", a);
        uint256 b = ((((revertRate - decimals) * decimals) /
            (rate - decimals)) *
            marginality +
            decimals *
            marginality) / decimals;
        //console.log("b ", b);
        uint256 c = (2 * decimals - marginEUR);
        //console.log("c ", c);
        newRate =
            ((sqrt(b**2 + 4 * a * c) - b) * decimals) /
            (2 * a) +
            decimals;
        return newRate;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ICOREplug {
    function calculateOdds(
        uint256 amount,
        uint256 outcomeWin,
        uint256[] calldata fundBank,
        uint256 marginality,
        uint256 DECIMALS
    ) external view returns (uint256);

    function viewPrize(
        bool currentBetPayed,
        uint256 currentBetOutcome,
        uint256 currentBetRate,
        uint256 currentBetAmount,
        uint256 conditionOutcomeWin,
        uint256 DECIMALS
    ) external view returns (bool success, uint256 amount);

    function checkOutcome(uint256 outcomeWin) external pure returns (bool);

    function checkFunds(uint256[] calldata conditionfundBank)
        external
        view
        returns (bool);

    function calcFundBank(
        uint256[] calldata rates,
        uint256 conditionalReinforcementFix
    ) external view returns (uint256[] memory);

    function calcPrizing(uint256[] calldata prizing, uint256 outcomeWin)
        external
        pure
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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