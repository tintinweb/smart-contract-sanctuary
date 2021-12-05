pragma solidity ^0.5.16;

import "./Naut.sol";

contract Nautstaking {
    using SafeMath for uint256;

    Astronaut public nautToken;
    address public owner;
    
    bool ido=false;

    mapping(address => bool) public isStaking;
    address[] public whitelistedUsers;
    
    struct StakeUsersInfo {
        uint256 amount;
        uint8 tier;
    }

    uint256 public Tier1 = 100 * 10**18;
    uint256 public Tier2 = 250 * 10**18;
    uint256 public Tier3 = 600 * 10**18;
    uint256 public Tier4 = 1500 * 10**18;

    uint256 private Tier1Users = 0;
    uint256 private Tier2Users = 0;
    uint256 private Tier3Users = 0;
    uint256 private Tier4Users = 0;

    mapping(address => StakeUsersInfo) staker;

    bool public isstakingLive = false;
    bool public ICOover = false;

    address[] public stakers;

    constructor(Astronaut _address) public {
        nautToken = Astronaut(_address);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwnership(address _newowner) external onlyOwner {
        require(msg.sender != _newowner);
        owner = _newowner;
    }

    modifier stoppedInEmergency() {
        require(isstakingLive);
        _;
    }

    modifier onlyWhenStopped() {
        require(!isstakingLive);
        _;
    }

    /** @dev Stop Staking
     */
    function stopStaking() public onlyOwner stoppedInEmergency {
        isstakingLive = false;
    }

    /** @dev Start Staking
     */
    function startStaking() public onlyOwner onlyWhenStopped {
        require(ido==false, "IDO over");
        isstakingLive = true;
    }

    /** @dev Start UnStaking
     */
    function StartUnstaking() public onlyOwner {
        require(isstakingLive == false , "Staking is live");
        ICOover = true;
        ido = true;
    }

    /** @dev Stop UnStaking
     */
    function StopUnstaking() public onlyOwner onlyWhenICOover {
        ICOover = false;
    }

    modifier onlyWhenICOover() {
        require(ICOover);
        _;
    }


    // invest function
    function stakeTokens(uint256 _amount) public stoppedInEmergency {

        // staking amount must be equal to below packages
        require(
            _amount == Tier1 ||
                _amount == Tier2 ||
                _amount == Tier3 ||
                _amount == Tier4,
            "Select Appropriate Tier"
        );

        require(isStaking[msg.sender] == false, "Already Staked");

        // Transfer staking tokens to staking Contract
        nautToken.transferFrom(msg.sender, address(this), _amount);

        // Add user To staking Data structure
        StakeUsersInfo storage stakeStorage = staker[msg.sender];

        if (_amount == Tier1) {
            stakeStorage.tier = 1;
            stakeStorage.amount = _amount;
            Tier1Users = Tier1Users + 1;
        } else if (_amount == Tier2) {
            stakeStorage.tier = 2;
            stakeStorage.amount = _amount;
            Tier2Users = Tier2Users + 1;
        } else if (_amount == Tier3) {
            stakeStorage.tier = 3;
            stakeStorage.amount = _amount;
            Tier3Users = Tier3Users + 1;
        } else {
            stakeStorage.tier = 4;
            stakeStorage.amount = _amount;
            Tier4Users = Tier4Users + 1;
        }

        stakers.push(msg.sender);
        isStaking[msg.sender] = true;
    }

    // allow user to withdraw their token
    function unStakeTokens() public onlyWhenICOover {
        require(isStaking[msg.sender] == true, "No previous deposit");

        uint256 balance = staker[msg.sender].amount;

        nautToken.transfer(msg.sender, balance);

        uint256 tier = staker[msg.sender].tier;

        if (tier == 1) {
            Tier1Users = Tier1Users - 1;
        } else if (tier == 2) {
            Tier2Users = Tier2Users - 1;
        } else if (tier == 3) {
            Tier3Users = Tier3Users - 1;
        } else if (tier == 4) {
            Tier4Users = Tier4Users - 1;
        }

        isStaking[msg.sender] = false;
        staker[msg.sender].amount = 0;
        staker[msg.sender].tier = 0;
        // stakers.pop(msg.sender);
    }

    function whitelist(address[] calldata _users, uint8[] calldata _tiers) external onlyOwner {
        
        uint userlength = _users.length;
        uint tierlength = _tiers.length;
        require(userlength == tierlength, "Incorrect params");
        
        for (uint i =0; i < userlength; i++) {
            
        StakeUsersInfo storage stakeStorage = staker[_users[i]];

        require(staker[_users[i]].tier == 0, "Already whitelisted");
        stakeStorage.tier = _tiers[i];
        whitelistedUsers.push(_users[i]);
    
        if (_tiers[i] == 1) {
            Tier1Users = Tier1Users + 1;
        } else if (_tiers[i] == 2) {
            Tier2Users = Tier2Users + 1;
        } else if (_tiers[i] == 3) {
            Tier3Users = Tier3Users + 1;
        } else if (_tiers[i] == 4) {
            Tier4Users = Tier4Users + 1;
        }
        else {
            revert();
        }
      }
    }

    // function blacklist(address _user) public onlyOwner {
    //     StakeUsersInfo storage stakeStorage = staker[_user];

    //     require(staker[_user].tier != 0, "Already blacklisted");

    //     uint8 tier = stakeStorage.tier;

    //     stakeStorage.tier = 0;

    //     if (tier == 1) {
    //         Tier1Users = Tier1Users - 1;
    //     } else if (tier == 2) {
    //         Tier2Users = Tier2Users - 1;
    //     } else if (tier == 3) {
    //         Tier3Users = Tier3Users - 1;
    //     } else if (tier == 4) {
    //         Tier4Users = Tier4Users - 1;
    //     }
    // }

    // Total no of Stakers
    function countStakers() public view returns (uint256) {
        return stakers.length;
    }
    
    
    // Total no of whitelistedUsers
    function countWhitelistedUsers() public view returns (uint256) {
        return whitelistedUsers.length;
    }
    
    // get Staker info
    function getStaker(address _address)
        public
        view
        returns (uint256 amount, uint8 tier)
    {
        return (staker[_address].amount, staker[_address].tier);
    }

    // check Balance
    function checkBalance(address _owner)
        public
        view
        returns (uint256 balance)
    {
        return nautToken.balanceOf(_owner);
    }

    // get Tier
    function getStakerTier(address _address) public view returns (uint8 tier) {
        return (staker[_address].tier);
    }

    // Total naut tokens in Contract Wallet
    function checkContractBalance() public view returns (uint256 balance) {
        return nautToken.balanceOf(address(this));
    }

    function tier1user() public view returns (uint256) {
        return Tier1Users;
    }

    function tier2user() public view returns (uint256) {
        return Tier2Users;
    }

    function tier3user() public view returns (uint256) {
        return Tier3Users;
    }

    function tier4user() public view returns (uint256) {
        return Tier4Users;
    }

    // allow Owner to Withdraw Dead Tokens from Smart Contract Wallet when Unstaking is complete
    function withdrawlAdmin(uint256 _amount, address _admin) public onlyOwner {
        uint256 withdrawlAmmount = _amount;
        nautToken.transfer(_admin, withdrawlAmmount);
    }


    function resetContract() public onlyOwner {
        
        require(checkContractBalance() ==0, "Contract not empty");
        
        address[] memory totalstakers = stakers;
        
        for (uint256 i = 0; i < totalstakers.length; i++) {
            if (isStaking[totalstakers[i]] == true) {
                 isStaking[totalstakers[i]] = false;
                 staker[totalstakers[i]].amount = 0;
                 staker[totalstakers[i]].tier = 0;
            }
        }
        
        address[] memory totalwhitelistedUsers = whitelistedUsers;
        
         for (uint256 i = 0; i < totalwhitelistedUsers.length; i++) {
                 staker[totalwhitelistedUsers[i]].tier = 0;
            }

        // stakingStart = 0;
        // stakingStop = 0;
        ICOover = false;
        ido=false;
        Tier1Users = 0;
        Tier2Users = 0;
        Tier3Users = 0;
        Tier4Users = 0;
        isstakingLive = false;

        delete stakers;
        delete whitelistedUsers;
    }


    function setTier(uint8 _tier, uint256 _value) public onlyOwner {
        require(
            _tier == 1 || _tier == 2 || _tier == 3 || _tier == 4,
            "Select Appropriate Tier"
        );

        if (_tier == 1) {
            Tier1 = _value * (10**18);
        } else if (_tier == 2) {
            Tier2 = _value * (10**18);
        } else if (_tier == 3) {
            Tier3 = _value * (10**18);
        } else {
            Tier4 = _value * (10**18);
        }
    }

}