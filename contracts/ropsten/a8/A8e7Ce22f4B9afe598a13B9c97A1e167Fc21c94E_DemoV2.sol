pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./Demo.sol";
//import "hardhat/console.sol";
import "./VerzionedInitializable.sol";

contract DemoV2 is Demo, VersionedInitializable {
    function initializeUpgrade() external virtual initializerV {
        //console.logAddress(daiAddress);
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return 2;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/proxy/Initializable.sol";

contract Demo is Initializable {
    uint256 week;

    function initialize(uint256 _x) public initializer {
        week = _x;
    }

    function getDaysInMonth() public pure returns (uint256) {
        return 30;
    }

    function getWeek() public view returns (uint256) {
        return week;
    }
}

pragma solidity >=0.6.0 <0.7.0;


/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
    /**
   * @dev Indicates that the contract has been initialized.
   */
    uint256 private lastInitializedRevision = 0;

    /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
    bool private _initializing;

    /**
   * @dev Modifier to use in the initializer function of a contract.
   */
    modifier initializerV() {
        uint256 revision = getRevision();
        require(_initializing || isConstructor() || revision > lastInitializedRevision, "Contract instance has already been initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev returns the revision number of the contract.
    /// Needs to be defined in the inherited class as a constant.
    function getRevision() virtual internal pure returns(uint256);


    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}