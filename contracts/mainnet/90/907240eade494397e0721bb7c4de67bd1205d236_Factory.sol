contract Registry {
    function owner(bytes32 node) public view returns (address) {}
}

contract Registrar { 
    modifier onlyOwner(bytes32 _hash) { _; }
    function transfer(bytes32 _hash, address newOwner) onlyOwner(_hash) {}
}

contract PublicResolver {
    modifier only_owner(bytes32 node) { _; }
    function setAddr(bytes32 node, address addr) only_owner(node) {}
    function setContent(bytes32 node, bytes32 hash) only_owner(node) {}
    function setName(bytes32 node, string name) only_owner(node) {}
    function setABI(bytes32 node, uint256 contentType, bytes data) only_owner(node) {}
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) only_owner(node) {}
    function setText(bytes32 node, string key, string value) only_owner(node) {}
}

contract ENS_Permissions {

    Registry registry = Registry(0x314159265dD8dbb310642f98f50C066173C1259b);
    Registrar registrar = Registrar(0x6090A6e47849629b7245Dfa1Ca21D94cd15878Ef);
    PublicResolver publicResolver = PublicResolver(0x5FfC014343cd971B7eb70732021E26C35B744cc4);

    address owner;
    bytes32 labelhash;
    bytes32 namehash;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier only_owner {
        require(owner == msg.sender);
        _;
    }

    struct Permissions {
        uint ownerMutability;
        uint addressMutability;
        mapping(string => uint) textKeyMutability;
    }

    Permissions permissions;

    function setOwner(address _newOwner) only_owner {
        owner = _newOwner;
    }

    function activatePermissionsBot(bytes32 _namehash, bytes32 _labelhash) only_owner {
        require(registry.owner(_namehash) == address(this));
        require(labelhash == 0 && namehash == 0);
        labelhash = _labelhash;
        namehash = _namehash;
    }

    function lockOwnership(uint _date) only_owner {
        require(permissions.ownerMutability < block.timestamp);
        require(_date > block.timestamp);
        permissions.ownerMutability == _date;
    }
    function lockAddress(uint _date) only_owner {
        require(permissions.ownerMutability > _date);
        require(permissions.addressMutability < block.timestamp);
        require(_date > block.timestamp);
        permissions.addressMutability == _date;
    }
    function lockTextKey(string _key, uint _date) only_owner {
        require(permissions.ownerMutability > _date);
        require(permissions.textKeyMutability[_key] < block.timestamp);
        require(_date > block.timestamp);
        permissions.textKeyMutability[_key] == _date;
    }
    
    // Transferring ownership from this contract also destroys the contract
    function transfer(address _newOwner) only_owner {
        require(permissions.ownerMutability < block.timestamp);
        registrar.transfer(labelhash, _newOwner);
        selfdestruct(msg.sender);
    }
    function setAddr(address _addr) only_owner {
        require(permissions.addressMutability < block.timestamp);
        publicResolver.setAddr(namehash, _addr);
    }
    function setText(string _key, string _value) only_owner {
        require(permissions.textKeyMutability[_key] < block.timestamp);
        publicResolver.setText(namehash, _key, _value);
    }    
}

contract Factory {
    function createPermissionsBot(address _owner) returns (address) {
        ENS_Permissions permissionsBot = new ENS_Permissions(_owner);
        return permissionsBot;
    }
}