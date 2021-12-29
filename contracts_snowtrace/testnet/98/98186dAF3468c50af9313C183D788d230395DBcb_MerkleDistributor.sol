/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

library AddressUtils {
    
    function toPayable(address addr) internal pure returns (address payable) {
        return address(bytes20(addr));
    }

    /**
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     */
    function isContract(address addr) internal view returns (bool result) {
        assembly {
            result := iszero(iszero(extcodesize(addr)))
        }
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 {
    // Optional fields 
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);


    function totalSupply() external view returns (uint256);

    function balanceOf(address _who) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/*
 * SPDX-License-Identifier:    MIT
 */

// From https://github.com/aragon/aragonOS/blob/next/contracts/common/SafeERC20.sol

// Inspired by AdEx (https://github.com/AdExNetwork/adex-protocol-eth/blob/b9df617829661a7518ee10f4cb6c4108659dd6d5/contracts/libs/SafeERC20.sol)
// and 0x (https://github.com/0xProject/0x-monorepo/blob/737d1dc54d72872e24abce5a1dbe1b66d35fa21a/contracts/protocol/contracts/protocol/AssetProxy/ERC20Proxy.sol#L143)

pragma solidity ^0.6.8;

import "../address-utils/AddressUtils.sol";

import "./ERC20.sol";

library SafeERC20 {
    using AddressUtils for address;

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata)
        private
        returns (bool ret)
    {
        if (!_addr.isContract()) {
            return false;
        }

        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas(),                // forward all
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                // Check number of bytes returned from last function call
                switch returndatasize()

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                    // Only return success if returned data was true
                    // Already have output in ptr
                    ret := iszero(iszero(mload(ptr)))
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
    }

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            _token.transfer.selector,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferFromCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.approve() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeApprove(ERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), approveCallData);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.6.8;

contract Initializable {
    mapping (string => uint256) public initBlocks;

    event Initialized(string indexed key);

    modifier onlyInit(string memory key) {
        require(initBlocks[key] == 0, "initializable: already initialized");
        initBlocks[key] = block.number;
        _;
        emit Initialized(key);
    }
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

// Copied and modified from: https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

import "@aragon/govern-contract-utils/contracts/erc20/SafeERC20.sol";
import "@aragon/govern-contract-utils/contracts/initializable/Initializable.sol";

contract MerkleDistributor is Initializable {
    
    using SafeERC20 for ERC20;

    ERC20 public token;
    bytes32 public merkleRoot;

    // This is a packed array of booleans.
    mapping (uint256 => uint256) private claimedBitMap;

    event Claimed(uint256 indexed index, address indexed to, uint256 amount);

    constructor() public {
        initialize(ERC20(address(0)), bytes32(0));
    }

    function initialize(ERC20 _token, bytes32 _merkleRoot) public onlyInit("distributor") {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 _index, address _to, uint256 _amount, bytes32[] calldata _merkleProof) external {
        require(!isClaimed(_index), "dist: already claimed");
        require(_verifyBalanceOnTree(_index, _to, _amount, _merkleProof), "dist: proof failed");

        _setClaimed(_index);
        token.safeTransfer(_to, _amount);

        emit Claimed(_index, _to, _amount);
    }

    function unclaimedBalance(uint256 _index, address _to, uint256 _amount, bytes32[] memory _proof) public view returns (uint256) {
        if (isClaimed(_index)) return 0;
        return _verifyBalanceOnTree(_index, _to, _amount, _proof) ? _amount : 0;
    }

    function _verifyBalanceOnTree(uint256 _index, address _to, uint256 _amount, bytes32[] memory _proof) internal view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_index, _to, _amount));
        return MerkleProof.verify(_proof, merkleRoot, node);
    }

    function isClaimed(uint256 _index) public view returns (bool) {
        uint256 claimedWord_index = _index / 256;
        uint256 claimedBit_index = _index % 256;
        uint256 claimedWord = claimedBitMap[claimedWord_index];
        uint256 mask = (1 << claimedBit_index);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 _index) private {
        uint256 claimedWord_index = _index / 256;
        uint256 claimedBit_index = _index % 256;
        claimedBitMap[claimedWord_index] = claimedBitMap[claimedWord_index] | (1 << claimedBit_index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}