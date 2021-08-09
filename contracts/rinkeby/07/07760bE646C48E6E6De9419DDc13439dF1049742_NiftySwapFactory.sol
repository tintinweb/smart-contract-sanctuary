// SPDX-License-Identifier: GPL 3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./NiftySwap.sol";
import "./CrossNiftySwap.sol";

contract NiftySwapFactory {

  /// @dev NiftySwap for swapping NFTs across NFT collections.
  address public crossNiftySwap;

  /// @dev Mapping from NFT collection => NiftySwap for that collection
  mapping(address => address) public swapRegistry;

  /// @dev Events
  event NiftySwapCreated(address nft, address niftyswap);

  modifier onlyValidNFT(address _nftContract) {
    require(
      IERC721(_nftContract).supportsInterface(type(IERC721).interfaceId) || 
      IERC721(_nftContract).supportsInterface(type(IERC721Metadata).interfaceId),
      "NiftySwapFactory: The NFT contract must implement ERC 721." 
    );

    _;
  }

  constructor() {}

  /// @dev Deploys a niftyswap for an NFT collection.
  function createNiftySwap(address _nft) external onlyValidNFT(_nft) {

    // Deploy with CREATE2
    bytes memory niftySwapBytecode = abi.encodePacked(type(NiftySwap).creationCode, abi.encode(_nft));
    bytes32 niftySwapSalt = keccak256(abi.encode(block.number, msg.sender));

    address niftyswap = Create2.deploy(0, niftySwapSalt, niftySwapBytecode);

    // Update niftyswap registry
    swapRegistry[_nft] = niftyswap;

    emit NiftySwapCreated(_nft, niftyswap);
  }

  /// @dev Deploys `crossNiftySwap` for swapping NFTs across NFT collections.
  function createCrossSwap() external {
    require(crossNiftySwap == address(0), "NiftySwapFactory: Cross NiftySwap already created.");
    
    // Deploy with CREATE2
    bytes memory crossSwapBytecode = type(CrossNiftySwap).creationCode;
    bytes32 crossSwapSalt = keccak256(abi.encode(block.number, msg.sender));
    
    crossNiftySwap = Create2.deploy(0, crossSwapSalt, crossSwapBytecode);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL 3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract NiftySwap {

  /// @dev The contract's primary NFT collection.
  IERC721Metadata public nifty;

  /// @dev Token ID of NFT to trade => Token ID of NFT wanted => Interested in trade.
  mapping(uint => mapping(uint => bool)) public interestInTrade;

  /// @dev Token ID of NFT to trade => Token ID of NFT wanted => owner of NFT to trade.
  mapping(uint => mapping(uint => address)) public ownerAtSignal;

  constructor(address _nifty) {
    nifty = IERC721Metadata(_nifty);
  }

  event InterestInTrade(uint indexed tokenIdOfWanted, uint indexed tokenIdToTrade, address indexed trader);
  event Trade(address ownerOfNft1, uint indexed tokenId1, address ownerOfNft2, uint indexed tokenId2);

  /// @dev Signal interest to trade an NFT you own for an NFT you want. If both parties signal interest, the NFTs are swapped.
  function signalInterest(uint _tokenIdNftWanted, uint _tokenIdNftToTrade, bool _interest) external {
    require(
      nifty.ownerOf(_tokenIdNftToTrade) == msg.sender, 
      "NiftySwap: Cannot signal interest to trade an NFT you do not own."
    );

    require(
      nifty.getApproved(_tokenIdNftToTrade) == address(this) ||
      
      nifty.isApprovedForAll(msg.sender, address(this)),
      "NiftySwap: This contract is no longer approved to transfer the NFT wanted."
    );

    if(interestInTrade[_tokenIdNftWanted][_tokenIdNftToTrade] && _interest) {

      address ownerOfWanted = nifty.ownerOf(_tokenIdNftWanted);

      require(
        ownerAtSignal[_tokenIdNftWanted][_tokenIdNftToTrade] == ownerOfWanted,
        "NiftySwap: The owner of the NFT you wanted has changed."
      );

      trade(_tokenIdNftWanted, _tokenIdNftToTrade, msg.sender);

    } else {

      interestInTrade[_tokenIdNftToTrade][_tokenIdNftWanted] = _interest;
      ownerAtSignal[_tokenIdNftToTrade][_tokenIdNftWanted] = msg.sender;

      emit InterestInTrade(_tokenIdNftWanted, _tokenIdNftToTrade, msg.sender);

    }
  }

  /// @dev Trades one NFT for another.
  function trade(uint _tokenIdNftWanted, uint _tokenIdNftToTrade, address _ownerOfNftToTrade) internal {

    // Get owner of NFT wanted.
    address ownerOfNftWanted = nifty.ownerOf(_tokenIdNftWanted);

    // Transfer NFT to trade.
    nifty.transferFrom(
      _ownerOfNftToTrade,
      ownerOfNftWanted,
      _tokenIdNftToTrade
    );

    // Transfer NFT wanted.
    nifty.transferFrom(
      ownerOfNftWanted,
      _ownerOfNftToTrade,
      _tokenIdNftWanted
    );

    emit Trade(_ownerOfNftToTrade, _tokenIdNftToTrade, ownerOfNftWanted, _tokenIdNftWanted);
  }
}

// SPDX-License-Identifier: GPL 3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract CrossNiftySwap {
  
  uint public nextSwapId;
  
  struct TradeableNFT {
    address ownerAtTrade;
    address nftContract;
    uint nftTokenId;
  }

  /// @dev NFT contract => tokenId => Swap ID
  mapping(address => mapping(uint => uint)) public swapId;

  /// @dev Swap ID => NFT
  mapping(uint => TradeableNFT) public tradeableNFT;

  /// @dev Swap ID of NFT to trade => Swap ID of NFT wanted => Interested in trade.
  mapping(uint => mapping(uint => bool)) public interestInTrade;

  /// @dev Events.
  event AvailableForTrade(address indexed owner, address indexed nftContract, uint indexed tokenId, uint swapId);
  event InterestInTrade(uint indexed swapIdOfWanted, uint indexed swapIdToTrade);
  event Trade(
      address indexed nftWanted,
      uint tokenIdOfWanted,
      address ownerOfWanted,
      uint swapIdOfWanted,

      address indexed nftTraded,
      uint tokenIdOfTraded,
      address ownerOfTraded,
      uint swapIdToTrade
    );

  modifier onlyTradeable(address _nftContract, uint _tokenId) {

    require(
      swapId[_nftContract][_tokenId] == 0 || tradeableNFT[swapId[_nftContract][_tokenId]].ownerAtTrade != msg.sender, 
      "NiftySwap: The NFT is already up for trade."
    );

    require(
      IERC721(_nftContract).supportsInterface(type(IERC721).interfaceId) || 
      IERC721(_nftContract).supportsInterface(type(IERC721Metadata).interfaceId),
      "NiftySwap: The NFT contract must implement ERC 721." 
    );

    require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "NiftySwap: Must own the NFT to trade it.");

    require(
      IERC721(_nftContract).getApproved(_tokenId) == address(this) || IERC721(_nftContract).isApprovedForAll(msg.sender, address(this)),
      "NiftySwap: Must approve this contract to transfer the NFT."
    );

    _;
  }

  modifier onlyValidTrade(uint _swapIdNftWanted, uint _swapIdNftToTrade) {
    
    require(
      IERC721(
        tradeableNFT[_swapIdNftWanted].nftContract
      ).ownerOf(tradeableNFT[_swapIdNftWanted].nftTokenId) == tradeableNFT[_swapIdNftWanted].ownerAtTrade,
      "NiftySwap: The owner of the NFT wanted has transfered away their NFT."
    );

    require(
      IERC721(
        tradeableNFT[_swapIdNftWanted].nftContract
      ).getApproved(tradeableNFT[_swapIdNftWanted].nftTokenId) == address(this) ||
      
      IERC721(
        tradeableNFT[_swapIdNftWanted].nftContract
      ).isApprovedForAll(tradeableNFT[_swapIdNftWanted].ownerAtTrade, address(this)),
      "NiftySwap: This contract is no longer approved to transfer the NFT wanted."
    );

    require(
      IERC721(
        tradeableNFT[_swapIdNftToTrade].nftContract
      ).ownerOf(tradeableNFT[_swapIdNftToTrade].nftTokenId) == msg.sender,
      "NiftySwap: Cannot trade an NFT you did not own when it was put up for trade."
    );

    require(
      IERC721(
        tradeableNFT[_swapIdNftToTrade].nftContract
      ).getApproved(tradeableNFT[_swapIdNftToTrade].nftTokenId) == address(this) ||
      
      IERC721(
        tradeableNFT[_swapIdNftToTrade].nftContract
      ).isApprovedForAll(tradeableNFT[_swapIdNftToTrade].ownerAtTrade, address(this)),
      "NiftySwap: Must approve this contract to transfer the NFT to trade it."
    );
    
    _;
  }

  constructor() {}

  /**
   **   External functions.
  */

  /// @dev Signal that an NFT is available for trading.
  function putUpForTrade(address _nftContract, uint _tokenId) external onlyTradeable(_nftContract, _tokenId) {

    // Get swap ID
    uint id = _swapId();

    // Signal interest to trade.
    tradeableNFT[id] = TradeableNFT({
      ownerAtTrade: msg.sender,
      nftContract: _nftContract,
      nftTokenId: _tokenId
    });

    swapId[_nftContract][_tokenId] = id;

    emit AvailableForTrade(msg.sender, _nftContract, _tokenId, id);
  }

  /// @dev Signal interest to trade an NFT available for trade. If both parties signal interest, the NFTs are swapped.
  function signalInterest(uint _swapIdNftWanted, uint _swapIdNftToTrade, bool _interest) external {

    require(
      _swapIdNftWanted < nextSwapId && _swapIdNftToTrade < nextSwapId,
      "NiftySwap: Invalid swap ID provided."
    );
    require(
      tradeableNFT[_swapIdNftToTrade].ownerAtTrade == msg.sender, 
      "NiftySwap: Cannot signal interest to trade an NFT you do not own or did not put up for sale."
    );

    // If both parties signal interest, swap the NFTs.
    if(interestInTrade[_swapIdNftWanted][_swapIdNftToTrade] && _interest) {
      interestInTrade[_swapIdNftWanted][_swapIdNftToTrade] = false;
      trade(_swapIdNftWanted, _swapIdNftToTrade);
    } else {
      interestInTrade[_swapIdNftToTrade][_swapIdNftWanted] = true;
      emit InterestInTrade(_swapIdNftWanted, _swapIdNftToTrade);
    }
  }

  /**
   **   Internal functions.
  */

  /// @dev Trades one NFT for another.
  function trade(uint _swapIdNftWanted, uint _swapIdNftToTrade) internal onlyValidTrade(_swapIdNftWanted, _swapIdNftToTrade) {

    // Transfer NFT to trade.
    IERC721(tradeableNFT[_swapIdNftToTrade].nftContract).transferFrom(
      tradeableNFT[_swapIdNftToTrade].ownerAtTrade,
      tradeableNFT[_swapIdNftWanted].ownerAtTrade,
      tradeableNFT[_swapIdNftToTrade].nftTokenId
    );

    // Transfer NFT wanted.
    IERC721(tradeableNFT[_swapIdNftWanted].nftContract).transferFrom(
      tradeableNFT[_swapIdNftWanted].ownerAtTrade,
      tradeableNFT[_swapIdNftToTrade].ownerAtTrade,
      tradeableNFT[_swapIdNftWanted].nftTokenId
    );

    emit Trade(
      tradeableNFT[_swapIdNftWanted].nftContract,
      tradeableNFT[_swapIdNftWanted].nftTokenId, 
      tradeableNFT[_swapIdNftWanted].ownerAtTrade,
      _swapIdNftWanted, 
      
      tradeableNFT[_swapIdNftToTrade].nftContract,
      tradeableNFT[_swapIdNftToTrade].nftTokenId, 
      tradeableNFT[_swapIdNftToTrade].ownerAtTrade,
      _swapIdNftToTrade
    );
  }

  function _swapId() internal returns (uint id) {
    id = nextSwapId;
    nextSwapId++;
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
  "metadata": {
    "bytecodeHash": "none"
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}