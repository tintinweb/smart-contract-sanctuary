/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @dev Interface of the BEP20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {BEP20Detailed}.
 */
interface IBEP20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface IBEP165 {
    //Query whether the interface ‘interfaceID’  is supported
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract BEP165 is IBEP165 {
    bytes4 private constant _INTERFACE_ID_BEP165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        _registerInterface(_INTERFACE_ID_BEP165);
    }

    function supportsInterface(bytes4 interfaceId) external override view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

interface IBEP721 {
  // Returns the number of NFTs owned by the given account
  function balanceOf(address _owner) external view returns (uint256);

  //Returns the owner of the given NFT
  function ownerOf(uint256 _tokenId) external view returns (address);

  //Transfer ownership of NFT
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

  //Transfer ownership of NFT
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

  //Transfer ownership of NFT
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

  //Grants address ‘_approved’ the authorization of the NFT ‘_tokenId’
  function approve(address _approved, uint256 _tokenId) external payable;

  //Grant/recover all NFTs’ authorization of the ‘_operator’
  function setApprovalForAll(address _operator, bool _approved) external;

  //Query the authorized address of NFT
  function getApproved(uint256 _tokenId) external view returns (address);

  //Query whether the ‘_operator’ is the authorized address of the ‘_owner’
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);

  //The successful ‘transferFrom’ and ‘safeTransferFrom’ will trigger the ‘Transfer’ Event
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

  //The successful ‘Approval’ will trigger the ‘Approval’ event
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  //The successful ‘setApprovalForAll’ will trigger the ‘ApprovalForAll’ event
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

}

interface IBEP721Metadata {
    //Return the token name
    function name() external view returns (string memory _name);

    //Return the token symbol
    function symbol() external view returns (string memory _symbol);

    //Returns the URI of the external file corresponding to ‘_tokenId’. External resource files need to include names, descriptions and pictures. 
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IBEP721Receiver {
    function onBEP721Received(address operator, address from, uint256 tokenId, bytes memory data) external returns (bytes4);
}

contract EggsbookHero is BEP165, IBEP721, IBEP721Metadata {
    using SafeMath for uint256;

    bytes4 private constant _BEP721_RECEIVED = 0x150b7a02;

    address private _creator;

    string private _name;

    string private _symbol;

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _token_id)
        public
        override
        view
        checkToken(_token_id)
        returns (string memory)
    {
        return _asset_data[_asset_indexes[_token_id]].url;
    }

    // Mapping owner address to user data (changeable in each transaction)
    mapping(address => User) _users;

    // Data of User
    struct User {
        // Inventory for this address
        uint256[] inventory;
    }

    // Change tree
    function getInventory(address _address)
        external
        view
        returns (uint256[] memory inventory)
    {
        return _users[_address].inventory;
    }

    /*** Asset Data ***/
    // Auto Increasement ID.
    // Default is 1
    uint256 public current_id = 1;

    // Data of Token
    struct Asset {
        // ID number of this Land (unique, stable).
        // Note: Provide when create the Land.
        uint256 id;
        // Owner address of this Land (unique, changeable by owner of Land).
        // Note: Provide when create the Land.
        address owner;
        // Array of coordinates for building the continious paths
        // Combining these paths will display the Land Boundary
        // Storage as string (unique, changeable by creator of Contract)
        // Example: [[1:1],[2:2],[3:3]]
        // Note: Provide when create the Land.
        string boundary;
        // Ynformation of this Land
        // Storage as string (changeable by creator of Contract)
        // Note: Empty info when create this Land. Can update any time.
        // A Land must have code and contry in order to initiate a transaction.
        // Unique Legal Code of the Land in this Country
        string code;
        // [0]: Country code of this Land
        // [1]: Administrative divisions first level's code of this Land
        // [2]: Administrative divisions second level's code of this Land
        // [3]: Administrative divisions third level's code of this Land
        // [4]: Administrative divisions fourth level's code of this Land
        uint256[] administrative;
        // Address of this Land
        string ad_address;
        // URL present more info of this Land. (changeable by creator of Contract)
        // Example: www.pisolution.co
        string url;
    }

    // Mapping id asset to hash asset (changeable in each transaction)
    mapping(uint256 => string) public _asset_indexes;

    // Mapping hash to token data (changeable in each transaction)
    mapping(string => Asset) public _asset_data;

    // Mapping from token ID to approved address (changeable in each transaction)
    mapping(uint256 => address) public _token_approvals;

