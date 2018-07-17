pragma solidity ^0.4.24;

contract Tokens {
    
    address private admin;

    uint256 private _totalSupply;
    mapping(address => uint) private balances;
    uint256 private id;

    mapping(uint256 => address) private tokenOwners;
    mapping(uint256 => bool) private tokenExists;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(uint256 => token) tokens;

    struct token {
        string iamge;
        string description;
        uint256 price;
        address artist;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _id);
    event Approval(address indexed _from, address indexed _to, uint256 _id);

    constructor() public {
        admin = msg.sender;
    }
    
    function name() public pure returns (string) {
        return &quot;Tokens&quot;;
    }

    function symbol() public pure returns (string) {
        return &quot;TKN&quot;;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _address) public view returns (uint) {
        return balances[_address];
    }

    function ownerOf(uint256 _id) public view returns (address) {
        require(tokenExists[_id]);
        return tokenOwners[_id];
    }

    function approve(address _to, uint256 _id) public {
        require(msg.sender == ownerOf(_id));
        require(msg.sender != _to);
        allowed[msg.sender][_to] = _id;
        emit Approval(msg.sender, _to, _id);
    }

    function takeOwnership(uint256 _id) public {
        require(tokenExists[_id]);
        address oldOwner = ownerOf(_id);
        address newOwner = msg.sender;
        require(newOwner != oldOwner);
        require(allowed[oldOwner][newOwner] == _id);
        balances[oldOwner] -= 1;
        tokenOwners[_id] = newOwner;
        balances[newOwner] += 1;
        emit Transfer(oldOwner, newOwner, _id);
    }

    function transfer(address _to, uint256 _id) public {
        address currentOwner = msg.sender;
        address newOwner = _to;
        require(tokenExists[_id]);
        require(currentOwner == ownerOf(_id));
        require(currentOwner != newOwner);
        require(newOwner != address(0));
        balances[currentOwner] -= 1;
        tokenOwners[_id] = newOwner;
        balances[newOwner] += 1;
        emit Transfer(currentOwner, newOwner, _id);
    }

    function tokenMetadata(uint256 _id) public view returns (string, string, uint256, address) {
        return (tokens[_id].iamge, tokens[_id].description, tokens[_id].price, tokens[_id].artist);
    }
    
    function createtoken(string _iamge, string _description, uint256 _price, address _artist, address _owner) public returns (bool success) {
        require(msg.sender == admin);
        tokens[id] = token(_iamge, _description, _price, _artist);
        tokenOwners[id] = _owner;
        tokenExists[id] = true;
        id += 1;
        balances[msg.sender] += 1;
        _totalSupply += 1;
        return true;
    }
    
    function buy(uint256 _id) payable public {
        require(msg.value > 0);
        require(msg.sender != 0x0);
        require(tokenExists[_id]);
        require(msg.value == tokens[_id].price);
        balances[tokenOwners[_id]] -= 1;
        tokenOwners[_id] = msg.sender;
        balances[msg.sender] += 1;
        uint portion = msg.value / 10;
        tokens[_id].artist.transfer(portion);
        tokenOwners[_id].transfer(msg.value - portion);
        tokens[_id].price += tokens[_id].price / 5;
    }
}