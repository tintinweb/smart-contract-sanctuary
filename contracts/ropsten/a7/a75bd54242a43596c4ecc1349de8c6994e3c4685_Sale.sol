pragma solidity ^0.4.23;

contract Token {
    uint public totalSupply;

    function balanceOf(address _owner) public view returns (uint balance);

    function transfer(address _to, uint _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    function approve(address _spender, uint _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract HasOwners {

    mapping(address => bool) public isOwner;
    address[] private owners;

    constructor(address[] _owners) public {
        for (uint i = 0; i < _owners.length; i++) _addOwner_(_owners[i]);
        owners = _owners;
    }

    modifier onlyOwner {require(isOwner[msg.sender], "sender must be owner");
        _;}
    modifier validAddress(address value) {require(value != address(0x0), "invalid address");
        _;}

    function getOwners() public view returns (address[]) {return owners;}

    function addOwner(address owner) external onlyOwner {_addOwner_(owner);}

    function _addOwner_(address owner) validAddress(owner) private {
        if (!isOwner[owner]) {
            isOwner[owner] = true;
            owners.push(owner);
            emit OwnerAdded(owner);
        }
    }

    event OwnerAdded(address indexed owner);

    function removeOwner(address owner) external onlyOwner {
        if (isOwner[owner]) {
            require(owners.length > 1, "removing the last owner is not allowed");
            isOwner[owner] = false;
            for (uint i = 0; i < owners.length - 1; i++) {
                if (owners[i] == owner) {
                    owners[i] = owners[owners.length - 1];
                    // replace map last entry
                    delete owners[owners.length - 1];
                    break;
                }
            }
            owners.length -= 1;
            emit OwnerRemoved(owner);
        }
    }

    event OwnerRemoved(address indexed owner);
}

contract Sale is HasOwners {
    address public wallet;
    Token public token;
    uint public price = 1000000;

    constructor (address[] _owners, address _wallet, address _token) HasOwners(_owners) public {
        wallet = _wallet;
        token = Token(_token);
    }

    function setToken(address _token) onlyOwner external {
        token = Token(_token);
    }

    function setWallet(address _wallet) onlyOwner external {
        wallet = _wallet;
    }

    function() external payable {
        wallet.transfer(msg.value);
        token.transfer(msg.sender, msg.value * price);
    }
}