    // Mapping from owner to operator approvals (changeable in each transaction)
    mapping(address => mapping(address => bool)) public _operator_approvals;

    // Address in Blacklist cannot do any thing (changeable in each transaction)
    mapping(address => bool) public _blacklist;

    /*** Token Payment Data ***/
    // Token Hash currently use in this contract
    address public token_hash;
    // Token BEP20
    IBEP20 Token;

    // Contructor of Contract
    constructor(
        string memory __name,
        string memory __symbol
    ) {
        // Save the creator address
        _creator = tx.origin;
        // Save the name of Token
        _name = __name;
        // Save the name of Symbol
        _symbol = __symbol;
    }

    // Validator for functions that only Creator is allowed to change internal data
    modifier onlyCreator() {
        require(_creator == msg.sender, "Permision: caller is not the creator");
        _;
    }

    // Validator for functions that address in blacklist is allowed to do anything
    modifier checkBlacklist() {
        require(
            _blacklist[msg.sender] == false,
            "Permision: caller is blocked"
        );
        _;
    }

    // Total Supply Auto Increasement
    function totalSupply() public view returns (uint256) {
        return current_id.sub(1);
    }

    /*** Land Functions ***/
    // Create new Token for new Land
    // Must provide unique hash string and boundary
    // Only creator is allowed to create new Land
    function createNewToken(
        string memory _hash,
        string memory _boundary,
        string memory _code,
        uint256[] memory _administrative,
        string memory _ad_address,
        string memory _url
    ) public onlyCreator {
        // Validate length of hash
        require(bytes(_hash).length == 58, "Invalid hash");
        // Validate duplicate Land hash
        require(_asset_data[_hash].id == 0, "Token already exists");
        // Validate boundary data of this Land
        require(bytes(_boundary).length > 0, "Invalid boundary");
        // Validate code data of this Land
        require(bytes(_code).length > 0, "Invalid code");
        // Validate country data of this Land
        require(_administrative[0] != 0, "Invalid Country");
        // Validate address data of this Land
        require(bytes(_ad_address).length > 0, "Invalid address");

        // Create Land with default Data
        _asset_data[_hash] = Asset(
            current_id,
            _creator,
            _boundary,
            _code,
            _administrative,
            _ad_address,
            _url
        );
        // Save hash string for this Land with lastest ID number
        _asset_indexes[current_id] = _hash;
        // Add new Land to Inventory of Creator with lastest ID number
        addAssetIdToOwner(_creator, current_id);

        // Emit Event
        emit CreateNewToken(current_id, _hash, _ad_address);

        // Auto increasement ID
        current_id++;
    }

    // Validator for functions need to access Land Data
    modifier checkToken(uint256 _index) {
        // ID must smaller than current auto increasement ID
        require(_index < current_id, "Token not found");
        // Check Token have ID ready in list of assets id
        require(bytes(_asset_indexes[_index]).length > 0, "Token not found");
        _;
    }
    modifier checkTokenByHash(string memory _hash) {
        // ID must smaller than current auto increasement ID
        require(_asset_data[_hash].id != 0, "Token not found");
        _;
    }

    // Validator for functions need to guaranteed Owner of Token is Sender by ID number
    modifier checkOwner(uint256 _token_id) {
        require(
            _asset_data[_asset_indexes[_token_id]].owner == msg.sender,
            "Permision denied"
        );
        _;
    }
    modifier checkOwnerByHash(string memory _hash) {
        require(_asset_data[_hash].owner == msg.sender, "Permision denied");
        _;
    }

    // Validator for functions need to guaranteed Owner of Token is Sender by ID number
    modifier checkPermission(uint256 _token_id) {
        // If approve Address create this transaction
        if (_asset_data[_asset_indexes[_token_id]].owner != msg.sender) {
            // Make sure Sender Address is Approved !
            if (
                _token_approvals[_token_id] != msg.sender &&
                _operator_approvals[
                    _asset_data[_asset_indexes[_token_id]].owner
                ][msg.sender] ==
                false
            ) {
                revert("Permision denied !");
            }
        }
        _;
    }
    modifier checkPermissionByHash(string memory _hash) {
        // If approve Address create this transaction
        if (_asset_data[_hash].owner != msg.sender) {
            // Make sure Sender Address is Approved !
            if (
                _token_approvals[_asset_data[_hash].id] != msg.sender &&
                _operator_approvals[_asset_data[_hash].owner][msg.sender] ==
                false
            ) {
                revert("Permision denied !");
            }
        }
        _;
    }

