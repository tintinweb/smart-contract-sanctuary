pragma solidity ^0.4.24;

contract Tokens {
    
    address private _admin;

    uint256 private _totalSupply;
    mapping(address => uint) private balances;
    uint256 private id;

    mapping(uint256 => address) private tokenOwners;
    mapping(uint256 => bool) private tokenExists;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(uint256 => token) tokens;

    struct token {
        string name;
        string horseId;
        string dna;
        string bornDate;
        string bornTime;
        string mass;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _id);
    event Approval(address indexed _from, address indexed _to, uint256 _id);

    constructor() public {
        _admin = msg.sender;
    }
    
    function admin() public view returns (address) {
        return _admin;
    }
    
    function name() public pure returns (string) {
        return "Tokens";
    }

    function symbol() public pure returns (string) {
        return "TKN";
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

    function tokenMetadata(uint256 _id) public view returns (string, string, string, string, string, string) {
        return (tokens[_id].name, tokens[_id].horseId, tokens[_id].dna, tokens[_id].bornDate, tokens[_id].bornTime, tokens[_id].mass);
    }
    
    function createtoken(string _name, string _horseId, string _dna, string _bornDate, string _bornTime, string _mass, address _owner) public returns (uint256) {
        uint256 tokenId = id;
        tokens[tokenId] = token(_name, _horseId, _dna, _bornDate, _bornTime, _mass);
        tokenOwners[tokenId] = _owner;
        tokenExists[tokenId] = true;
        id += 1;
        balances[msg.sender] += 1;
        _totalSupply += 1;
        return tokenId;
    }
}