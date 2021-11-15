// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./Ownable.sol";
import "./IGSB.sol";
import "./IInspirePool.sol";

contract InspirePoolV3 is Ownable, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IGSB;
    
    uint256 public constant MAX_MINT_AMOUNT = 120000000e18; // 该池最大挖币数，挖完为止
    uint256 public constant INIT_PER_DAY = 10000e18; // 初始挖矿速度为1W枚每天
    uint256 public constant MAX_PER_DAY = 30000e18; // 最大挖矿速度为3W枚每天
    uint256 public constant ADDER = 300000e18; // 每增加300000U，挖矿速度增加3000枚/天
    uint256 public constant INCREASER = 3000e18; // 每增加30000U，挖矿速度增加3000枚/天
    uint256 public constant THREE_DAY_BLOCK = 28800 * 3; // 用户一次最多提取3天的GSB奖励，每天5%
    uint256 public totalAmount; // BUSD池和GSB池累积的总价值，GSB按照投资时的价格计算
    uint256 public totalAmountBusd;
    uint256 public totalAmountGsb;
    uint256 public gsbPerBlock; // 每区块产币数，根据BUSD池和GSB池的累积投入金额进行增长
    uint256 public burnNum; // 烧毁GSB数量
    uint256 public lastRewardBlock;
    uint256 public startBlock;
    uint256 public accGsbPerShare;
    uint256 public hasMintAmount; // 已挖出多少GSB
    uint256 public userCount;
    bool public paused;
    
    address public gsbBusdLp;
    address public teamer;
    
    IGSB public gsb;
    IERC20 public busd;
    // TODO
    IInspirePool private constant ipool = IInspirePool(0x0e8cC1ccC0e78b44396554dA8DB118b37D18588d);
    
    struct User {
        uint256 id;
        address refer; // 邀请人地址
        uint256 directPushNum; // 直推人数，直推一人拿一代。。。。。
        uint256 teamAmount; // 团队业绩
        uint256 totalAmount; // 购买金额
        uint256 amountBusd;
        uint256 amountGsb;
        uint256 referRewardBusd; // BUSD Pool邀请奖励
        uint256 hasWithdrawBusd;
        uint256 referRewardGsb; // GSB Pool邀请奖励
        uint256 hasWithdrawGsb;
        uint256 lastRewardBlockGsb;
        uint256 rewardDebt; // Reward debt.
        uint256 isMigrate; // 从2.0迁移到3.0，1代表已迁移完
    }
    mapping(address => User) public userMap;
    
    struct UserMining {
        uint256 amount;
        uint256 rewardDebt; // Reward debt.
        uint256 blockNumber;
    }
    mapping(address => mapping(uint256 => UserMining)) public userMiningMap;
    mapping(address => uint256) public userMiningCountMap;
    
    event Deposit(address indexed _user, uint256 indexed _amount);
    event Withdraw(address indexed _user, uint256 indexed _amount);
    
    /*constructor(IGSB _gsb, IERC20 _busd, address _teamer) {
        gsb = _gsb;
        busd = _busd;
        teamer = _teamer;
        gsbPerBlock = INIT_PER_DAY / 28800;
        startBlock = block.number;
        lastRewardBlock = block.number;
    }*/
    
    function initialize() external initializer {
        totalAmount = ipool.totalAmount();
        totalAmountBusd = ipool.totalAmountBusd();
        totalAmountGsb = ipool.totalAmountGsb();
        burnNum = ipool.burnNum();
        hasMintAmount = ipool.hasMintAmount();
        userCount = ipool.userCount();
        gsbBusdLp = ipool.gsbBusdLp();
        teamer = ipool.teamer();
        gsb = IGSB(ipool.gsb());
        busd = IGSB(ipool.busd());
        startBlock = ipool.startBlock();
        
        _setOwner(_msgSender());
        accGsbPerShare = 0;
        gsbPerBlock = INIT_PER_DAY / 28800;
        lastRewardBlock = block.number;
        paused = false;
    }
    
    function migrate() external {
        address _user = _msgSender();
        require(userMap[_user].isMigrate == 0, "only migrate once");
        IInspirePool.User memory userOld = ipool.userMap(_user);
        uint256 _totalAmount = userOld.totalAmount;
        require(_totalAmount > 0, "can not migrate");
        address _refer = userOld.refer;
        userMap[_user].id = userOld.id;
        userMap[_user].refer = _refer;
        userMap[_user].directPushNum = userOld.directPushNum;
        userMap[_user].totalAmount = _totalAmount;
        userMap[_user].amountBusd = userOld.amountBusd;
        userMap[_user].isMigrate = 1;
        
        /*userMap[_user] = User({
            id : userOld.id,
            refer : _refer,
            directPushNum : userOld.directPushNum,
            teamAmount : 0,
            totalAmount : userOld.totalAmount,
            amountBusd : userOld.amountBusd,
            amountGsb : userOld.amountGsb,
            referRewardBusd : 0,
            hasWithdrawBusd : 0,
            referRewardGsb : 0,
            hasWithdrawGsb : 0,
            lastRewardBlockGsb : 0,
            rewardDebt : 0,
            isMigrate : 1
        });*/
        
        // 迁移完成后才能质押，迁移过来的数据是第一台矿机
        update();
        userMiningCountMap[_user] = 1;
        userMiningMap[_user][1].amount = _totalAmount;
        userMiningMap[_user][1].rewardDebt = _totalAmount.mul(accGsbPerShare).div(1e12);
        userMiningMap[_user][1].blockNumber = block.number;
        
        _calTeamAmountOld(_refer, _totalAmount);
    }
    
    function _calTeamAmountOld(address _user, uint256 _amount) private {
        for (uint256 i = 1; i <= 30; i++) {
            if (_user == address(0)) {
                return;
            }
            userMap[_user].teamAmount = userMap[_user].teamAmount.add(_amount);
            IInspirePool.User memory userOld = ipool.userMap(_user);
            _user = userOld.refer;
        }
    }
    
    function pending(address _user, uint256 _count) public view returns (uint256) {
        UserMining storage user = userMiningMap[_user][_count];
        uint256 _accGsbPerShare = accGsbPerShare;
        if (user.amount > 0) {
            if (block.number > lastRewardBlock) {
                if (hasMintAmount < MAX_MINT_AMOUNT) {
                    uint256 blockReward = getGsbBlockReward(lastRewardBlock);
                    if (hasMintAmount.add(blockReward) > MAX_MINT_AMOUNT) {
                        blockReward = MAX_MINT_AMOUNT.sub(hasMintAmount);
                    }
                    _accGsbPerShare = _accGsbPerShare.add(blockReward.mul(1e12).div(totalAmount));
                }
            }
            uint256 _sub = _pendingAmountSub(user.blockNumber);
            return (user.amount.mul(_accGsbPerShare).div(1e12).sub(user.rewardDebt)).mul(_sub).div(1000);
        }
        return 0;
    }
    
    function depositBusd(uint256 _amount, address _refer) public notPause {
        address _user = _msgSender();
        _migrateComplete(_user);
        require(_amount >= 500e18, "At least 500 BUSD");
        _bindRefer(_user, _refer);
        User storage user = userMap[_user];
        update();
        /*if (user.totalAmount > 0) {
            uint256 pendingAmount = user.totalAmount.mul(accGsbPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingAmount > 0) {
                safeGsbTransfer(_user, pendingAmount);
            }
        }*/
        busd.safeTransferFrom(_user, address(this), _amount);
        user.amountBusd = user.amountBusd.add(_amount);
        user.totalAmount = user.totalAmount.add(_amount);
        totalAmount = totalAmount.add(_amount);
        totalAmountBusd = totalAmountBusd.add(_amount);
        user.rewardDebt = user.totalAmount.mul(accGsbPerShare).div(1e12);
        
        _addMing(_user, _amount);
        
        _calReferProfit(address(busd), _user, _amount, _amount); // 计算所有上级的收益
        _calGsbPerBlock();  // 重新计算gsbPerBlock
        emit Deposit(_user, _amount);
    }
    
    function depositGsb(uint256 _amount1, address _refer) public notPause {
        address _user = _msgSender();
        _migrateComplete(_user);
        uint256 _amount = _amount1.mul(gsbPriceInBusd()).div(1e18);
        require(_amount >= 500e18, "At least 500 BUSD");
        _bindRefer(_user, _refer);
        User storage user = userMap[_user];
        if (user.amountGsb == 0) {
            user.lastRewardBlockGsb = block.number;
        }
        update();
        /*if (user.totalAmount > 0) {
            uint256 pendingAmount = user.totalAmount.mul(accGsbPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingAmount > 0) {
                safeGsbTransfer(_user, pendingAmount);
            }
        }*/
        gsb.safeTransferFrom(_user, address(this), _amount1);
        user.amountGsb = user.amountGsb.add(_amount1);
        user.totalAmount = user.totalAmount.add(_amount);
        totalAmount = totalAmount.add(_amount);
        totalAmountGsb = totalAmountGsb.add(_amount1);
        user.rewardDebt = user.totalAmount.mul(accGsbPerShare).div(1e12);
        
        _addMing(_user, _amount);
        
        _calReferProfit(address(gsb), _user, _amount1, _amount); // 计算所有上级的收益
        _calGsbPerBlock();  // 重新计算gsbPerBlock
        emit Deposit(_user, _amount);
    }
    
    function _addMing(address _user, uint256 _amount) private {
        userMiningCountMap[_user] = userMiningCountMap[_user] + 1;
        uint256 _count = userMiningCountMap[_user];
        userMiningMap[_user][_count].amount = userMiningMap[_user][_count].amount.add(_amount);
        userMiningMap[_user][_count].rewardDebt = userMiningMap[_user][_count].amount.mul(accGsbPerShare).div(1e12);
        userMiningMap[_user][_count].blockNumber = block.number;
    }
    
    // 迁移完成后才能质押
    function _migrateComplete(address _user) internal view {
        IInspirePool.User memory userOld = ipool.userMap(_user);
        if (userOld.totalAmount > 0) {
            require(userMap[_user].isMigrate == 1, "Pledge only after migration");
        }
    }
    
    function withdraw(uint256 _miningCount) public notPause {
        address _user = _msgSender();
        UserMining storage user = userMiningMap[_user][_miningCount];
        require(user.amount > 0, "withdraw: not good");
        update();
        uint256 pendingAmount = user.amount.mul(accGsbPerShare).div(1e12).sub(user.rewardDebt);
        if (pendingAmount > 0) {
            uint256 _sub = _pendingAmountSub(user.blockNumber);
            safeGsbTransfer(_user, pendingAmount.mul(_sub).div(1000));
        }
        user.rewardDebt = user.amount.mul(accGsbPerShare).div(1e12);
        emit Withdraw(_user, pendingAmount);
    }
    
    function _pendingAmountSub(uint256 _blockNumber) internal view returns (uint256) {
        uint256 _sub = 1000;
        if (block.number > _blockNumber) {
            uint256 _diff = block.number.sub(_blockNumber);
            uint256 _days = _diff / 28800;
            if (_days > 0 && _days < _sub) {
                _sub = _sub - _days;
            } else if (_days >= _sub) {
                _sub = 0;
            }
        }
        return _sub;
    }
    
    // 提取BUSD的邀请奖励
    function withdrawBusdReward() public notPause {
        address _user = _msgSender();
        User storage user = userMap[_user];
        uint256 _referRewardBusd = user.referRewardBusd;
        require(_referRewardBusd > 0, "withdrawBusdReward: not good");
        user.referRewardBusd = 0;
        user.hasWithdrawBusd = user.hasWithdrawBusd.add(_referRewardBusd);
        busd.safeTransfer(_user, _referRewardBusd);
    }
    
    
    // 提取GSB的邀请奖励
    function withdrawGsbReward() public notPause {
        address _user = _msgSender();
        User storage user = userMap[_user];
        uint256 _referRewardGsb = user.referRewardGsb;
        uint256 _lastRewardBlockGsb = user.lastRewardBlockGsb;
        require(_referRewardGsb > 0, "withdrawGsbReward: not good");
        
        if (block.number > _lastRewardBlockGsb) {
            uint256 _diff = block.number.sub(_lastRewardBlockGsb);
            if (_diff > THREE_DAY_BLOCK) {
                _diff = THREE_DAY_BLOCK;
            }
            uint256 _accGsbPerBlock = _referRewardGsb.mul(5).mul(1e12).div(100).div(28800);
            uint256 _reward = _diff.mul(_accGsbPerBlock).div(1e12);
            user.referRewardGsb = user.referRewardGsb.sub(_reward);
            user.hasWithdrawGsb = user.hasWithdrawGsb.add(_reward);
            user.lastRewardBlockGsb = block.number;
            gsb.safeTransfer(_user, _reward);
        }
    }
    
    // 当前能够提取的GSB
    function pendingGsb(address _user) public view returns (uint256) {
        User storage user = userMap[_user];
        uint256 _referRewardGsb = user.referRewardGsb;
        if (_referRewardGsb == 0) {
            return 0;
        }
        if (block.number <= user.lastRewardBlockGsb) {
            return 0;
        }
        uint256 _diff = block.number.sub(user.lastRewardBlockGsb);
        if (_diff > THREE_DAY_BLOCK) {
            _diff = THREE_DAY_BLOCK;
        }
        uint256 _accGsbPerBlock = _referRewardGsb.mul(5).mul(1e12).div(100).div(28800);
        return _diff.mul(_accGsbPerBlock).div(1e12);
    }

    // times 1e18
    function gsbPriceInBusd() view public returns (uint256) {
        if (gsbBusdLp == address(0)) {
            return 0;
        }
        return busd.balanceOf(gsbBusdLp).mul(1e18).div(gsb.balanceOf(gsbBusdLp));
    }

    // 计算所有上级的收益
    function _calReferProfit(address _token, address _user, uint256 _amount, uint256 _amountBusd) private {
        uint256 _remaning = _amount; // 剩余部分全部转到团队地址
        for (uint256 i = 1; i <= 30; i++) {
            address _refer = userMap[_user].refer;
            if (userMap[_refer].id == 0) {
                break;
            }
            userMap[_refer].teamAmount = userMap[_refer].teamAmount.add(_amountBusd);
            
            if (userMap[_refer].directPushNum >= i) {
                uint256 _profitCoefficient = profitCoefficient(i);
                uint256 _profit = _amount.mul(6).mul(_profitCoefficient).div(1000).div(10);
                if (_token == address(busd)) {
                    uint256 _referRewardBusd = userMap[_refer].referRewardBusd;
                    {
                        uint256 _totalReward = userMap[_refer].amountBusd.mul(3);
                        uint256 _hasWithdrawBusd = userMap[_refer].hasWithdrawBusd;
                        if (_referRewardBusd.add(_hasWithdrawBusd) >= _totalReward) {
                            _profit = 0;
                        } else {
                            if (_referRewardBusd.add(_hasWithdrawBusd).add(_profit) > _totalReward) {
                                _profit = _totalReward.sub(_referRewardBusd).sub(_hasWithdrawBusd);
                            }
                        }
                    }
                    if (_profit > 0) {
                        userMap[_refer].referRewardBusd = _referRewardBusd.add(_profit);
                    }
                } else if (_token == address(gsb)) {
                    uint256 _referRewardGsb = userMap[_refer].referRewardGsb;
                    {
                        uint256 _totalReward = userMap[_refer].amountGsb.mul(3);
                        uint256 _hasWithdrawGsb = userMap[_refer].hasWithdrawGsb;
                        if (_referRewardGsb.add(_hasWithdrawGsb) >= _totalReward) {
                            _profit = 0;
                        } else {
                            if (_referRewardGsb.add(_hasWithdrawGsb).add(_profit) > _totalReward) {
                                _profit = _totalReward.sub(_referRewardGsb).sub(_hasWithdrawGsb);
                            }
                        }
                    }
                    if (_profit > 0) {
                        userMap[_refer].referRewardGsb = _referRewardGsb.add(_profit);
                    }
                }
                _remaning = _remaning.sub(_profit);
            }
            _user = _refer;
        }
        
        // 销毁35%的GSB
        if (_token == address(gsb)) {
            uint256 _burnNum = _amount.mul(35).div(100);
            gsb.burn(_burnNum);
            _remaning = _remaning.sub(_burnNum);
            burnNum = burnNum.add(_burnNum);
        }
        if (_remaning > 0) {
            IERC20(_token).safeTransfer(teamer, _remaning);
        }
    }
    
    // 计算gsbPerBlock
    function _calGsbPerBlock() private {
        uint256 _totalAmount = totalAmount;
        uint256 _add = _totalAmount.div(ADDER).mul(INCREASER);
        if (_add > 0) {
            uint256 _perDay = INIT_PER_DAY.add(_add);
            if (_perDay > MAX_PER_DAY) {
                _perDay = MAX_PER_DAY;
            }
            gsbPerBlock = _perDay / 28800;
        }
    }
    
    // 推荐奖励系统，放大1000倍
    function profitCoefficient(uint256 i) private pure returns (uint256) {
        if (i == 1) {
            return 150;
        } else if ( i == 2) {
            return 110;
        } else if ( i == 3) {
            return 100;
        } else if ( i == 4) {
            return 90;
        } else if ( i == 5) {
            return 80;
        } else if ( i == 6) {
            return 70;
        } else if ( i == 7) {
            return 60;
        } else if ( i == 8) {
            return 50;
        } else if ( i == 9) {
            return 40;
        } else if ( i == 10) {
            return 30;
        } else if ( i == 11 || i == 12) {
            return 20;
        } else {
            return 10;
        }
    }

    function update() public {
        if (hasMintAmount >= MAX_MINT_AMOUNT) {
            return;
        }
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (totalAmount == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 blockReward = getGsbBlockReward(lastRewardBlock);
        if (hasMintAmount.add(blockReward) > MAX_MINT_AMOUNT) {
            blockReward = MAX_MINT_AMOUNT.sub(hasMintAmount);
        }
        if (blockReward <= 0) {
            return;
        }
        bool minRet = gsb.mint(address(this), blockReward);
        if (minRet) {
            hasMintAmount = hasMintAmount.add(blockReward);
            accGsbPerShare = accGsbPerShare.add(blockReward.mul(1e12).div(totalAmount));
        }
        lastRewardBlock = block.number;
    }
    
    function getGsbBlockReward(uint256 _lastRewardBlock) public view returns (uint256) {
        return (block.number.sub(_lastRewardBlock)).mul(gsbPerBlock);
    }
    
    function safeGsbTransfer(address _to, uint256 _amount) internal {
        uint256 bal = gsb.balanceOf(address(this));
        if (_amount > bal) {
            gsb.transfer(_to, bal);
        } else {
            gsb.transfer(_to, _amount);
        }
    }
    
    function _bindRefer(address _user, address _refer) private {
        if (userMap[_user].id == 0) {
            // new user
            userCount++;
            userMap[_user].id = userCount;
            if (userMap[_refer].id > 0) {
                // refer is old user
                userMap[_user].refer = _refer;
                userMap[_refer].directPushNum++;
            }
        }
    }
    
    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }
    
    function setPause() public onlyOwner {
        paused = !paused;
    }
    
    function setGsbBusdLp(address _gsbBusdLp) public onlyOwner {
        gsbBusdLp = _gsbBusdLp;
    }
    
    function setTeamer(address _teamer) public onlyOwner {
        teamer = _teamer;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGSB is IERC20 {
    function mint(address to, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInspirePool {
    struct User {
        uint256 id;
        address refer; // 邀请人地址
        uint256 directPushNum; // 直推人数，直推一人拿一代。。。。。
        uint256 totalAmount; // 购买金额
        uint256 amountBusd;
        uint256 amountGsb;
        uint256 referRewardBusd; // BUSD Pool邀请奖励
        uint256 hasWithdrawBusd;
        uint256 referRewardGsb; // GSB Pool邀请奖励
        uint256 hasWithdrawGsb;
        uint256 lastRewardBlockGsb;
        uint256 rewardDebt; // Reward debt.
    }
    
    function totalAmount() external view returns (uint256);
    function totalAmountBusd() external view returns (uint256);
    function totalAmountGsb() external view returns (uint256);
    function burnNum() external view returns (uint256);
    function hasMintAmount() external view returns (uint256);
    function startBlock() external view returns (uint256);
    function gsb() external view returns (address);
    function busd() external view returns (address);
    function gsbBusdLp() external view returns (address);
    function teamer() external view returns (address);
    function userCount() external view returns (uint256);
    function userMap(address _user) external view returns (User memory);
    
}

