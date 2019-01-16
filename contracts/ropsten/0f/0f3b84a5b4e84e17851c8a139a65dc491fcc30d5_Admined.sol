pragma solidity ^0.4.17;
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