/**
 *Submitted for verification at polygonscan.com on 2021-07-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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

    uint256[49] private __gap;
}

interface IMeebMasterStats {
    struct MeebInfo {
        uint8 id;
        string Name;
        string Attribute;
        uint8 Level;
        string Passive;
    }

    struct MeebPurity {
        uint8 id;
        string Name;
        uint8 Star;
    }

    struct MeebBody {
        uint16 HP;
        uint16 Atk;
        uint16 S_Atk;
        uint16 Energy;
        uint16 Crit;
        uint16 Crit_Dmg;
        uint16 Speed;
        uint16 AFK_Stat;
        uint16 Luck;
        uint16 Productivity;
    }

    /**
     * @dev Returns game info.
     */
    function info()
        external
        view
        returns (
            uint256 totalSupply,
            uint256 totalBurned,
            uint256 totalFusion,
            uint256[] memory otherInfo
        );

    /**
     * @dev Returns MeebMaster stats from the token ID
     */
    function stats(uint256 tokenId)
        external
        view
        returns (
            uint16[] memory pvpStats,
            uint16 luckStat,
            uint16 productivityStat,
            uint256 otherStats
        );

    /**
     * @dev Returns MeebMaster card details from the token ID
     */
    function details(uint256 tokenId)
        external
        view
        returns (
            MeebInfo[] memory info,
            MeebPurity memory purity,
            MeebBody memory body
        );

    /**
     * @dev Returns expected price (in MEEB) from the token ID
     */
    function expectedPrice(uint256 tokenId) external view returns (uint256);

    function setInfo(uint256 tokenId, MeebInfo[] memory newInfo) external;

    function setPurity(uint256 tokenId, MeebPurity memory newPurity) external;

    function setBody(uint256 tokenId, MeebBody memory newBody) external;

    function setDetails(
        uint256 tokenId,
        MeebInfo[] memory newInfo,
        MeebPurity memory newPurity,
        MeebBody memory newBody
    ) external;
}

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

interface IMeebMasterNFT is IERC721 {
    function getStats(uint256 tokenId)
        external
        view
        returns (
            uint16[] memory pvpStats,
            uint16 luckStat,
            uint16 productivityStat,
            uint256 otherStats
        );

    function totalBurned() external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    function lockedBy(uint256 tokenId) external view returns (address);

    function lock(uint256 tokenId, address locker) external;

    function unlock(uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}

interface IMeebMasterFactory {
    function nft() external view returns (address);

    function stats() external view returns (address);

    function totalBurned() external view returns (uint256);

    function totalFusion() external view returns (uint256);

    function mintedTokens() external view returns (uint256);

    function tokenMintedIndex(uint256 tokenId) external view returns (uint256 index);

    function tokenByIndex(uint256 index) external view returns (uint256 tokenId);

    function tokenInfo(uint256 tokenId)
        external
        view
        returns (
            uint256[] memory parents,
            uint256 mintedFee,
            uint256 birthDate,
            uint256 deathDate
        );

    function fusionInfo(uint256[] memory parents) external view returns (uint256 burnedFee, uint256[] memory otherInfo);

    function mintToken(
        address receiver,
        uint256 tokenId,
        IMeebMasterStats.MeebInfo[] memory info,
        IMeebMasterStats.MeebPurity memory purity,
        IMeebMasterStats.MeebBody memory body
    ) external;

    function burnToken(uint256 tokenId) external;

