/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: IRandom

interface IRandom {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function requestChainLinkEntropy() external returns (bytes32 requestId);
}

// Part: IRarity

interface IRarity {
    //enum Rarity {Simple, SimpleUpgraded, Rare, Legendary, F1, F2, F3}
    function getRarity(address _contract, uint256 _tokenId) external view returns(uint8 r);
    function getRarity2(address _contract, uint256 _tokenId) external view returns(uint8 r);
}

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/IERC721

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

// Part: IHero

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IHero is IERC721 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function multiMint() external;
    function setPartner(address _partner, uint256 _limit) external;
    function transferOwnership(address newOwner) external; 
    function partnersLimit(address _partner) external view returns(uint256, uint256);
    function totalSupply() external view returns(uint256);
    function reservedForPartners() external view returns(uint256);
}

// Part: OpenZeppelin/openzeppelin-co[email protected]/ERC165

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// Part: OpenZeppelin/[email protected]/IERC1155

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// Part: OpenZeppelin/[email protected]/IERC1155Receiver

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// Part: OpenZeppelin/[email protected]/Ownable

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

// Part: OpenZeppelin/[email protected]/ERC1155Receiver

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: HeroesUpgraderV2.sol

contract HeroesUpgraderV2  is ERC1155Receiver, Ownable {

    // F1, F2, F3 rarity types reserved for future game play
    enum Rarity {Simple, SimpleUpgraded, Rare, Legendary, F1, F2, F3}
    struct Modification {
        address sourceContract;
        Rarity  sourceRarity;
        address destinitionContract;
        Rarity  destinitionRarity;
        uint256 balanceForUpgrade;
        bool enabled;
    }

    bool internal chainLink;
    address public chainLinkAdapter;
    address internal whiteListBalancer = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public externalStorage;

    // Mapping of enabled modifications
    // From modifier contract address and tokenId to Modification
    mapping(address => mapping(uint256 => Modification)) public enabledModifications;

    // Mapping of enabled source conatracts
    mapping(address => bool) public sourceContracts;
    
    //Mapping from upgradING contract address and tokenId to token 
    //rarity. By default (token was not upgrade) any token has Simple rarity
    mapping(address => mapping(uint256 => Rarity)) public rarity;
    
    event Upgraded(address destinitionContract, uint256 oldHero, uint256 newHero, Rarity newRarity);
    event ModificationChange(address modifierContract, uint256 modifierId);
    

    
    function upgrade(uint256 oldHero, address modifierContract, uint256 modifierId) public {
        //1.0 Check that modification is registered
        require(
            enabledModifications[modifierContract][modifierId].enabled
            , "Unknown modificator"
        );
        // 1.1. Check that this hero is not rare o legendary
        // In more common sence that modification from current oldHero rariry is enabled
        require(
            rarity[
              enabledModifications[modifierContract][modifierId].sourceContract
            ][oldHero] == enabledModifications[modifierContract][modifierId].sourceRarity,
            "Cant modify twice or from your rarity"
        );

        require(
            IHero(
               enabledModifications[modifierContract][modifierId].sourceContract
            ).ownerOf(oldHero) == msg.sender,
            "You need own hero for upgrade"
        );
        //2.Charge modificator from user
        IERC1155(modifierContract).safeTransferFrom(
            msg.sender,
            address(this),
            modifierId,
            enabledModifications[modifierContract][modifierId].balanceForUpgrade,
            '0'
        );

        //3.Mint new hero  and save rarity
        // get existing mint limit for this conatrct
        (uint256 limit, uint256 minted) =
            IHero(
               enabledModifications[modifierContract][modifierId].destinitionContract
            ).partnersLimit(address(this));
        
        // increase and set new free limit mint for this contract
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).setPartner(address(this), limit + 1);
        
        
         
        //get tokenId of token thet will mint
        uint256 newToken = IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).totalSupply();
        
        // mint with white list
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).multiMint();
        
        // transfer new token to sender
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).transferFrom(address(this), msg.sender, newToken);

        
        /////////////////////////////////////////////////////////////////////
        // correct whitelist balance
        // For use  this functionalite Heroes Owner must manualy set limit
        // for whiteListBalancer (two tx with same limit)
        // (uint256 wl_limit, uint256 wl_minted) = IHero(
        //        enabledModifications[modifierContract][modifierId].destinitionContract
        //    ).partnersLimit(whiteListBalancer); 

        //if (limit != 0) {
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).setPartner(whiteListBalancer, limit);
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).setPartner(whiteListBalancer, limit);
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).setPartner(whiteListBalancer, limit);
        IHero(
            enabledModifications[modifierContract][modifierId].destinitionContract
        ).setPartner(whiteListBalancer, 0);
        //}
        /////////////////////////////////////////////////////////////////////

        
        //safe rarity of upgradING token
        rarity[
            enabledModifications[modifierContract][modifierId].sourceContract
        ][oldHero] = Rarity.SimpleUpgraded;

        //safe rarity of new minted token
        rarity[
            enabledModifications[modifierContract][modifierId].sourceContract
        ][newToken] = enabledModifications[modifierContract][modifierId].destinitionRarity;
        //4.transfer new hero to msg.sender
        emit Upgraded(
            enabledModifications[modifierContract][modifierId].destinitionContract, 
            oldHero,
            newToken, 
            enabledModifications[modifierContract][modifierId].destinitionRarity
        );
        
        if (chainLink) {
            IRandom(chainLinkAdapter).requestChainLinkEntropy();    
        }
        

    }

    function upgradeBatch(uint256[] memory oldHeroes, address modifierContract, uint256 modifierId) public {
        require(oldHeroes.length <= 10, "Not more then 10");
        for (uint256 i; i < oldHeroes.length; i ++) {
            upgrade(oldHeroes[i], modifierContract, modifierId);
        }
    }


    /// Return rarity of given  token
    function getRarity(address _contract, uint256 _tokenId) public view returns(Rarity r) {
        r = rarity[_contract][_tokenId];
        if (externalStorage != address(0)) {
            uint8 extRar = IRarity(externalStorage).getRarity(_contract, _tokenId);
            if (Rarity(extRar) > r) {
                r = Rarity(extRar);
            }
        }
        return r;
    }


    /// Return rarity of given  token
    function getRarity2(address _contract, uint256 _tokenId) public view returns(Rarity r) {
        require(sourceContracts[_contract], "Unknown source contract");
        require(
            IHero(_contract).ownerOf(_tokenId) != address(0),
            "Seems like token not exist"
        );
        return getRarity(_contract, _tokenId);
        // r = rarity[_contract][_tokenId];
        //         if (externalStorage != address(0)) {
        //     Rarity extRar = IRarity(externalStorage).getRarity(_contract, _tokenId);
        //     if (extRar > r) {
        //         r = extRar;
        //     }
        // }
        // return r;
    }


    
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        override
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));  
    }    

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        override
        returns(bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256,uint256,bytes)"));  
    }
    
    //////////////////////////////////////////////////////
    ///   Admin Functions                             ////
    //////////////////////////////////////////////////////
    function setModification(
        address _modifierContract,
        uint256 _modifierId,
        address _sourceContract,
        Rarity  _sourceRarity,
        address _destinitionContract,
        Rarity  _destinitionRarity,
        uint256 _balanceForUpgrade,
        bool    _isEnabled
    ) external onlyOwner {
        require(_modifierContract != address(0), "No zero");
        enabledModifications[_modifierContract][_modifierId].sourceContract = _sourceContract;
        enabledModifications[_modifierContract][_modifierId].sourceRarity = _sourceRarity;
        enabledModifications[_modifierContract][_modifierId].destinitionContract = _destinitionContract;
        enabledModifications[_modifierContract][_modifierId].destinitionRarity = _destinitionRarity;
        enabledModifications[_modifierContract][_modifierId].balanceForUpgrade = _balanceForUpgrade;
        enabledModifications[_modifierContract][_modifierId].enabled = _isEnabled;
        sourceContracts[_sourceContract] = _isEnabled;
        emit ModificationChange(_modifierContract, _modifierId);
    }

    function setModificationState(
        address _modifierContract,
        uint256 _modifierId,
        bool    _isEnabled
    ) external onlyOwner {
        require(_modifierContract != address(0), "No zero");
        enabledModifications[_modifierContract][_modifierId].enabled = _isEnabled;
        sourceContracts[
            enabledModifications[_modifierContract][_modifierId].sourceContract
        ] = _isEnabled;
        emit ModificationChange(_modifierContract, _modifierId);
    }

    function revokeOwnership(address _contract) external onlyOwner {
        IHero(_contract).transferOwnership(owner());
    }

    function setChainLink(bool _isOn) external onlyOwner {
        require(chainLinkAdapter != address(0), "Set adapter address first");
        chainLink = _isOn;
    }

    function setChainLinkAdapter(address _adapter) external onlyOwner {
        chainLinkAdapter = _adapter;
    } 

    function setPartnerProxy(
        address _contract, 
        address _partner, 
        uint256 _newLimit
    ) 
        external 
        onlyOwner 
    {
        IHero(_contract).setPartner(_partner, _newLimit);
    } 

    function setWLBalancer(address _balancer) external onlyOwner {
        require(_balancer != address(0));
        whiteListBalancer = _balancer;
    }

    function loadRaritiesBatch(address _contract, uint256[] memory _tokens, Rarity[] memory _rarities) external onlyOwner {
        require(_contract != address(0), "No Zero Address");
        require(_tokens.length == _rarities.length);
         for (uint256 i; i < _tokens.length; i ++) {
            rarity[_contract][_tokens[i]] = _rarities[i];
        }
    }

    function setExternalStorage(address _storage) external onlyOwner {
        externalStorage = _storage;
    }
}