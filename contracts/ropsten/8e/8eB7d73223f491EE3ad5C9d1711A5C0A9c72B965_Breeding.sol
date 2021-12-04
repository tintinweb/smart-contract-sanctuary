/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

pragma solidity 0.8.4;
//SPDX-License-Identifier: UNLICENSED

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

interface ICollarQuest is IERC721 {
    function spawnSparce( uint256 _genes, address _owner) external returns (uint256);
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);
 
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  
  function burn(uint256 amount) external;
  
  function burnFrom(address account, uint256 amount) external;

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Validator {
    bytes32 public constant SIGNATURE_PERMIT_TYPEHASH = keccak256("validateSig(address _owner, uint _sireId, uint _matronId, uint _gene, uint _deadline, bytes memory signature)");
    uint public chainId;
    
    using ECDSA for bytes32;
    
    constructor() {
        uint _chainId;
        assembly {
            _chainId := chainid()
        }
        
        chainId = _chainId;
    }
    
    function validateSig(address _owner, uint _sireId, uint _matronId, uint _gene, uint _deadline, bytes memory signature) public view returns (address){
      // This recreates the message hash that was signed on the client.
      bytes32 hash = keccak256(abi.encodePacked(SIGNATURE_PERMIT_TYPEHASH, _owner, _sireId, _matronId, _gene, chainId, _deadline));
      bytes32 messageHash = hash.toSignedMessageHash();
    
      // Verify that the message's signer is the owner of the order
      return messageHash.recover(signature);
    }
}

library ECDSA {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param signature bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (signature.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables with inline assembly.
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
  function toSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
  }
}

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

