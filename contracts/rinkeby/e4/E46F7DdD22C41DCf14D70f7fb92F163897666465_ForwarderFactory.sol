// SPDX-License-Identifier: MIT
// from https://github.com/optionality/clone-factory
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

/**
 * Contract that exposes the needed erc20 token functions
*/

abstract contract ERC20Interface {

  /*
  * @dev Send _value amount of tokens to address _to
  * @param _to The destination address
  * @param _value The amount to sent
  */
  function transfer(address _to, uint256 _value) public virtual returns (bool success);

  /*
  * @dev Get the account balance of another account with address _owner
  * @param _owner The address owner
  */
  function balanceOf(address _owner) public virtual view returns (uint256 balance);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

/**
 * Contract that exposes the needed erc721 token functions
*/

abstract contract ERC721Interface {

    /*
    * @dev Send _tokenId token to address _to
    * @param _from The address where the token is assigned
    * @param _to The destination address of the token
    * @param _tokenId The token id
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual;

    /*
    * @dev Get the balance of this contract of address owner
    * @param _owner The address where we want to know the balance
    */
    function balanceOf(address _owner) public virtual view returns (uint256 balance);

    /*
    * @dev Returns a token ID owned by owner at a given index of its token list. Use along with balanceOf to enumerate all of owner's tokens.
    * @param _owner The owner address
    * @param _index The index of the token (related to balanceOf)
    */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public virtual view returns (uint256 tokenId);

    /*
    * @dev Returns if the operator is allowed to manage all of the assets of owner.
    * @param _owner The owner address
    * @param _operator The operator address
    */
    function isApprovedForAll(address _owner, address _operator) public virtual view returns (bool approved);

    /*
    * @dev Approve or remove operator as an operator for the caller. Operators can call transferFrom or safeTransferFrom for any token owned by the caller.
    * @param _owner The operator address
    * @param _approved Flag is approved or not
    */
    function setApprovalForAll(address _operator, bool _approved) public virtual;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import './GenuIERC721Receiver.sol';
import './ERC20Interface.sol';
import './ERC721Interface.sol';

/**
 * Contract that will forward any incoming Ether to the creator of the contract
 *
*/
contract Forwarder is GenuIERC721Receiver {
  /*
   * Constants
  */

  bytes4 private constant ERC721_RECEIVED = 0x150b7a02; // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`

  uint256 internal constant SECONDS_IN_A_DAY = 86400;

  /*
   * Data Structures and value
  */

  address public _parentAddress; // Address to which any funds sent to this contract will be forwarded

  /*
   * Events
  */

  event ForwarderDeposited(address from, uint256 value, bytes data);
  event ForwarderERC721Deposited(address indexed from, uint256[] indexed tokenIds, uint256 indexed time);

  /*
   * Modifiers
  */

  /*
   * @dev Modifier that will execute internal code block only if the sender is the parent address
  */
  modifier onlyParent {
    require(msg.sender == _parentAddress, 'Only Parent');
    _;
  }

  /**
   * @dev Modifier that will execute internal code block only if the contract has not been initialized yet
  */
  modifier onlyUninitialized {
    require(_parentAddress == address(0x0), 'Already initialized');
    _;
  }

  /*
   * Payable functions
  */

  /*
   * @dev Default function; Gets called when data is sent but does not match any other function
  */
  fallback() external payable {
    flush();
  }

  /*
   * @dev Default function; Gets called when Ether is deposited with no data, and forwards it to the parent address
  */
  receive() external payable {
    flush();
  }

  /*
   * @dev Initialize the contract, and sets the destination address to that of the creator
   * @param _parentAddress
  */
  function init(address parentAddress) external onlyUninitialized {
    _parentAddress = parentAddress;
    uint256 _value = address(this).balance;

    if (_value == 0) {
      return;
    }

    (bool _success, ) = _parentAddress.call{ value: _value }('');
    require(_success, 'Flush failed');
    // NOTE: since we are forwarding on initialization,
    // we don't have the context of the original sender.
    // We still emit an event about the forwarding but set
    // the sender to the forwarder itself
    emit ForwarderDeposited(address(this), _value, msg.data);
  }

  /**
   * @dev Execute a token transfer of the full balance from the forwarder token to the parent address
   * @param tokenContractAddress the address of the erc20 token contract
  */
  function flushTokens(address tokenContractAddress) external onlyParent {
    ERC20Interface _instance = ERC20Interface(tokenContractAddress);
    address _forwarderAddress = address(this);
    uint256 _forwarderBalance = _instance.balanceOf(_forwarderAddress);
    if (_forwarderBalance == 0) {
      return;
    }

    TransferHelper.safeTransfer(
      tokenContractAddress,
      _parentAddress,
      _forwarderBalance
    );
  }

  /**
   * @dev Execute a token transfer of the full balance from the forwarder token to the parent address
   * @param tokenContractAddress the address of the erc721 token contract
  */
  function flushTokensERC721(address tokenContractAddress) external onlyParent {
    ERC721Interface _instance = ERC721Interface(tokenContractAddress);
    address _forwarderAddress = address(this);
    uint256 _forwarderBalance = _instance.balanceOf(_forwarderAddress);
    if (_forwarderBalance == 0) {
      return;
    }

    if (_instance.isApprovedForAll(_forwarderAddress, _parentAddress) == false) {
      _instance.setApprovalForAll(_parentAddress, true);
    }

    uint256[] memory _tokenIds = new uint256[](_forwarderBalance);

    for(uint256 i = 0; i < _forwarderBalance; i++) {
      uint256 _tokenId = _instance.tokenOfOwnerByIndex(_forwarderAddress, 0);
      _instance.safeTransferFrom(_forwarderAddress, _parentAddress, _tokenId);
      _tokenIds[i] = _tokenId;
    }
    emit ForwarderERC721Deposited(_forwarderAddress, _tokenIds, block.timestamp - (block.timestamp % SECONDS_IN_A_DAY));
  }

  /**
   * @dev Execute a token transfer of the full balance from the forwarder token to the parent address
   * @param tokenContractAddress the address of the erc721 token contract
   * @param quantity the quantity to move
  */
  function flushTokensERC721(address tokenContractAddress, uint256 quantity) external onlyParent {
    ERC721Interface _instance = ERC721Interface(tokenContractAddress);
    address _forwarderAddress = address(this);
    uint256 _forwarderBalance = _instance.balanceOf(_forwarderAddress);
    require(quantity <= _forwarderBalance, "The quantity cannot be greater than current balance");
    if (_forwarderBalance == 0) {
      return;
    }

    if (!_instance.isApprovedForAll(_forwarderAddress, _parentAddress)) {
      _instance.setApprovalForAll(_parentAddress, true);
    }

    uint256[] memory _tokenIds = new uint256[](_forwarderBalance);

    for(uint256 i = 0; i < quantity; i++) {
      uint256 _tokenId = _instance.tokenOfOwnerByIndex(_forwarderAddress, 0);
      _instance.safeTransferFrom(_forwarderAddress, _parentAddress, _tokenId);
      _tokenIds[i] = _tokenId;
    }
    emit ForwarderERC721Deposited(_forwarderAddress, _tokenIds, block.timestamp - (block.timestamp % SECONDS_IN_A_DAY));
  }

  /**
   * @dev Flush the entire balance of the contract to the parent address.
  */
  function flush() public {
    uint256 _value = address(this).balance;

    if (_value == 0) {
      return;
    }

    (bool _success, ) = _parentAddress.call{ value: _value }('');
    require(_success, 'Flush failed');
    emit ForwarderDeposited(msg.sender, _value, msg.data);
  }

  /**
   * @dev Override, this function is a hook and it is called before each token transfer.
   * @param operator The address operator
   * @param from The address from
   * @param tokenId The token id
   * @param data The data
  */
  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
    return ERC721_RECEIVED;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
import './Forwarder.sol';
import './CloneFactory.sol';

contract ForwarderFactory is CloneFactory {

  /*
   * Data Structures and value
  */

  address public _implementationAddress;

  /*
   * Events
  */

  event ForwarderCreated(address newForwarderAddress, address parentAddress);

  /*
   * Constructor
  */

  constructor(address implementationAddress) {
    _implementationAddress = implementationAddress;
  }

  /**
  * @dev Create the token and emit a TokenCreated event
  * @param parent the token ID of the token to create
  * @param salt the token URI associated with this token
  */
  function createForwarder(address parent, bytes32 salt) external {
    // include the signers in the salt so any contract deployed to a given address must have the same signers
    bytes32 _finalSalt = keccak256(abi.encodePacked(parent, salt));

    address payable clone = createClone(_implementationAddress, _finalSalt);
    Forwarder(clone).init(parent);
    emit ForwarderCreated(clone, parent);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface GenuIERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}