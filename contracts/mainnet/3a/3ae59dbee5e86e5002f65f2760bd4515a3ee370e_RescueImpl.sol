/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

pragma solidity 0.5.14;


contract VersionedInitializable {
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

  /// @dev returns the revision number of the contract.
  /// Needs to be defined in the inherited class as a constant.
  function getRevision() internal pure returns (uint256);

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address)
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

contract RescueImpl is VersionedInitializable {
  address public constant RESCUE_ADMIN = address(0x334E6291B73e340305f3FC5A65F4BCD3AA816195);

  address public constant FUNDS_RECEIVER = address(0x2517C251C8EDd3E6977051e6bb86Cc7876D07667);

  function getRevision() internal pure returns (uint256) {
    return 1;
  }

  function initialize(address addressesProvider) public initializer {}

  function rescue() public {
    require(msg.sender == RESCUE_ADMIN, 'INVALID_CALLER');
    (bool success, ) = FUNDS_RECEIVER.call.value(address(this).balance).gas(50000)('');
    require(success, 'FAILED_TRANSFER');
  }
}