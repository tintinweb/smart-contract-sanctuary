pragma solidity ^0.4.16;

contract TestERC721 {
    
    address private _admin;

    uint256 private _totalSupply;
    mapping(address => uint) private balances;
    uint256 private index;

    mapping(uint256 => address) private tokenOwners;
    mapping(uint256 => bool) private tokenExists;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(uint256 => token) tokens;

    struct token {
        string name;
        string link;
        uint256 price;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _from, address indexed _to, uint256 _tokenId);

    function TestERC721() public {
        _admin = msg.sender;
    }
    
    function admin() public constant returns (address) {
        return _admin;
    }
    
    function name() public pure returns (string) {
        return "Test Token";
    }

    function symbol() public pure returns (string) {
        return "TTE";
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _address) public constant returns (uint) {
        return balances[_address];
    }

    function changeAdmin(address _address) public {
        require(msg.sender == _admin);
        _admin = _address;
    }
    function ownerOf(uint256 _tokenId) public constant returns (address) {
        require(tokenExists[_tokenId]);
        return tokenOwners[_tokenId];
    }

    function approve(address _to, uint256 _tokenId) public {
        require(msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);
        allowed[msg.sender][_to] = _tokenId;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function takeOwnership(uint256 _tokenId) public {
        require(tokenExists[_tokenId]);
        address oldOwner = ownerOf(_tokenId);
        address newOwner = msg.sender;
        require(newOwner != oldOwner);
        require(allowed[oldOwner][newOwner] == _tokenId);
        balances[oldOwner] -= 1;
        tokenOwners[_tokenId] = newOwner;
        balances[newOwner] += 1;
        emit Transfer(oldOwner, newOwner, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public {
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

    function tokenMetadata(uint256 _tokenId) public constant returns (string, string, uint256) {
        return (tokens[_tokenId].name, tokens[_tokenId].link, tokens[_tokenId].price);
    }
    
    function createtoken(string _name, string _link, uint256 _price) public returns (bool success) {
        tokens[index] = token(_name, _link, _price);
        tokenOwners[index] = msg.sender;
        tokenExists[index] = true;
        index += 1;
        balances[msg.sender] += 1;
        _totalSupply += 1;
        return true;
    }

    function updatetoken(uint256 _tokenId, string _name, string _link, uint256 _price) public returns (bool success) {
        require(tokenExists[_tokenId]);
        tokens[_tokenId] = token(_name, _link, _price);
        return true;
    }

    function buytoken(uint256 _tokenId) payable public {
        address newOwner = msg.sender;
        address oldOwner = tokenOwners[_tokenId];
        require(tokenExists[_tokenId]);
        require(newOwner != ownerOf(_tokenId));
        require(msg.value >= tokens[_tokenId].price);
        uint256 _remainder = msg.value - tokens[_tokenId].price;
        newOwner.transfer(_remainder);
        uint256 price20 = tokens[_tokenId].price/5;
        _admin.transfer(price20/20);
        oldOwner.transfer(tokens[_tokenId].price - price20/20);
        tokens[_tokenId].price += price20; 
        tokenOwners[_tokenId] = newOwner;
        balances[oldOwner] -= 1;
        balances[newOwner] += 1;
        emit Transfer(oldOwner, newOwner, _tokenId);
    }
}