// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Registry holding the rarity value of a given NFT.
/// @author Nemitari Ajienka @najienka
interface INFTRarityRegister {
	/**
	 * The Staking SC allows to stake Prizes won via lottery which can be used to increase the APY of
	 * staked tokens according to the rarity of NFT staked. For this reason,
	 * we need to hold a table that the Staking SC can query and get back the rarity value of a given
	 * NFT price (even the ones in the past).
	 */
	event NftRarityStored(
		address indexed tokenAddress,
		uint256 tokenId,
		uint256 rarityValue
	);

	/**
	 * @dev Store the rarity of a given NFT
	 * @param tokenAddress The NFT smart contract address e.g., ERC-721 standard contract
	 * @param tokenId The NFT's unique token id
	 * @param rarityValue The rarity of a given NFT address and id unique combination
	 */
	function storeNftRarity(address tokenAddress, uint256 tokenId, uint8 rarityValue) external;

	/**
	 * @dev Get the rarity of a given NFT
	 * @param tokenAddress The NFT smart contract address e.g., ERC-721 standard contract
	 * @param tokenId The NFT's unique token id
	 * @return The the rarity of a given NFT address and id unique combination and timestamp
	 */
	function getNftRarity(address tokenAddress, uint256 tokenId) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTRarityRegister.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Registry holding the rarity value of a given NFT.
/// @author Nemitari Ajienka @najienka
contract NFTRarityRegister is INFTRarityRegister, Ownable {
	mapping(address => mapping(uint256 => uint8)) private rarityRegister;

	/**
	 * @dev Store the rarity of a given NFT
	 * @param tokenAddress The NFT smart contract address e.g., ERC-721 standard contract
	 * @param tokenId The NFT's unique token id
	 * @param rarityValue The rarity of a given NFT address and id unique combination
	 * using percentage i.e., 100% = 1000 to correct for precision and
	 * to save gas required when converting from category, e.g.,
	 * high, medium, low to percentage in staking contract
	 * can apply rarityValue on interests directly after fetching
	 */
	function storeNftRarity(address tokenAddress, uint tokenId, uint8 rarityValue) external override onlyOwner {
		// check tokenAddress, tokenId and rarityValue are valid
		// _exists ERC721 function is internal
		require(tokenAddress != address(0), "NFTRarityRegister: Token address is invalid");
		require(getNftRarity(tokenAddress, tokenId) == 0, "NFTRarityRegister: Rarity already set for token");
		require(rarityValue >= 100, "NFTRarityRegister: Value must be at least 100");

		rarityRegister[tokenAddress][tokenId] = rarityValue;

		emit NftRarityStored(tokenAddress, tokenId, rarityValue);
	}

	/**
	 * @dev Get the rarity of a given NFT
	 * @param tokenAddress The NFT smart contract address e.g., ERC-721 standard contract
	 * @param tokenId The NFT's unique token id
	 * @return The the rarity of a given NFT address and id unique combination and timestamp
	 */
	function getNftRarity(address tokenAddress, uint256 tokenId) public override view returns (uint8) {
		return rarityRegister[tokenAddress][tokenId];
	}
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "remappings": [],
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