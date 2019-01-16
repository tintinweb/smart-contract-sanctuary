pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

// ----------------------------------------------------------------------------
// Devery Contracts - The Monolithic Registry
//
// Deployed to Ropsten Testnet at 0x654f4a3e3B7573D6b4bB7201AB70d718961765CD
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd for Devery 2017. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function Owned() public {
        owner = msg.sender;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}


// ----------------------------------------------------------------------------
// Administrators
// ----------------------------------------------------------------------------
contract Admined is Owned {

    mapping (address => bool) public admins;

    event AdminAdded(address addr);
    event AdminRemoved(address addr);

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    function isAdmin(address addr) public constant returns (bool) {
        return (admins[addr] || owner == addr);
    }
    function addAdmin(address addr) public onlyOwner {
        require(!admins[addr] && addr != owner);
        admins[addr] = true;
        AdminAdded(addr);
    }
    function removeAdmin(address addr) public onlyOwner {
        require(admins[addr]);
        delete admins[addr];
        AdminRemoved(addr);
    }
}


// ----------------------------------------------------------------------------
// Devery Registry
// ----------------------------------------------------------------------------
contract DeveryRegistry is Admined {

    struct App {
        address appAccount;
        string appName;
        address feeAccount;
        uint fee;
        bool active;
    }
    struct Brand {
        address brandAccount;
        address appAccount;
        string brandName;
        bool active;
    }
    struct Product {
        address productAccount;
        address brandAccount;
        string description;
        string details;
        uint year;
        string origin;
        bool active;
    }

    ERC20Interface public token;
    address public feeAccount;
    uint public fee;
    mapping(address => App) public apps;
    mapping(address => Brand) public brands;
    mapping(address => Product) public products;
    mapping(address => mapping(address => bool)) permissions;
    mapping(bytes32 => address) markings;
    address[] public appAccounts;
    address[] public brandAccounts;
    address[] public productAccounts;

    event TokenUpdated(address indexed oldToken, address indexed newToken);
    event FeeUpdated(address indexed oldFeeAccount, address indexed newFeeAccount, uint oldFee, uint newFee);
    event AppAdded(address indexed appAccount, string appName, address feeAccount, uint fee, bool active);
    event AppUpdated(address indexed appAccount, string appName, address feeAccount, uint fee, bool active);
    event BrandAdded(address indexed brandAccount, address indexed appAccount, string brandName, bool active);
    event BrandUpdated(address indexed brandAccount, address indexed appAccount, string brandName, bool active);
    event ProductAdded(address indexed productAccount, address indexed brandAccount, address indexed appAccount, string description, bool active);
    event ProductUpdated(address indexed productAccount, address indexed brandAccount, address indexed appAccount, string description, bool active);
    event Permissioned(address indexed marker, address indexed brandAccount, bool permission);
    event Marked(address indexed marker, address indexed productAccount, address appFeeAccount, address feeAccount, uint appFee, uint fee, bytes32 itemHash);


    // ------------------------------------------------------------------------
    // Token, fee account and fee
    // ------------------------------------------------------------------------
    function setToken(address _token) public onlyAdmin {
        TokenUpdated(address(token), _token);
        token = ERC20Interface(_token);
    }
    function setFee(address _feeAccount, uint _fee) public onlyAdmin {
        FeeUpdated(feeAccount, _feeAccount, fee, _fee);
        feeAccount = _feeAccount;
        fee = _fee;
    }

    // ------------------------------------------------------------------------
    // Account can add itself as an App account
    // ------------------------------------------------------------------------
    function addApp(string appName, address _feeAccount, uint _fee) public {
        App storage e = apps[msg.sender];
        require(e.appAccount == address(0));
        apps[msg.sender] = App({
            appAccount: msg.sender,
            appName: appName,
            feeAccount: _feeAccount,
            fee: _fee,
            active: true
        });
        appAccounts.push(msg.sender);
        AppAdded(msg.sender, appName, _feeAccount, _fee, true);
    }
    function updateApp(string appName, address _feeAccount, uint _fee, bool active) public {
        App storage e = apps[msg.sender];
        require(msg.sender == e.appAccount);
        e.appName = appName;
        e.feeAccount = _feeAccount;
        e.fee = _fee;
        e.active = active;
        AppUpdated(msg.sender, appName, _feeAccount, _fee, active);
    }
    function getApp(address appAccount) public constant returns (App app) {
        app = apps[appAccount];
    }
    function getAppData(address appAccount) public constant returns (address _feeAccount, uint _fee, bool active) {
        App storage e = apps[appAccount];
        _feeAccount = e.feeAccount;
        _fee = e.fee;
        active = e.active;
    }
    function appAccountsLength() public constant returns (uint) {
        return appAccounts.length;
    }

    // ------------------------------------------------------------------------
    // App account can add Brand account
    // ------------------------------------------------------------------------
    function addBrand(address brandAccount, string brandName) public {
        App storage app = apps[msg.sender];
        require(app.appAccount != address(0));
        Brand storage brand = brands[brandAccount];
        require(brand.brandAccount == address(0));
        brands[brandAccount] = Brand({
            brandAccount: brandAccount,
            appAccount: msg.sender,
            brandName: brandName,
            active: true
        });
        brandAccounts.push(brandAccount);
        BrandAdded(brandAccount, msg.sender, brandName, true);
    }
    function updateBrand(address brandAccount, string brandName, bool active) public {
        Brand storage brand = brands[brandAccount];
        require(brand.appAccount == msg.sender);
        brand.brandName = brandName;
        brand.active = active;

        BrandUpdated(brandAccount, msg.sender, brandName, active);
    }
    function getBrand(address brandAccount) public constant returns (Brand brand) {
        brand = brands[brandAccount];
    }
    function getBrandData(address brandAccount) public constant returns (address appAccount, address appFeeAccount, bool active) {
        Brand storage brand = brands[brandAccount];
        require(brand.appAccount != address(0));
        App storage app = apps[brand.appAccount];
        require(app.appAccount != address(0));
        appAccount = app.appAccount;
        appFeeAccount = app.feeAccount;
        active = app.active && brand.active;
    }
    function brandAccountsLength() public constant returns (uint) {
        return brandAccounts.length;
    }

    // ------------------------------------------------------------------------
    // Brand account can add Product account
    // ------------------------------------------------------------------------
    function addProduct(address productAccount, string description, string details, uint year, string origin) public {
        Brand storage brand = brands[msg.sender];
        require(brand.brandAccount != address(0));
        App storage app = apps[brand.appAccount];
        require(app.appAccount != address(0));
        Product storage product = products[productAccount];
        require(product.productAccount == address(0));
        products[productAccount] = Product({
            productAccount: productAccount,
            brandAccount: msg.sender,
            description: description,
            details: details,
            year: year,
            origin: origin,
            active: true
        });
        productAccounts.push(productAccount);
        ProductAdded(productAccount, msg.sender, app.appAccount, description, true);
    }
    function updateProduct(address productAccount, string description, string details, uint year, string origin, bool active) public {
        Product storage product = products[productAccount];
        require(product.brandAccount == msg.sender);
        Brand storage brand = brands[msg.sender];
        require(brand.brandAccount == msg.sender);
        App storage app = apps[brand.appAccount];
        product.description = description;
        product.details = details;
        product.year = year;
        product.origin = origin;
        product.active = active;
        ProductUpdated(productAccount, product.brandAccount, app.appAccount, description, active);
    }
    function getProduct(address productAccount) public constant returns (Product product) {
        product = products[productAccount];
    }
    function getProductData(address productAccount) public constant returns (address brandAccount, address appAccount, address appFeeAccount, bool active) {
        Product storage product = products[productAccount];
        require(product.brandAccount != address(0));
        Brand storage brand = brands[brandAccount];
        require(brand.appAccount != address(0));
        App storage app = apps[brand.appAccount];
        require(app.appAccount != address(0));
        brandAccount = product.brandAccount;
        appAccount = app.appAccount;
        appFeeAccount = app.feeAccount;
        active = app.active && brand.active && brand.active;
    }
    function productAccountsLength() public constant returns (uint) {
        return productAccounts.length;
    }

    // ------------------------------------------------------------------------
    // Brand account can permission accounts as markers
    // ------------------------------------------------------------------------
    function permissionMarker(address marker, bool permission) public {
        Brand storage brand = brands[msg.sender];
        require(brand.brandAccount != address(0));
        permissions[marker][msg.sender] = permission;
        Permissioned(marker, msg.sender, permission);
    }

    // ------------------------------------------------------------------------
    // Compute item hash from the public key
    // ------------------------------------------------------------------------
    function addressHash(address item) public pure returns (bytes32 hash) {
        hash = keccak256(item);
    }

    // ------------------------------------------------------------------------
    // Markers can add [productAccount, sha3(itemPublicKey)]
    // ------------------------------------------------------------------------
    function mark(address productAccount, bytes32 itemHash) public {
        Product storage product = products[productAccount];
        require(product.brandAccount != address(0) && product.active);
        Brand storage brand = brands[product.brandAccount];
        require(brand.brandAccount != address(0) && brand.active);
        App storage app = apps[brand.appAccount];
        require(app.appAccount != address(0) && app.active);
        bool permissioned = permissions[msg.sender][brand.brandAccount];
        require(permissioned);
        markings[itemHash] = productAccount;
        Marked(msg.sender, productAccount, app.feeAccount, feeAccount, app.fee, fee, itemHash);
        if (app.fee > 0) {
            token.transferFrom(brand.brandAccount, app.feeAccount, app.fee);
        }
        if (fee > 0) {
            token.transferFrom(brand.brandAccount, feeAccount, fee);
        }
    }

    // ------------------------------------------------------------------------
    // Check itemPublicKey has been registered
    // ------------------------------------------------------------------------
    function check(address item) public constant returns (address productAccount, address brandAccount, address appAccount) {
        bytes32 hash = keccak256(item);
        productAccount = markings[hash];
        // require(productAccount != address(0));
        Product storage product = products[productAccount];
        // require(product.brandAccount != address(0));
        Brand storage brand = brands[product.brandAccount];
        // require(brand.brandAccount != address(0));
        brandAccount = product.brandAccount;
        appAccount = brand.appAccount;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}






/**
 * @title ERC165
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract ERC165 {
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
    /**
     * 0x01ffc9a7 ===
     *     bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
     */

    /**
     * @dev a mapping of interface id to whether or not it&#39;s supported
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev A contract implementing SupportsInterfaceWithLookup
     * implement ERC165 itself
     */
    constructor () internal {
        _registerInterface(_InterfaceId_ERC165);
    }

    /**
     * @dev implement supportsInterface(bytes4) using a lookup table
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev internal method for registering an interface
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes data) public returns (bytes4);
}


/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    using SafeMath for uint256;
    using Address for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => uint256) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
    /*
     * 0x80ac58cd ===
     *     bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
     *     bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
     *     bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
     *     bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
     */

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_InterfaceId_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }

    /**
     * @dev Gets the owner of the specified token ID
     * @param tokenId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
    */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        require(to != address(0));

        _clearApproval(from, tokenId);
        _removeTokenFrom(from, tokenId);
        _addTokenTo(to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
    */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes _data) public {
        transferFrom(from, to, tokenId);
        // solium-disable-next-line arg-overflow
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    /**
     * @dev Returns whether the specified token exists
     * @param tokenId uint256 ID of the token to query the existence of
     * @return whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to mint a new token
     * Reverts if the given token ID already exists
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted by the msg.sender
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        _addTokenTo(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token
     * Reverts if the token does not exist
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        _clearApproval(owner, tokenId);
        _removeTokenFrom(owner, tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to add a token ID to the list of a given address
     * Note that this function is left internal to make ERC721Enumerable possible, but is not
     * intended to be called by custom derived contracts: in particular, it emits no Transfer event.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenTo(address to, uint256 tokenId) internal {
        require(_tokenOwner[tokenId] == address(0));
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
    }

    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * Note that this function is left internal to make ERC721Enumerable possible, but is not
     * intended to be called by custom derived contracts: in particular, it emits no Transfer event,
     * and doesn&#39;t clear approvals.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _tokenOwner[tokenId] = address(0);
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address
     * The call is not executed if the target address is not a contract
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes _data) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID
     * Reverts if the given address is not indeed the owner of the token
     * @param owner owner of the token
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(address owner, uint256 tokenId) private {
        require(ownerOf(tokenId) == owner);
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

/**
 * @dev Manages Devery specific ERC721 functionality. We are going to control the ownership of products through the
 * ERC721 specification, so every product ownership can be represented as a non fungible token. Brands
 * might choose to create, mark and mint a ERC721 for every physical unit of a product or create and mark a single
 * product and then mint multiple units of it. This flexibility will make the process of marking low ticket items
 * expenentially cheaper without compromise the security that you get by creating and marking every single product in case
 * of higher ticket items
 *
 * @title DeveryERC721Token
 * @author victor eloy
 */
contract DeveryERC721Token is ERC721,Admined {


    address[] public tokenIdToProduct;
    mapping(address => uint) public totalAllowedProducts;
    mapping(address => uint) public totalMintedProducts;
    DeveryRegistry deveryRegistry;

    /**
      * @dev modifier to enforce that only the brand that created a given product can change it
      * this modifier will check the core devery registry to fetch the brand address.
      */
    modifier brandOwnerOnly(address _productAddress){
        address productBrandAddress;
        (,productBrandAddress,,,,,) = deveryRegistry.products(_productAddress);
        require(productBrandAddress == msg.sender);
        _;
    }

    /**
      * @dev Allow contract admins to set the address of Core Devery Registry contract
      */
    function setDeveryRegistryAddress(address _deveryRegistryAddress) external onlyAdmin {
        deveryRegistry = DeveryRegistry(_deveryRegistryAddress);
    }

    /**
      * @dev adjusts the maximum mintable amount of a certain product
      */
    function setMaximumMintableQuantity(address _productAddress, uint _quantity) external payable brandOwnerOnly(_productAddress){
        require(_quantity >= totalMintedProducts[_productAddress] || _quantity == 0);
        totalAllowedProducts[_productAddress] = _quantity;
    }

    /**
      * @dev mint a new ERC721 token for a given product and assing it to the original product brand;
      */
    function claimProduct(address _productAddress,uint _quantity) external payable  brandOwnerOnly(_productAddress) {
        require(totalAllowedProducts[_productAddress] == 0 || totalAllowedProducts[_productAddress] >= totalMintedProducts[_productAddress] + _quantity);
        totalMintedProducts[_productAddress]+=_quantity;
        for(uint i = 0;i<_quantity;i++){
            uint nextId = tokenIdToProduct.push(_productAddress) - 1;
            _mint(msg.sender,nextId);
        }
    }

    /**
      * @dev returns the products owned by a given ethereum address
      */
    function getProductsByOwner(address _owner) external view returns (address[]){
        address[] memory products = new address[](balanceOf(_owner));
        uint counter = 0;
        for(uint i = 0; i < tokenIdToProduct.length;i++){
            if(ownerOf(i) == _owner){
                products[counter] = tokenIdToProduct[i];
                counter++;
            }
        }
        return products;
    }
}