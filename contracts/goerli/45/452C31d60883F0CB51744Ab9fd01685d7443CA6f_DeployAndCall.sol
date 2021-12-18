// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    DeployAndCall.sol :: 0x452C31d60883F0CB51744Ab9fd01685d7443CA6f
 *    etherscan.io verified 2021-12-18
 */ 

import "../Account/AccountFactory.sol";

/// @title DeployAndCall
/// @notice This contract contains a function to batch account deploy and call into one transaction
contract DeployAndCall {
  /// @dev The AccountFactory to use for account deployments
  AccountFactory constant ACCOUNT_FACTORY = AccountFactory(0xe925f84cA9Dd5b3844fC424861D7bDf9485761B6);

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

/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    AccountFactory.sol :: 0xe925f84cA9Dd5b3844fC424861D7bDf9485761B6
 *    etherscan.io verified 2021-12-18
 */ 

/// @title Brink account factory
/// @notice This is a factory contract used for deployment of Brink proxy accounts
contract AccountFactory {
  error DeployFailed();

  /// @dev Deploys a Proxy account for the given owner
  /// @param owner Owner of the Proxy account
  /// @return account Address of the deployed Proxy account
  /// @notice This deploys a "minimal proxy" contract with the proxy owner address added to the deployed bytecode. The
  /// owner address can be read within a delegatecall by using `extcodecopy`. Minimal proxy bytecode is from
  /// https://medium.com/coinmonks/the-more-minimal-proxy-5756ae08ee48 and https://eips.ethereum.org/EIPS/eip-1167. It
  /// utilizes the "vanity address optimization" from EIP 1167
  function deployAccount(address owner) external returns (address account) {
    bytes memory initCode = abi.encodePacked(
      //  [* constructor **] [** minimal proxy ***] [******* implementation *******] [**** minimal proxy *****]
      hex'603c3d8160093d39f3_3d3d3d3d363d3d37363d6f_afcbce78c080f96032a5c1cb1b832d7b_5af43d3d93803e602657fd5bf3',
      owner
    );
    assembly {
      account := create2(0, add(initCode, 0x20), mload(initCode), 0)
    }
    if(account == address(0)) {
      revert DeployFailed();
    }
  }
}