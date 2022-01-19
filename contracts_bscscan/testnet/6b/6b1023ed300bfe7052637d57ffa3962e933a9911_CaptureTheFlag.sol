/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



pragma solidity ^0.8.0;


contract CaptureTheFlag is Ownable {

	bytes32 public whiteListRootHash;

	address public currentFlagHolder;

	event AddNewMember(address newMember, bytes32 oldRoot, bytes32 newRoot);
	
	function addMember(address newMember, address[] memory oldAddresses) public payable onlyOwner {
		bytes32 oldHash = getRootHash(oldAddresses);
		require(oldHash == whiteListRootHash, 'CaptureTheFlag: Roots do not match');
		address[] memory newAddresses = new address[](oldAddresses.length + 1);
		for (uint256 i; i < oldAddresses.length; i++) {
			newAddresses[i] = oldAddresses[i];
		}
		newAddresses[newAddresses.length - 1] = newMember;
		bytes32 newHash = getRootHash(newAddresses);
		whiteListRootHash = newHash;
		emit AddNewMember(newMember, oldHash, newHash);
	}
	
	function fillAddresses(address[] memory addresses) internal pure returns(address[] memory) {
		uint256 length = addresses.length;
		uint256 newLength = length;
		while (newLength & (newLength - 1) != 0) {
			newLength++;
		}
		address[] memory newAddresses = new address[](newLength);
		for (uint256 i; i < length; i++) {
			newAddresses[i] = addresses[i];
		}
		return newAddresses;
	}
	
//  sort is not important
//	function sortAddresses(address[] memory addresses) public pure returns (address[] memory) {
//		quickSort(addresses, int(0), int(addresses.length - 1));
//		return addresses;
//	}
	
	function quickSort(address[] memory addresses, int left, int right) public pure {
		int i = left;
		int j = right;
		if(i==j) return;
		address pivot = addresses[uint(left + (right - left) / 2)];
		while (i <= j) {
			while (addresses[uint(i)] < pivot) i++;
			while (pivot < addresses[uint(j)]) j--;
			if (i <= j) {
				(addresses[uint(i)],addresses[uint(j)]) = (addresses[uint(j)], addresses[uint(i)]);
				i++;
				j--;
			}
		}
		if (left < j)
			quickSort(addresses, left, j);
		if (i < right)
			quickSort(addresses, i, right);
	}
	
	function getLeaves(address[] memory addresses) internal pure returns(bytes32[] memory) {
		uint256 length = addresses.length;
//		addresses = sortAddresses(addresses); // sorting
		bytes32[] memory leaves = new bytes32[](length);
		for (uint256 i; i < length; i++) {
			leaves[i] = keccak256(abi.encodePacked(i, addresses[i])); // get hash from original data
		}
		return leaves;
	}
	
	function getNodes(address[] memory addresses) internal pure returns(bytes32[] memory) {
		bytes32[] memory leaves = getLeaves(addresses);
		uint256 length = leaves.length;
		uint256 nodeCount = (length * 2) - 1; // length of all nodes
		bytes32[] memory nodes = new bytes32[](nodeCount);
		for (uint256 i = 0; i < leaves.length; i++) {
			nodes[i] = leaves[i]; // put first layer of hashes to nodes
		}
		uint256 path = length; // path equal to current layer length
		uint256 offset = 0; // needs to skip passed layer
		uint256 iteration = length;
		while (path > 0) {
			for (uint256 i = 0; i < path - 1; i += 2) {
				nodes[iteration] = keccak256(
					abi.encodePacked(nodes[offset + i], nodes[offset + i + 1])
					// get hashes on next layers, until root, last item of nodes is rootHash
				);
				iteration++;
			}
			offset += path;
			path /= 2; // get next layer length
		}
		return nodes;
	}
	
	function getRootHash(address[] memory addresses) internal pure returns(bytes32) {
		if (addresses.length == 0) {
			return bytes32(0);
		}
		bytes32[] memory nodes = getNodes(fillAddresses(addresses));
		return nodes[nodes.length - 1];
	}
	
	function log2(uint256 x) public pure returns (uint256 y) {
		assembly {
			let arg := x
			x := sub(x,1)
			x := or(x, div(x, 0x02))
			x := or(x, div(x, 0x04))
			x := or(x, div(x, 0x10))
			x := or(x, div(x, 0x100))
			x := or(x, div(x, 0x10000))
			x := or(x, div(x, 0x100000000))
			x := or(x, div(x, 0x10000000000000000))
			x := or(x, div(x, 0x100000000000000000000000000000000))
			x := add(x, 1)
			let m := mload(0x40)
			mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
			mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
			mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
			mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
			mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
			mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
			mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
			mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
			mstore(0x40, add(m, 0x100))
			let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
			let shift := 0x100000000000000000000000000000000000000000000000000000000000000
			let a := div(mul(x, magic), shift)
			y := div(mload(add(m,sub(255,a))), shift)
			y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
		}
	}
	
	function getProof(
		address candidate,
		address[] memory addresses
	) public pure returns(bytes32[] memory proof, uint256 index) {
		address[] memory filledAddresses = fillAddresses(addresses);
		uint256 length = filledAddresses.length;
		uint256 proofLength = log2(length);
		if (proofLength == 0) {
			proofLength = 1;
		}
		proof = new bytes32[](proofLength);
		bytes32[] memory nodes = getNodes(filledAddresses);
//		filledAddresses = sortAddresses(filledAddresses);
		for (uint256 i; i < length; i++) {
			if (filledAddresses[i] == candidate) {
				index = i;
				break;
			}
		}
		uint256 pathItem = index; // pathItem needs to know is item odd
		uint256 pathLayer = length; // current layer length
		uint256 offset = 0; // needs to skip passed layer
		uint256 iteration = 0;
		while (pathLayer > 1) {
			bytes32 node;
			if ((pathItem & 0x01) == 1) { // if odd
				node = nodes[offset + pathItem - 1];
			} else {
				node = nodes[offset + pathItem + 1];
			}
			proof[iteration] = node;
			iteration++;
			offset += pathLayer;
			pathLayer /= 2;
			pathItem /= 2;
		}
	}
	
	function verify(
		address candidate,
		uint256 index,
		bytes32[] calldata proof
	) public view returns(bool) {
		// get leave of current pretender value
		bytes32 node = keccak256(abi.encodePacked(index, candidate));
		uint256 path = index; // path needs to know is item odd
		if (proof[0] != 0) {
			for (uint16 i = 0; i < proof.length; i++) {
				// get next nodes from previous nodes until arrived root
				if ((path & 0x01) == 1) { // if odd
					node = keccak256(abi.encodePacked(proof[i], node));
				} else {
					node = keccak256(abi.encodePacked(node, proof[i]));
				}
				path /= 2;
			}
		}
		return node == whiteListRootHash;
	}

	function capture(uint256 index, bytes32[] calldata proof) public payable {
		require(verify(msg.sender, index, proof), 'CaptureTheFlag: Invalid proof');
		currentFlagHolder = msg.sender;
	}
}