/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;
// File: contracts/ICounterfactualNFT.sol

// Copyright 2017 Loopring Technology Limited.



/**
 * @title ICounterfactualNFT
 */
abstract contract ICounterfactualNFT
{
    function initialize(address owner, string memory _uri)
        public
        virtual;
}

// File: @openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol

// OpenZeppelin Contracts v4.4.0 (utils/Create2.sol)


/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2Upgradeable {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// File: contracts/external/CloneFactory.sol

// This code is taken from https://eips.ethereum.org/EIPS/eip-1167
// Modified to a library and generalized to support create/create2.

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

library CloneFactory {
  function getByteCode(address target) internal pure returns (bytes memory byteCode) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      byteCode := mload(0x40)
      mstore(byteCode, 0x37)

      let clone := add(byteCode, 0x20)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      mstore(0x40, add(byteCode, 0x60))
    }
  }
}

// File: ../contracts/NFTFactory.sol

// Copyright 2017 Loopring Technology Limited.





/// @title NFTFactory
/// @author Brecht Devos - <[email protected]>
contract NFTFactory
{
    event NFTContractCreated (address nftContract, address owner, string baseURI);

    string public constant NFT_CONTRACT_CREATION = "NFT_CONTRACT_CREATION";
    address public immutable implementation;

    constructor(
        address _implementation
        )
    {
        implementation = _implementation;
    }

    /// @dev Create a new NFT contract.
    /// @param owner The NFT contract owner.
    /// @param baseURI The base token URI (empty string allowed/encouraged to use IPFS mode)
    /// @return nftContract The new NFT contract address
    function createNftContract(
        address            owner,
        string    calldata baseURI
        )
        external
        payable
        returns (address nftContract)
    {
        // Deploy the proxy contract
        nftContract = Create2Upgradeable.deploy(
            0,
            keccak256(abi.encodePacked(NFT_CONTRACT_CREATION, owner, baseURI)),
            CloneFactory.getByteCode(implementation)
        );

        // Initialize
        ICounterfactualNFT(nftContract).initialize(owner, baseURI);

        emit NFTContractCreated(nftContract, owner, baseURI);
    }

    function computeNftContractAddress(
        address          owner,
        string  calldata baseURI
        )
        public
        view
        returns (address)
    {
        return _computeAddress(owner, baseURI);
    }

    function getNftContractCreationCode()
        public
        view
        returns (bytes memory)
    {
        return CloneFactory.getByteCode(implementation);
    }

    function _computeAddress(
        address          owner,
        string  calldata baseURI
        )
        private
        view
        returns (address)
    {
        return Create2Upgradeable.computeAddress(
            keccak256(abi.encodePacked(NFT_CONTRACT_CREATION, owner, baseURI)),
            keccak256(CloneFactory.getByteCode(implementation))
        );
    }
}