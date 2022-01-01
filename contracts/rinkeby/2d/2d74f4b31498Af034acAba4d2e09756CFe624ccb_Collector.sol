// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../token/VersionedInitializable.sol";

contract Collector is VersionedInitializable {

  uint256 public constant REVISION = 1;

  /**
   * @dev returns the revision of the implementation contract
   */
  function getRevision() internal override pure returns (uint256) {
    return REVISION;
  }

  /**
   * @dev initializes the contract upon assignment to the InitializableAdminUpgradeabilityProxy
   */
  function initialize() external initializer {
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract VersionedInitializable {
    /**
    * @dev Indicates that the contract has been initialized.
    */
    uint256 private lastInitializedRevision = 0;

    /**
    * @dev Indicates that the contract is in the process of being initialized.
    */
    bool private initializing;

    /**
    * @dev Modifier to use in the initializer function of a contract.
    */
    modifier initializer() {
        uint256 revision = getRevision();
        require(
            initializing || isConstructor() || revision > lastInitializedRevision,
            'Contract instance has already been initialized'
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /**
    * @dev returns the revision number of the contract
    * Needs to be defined in the inherited class as a constant.
    **/
    function getRevision() internal pure virtual returns (uint256);

    /**
    * @dev Returns true if and only if the function is running in the constructor
    **/
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}