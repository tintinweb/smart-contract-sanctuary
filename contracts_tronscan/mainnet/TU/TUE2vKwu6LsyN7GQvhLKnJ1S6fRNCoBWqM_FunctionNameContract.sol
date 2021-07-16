//SourceUnit: functionNames.sol

pragma solidity 0.4.25;

// Function Island Username contract. Names cost 25 trx to set or change. Funds go to Developer.
contract FunctionNameContract {
    address public nameFundReceiver;
    
    uint private usernamePrice;
    
    mapping(address => string) private addressNameMap;
    mapping(string => address) private nameAddressMap;
    
    event Register(address addr, string name);
    event FundsCollected(address addr, uint funds);

    constructor() public {nameFundReceiver = msg.sender; usernamePrice = 25000000;}
    function namePrice() public view returns (uint) {return usernamePrice;}
    function nameBalance() public view returns (uint) {return address(this).balance;}
    function getAddressByName(string memory name) public view returns (address) {return nameAddressMap[name];} // Find address of a user
    function getNameByAddress(address addr) public view returns (string memory name) {return addressNameMap[addr];} // Find username of an address
    function isAvailable(string memory name) public view returns (bool) {if (checkCharacters(bytes(name))) {return (nameAddressMap[name] == address(0));} return false;} // Check availability

    // ADMIN: Collect Funds
    function collectFunds() public returns (bool _success) {
        require(msg.sender == nameFundReceiver);
        uint funds = address(this).balance;
        nameFundReceiver.transfer(funds);
        emit FundsCollected(nameFundReceiver, funds);
        return true;
    }

    // Register a name for your own address - you pay the fee, you get the name.
    function registerName(string memory name) public payable returns (bool _success) {
        require(msg.value == namePrice());
        require(bytes(name).length <= 32, "name must be fewer than 32 bytes");
        require(bytes(name).length >= 3, "name must be more than 3 bytes");
        require(checkCharacters(bytes(name)));
        require(nameAddressMap[name] == address(0), "name in use");
        string memory oldName = addressNameMap[msg.sender];
        if (bytes(oldName).length > 0) {nameAddressMap[oldName] = address(0);}
        addressNameMap[msg.sender] = name;
        nameAddressMap[name] = msg.sender;
        emit Register(msg.sender, name);
        return true;
    }
    
    // Register a name for another address - you pay the fee, they get the name.
    function registerNameFor(address _for, string memory name) public payable returns (bool _success) {
        require(msg.value == namePrice());
        require(bytes(name).length <= 32, "name must be fewer than 32 bytes");
        require(bytes(name).length >= 3, "name must be more than 3 bytes");
        require(checkCharacters(bytes(name)));
        require(nameAddressMap[name] == address(0), "name in use");
        string memory oldName = addressNameMap[_for];
        if (bytes(oldName).length > 0) {nameAddressMap[oldName] = address(0);}
        addressNameMap[_for] = name;
        nameAddressMap[name] = _for;
        emit Register(_for, name);
        return true;
    }
    
    // Validation - Check for only letters and numbers (9-0, A-Z, a-z)
    function checkCharacters(bytes memory name) internal pure returns (bool) {
        for(uint i; i<name.length; i++){bytes1 char = name[i]; if(!(char >= 0x30 && char <= 0x39) && !(char >= 0x41 && char <= 0x5A) && !(char >= 0x61 && char <= 0x7A)) return false;} return true;
    }
}