    function fusionToken(uint256[] memory parents) external;
}

contract MeebMasterStats is IMeebMasterStats, OwnableUpgradeable {
    address public nft;
    address public factory;

    mapping(address => bool) private _admin;

    mapping(uint256 => MeebInfo[]) private info_;
    mapping(uint256 => MeebPurity) private purity_;
    mapping(uint256 => MeebBody) private body_;

    /* ========== EVENTS ========== */

    event AdminUpdate(address indexed account, bool isAdmin);

    /* ========== Modifiers =============== */

    modifier onlyAdmin() {
        require(_admin[msg.sender] || owner() == msg.sender, "!admin");
        _;
    }

    /* ========== GOVERNANCE ========== */

    function initialize(address _nft, address _factory) external initializer {
        require(_nft == IMeebMasterFactory(_factory).nft(), "wrong nft & factory");
        __Ownable_init();
        nft = _nft;
        factory = _factory;
    }

    function setAdmin(address _account, bool _isAdmin) external onlyOwner {
        require(_account != address(0), "zero");
        _admin[_account] = _isAdmin;
        emit AdminUpdate(_account, _isAdmin);
    }

    function setFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "zero");
        factory = _factory;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isAdmin(address _account) external view returns (bool) {
        return _admin[_account];
    }

    function info()
        external
        view
        override
        returns (
            uint256 totalSupply,
            uint256 totalBurned,
            uint256 totalFusion,
            uint256[] memory otherInfo
        )
    {
        totalSupply = IERC20(nft).totalSupply();
        totalBurned = IMeebMasterNFT(nft).totalBurned();
        totalFusion = IMeebMasterFactory(factory).totalFusion();
        otherInfo = new uint256[](0);
    }

    function stats(uint256 tokenId)
        external
        view
        override
        returns (
            uint16[] memory pvpStats,
            uint16 luckStat,
            uint16 productivityStat,
            uint256 otherStats
        )
    {
        MeebBody memory _body = body_[tokenId];
        pvpStats = new uint16[](8);
        pvpStats[0] = _body.HP;
        pvpStats[1] = _body.Atk;
        pvpStats[2] = _body.S_Atk;
        pvpStats[3] = _body.Energy;
        pvpStats[4] = _body.Crit;
        pvpStats[5] = _body.Crit_Dmg;
        pvpStats[6] = _body.Speed;
        pvpStats[7] = _body.AFK_Stat;
        luckStat = _body.Luck;
        productivityStat = _body.Productivity;
        otherStats = 0;
    }

    function details(uint256 tokenId)
        external
        view
        override
        returns (
            MeebInfo[] memory tokenInfo,
            MeebPurity memory purity,
            MeebBody memory body
        )
    {
        tokenInfo = info_[tokenId];
        purity = purity_[tokenId];
        body = body_[tokenId];
    }

    function expectedPrice(uint256 tokenId) external view override returns (uint256 _price) {
        _price = 10 ether; // default
        MeebInfo[] memory _info = info_[tokenId];
        if (_info.length > 0) {
            uint256 length = _info.length;
            uint256 _totalLevel = 0;
            for (uint256 i = 0; i < length; i++) {
                uint256 _itemLvl = _info[i].Level;
                _totalLevel += _itemLvl * _itemLvl;
            }
            uint256 _purityStar = purity_[tokenId].Star;
            uint256 _tokenValue = _totalLevel * _purityStar * _purityStar;
            _price = (_price * _tokenValue) / 8;
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setInfo(uint256 tokenId, MeebInfo[] memory newInfo) public override onlyAdmin {
        if (info_[tokenId].length > 0) {
            delete info_[tokenId];
        }
        uint256 length = newInfo.length;
        for (uint256 i = 0; i < length; ++i) {
            info_[tokenId].push(newInfo[i]);
        }
    }

    function setPurity(uint256 tokenId, MeebPurity memory newPurity) public override onlyAdmin {
        delete purity_[tokenId];
        purity_[tokenId] = newPurity;
    }

    function setBody(uint256 tokenId, MeebBody memory newBody) public override onlyAdmin {
        delete body_[tokenId];
        body_[tokenId] = newBody;
    }

    function setDetails(
        uint256 tokenId,
        MeebInfo[] memory newInfo,
        MeebPurity memory newPurity,
        MeebBody memory newBody
    ) external override onlyAdmin {
        setInfo(tokenId, newInfo);
        setPurity(tokenId, newPurity);
        setBody(tokenId, newBody);
    }

    /* ========== EMERGENCY ========== */

    function rescueStuckErc20(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}