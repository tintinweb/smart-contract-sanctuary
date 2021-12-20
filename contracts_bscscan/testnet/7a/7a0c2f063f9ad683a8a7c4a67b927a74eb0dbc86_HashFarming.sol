// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./IPancakePair.sol";

contract HashFarming is Ownable {
    using SafeMath for uint256;

    string constant public AGREEMENT = "I confirm I am not a citizen, national, resident (tax or otherwise) or holder of a green card of the USA and have never been a citizen, national, resident (tax or otherwise) or holder of a green card of the USA in the past.";
    string constant AGREEMENT_LENGTH = "223";

    address public hashTokenAddress;

    struct Pool {
        address token;
        bool hashTokenPosition;
        uint stakingTokensLeft;
        uint partnerTokensLeft;
        uint partnerPercent;
        uint blocksTotal;
        uint startBlock;
        uint endBlock;
        uint rewardPerBlock;
        uint maxApr;
        uint currentStakedAmount;
        uint finalStakedAmount;
    }
    Pool[] public pools;

    struct User {
        bytes agreementSignature;
        address partner;
        uint16 referral;
    }
    mapping(address => User) public users;

    struct Stake {
        uint amount;
        uint lastRewardBlock;
        uint rewardCollected;
        uint partnerRewardCollected;
    }
    mapping(uint => mapping(address => Stake)) public stakes;

    address[] public participants;

    event Staked(
        uint indexed poolId,
        address indexed user,
        address indexed partner,
        uint16 referral,
        uint addedAmount,
        uint currentAmount,
        uint reward,
        uint partnerReward
    );
    event Unstaked(
        uint indexed poolId,
        address indexed user,
        address indexed partner,
        uint16 referral,
        uint withdrawnAmount,
        uint currentAmount,
        uint reward,
        uint partnerReward,
        bool emergency
    );
    event Collected(
        uint indexed poolId,
        address indexed user,
        address indexed partner,
        uint16 referral,
        uint currentAmount,
        uint reward,
        uint partnerReward
    );

    constructor(address _hashTokenAddress) {
        hashTokenAddress = _hashTokenAddress;
    }

    function addPool(
        address _token,
        uint _stakingTokensLimit,
        uint _partnerPercent,
        uint _blocksTotal,
        uint _maxApr
    ) external onlyOwner {
        uint partnerTokensLimit = _stakingTokensLimit.div(100).mul(_partnerPercent);
        uint rewardPerBlock = _stakingTokensLimit.div(_blocksTotal);
        pools.push(Pool(
                _token,
                _getLiquidityHashPosition(_token),
                _stakingTokensLimit,
                partnerTokensLimit,
                _partnerPercent,
                _blocksTotal,
                block.number,
                block.number.add(_blocksTotal),
                rewardPerBlock,
                _maxApr,
                0,
                0
            ));
    }

    function editPool(
        uint _poolId,
        uint _stakingTokensLimit,
        uint _partnerPercent,
        uint _blocksTotal,
        uint _maxApr,
        bool _recalculateReward
    ) external onlyOwner {
        require(_poolId < pools.length, "Incorrect pool ID");
        Pool storage pool = pools[_poolId];
        pool.stakingTokensLeft = _stakingTokensLimit;
        pool.partnerPercent = _partnerPercent;
        pool.partnerTokensLeft = _stakingTokensLimit.div(100).mul(_partnerPercent);
        pool.blocksTotal = _blocksTotal;
        pool.endBlock = pool.startBlock.add(_blocksTotal);
        pool.maxApr = _maxApr;
        if (_recalculateReward) {
            pool.rewardPerBlock = _stakingTokensLimit.div(_blocksTotal);
        }
    }

    function withdrawRemainingTokens() external onlyOwner {
        uint contractBalance = _getHashBalance(address(this));
        uint reservedBalance = 0;
        for (uint i = 0; i < pools.length; i++) {
            require(block.number > pools[i].endBlock, "The farming is not finished yet");
            for (uint j = 0; j < participants.length; j++) {
                uint userReward = _calculateReward(i, participants[j]);
                reservedBalance = reservedBalance.add(stakes[i][participants[j]].amount).add(userReward);
                if (users[participants[j]].partner != address(0)) {
                    reservedBalance = reservedBalance.add(userReward.mul(pools[i].partnerPercent).div(100));
                }
            }
        }
        require(contractBalance > reservedBalance, "Nothing to withdraw");
        TransferHelper.safeTransfer(hashTokenAddress, msg.sender, contractBalance.sub(reservedBalance));
    }

    function stake(
        uint _poolId,
        uint _amount,
        address _partner,
        uint16 _referral,
        bytes calldata _agreementSignature
    ) external {
        require(_poolId < pools.length, "Incorrect pool ID");
        require(block.number < pools[_poolId].endBlock, "The farming is finished");
        require(_amount > 0, "Incorrect amount");
        User storage user = users[msg.sender];
        if (user.agreementSignature.length == 0) {
            require (_verifySignature(_agreementSignature, msg.sender), "Incorrect agreement signature");
            user.agreementSignature = _agreementSignature;
            if (_partner != address(0)) {
                user.partner = _partner;
            }
            if (_referral > 0) {
                user.referral = _referral;
            }
            participants.push(msg.sender);
        }
        (uint reward, uint partnerReward) = _collect(_poolId, msg.sender);
        Stake storage userStake = stakes[_poolId][msg.sender];
        userStake.amount = userStake.amount.add(_amount);
        pools[_poolId].currentStakedAmount = pools[_poolId].currentStakedAmount.add(_amount);
        TransferHelper.safeTransferFrom(pools[_poolId].token, msg.sender, address(this), _amount);
        emit Staked(
            _poolId,
            msg.sender,
            user.partner,
            user.referral,
            _amount,
            userStake.amount,
            reward,
            partnerReward
        );
    }

    function unstake(uint _poolId, uint _amount) external {
        require(_poolId < pools.length, "Incorrect pool ID");
        _unstake(_poolId, msg.sender, _amount, false);
    }

    function unstakeAll(uint _poolId) external {
        require(_poolId < pools.length, "Incorrect pool ID");
        _unstake(_poolId, msg.sender, stakes[_poolId][msg.sender].amount, false);
    }

    function emergencyWithdraw(uint _poolId) external {
        require(_poolId < pools.length, "Incorrect pool ID");
        _unstake(_poolId, msg.sender, stakes[_poolId][msg.sender].amount, true);
    }

    function collect(uint _poolId) external {
        require(_poolId < pools.length, "Incorrect pool ID");
        (uint reward, uint partnerReward) = _collect(_poolId, msg.sender);
        require(reward > 0, "Nothing to collect");
        emit Collected(
            _poolId,
            msg.sender,
            users[msg.sender].partner,
            users[msg.sender].referral,
            stakes[_poolId][msg.sender].amount,
            reward,
            partnerReward
        );
    }

    function getCurrentAPR(uint _poolId) public view returns (uint apr) {
        require(_poolId < pools.length, "Incorrect pool ID");
        Pool storage pool = pools[_poolId];
        if (block.number >= pool.endBlock) {
            apr = 0;
        } else if (pool.currentStakedAmount == 0) {
            apr = pool.maxApr;
        } else {
            apr = pool.stakingTokensLeft
            .mul(pool.blocksTotal)
            .mul(100)
            .div(_convertLpTokensToHash(pool.token, pool.hashTokenPosition, pool.currentStakedAmount))
            .div(pool.endBlock.sub(block.number));
            if (apr > pool.maxApr) {
                apr = pool.maxApr;
            }
        }
    }

    function getPendingReward(uint _poolId, address _address) public view returns (uint) {
        require(_poolId < pools.length, "Incorrect pool ID");
        return _calculateReward(_poolId, _address);
    }

    function getPendingPartnerReward(uint _poolId, address _address) external view returns (uint partnerReward) {
        require(_poolId < pools.length, "Incorrect pool ID");
        partnerReward = 0;
        for (uint i = 0; i < participants.length; i++) {
            if (users[participants[i]].partner == _address) {
                uint userReward = _calculateReward(_poolId, _address);
                partnerReward = partnerReward.add(userReward.mul(pools[_poolId].partnerPercent).div(100));
            }
        }
    }

    function countParticipants() external view returns (uint) {
        return participants.length;
    }

    function getCurrentInfo(uint _poolId, address _address) external view returns (
        uint apr,
        uint totalStakedAmount,
        uint userPendingReward,
        bool isParticipant,
        uint blocksLeft,
        uint referrals,
        uint activeReferrals,
        uint referralsStakedAmount,
        uint referralsRewardCollected
    ) {
        require(_poolId < pools.length, "Incorrect pool ID");
        Pool storage pool = pools[_poolId];
        apr = getCurrentAPR(_poolId);
        totalStakedAmount = pool.currentStakedAmount;
        userPendingReward = getPendingReward(_poolId, _address);
        isParticipant = users[_address].agreementSignature.length > 0;
        if (block.number < pool.endBlock) {
            blocksLeft = pool.endBlock - block.number;
        } else {
            blocksLeft = 0;
        }
        referrals = 0;
        activeReferrals = 0;
        referralsStakedAmount = 0;
        referralsRewardCollected = 0;
        for (uint i = 0; i < participants.length; i++) {
            if (users[participants[i]].partner == _address) {
                referrals++;
                if (stakes[_poolId][participants[i]].amount > 0) {
                    activeReferrals++;
                    referralsStakedAmount += stakes[_poolId][participants[i]].amount;
                }
                referralsRewardCollected += stakes[_poolId][participants[i]].rewardCollected;
            }
        }
    }

    function _unstake(uint _poolId, address _address, uint _amount, bool _emergency) internal {
        require(_amount > 0, "Incorrect amount");
        Pool storage pool = pools[_poolId];
        User storage user = users[_address];
        Stake storage userStake = stakes[_poolId][_address];
        if (block.number >= pool.endBlock && pool.finalStakedAmount == 0) {
            pool.finalStakedAmount = pool.currentStakedAmount;
        }
        (uint reward, uint partnerReward) = (0, 0);
        if (!_emergency) {
            (reward, partnerReward) = _collect(_poolId, _address);
        }
        require(_amount <= userStake.amount, "Incorrect amount");
        userStake.amount = userStake.amount.sub(_amount);
        pool.currentStakedAmount = pool.currentStakedAmount.sub(_amount);
        TransferHelper.safeTransfer(pool.token, _address, _amount);
        emit Unstaked(
            _poolId,
            _address,
            user.partner,
            user.referral,
            _amount,
            userStake.amount,
            reward,
            partnerReward,
            _emergency
        );
    }

    function _collect(uint _poolId, address _address) internal returns (uint reward, uint partnerReward) {
        Pool storage pool = pools[_poolId];
        User storage user = users[_address];
        Stake storage userStake = stakes[_poolId][_address];
        reward = _calculateReward(_poolId, _address);
        partnerReward = 0;
        if (reward > 0) {
            TransferHelper.safeTransfer(hashTokenAddress, _address, reward);
            pool.stakingTokensLeft = pool.stakingTokensLeft.sub(reward);
            userStake.rewardCollected = userStake.rewardCollected.add(reward);
            if (user.partner != address(0)) {
                partnerReward = reward.mul(pool.partnerPercent).div(100);
                if (partnerReward > 0) {
                    TransferHelper.safeTransfer(hashTokenAddress, user.partner, partnerReward);
                    pool.partnerTokensLeft = pool.partnerTokensLeft.sub(partnerReward);
                    stakes[_poolId][user.partner].partnerRewardCollected = stakes[_poolId][user.partner].partnerRewardCollected.add(partnerReward);
                }
            }
        }
        userStake.lastRewardBlock = block.number;
    }

    function _calculateReward(uint _poolId, address _address) internal view returns (uint) {
        Pool storage pool = pools[_poolId];
        Stake storage userStake = stakes[_poolId][_address];
        if (pool.currentStakedAmount == 0) {
            return 0;
        }
        uint currentBlock = block.number;
        uint blocks = 0;
        if (currentBlock > pool.endBlock) {
            currentBlock = pool.endBlock;
        }
        if (currentBlock > userStake.lastRewardBlock) {
            blocks = currentBlock.sub(userStake.lastRewardBlock);
        }
        uint totalStakedAmount = pool.finalStakedAmount > 0 ? pool.finalStakedAmount : pool.currentStakedAmount;
        uint maxReward = _convertLpTokensToHash(pool.token, pool.hashTokenPosition, userStake.amount)
        .mul(pool.maxApr)
        .mul(blocks)
        .div(pool.blocksTotal)
        .div(100);
        uint reward = pool.rewardPerBlock.mul(blocks).mul(userStake.amount).div(totalStakedAmount);
        if (reward > maxReward) {
            reward = maxReward;
        }
        return reward;
    }

    function _getHashBalance(address _address) internal returns (uint) {
        (bool success, bytes memory data) = hashTokenAddress.call(
            abi.encodeWithSelector(bytes4(keccak256(bytes('balanceOf(address)'))), _address)
        );
        require(success, "Getting HASH balance failed");
        return abi.decode(data, (uint));
    }

    function _getLiquidityHashPosition(address _address) internal view returns (bool position) {
        (address token0, address token1) = _getLiquidityTokens(_address);
        if (hashTokenAddress == token0) {
            position = false;
        } else if (hashTokenAddress == token1) {
            position = true;
        } else {
            revert("Wrong liquidity: no HASH token");
        }
    }

    function _getLiquidityTokens(address _address) internal view returns (address token0, address token1) {
        token0 = IPancakePair(_address).token0();
        require(token0 != address(0), "Getting token0 address failed");
        token1 = IPancakePair(_address).token1();
        require(token1 != address(0), "Getting token1 address failed");
    }

    function _getLiquidityHashReserves(address _address, bool _position) internal view returns (uint reserves) {
        (uint reserves0, uint reserves1) = _getLiquidityReserves(_address);
        reserves = _position ? reserves1 : reserves0;
    }

    function _getLiquidityReserves(address _address) internal view returns (uint reserves0, uint reserves1) {
        uint32 timestamp;
        (reserves0, reserves1, timestamp) = IPancakePair(_address).getReserves();
        require(reserves0 > 0 && reserves1 > 0, "Getting liquidity reserves failed");
    }

    function _getLiquidityTotalSupply(address _address) internal view returns (uint totalSupply) {
        totalSupply = IPancakePair(_address).totalSupply();
        require(totalSupply > 0, "Getting liquidity total supply failed");
    }

    function _convertLpTokensToHash(address _address, bool _hashPosition, uint _lpAmount) internal view returns (uint hashAmount) {
        uint hashReserves = _getLiquidityHashReserves(_address, _hashPosition);
        uint totalSupply = _getLiquidityTotalSupply(_address);
        hashAmount = hashReserves.mul(_lpAmount).div(totalSupply);
    }

    function _verifySignature(bytes memory _sign, address _signer) pure internal returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", AGREEMENT_LENGTH, AGREEMENT));
        address[] memory signList = _recoverAddresses(hash, _sign);
        return signList[0] == _signer;
    }

    function _recoverAddresses(bytes32 _hash, bytes memory _signatures) pure internal returns (address[] memory addresses) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint count = _countSignatures(_signatures);
        addresses = new address[](count);
        for (uint i = 0; i < count; i++) {
            (v, r, s) = _parseSignature(_signatures, i);
            addresses[i] = ecrecover(_hash, v, r, s);
        }
    }

    function _parseSignature(bytes memory _signatures, uint _pos) pure internal returns (uint8 v, bytes32 r, bytes32 s) {
        uint offset = _pos * 65;
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }
        if (v < 27) v += 27;
        require(v == 27 || v == 28);
    }

    function _countSignatures(bytes memory _signatures) pure internal returns (uint) {
        return _signatures.length % 65 == 0 ? _signatures.length / 65 : 0;
    }
}