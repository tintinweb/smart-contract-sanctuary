/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-24
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/interfaces/ITheProperty.sol


pragma solidity ^0.8.0;



interface ITheProperty is IERC721Enumerable, IERC721Metadata {
    // Struct to store any precesion values along with their previous values.
    struct precesionValues {
        uint256[] values;
        uint256[] timestamps;
    }

    // Struct to store property type.
    struct propertyType {
        string name; // name of property type
        uint256 price; // Price of the proerty in NEIBR
        precesionValues dailyRewards; // Daily rewards updated over time.
        uint256 maxDailyReward; // Max daily reward that an property can reach
        uint256 monthlyRent; // Monthly rent that user have to pay(proerty tax)
        uint256 minSellReward; // minimum daily reward required to sell(transfer) the property
        string propertyURI; // Method to store the URI of this property type
    }

    function propertyTypes(uint256 index)
        external
        view
        returns (propertyType memory);

    function doesPropertyTypeExists(uint256 _propertyTypeIndex)
        external
        view
        returns (bool);

    struct property {
        string name; //Name of property
        uint256 propertyTypeIndex; // Property type index.
        uint256 createdOn; // Timestamp when Propery was created.
        precesionValues furnitureIndices; // Furniture indices and allocation times.
        uint256 lastRentDeposited; // Time then the last rent was deposted.
        uint256 lastRewardCalculated; // Timestamp when the reward was calculated.
        uint256 unclaimedDetachedReward; // Unclaimed reward that have no record in contract.
        bool reachedMinRewardInTime; // Bool to check if minReward was reached in specified time.
    }

    function properties(uint256 index) external view returns (property memory);

    // Method to check if the rent is cleared.
    function isRentCleared(uint256 tokenId) external view returns (bool);

    // Method to check if proerty is locked due to insufficient rent payment.
    function isPropertyLocked(uint256 tokenId) external view returns (bool);

