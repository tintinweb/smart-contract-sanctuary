pragma solidity ^0.4.26;
pragma experimental ABIEncoderV2;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract Shop is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public _totalSupply;
    int256 uuid = 0;
    address owner;
    Item[] public Items;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => string[]) public UserInvntory;
    mapping(address => bool) public whitelist;
    mapping(address => int256) public UserBonus;
    mapping(uint256 => RepairItem) public RepairItems;
    struct Item {
        string itemName;
        int256 itemPrice;
        int256 itemCount;
        string itemDescription;
        string imageHash;
        address sender;
        uint256 createAt;
    }

    struct RepairItem {
        address vendorAddress;
        address customerAddress;
        address sender;
        string itemName;
        string itemDescription;
        string imageHash;
        int256 repairPrice;
        uint256 createAt;
    }

    struct UserInventory {
        string imagesHash;
    }

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        owner = msg.sender;
        name = "WSShop";
        symbol = "WSS";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyOwner() {
        //檢查發送者是不是owner 不是的話就回傳Not Owner
        require(msg.sender == owner, "Not Owner!!!");
        _;
    }

    modifier checkEnoughBonus(address _address, int256 price) {
        require(UserBonus[_address] >= price, "User not have enough bonus");
        _;
    }

    modifier checkWhitelist(address _address) {
        require(
            whitelist[_address] == true,
            "The address does not exist in the whitelist"
        );
        _;
    }

    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 tokens)
        public
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint256 tokens)
        public
        returns (bool success)
    {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function createItem(
        string _itemName,
        int256 _itemPrice,
        int256 _itemCount,
        string _itemDescription,
        string _imageHash
    ) public {
        Item memory newItem =
            Item({
                itemName: _itemName,
                itemPrice: _itemPrice,
                itemCount: _itemCount,
                itemDescription: _itemDescription,
                sender: msg.sender,
                imageHash: _imageHash,
                createAt: now
            });
        Items.push(newItem);
    }

    function buy(
        address _address,
        int256 _bonus,
        string _imagesHash
    ) public returns (bool) {
        UserBonus[_address] += _bonus;
        UserInvntory[_address].push(_imagesHash);
        return true;
    }

    function repair(
        address _vendorAddress,
        address _customerAddress,
        string _itemName,
        string _itemDescription,
        string _imageHash,
        int256 _repairPrice,
        uint256 _index
    ) public checkWhitelist(_vendorAddress) {
        RepairItems[_index] = RepairItem({
            vendorAddress: _vendorAddress,
            customerAddress: _customerAddress,
            sender: msg.sender,
            itemName: _itemName,
            itemDescription: _itemDescription,
            imageHash: _imageHash,
            repairPrice: _repairPrice,
            createAt: now
        });
    }

    function exchangeGift(address _address, int256 price)
        public
        checkEnoughBonus(_address, price)
        returns (bool)
    {
        UserBonus[_address] -= price;
        return true;
    }

    function getAllItemsData() public view returns (Item[] memory) {
        return Items;
    }

    function getUserInventory(address _address) public view returns (string[]) {
        return UserInvntory[_address];
    }
}