    // Validator for functions need to guaranteed Token's info is ready
    modifier checkTokenReady(uint256 _token_id) {
        require(
            bytes(_asset_data[_asset_indexes[_token_id]].code).length > 0,
            "Token is not ready"
        );
        require(
            _asset_data[_asset_indexes[_token_id]].administrative.length > 0,
            "Token is not ready"
        );
        require(
            bytes(_asset_data[_asset_indexes[_token_id]].ad_address).length > 0,
            "Token is not ready"
        );
        _;
    }
    modifier checkTokenReadyByHash(string memory _hash) {
        require(
            bytes(_asset_data[_hash].code).length > 0,
            "Token is not ready"
        );
        require(
            _asset_data[_hash].administrative.length > 0,
            "Token is not ready"
        );
        require(
            bytes(_asset_data[_hash].ad_address).length > 0,
            "Token is not ready"
        );
        _;
    }

    // Update Token info
    // Only Creator can update Info
    function updateTokenInfo(
        uint256 _token_id,
        string memory _code,
        uint256[] memory _administrative,
        string memory _ad_address
    ) public {
        updateTokenInfoByHash(
            _asset_indexes[_token_id],
            _code,
            _administrative,
            _ad_address
        );
    }

    function updateTokenInfoByHash(
        string memory _hash,
        string memory _code,
        uint256[] memory _administrative,
        string memory _ad_address
    ) public onlyCreator checkTokenByHash(_hash) {
        // Make sure info string is not empty
        require(bytes(_code).length > 0, "Invalid Code");
        require(_administrative[0] > 0, "Invalid Country");
        require(bytes(_ad_address).length > 0, "Invalid Address");

        // Save info for that token
        _asset_data[_hash].code = _code;
        _asset_data[_hash].administrative = _administrative;
        _asset_data[_hash].ad_address = _ad_address;
    }

    

    // Returns the amount of Land owned by the given account
    function balanceOf(address _owner) external override view returns (uint256) {
        return _users[_owner].inventory.length;
    }

    // Returns the owner of the given Token by ID
    function ownerOf(uint256 _token_id)
        external
        override 
        view
        checkToken(_token_id)
        returns (address)
    {
        return _asset_data[_asset_indexes[_token_id]].owner;
    }

    // Grants address ‘_approved’ the authorization of the NFT ‘_token_id’
    function approve(address _approved, uint256 _token_id)
        external
        override 
        payable
        checkBlacklist
        checkToken(_token_id)
        checkOwner(_token_id)
    {
        _token_approvals[_token_id] = _approved;
        emit Approval(msg.sender, _approved, _token_id);
    }

    function approveByHash(address _approved, string calldata _hash)
        external
        payable
        checkBlacklist
        checkToken(_asset_data[_hash].id)
        checkOwner(_asset_data[_hash].id)
    {
        _token_approvals[_asset_data[_hash].id] = _approved;
        emit Approval(msg.sender, _approved, _asset_data[_hash].id);
    }

    // Grant/recover all NFTs’ authorization of the ‘_operator’
    function setApprovalForAll(address _operator, bool _approved)
        external
        override 
        
        checkBlacklist
    {
        if (_approved == true) {
            _operator_approvals[msg.sender][_operator] = _approved;
        } else {
            delete _operator_approvals[msg.sender][_operator];
        }
        // Emit Event
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // Query the authorized address of NFT
    function getApproved(uint256 _token_id) external override  view returns (address) {
        return _token_approvals[_token_id];
    }

    // Query whether the ‘_operator’ is the authorized address of the ‘_owner’
    function isApprovedForAll(address _owner, address _operator)
        external
        override 
        view
        returns (bool)
    {
        return _operator_approvals[_owner][_operator];
    }

    // Query whether the ‘_operator’ is the authorized address of the ‘_owner’
    function setBlacklist(address _address, bool _status) external onlyCreator {
        require(_address != _creator, "Cant not block Creator");
        if (_status == true) {
            _blacklist[_address] = _status;
        } else {
            delete _blacklist[_address];
        }
    }

    // Transfer ownership of Token by ID from address to address
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _token_id,
        bytes calldata _data
    ) external override  payable  checkBlacklist checkToken(_token_id) {
        _transfer(_from, _to, _asset_indexes[_token_id]);
        require(_checkOnBEP721Received(_from, _to, _token_id, _data));
    }

