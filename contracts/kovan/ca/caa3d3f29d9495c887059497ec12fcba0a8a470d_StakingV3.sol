/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// File: contracts/IBEP20.sol

pragma solidity >=0.5.0;

interface IBEP20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function mint(address to, uint256 value) external returns (bool) ;
}

// File: contracts/SafeMath.sol

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity >=0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts/StakingV3.sol

pragma solidity ^ 0.5.3;



contract StakingV3 {
    using SafeMath
    for uint256;
    struct Stakes {
        uint256 stakedAmount;
        uint256 blockNumber;
        uint256 totalStakes;
        address user;
        uint256 _id;
        uint256 emissionRate;
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
        uint256 emissionRate;
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
    uint256 public tokenPerBlocks;
    uint256[] public monthlyStakePercentage;
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
    bool private isInitialized;
    bool private isPause;

    struct Emission {
        uint256 aliaShare;
        uint256 lpShare;
        uint256 tokenPerBlocks;
        uint256 blockNumber;
        uint256 totalStakes;
        uint256 totalFarms;
    }

    mapping(uint256 => Emission) public _emission;
    uint256 private emissionId;

    uint256 public aliaShare;
    uint256 public lpShare;
    bool private isInitialized2;

    function init() public {
        require(!isInitialized, "already initialized");
        isInitialized = true;
        _owner = msg.sender;
        require(msg.sender == _owner, "Not authorized to use this function");
        totalUsers = 0;
        totalStakes = 0;
        decimals = 1000000000000000000;
        nonce = 0;
        months = 27;
        tokenPerBlocks = 5000000000000000000;
        monthlyStakePercentage = [tokenPerBlocks];
        totalfarmers = 0;
        totalFarms = 0;
        initialBlockNumber = 5902715;
        alia = IBEP20(0xa24576B0E579d7e08E284f82a49CccCAdbdEe793);
        lp = IBEP20(0xDA8cc99483011ab1dB3e8a131c49753e9390519A);
        bonus = 0xb1a916DD35C9bB0839EaC2b03231D8348c43025D;
        initialDeployTime = 1616414400;
        developerAddress = 0x1F4dAC9aA704EB455bfcfAb5fd1cBB64c85D4765;
        marketing = [0x38977C56AFb71AfC3231f2A69800A17E9B7c8eF0, 0xC558EdCd2CCC8c7A521658d69fEaf64a0FaE54A2, 0x65c6A0Fa6A1109b171E90B4D00A25D13F753a0ac, 0xf079598a8b2890F61f942e368a9cF7b2d3A0a63e, 0x07d0945541D7Ed5eCa2C070B267e25281E528D4c, 0xbD412B529Cb4C4DECcC6eb5b5dcC70E878f8Cdd8];
        partners = [0xe45509c949f0f08eBEe6C15047430a831af4012D, 0x04075565618450111553fff5767c654100E61e52, 0x1467443B1C60bcA168c381e0Ba11a25ac71ca6dA, 0x63b262b1f1bc99Db421713649a2A83DB073fE9B1, 0x605445fa5EC79105E7d2C1E234220407b10E2411, 0x812fF99d8e8690732261c36d5ED5DB2DF114a147];
        aliaShare = 15;
        lpShare = 50;
        emissionId++;
        _emission[emissionId] = Emission(aliaShare, lpShare, tokenPerBlocks, block.number, totalStakes, totalFarms);        
    }

    function init2() public {
        require(!isInitialized2, "already initialized");
        isInitialized2 = true;
        aliaShare = 15;
        lpShare = 50;
        emissionId++;
        _emission[emissionId] = Emission(aliaShare, lpShare, tokenPerBlocks, block.number, totalStakes, totalFarms);
    }

    modifier isPaused() {        
        require(!isPause, "already Paused");
        _;
    }

    function pauseContract(bool _pause) public {
        require(msg.sender == 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859, "Not authorized to use this function");
        isPause = _pause;
    }

    function updateStaking(uint256 from, uint256 to) public {
        require(msg.sender == 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859, "Not authorized to use this function");
        for (uint256 i = from; i < to; i++) {
            stakeRecords[userInfo[i].user].emissionRate = 1;
        }
    }

    function updateFarming(uint256 from, uint256 to) public {
        require(msg.sender == 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859, "Not authorized to use this function");
        for (uint256 i = from; i < to; i++) {
            farmRecords[farmerInfo[i].farmer].emissionRate = 1;
        }
    }

    function changeShare(uint256 lpAmount, uint256 aliaAmount) public {
        require(msg.sender == 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859, "Not authorized to use this function");
        require(lpAmount > 0 && aliaAmount > 0, "Amount can not be 0");
        require(SafeMath.add(lpAmount, aliaAmount) <= 65, "Can not be greater than 65");
        lpShare = lpAmount;
        aliaShare = aliaAmount;
        emissionId++;
        _emission[emissionId] = Emission(aliaShare, lpShare, tokenPerBlocks, block.number, totalStakes, totalFarms);
    }

    function blockReward(uint256 _reward) public {
        require(msg.sender == 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859, "Not authorized to use this function");
        tokenPerBlocks = _reward;
        emissionId++;
        _emission[emissionId] = Emission(aliaShare, lpShare, tokenPerBlocks, block.number, totalStakes, totalFarms);
    }

    function changeOwnership(address newOwner) public {
        require(msg.sender == _owner, "Not authorized to use this function");
        _owner = newOwner;
    }

    function createStake(uint256 amount) public isPaused {
        require(amount > 0, "Create Stake");
        if (stakeRecords[msg.sender].blockNumber > 0) stakeRewards[msg.sender] = SafeMath.add(stakeRewards[msg.sender], calculateReward(msg.sender));
        totalStakes = SafeMath.add(totalStakes, amount);
        stakeRecords[msg.sender] = Stakes(SafeMath.add(stakeRecords[msg.sender].stakedAmount, amount), block.number, 0, msg.sender, 0, emissionId);
        alia.transferFrom(msg.sender, address(this), amount);
    }

    function unStake(uint256 _amount) public isPaused {
        uint256 stakeAmount = stakeRecords[msg.sender].stakedAmount;
        require(_amount > 0 && _amount <= stakeAmount, "Unstake");
        stakeRewards[msg.sender] = SafeMath.add(stakeRewards[msg.sender], calculateReward(msg.sender));
        if (stakeAmount == _amount) {
            alia.mint(msg.sender, stakeRewards[msg.sender]);
            stakeRewards[msg.sender] = 0;
            delete stakeRecords[msg.sender];
        } else {
            stakeAmount = SafeMath.sub(stakeAmount, _amount);
            stakeRecords[msg.sender].stakedAmount = stakeAmount;
            stakeRecords[msg.sender].blockNumber = block.number;
            stakeRecords[msg.sender].emissionRate = emissionId;
        }
        totalStakes = SafeMath.sub(totalStakes, _amount);
        alia.transfer(msg.sender, _amount);
    }

    function compound() public isPaused {
        stakeRewards[msg.sender] = SafeMath.add(stakeRewards[msg.sender], calculateReward(msg.sender));
        alia.mint(address(this), stakeRewards[msg.sender]);
        helperCompound(stakeRewards[msg.sender]);
        stakeRewards[msg.sender] = 0;
    }

    function helperCompound(uint256 amount) private {
        require(amount > 0, "Amount is equal to 0");
        stakeRecords[msg.sender].stakedAmount = SafeMath.add(stakeRecords[msg.sender].stakedAmount, amount);
        stakeRecords[msg.sender].blockNumber = block.number;
        stakeRecords[msg.sender].emissionRate = emissionId;
        totalStakes = SafeMath.add(totalStakes, amount);
    }

    function harvest() public isPaused {
        stakeRewards[msg.sender] = SafeMath.add(stakeRewards[msg.sender], calculateReward(msg.sender));
        require(stakeRewards[msg.sender] > 0, "Harvest");
        alia.mint(msg.sender, stakeRewards[msg.sender]);
        stakeRewards[msg.sender] = 0;
        stakeRecords[msg.sender].blockNumber = block.number;
        stakeRecords[msg.sender].emissionRate = emissionId;
    }

    function calculateReward(address _stakeHolder) public view returns(uint256) {
        if (stakeRecords[_stakeHolder].stakedAmount == 0) return stakeRewards[_stakeHolder];
        uint256 poolShare;
        uint256 blocks;
        uint256 finalReward;
        uint256 emissionRate;
        uint256 userStakedAmount = stakeRecords[_stakeHolder].stakedAmount;
        for (uint256 i = stakeRecords[_stakeHolder].emissionRate; i <= emissionId; i++) {
            if (_emission[i + 1].blockNumber > 0 ) {
                if(stakeRecords[_stakeHolder].emissionRate == (i -1)) {
                    blocks = SafeMath.sub(_emission[i + 1].blockNumber, _emission[i].blockNumber);
                } else {
                    blocks = SafeMath.sub(_emission[i + 1].blockNumber, stakeRecords[_stakeHolder].blockNumber);
                }
                poolShare = SafeMath.div(SafeMath.mul(userStakedAmount, 100000000000000000000), _emission[i + 1].totalStakes);
            } else {
                if(stakeRecords[_stakeHolder].emissionRate < i) blocks = SafeMath.sub(block.number, _emission[i].blockNumber);
                else blocks = SafeMath.sub(block.number, stakeRecords[_stakeHolder].blockNumber);
                poolShare = SafeMath.div(SafeMath.mul(userStakedAmount, 100000000000000000000), totalStakes);
            }
            emissionRate = SafeMath.mul(_emission[i].tokenPerBlocks, _emission[i].aliaShare);
            finalReward = SafeMath.add(finalReward, SafeMath.mul(SafeMath.mul(blocks, poolShare), emissionRate));
        }
        return SafeMath.div(finalReward, 10000000000000000000000);
    }

    function createfarm(uint256 amount) public isPaused {
        require(amount > 0, "Invalid Amount");
        if (farmRecords[msg.sender].farmBlockNumber > 0) farmRewards[msg.sender] = SafeMath.add(farmRewards[msg.sender], calculateRewardLP(msg.sender));
        totalFarms = SafeMath.add(totalFarms, amount);
        farmRecords[msg.sender].farmedAmount = SafeMath.add(farmRecords[msg.sender].farmedAmount, amount);
        farmRecords[msg.sender].farmBlockNumber = block.number;
        farmRecords[msg.sender].emissionRate = emissionId;
        lp.transferFrom(msg.sender, address(this), amount);
    }

    function unFarm(uint256 _amount) public isPaused {
        uint256 farmAmount = farmRecords[msg.sender].farmedAmount;
        require(_amount > 0 && _amount <= farmAmount, "Invalid Unstake Amount");
        farmRewards[msg.sender] = SafeMath.add(farmRewards[msg.sender], calculateRewardLP(msg.sender));
        if (farmAmount == _amount) {
            alia.mint(msg.sender, farmRewards[msg.sender]);
            farmRewards[msg.sender] = 0;
            delete farmRecords[msg.sender];
        } else {
            farmAmount = SafeMath.sub(farmAmount, _amount);
            farmRecords[msg.sender].farmedAmount = farmAmount;
            farmRecords[msg.sender].farmBlockNumber = block.number;
            farmRecords[msg.sender].emissionRate = emissionId;
        }
        totalFarms = SafeMath.sub(totalFarms, _amount);
        lp.transfer(msg.sender, _amount);
    }

    function compoundLP() public isPaused {
        farmRewards[msg.sender] = SafeMath.add(farmRewards[msg.sender], calculateRewardLP(msg.sender));
        stakeRewards[msg.sender] = SafeMath.add(stakeRewards[msg.sender], calculateReward(msg.sender));
        require(farmRewards[msg.sender] > 0, "Can not compound with 0");
        alia.mint(address(this), farmRewards[msg.sender]);
        helperCompound(farmRewards[msg.sender]);
        farmRewards[msg.sender] = 0;
        farmRecords[msg.sender].farmBlockNumber = block.number;
        farmRecords[msg.sender].emissionRate = emissionId;
    }

    function harvestLP() public isPaused {
        farmRewards[msg.sender] = SafeMath.add(farmRewards[msg.sender], calculateRewardLP(msg.sender));
        require(farmRewards[msg.sender] > 0, "Invalid Amount");
        alia.mint(msg.sender, farmRewards[msg.sender]);
        farmRewards[msg.sender] = 0;
        farmRecords[msg.sender].farmBlockNumber = block.number;
        farmRecords[msg.sender].emissionRate = emissionId;
    }

    function calculateRewardLP(address _farmHolder) public view returns(uint256) {
        if (farmRecords[_farmHolder].farmedAmount == 0) return farmRewards[_farmHolder];
        uint256 poolShare;
        uint256 blocks;
        uint256 finalReward;
        uint256 emissionRate;
        uint256 farmedAmount = farmRecords[_farmHolder].farmedAmount;

        for (uint256 i = farmRecords[_farmHolder].emissionRate; i <= emissionId; i++) {
            if (_emission[i + 1].blockNumber > 0) {
                if(farmRecords[_farmHolder].emissionRate == (i -1)) {
                    blocks = SafeMath.sub(_emission[i + 1].blockNumber, _emission[i].blockNumber);
                } else {
                    blocks = SafeMath.sub(_emission[i + 1].blockNumber, farmRecords[_farmHolder].farmBlockNumber);
                }
                poolShare = SafeMath.div(SafeMath.mul(farmedAmount, 100000000000000000000), _emission[i + 1].totalFarms);
            } else {
                if(farmRecords[_farmHolder].emissionRate < i) blocks = SafeMath.sub(block.number, _emission[i].blockNumber);
                else blocks = SafeMath.sub(block.number, farmRecords[_farmHolder].farmBlockNumber);
                poolShare = SafeMath.div(SafeMath.mul(farmedAmount, 100000000000000000000), totalFarms);
            }
            emissionRate = SafeMath.mul(_emission[i].tokenPerBlocks, _emission[i].lpShare);
            finalReward = SafeMath.add(finalReward, SafeMath.mul(SafeMath.mul(blocks, poolShare), emissionRate));
        }
        return SafeMath.div(finalReward, 10000000000000000000000);
    }

    function aliaShareDistribution(address _dev, address _bonus, address[] memory _marketing, address[] memory _partners) public {
        require(msg.sender == 0x0F5Dd80B2306183aDD70eDb00F53D4658C17e0b4, "Not authorized to use this function");
        if (totalBlocks == 0) totalBlocks = block.number - initialBlockNumber;
        else totalBlocks = block.number - lastBlockNum;
        lastBlockNum = block.number;
        alia.mint(_dev, SafeMath.div(SafeMath.mul(SafeMath.mul(tokenPerBlocks, 10), totalBlocks), 100));
        alia.mint(_bonus, SafeMath.div(SafeMath.mul(SafeMath.mul(tokenPerBlocks, 5), totalBlocks), 100));
        for (uint256 i = 0; i < _marketing.length; i++) alia.mint(_marketing[i], SafeMath.div(SafeMath.div(SafeMath.mul(SafeMath.mul(tokenPerBlocks, 10), totalBlocks), _marketing.length), 100));
        for (uint256 j = 0; j < _partners.length; j++) alia.mint(_partners[j], SafeMath.div(SafeMath.div(SafeMath.mul(SafeMath.mul(tokenPerBlocks, 10), totalBlocks), _partners.length), 100));
    }
}