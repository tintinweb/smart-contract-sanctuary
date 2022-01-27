// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IS16NFT {
    function mintEditionsUser(
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _quantity
    ) external returns (bool);

    function claimNfts(
        address _to,
        uint256[] memory tokenIds,
        uint256[] memory quantity) 
        external returns (bool);

    function getCurrentTokenId() external view returns (uint256);
    function updateIdsEdition(uint256[] memory _tokenIds,uint256[] memory _quantity) external;

    function getmintedEditionsToken(uint256 _tokenId)
        external
        view
        returns (uint256);

    function isMinted(uint256 _tokenId) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function cap() external view returns (uint256);

    function getEditionCap() external view returns (uint256);

    function balanceOf(address owner, uint256 id)
        external
        view
        returns (uint256);

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);
}

interface IS16Presale {
    function isRegisterforPresale(address wallet) external view returns (bool);
}

interface IS16Token {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function airdropTokenUser(address account, uint256 amount) external;
}
 
contract S16Distributor is AccessControl {
    
    struct ClaimNFT {
        address claimWallet;
        uint256[] tokenIds;
        uint256[] quantity;
        bool isClaimed;
    }

    struct ClaimToken {
        address claimWallet;
        uint256 claimAmount;
        bool isClaimed;
    }

    uint256 public preSaleMintPrice = 0.16 ether;
    uint256 public publicSaleMintPrice = 0.25 ether;

    uint256 public PRE_SALE_START_TIME;
    uint256 public PUBLIC_SALE_TIME_START;

    uint256 private userPreSaleMaxEditionCap = 10; 
    uint256 private userPublicSaleMaxEditionCap = 10;

    bool public _mintingPaused = false;
    uint256 private _trackerTokenId;

    address public s16AdminWallet;

    // mapping for preSale mint limit for users
    mapping(address => uint256) public preSaleMintLimit;

     //mapping for public sale mint limit for users
    mapping (address => uint256) public publicSaleMintLimit;

    mapping (address => ClaimNFT) public claimS16NFTs;
    mapping(address => ClaimToken) public claimTokens;


    IS16NFT s16NFT;
    IS16Token s16Token;
    IS16Presale s16Presale;

    constructor(address _s16NFT, address _s16Token, address _s16PreSale,address _s16AdminWallet) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        s16NFT = IS16NFT(_s16NFT);
        s16Token = IS16Token(_s16Token);
        s16Presale = IS16Presale(_s16PreSale);

        s16AdminWallet =_s16AdminWallet;
        
        PRE_SALE_START_TIME = 1643266800; //PreSale Time //TODO change time on mainnet is 1643414400 : Presale Time: 28 January 7 pm EST 
        PUBLIC_SALE_TIME_START = 1643270400; //Public Sale Time //TODO change time on mainnet is 1643500800 : PublicSale Time: 29 January 7 pm EST
    }

    function updateUserPreSaleMaxEditionCap(uint256 _newCap) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        require(_newCap > 0, "S16Dist: value error");
        userPreSaleMaxEditionCap = _newCap;
    }

    function updateUserPublicSaleMaxEditionCap(uint256 _newCap) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        require(_newCap > 0, "S16Dist: value error");
        userPublicSaleMaxEditionCap = _newCap;
    }


    function setPreSaleStartTime(uint256 _PRE_SALE_START_TIME) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        PRE_SALE_START_TIME = _PRE_SALE_START_TIME;
    }

    function setPublicSaleStartTime(uint256 _PUBLIC_SALE_TIME_START) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        PUBLIC_SALE_TIME_START = _PUBLIC_SALE_TIME_START;
    }

    function preSaleMint(address wallet, uint256 _editionQty, bool _claimNow) public payable {
        
        require(s16AdminWallet != address(0x0), "S16Dist: eth to null address");
        require(!_mintingPaused, "S16Dist: Minting paused");
        require(s16Presale.isRegisterforPresale(wallet), "S16Dist: you are not registered for presaleMint");
        require(preSaleMintLimit[wallet]+_editionQty <= userPreSaleMaxEditionCap, "S16Dist: minting limit exceed only 10 allowed");
        require(block.timestamp >= PRE_SALE_START_TIME && block.timestamp <= PUBLIC_SALE_TIME_START, "S16Dist: presale time error");
        require(msg.value >= (preSaleMintPrice * _editionQty),"S16Dist: Presale price error");

        payable(s16AdminWallet).transfer(msg.value);
    

       (uint256[] memory tokenIds, uint256[] memory editionQty) = _mintTokensEditions(_editionQty);

        uint256 s16TokenAmount = _editionQty * 16000e18;

        if(_claimNow) {
            s16NFT.mintEditionsUser(wallet, tokenIds, editionQty);
            s16Token.airdropTokenUser(wallet, s16TokenAmount);
            preSaleMintLimit[wallet] += _editionQty;
        } else {
            uint256[] storage newClaimTokenIds = claimS16NFTs[wallet].tokenIds;
            uint256[] storage newClaimTokenQty = claimS16NFTs[wallet].quantity;
            for(uint i =0; i < tokenIds.length; i++) {
                newClaimTokenIds.push(tokenIds[i]);
                newClaimTokenQty.push(editionQty[i]);
            }
            s16NFT.updateIdsEdition(tokenIds,editionQty);
            claimS16NFTs[wallet]  = ClaimNFT(wallet, newClaimTokenIds, newClaimTokenQty, false);
            uint256 prevClaimAmount = claimTokens[wallet].claimAmount;
            claimTokens[wallet] = ClaimToken(wallet, prevClaimAmount+s16TokenAmount, false);
            preSaleMintLimit[wallet] += _editionQty;
        }
    }

    function publicSaleMint(address wallet, uint256 _editionQty) public payable returns (bool) {

        require(!_mintingPaused, "S16Dist: Minting paused");
        require(s16AdminWallet != address(0x0), "S16Dist: eth to null address");
        require(block.timestamp >= PUBLIC_SALE_TIME_START, "S16Dist: Public Sale not yet started");
        require(publicSaleMintLimit[wallet] + _editionQty <= userPublicSaleMaxEditionCap, "S16Dist, Public Sale Mint limit is 10");
        if(s16Presale.isRegisterforPresale(wallet)){
            require(msg.value >= (preSaleMintPrice * _editionQty),"S16Dist: Presale price error");
        }else{
             require(msg.value >= (publicSaleMintPrice * _editionQty), "S16Dist: Insufficient amount provided for minting");
        }
       

        payable(s16AdminWallet).transfer(msg.value);

        (uint256[] memory tokenIds, uint256[] memory editionQty) = _mintTokensEditions(_editionQty);

        uint256 s16TokenAmount = _editionQty * 16000e18;

        s16NFT.mintEditionsUser(wallet, tokenIds, editionQty);
        s16Token.airdropTokenUser(wallet, s16TokenAmount);

        publicSaleMintLimit[wallet] += _editionQty;
        return true;
    }

    function mintbyAdmin(address wallet, uint256 _editionQty) public {
        
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");

        (uint256[] memory tokenIds, uint256[] memory editionQty) = _mintTokensEditions(_editionQty);
        s16NFT.claimNfts(wallet, tokenIds, editionQty);

    }

    function _mintTokensEditions(uint256 _editionQty) internal returns (uint256[] memory, uint256[] memory) {

        uint256 currentTokenID = s16NFT.getCurrentTokenId();
        uint256 totalNFTs = s16NFT.cap();
        uint256 editionCap = s16NFT.getEditionCap();
        uint256[] memory newTokenIds = new uint256[](_editionQty);
        uint256[] memory newEditionQty = new uint256[](_editionQty);

        for(uint i = 0; i < _editionQty; i++) {
            newTokenIds[i] = _trackerTokenId + 1;
            uint256 currentTokenEdition = s16NFT.getmintedEditionsToken(currentTokenID);
            newEditionQty[i] = 1;
            _trackerTokenId++;
            if(_trackerTokenId >= totalNFTs)
                _trackerTokenId = 0;
            if(currentTokenEdition == editionCap)
                _trackerTokenId++;
        }

        return (newTokenIds, newEditionQty);
    }

     function claim() public {

        require(block.timestamp > PRE_SALE_START_TIME, "S16DIST: claim allowed after presale start"); 
        address _wallet = msg.sender;
        require(_wallet == claimTokens[_wallet].claimWallet, "S16DIST: you cannot claim");
        require(_wallet == claimS16NFTs[_wallet].claimWallet,"S16DIST: you cannot claim");
        require(!claimTokens[_wallet].isClaimed, "S16DIST: already claimed S16 tokens");
        require(!claimS16NFTs[_wallet].isClaimed,"S16DIST: already claimed nft editions");
        s16Token.airdropTokenUser(_wallet, claimTokens[_wallet].claimAmount);
        claimTokens[_wallet].isClaimed = true;
         s16NFT.claimNfts( _wallet,claimS16NFTs[_wallet].tokenIds,claimS16NFTs[_wallet].quantity);
        claimS16NFTs[_wallet].isClaimed = true;
    }

    function togglePause(bool _pause) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "S16DIST: Caller is not a admin");
        require(_mintingPaused != _pause, "S16DIST: Already in desired pause state");
        _mintingPaused = _pause;
    }

    function updatePreSalePrice(uint256 _newPrice) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "S16DIST: Caller is not admin");
        preSaleMintPrice = _newPrice;
    }

    function updatePublicSalePrice(uint256 _newPrice) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "S16DIST: Caller is not admin");
        publicSaleMintPrice = _newPrice;
    }

    function getUserClaimNFTs(address _address) public view returns(ClaimNFT memory) {
       return claimS16NFTs[_address];
    }

     function getUserClaimTokens(address _address) public view returns(ClaimToken memory) {
       return claimTokens[_address];
    }

    function updateAdminWallet(address _adminWallet) public {
        require(_adminWallet != address(0x0), "S16Dist: null address error");
        s16AdminWallet = _adminWallet;
    }

   
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
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev SupdatePreSalePriceee {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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