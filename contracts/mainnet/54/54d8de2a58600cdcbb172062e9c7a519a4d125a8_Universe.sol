// SPDX-License-Identifier: MIT
//values = [100, 100, 100, 100, 100, 100, 100];
//stakedTokens = ["0x34b035b7e7f9cb6f4083672f2d9f679217774fd6", "0x34b035b7e7f9cb6f4083672f2d9f679217774fd6", "0x34b035b7e7f9cb6f4083672f2d9f679217774fd6", "0x34b035b7e7f9cb6f4083672f2d9f679217774fd6", "0x34b035b7e7f9cb6f4083672f2d9f679217774fd6", "0x34b035b7e7f9cb6f4083672f2d9f679217774fd6", "0x34b035b7e7f9cb6f4083672f2d9f679217774fd6"];
pragma solidity >=0.4.0 <=0.8.0;

// import "./Oracle_Wrapper.sol";
// Oracle_Wrapper_address = 0xB87c7158Cd83FC8f3300802AD9602B5569819f9a;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface Token {
    function transferOwnership(address newOwner) external;
    function stop() external;
    function start() external;
    function close() external;
    function decimals() external view returns(uint256);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    // function transfer(address to, uint256 value) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function mint( address to, uint256 value ) external returns (bool);
    function increaseApproval(address spender, uint addedValue) external returns (bool);
    function decreaseApproval(address spender, uint subtractedValue) external returns (bool);
    function burn(uint256 _value) external;
    function burnTokens(address who,uint256 _value) external;
}

