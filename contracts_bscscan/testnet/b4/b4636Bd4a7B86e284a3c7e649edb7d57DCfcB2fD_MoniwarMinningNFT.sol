// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./MowaCore.sol";
import "./IERC721.sol";

contract MoniwarMinningNFT is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 hashRate; // hashRate = level * star
    }
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    struct ListNFT {
        uint256 amountCalHashrate;
        uint256 amountDeposit;
        uint256 totalAmount;
        uint256 hashRate;
        uint256 tokenId;
    }

    mapping (uint256 => mapping(address => mapping(uint256 => ListNFT))) public listNFT;

    // Info of each pool.
    struct PoolInfo {
        uint256 startBlock; // Start block
        uint256 endBlock; // End block
        uint256 lastRewardBlock; // Last block number that MOWAs distribution occurs.
        uint256 totalReward;
        uint256 remainingReward;
        uint256 rewardPerBlock;
        uint256 accMowaPerShare; // Accumulated MOWAs per share, times 1e12. See below.
        uint256 totalAmount;
        uint256 totalHashRate;
    }
    PoolInfo[] public mowaPoolInfoNFT;

    // Info NFT
    struct PoolNFT {
        uint256 character;
        uint256 hashRate;
        uint256 price;
    }
    mapping(uint256 => PoolNFT) public poolNFT;

    // The MOWA TOKEN!
    IERC20 public mowaToken;
    // The MOWA NFT Core!
    MowaCore public mowaNFTCore;

    // The MOWA NFT!
    IERC721 public mowaNFT;
    // Fee harvest
    uint256 feeHarvest = 15;
    // Fee stake
    uint256 feeStake = 1 * 10**18;

    address public feeHarvestWallet = 0xAC29547f8BF4F3f3Aa52DD1C1469c9eEE2fC4Da0;
    address public feeStakeWallet = 0x385809F4A8867Eb170A0C78772D9A13f3276C290;

    uint256 totalPool = 10;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositNFT(address indexed user, uint256 indexed pid, uint256 indexed uid, uint256 tokenId);
    event UnstakeNFT(address indexed user, uint256 indexed pid, uint256 indexed uid, uint256 tokenId);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardsHarvested(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _mowaToken,
        MowaCore _mowaNFTCore,
        IERC721 _mowaNFT
    ) public {
        mowaToken = _mowaToken;
        mowaNFT = _mowaNFT;
        mowaNFTCore = MowaCore(_mowaNFTCore);
        poolNFT[0]  = PoolNFT(0, 50, 210 * 10**18);
        poolNFT[1]  = PoolNFT(1, 50, 210 * 10**18);
        poolNFT[2]  = PoolNFT(2, 50, 210 * 10**18);
        poolNFT[3]  = PoolNFT(3, 50, 210 * 10**18);
        poolNFT[4]  = PoolNFT(4, 50, 210 * 10**18);
        poolNFT[5]  = PoolNFT(5, 50, 210 * 10**18);
        poolNFT[6]  = PoolNFT(6, 50, 210 * 10**18);
        poolNFT[7]  = PoolNFT(7, 50, 210 * 10**18);
        poolNFT[8]  = PoolNFT(8, 5, 28.98 * 10**18);
        poolNFT[9]  = PoolNFT(9, 5, 28.98 * 10**18);
        poolNFT[10] = PoolNFT(10, 140, 483 * 10**18);
        poolNFT[11] = PoolNFT(11, 140, 483 * 10**18);
        poolNFT[12] = PoolNFT(12, 140, 483 * 10**18);
        poolNFT[13] = PoolNFT(13, 240, 787.5 * 10**18);
        poolNFT[14] = PoolNFT(14, 50, 210 * 10**18);
        poolNFT[15] = PoolNFT(15, 50, 210 * 10**18);
        poolNFT[16] = PoolNFT(16, 50, 210 * 10**18);
        poolNFT[17] = PoolNFT(17, 140, 483 * 10**18);
        poolNFT[18] = PoolNFT(18, 240, 787.5 * 10**18);
        poolNFT[19] = PoolNFT(19, 50, 210 * 10**18);
        poolNFT[20] = PoolNFT(20, 50, 210 * 10**18);
        poolNFT[21] = PoolNFT(21, 50, 210 * 10**18);
        poolNFT[22] = PoolNFT(22, 140, 483 * 10**18);
        poolNFT[23] = PoolNFT(23, 240, 787.5 * 10**18);
    }

    function setPriceNFT(uint256 character, uint256 price) public onlyOwner {
        poolNFT[character].price = price.mul(1e18);
    }

    function setHashrateNFT(uint256 character, uint256 hashRate) public onlyOwner {
        poolNFT[character].hashRate = hashRate;
    }

    function setNFTInList(uint256 character, uint256 hashRate, uint256 price) public onlyOwner {
        require(poolNFT[character].hashRate == 0, "NFT has in pool");
        poolNFT[character] = PoolNFT(character, hashRate, price.mul(1e18));
    }

    // Add a new pool. Can only be called by the owner.
    function add(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _totalReward,
        uint256 _rewardPerBlock
    ) public onlyOwner {
        uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
        mowaPoolInfoNFT.push(
            PoolInfo({
                lastRewardBlock : lastRewardBlock,
                accMowaPerShare : 0,
                startBlock : _startBlock,
                endBlock : _endBlock,
                totalReward: _totalReward.mul(1e18),
                remainingReward: _totalReward.mul(1e18),
                rewardPerBlock : _rewardPerBlock,
                totalAmount : 0,
                totalHashRate : 0
            })
        );
    }

    // Update the given pool's MOWA allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _totalReward,
        uint256 _rewardPerBlock,
        bool _withUpdate
    ) public onlyOwner {
        if (_startBlock > 0) {
            mowaPoolInfoNFT[_pid].startBlock = _startBlock;
        }
        if (_endBlock > 0) {
            mowaPoolInfoNFT[_pid].endBlock = _endBlock;
        }
        if (_totalReward > 0) {
            mowaPoolInfoNFT[_pid].totalReward = _totalReward.mul(1e18);
            mowaPoolInfoNFT[_pid].remainingReward = _totalReward.mul(1e18);
        }
        if (_rewardPerBlock > 0) {
            mowaPoolInfoNFT[_pid].rewardPerBlock = _rewardPerBlock;
        }
        if (_withUpdate) {
            updatePool(_pid);
        }
    }

    function setTotalPool(uint256 _total) public onlyOwner {
        totalPool = _total;
    }

    function getUserInfo(uint256 pid, address _userAddress) public view returns (ListNFT[] memory)
    {
        ListNFT[] memory list = new ListNFT[](totalPool);
        for (uint256 index = 0; index < totalPool; index++) {
            list[index] = listNFT[pid][_userAddress][index];
        }
        return list;
    }

    function getUserTokenId(uint256 pid, uint256 uid, address _userAddress) public view returns (uint256 tokenId)
    {
        return listNFT[pid][_userAddress][uid].tokenId;
    }

    function getPriceUpgrade(uint256 pid, uint256 uid, address _userAddress) public view returns (uint256 price)
    {
        return listNFT[pid][_userAddress][uid].amountCalHashrate;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256)
    {
        return _to.sub(_from);
    }

    // calculator
    function calculator(uint256 _pid, uint256 date, uint256 hashrate) external view returns (uint256) {
        uint256 blockCal = date.mul(86400).div(3);
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        uint256 totalHahrate = hashrate.add(pool.totalHashRate);
        uint256 accMowaPerShare = pool.accMowaPerShare;
        uint256 mowaReward = blockCal.mul(pool.rewardPerBlock);
        accMowaPerShare = accMowaPerShare.add(mowaReward.mul(1e12).div(totalHahrate));
        return hashrate.mul(accMowaPerShare).div(1e12);
    }

    function getEndBlock(uint256 _pid) external view returns (uint256) {
        return mowaPoolInfoNFT[_pid].endBlock.sub(block.number);
    }

    // View function to see pending MOWAs on frontend.
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256)
    {
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 pending = user.rewardLockedUp;
        if (
            user.hashRate == 0 ||
            block.number < pool.startBlock ||
            block.number >= pool.endBlock
        ) {
            return pending;
        }
        uint256 accMowaPerShare = pool.accMowaPerShare;
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 mowaReward = multiplier.mul(pool.rewardPerBlock);

        accMowaPerShare = accMowaPerShare.add(mowaReward).mul(1e12).div(pool.totalHashRate);
        pending = user.hashRate.mul(accMowaPerShare).div(1e12).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        if (block.number < pool.lastRewardBlock) {
            return;
        }
        if (block.number >= pool.endBlock) {
            pool.rewardPerBlock = 0;
            return;
        }
        if (pool.totalHashRate == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 mowaReward = multiplier.mul(pool.rewardPerBlock);
        pool.accMowaPerShare = pool.accMowaPerShare.add(mowaReward).mul(1e12).div(pool.totalHashRate);
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for MOWA allocation.
    function upgrade(uint256 _pid, uint256 uid, uint256 number) public nonReentrant {
        require(number == 2 ||  number == 5 || number == 10, "Number not yet");
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        require(block.number < pool.endBlock, "pool has ended");
        ListNFT storage list = listNFT[_pid][msg.sender][uid];
        uint256 amountCalHashrate = list.amountCalHashrate;
        uint256 hashRate = list.hashRate;
        uint256 tokenId = list.tokenId;

        require(tokenId > 0, "nft not stake pool");
        uint256 amountUpgarade = 0;
        if(number == 2){
            amountUpgarade = amountCalHashrate.mul(number).mul(95).div(100);
        } else if(number == 5){
            amountUpgarade = amountCalHashrate.mul(number).mul(9).div(10);
        } else {
            amountUpgarade = amountCalHashrate.mul(number).mul(75).div(100);
        }

        uint256 hashRateUpgrade = hashRate.mul(number);
        uint256 mowaBal = mowaToken.balanceOf(address(msg.sender));
        require(mowaBal >= amountUpgarade, "Insufficient funds in the account");
        mowaToken.transferFrom(address(msg.sender), address(this), amountUpgarade);

        updatePool(_pid);
        payOrLockupPendingMowa(_pid);

        uint256 amoutsendwithfee = amountUpgarade.mul(10).div(1000);
        list.amountDeposit = list.amountDeposit.add(amountUpgarade).sub(amoutsendwithfee);
        list.amountCalHashrate = amountUpgarade;
        list.totalAmount = list.totalAmount.add(amountUpgarade);
        list.hashRate = hashRateUpgrade;

        UserInfo storage user = userInfo[_pid][msg.sender];
        user.amount = user.amount.add(amountUpgarade).sub(amoutsendwithfee);
        user.hashRate = user.hashRate.sub(hashRate).add(hashRateUpgrade);
        pool.totalAmount = pool.totalAmount.add(amountUpgarade);
        pool.totalHashRate = pool.totalHashRate.sub(hashRate).add(hashRateUpgrade);
//        user.rewardDebt = user.hashRate.mul(pool.accMowaPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, user.amount);
    }

    // Stake NFT
    function depositNFT(uint256 _pid, uint256 uid, uint256 _tokenId) public nonReentrant {
        require(_tokenId > 0, "tokenID not NFT");
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        require(block.number < pool.endBlock, "pool has ended");
        require(mowaNFT.ownerOf(_tokenId) == msg.sender, "not own");

        ListNFT storage list = listNFT[_pid][msg.sender][uid];
        require(list.tokenId == 0, "already stake this nft");
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 characterNFT = mowaNFTCore.getNFT(_tokenId).character;
        uint256 hashRate = poolNFT[characterNFT].hashRate;
        require(hashRate > 0, "NFT not define");

        bool checkToken = false;
        for (uint256 index = 0; index < totalPool; index++) {
            if(listNFT[_pid][msg.sender][index].tokenId == _tokenId){
                checkToken = true;
            }
        }
        require(checkToken == false, "already stake this nft");

        if(feeStake > 0){
            uint256 mowaBal = mowaToken.balanceOf(address(msg.sender));
            require(mowaBal >= feeStake, "Insufficient funds in the account");
            mowaToken.transferFrom(address(msg.sender), feeStakeWallet, feeStake);
        }
        updatePool(_pid);
        payOrLockupPendingMowa(_pid);
        uint256 amount = poolNFT[characterNFT].price;
        mowaNFT.transferFrom(address(msg.sender), address(this), _tokenId);

        list.tokenId = _tokenId;
        list.amountCalHashrate = amount;
        list.totalAmount = amount;
        list.amountDeposit = 0;
        list.hashRate = hashRate;

        user.hashRate = user.hashRate.add(hashRate);
        pool.totalAmount = pool.totalAmount.add(amount);
        pool.totalHashRate = pool.totalHashRate.add(hashRate);
        emit DepositNFT(msg.sender, _pid, uid, _tokenId);
    }

    //Harvest proceeds msg.sender
    function harvest(uint256 _pid) public nonReentrant {
        updatePool(_pid);
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(block.number >= pool.startBlock, "pool not start");

        uint256 pending = 0;
        if (user.hashRate == 0 || block.number >= pool.endBlock) {
            pending = user.rewardLockedUp;
        } else {
            pending = user.hashRate.mul(pool.accMowaPerShare).div(1e12).sub(user.rewardDebt);
            pending = pending.add(user.rewardLockedUp);
        }
        if (pending > 0) {
            if(pending > pool.remainingReward){
                pending = pool.remainingReward;
            }
            if (feeHarvest > 0) {
                uint256 harvestFee = pending.mul(feeHarvest).div(1000);
                safeMowaTransfer(feeHarvestWallet, harvestFee);
                safeMowaTransfer(msg.sender, pending.sub(harvestFee));
            } else {
                safeMowaTransfer(msg.sender, pending);
            }
            pool.remainingReward = pool.remainingReward.sub(pending);
        }

        user.rewardLockedUp = 0;
        user.rewardDebt = pending;
        emit RewardsHarvested(msg.sender, _pid, pending);
    }

    //Harvest proceeds msg.sender
    function unStake(uint256 _pid, uint256 uid) public nonReentrant {
        updatePool(_pid);
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        ListNFT storage list = listNFT[_pid][msg.sender][uid];

        uint256 amount = list.amountDeposit;
        uint256 hashRate = list.hashRate;
        uint256 _tokenId = list.tokenId;

        require(_tokenId > 0, "nft not stake pool");
        mowaNFT.transferFrom(address(this), msg.sender, _tokenId);
        payOrLockupPendingMowa(_pid);

        if (amount > 0) {
            safeMowaTransfer(address(msg.sender), amount);
            user.amount = user.amount.sub(amount);
        }

        if(list.totalAmount > 0){
            pool.totalAmount = pool.totalAmount.sub(list.totalAmount);
        }

        user.hashRate = user.hashRate.sub(hashRate);
        pool.totalHashRate = pool.totalHashRate.sub(hashRate);

        list.tokenId = 0;
        list.amountCalHashrate = 0;
        list.amountDeposit = 0;
        list.hashRate = 0;
        list.totalAmount = 0;

        emit UnstakeNFT(msg.sender, _pid, uid, _tokenId);
    }

    // Pay or lockup pending MOWAs.
    function payOrLockupPendingMowa(uint256 _pid) internal {
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(block.number >= pool.startBlock, "pool not start");
        uint256 pending = 0;
        if (user.hashRate == 0 || block.number >= pool.endBlock) {
            pending = user.rewardLockedUp;
        } else {
            pending = user.hashRate.mul(pool.accMowaPerShare).div(1e12).sub(user.rewardDebt);
            pending = pending.add(user.rewardLockedUp);
            user.rewardDebt = pending;
        }
        user.rewardLockedUp = pending;
    }

    // Safe mowa transfer function, just in case if rounding error causes pool to not have enough MOWAs.
    function safeMowaTransfer(address _to, uint256 _amount) internal {
        uint256 mowaBal = mowaToken.balanceOf(address(this));
        if (_amount > mowaBal) {
            mowaToken.transfer(_to, mowaBal);
        } else {
            mowaToken.transfer(_to, _amount);
        }
    }

    function setFeeHarvestWallet(address _addr) external onlyOwner {
        feeHarvestWallet = _addr;
    }

    function setFeeStakeWallet(address _addr) external onlyOwner {
        feeStakeWallet = _addr;
    }

    function setFeeStake(uint256 _feeStake) external onlyOwner {
        feeStake = _feeStake.mul(1e18);
    }

    function setFeeHarvest(uint256 _fee) external onlyOwner {
        feeHarvest = _fee;
    }

    /**
     * @dev Withdraw bnb from this contract (Callable by owner only)
     */
    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) public onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IERC20(coinAddress).transfer(to, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "./Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
 
abstract contract Ownable is Context {
    address private _owner;

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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }    
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

    struct Mowa {
        uint256 tokenId;
        uint256 level;
        uint256 skill;
        uint256 star;
        uint256 character;
        uint256 class;
        uint256 bornTime;
    }

    struct User {
        Mowa[] mowas;
        address owner;
    }

interface MowaCore {
    function changeLevel(
        uint256 _tokenId,
        address _owner,
        uint256 _level
    ) external;

    function changeClass(
        uint256 _tokenId,
        address _owner,
        uint256 _class
    ) external;

    function changeSkill(
        uint256 _tokenId,
        address _owner,
        uint256 _skill
    ) external;

    function changeCharacter(
        uint256 _tokenId,
        address _owner,
        uint256 _character
    ) external;

    function changeStar(
        uint256 _tokenId,
        address _owner,
        uint256 _star
    ) external;

    function getNFT(uint256 _tokenId) external view returns (Mowa memory);

    function setNFTFactory(Mowa memory _mowa, uint256 _tokenId) external;

    function setNFTForUser(
        Mowa memory _mowa,
        uint256 _tokenId,
        address _userAddress
    ) external;

    function safeMintNFT(address _addr, uint256 tokenId) external;

    function getAllNFT(uint256 _fromTokenId, uint256 _toTokenId) external view returns (Mowa[] memory);

    function getUser(address _userAddress) external view returns (User memory userInfo);
    function getNextNFTId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}