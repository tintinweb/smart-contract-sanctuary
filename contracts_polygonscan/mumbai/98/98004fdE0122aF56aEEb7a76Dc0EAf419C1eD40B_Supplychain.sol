/**
 *Submitted for verification at polygonscan.com on 2021-10-05
*/

pragma solidity ^0.8.0;

contract Supplychain{
    
    // state
    enum PackageState{NONE, REGISTERED, DISPATCHED, IN_TRANSIT, DELIVERED}
    
    struct Package{
        PackageState state;
        uint256      registerDate;
        uint256      deliveryDate;
        uint256      id;
        address      sender;
    }
    uint256 private packageCounter;
    mapping(uint256 => Package) public  packages;
    mapping(address => bool)    private admins;
    mapping(address => bool)    private users;
    
    event PackageRegistered(uint256 id, address sender, uint256 timestamp);
    event PackageUpdate(uint256 id, PackageState state);
    event PackageDelivered(uint256 id, PackageState state, uint256 timestamp);
    event NewAdmin(address from, address newAdmin, uint256 timestamp);
    event NewUser(address newUser, uint256 timestamp);
    
    //logic
    
    modifier onlyAdmin() {
        require(admins[msg.sender], "Supplychain: only admin can invoke");
        _;
    }
    
    modifier onlyUser() {
        require(users[msg.sender], "Supplychain: only users can invoke");
        _;
    }
    
    constructor () {
        admins[msg.sender] = true;
        emit NewAdmin(address(0), msg.sender, block.timestamp);
    }
    
    function registerPackage() onlyUser public {
        packageCounter++;
        Package memory package;
        package.state = PackageState.REGISTERED;
        package.registerDate = block.timestamp;
        package.id = packageCounter;
        package.sender = msg.sender;
        packages[packageCounter] = package;
        emit PackageRegistered(packageCounter, msg.sender, block.timestamp);
    }
    
    function nextStep(uint256 _id) onlyAdmin public {
        require(
            packages[_id].sender!=address(0), 
            "Supplychain: package does exist"
        );
        packages[_id].state = PackageState( uint8(packages[_id].state) + 1 );
        if(packages[_id].state == PackageState.DELIVERED){
            packages[_id].deliveryDate = block.timestamp;
            emit PackageDelivered(_id, PackageState.DELIVERED, block.timestamp);
        }else {
            emit PackageUpdate(_id, packages[_id].state);
        }
    }
    
    function addAdmin(address _admin) public onlyAdmin {
        require(
            !users[_admin], 
            "Supplychain: User cannot be an admin"
        );
        admins[_admin] = true;
        emit NewAdmin(msg.sender, _admin, block.timestamp);
    }
    
    function registerAsUser() public {
        require(
            !admins[msg.sender],
            "Supplychain: Admin cannot be a user"
        );
        users[msg.sender] = true;
        emit NewUser(msg.sender, block.timestamp);
    }
    
}