//change the name to universe
contract Universe {
    using SafeMath for uint;
    address public owner;
    Token token;
    // OracleWrapper oracle;
    
    struct UserDetail {
        uint256 id;
        address referrer;
        uint256 etherReceived;
        address[] rewardTokenAddresses;
        mapping (uint8 => LevelDetail) levels;
        mapping (address => uint256) tokenRewards;
    }
    
    struct LevelDetail {
        uint256 income;
        uint256 levelReferrals;
        mapping (address => bool) isReferral;
        bool activeStatus;
    }
    
    struct StakingTokenDetail {
        address tokenAddress;
        uint256 amountToStake;
    }
    
    struct RewardTokenDetail {
        uint256 currentBalance;
        uint256 lastBalance;
    }
    
    uint256 currentUserId;
    uint8 public Last_Level;
    uint8 taxPercentage;//check the uint type for this
    uint8 commission;
    uint8[] levelRate;
    uint256 missedEthers;
    address[] missedTokenAddresses;
    mapping (address => uint256) missedTokenRewards;
    address public taxTokenAddress;
    address public oracleWrapperAddress;
    mapping (address => UserDetail) public users;
    mapping (uint256 => address) public userIds;
    mapping (uint8 => StakingTokenDetail) public stakedTokens;
    mapping (address => RewardTokenDetail) public rewardTokens;
    
    event Registration(address indexed userAddress, address indexed referrerAddress, uint256 userId, uint256 referrerId);
    event LevelActivated(address indexed userAddress, uint8 level, address indexed tokenStaked, uint256 amount);
    event TokenUnstaked(address indexed userAddress, uint8 level, address indexed tokenUnstaked, uint256 amount);
    event LevelIncome(address indexed _from, address indexed receiver, uint8 level, uint256 amount, uint256 levelReferralCount);
    event IncomeWithdrawn(address indexed receiver, address indexed tokenAddress, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner has the access");
        _;
    }
    
    constructor(address ownerAddress) public {
        owner = ownerAddress;
        commission = 10;
        Last_Level = 7;
        // oracle = OracleWrapper(oracleWrapperAddress);
        currentUserId++;
        levelRate = [30, 20, 10, 10, 10, 10, 10];
        
        UserDetail memory user = UserDetail({
           id: currentUserId,
           referrer: address(0),
           etherReceived: uint256(0),
           rewardTokenAddresses: new address[](0)
        });
        
        users[owner] = user;
        userIds[currentUserId] = owner;
        for (uint8 i=1; i<=Last_Level; i++) {
            users[owner].levels[i].activeStatus = true;
        }
        currentUserId++;
        
    }
    
    receive() external payable {
        if(msg.data.length == 0) {
            if (isUserExists(tx.origin)) {
                levelIncome(tx.origin, users[tx.origin].referrer, address(0), msg.value, true);
            } else {
                missedEthers = missedEthers.add(msg.value);
            }
        }
    }
    
    function registration(address referrerAddress) external {
        UserDetail memory user = UserDetail({
           id: currentUserId,
           referrer: referrerAddress,
           etherReceived: uint256(0),
           rewardTokenAddresses: new address[](0)
        });
        
        users[msg.sender] = user;
        userIds[currentUserId] = msg.sender;
        currentUserId++;
        emit Registration(msg.sender, referrerAddress, users[msg.sender].id, users[referrerAddress].id);
    }
    
    function activateLevelByStaking(uint8 level) external {
        activateLevel(msg.sender, level);
    }
    
    function activateLevel(address userAddress, uint8 level) private {
        //add isUserExists check
        require(!users[userAddress].levels[level].activeStatus, "Level Already activated");
        require(level == 1 || users[userAddress].levels[level-1].activeStatus, "Please activate immediate higher level");
        address tokenAddress = stakedTokens[level].tokenAddress;
        uint256 amount = stakedTokens[level].amountToStake;
        
        Token(tokenAddress).transferFrom(userAddress, address(this), amount);
        rewardTokens[tokenAddress].lastBalance = rewardTokens[tokenAddress].lastBalance.add(amount); 
        users[userAddress].levels[level].activeStatus = true;
        
        emit LevelActivated(userAddress, level, tokenAddress, amount);
    }
    
    function unstakeToken(uint8 level) public returns (bool) {
        require(users[msg.sender].levels[level].activeStatus, "Level Not active yet");
        address tokenAddress = stakedTokens[level].tokenAddress;
        uint256 amount = stakedTokens[level].amountToStake;
        
        Token(tokenAddress).transfer(msg.sender, amount);
        rewardTokens[tokenAddress].lastBalance = rewardTokens[tokenAddress].lastBalance.sub(amount);
        users[msg.sender].levels[level].activeStatus = false;
        emit TokenUnstaked(msg.sender, level, tokenAddress, amount);
        return true;
    }
    
    /**
    * who will send the poolRewards to the contract, user or any 
    * admin
    */
    function poolRewards(address[] memory tokenAddressSuper, uint256[] memory totalAmount, address[] memory _from, address[] memory tokenAddress, uint256[] memory amount) external onlyOwner {
        for (uint256 i=0; i<tokenAddressSuper.length; i++) {
            require(totalAmount[i] >= Token(tokenAddressSuper[i]).balanceOf(address(this)).sub(rewardTokens[tokenAddressSuper[i]].lastBalance), "Wrong Balance info");
            rewardTokens[tokenAddressSuper[i]].lastBalance = rewardTokens[tokenAddressSuper[i]].lastBalance.add(totalAmount[i]);
            // oracle.addTypeOneMapping(tokenAddressSuper[i], chainlinkAddress[i]);
        }
        
        //update the last balance whenever user withdraws
        for (uint256 j=0; j<_from.length; j++) {
            if (isUserExists(_from[j])) {
                levelIncome(_from[j], users[_from[j]].referrer, tokenAddress[j], amount[j], false);
            } else {
                missedTokenRewards[tokenAddress[j]] = missedTokenRewards[tokenAddress[j]].add(amount[j]);
                missedTokenAddresses.push(tokenAddress[j]);
            }
        }
    }
    
    function levelIncome(address _from, address receiver, address tokenAddress, uint256 amount, bool isEther) private {
        for (uint8 i=0; i<Last_Level; i++) {
            uint256 income = (amount.mul(levelRate[i])).div(100);
            address eligibleReferrer = getEligibleReferrer(receiver, i+1);
            if (!isEther) {
                users[eligibleReferrer].tokenRewards[tokenAddress] = users[eligibleReferrer].tokenRewards[tokenAddress].add(income);
                users[eligibleReferrer].rewardTokenAddresses.push(tokenAddress);
            } else {
                users[eligibleReferrer].etherReceived = users[eligibleReferrer].etherReceived.add(income);
            }
            
            if (!users[eligibleReferrer].levels[i+1].isReferral[eligibleReferrer]) {
                users[eligibleReferrer].levels[i+1].isReferral[eligibleReferrer] = true;
                users[eligibleReferrer].levels[i+1].levelReferrals++;
            }
            
            emit LevelIncome(_from, receiver, i+1, income, users[eligibleReferrer].levels[i+1].levelReferrals);
            receiver = users[eligibleReferrer].referrer;
        }
    }
    
    function withdrawIncome() external {
        uint256 rewards;
        address rewardTokenAddress;
        uint256 size = users[msg.sender].rewardTokenAddresses.length;
        for (uint8 i=0; i<size; i++) {
            rewardTokenAddress = users[msg.sender].rewardTokenAddresses[i];
            rewards = users[msg.sender].tokenRewards[rewardTokenAddress];
            Token(rewardTokenAddress).transfer(msg.sender, rewards);
            emit IncomeWithdrawn(msg.sender, rewardTokenAddress, rewards);
            rewardTokens[rewardTokenAddress].lastBalance = rewardTokens[rewardTokenAddress].lastBalance.sub(rewards);
            users[msg.sender].tokenRewards[rewardTokenAddress] = users[msg.sender].tokenRewards[rewardTokenAddress].sub(rewards);
        }
        
        users[msg.sender].rewardTokenAddresses = new address[](0);
        
        uint256 etherRewards = users[msg.sender].etherReceived;
        if(etherRewards > address(this).balance) {
            etherRewards = address(this).balance;
        }
        
        address(uint160(msg.sender)).transfer(etherRewards);
        users[msg.sender].etherReceived = users[msg.sender].etherReceived.sub(etherRewards);
    }
    
    // function calculateTax(address userAddress) private {
        
    // }
    
    function checkLevelEligibility(address userAddress, uint8 level) private view returns (bool) {
        while (level != 0) {
            if (!users[userAddress].levels[level].activeStatus) {
                return false;
            }
            
            level--;
        }
        
        return true;
    }
    
    function getEligibleReferrer(address userAddress, uint8 level) private view returns(address) {
        while (userAddress != address(0)) {
            if (checkLevelEligibility(userAddress, level)) {
                return userAddress;
            }
            
            userAddress = users[userAddress].referrer;
        }
        
        return owner;
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }
    
    function getStakingTokenDetail(uint8 level) public view returns (address, uint256, uint256) {
        return (
            stakedTokens[level].tokenAddress,
            stakedTokens[level].amountToStake,
            Token(stakedTokens[level].tokenAddress).balanceOf(address(this))
            );
    }
    
    function getUserDetail(address userAddress, address tokenAddress) public view returns (uint256, address[] memory, uint256) {
        return (
            users[userAddress].etherReceived,
            users[userAddress].rewardTokenAddresses,
            users[userAddress].tokenRewards[tokenAddress]
            );
    }
    
    function addStakingToken(address[] memory tokenAddress, uint256[] memory amount) public onlyOwner {
        for (uint8 i=0; i<tokenAddress.length; i++) {//change this to 7
            token = Token(tokenAddress[i]);
            stakedTokens[i+1].tokenAddress = tokenAddress[i];
            stakedTokens[i+1].amountToStake = amount[i].mul(10**(token.decimals()));
        }
    }
    
    function changeStakingToken(address tokenAddress, uint8 level) public onlyOwner {
        stakedTokens[level].tokenAddress = tokenAddress;
        // oracle.addTypeOneMapping(tokenAddress, chainlinkAddress);
    }
    
    function changeStakingAmount(uint256 amount, uint8 level) public onlyOwner {
        stakedTokens[level].amountToStake = amount.mul(Token(stakedTokens[level].tokenAddress).decimals());
    }
    
    function updateTaxToken(address tokenAddress) public onlyOwner {
        taxTokenAddress = tokenAddress;
        // oracle.addTypeOneMapping(tokenAddress, chainlinkAddress);
    }
    
    function updateCommission(uint8 newCommission) public onlyOwner {
        commission = newCommission;
    }
    
    function updateTaxPercentage(uint8 percentage) public onlyOwner {
        taxPercentage = percentage;
    }
    
    function updateOracleWrapperAddress(address newAddress) public onlyOwner {
        oracleWrapperAddress = newAddress;
    }
    
    function withdrawMissedRewards() public onlyOwner {
        if (missedEthers > address(this).balance) {
            missedEthers = address(this).balance;
        }
        
        address(uint160(owner)).transfer(missedEthers);
        missedEthers = 0;
        for (uint256 i=0; i<missedTokenAddresses.length; i++) {
            Token(missedTokenAddresses[i]).transfer(owner, missedTokenRewards[missedTokenAddresses[i]]);
            missedTokenRewards[missedTokenAddresses[i]] = 0;
        }
        
        missedTokenAddresses = new address[](0);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}