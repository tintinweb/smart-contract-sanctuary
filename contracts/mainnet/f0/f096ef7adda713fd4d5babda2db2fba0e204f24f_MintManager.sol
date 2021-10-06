// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface BaseTokenContract {
      function mintTokenPrivileged(address _recipient) external payable;
}

interface ISaconiStakingAgent is IERC721Enumerable {
    function isStakedByAddress(address staker, address tokenContract, uint256 tokenID) external view returns (bool);
}

contract MintManager is Ownable {
    
    uint256 constant tokenPrice = 100000000000000000;
    
    uint256 constant normalLimit = 1241; // 3000 - 1659 - 100
    uint256 constant waltzLimit = 100;
    
    address constant waltzAddress = 0xD58434F33a20661f186ff67626ea6BDf41B80bCA; // Mainnet
  	address constant saconiStakingAddress = 0x23e369A9A725c7Da18d023d1C7c8b928237e24f7; // Mainnet
  	ISaconiStakingAgent ITokenContract = ISaconiStakingAgent(saconiStakingAddress);
    
    // Needed for staking function to check tokenId
    address constant saconiHolmovimientoAddress = 0x0B1F901EEDfa11E7cf65efeB566EEffb6D38fbc0; // Mainnet
    address constant baseAddress = 0xEc8bcffD08bb22Aed27F083b59212b8194B99dBa; // Mainnet

    bool specialMintingEnabled;
    bool normalMintingEnabled;
    
    uint256 waltzCount;
    uint256 normalCount;
    
    address payable recipient1;
    address payable recipient2;
    address payable recipient3;

    
    mapping (uint256 => bool) waltzTokenIsRedeemed;
    mapping (address => uint256) freeMintsClaimedSaconi;
    
    constructor() {
        recipient1 = payable(0x6a024f521f83906671e1a23a8B6c560be7e980F4);
        recipient2 = payable(0x212Da8c9Dad7e9B6a71422665c58Bf9a7ECAe6D0);
        recipient3 = payable(0xf0bE1F2FB8abfa9aBF7d218a226ef4F046f09a40);
        
        specialMintingEnabled = false;
        normalMintingEnabled = false;
        
        waltzCount = 0;
        normalCount = 0;
    }
    
    function mintSpecialSaconi() private {
        require(specialMintingEnabled == true, "Special minting not enabled");
        BaseTokenContract(baseAddress).mintTokenPrivileged(msg.sender);
    }
  
    function maxFreeClaimsSaconi(uint256 stakedAmount) internal pure returns (uint256) {
        if (stakedAmount >= 7) {
            return 4+(stakedAmount-5)/2;
        } else if (stakedAmount >= 4) {
            return 3;
        } else if (stakedAmount >= 2) {
            return 2;
        } else if (stakedAmount == 1) {
            return 1;
        } else {
            return 0;
        }
    }
  
    function claimFreeMintsSaconi(uint256 mint, uint256 stakedAmount, uint256[] calldata tokenIDList) external {
        require(mint <= 10, "Max. 10 per transaction");
        
        for (uint256 i=0; i<stakedAmount; i++) {
            require(ITokenContract.isStakedByAddress(msg.sender, saconiHolmovimientoAddress, tokenIDList[i]), "Token not owned");
        }
        require(mint + freeMintsClaimedSaconi[msg.sender] <= maxFreeClaimsSaconi(stakedAmount), "All free mints used");
        
        for (uint256 i=0; i<mint; i++) {
            // no need for args, internal function
            mintSpecialSaconi();
            freeMintsClaimedSaconi[msg.sender]++;
        }
    }
    
    function mintPaid() internal {
        require(msg.value == tokenPrice, "Incorrect value");
        BaseTokenContract(baseAddress).mintTokenPrivileged(msg.sender);
        
        uint256 part1 = (33 * 100 * msg.value) / (100*100);
        uint256 part2 = (33 * 100 * msg.value) / (100*100);
        uint256 part3 = (msg.value) - (part1+part2);
        recipient1.transfer(part1);
        recipient2.transfer(part2);
        recipient3.transfer(part3);
    }
    
    function mintSpecialWaltz() public payable {
        require(specialMintingEnabled == true, "Special minting not enabled");
        require(waltzCount < waltzLimit, "WALTZ special limit reached");
        waltzCount++;
        uint256 ownedTokenID = IERC721Enumerable(waltzAddress).tokenOfOwnerByIndex(msg.sender, 0);
        require(waltzTokenIsRedeemed[ownedTokenID] == false);
        waltzTokenIsRedeemed[ownedTokenID] = true;
        mintPaid();
    }
    
    function mintNormal() public payable {
        require(normalMintingEnabled == true, "Normal minting not enabled");
      	require(normalCount < normalLimit, "Normal limit reached");
      	normalCount++;
        mintPaid();
    }
    
    function setMintingEnabled(bool _specialMintingEnabled, bool _normalMintingEnabled) public onlyOwner {
        specialMintingEnabled = _specialMintingEnabled;
        normalMintingEnabled = _normalMintingEnabled;
    }

}

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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}