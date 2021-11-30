// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "../Account/AccountFactory.sol";

/// @title DeployAndCall
/// @notice This contract contains a function to batch account deploy and call into one transaction
contract DeployAndCall {
  /// @dev The AccountFactory to use for account deployments
  AccountFactory constant ACCOUNT_FACTORY = AccountFactory(0x0B71C16a71eB1aF834e78678529A6e7003f73C5c);

  /// @dev Deploys an account for the given owner and executes callData on the account
  /// @param owner Address of the account owner
  /// @param callData The call to execute on the account after deployment
  function deployAndCall(address owner, bytes memory callData) external payable {
    address account = ACCOUNT_FACTORY.deployAccount(owner);

    if (callData.length > 0) {
      assembly {
        let result := call(gas(), account, callvalue(), add(callData, 0x20), mload(callData), 0, 0)
        returndatacopy(0, 0, returndatasize())
        switch result
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/// @title Brink account factory
/// @notice This is a factory contract used for deployment of Brink proxy accounts
contract AccountFactory {
  /// @dev Salt used for salted deployment of Proxy accounts
  bytes32 constant SALT = 0x841eb53dae7d7c32f92a7e2a07956fb3b9b1532166bc47aa8f091f49bcaa9ff5;

  /// @dev Deploys a Proxy account for the given owner
  /// @param owner Owner of the Proxy account
  /// @return account Address of the deployed Proxy account
  /// @notice This deploys a "minimal proxy" contract (https://eips.ethereum.org/EIPS/eip-1167) with the proxy owner
  /// address added to the deployed bytecode. The owner address can be read within a delegatecall by using `extcodecopy`
  function deployAccount(address owner) external returns (address account) {
    bytes memory initCode = abi.encodePacked(
      //  [*** constructor **][**** eip-1167 ****][******* implementation_address *******][********* eip-1167 *********]
      hex'3d604180600a3d3981f3363d3d373d3d3d363d7320462190079006816ce1b85664f6202873b4e4165af43d82803e903d91602b57fd5bf3',
      owner
    );
    assembly {
      account := create2(0, add(initCode, 0x20), mload(initCode), SALT)
    }
  }
}