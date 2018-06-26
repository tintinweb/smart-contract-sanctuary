pragma solidity ^0.4.22;

contract Tokens {
    
    address private _admin;

    uint256 private _totalSupply;
    mapping(address => uint) private balances;
    uint256 private index;
    mapping(uint256 => string) private ids;

    mapping(string => address) private tokenOwners;
    mapping(string => bool) private tokenExists;
    mapping(address => mapping (address => string)) allowed;
    mapping(string => token) tokens;

    struct token {
        string name;
        string price;
        string description;
    }

    event Transfer(address indexed _from, address indexed _to, string _tokenId);
    event Approval(address indexed _from, address indexed _to, string _tokenId);

    constructor() public {
        _admin = msg.sender;
    }
    
    function admin() public view returns (address) {
        return _admin;
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
    
    function idOf(uint256 _id) public view returns (string) {
        return ids[_id];
    }

    function ownerOf(string _tokenId) public view returns (address) {
        require(tokenExists[_tokenId]);
        return tokenOwners[_tokenId];
    }

    function approve(address _to, string _tokenId) public {
        require(msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);
        allowed[msg.sender][_to] = _tokenId;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function takeOwnership(string _tokenId) public {
        require(tokenExists[_tokenId]);
        address oldOwner = ownerOf(_tokenId);
        address newOwner = msg.sender;
        require(newOwner != oldOwner);
        require(keccak256(allowed[oldOwner][newOwner]) == keccak256(_tokenId));
        balances[oldOwner] -= 1;
        tokenOwners[_tokenId] = newOwner;
        balances[newOwner] += 1;
        emit Transfer(oldOwner, newOwner, _tokenId);
    }

    function transfer(address _to, string _tokenId) public {
        address currentOwner = msg.sender;
        address newOwner = _to;
        require(tokenExists[_tokenId]);
        require(currentOwner == ownerOf(_tokenId));
        require(currentOwner != newOwner);
        require(newOwner != address(0));
        balances[currentOwner] -= 1;
        tokenOwners[_tokenId] = newOwner;
        balances[newOwner] += 1;
        emit Transfer(currentOwner, newOwner, _tokenId);
    }

    function tokenMetadata(string _tokenId) public view returns (string, string, string) {
        return (tokens[_tokenId].name, tokens[_tokenId].price, tokens[_tokenId].description);
    }
    
    function createtoken(string _id, string _name, string _price, string _description) public returns (bool success) {
        //require(msg.sender == _admin);
        require(tokenExists[_id] == false);
        tokens[_id] = token(_name, _price, _description);
        tokenOwners[_id] = msg.sender;
        tokenExists[_id] = true;
        ids[index] = _id;
        index += 1;
        balances[msg.sender] += 1;
        _totalSupply += 1;
        return true;
    }

    function updatetoken(string _tokenId, string _name, string _price, string _description) public returns (bool success) {
        //require(msg.sender == _admin);
        require(tokenOwners[_tokenId] == msg.sender);
        require(tokenExists[_tokenId]);
        tokens[_tokenId] = token(_name, _price, _description);
        return true;
    }
    
    function changeadmin(address _new_admin) public {
        require(msg.sender == _admin);
        _admin = _new_admin;
    }
}