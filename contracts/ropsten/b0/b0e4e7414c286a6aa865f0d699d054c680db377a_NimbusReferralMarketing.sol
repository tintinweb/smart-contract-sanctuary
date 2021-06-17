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

interface INimbusReferralProgramUsers {
    function userSponsor(uint user) external view returns (uint);
    function registerUser(address user, uint category) external returns (uint); //public
}

interface INimbusReferralProgram {
    function userSponsor(uint user) external view returns (uint);
    function userSponsorByAddress(address user) external view returns (uint);
    function userIdByAddress(address user) external view returns (uint);
    function userAddressById(uint id) external view returns (address);
    function userSponsorAddressByAddress(address user) external view returns (address);
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

contract NimbusReferralMarketing is Ownable {

    struct StakingAmount {
        uint NBU;
        uint GNBU;
    }

    INimbusReferralProgram rp;
    INimbusReferralProgramUsers rpUsers;
    IBEP20 NBU;
    IBEP20 GNBU;

    mapping(address => bool) public isManager;
    mapping(address => bool) public isLeader;

    mapping(address => address) public userLeader;
    mapping(address => address) public userManager;

    mapping(address => StakingAmount) public leaderTotalStakingAmount;
    mapping(address => StakingAmount) public managerTotalStakingAmount;

    mapping(address => bool) public isAllowedContract;

    constructor(address _nbu, address _gnbu, address _rp, address _rpUsers) {
        NBU = IBEP20(_nbu);
        GNBU = IBEP20(_gnbu);
        rp = INimbusReferralProgram(_rp);
        rpUsers = INimbusReferralProgramUsers(_rpUsers);
    }

    modifier onlyAllowedContract() {
        require(isAllowedContract[msg.sender] == true, "NimbusReferralProgram: Provided address is not an allowed contract");
        _;
    }
   
    function updateAllowedContract(address _contract, bool isAllowed) external onlyOwner {
        require(_isContract(_contract), "NimbusReferralProgram: Provided address is not a contract.");
        isAllowedContract[_contract] = isAllowed;
    }

    function updateLeader(address user, bool _isLeader) external onlyOwner {
        require(rp.userIdByAddress(user) != 0, "NimbusReferralProgram: User is not registered.");
        isLeader[user] = _isLeader;
    }

    function updateLeaderForUser(address user, address leader) public {
        require(user != address(0), "NimbusReferralProgram: User address is equal to 0");
        require(leader != address(0), "NimbusReferralProgram: Leader address is equal to 0");

        userLeader[user] = leader;
    }

    function updateLeaderForUsers(address leader, address[] memory users) external onlyOwner {
        for(uint i = 0; i < users.length; i++) {
            updateLeaderForUser(users[i], leader);
        }
    }
    
    function updateLeadersForUsers(address[] memory leaders, address[] memory users) external onlyOwner {
        require(leaders.length == users.length, "NimbusReferralProgram: Leaders and users arrays length are not equal.");
        for(uint i = 0; i < users.length; i++) {
            updateLeaderForUser(users[i], leaders[i]);
        }
    }

    function updateManager(address user, bool _isManager) external onlyOwner {
        require(rp.userIdByAddress(user) != 0, "NimbusReferralProgram: User is not registered.");
        isManager[user] = _isManager;
    }

    function updateManagerForUser(address user, address manager) public {
        require(user != address(0), "NimbusReferralProgram: User address is equal to 0");
        require(manager != address(0), "NimbusReferralProgram: Manager address is equal to 0");

        userManager[user] = manager;
    }

    function updateManagerForUsers(address manager, address[] memory users) external onlyOwner {
        for(uint i = 0; i < users.length; i++) {
            updateManagerForUser(users[i], manager);
        }
    }

    function updateManagerssForUsers(address[] memory managers, address[] memory users) external onlyOwner {
        require(managers.length == users.length, "NimbusReferralProgram: Managers and users arrays length are not equal.");
        for(uint i = 0; i < users.length; i++) {
            updateManagerForUser(users[i], managers[i]);
        }
    }

    function registerUser(address user, uint sponsorId) external returns(uint userId){
        address sponsorAddress = rp.userAddressById(sponsorId);

        if (isLeader[sponsorAddress] == true) {
            updateLeaderForUser(user, sponsorAddress);
            updateManagerForUser(user, userManager[sponsorAddress]);
            return rpUsers.registerUser(user, sponsorId);
        } else {
            updateLeaderForUser(user, userLeader[sponsorAddress]);
            updateManagerForUser(user, userManager[userLeader[sponsorAddress]]);
            return rpUsers.registerUser(user, sponsorId);
        }
    }

    function updateReferralStakingAmount(address user, address token, uint amount) external onlyAllowedContract {
        require(rp.userIdByAddress(user) != 0, "NimbusReferralProgram: User is not a part of referral program.");
        require(token == address(NBU) || token == address(GNBU), "NimbusReferralProgram: Invalid staking token.");

        _updateTokenStakingAmount(userLeader[user], token, amount);
    }
    
    function _isContract(address _contract) internal view returns (bool isContract){
        uint32 size;
        assembly {
            size := extcodesize(_contract)
        }
        return (size > 0);
    }

    function _updateTokenStakingAmount(address leader, address token, uint amount) internal {
        require(isLeader[leader] == true, "NimbusReferralProgram: User is not leader.");
        require(userManager[leader] != address(0), "NimbusReferralProgram: Leader has no manager.");
        
        if(token == address(NBU)) {
            leaderTotalStakingAmount[leader].NBU += amount;
            managerTotalStakingAmount[userManager[leader]].NBU += amount;
        }

        if(token == address(GNBU)) {
            leaderTotalStakingAmount[leader].GNBU += amount;
            managerTotalStakingAmount[userManager[leader]].GNBU += amount;
        }
    }

    

}