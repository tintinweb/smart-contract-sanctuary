// SPDX-License-Identifier: UNLICENSED
import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

pragma solidity ^0.7.6;
pragma abicoder v2;


interface PeaNFT is IERC721 {
    
    enum Champ {
        __GEM,
        CANION,
        DRANI,
        SEPTER,
        UNIAS
    }

    enum Level {
        BEGINNER,
        APPRENTICE,
        MASTER,
        GRANDMASTER,
        EPIC,
        LEGENDARY
    }

    struct Pean {
        Champ champ;
        Level level;
        uint256 exp;
        uint256 bornAt;
    }

    function getPean(uint256 _tokenId) external view returns (Pean memory);
}

interface PeaToken is IERC20 {
    function farm(address to, uint256 amount) external;
}

// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once PeaNFT is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract PeaFarming is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    // Info of each pool.
    struct PoolInfo {
        PeaNFT.Champ champ; // Address of LP token contract.
        PeaNFT.Level level; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Peas to distribute per block.
        uint256 lastRewardBlock; // Last block number that Peas distribution occurs.
        uint256 accPeaTokenPerShare; // Accumulated Peas per share, times 1e12. See below.
    }
    // The Pea TOKEN!
    PeaToken public peaToken;
    PeaNFT public peaNFT;
    // Dev address.
    address public devaddr;
    uint256 public devreward;
    // Amount block number halving.
    uint256 public halvingBlockAmount;
    // Pea tokens created per block.
    uint256 public peaTokenPerBlock;
    // Bonus muliplier for early peaToken makers.
    uint256 public constant HAVING_MULTIPLIER = 9; // -10%
    uint256 public constant REWARD_MULTIPLIER = 10**6;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(PeaNFT.Champ => mapping(PeaNFT.Level => mapping(address => uint256)))
        public userRewardDebt;
    mapping(PeaNFT.Champ => mapping(PeaNFT.Level => mapping(address => EnumerableSet.UintSet)))
        internal userNFT;
    mapping(PeaNFT.Champ => mapping(PeaNFT.Level => EnumerableSet.UintSet))
        private farmingNFT;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Pea mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 _tokenId);
    event Withdraw(address indexed user, uint256 _tokenId);
    event EmergencyWithdraw(address indexed user, uint256 _champ, uint256 _level);

    constructor(PeaToken _peaToken, PeaNFT _peaNFT) {
        peaToken = _peaToken;
        peaNFT = _peaNFT;
        devaddr = msg.sender;
        devreward = 10;

        uint256 _alloc = 12;
        for (uint256 _cp = 1; _cp < 5; ++_cp) {
            for (uint256 _lv = 0; _lv < 6; ++_lv) {
                _alloc = _alloc + (_alloc * 15 * _lv).div(100);
                add(_alloc , PeaNFT.Champ(_cp), PeaNFT.Level(_lv), true);
            }
        }
    }

    function configFarming(
        uint256 _peaTokenPerBlock,
        uint256 _startBlock,
        uint256 _halvingBlockAmount
    ) public onlyOwner {
        require(startBlock == 0, "once time");
        require(_startBlock > block.number, "too old block");

        peaTokenPerBlock = _peaTokenPerBlock.div(REWARD_MULTIPLIER);
        halvingBlockAmount = _halvingBlockAmount;
        startBlock = _startBlock;
    }

    function poolSize(PeaNFT.Champ _champ, PeaNFT.Level _level) public view returns (uint256) {
        return farmingNFT[_champ][_level].length();
    }

    function add(
        uint256 _allocPoint,
        PeaNFT.Champ _champ,
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
                champ: _champ,
                level: _level,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accPeaTokenPerShare: 0
            })
        );
    }

    // Update the given pool's PeaNFT allocation point. Can only be called by the owner.
    function set(
        PeaNFT.Champ _champ,
        PeaNFT.Level _level,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 _pid = uint256(_level) + (uint256(_champ) - 1) * 6;
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        // console.log("getMultiplier from %s to %s", _from, _to);

        uint256 oldHalving = _from.sub(startBlock).div(halvingBlockAmount);
        // console.log("oldHalving: %s", oldHalving);
        uint256 rangeBlock = _to.sub(startBlock);
        // console.log("rangeBlock: %s", rangeBlock);
        uint256 timeOfHalving = rangeBlock.div(halvingBlockAmount);
        // console.log("timeOfHalving: %s", timeOfHalving);
        uint256 multipler;

        for (uint256 index = oldHalving; index <= timeOfHalving; index++) {
            uint256 nextHavlingBlock = startBlock.add(
                (index + 1).mul(halvingBlockAmount)
            );
            uint256 amountBlock;
            if (index == oldHalving && index == timeOfHalving) {
                amountBlock = _to.sub(_from);
            } else if (index == oldHalving) {
                amountBlock = nextHavlingBlock.sub(_from);
            } else if (index == timeOfHalving) {
                amountBlock = _to.sub(nextHavlingBlock.sub(halvingBlockAmount));
            } else {
                amountBlock = halvingBlockAmount;
            }
            uint256 mulPart = amountBlock
                .mul(REWARD_MULTIPLIER)
                .mul(HAVING_MULTIPLIER**index)
                .div(10**index);
            multipler = multipler.add(mulPart);
            // console.log(
            //     "nextHavlingBlock: %s , amountBlock: %s",
            //     nextHavlingBlock,
            //     amountBlock
            // );
            // console.log("mulPart: %s , multipler: %s", mulPart, multipler);
        }

        // console.log(" multipler: %s", multipler);
        return multipler;
    }

    // View function to see pending Pean on frontend.
    function pendingPeaToken(
        PeaNFT.Champ _champ,
        PeaNFT.Level _level,
        address _user
    ) external
    view
    returns (uint256)
    {
        uint256 _pid = uint256(_level) + (uint256(_champ) - 1) * 6;
        PoolInfo storage pool = poolInfo[_pid];
        // console.log("User: %s pid %s", _user, _pid);

        uint256 accPeaTokenPerShare = pool.accPeaTokenPerShare;
        // console.log(
        //     "Pool info: per share %s, allocPoint: %s",
        //     accPeaTokenPerShare,
        //     pool.allocPoint
        // );

        uint256 peanSupply = farmingNFT[pool.champ][pool.level].length();

        if (block.number > pool.lastRewardBlock && peanSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            // console.log("multiplier: %s", multiplier);
            // console.log("peaTokenPerBlock: %s", peaTokenPerBlock);
            uint256 peaTokenReward = multiplier
                .mul(peaTokenPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            // console.log("peaTokenReward: %s", peaTokenReward);
            accPeaTokenPerShare = accPeaTokenPerShare.add(
                peaTokenReward.mul(1e12).div(peanSupply)
            );
        }
        return
            userNFT[pool.champ][pool.level][_user]
                .length()
                .mul(accPeaTokenPerShare)
                .div(1e12)
                .sub(userRewardDebt[pool.champ][pool.level][_user]);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        for (uint256 _cp = 1; _cp < 5; ++_cp) {
            for (uint256 _lv = 0; _lv < 6; ++_lv) {
                updatePool(_cp, _lv);
            }
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _champ, uint256 _level) public {
        uint256 _pid = _level + (_champ - 1) * 6;
        if (_pid >= poolInfo.length){
            return;
        }

        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        
        uint256 peanSupply = farmingNFT[PeaNFT.Champ(_champ)][PeaNFT.Level(_level)].length();
        if (peanSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 peaTokenReward = multiplier
            .mul(peaTokenPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);

        peaToken.farm(devaddr, peaTokenReward.div(devreward));
        peaToken.farm(address(this), peaTokenReward);
        pool.accPeaTokenPerShare = pool.accPeaTokenPerShare.add(
            peaTokenReward.mul(1e12).div(peanSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit NFT tokens to Farming for PeaNFT allocation.
    function deposit(uint256 _tokenId) public {
        require(block.number > startBlock, "not start");
        PeaNFT.Pean memory pean = peaNFT.getPean(_tokenId);
        PeaNFT.Champ _champ = pean.champ;
        PeaNFT.Level _level = pean.level;

        uint256 _pid = uint256(_level) + (uint256(_champ) - 1) * 6;
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(uint256(_champ), uint256(_level));

        if (userNFT[pool.champ][pool.level][msg.sender].length() > 0) {
            uint256 pending = userNFT[pool.champ][pool.level][msg.sender]
                .length()
                .mul(pool.accPeaTokenPerShare)
                .div(1e12)
                .sub(userRewardDebt[_champ][_level][msg.sender]);
            safePeaTokenTransfer(msg.sender, pending);
        }
        peaNFT.transferFrom(address(msg.sender), address(this), _tokenId);

        farmingNFT[_champ][_level].add(_tokenId);
        userNFT[_champ][_level][msg.sender].add(_tokenId);
        userRewardDebt[_champ][_level][msg.sender] = userNFT[_champ][_level][msg.sender]
            .length()
            .mul(pool.accPeaTokenPerShare)
            .div(1e12);
        emit Deposit(msg.sender, _tokenId);
    }

    // Withdraw NFT tokens from Farming.
    function withdraw(uint256 _tokenId) public {
        PeaNFT.Pean memory pean = peaNFT.getPean(_tokenId);
        PeaNFT.Champ _champ = pean.champ;
        PeaNFT.Level _level = pean.level;

        require(
            userNFT[_champ][_level][msg.sender].contains(_tokenId),
            "withdraw: not good"
        );

        uint256 _pid = uint256(_level) + (uint256(_champ) - 1) * 6;
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(uint256(_champ), uint256(_level));
        uint256 pending = userNFT[pool.champ][pool.level][msg.sender]
            .length()
            .mul(pool.accPeaTokenPerShare)
            .div(1e12)
            .sub(userRewardDebt[pool.champ][pool.level][msg.sender]);
        safePeaTokenTransfer(msg.sender, pending);

        farmingNFT[_champ][_level].remove(_tokenId);
        userNFT[_champ][_level][msg.sender].remove(_tokenId);
        userRewardDebt[pool.champ][pool.level][msg.sender] = userNFT[pool.champ][pool.level][msg.sender]
            .length()
            .mul(pool.accPeaTokenPerShare)
            .div(1e12);
        peaNFT.transferFrom(address(this), address(msg.sender), _tokenId);
        emit Withdraw(msg.sender, _tokenId);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _champ, uint256 _level) public {
        uint256 _pid = _level + (_champ - 1) * 6;
        PoolInfo storage pool = poolInfo[_pid];

        uint256 userFarms = userNFT[pool.champ][pool.level][msg.sender].length();
        require(userFarms > 0, "nothing to withdraw");

        for (uint256 index = 0; index < userFarms; index++) {
            uint256 tokenId = userNFT[pool.champ][pool.level][msg.sender].at(index);
            emit EmergencyWithdraw(msg.sender, _champ, _level);
            peaNFT.transferFrom(address(this), address(msg.sender), tokenId);
            userNFT[pool.champ][pool.level][msg.sender].remove(tokenId);
        }

        userRewardDebt[pool.champ][pool.level][msg.sender] = 0;
    }

    // Safe peaToken transfer function, just in case if rounding error causes pool to not have enough Peas.
    function safePeaTokenTransfer(address _to, uint256 _amount) internal {
        uint256 peaTokenBal = peaToken.balanceOf(address(this));
        uint256 amount;
        if (_amount > peaTokenBal) {
            amount = peaTokenBal;
        } else {
            amount = _amount;
        }
        peaToken.transfer(_to, amount);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function devReward(uint256 _reward) public onlyOwner {
        require(_reward > 0, "dev have to survive");
        require(_reward < 99, "that was cute");

        devreward = _reward;
    }

    function balanceOfUser(uint256 _champ, uint256 _level, address _user)
        public
        view
        returns (uint256)
    {
        uint256 _pid = _level + (_champ - 1) * 6;
        PoolInfo storage pool = poolInfo[_pid];
        return userNFT[pool.champ][pool.level][_user].length();
    }

    function tokenOfUserByIndex(
        uint256 _champ,
        uint256 _level,
        address _user,
        uint256 _index
    ) public view returns (uint256) {
        uint256 _pid = _level + (_champ - 1) * 6;
        PoolInfo storage pool = poolInfo[_pid];
        return userNFT[pool.champ][pool.level][_user].at(_index);
    }
}