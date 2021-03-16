/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// File: contracts/IBEP20.sol

pragma solidity ^ 0.5.3;
interface IBEP20 {
    event Transfer(address indexed from, address indexed to, uint value);
    function balanceOf(address account) external returns(uint256);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function mint(address to, uint256 value) external returns (bool) ;
}

// File: contracts/SafeMath.sol

pragma solidity ^ 0.5.3;
library SafeMath {
    int256 constant private INT256_MIN = -2 ** 255;
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function mul(int256 a, int256 b) internal pure returns(int256) {
        if (a == 0) return 0;
        require(!(a == -1 && b == INT256_MIN));
        int256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function div(int256 a, int256 b) internal pure returns(int256) {
        require(b != 0);
        require(!(b == -1 && a == INT256_MIN));
        int256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function sub(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function add(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
}

// File: contracts/Staking.sol

pragma solidity ^ 0.5.3;


contract Staking {
    using SafeMath
    for uint256;
    struct Stakes {
        uint256 stakedAmount;
        uint256 blockNumber;
        uint256 totalStakes;
        address user;
        uint256 _id;
    }
    struct User {
        uint256 _id;
        address user;
    }
    struct Farms {
        uint256 farmedAmount;
        uint256 farmBlockNumber;
        uint256 totalFarms;
        address farmer;
        uint256 _id;
    }
    struct Farmer {
        uint256 _id;
        address farmer;
    }
    mapping(address => uint256) public farmRewards;
    mapping(uint256 => Farmer) public farmerInfo;
    mapping(address => Farms) public farmRecords;
    mapping(address => uint256) public stakeRewards;
    mapping(uint256 => User) public userInfo;
    mapping(address => Stakes) public stakeRecords;
    IBEP20 alia;
    IBEP20 lp;
    uint256 public totalStakes;
    uint256 public totalUsers;
    uint256 internal initialBlockNumber;
    uint256 internal nonce;
    uint256 internal decimals;
    uint256 internal months;
    uint256 internal tokenPerBlocks;
    uint256[] internal monthlyStakePercentage;
    address internal _owner;
    uint256 public totalfarmers;
    uint256 public totalFarms;
    uint256 internal initialDeployTime;
    uint256 private lastBlockNum;
    address private randomish;
    uint256 private totalBlocks;
    address private developerAddress;
    address private bonus;
    address[] private marketing;
    address[] private partners;

    function init() public {
        _owner = msg.sender;
        require(msg.sender == _owner,"Not authorized to use this function");
        totalUsers = 0;
        totalStakes = 0;
        decimals = 1000000000000000000;
        nonce = 0;
        months = 27;
        tokenPerBlocks = 40;
        monthlyStakePercentage = [tokenPerBlocks];
        totalfarmers = 0;
        totalFarms = 0;
        alia = IBEP20(0xe1a4af407A124777A4dB6bB461b6F256c1f8E341);
        lp = IBEP20(0x6BC5b035Ae5d38D6917368b15D4a931D77E9ae50);
        initialBlockNumber = 5808130;
        bonus = 0xb1a916DD35C9bB0839EaC2b03231D8348c43025D;
        initialDeployTime = 1616130000;
        developerAddress = 0x1F4dAC9aA704EB455bfcfAb5fd1cBB64c85D4765;
        marketing = [0x38977C56AFb71AfC3231f2A69800A17E9B7c8eF0, 0xC558EdCd2CCC8c7A521658d69fEaf64a0FaE54A2, 0x65c6A0Fa6A1109b171E90B4D00A25D13F753a0ac, 0xf079598a8b2890F61f942e368a9cF7b2d3A0a63e, 0x07d0945541D7Ed5eCa2C070B267e25281E528D4c, 0xbD412B529Cb4C4DECcC6eb5b5dcC70E878f8Cdd8];
        partners = [0xe45509c949f0f08eBEe6C15047430a831af4012D, 0x04075565618450111553fff5767c654100E61e52, 0x1467443B1C60bcA168c381e0Ba11a25ac71ca6dA, 0x63b262b1f1bc99Db421713649a2A83DB073fE9B1, 0x605445fa5EC79105E7d2C1E234220407b10E2411, 0x812fF99d8e8690732261c36d5ED5DB2DF114a147];
        _allocations();
    }

    function blockReward(uint256 _reward) public {
        require(msg.sender == _owner,"Not authorized to use this function");
        monthlyStakePercentage = [_reward];
        tokenPerBlocks = _reward;
        _allocations();
    }

    function _allocations() internal {
        uint256 value = tokenPerBlocks;
        for (uint256 i = 0; i < months; i++) {
            uint256 deduction = value;
            value = SafeMath.sub(value, SafeMath.div(value * 10, 100));
            deduction = SafeMath.sub(deduction, value);
            if (deduction < 1) deduction = 1;
            monthlyStakePercentage.push(SafeMath.sub(tokenPerBlocks, deduction));
            if (SafeMath.sub(tokenPerBlocks, value) < 1) deduction = 0;
            tokenPerBlocks = SafeMath.sub(tokenPerBlocks, deduction);
        }
    }

    function createStake(uint256 amount) public {
        require(amount > 0, "Create Stake");
        if (stakeRecords[msg.sender].blockNumber > 0) {
            stakeRewards[msg.sender] += calculateReward(msg.sender);
            randomish = address(uint160(uint(keccak256(abi.encodePacked(nonce++, blockhash(block.number))))));
            userInfo[stakeRecords[msg.sender]._id].user = randomish;
            stakeRecords[msg.sender].user = randomish;
            if (block.number < initialBlockNumber) stakeRecords[randomish] = Stakes(stakeRecords[msg.sender].stakedAmount, initialBlockNumber, stakeRecords[msg.sender].totalStakes, randomish, stakeRecords[msg.sender]._id);
            else stakeRecords[randomish] = Stakes(stakeRecords[msg.sender].stakedAmount, stakeRecords[msg.sender].blockNumber, stakeRecords[msg.sender].totalStakes, randomish, stakeRecords[msg.sender]._id);
        }
        totalStakes += amount;
        userInfo[totalUsers] = User(totalUsers, msg.sender);
        if (block.number < initialBlockNumber) stakeRecords[msg.sender] = Stakes(SafeMath.add(stakeRecords[msg.sender].stakedAmount, amount), initialBlockNumber, totalStakes, msg.sender, totalUsers);
        else stakeRecords[msg.sender] = Stakes(SafeMath.add(stakeRecords[msg.sender].stakedAmount, amount), block.number, totalStakes, msg.sender, totalUsers);
        totalUsers++;
        alia.transferFrom(msg.sender, address(this), amount);
    }

    function calculateReward(address _stakeHolder) public view returns(uint256) {
        if (stakeRecords[_stakeHolder].stakedAmount == 0 || block.number < initialBlockNumber) return stakeRewards[msg.sender];
        uint256 userCount = stakeRecords[_stakeHolder]._id;
        uint256 userStakedAmount = stakeRecords[_stakeHolder].stakedAmount;
        uint256 poolShare = 0;
        address current;
        address next;
        uint256 blocks = 0;
        uint256 finalReward = 0;
        uint256 emissionRate = 40;
        uint256 aliaPercentage = 26;
        uint256 deployTimeDifference;
        uint256 month;
        for (uint256 i = userCount; i < totalUsers; i++) {
            current = userInfo[i].user;
            if (stakeRecords[current]._id == (totalUsers - 1)) {
                blocks = SafeMath.sub(block.number, stakeRecords[current].blockNumber);
                poolShare = SafeMath.div(SafeMath.mul(userStakedAmount, 100), stakeRecords[current].totalStakes);
            } else {
                next = userInfo[i + 1].user;
                blocks = SafeMath.sub(stakeRecords[next].blockNumber, stakeRecords[current].blockNumber);
                poolShare = SafeMath.div(SafeMath.mul(userStakedAmount, 100), stakeRecords[current].totalStakes);
            }
            deployTimeDifference = SafeMath.sub(stakeRecords[current].blockNumber, initialBlockNumber);
            month = SafeMath.div(deployTimeDifference, 864000);
            emissionRate = SafeMath.mul(monthlyStakePercentage[month], aliaPercentage);
            finalReward = SafeMath.add(finalReward, SafeMath.mul(SafeMath.mul(blocks, poolShare), emissionRate));
        }
        return SafeMath.div(SafeMath.mul(finalReward, decimals), 10000);
    }

    function unStake(uint256 _amount) public {
        uint256 stakeAmount = stakeRecords[msg.sender].stakedAmount;
        require(_amount > 0 && _amount <= stakeAmount && block.number > initialBlockNumber, "Unstake");
        stakeRewards[msg.sender] = SafeMath.add(stakeRewards[msg.sender], calculateReward(msg.sender));
        if (stakeAmount == _amount) {
            alia.mint(msg.sender, stakeRewards[msg.sender]);
            alia.transfer(msg.sender, _amount);
            randomish = address(uint160(uint(keccak256(abi.encodePacked(nonce++, blockhash(block.number))))));
            userInfo[stakeRecords[msg.sender]._id].user = randomish;
            stakeRecords[msg.sender].user = randomish;
            stakeRecords[randomish] = Stakes(stakeRecords[msg.sender].stakedAmount, stakeRecords[msg.sender].blockNumber, SafeMath.sub(stakeRecords[msg.sender].totalStakes, _amount), randomish, stakeRecords[msg.sender]._id);
            stakeRewards[msg.sender] = 0;
            delete stakeRecords[msg.sender];
            address newRandomish = address(uint160(uint(keccak256(abi.encodePacked(nonce++, blockhash(block.number))))));
            userInfo[totalUsers] = User(totalUsers, newRandomish);
            totalStakes -= _amount;
            stakeRecords[newRandomish] = Stakes(0, block.number, totalStakes, newRandomish, totalUsers);
            totalUsers++;
        } else {
            if (alia.balanceOf(address(this)) >= _amount) alia.transfer(msg.sender, _amount);
            else alia.mint(msg.sender, _amount);
            stakeAmount -= _amount;
            totalStakes -= _amount;
            reStake(stakeAmount);
        }
    }

    function reStake(uint256 amount) private {
        randomish = address(uint160(uint(keccak256(abi.encodePacked(nonce++, blockhash(block.number))))));
        userInfo[stakeRecords[msg.sender]._id].user = randomish;
        stakeRecords[msg.sender].user = randomish;
        stakeRecords[randomish] = Stakes(amount, stakeRecords[msg.sender].blockNumber, stakeRecords[msg.sender].totalStakes, randomish, stakeRecords[msg.sender]._id);
        userInfo[totalUsers] = User(totalUsers, msg.sender);
        stakeRecords[msg.sender] = Stakes(amount, block.number, totalStakes, msg.sender, totalUsers);
        totalUsers++;
    }

    function compound() public {
        require(block.number > initialBlockNumber,"Compound");
        stakeRewards[msg.sender] = SafeMath.add(stakeRewards[msg.sender], calculateReward(msg.sender));
        alia.mint(address(this), stakeRewards[msg.sender]);
        helperCompound(stakeRewards[msg.sender]);
        stakeRewards[msg.sender] = 0;
    }

    function helperCompound(uint256 amount) private {
        require(amount > 0, "Amount is equal to 0");
        if (stakeRecords[msg.sender].blockNumber > 0) {
            randomish = address(uint160(uint(keccak256(abi.encodePacked(nonce++, blockhash(block.number))))));
            userInfo[stakeRecords[msg.sender]._id].user = randomish;
            stakeRecords[msg.sender].user = randomish;
            stakeRecords[randomish] = Stakes(stakeRecords[msg.sender].stakedAmount, stakeRecords[msg.sender].blockNumber, stakeRecords[msg.sender].totalStakes, randomish, stakeRecords[msg.sender]._id);
        }
        totalStakes += amount;
        userInfo[totalUsers] = User(totalUsers, msg.sender);
        stakeRecords[msg.sender] = Stakes(SafeMath.add(stakeRecords[msg.sender].stakedAmount, amount), block.number, totalStakes, msg.sender, totalUsers);
        totalUsers++;
    }

    function harvest() public {
        stakeRewards[msg.sender] = SafeMath.add(stakeRewards[msg.sender], calculateReward(msg.sender));
        require(stakeRewards[msg.sender] > 0 && block.number > initialBlockNumber, "Harvest");
        alia.mint(msg.sender, stakeRewards[msg.sender]);
        stakeRewards[msg.sender] = 0;
        randomish = address(uint160(uint(keccak256(abi.encodePacked(nonce++, blockhash(block.number))))));
        userInfo[stakeRecords[msg.sender]._id].user = randomish;
        stakeRecords[msg.sender].user = randomish;
        userInfo[totalUsers] = User(totalUsers, msg.sender);
        stakeRecords[randomish] = Stakes(stakeRecords[msg.sender].stakedAmount, stakeRecords[msg.sender].blockNumber, stakeRecords[msg.sender].totalStakes, randomish, stakeRecords[msg.sender]._id);
        stakeRecords[msg.sender] = Stakes(stakeRecords[msg.sender].stakedAmount, block.number, totalStakes, msg.sender, totalUsers);
        totalUsers++;
    }


    function createfarm(uint256 amount) public {
        require(amount > 0, "Create Farm");
        if (farmRecords[msg.sender].farmBlockNumber > 0) {
            farmRewards[msg.sender] += calculateRewardLP(msg.sender);
            randomGeneratorLP();
            if (block.number < initialBlockNumber) farmRecords[randomish] = Farms(farmRecords[msg.sender].farmedAmount, initialBlockNumber, farmRecords[msg.sender].totalFarms, randomish, farmRecords[msg.sender]._id);
            else farmRecords[randomish] = Farms(farmRecords[msg.sender].farmedAmount, farmRecords[msg.sender].farmBlockNumber, farmRecords[msg.sender].totalFarms, randomish, farmRecords[msg.sender]._id);
        }
        totalFarms += amount;
        farmerInfo[totalfarmers] = Farmer(totalfarmers, msg.sender);
        if (block.number < initialBlockNumber) farmRecords[msg.sender] = Farms(SafeMath.add(farmRecords[msg.sender].farmedAmount, amount), initialBlockNumber, totalFarms, msg.sender, totalfarmers);
        else farmRecords[msg.sender] = Farms(SafeMath.add(farmRecords[msg.sender].farmedAmount, amount), block.number, totalFarms, msg.sender, totalfarmers);
        totalfarmers++;
        lp.transferFrom(msg.sender, address(this), amount);
    }

    function calculateRewardLP(address _farmHolder) public view returns(uint256) {
        if (farmRecords[_farmHolder].farmedAmount == 0 || block.number < initialBlockNumber) return farmRewards[msg.sender];
        uint256 farmerCount = farmRecords[_farmHolder]._id;
        uint256 farmedAmount = farmRecords[_farmHolder].farmedAmount;
        uint256 poolShare = 0;
        address current;
        address next;
        uint256 blocks = 0;
        uint256 finalReward = 0;
        uint256 emissionRate = 40;
        uint256 lpPercentage = 39;
        uint256 deployTimeDifference;
        uint256 month;
        for (uint256 i = farmerCount; i < totalfarmers; i++) {
            current = farmerInfo[i].farmer;
            if (farmRecords[current]._id == (totalfarmers - 1)) {
                blocks = SafeMath.sub(block.number, farmRecords[current].farmBlockNumber);
            } else {
                next = farmerInfo[i + 1].farmer;
                blocks = SafeMath.sub(farmRecords[next].farmBlockNumber, farmRecords[current].farmBlockNumber);
            }
            deployTimeDifference = SafeMath.sub(farmRecords[current].farmBlockNumber, initialBlockNumber);
            month = SafeMath.div(deployTimeDifference, 864000);
            poolShare = SafeMath.div(SafeMath.mul(farmedAmount, 100), farmRecords[current].totalFarms);
            emissionRate = SafeMath.mul(monthlyStakePercentage[month], lpPercentage);
            finalReward = SafeMath.add(finalReward, SafeMath.mul(SafeMath.mul(blocks, poolShare), emissionRate));
        }
        return SafeMath.div(SafeMath.mul(finalReward, decimals), 10000);
    }

    function unFarm(uint256 _amount) public {
        uint256 farmAmount = farmRecords[msg.sender].farmedAmount;
        require(_amount > 0 && block.number > initialBlockNumber && _amount <= farmAmount, "Unfarm");
        farmRewards[msg.sender] = SafeMath.add(farmRewards[msg.sender], calculateRewardLP(msg.sender));
        if (farmAmount == _amount) {
            alia.mint(msg.sender, farmRewards[msg.sender]);
            randomish = address(uint160(uint(keccak256(abi.encodePacked(nonce++, blockhash(block.number))))));
            farmerInfo[farmRecords[msg.sender]._id].farmer = randomish;
            farmRecords[msg.sender].farmer = randomish;
            farmRecords[randomish] = Farms(farmRecords[msg.sender].farmedAmount, farmRecords[msg.sender].farmBlockNumber, SafeMath.sub(farmRecords[msg.sender].totalFarms, _amount), randomish, farmRecords[msg.sender]._id);
            farmRewards[msg.sender] = 0;
            delete farmRecords[msg.sender];
            address newRandomish = address(uint160(uint(keccak256(abi.encodePacked(nonce++, blockhash(block.number))))));
            farmerInfo[totalfarmers] = Farmer(totalfarmers, newRandomish);
            totalFarms -= _amount;
            farmRecords[newRandomish] = Farms(0, block.number, totalFarms, newRandomish, totalfarmers);
            totalfarmers++;
        } else {
            farmAmount -= _amount;
            totalFarms -= _amount;
            refarm(farmAmount);
        }
        lp.transfer(msg.sender, _amount);
    }

    function refarm(uint256 amount) private {
        randomGeneratorLP();
        farmRecords[randomish] = Farms(amount, farmRecords[msg.sender].farmBlockNumber, farmRecords[msg.sender].totalFarms, randomish, farmRecords[msg.sender]._id);
        farmerInfo[totalfarmers] = Farmer(totalfarmers, msg.sender);
        farmRecords[msg.sender] = Farms(amount, block.number, totalFarms, msg.sender, totalfarmers);
        totalfarmers++;
    }

    function compoundLP() public {
        require(block.number > initialBlockNumber, 'Compound LP');
        farmRewards[msg.sender] = SafeMath.add(farmRewards[msg.sender], calculateRewardLP(msg.sender));
        stakeRewards[msg.sender] = SafeMath.add(stakeRewards[msg.sender], calculateReward(msg.sender));
        alia.mint(address(this), farmRewards[msg.sender]);
        helperCompound(farmRewards[msg.sender]);
        farmRewards[msg.sender] = 0;
        refarm(farmRecords[msg.sender].farmedAmount);
    }

    function harvestLP() public {
        farmRewards[msg.sender] = SafeMath.add(farmRewards[msg.sender], calculateRewardLP(msg.sender));
        require(farmRewards[msg.sender] > 0 && block.number > initialBlockNumber, "Harvest LP");
        alia.mint(msg.sender, farmRewards[msg.sender]);
        farmRewards[msg.sender] = 0;
        randomGeneratorLP();
        farmerInfo[totalfarmers] = Farmer(totalfarmers, msg.sender);
        farmRecords[randomish] = Farms(farmRecords[msg.sender].farmedAmount, farmRecords[msg.sender].farmBlockNumber, farmRecords[msg.sender].totalFarms, randomish, farmRecords[msg.sender]._id);
        farmRecords[msg.sender] = Farms(farmRecords[msg.sender].farmedAmount, block.number, totalFarms, msg.sender, totalfarmers);
        totalfarmers++;
    }

    function randomGeneratorLP() private {
        randomish = address(uint160(uint(keccak256(abi.encodePacked(nonce++, blockhash(block.number))))));
        farmerInfo[farmRecords[msg.sender]._id].farmer = randomish;
        farmRecords[msg.sender].farmer = randomish;
    }

    function addPartner(address partner, uint256 flag) public {
        require(msg.sender == _owner,"Not authorized to use this function");
        if (flag == 1) partners.push(partner);
        else {
            for (uint256 i = 0; i < partners.length; i++) {
                if (partners[i] == partner) delete partners[i];
            }
        }
    }

    function addMarketer(address marketer, uint256 flag) public {
        require(msg.sender == _owner,"Not authorized to use this function");
        if (flag == 1) marketing.push(marketer);
        else {
            for (uint256 i = 0; i < marketing.length; i++) {
                if (marketing[i] == marketer) delete marketing[i];
            }
        }
    }

    function aliaShareDistribution() public {
        require(msg.sender == _owner,"Not authorized to use this function");
        if (totalBlocks == 0) totalBlocks = block.number - initialBlockNumber;
        else totalBlocks = block.number - lastBlockNum;
        lastBlockNum = block.number;
        if (totalBlocks == 0) totalBlocks = block.number - initialBlockNumber;
        else totalBlocks = block.number - totalBlocks;
        uint256 month = SafeMath.div(SafeMath.div(SafeMath.div(SafeMath.sub(now, initialDeployTime), 60), 1440), 30);
        alia.mint(developerAddress, SafeMath.div(SafeMath.mul(SafeMath.mul(SafeMath.mul(monthlyStakePercentage[month], 10), totalBlocks), decimals), 100));
        alia.mint(bonus, SafeMath.div(SafeMath.mul(SafeMath.mul(SafeMath.mul(monthlyStakePercentage[month], 5), totalBlocks), decimals), 100));
        for (uint256 i = 0; i < marketing.length; i++) alia.mint(marketing[i], SafeMath.div(SafeMath.div(SafeMath.mul(SafeMath.mul(SafeMath.mul(monthlyStakePercentage[month], 10), totalBlocks), decimals), marketing.length), 100));
        for (uint256 j = 0; j < partners.length; j++) alia.mint(partners[j], SafeMath.div(SafeMath.div(SafeMath.mul(SafeMath.mul(SafeMath.mul(monthlyStakePercentage[month], 10), totalBlocks), decimals), partners.length), 100));
    }
}