/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

pragma solidity =0.8.1;

interface IReferralProgram {
    function userSponsorByAddress(address user) external view returns (uint);
    function userSponsor(uint user) external view returns (uint);
    function userAddressById(uint id) external view returns (address);
    function userIdByAddress(address user) external view returns (uint);
    function userSponsorAddressByAddress(address user) external view returns (address);
    
    event Registration(uint userId, address userAddress, uint sponsorId);
}

contract UnicornReferralProgramUsers is IReferralProgram {
    uint public lastUserId;
    mapping(address => uint) public override userIdByAddress;
    mapping(uint => address) public override userAddressById;

    mapping(uint => uint) private _userSponsor;
    mapping(uint => uint[]) private _userReferrals;

    constructor(address initialUser)  {
        userIdByAddress[initialUser] = 2;
        userAddressById[2] = initialUser;
        _userSponsor[2] = 1;
        lastUserId = 2;
    }

    receive() payable external {
        revert();
    }

    function userSponsorByAddress(address user) external override view returns (uint) {
        return _userSponsor[userIdByAddress[user]];
    }

    function userSponsor(uint user) external override view returns (uint) {
        return _userSponsor[user];
    }

    function userSponsorAddressByAddress(address user) external override view returns (address) {
        return userAddressById[_userSponsor[userIdByAddress[user]]];
    }

    function getUserReferrals(uint userId) external view returns (uint[] memory) {
        return _userReferrals[userId];
    }

    function getUserReferrals(address user) external view returns (uint[] memory) {
        return _userReferrals[userIdByAddress[user]];
    }


    function registerBySponsorAddress(address sponsorAddress) external returns (uint) { 
        return registerBySponsorId(userIdByAddress[sponsorAddress]);
    }

    function register() public returns (uint) {
        return registerBySponsorId(2);
    }

    function registerBySponsorId(uint sponsorId) public returns (uint) {
        require(userIdByAddress[msg.sender] == 0, "Unicorn Users: Already registered");
        require(_userSponsor[sponsorId] != 0, "Unicorn Users: No such sponsor");
        
        uint id = ++lastUserId; //gas saving
        userIdByAddress[msg.sender] = id;
        userAddressById[id] = msg.sender;
        _userSponsor[id] = sponsorId;
        _userReferrals[sponsorId].push(id);
        emit Registration(id, msg.sender, sponsorId);
        return id;
    }
}