//SourceUnit: Patronize.sol

pragma solidity 0.5.10;

contract Patronize {
    
    struct User {
        uint32 id;
        address userAddress;
        address sponsor;
        address placement;
        uint32 directSales;
        bool exists;
    }
    
    mapping (address => User) public users;
    uint32 private lastId;
    address private owner;
    
    uint internal reentry_status;
    uint internal constant ENTRY_ENABLED = 1;
    uint internal constant ENTRY_DISABLED = 2;
    
    modifier blockEntry() {

        require(reentry_status != ENTRY_DISABLED, "Security Entry Block");
        reentry_status = ENTRY_DISABLED;
        _;

        reentry_status = ENTRY_ENABLED;
    }
    
    event registerEvent(uint indexed userId, address indexed user, address indexed sponsor);
    
    constructor(address _user) public payable {
        owner = _user;
        
        reentry_status = ENTRY_ENABLED;
        
        if(!users[_user].exists) {
            createAccount(_user, _user, _user);
        }
    }
    
    function() external payable {
        registrationEntry(msg.sender, owner, owner);
    }
    
    function userRegister(address _sender, address _sponsor, address _placement) external payable blockEntry() {
        //require(!users[_sender].exists, "Account already exists");
        //require(users[_sponsor].exists, "Sponsor not exists");
        //require(users[_placement].exists, "Placement not exists");
        
        registrationEntry(_sender, _sponsor, _placement);
    }
    
    function registrationEntry(address _user, address _sponsor, address _placement) internal  {
        require(msg.value==777000000, "777 TRX Require to register!");
        
        createAccount(_user, _sponsor, _placement);

        doPayout(_sponsor);
    }
    
    function createAccount(address _user, address _sponsor, address _placement) internal {
        lastId++;
        users[_user] = User({
            id: lastId,
            userAddress: _user,
            sponsor: _sponsor,
            placement: _placement,
            directSales: 0,
            exists: true
        });
        users[_sponsor].directSales++;
        
        emit registerEvent(lastId, _user, _sponsor);
    }
    
    function doPayout(address _user) internal {
        address(uint160(_user)).transfer(192000000);
        address(uint160(owner)).transfer(585000000);
    }
    
}