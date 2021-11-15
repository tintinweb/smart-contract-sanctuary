pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract PolkaBridgeStaking is Ownable {
    string public name = "PolkaBridge: Staking";
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 rewardClaimed;
        uint256 lastBlock;
        uint256 beginTime;
        uint256 endTime;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 stakeToken;
        IERC20 rewardToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint256 rewardPerBlock;
        uint256 totalTokenStaked;
        uint256 totalTokenClaimed;
        uint256 endDate;
    }

    // Info of each pool.
    PoolInfo[] private poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public totalUser;

    // The block number when staking  starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(uint256 _startBlock) public {
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function addPool(
        uint256 _allocPoint,
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _endDate,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 _lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;

        poolInfo.push(
            PoolInfo({
                stakeToken: _stakeToken,
                rewardToken: _rewardToken,
                allocPoint: _allocPoint,
                lastRewardBlock: _lastRewardBlock,
                accTokenPerShare: 0,
                rewardPerBlock: _rewardPerBlock,
                totalTokenStaked: 0,
                totalTokenClaimed: 0,
                endDate: _endDate
            })
        );
    }

    function setPool(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _rewardPerBlock,
        uint256 _endDate,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        if (_allocPoint > 0) {
            poolInfo[_pid].allocPoint = _allocPoint;
        }
        if (_rewardPerBlock > 0) {
            poolInfo[_pid].rewardPerBlock = _rewardPerBlock;
        }
        if (_endDate > 0) {
            poolInfo[_pid].endDate = _endDate;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _fromBlock, uint256 _toBlock)
        public
        view
        returns (uint256)
    {
        return _toBlock.sub(_fromBlock);
    }

    function getTotalTokenStaked(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return pool.totalTokenStaked;
    }

    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 totalTokenStaked = getTotalTokenStaked(_pid);

        if (block.number > pool.lastRewardBlock && totalTokenStaked > 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number); //number diff block
            uint256 tokenReward = multiplier.mul(pool.rewardPerBlock);

            accTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(1e18).div(totalTokenStaked)
            );
        }
        return user.amount.mul(accTokenPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
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
        uint256 totalTokenStaked = getTotalTokenStaked(_pid);

        if (totalTokenStaked == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(pool.rewardPerBlock);

        pool.accTokenPerShare = pool.accTokenPerShare.add(
            tokenReward.mul(1e18).div(totalTokenStaked)
        );
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(block.timestamp < pool.endDate, "staking pool already closed");

        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accTokenPerShare).div(1e18).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                safeTokenTransfer(msg.sender, pending, _pid);
                pool.totalTokenClaimed = pool.totalTokenClaimed.add(pending);
                user.rewardClaimed = user.rewardClaimed.add(pending);
            }
        } else {
            //new user, or old user unstake all before
            totalUser = totalUser.add(1);
            user.beginTime = block.timestamp;
            user.endTime = 0; //reset endtime
        }
        if (_amount > 0) {
            pool.stakeToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
            pool.totalTokenStaked = pool.totalTokenStaked.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e18);
        user.lastBlock = block.number;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: bad request");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accTokenPerShare).div(1e18).sub(
                user.rewardDebt
            );
        if (pending > 0) {
            safeTokenTransfer(msg.sender, pending, _pid);
            pool.totalTokenClaimed = pool.totalTokenClaimed.add(pending);
            user.rewardClaimed = user.rewardClaimed.add(pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            if (user.amount == 0) {
                user.endTime = block.timestamp;
            }
            pool.totalTokenStaked = pool.totalTokenStaked.sub(_amount);

            pool.stakeToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e18);
        user.lastBlock = block.number;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.stakeToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function safeTokenTransfer(
        address _to,
        uint256 _amount,
        uint256 _pid
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 totalPoolReward = pool.allocPoint;

        if (_amount > totalPoolReward) {
            pool.rewardToken.transfer(_to, totalPoolReward);
        } else {
            pool.rewardToken.transfer(_to, _amount);
        }
    }

    function getPoolInfo(uint256 _pid)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            poolInfo[_pid].accTokenPerShare,
            poolInfo[_pid].lastRewardBlock,
            poolInfo[_pid].rewardPerBlock,
            poolInfo[_pid].totalTokenStaked,
            poolInfo[_pid].totalTokenClaimed
        );
    }

    function getDiffBlock(address user, uint256 pid)
        public
        view
        returns (uint256)
    {
        UserInfo memory user = userInfo[pid][user];
        return block.number.sub(user.lastBlock);
    }
}

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PolkaBridgeStaking.sol";

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