    // Method to be used for presale Minting.
    function presaleMint(uint256 _propertyTypeIndex, string memory _name)
        external;
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/Presale.sol


pragma solidity ^0.8.0;



// TODO: create presale contract to accept the payment.
contract Presale is Ownable {
    // strcture to store presale details:
    struct presaleDetail {
        uint256 price; // Price of presale in AVAX;
        uint256 maxSupply; // Cap for presale;
        uint256 totalSupply; // Current supply for this presale;
    }

    /**Mapping to store all the presale;
     {
        propertyTypeIndex:{
            price: Price for presale;
            maxSupply: Cap for presale for propertyIndex;
            totalSupply: Currnt supply of thid preoprty type by this presale;
        }
     }
     */
    mapping(uint256 => presaleDetail) public presale;

    // array to store presales;
    uint256[] public presales;

    // property contract addresss
    address property;
    uint256 public precisionValue;

    // pool shares
    uint256 treasuryPoolShare;
    uint256 NEIBRPoolShare;

    // Pool addresses
    address payable public treasury;
    address payable public NEIBR;

    /**
     * @dev Method to check if presale exists or not for propertyType.
     * @notice This method returns true if presale exists.
     * @param _propertyTypeIndex Property type index
     * @return Returns true if property presale exists.
     */
    function presaleExists(uint256 _propertyTypeIndex)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < presales.length; i++) {
            if (presales[i] == _propertyTypeIndex) return true;
        }
        return false;
    }

    /**
     * @dev Method will push proprtyTypeIndex in presales if not exists.
     * @param _propertyTypeIndex Property type index
     */
    function _addPresaleList(uint256 _propertyTypeIndex) private {
        if (!presaleExists(_propertyTypeIndex)) {
            presales.push(_propertyTypeIndex);
        }
    }

    // Private method to distribute the fund.
    function _distributeFund() private {
        uint256 treasuryPoolFee = (msg.value * treasuryPoolShare) /
            (100 * precisionValue);
        uint256 NEIBRPoolFee = (msg.value * NEIBRPoolShare) /
            (100 * precisionValue);

        // Transfer shares.
        treasury.transfer(treasuryPoolFee);
        NEIBR.transfer(NEIBRPoolFee);
    }

    /**
     * @dev Private method to create presale
     * @param _propertyTypeIndex Property type index
     * @param _price Presale price for property type.
     * @param _maxSupply Cap for this presale
     */
    function _createPresale(
        uint256 _propertyTypeIndex,
        uint256 _price,
        uint256 _maxSupply
    ) private {
        // Check if property exists.
        ITheProperty _property = ITheProperty(property);
        require(
            _property.doesPropertyTypeExists(_propertyTypeIndex),
            "Presale: The furniture category doesn't exists."
        );

        // Check if presale already exists.
        require(
            !presaleExists(_propertyTypeIndex),
            "Presale: Presale already exists"
        );

        // Create presale for the PropertyType:
        presale[_propertyTypeIndex] = presaleDetail(_price, _maxSupply, 0);
        _addPresaleList(_propertyTypeIndex);
    }

    /**
     * @dev Method to create presale, allowed to onlyOwner.
     * @notice This method allows you to create new presale for the property if you're onwer.
     * @param _propertyTypeIndex Property type index
     * @param _price Presale price for property type.
     * @param _maxSupply Cap for this presale
     */
    function createPresale(
        uint256 _propertyTypeIndex,
        uint256 _price,
        uint256 _maxSupply
    ) public onlyOwner {
        // Create the presale.
        _createPresale(_propertyTypeIndex, _price, _maxSupply);
    }

    /**
     * @dev Method to update presale price, allowed to onlyOwner.
     * @notice This method allows you to update price of presale for the property if you're onwer.
     * @param _propertyTypeIndex Property type index
     * @param _price Presale price for property type.
     */
    function updatePresalePrice(uint256 _propertyTypeIndex, uint256 _price)
        public
        onlyOwner
    {
        // Check if presale already exists.
        require(
            presaleExists(_propertyTypeIndex),
            "Presale: Presale already exists"
        );

        // Update the price for presale.
        presale[_propertyTypeIndex].price = _price;
    }

    /**
     * @dev Public method to mint the property.
     * @notice This method allows you to create new property by paying the presale price
     * @param _propertyTypeIndex Property type index
     * @param _name Name of the property
     */
    function presaleMint(uint256 _propertyTypeIndex, string memory _name)
        public
        payable
    {
        // Check if presale exists.
        require(
            presaleExists(_propertyTypeIndex),
            "Presale: Presale doesn't exists."
        );

        // Get presale detail
        presaleDetail storage _presaleDetail = presale[_propertyTypeIndex];
        require(
            msg.value >= _presaleDetail.price,
            "Presale: Insufficient payment."
        );

        // Check if we have't reached the presale limit.
        require(
            _presaleDetail.totalSupply < _presaleDetail.maxSupply,
            "Presale: Max allowed limit reached for this presale."
        );

        // Mint property.
        ITheProperty _property = ITheProperty(property);
        _property.presaleMint(_propertyTypeIndex, _name);

        // Update presale.
        _presaleDetail.totalSupply++;

        // Distribute the fund.
        _distributeFund();
    }

    /**
     * @dev Method to return length of presales
     * @notice This method will return the number of presales available
     * @return Length of presales
     */
    function getPresalesLength() public view returns (uint256) {
        return presales.length;
    }

    constructor(
        address _property,
        address _treasury,
        address _NEIBR
    ) {
        // Specify the property address.
        property = _property;

        uint256 _oneDollerInAvax = 17350300000000000;

        // Create default presales.
        uint256[3] memory _pricesInDoller = [
            uint256(200), // Price in doller for condo
            350, // Price in doller for House
            500 // Price in doller for Mansion
        ];
        uint256[3] memory _maxSupplies = [
            uint256(10), // maxSupply for Condo
            10, // maxSupply for House
            10 // maxSupply for Mansion
        ];
        for (uint256 i = 0; i < _pricesInDoller.length; i++) {
            _createPresale(
                i,
                _pricesInDoller[i] * _oneDollerInAvax,
                _maxSupplies[i]
            );
        }

        // Set 5 decimal precesion value.
        precisionValue = 10**5;

        // Set distribution params.
        treasury = payable(_treasury);
        NEIBR = payable(_NEIBR);
        treasuryPoolShare = 70 * precisionValue;
        NEIBRPoolShare = 30 * precisionValue;

        // Check for pool share
        require(
            treasuryPoolShare + NEIBRPoolShare == 100 * precisionValue,
            "Presale: Sum of shares must be 100."
        );
    }
}