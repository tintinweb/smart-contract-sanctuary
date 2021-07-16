/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
/*
    The MIT License (MIT)
    Copyright (c) 2018 Murray Software, LLC.
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {
  function createClone(address target, bytes32 salt)
    internal
    returns (address payable result)
  {
    bytes20 targetBytes = bytes20(target);
    assembly {
      // load the next free memory slot as a place to store the clone contract data
      let clone := mload(0x40)

      // The bytecode block below is responsible for contract initialization
      // during deployment, it is worth noting the proxied contract constructor will not be called during
      // the cloning procedure and that is why an initialization function needs to be called after the
      // clone is created
      mstore(
        clone,
        0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
      )

      // This stores the address location of the implementation contract
      // so that the proxy knows where to delegate call logic to
      mstore(add(clone, 0x14), targetBytes)

      // The bytecode block is the actual code that is deployed for each clone created.
      // It forwards all calls to the already deployed implementation via a delegatecall
      mstore(
        add(clone, 0x28),
        0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
      )

      // deploy the contract using the CREATE2 opcode
      // this deploys the minimal proxy defined above, which will proxy all
      // calls to use the logic defined in the implementation contract `target`
      result := create2(0, clone, 0x37, salt)
    }
  }

  function isClone(address target, address query)
    internal
    view
    returns (bool result)
  {
    bytes20 targetBytes = bytes20(target);
    assembly {
      // load the next free memory slot as a place to store the comparison clone
      let clone := mload(0x40)

      // The next three lines store the expected bytecode for a miniml proxy
      // that targets `target` as its implementation contract
      mstore(
        clone,
        0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
      )
      mstore(add(clone, 0xa), targetBytes)
      mstore(
        add(clone, 0x1e),
        0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
      )

      // the next two lines store the bytecode of the contract that we are checking in memory
      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)

      // Check if the expected bytecode equals the actual bytecode and return the result
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}


/**
 * Contract that exposes the needed erc20 token functions
 */

abstract contract ERC20Interface {
  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value)
    public
    virtual
    returns (bool success);

  // Get the account balance of another account with address _owner
  function balanceOf(address _owner)
    public
    virtual
    view
    returns (uint256 balance);
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


/**
 * Contract that will forward any incoming Ether to the creator of the contract
 *
 */
contract Forwarder {
  // Address to which any funds sent to this contract will be forwarded
  address public parentAddress;
  event ForwarderDeposited(address from, uint256 value, bytes data);

  /**
   * Initialize the contract, and sets the destination address to that of the creator
   */
  function init(address _parentAddress) external onlyUninitialized {
    parentAddress = _parentAddress;
    uint256 value = address(this).balance;

    if (value == 0) {
      return;
    }

    (bool success, ) = parentAddress.call{ value: value }('');
    require(success, 'Flush failed');
    // NOTE: since we are forwarding on initialization,
    // we don't have the context of the original sender.
    // We still emit an event about the forwarding but set
    // the sender to the forwarder itself
    emit ForwarderDeposited(address(this), value, msg.data);
  }

  /**
   * Modifier that will execute internal code block only if the sender is the parent address
   */
  modifier onlyParent {
    require(msg.sender == parentAddress, 'Only Parent');
    _;
  }

  /**
   * Modifier that will execute internal code block only if the contract has not been initialized yet
   */
  modifier onlyUninitialized {
    require(parentAddress == address(0x0), 'Already initialized');
    _;
  }

  /**
   * Default function; Gets called when data is sent but does not match any other function
   */
  fallback() external payable {
    flush();
  }

  /**
   * Default function; Gets called when Ether is deposited with no data, and forwards it to the parent address
   */
  receive() external payable {
    flush();
  }

  /**
   * Execute a token transfer of the full balance from the forwarder token to the parent address
   * @param tokenContractAddress the address of the erc20 token contract
   */
  function flushTokens(address tokenContractAddress) external onlyParent {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    address forwarderAddress = address(this);
    uint256 forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }

    TransferHelper.safeTransfer(
      tokenContractAddress,
      parentAddress,
      forwarderBalance
    );
  }

  /**
   * Flush the entire balance of the contract to the parent address.
   */
  function flush() public {
    uint256 value = address(this).balance;

    if (value == 0) {
      return;
    }

    (bool success, ) = parentAddress.call{ value: value }('');
    require(success, 'Flush failed');
    emit ForwarderDeposited(msg.sender, value, msg.data);
  }
}

contract ForwarderFactory is CloneFactory {
  address public implementationAddress;

  event ForwarderCreated(address newForwarderAddress, address parentAddress);

  constructor(address _implementationAddress) {
    implementationAddress = _implementationAddress;
  }

  function createForwarder(address parent, bytes32 salt) external {
    // include the signers in the salt so any contract deployed to a given address must have the same signers
    bytes32 finalSalt = keccak256(abi.encodePacked(parent, salt));

    address payable clone = createClone(implementationAddress, finalSalt);
    Forwarder(clone).init(parent);
    emit ForwarderCreated(clone, parent);
  }
}