abstract contract AccessControl is Context, IAccessControl {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
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

contract BreedingCore is AccessControl, Validator {
    ICollarQuest public collarQuest;
    IERC20 public SLP;
    IERC20 public TAG;
    
    event Breed(uint indexed _sireId, uint indexed _matronId, uint indexed _eggID);
    event EggHatch( uint indexed _eggID, uint indexed _sparceId);
    
    struct BreedStruct {
        address receiver;
        uint sireId;
        uint matronId;
        uint eggGene;
        uint layEggOn;
        bool isHatched;
    }
    
    struct BreedInfoStruct {
        uint breedCount;
        uint eggID;
        bool isEggHatched;
    }
    
    address public treasury;
    
    uint hatchTime = 5 days;
    uint totalBreedCount = 7;
    uint TAGFee;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BREED_MANAGER = keccak256("BREED_MANAGER");
    
    BreedStruct[] public breedInfo;
    
    mapping(uint => BreedInfoStruct) public sparceInfo; 
    mapping(uint => uint) public breedSPLFee;
    mapping(address => uint[]) public userEggs;
    
    modifier notBreedWhen() {
       require((address(SLP) != address(0)) && (address(TAG) != address(0)));
       _;
    }
    
    function payBreedFee( address _owner, uint _matronCount, uint _sireCount) internal {
        require(TAG.balanceOf(_owner) >= TAGFee,"BreedingCore : insufficient balance to pay TAG Fee");
        require(TAG.allowance(_owner, address(this)) >= TAGFee,"BreedingCore : insufficient allowance to pay TAG");
        require(TAG.transferFrom(_owner, treasury, TAGFee),"BreedingCore : TAG transfer failed");
        
        uint _slpFee = breedSPLFee[_matronCount] + breedSPLFee[_sireCount];
        
        require(SLP.balanceOf(_owner) >= _slpFee,"BreedingCore : insufficient balance to pay SLP fee");
        require(SLP.allowance(_owner, address(this)) >= _slpFee,"BreedingCore : insufficient allowance to pay SLP fee");
        SLP.burnFrom(_owner, _slpFee);
    }
}

contract Breeding is BreedingCore {
    
    constructor( address _breedManager, ICollarQuest _collarQuest, address _treasury) {
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(BREED_MANAGER, _breedManager);
        
        treasury = _treasury;
        collarQuest = _collarQuest;
    }

    function setCollarQuest( ICollarQuest _collarQuest) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        collarQuest = _collarQuest;
    }
    
    function setTotalBreedCount( uint _totalBreedCount) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        totalBreedCount = _totalBreedCount;
    }
    
    function setHatchTime( uint _hatchTime) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        hatchTime = _hatchTime;
    }
    
    function setTreasury( address _treasury) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        require(_treasury != address(0),"BreedingCore : _treasury should not be a zero address");
        treasury = _treasury;
    }
    
    function setTag( IERC20 _tag) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        require(address(_tag) != address(0), "BreedingCore : _tag should not be zero");
        TAG = _tag;
    }
    
    function setSPL( IERC20 _slp) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        require(address(_slp) != address(0), "BreedingCore : _slp should not be zero");
        SLP = _slp;
    }
    
    function setTagFee( uint _tag) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        require(_tag > 0,"BreedingCore : tag fee should be greater than zero");
        TAGFee = _tag;
    }
    
    function setSLPFee( uint _birthCount, uint _slpFee) external onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        require((_birthCount <= totalBreedCount) && (_birthCount > 0),"BreedingCore : invalid breed count or exceed breed count");
        require(_slpFee > 0,"BreedingCore : slp fee should be greater than zero");
        breedSPLFee[_birthCount] = _slpFee;
    }
    
    function breed( uint _matronId, uint _sireId, uint _gene, uint _deadLine, bytes memory _signature) external notBreedWhen {
       require(_sireId != _matronId,"BreedingCore : sireId should not be equal to matronId"); 
       require(collarQuest.ownerOf(_sireId) != address(0),"BreedingCore : invalid sireId ownership");
       require(collarQuest.ownerOf(_matronId) != address(0),"BreedingCore : invalid matronId ownership");
       require((collarQuest.ownerOf(_matronId) == _msgSender()) || (collarQuest.ownerOf(_sireId) == _msgSender()), "BreedingCore : caller is not a owner");
       require(sparceInfo[_sireId].breedCount < totalBreedCount,"BreedingCore : sireId exceed breed count");
       require(sparceInfo[_matronId].breedCount < totalBreedCount,"BreedingCore : matronId exceed breed count");
       require(!sparceInfo[_matronId].isEggHatched, "BreedingCore : matronId egg not hatched");
       require(!sparceInfo[_sireId].isEggHatched, "BreedingCore : sireId egg not hatched");
       require(_gene > 0,"BreedingCore : gene should be greater than zero");
       require(hasRole(BREED_MANAGER,validateSig(_msgSender(), _sireId, _matronId, _gene, _deadLine, _signature)),"BreedingCore : failed to verify the signature");
       
       uint[2] memory _eggID;
       _eggID[0] = sparceInfo[_sireId].eggID;
       _eggID[1] = sparceInfo[_matronId].eggID;
       
       
       if(breedInfo.length > 0){
            uint[4] memory _parents;
            (_parents[0], _parents[1]) = (breedInfo[_eggID[0]].sireId, breedInfo[_eggID[0]].matronId);
            (_parents[2], _parents[3]) = (breedInfo[_eggID[1]].sireId, breedInfo[_eggID[1]].matronId);
            
            require((_parents[0] != _parents[2]) || ((_parents[0] == _parents[2]) && (_parents[0] == 0)),"BreedingCore : should not be breeded with sibblings or parents");
            require((_parents[1] != _parents[3]) || ((_parents[1] == _parents[3]) && (_parents[1] == 0)),"BreedingCore : should not be breeded with sibblings or parents");
       }
       
       userEggs[_msgSender()].push(breedInfo.length);
       
       sparceInfo[_sireId].isEggHatched = true;
       sparceInfo[_sireId].breedCount++;
       sparceInfo[_matronId].isEggHatched = true;
       sparceInfo[_matronId].breedCount++;
       
       payBreedFee(_msgSender(), sparceInfo[_sireId].breedCount, sparceInfo[_matronId].breedCount);
       
       breedInfo.push(BreedStruct({
           receiver : _msgSender(),
           sireId : _sireId,
           matronId : _matronId,
           eggGene : _gene,
           layEggOn : block.timestamp,
           isHatched : false
       }));
       
       emit Breed( _sireId,  _matronId, userEggs[_msgSender()][userEggs[_msgSender()].length - 1]);
    }
    
    function eggsHatch( uint _eggID) external {
        BreedStruct storage _breed = breedInfo[_eggID];
        
        require(_eggID < breedInfo.length,"BreedingCore : invalid egg id");
        require((_breed.layEggOn+hatchTime) < block.timestamp,"BreedingCore : wait till hatch period");
        require(!_breed.isHatched,"BreedingCore : egg is already hatched");
       
        sparceInfo[_breed.sireId].isEggHatched = false; 
        sparceInfo[_breed.matronId].isEggHatched = false;
        _breed.isHatched = true;
        
        uint _sparceID = collarQuest.spawnSparce(_breed.eggGene, _breed.receiver);
        sparceInfo[_sparceID].eggID = _eggID;
        
        emit EggHatch( _eggID, _sparceID);
    }
    
}