    function safeTransferFromByHash(
        address _from,
        address _to,
        string calldata _hash,
        bytes calldata _data
    ) external  checkBlacklist checkToken(_asset_data[_hash].id) {
        _transfer(_from, _to, _hash);
        require(
            _checkOnBEP721Received(_from, _to, _asset_data[_hash].id, _data)
        );
    }

    // Transfer ownership of Token by ID from address to address
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _token_id
    ) external override payable  checkBlacklist checkToken(_token_id) {
        _transfer(_from, _to, _asset_indexes[_token_id]);
    }

    function safeTransferFromByHash(
        address _from,
        address _to,
        string calldata _hash
    ) external  checkBlacklist checkToken(_asset_data[_hash].id) {
        _transfer(_from, _to, _hash);
    }

    // Transfer ownership of Token by ID from address to address
    function transferFrom(
        address _from,
        address _to,
        uint256 _token_id
    ) external override  payable  checkBlacklist checkToken(_token_id) {
        _transfer(_from, _to, _asset_indexes[_token_id]);
    }

    function transferFromByHash(
        address _from,
        address _to,
        string calldata _hash
    ) external  checkBlacklist checkToken(_asset_data[_hash].id) {
        _transfer(_from, _to, _hash);
    }

    // Transfer function
    function _transfer(
        address _from,
        address _to,
        string memory _hash
    )
        internal
        checkPermissionByHash(_hash)
        checkTokenReadyByHash(_hash)
    {
        // Update new Owner and Data of this Token
        _changePermission(_to, _hash);

        // Emit Event
        emit Transfer(_from, _to, _asset_data[_hash].id);
    }

    // Update Token Owner and Data function
    function _changePermission(address _to, string memory _hash) internal {
        // Remove current Token id from owner inventory
        removeAssetIdFromOwner(_asset_data[_hash].owner, _asset_data[_hash].id);
        // Change owner of the Token
        _asset_data[_hash].owner = _to;
        // Remove Approvals of the Token
        _token_approvals[_asset_data[_hash].id] = _to;
        // Add Token ID to new Inventory
        addAssetIdToOwner(_asset_data[_hash].owner, _asset_data[_hash].id);
    }

    // Add Id of asset to asset list by address
    function addAssetIdToOwner(address _owner, uint256 _token_id) internal {
        _users[_owner].inventory.push(_token_id);
    }

    // Remove Id of asset from asset list by address
    function removeAssetIdFromOwner(address _owner, uint256 _token_id)
        internal
    {
        for (
            uint256 asset = 0;
            asset < _users[_owner].inventory.length;
            asset++
        ) {
            if (_users[_owner].inventory[asset] == _token_id) {
                // Move the last element into the place to delete
                _users[_owner].inventory[asset] = _users[_owner].inventory[
                    _users[_owner].inventory.length - 1
                ];
                // Remove the last element
                _users[_owner].inventory.pop();
                break;
            }
        }
    }

    // Burn an Token in case this Land is not available / valid any more.
    // Or someone want to split big land into many small Land
    // Make sure the old Land not mess up with new Land
    // Only Owner can burn their Land
    function burnToken(uint256 _token_id) public {
        burnTokenByHash(_asset_indexes[_token_id]);
    }

    function burnTokenByHash(string memory _hash)
        public
        
        checkBlacklist
        checkTokenByHash(_hash)
        checkOwnerByHash(_hash)
    {
        // Remove the burned token id from Owner Inventory
        removeAssetIdFromOwner(_asset_data[_hash].owner, _asset_data[_hash].id);
        // Delete Approval of this Token
        delete _token_approvals[_asset_data[_hash].id];
        // Delete Token ID from list
        delete _asset_indexes[_asset_data[_hash].id];
        // Delete data of this Token
        delete _asset_data[_hash];
        emit BurnToken(_hash);
    }

    // Check Receiver is Contract or normal Address
    function _checkOnBEP721Received(
        address _from,
        address _to,
        uint256 _token_id,
        bytes memory _data
    ) internal returns (bool) {
        if (!isContract(_to)) {
            return true;
        }

        bytes4 retval =
            IBEP721Receiver(_to).onBEP721Received(
                msg.sender,
                _from,
                _token_id,
                _data
            );
        return (retval == _BEP721_RECEIVED);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    //The successful ‘createNewToken’ will trigger the ‘CreateNewToken’ Event
    event CreateNewToken(
        uint256 indexed _token_id,
        string indexed _hash,
        string indexed _address
    );

    //The successful ‘setApprovalForAll’ will trigger the ‘ApprovalForAll’ event
    event BurnToken(string indexed _hash);
}