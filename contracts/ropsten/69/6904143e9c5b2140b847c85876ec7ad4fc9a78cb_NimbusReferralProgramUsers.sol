/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity =0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function getOwner() external view returns (address);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function transferOwnership(address transferOwner) external onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface INimbusReferralProgram {
    function userSponsor(uint user) external view returns (uint);
    function userSponsorByAddress(address user) external view returns (uint);
    function userIdByAddress(address user) external view returns (uint);
    function userAddressById(uint id) external view returns (address);
    function userSponsorAddressByAddress(address user) external view returns (address);
}

contract NimbusReferralProgramUsers is INimbusReferralProgram, Ownable {
    uint public lastUserId;
    mapping(address => uint) public override userIdByAddress;
    mapping(uint => address) public override userAddressById;
    mapping(uint => uint) public userCategory;
    mapping(uint => uint) private _userSponsor;
    mapping(uint => uint[]) private _userReferrals;

    bytes32 public immutable DOMAIN_SEPARATOR;
    // keccak256("UpdateUserAddressBySig(uint256 id,address user,uint256 nonce,uint256 deadline)");
    bytes32 public constant UPDATE_ADDRESS_TYPEHASH = 0x965f73b57f3777233e641e140ef6fc17fb3dd7594d04c94df9e3bc6f8531614b;
    // keccak256("UpdateUserDataBySig(uint256 id,address user,bytes32 refHash,uint256 nonce,uint256 deadline)");
    bytes32 public constant UPDATE_DATA_TYPEHASG = 0x48b1ff889c9b587c3e7ddba4a9f57008181c3ed75eabbc6f2fefb3a62e987e95;
    mapping(address => uint) public nonces;

    address public migrator;
    mapping(address => bool) public registrators;

    event Register(address indexed user, uint indexed userId, uint indexed sponsorId, uint userType);
    event MigrateUserBySign(address indexed signatory, uint indexed userId, address indexed userAddress, uint nonce);

    constructor(address migratorAddress)  {
        require(migratorAddress != address(0), "Nimbus Referral: Zero address");
        migrator = migratorAddress;
        registrators[migratorAddress] = true;

        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes("NimbusReferralProgram")),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    receive() payable external {
        revert();
    }

    modifier onlyMigrator() {
        require(msg.sender == migrator, "Nimbus Referral: Caller is not the migrator");
        _;
    }

    modifier onlyRegistrator() {
        require(registrators[msg.sender], "Nimbus Referral: Caller is not the registrator");
        _;
    }

    function userSponsorByAddress(address user) external override view returns (uint) {
        return _userSponsor[userIdByAddress[user]];
    }

    function userSponsor(uint user) external override view returns (uint) {
        return _userSponsor[user];
    }

    function userSponsorAddressByAddress(address user) external override view returns (address) {
        uint sponsorId = _userSponsor[userIdByAddress[user]];
        if (sponsorId < 1000000001) return address(0);
        else return userAddressById[sponsorId];
    }

    function getUserReferrals(uint userId) external view returns (uint[] memory) {
        return _userReferrals[userId];
    }

    function getUserReferrals(address user) external view returns (uint[] memory) {
        return _userReferrals[userIdByAddress[user]];
    }




    function registerBySponsorAddress(address sponsorAddress) external returns (uint) { 
        return _registerUser(msg.sender, userIdByAddress[sponsorAddress], 0);
    }

    function register() public returns (uint) {
        return _registerUser(msg.sender, 1000000001, 0);
    }

    function registerBySponsorId(uint sponsorId) public returns (uint) {
        return _registerUser(msg.sender, sponsorId, 0);
    }

    function registerUserBySponsorAddress(address user, address sponsorAddress, uint category) external onlyRegistrator returns (uint) { 
        return _registerUser(user, userIdByAddress[sponsorAddress], category);
    }

    function registerUser(address user, uint category) public onlyRegistrator  returns (uint) {
        return _registerUser(user, 1000000001, category);
    }

    function registerUserBySponsorId(address user, uint sponsorId, uint category) public onlyRegistrator returns (uint) {
        return _registerUser(user, sponsorId, category);
    }

    function _registerUser(address user, uint sponsorId, uint category) private returns (uint) {
        require(user != address(0), "Nimbus Referral: Address is zero");
        require(userIdByAddress[user] == 0, "Nimbus Referral: Already registered");
        require(_userSponsor[sponsorId] != 0, "Nimbus Referral: No such sponsor");
        
        uint id = ++lastUserId; //gas saving
        userIdByAddress[user] = id;
        userAddressById[id] = user;
        _userSponsor[id] = sponsorId;
        _userReferrals[sponsorId].push(id);
        if (category > 0) userCategory[id] = category;
        emit Register(user, id, sponsorId, category);
        return id;
    }



    function migrateUsers(uint[] memory ids, uint[] memory sponsorId, address[] memory userAddress) external onlyMigrator {
        require(lastUserId == 0, "Nimbus Referral: Basic migration is finished");
        require(ids.length == sponsorId.length, "Nimbus Referral: Different array lengths");     
        for (uint i; i < ids.length; i++) {
            uint id = ids[i];
            _userSponsor[id] = sponsorId[i];
            if (userAddress[i] != address(0)) {
                userIdByAddress[userAddress[i]] = id;
                userAddressById[id] = userAddress[i];
            }
        }
    } 

    function updateUserAddress(uint id, address userAddress) external onlyMigrator {
        require(userAddress != address(0), "Nimbus Referral: Address is zero");
        require(_userSponsor[id] > 1000000000, "Nimbus Referral: No such user");
        require(userIdByAddress[userAddress] == 0, "Nimbus Referral: Address is already in the system");
        userIdByAddress[userAddress] = id;
        userAddressById[id] = userAddress;
    }

    
    function updateUserCategory(uint id, uint category) external onlyMigrator {
        require(_userSponsor[id] > 1000000000, "Nimbus Referral: No such user");
        userCategory[id] = category;
    }

    function updateUserAddressBySig(uint id, address userAddress, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "Nimbus Referral: Signature expired");
        require(userIdByAddress[userAddress] == 0, "Nimbus Referral: Address is already in the system");
        uint nonce = nonces[userAddress]++;
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(UPDATE_ADDRESS_TYPEHASH, id, userAddress, nonce, deadline))
            )
        );
        
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == migrator, 'Nimbus Referral: Invalid signature');
        userIdByAddress[userAddress] = id;
        userAddressById[id] = userAddress;
        emit MigrateUserBySign(recoveredAddress, id, userAddress, nonce);
    }

    function updateUserCategoryBySig(uint id, uint category, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "Nimbus Referral: Signature expired");
        require(_userSponsor[id] > 1000000000, "Nimbus Referral: No such user");
        uint nonce = nonces[userAddressById[id]]++;
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(UPDATE_ADDRESS_TYPEHASH, id, category, nonce, deadline))
            )
        );
        
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == migrator, 'Nimbus Referral: Invalid signature');
        userCategory[id] = category;
    }

    function updateUserDataBySig(uint id, address userAddress, uint[] memory referrals, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "Nimbus Referral: Signature expired");
        uint nonce = nonces[userAddress]++;
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(UPDATE_DATA_TYPEHASG, id, userAddress, keccak256(abi.encodePacked(referrals)), nonce, deadline))
            )
        );
        
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == migrator, 'Nimbus Referral: Invalid signature');
        userIdByAddress[userAddress] = id;
        userAddressById[id] = userAddress;
        _userReferrals[id] = referrals;
        emit MigrateUserBySign(recoveredAddress, id, userAddress, nonce);
    }

    function updateUserReferralsBySig(uint id, address userAddress, uint[] memory referrals, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "Nimbus Referral: Signature expired");
        uint nonce = nonces[userAddress]++;
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(UPDATE_DATA_TYPEHASG, id, userAddress, keccak256(abi.encodePacked(referrals)), nonce, deadline))
            )
        );
        
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == migrator, 'Nimbus Referral: Invalid signature');
        userIdByAddress[userAddress] = id;
        userAddressById[id] = userAddress;
        for (uint i; i < referrals.length; i++) {
            _userReferrals[id].push(referrals[i]);
        }
        emit MigrateUserBySign(recoveredAddress, id, userAddress, nonce);
    }

    function updateUserReferrals(uint id, uint[] memory referrals) external onlyMigrator {
        _userReferrals[id] = referrals;
        for (uint i; i < referrals.length; i++) {
            _userReferrals[id].push(referrals[i]);
        }
    }

    function updateMigrator(address newMigrator) external {
        require(msg.sender == migrator || msg.sender == owner, "Nimbus Referral: Not allowed");
        require(newMigrator != address(0), "Nimbus Referral: Address is zero");
        migrator = newMigrator;
    }

    function updateRegistrator(address registrator, bool isActive) external onlyOwner {
        registrators[registrator] = isActive;
    }

    function finishBasicMigration(uint userId) external onlyMigrator {
        lastUserId = userId;
    }
}