contract PolkabridgeLaunchPadV2 is Ownable, ReentrancyGuard {
    string public name = "PolkaBridge: LaunchPad V2";
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    address payable private ReceiveToken;

    struct IDOPool {
        uint256 Id;
        uint256 Begin;
        uint256 End;
        uint256 Type; //1: comminity round, 2 stackers round
        IERC20 IDOToken;
        uint256 MaxPurchaseTier1;
        uint256 MaxPurchaseTier2; //==comminity tier
        uint256 MaxPurchaseTier3;
        uint256 TotalCap;
        uint256 MinimumTokenSoldout;
        uint256 TotalToken; //total sale token for this pool
        uint256 RatePerETH;
        uint256 TotalSold; //total number of token sold
        uint256 MinimumStakeAmount;
    }

    struct ClaimInfo {
        uint256 ClaimTime1;
        uint256 PercentClaim1;
        uint256 ClaimTime2;
        uint256 PercentClaim2;
        uint256 ClaimTime3;
        uint256 PercentClaim3;
    }

    struct User {
        uint256 Id;
        address UserAddress;
        bool IsWhitelist;
        uint256 TotalTokenPurchase;
        uint256 TotalETHPurchase;
        uint256 PurchaseTime;
        uint256 LastClaimed;
        uint256 TotalPercentClaimed;
        uint256 NumberClaimed;
        bool IsActived;
    }

    mapping(uint256 => mapping(address => User)) public users; //poolid - listuser

    IDOPool[] pools;

    mapping(uint256 => ClaimInfo) public claimInfos; //pid

    constructor(address payable receiveTokenAdd) public {
        ReceiveToken = receiveTokenAdd;
    }

    function addMulWhitelist(address[] memory user, uint256 pid)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < user.length; i++) {
            users[pid][user[i]].Id = pid;
            users[pid][user[i]].UserAddress = user[i];
            users[pid][user[i]].IsWhitelist = true;
            users[pid][user[i]].IsActived = true;
        }
    }

    function updateWhitelist(
        address user,
        uint256 pid,
        bool isWhitelist,
        bool isActived
    ) public onlyOwner {
        users[pid][user].IsWhitelist = isWhitelist;
        users[pid][user].IsActived = isActived;
    }

    function IsWhitelist(
        address user,
        uint256 pid,
        uint256 stackAmount
    ) public view returns (bool) {
        uint256 poolIndex = pid.sub(1);
        if (pools[poolIndex].Type == 1) // community round
        {
            return true;
        } else if (pools[poolIndex].Type == 2) // stakers round
        {
            if (stackAmount >= pools[poolIndex].MinimumStakeAmount) return true;
            return false;
        } else if (pools[poolIndex].Type == 3) //internal
        {
            if (users[poolIndex][user].IsWhitelist) return true;
            return false;
        } else {
            return false;
        }
    }

    function addPool(
        uint256 begin,
        uint256 end,
        uint256 _type,
        IERC20 idoToken,
        uint256 maxPurchaseTier1,
        uint256 maxPurchaseTier2,
        uint256 maxPurchaseTier3,
        uint256 totalCap,
        uint256 totalToken,
        uint256 ratePerETH,
        uint256 minimumTokenSoldout,
        uint256 minimumStakeAmount
    ) public onlyOwner {
        uint256 id = pools.length.add(1);
        pools.push(
            IDOPool({
                Id: id,
                Begin: begin,
                End: end,
                Type: _type,
                IDOToken: idoToken,
                MaxPurchaseTier1: maxPurchaseTier1,
                MaxPurchaseTier2: maxPurchaseTier2,
                MaxPurchaseTier3: maxPurchaseTier3,
                TotalCap: totalCap,
                TotalToken: totalToken,
                RatePerETH: ratePerETH,
                TotalSold: 0,
                MinimumTokenSoldout: minimumTokenSoldout,
                MinimumStakeAmount: minimumStakeAmount
            })
        );
    }

    function addClaimInfo(
        uint256 percentClaim1,
        uint256 claimTime1,
        uint256 percentClaim2,
        uint256 claimTime2,
        uint256 percentClaim3,
        uint256 claimTime3,
        uint256 pid
    ) public onlyOwner {
        claimInfos[pid].ClaimTime1 = claimTime1;
        claimInfos[pid].PercentClaim1 = percentClaim1;
        claimInfos[pid].ClaimTime2 = claimTime2;
        claimInfos[pid].PercentClaim2 = percentClaim2;
        claimInfos[pid].ClaimTime3 = claimTime3;
        claimInfos[pid].PercentClaim3 = percentClaim3;
    }

    function updateClaimInfo(
        uint256 percentClaim1,
        uint256 claimTime1,
        uint256 percentClaim2,
        uint256 claimTime2,
        uint256 percentClaim3,
        uint256 claimTime3,
        uint256 pid
    ) public onlyOwner {
        if (claimTime1 > 0) {
            claimInfos[pid].ClaimTime1 = claimTime1;
        }

        if (percentClaim1 > 0) {
            claimInfos[pid].PercentClaim1 = percentClaim1;
        }
        if (claimTime2 > 0) {
            claimInfos[pid].ClaimTime2 = claimTime2;
        }

        if (percentClaim2 > 0) {
            claimInfos[pid].PercentClaim2 = percentClaim2;
        }

        if (claimTime3 > 0) {
            claimInfos[pid].ClaimTime3 = claimTime3;
        }

        if (percentClaim3 > 0) {
            claimInfos[pid].PercentClaim3 = percentClaim3;
        }
    }

    function updatePool(
        uint256 pid,
        uint256 begin,
        uint256 end,
        uint256 maxPurchaseTier1,
        uint256 maxPurchaseTier2,
        uint256 maxPurchaseTier3,
        uint256 totalCap,
        uint256 totalToken,
        uint256 ratePerETH,
        IERC20 idoToken,
        uint256 minimumTokenSoldout,
        uint256 pooltype,
        uint256 minimumStakeAmount
    ) public onlyOwner {
        uint256 poolIndex = pid.sub(1);
        if (begin > 0) {
            pools[poolIndex].Begin = begin;
        }
        if (end > 0) {
            pools[poolIndex].End = end;
        }

        if (maxPurchaseTier1 > 0) {
            pools[poolIndex].MaxPurchaseTier1 = maxPurchaseTier1;
        }
        if (maxPurchaseTier2 > 0) {
            pools[poolIndex].MaxPurchaseTier2 = maxPurchaseTier2;
        }
        if (maxPurchaseTier3 > 0) {
            pools[poolIndex].MaxPurchaseTier3 = maxPurchaseTier3;
        }
        if (totalCap > 0) {
            pools[poolIndex].TotalCap = totalCap;
        }
        if (totalToken > 0) {
            pools[poolIndex].TotalToken = totalToken;
        }
        if (ratePerETH > 0) {
            pools[poolIndex].RatePerETH = ratePerETH;
        }

        if (minimumStakeAmount > 0) {
            pools[poolIndex].MinimumStakeAmount = minimumStakeAmount;
        }

        if (minimumTokenSoldout > 0) {
            pools[poolIndex].MinimumTokenSoldout = minimumTokenSoldout;
        }
        if (pooltype > 0) {
            pools[poolIndex].Type = pooltype;
        }
        pools[poolIndex].IDOToken = idoToken;
    }

    function withdrawErc20(IERC20 token) public onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    //withdraw ETH after IDO
    function withdrawPoolFund() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "not enough fund");
        ReceiveToken.transfer(balance);
    }

    function purchaseIDO(
        uint256 stakeAmount,
        uint256 pid,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable nonReentrant {
        uint256 poolIndex = pid.sub(1);

        if (pools[poolIndex].Type == 2) {
            bytes32 hash = keccak256(abi.encodePacked(msg.sender, stakeAmount));
            bytes32 messageHash = hash.toEthSignedMessageHash();

            require(
                owner() == ecrecover(messageHash, v, r, s),
                "owner should sign purchase info"
            );
        }

        require(
            block.timestamp >= pools[poolIndex].Begin &&
                block.timestamp <= pools[poolIndex].End,
            "invalid time"
        );
        //check user
        require(IsWhitelist(msg.sender, pid, stakeAmount), "invalid user");

        //check amount
        uint256 ethAmount = msg.value;
        users[pid][msg.sender].TotalETHPurchase = users[pid][msg.sender]
            .TotalETHPurchase
            .add(ethAmount);

        if (pools[poolIndex].Type == 2) {
            //stackers round
            if (stakeAmount < 1500 * 1e18) {
                require(
                    users[pid][msg.sender].TotalETHPurchase <=
                        pools[poolIndex].MaxPurchaseTier1,
                    "invalid maximum purchase for tier1"
                );
            } else if (
                stakeAmount >= 1500 * 1e18 && stakeAmount < 3000 * 1e18
            ) {
                require(
                    users[pid][msg.sender].TotalETHPurchase <=
                        pools[poolIndex].MaxPurchaseTier2,
                    "invalid maximum purchase for tier2"
                );
            } else {
                require(
                    users[pid][msg.sender].TotalETHPurchase <=
                        pools[poolIndex].MaxPurchaseTier3,
                    "invalid maximum purchase for tier3"
                );
            }
        } else if (pools[poolIndex].Type == 1) {
            //community round

            require(
                users[pid][msg.sender].TotalETHPurchase <=
                    pools[poolIndex].MaxPurchaseTier2,
                "invalid maximum contribute"
            );
        } else {
            //=3
            require(
                users[pid][msg.sender].TotalETHPurchase <=
                    pools[poolIndex].MaxPurchaseTier3,
                "invalid maximum contribute"
            );
        }

        uint256 tokenAmount = ethAmount.mul(pools[poolIndex].RatePerETH).div(
            1e18
        );

        uint256 remainToken = getRemainIDOToken(pid);
        require(
            remainToken > pools[poolIndex].MinimumTokenSoldout,
            "IDO sold out"
        );
        require(remainToken >= tokenAmount, "IDO sold out");

        users[pid][msg.sender].TotalTokenPurchase = users[pid][msg.sender]
            .TotalTokenPurchase
            .add(tokenAmount);

        pools[poolIndex].TotalSold = pools[poolIndex].TotalSold.add(
            tokenAmount
        );
    }

    function claimToken(uint256 pid) public nonReentrant {
        require(
            users[pid][msg.sender].TotalPercentClaimed < 100,
            "you have claimed enough"
        );
        uint256 userBalance = getUserTotalPurchase(pid);
        require(userBalance > 0, "invalid claim");

        uint256 poolIndex = pid.sub(1);
        if (users[pid][msg.sender].NumberClaimed == 0) {
            require(
                block.timestamp >= claimInfos[poolIndex].ClaimTime1,
                "invalid time"
            );
            pools[poolIndex].IDOToken.safeTransfer(
                msg.sender,
                userBalance.mul(claimInfos[poolIndex].PercentClaim1).div(100)
            );
            users[pid][msg.sender].TotalPercentClaimed.add(
                claimInfos[poolIndex].PercentClaim1
            );
        } else if (users[pid][msg.sender].NumberClaimed == 1) {
            require(
                block.timestamp >= claimInfos[poolIndex].ClaimTime2,
                "invalid time"
            );
            pools[poolIndex].IDOToken.safeTransfer(
                msg.sender,
                userBalance.mul(claimInfos[poolIndex].PercentClaim2).div(100)
            );
            users[pid][msg.sender].TotalPercentClaimed.add(
                claimInfos[poolIndex].PercentClaim2
            );
        } else if (users[pid][msg.sender].NumberClaimed == 2) {
            require(
                block.timestamp >= claimInfos[poolIndex].ClaimTime3,
                "invalid time"
            );
            pools[poolIndex].IDOToken.safeTransfer(
                msg.sender,
                userBalance.mul(claimInfos[poolIndex].PercentClaim3).div(100)
            );
            users[pid][msg.sender].TotalPercentClaimed.add(
                claimInfos[poolIndex].PercentClaim3
            );
        }

        users[pid][msg.sender].LastClaimed = block.timestamp;
        users[pid][msg.sender].NumberClaimed.add(1);
    }

    function getUserTotalPurchase(uint256 pid) public view returns (uint256) {
        return users[pid][msg.sender].TotalTokenPurchase;
    }

    function getRemainIDOToken(uint256 pid) public view returns (uint256) {
        uint256 poolIndex = pid.sub(1);
        uint256 tokenBalance = getBalanceTokenByPoolId(pid);
        if (pools[poolIndex].TotalSold > tokenBalance) {
            return 0;
        }

        return tokenBalance.sub(pools[poolIndex].TotalSold);
    }

    function getBalanceTokenByPoolId(uint256 pid)
        public
        view
        returns (uint256)
    {
        uint256 poolIndex = pid.sub(1);

        return pools[poolIndex].TotalToken;
    }

    function getPoolInfo(uint256 pid)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            IERC20
        )
    {
        uint256 poolIndex = pid.sub(1);
        return (
            pools[poolIndex].Begin,
            pools[poolIndex].End,
            pools[poolIndex].Type,
            pools[poolIndex].RatePerETH,
            pools[poolIndex].TotalSold,
            pools[poolIndex].IDOToken
        );
    }

    function getClaimInfo(uint256 pid)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 poolIndex = pid.sub(1);
        return (
            claimInfos[poolIndex].ClaimTime1,
            claimInfos[poolIndex].PercentClaim1,
            claimInfos[poolIndex].ClaimTime2,
            claimInfos[poolIndex].PercentClaim2,
            claimInfos[poolIndex].ClaimTime3,
            claimInfos[poolIndex].PercentClaim3
        );
    }

    function getPoolSoldInfo(uint256 pid) public view returns (uint256) {
        uint256 poolIndex = pid.sub(1);
        return (pools[poolIndex].TotalSold);
    }

    function getWhitelistfo(uint256 pid)
        public
        view
        returns (
            address,
            bool,
            uint256,
            uint256
        )
    {
        return (
            users[pid][msg.sender].UserAddress,
            users[pid][msg.sender].IsWhitelist,
            users[pid][msg.sender].TotalTokenPurchase,
            users[pid][msg.sender].TotalETHPurchase
        );
    }

    function getUserInfo(uint256 pid, address user)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            users[pid][user].IsWhitelist,
            users[pid][user].TotalTokenPurchase,
            users[pid][user].TotalETHPurchase,
            users[pid][user].TotalPercentClaimed
        );
    }

    function addressToString(address _addr)
        public
        pure
        returns (string memory)
    {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}

pragma solidity >=0.6.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.6.0;


contract Context {
  
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address  private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;


interface IERC20 {
   
    function totalSupply() external view returns (uint256);

  
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);
   
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

