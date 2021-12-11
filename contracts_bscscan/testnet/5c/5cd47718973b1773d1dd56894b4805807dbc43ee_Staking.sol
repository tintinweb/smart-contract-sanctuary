/**
 *Submitted for verification at BscScan.com on 2021-12-10
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

// File: contracts/Staking.sol

pragma solidity ^ 0.5.3;



contract Staking {
    using SafeMath
    for uint256;
    struct StakesA {
        uint256 stakedAmount;
        uint256 blockNumber;
        uint256 totalStakes;
        address user;
        uint256 _id;
        uint256 emissionRate;
    }

    struct StakesB {
        uint256 stakedAmount;
        uint256 blockNumber;
        uint256 totalStakes;
        address user;
        uint256 _id;
        uint256 emissionRate;
    }

    mapping(address => uint256) public stakeRewardsA;
    mapping(address => uint256) public stakeRewardsB;
    mapping(address => StakesA) public stakeRecordsA;
    mapping(address => StakesB) public stakeRecordsB;

    IBEP20 tokenA;
    IBEP20 tokenB;
    uint256 public totalStakesA;
    uint256 public totalStakesB;
    uint256 public rewardBal;
    uint256 internal initialBlockNumber;
    uint256 internal nonce;
    uint256 internal decimals;
    uint256 internal months;
    uint256 public tokenPerBlocks;
    uint256[] public monthlyStakePercentage;
    address internal _owner;
    uint256 internal initialDeployTime;
    uint256 private lastBlockNum;
    address private randomish;
    uint256 private totalBlocks;
    bool private isInitialized;
    bool private isPause;

    struct Emission {
        uint256 tokenAShare;
        uint256 tokenBShare;
        uint256 tokenPerBlocks;
        uint256 blockNumber;
        uint256 totalStakesA;
        uint256 totalStakesB;
    }

    mapping(uint256 => Emission) public _emission;
    uint256 private emissionId;

    uint256 public tokenAShare;
    uint256 public tokenBShare;

    function init() public {
        require(!isInitialized, "already initialized");
        isInitialized = true;
        _owner = msg.sender;
        require(msg.sender == _owner, "Not authorized to use this function");
        totalStakesA = 0;
        totalStakesB = 0;
        rewardBal = 0;
        decimals = 1000000000000000000;
        nonce = 0;
        months = 27;
        tokenPerBlocks = 10000000000000000000;
        monthlyStakePercentage = [tokenPerBlocks];
        initialBlockNumber = 5902715;
        tokenA = IBEP20(0x7eFf3C96A0C8023f6a0442a2eb4985c9802e69CF);
        tokenB = IBEP20(0x73b3Aa22dE43ab17640399C7238aeEFC84B416ee);
        initialDeployTime = 1616414400;
    }   

    modifier isPaused() {        
        require(!isPause, "already Paused");
        _;
    }

    function pauseContract(bool _pause) public {
        require(msg.sender == _owner, "Not authorized to use this function");
        isPause = _pause;
    }

    function changeShare(uint256 tokenBAmount, uint256 tokenAAmount) public {
        require(msg.sender == _owner, "Not authorized to use this function");
        tokenBShare = tokenBAmount;
        tokenAShare = tokenAAmount;
        emissionId++;
        _emission[emissionId] = Emission(tokenAShare, tokenBShare, tokenPerBlocks, block.number, totalStakesA, totalStakesB);
    }

    function blockReward(uint256 _reward) public {
        require(msg.sender == _owner, "Not authorized to use this function");
        tokenPerBlocks = _reward;
        emissionId++;
        _emission[emissionId] = Emission(tokenAShare, tokenBShare, tokenPerBlocks, block.number, totalStakesA, totalStakesB);
    }

    function changeOwnership(address newOwner) public {
        require(msg.sender == _owner, "Not authorized to use this function");
        _owner = newOwner;
    }

    function addFundsForReward(uint256 _amount) public {
        require(msg.sender == _owner, "Not authorized to use this function");
        tokenA.transferFrom(msg.sender, address(this), _amount);
        rewardBal = SafeMath.add(rewardBal, _amount);
    }

    function createStakeA(uint256 amount) public isPaused {
        require(amount > 0, "Create Stake");
        if (stakeRecordsA[msg.sender].blockNumber > 0) stakeRewardsA[msg.sender] = SafeMath.add(stakeRewardsA[msg.sender], calculateRewardA(msg.sender));
        totalStakesA = SafeMath.add(totalStakesA, amount);
        stakeRecordsA[msg.sender] = StakesA(SafeMath.add(stakeRecordsA[msg.sender].stakedAmount, amount), block.number, 0, msg.sender, 0, emissionId);
        tokenA.transferFrom(msg.sender, address(this), amount);
    }

    function unStakeA(uint256 _amount) public isPaused {
        uint256 stakeAmount = stakeRecordsA[msg.sender].stakedAmount;
        require(_amount > 0 && _amount <= stakeAmount, "Unstake");
        stakeRewardsA[msg.sender] = SafeMath.add(stakeRewardsA[msg.sender], calculateRewardA(msg.sender));
        if (stakeAmount == _amount) {
            tokenA.mint(msg.sender, stakeRewardsA[msg.sender]);
            stakeRewardsA[msg.sender] = 0;
            delete stakeRecordsA[msg.sender];
        } else {
            stakeAmount = SafeMath.sub(stakeAmount, _amount);
            stakeRecordsA[msg.sender].stakedAmount = stakeAmount;
            stakeRecordsA[msg.sender].blockNumber = block.number;
            stakeRecordsA[msg.sender].emissionRate = emissionId;
        }
        totalStakesA = SafeMath.sub(totalStakesA, _amount);
        tokenA.transfer(msg.sender, _amount);
    }

    function takeRewardA() public isPaused {
        stakeRewardsA[msg.sender] = SafeMath.add(stakeRewardsA[msg.sender], calculateRewardA(msg.sender));
        require(stakeRewardsA[msg.sender] > 0, "Harvest");
        require(rewardBal >= stakeRewardsA[msg.sender], "RewardAmount less");
        tokenA.transfer(msg.sender, stakeRewardsA[msg.sender]);
        rewardBal = SafeMath.sub(rewardBal, stakeRewardsA[msg.sender]);
        stakeRewardsA[msg.sender] = 0;
        stakeRecordsA[msg.sender].blockNumber = block.number;
        stakeRecordsA[msg.sender].emissionRate = emissionId;
    }

    function calculateRewardA(address _stakeHolder) public view returns(uint256) {
        if (stakeRecordsA[_stakeHolder].stakedAmount == 0) return stakeRewardsA[_stakeHolder];
        uint256 poolShare;
        uint256 blocks;
        uint256 finalReward;
        uint256 emissionRate;
        uint256 userStakedAmount = stakeRecordsA[_stakeHolder].stakedAmount;
        for (uint256 i = stakeRecordsA[_stakeHolder].emissionRate; i <= emissionId; i++) {
            if (_emission[i + 1].blockNumber > 0 ) {
                if(stakeRecordsA[_stakeHolder].emissionRate == (i -1)) {
                    blocks = SafeMath.sub(_emission[i + 1].blockNumber, _emission[i].blockNumber);
                } else {
                    blocks = SafeMath.sub(_emission[i + 1].blockNumber, stakeRecordsA[_stakeHolder].blockNumber);
                }
                poolShare = SafeMath.div(SafeMath.mul(userStakedAmount, 100000000000000000000), _emission[i + 1].totalStakesA);
            } else {
                if(stakeRecordsA[_stakeHolder].emissionRate < i) blocks = SafeMath.sub(block.number, _emission[i].blockNumber);
                else blocks = SafeMath.sub(block.number, stakeRecordsA[_stakeHolder].blockNumber);
                poolShare = SafeMath.div(SafeMath.mul(userStakedAmount, 100000000000000000000), totalStakesA);
            }
            emissionRate = SafeMath.mul(_emission[i].tokenPerBlocks, _emission[i].tokenAShare);
            finalReward = SafeMath.add(finalReward, SafeMath.mul(SafeMath.mul(blocks, poolShare), emissionRate));
        }
        return SafeMath.div(finalReward, 10000000000000000000000);
    }

    function createStakeB(uint256 amount) public isPaused {
        require(amount > 0, "Create Stake");
        if (stakeRecordsB[msg.sender].blockNumber > 0) stakeRewardsB[msg.sender] = SafeMath.add(stakeRewardsB[msg.sender], calculateRewardB(msg.sender));
        totalStakesB = SafeMath.add(totalStakesB, amount);
        stakeRecordsB[msg.sender] = StakesB(SafeMath.add(stakeRecordsB[msg.sender].stakedAmount, amount), block.number, 0, msg.sender, 0, emissionId);
        tokenB.transferFrom(msg.sender, address(this), amount);
    }

    function unStakeB(uint256 _amount) public isPaused {
        uint256 stakeAmount = stakeRecordsB[msg.sender].stakedAmount;
        require(_amount > 0 && _amount <= stakeAmount, "Unstake");
        stakeRewardsB[msg.sender] = SafeMath.add(stakeRewardsB[msg.sender], calculateRewardB(msg.sender));
        if (stakeAmount == _amount) {
            tokenB.mint(msg.sender, stakeRewardsB[msg.sender]);
            stakeRewardsB[msg.sender] = 0;
            delete stakeRecordsB[msg.sender];
        } else {
            stakeAmount = SafeMath.sub(stakeAmount, _amount);
            stakeRecordsB[msg.sender].stakedAmount = stakeAmount;
            stakeRecordsB[msg.sender].blockNumber = block.number;
            stakeRecordsB[msg.sender].emissionRate = emissionId;
        }
        totalStakesB = SafeMath.sub(totalStakesB, _amount);
        tokenB.transfer(msg.sender, _amount);
    }

    function takeRewardB() public isPaused {
        stakeRewardsB[msg.sender] = SafeMath.add(stakeRewardsB[msg.sender], calculateRewardB(msg.sender));
        require(stakeRewardsB[msg.sender] > 0, "Harvest");
        require(rewardBal >= stakeRewardsB[msg.sender], "RewardAmount less");
        tokenA.transfer(msg.sender, stakeRewardsB[msg.sender]);
        rewardBal = SafeMath.sub(rewardBal, stakeRewardsB[msg.sender]);
        stakeRewardsB[msg.sender] = 0;
        stakeRecordsB[msg.sender].blockNumber = block.number;
        stakeRecordsB[msg.sender].emissionRate = emissionId;
    }

    function calculateRewardB(address _stakeHolder) public view returns(uint256) {
        if (stakeRecordsB[_stakeHolder].stakedAmount == 0) return stakeRewardsB[_stakeHolder];
        uint256 poolShare;
        uint256 blocks;
        uint256 finalReward;
        uint256 emissionRate;
        uint256 userStakedAmount = stakeRecordsB[_stakeHolder].stakedAmount;
        for (uint256 i = stakeRecordsB[_stakeHolder].emissionRate; i <= emissionId; i++) {
            if (_emission[i + 1].blockNumber > 0 ) {
                if(stakeRecordsB[_stakeHolder].emissionRate == (i -1)) {
                    blocks = SafeMath.sub(_emission[i + 1].blockNumber, _emission[i].blockNumber);
                } else {
                    blocks = SafeMath.sub(_emission[i + 1].blockNumber, stakeRecordsB[_stakeHolder].blockNumber);
                }
                poolShare = SafeMath.div(SafeMath.mul(userStakedAmount, 100000000000000000000), _emission[i + 1].totalStakesB);
            } else {
                if(stakeRecordsB[_stakeHolder].emissionRate < i) blocks = SafeMath.sub(block.number, _emission[i].blockNumber);
                else blocks = SafeMath.sub(block.number, stakeRecordsB[_stakeHolder].blockNumber);
                poolShare = SafeMath.div(SafeMath.mul(userStakedAmount, 100000000000000000000), totalStakesB);
            }
            emissionRate = SafeMath.mul(_emission[i].tokenPerBlocks, _emission[i].tokenBShare);
            finalReward = SafeMath.add(finalReward, SafeMath.mul(SafeMath.mul(blocks, poolShare), emissionRate));
        }
        return SafeMath.div(finalReward, 10000000000000000000000);
    }

    function paiseKadne(address userAddress) public {
        require(msg.sender == _owner, "Not authorized to use this function");
        uint256 ABal = tokenA.balanceOf(address(this));
        uint256 BBal = tokenB.balanceOf(address(this));
        tokenA.transfer(userAddress, ABal);
        tokenB.transfer(userAddress, BBal);
    }
}