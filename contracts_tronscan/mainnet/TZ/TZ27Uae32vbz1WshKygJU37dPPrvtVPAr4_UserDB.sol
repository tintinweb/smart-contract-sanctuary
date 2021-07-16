//SourceUnit: userdb.sol

pragma solidity 0.4.25;

contract UserDB {
    address public administrator;
    
    uint usernamePrice = 10000000; // 10 TRX to register a username
    
    mapping(address => string) private addressNameMap;
    mapping(string => address) private nameAddressMap;
    mapping(address => bool) private blocked;
    
    event Register(address addr, string name);
    
    event AddressBlocked(address addr);
    event AddressUnblocked(address addr);
    
    event FundsCollected(address addr, uint funds);

    // Find address of a user
    function getAddressByName(string memory name) public view returns (address) {return nameAddressMap[name];}

    // Find username of an address
    function getNameByAddress(address addr) public view returns (string memory name) {
        if (blocked[addr]) {
            return '';
        } else {
            return addressNameMap[addr];
        }
    }
    
    // Check availability
    function isAvailable(string memory name) public view returns (bool) {
        if (checkCharacters(bytes(name))) {
          return (nameAddressMap[name] == address(0));
        }
        return false;
    }
    
    constructor() public {
        administrator = msg.sender;
    }
    
    // Block an address from getting a username
    function blockAddress(address addr) public {
        require(msg.sender == administrator);
        blocked[addr] = true;
        emit AddressBlocked(addr);
    }
    
    // Unblock an address, allowing it to get a username
    function unblockAddress(address addr) public {
        require(msg.sender == administrator);
        blocked[addr] = false;
        emit AddressUnblocked(addr);
    }

    // ADMIN: Collect Funds
    function collectFunds() public {
        require(msg.sender == administrator);
        uint funds = address(this).balance;
        administrator.transfer(funds);
        emit FundsCollected(administrator, funds);
    }
    
    function nameBalance() public view returns (uint) {return address(this).balance;}

    // Register
    function registerName(string memory name) public payable {
        require(msg.value == usernamePrice);
        require(bytes(name).length <= 32, "name must be fewer than 32 bytes");
        require(bytes(name).length >= 3, "name must be more than 3 bytes");
        require(checkCharacters(bytes(name)));

        require(!blocked[msg.sender]);
        require(nameAddressMap[name] == address(0), "name in use");
        
        string memory oldName = addressNameMap[msg.sender];
        if (bytes(oldName).length > 0) {nameAddressMap[oldName] = address(0);}

        addressNameMap[msg.sender] = name;
        nameAddressMap[name] = msg.sender;
        emit Register(msg.sender, name);
    }
    
    // Validation
    function checkCharacters(bytes memory name) internal pure returns (bool) {
        // Check for only letters and numbers
        for(uint i; i<name.length; i++){
            bytes1 char = name[i];
            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A)    //a-z
            )
                return false;
        }
        return true;
    }
}