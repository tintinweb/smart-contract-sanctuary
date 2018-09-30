pragma solidity^0.4.24;

/// A completely standalone nickname registrar
/// https://M2D.win
/// Laughing Man

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

contract NicknameRegistrar is DSAuth {
    uint public namePrice = 10 finney;

    mapping (address => string) public names;
    mapping (bytes32 => address) internal _addresses;
    mapping (address => string) public pendingNameTransfers;
    mapping (bytes32 => bool) internal _inTransfer;

    modifier onlyUniqueName(string name) {
        require(!nameTaken(name), "Name taken!");
        _;
    }

    modifier onlyPaid() {
        require(msg.value >= namePrice, "Not enough value sent!");
        _;
    }

    modifier limitedLength(string s) {
        require(bytes(s).length <= 32, "Name too long!");
        require(bytes(s).length >= 1, "Name too short!");
        _;
    }

    event NameSet(address addr, string name);
    event NameUnset(address addr);
    event NameTransferRequested(address from, address to, string name);
    event NameTransferAccepted(address by, string name);

    function nameTaken(string name) public view returns(bool) {
        return _addresses[stringToBytes32(name)] != address(0x0) ||
        _inTransfer[stringToBytes32(name)];
    }

    function hasName(address addr) public view returns(bool) {
        return bytes(names[addr]).length > 0;
    }

    function addresses(string name) public view returns(address) {
        return _addresses[stringToBytes32(name)];
    }
    
    function setMyName(string newName) public payable
    onlyUniqueName(newName)
    limitedLength(newName) 
    onlyPaid
    {
        names[msg.sender] = newName;
        _addresses[stringToBytes32(newName)] = msg.sender;
        emit NameSet(msg.sender, newName);
    }

    function unsetMyName() public {
        _addresses[stringToBytes32(names[msg.sender])] = address(0x0);
        names[msg.sender] = "";      
        emit NameUnset(msg.sender);  
    }

    function transferMyName(address to) public payable onlyPaid {
        require(hasName(msg.sender), "You don&#39;t have a name to transfer!");
        pendingNameTransfers[to] = names[msg.sender];
        _inTransfer[stringToBytes32(names[msg.sender])] = true;
        
        emit NameTransferRequested(msg.sender, to, names[msg.sender]);
        names[msg.sender] = "";
    }

    function acceptNameTranfer() public
    limitedLength(pendingNameTransfers[msg.sender]) {
        names[msg.sender] = pendingNameTransfers[msg.sender];
        _addresses[stringToBytes32(pendingNameTransfers[msg.sender])] = msg.sender;
        
        _inTransfer[stringToBytes32(pendingNameTransfers[msg.sender])] = false;
        pendingNameTransfers[msg.sender] = "";
        emit NameTransferAccepted(msg.sender, names[msg.sender]);
    }

    function getMoney() public auth {
        owner.transfer(address(this).balance);
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        // solium-disable security/no-inline-assembly
        assembly {
            result := mload(add(source, 32))
        }
    }
}