// SPDX-License-Identifier: UNLICENSED
import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

pragma solidity ^0.7.6;
pragma abicoder v2;

interface PeanToken is IERC20 {
    function farm(address to, uint256 amount) external;
}

interface PeaNFT is IERC721 {
    enum Level {
        __KEY,
        ARCHER,
        FIGHTER,
        DESTROYER,
        WANDERER,
        TEMPLAR
    }

    struct Pean {
        Level level;
        uint256 exp;
        uint256 bornAt;
    }

    function getPean(uint256 token) external view returns (Pean memory);

    function farm(address to, uint256 amount) external;
}

// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once PeaNFT is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract PeanFarming is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    // Info of each pool.
    struct PoolInfo {
        PeaNFT.Level level; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Pean to distribute per block.
        uint256 lastRewardBlock; // Last block number that Pean distribution occurs.
        uint256 accPeanTokenPerShare; // Accumulated Pean per share, times 1e12. See below.
    }
    PeaNFT public peaNFT;
    PeanToken public peanToken;
    // Dev address.
    address public devaddr;
    uint256 public halvingBlockAmount;
    uint256 public peanTokenPerBlock;
    uint256 public constant HAVING_MULTIPLIER = 9; // -10%
    uint256 public constant REWARD_MULTIPLIER = 10**6;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(PeaNFT.Level => mapping(address => uint256))
        public userRewardDebt;
    mapping(PeaNFT.Level => mapping(address => EnumerableSet.UintSet))
        internal userNFT;
    mapping(PeaNFT.Level => EnumerableSet.UintSet) private farmingNFT;
    mapping(uint256 => uint256) private farmingTime;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 _tokenId);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 _tokenId);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 _tokenId
    );

    constructor(PeanToken _peanToken, PeaNFT _peaNFT) {
        peanToken = _peanToken;
        peaNFT = _peaNFT;
        devaddr = msg.sender;
        // Pid 1: 1x
        // Pid 2: 1.2x
        // Pid 3: 1.4x
        // Pid 4: 1.6x
        // Pid 5: 2.0x
        add(0, PeaNFT.Level.__KEY, true);
        add(10, PeaNFT.Level.ARCHER, true);
        add(12, PeaNFT.Level.FIGHTER, true);
        add(14, PeaNFT.Level.DESTROYER, true);
        add(16, PeaNFT.Level.WANDERER, true);
        add(20, PeaNFT.Level.TEMPLAR, true);
    }

    function configFarming(uint256 _startBlock, uint256 _halvingBlockAmount)
        public
        onlyOwner
    {
        require(startBlock == 0, "once time");
        require(_startBlock > block.number, "too old block");

        uint256 _peanTokenPerBlock = 72 * 10**18;
        peanTokenPerBlock = _peanTokenPerBlock.div(REWARD_MULTIPLIER);
        halvingBlockAmount = _halvingBlockAmount;
        startBlock = _startBlock;
    }

    function poolSize(PeaNFT.Level _level) public view returns (uint256) {
        return farmingNFT[_level].length();
    }

    function add(
        uint256 _allocPoint,
        PeaNFT.Level _level,
        bool _withUpdate
    ) internal {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                level: _level,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accPeanTokenPerShare: 0
            })
        );
    }

    // Update the given pool's PeaNFT allocation point. Can only be called by the owner.
    // function set(
    //     uint256 _pid,
    //     uint256 _allocPoint,
    //     bool _withUpdate
    // ) public onlyOwner {
    //     if (_withUpdate) {
    //         massUpdatePools();
    //     }
    //     totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
    //         _allocPoint
    //     );
    //     poolInfo[_pid].allocPoint = _allocPoint;
    // }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        uint256 oldHalving = _from.sub(startBlock).div(halvingBlockAmount);
        uint256 rangeBlock = _to.sub(startBlock);
        uint256 timeOfHalving = rangeBlock.div(halvingBlockAmount);
        uint256 multipler;
        if (timeOfHalving == 0 && oldHalving == 0) {
            multipler = _to.sub(_from).mul(REWARD_MULTIPLIER);
        } else
            for (uint256 index = oldHalving; index <= timeOfHalving; index++) {
                uint256 nextHavlingBlock = startBlock.add(
                    (index + 1).mul(halvingBlockAmount)
                );
                uint256 amountBlock;
                if (index == oldHalving) {
                    amountBlock = nextHavlingBlock.sub(_from);
                } else if (index == timeOfHalving) {
                    amountBlock = _to.sub(
                        nextHavlingBlock.sub(halvingBlockAmount)
                    );
                } else {
                    amountBlock = halvingBlockAmount;
                }
                uint256 mulPart = amountBlock
                    .mul(REWARD_MULTIPLIER)
                    .mul(HAVING_MULTIPLIER**index)
                    .div(10**index);
                multipler = multipler.add(mulPart);
            }
        return multipler;
    }

    // View function to see pending Pean on frontend.
    function pendingPeanToken(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 accPeanTokenPerShare = pool.accPeanTokenPerShare;

        uint256 peanSupply = farmingNFT[pool.level].length();

        if (block.number > pool.lastRewardBlock && peanSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 peanTokenReward = multiplier
                .mul(peanTokenPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accPeanTokenPerShare = accPeanTokenPerShare.add(
                peanTokenReward.mul(1e12).div(peanSupply)
            );
        }
        return
            userNFT[pool.level][_user]
                .length()
                .mul(accPeanTokenPerShare)
                .div(1e12)
                .sub(userRewardDebt[pool.level][_user]);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 peanSupply = farmingNFT[PeaNFT.Level(_pid)].length();
        if (peanSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 peanTokenReward = multiplier
            .mul(peanTokenPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);

        peanToken.farm(devaddr, peanTokenReward.div(10));
        peanToken.farm(address(this), peanTokenReward);
        pool.accPeanTokenPerShare = pool.accPeanTokenPerShare.add(
            peanTokenReward.mul(1e12).div(peanSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit NFT tokens to Farming for PeaNFT allocation.
    function deposit(uint256 _tokenId) public {
        if (startBlock > block.number) {
            revert("Not start");
        }
        PeaNFT.Pean memory pean = peaNFT.getPean(_tokenId);
        PeaNFT.Level level = pean.level;
        uint256 _pid = uint256(level);
        if (_pid == 0) {
            revert("Require: not key");
        }
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);
        if (userNFT[pool.level][msg.sender].length() > 0) {
            uint256 pending = userNFT[pool.level][msg.sender]
                .length()
                .mul(pool.accPeanTokenPerShare)
                .div(1e12)
                .sub(userRewardDebt[level][msg.sender]);
            safePeanTokenTransfer(msg.sender, pending);
        }
        peaNFT.transferFrom(address(msg.sender), address(this), _tokenId);

        farmingNFT[level].add(_tokenId);
        userNFT[level][msg.sender].add(_tokenId);
        userRewardDebt[level][msg.sender] = userNFT[level][msg.sender]
            .length()
            .mul(pool.accPeanTokenPerShare)
            .div(1e12);

        farmingTime[_tokenId] = block.timestamp;
        emit Deposit(msg.sender, _pid, _tokenId);
    }

    // Withdraw NFT tokens from Farming.
    function withdraw(uint256 _tokenId) public {
        PeaNFT.Pean memory pean = peaNFT.getPean(_tokenId);
        PeaNFT.Level level = pean.level;
        require(
            userNFT[level][msg.sender].contains(_tokenId),
            "withdraw: not good"
        );
        uint256 _pid = uint256(level);
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);
        uint256 pending = userNFT[pool.level][msg.sender]
            .length()
            .mul(pool.accPeanTokenPerShare)
            .div(1e12)
            .sub(userRewardDebt[pool.level][msg.sender]);
        safePeanTokenTransfer(msg.sender, pending);

        farmingNFT[level].remove(_tokenId);
        userNFT[level][msg.sender].remove(_tokenId);
        userRewardDebt[pool.level][msg.sender] = userNFT[pool.level][msg.sender]
            .length()
            .mul(pool.accPeanTokenPerShare)
            .div(1e12);
        peaNFT.transferFrom(address(this), address(msg.sender), _tokenId);
        emit Withdraw(msg.sender, _pid, _tokenId);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 userFarms = userNFT[pool.level][msg.sender].length();
        require(userFarms > 0, "nothing to withdraw");
        for (uint256 index = 0; index < userFarms; index++) {
            uint256 tokenId = userNFT[pool.level][msg.sender].at(index);
            emit EmergencyWithdraw(msg.sender, _pid, tokenId);
            peaNFT.transferFrom(address(this), address(msg.sender), tokenId);
            userNFT[pool.level][msg.sender].remove(tokenId);
        }

        userRewardDebt[pool.level][msg.sender] = 0;
    }

    // Safe peanToken transfer function, just in case if rounding error causes pool to not have enough Pean.
    function safePeanTokenTransfer(address _to, uint256 _amount) internal {
        uint256 peanTokenBal = peanToken.balanceOf(address(this));
        uint256 amount;
        if (_amount > peanTokenBal) {
            amount = peanTokenBal;
        } else {
            amount = _amount;
        }
        peanToken.transfer(_to, amount);
    }

    function balanceOfUser(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        return userNFT[poolInfo[_pid].level][_user].length();
    }

    function tokenOfUserByIndex(
        uint256 _pid,
        address _user,
        uint256 _index
    ) public view returns (uint256) {
        return userNFT[poolInfo[_pid].level][_user].at(_index);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function recoverPean(uint256 amount) public {
        require(msg.sender == devaddr);
        peanToken.transfer(msg.sender, amount); // dont expect we'll hold tokens here but might as well
    }
}