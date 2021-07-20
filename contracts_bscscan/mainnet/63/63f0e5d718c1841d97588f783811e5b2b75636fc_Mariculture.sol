/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// The Great Wave off Kanagawa
// https://wave.cash/
// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

interface ITOKEN {

  function totalSupply() external view returns (uint256);

  function totalBurnt() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function mint(uint256 amount, address account) external returns (bool);
  function burnFrom(uint256 amount, address account) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IKANAGAWA {

  function getUpgradeFee(uint8 level) external view returns (uint);

  function isRegistered(address user) external view returns (bool);

  function getUserID(address user) external view returns (uint);

  function getUserLevel(uint userID) external view returns (uint8);

}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

library SafeToken {
    using SafeMath for uint256;

    function safeTransfer(
        ITOKEN token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        ITOKEN token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(ITOKEN token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeToken: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeToken: BEP20 operation did not succeed");
        }
    }
}

contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "OWNER_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

contract Base is InitializableOwnable {
    using SafeToken for ITOKEN;
    using SafeMath for uint256;

    // ============ Storage ============

    struct LpTokenInfo {
        address pool;
        uint256 rewardBase;
        uint256 totalStaked;
        uint256 totalReward;
        mapping(address => uint256) userStaked;
        mapping(address => uint256) userRewardUnclaim;
        mapping(address => uint256) userRewardClaimed;
        mapping(address => uint256) userRewardBlockNum;
    }

    LpTokenInfo[] public lpTokenInfos;

    mapping(address => bool) internal _userLocked;

    address internal _wave;
    address internal _can;
    address internal _kanagawa;
    uint256 internal _oneHour;
    uint256 internal _maxCDT;
    uint256 internal _coolDownHours;
    uint256 internal _maxStakeBlocks;
    uint256 internal _multiplicator;

    // ============ Event =============
    event NewLpToken(uint256 indexed i, address pool);
    event RemoveLpToken(address pool);
    event UpdateRewardBase(uint256 indexed i, uint256 rewardBase);
    event Lock(address indexed user);
    event UnLock(address indexed user);

    // ============ Modifiers ============

    modifier unlock() {
        require(!isLocked(msg.sender), "ACCOUNT_LOCKED");
        _;
    }

    // ============ View  ============
    function isLocked(address user) public view returns (bool) {
        return _userLocked[user];
    }

    function getUpgradeFee(uint8 level) public view returns (uint) {
        return IKANAGAWA(_kanagawa).getUpgradeFee(level);
    }

    function isRegistered(address user) public view returns (bool) {
        return IKANAGAWA(_kanagawa).isRegistered(user);
    }

    function getUserID(address user) public view returns (uint) {
        return IKANAGAWA(_kanagawa).getUserID(user);
    }

    function getUserLevel(uint userID) public view returns (uint8) {
        return IKANAGAWA(_kanagawa).getUserLevel(userID);
    }

    function getUserLevelByAddress(address user) public view returns (uint8) {
        return IKANAGAWA(_kanagawa).getUserLevel(getUserID(user));
    }

    function getLpTokenById(uint256 i) public view returns (address) {
        require(i<lpTokenInfos.length, "FarmV1: POOL_ID_NOT_FOUND");
        LpTokenInfo memory lpt = lpTokenInfos[i];
        return lpt.pool;
    }

    function getIdByLpToken(address pool) public view returns(uint256) {
        uint256 len = lpTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            if (pool == lpTokenInfos[i].pool) {
                return i;
            }
        }
        require(false, "FarmV1: TOKEN_NOT_FOUND");
    }

    function getPoolsNum() external view returns(uint256) {
        return lpTokenInfos.length;
    }

    function getUserStaked(address user, uint256 i) public view returns (uint256) {
        require(i<lpTokenInfos.length, "FarmV1: POOL_ID_NOT_FOUND");
        return lpTokenInfos[i].userStaked[user];
    }

    function getUserStakedByLp(address user, address pool) public view returns (uint256) {
        return getUserStaked(user, getIdByLpToken(pool));
    }

    function getUserUnclaim(address user, uint256 i) public view returns (uint256) {
        require(i<lpTokenInfos.length, "FarmV1: POOL_ID_NOT_FOUND");
        return lpTokenInfos[i].userRewardUnclaim[user];
    }

    function getUserClaimed(address user, uint256 i) public view returns (uint256) {
        require(i<lpTokenInfos.length, "FarmV1: POOL_ID_NOT_FOUND");
        return lpTokenInfos[i].userRewardClaimed[user];
    }

    function getUserRewardBlockNum(address user, uint256 i) public view returns (uint256) {
        require(i<lpTokenInfos.length, "FarmV1: POOL_ID_NOT_FOUND");
        return lpTokenInfos[i].userRewardBlockNum[user];
    }

    function getUserStakedBlockNum(address user, uint256 i) public view returns (uint256) {
        require(i<lpTokenInfos.length, "FarmV1: POOL_ID_NOT_FOUND");
        if (getUserRewardBlockNum(user, i)>0 && getUserStaked(user, i)>0) {
            return block.number.sub(getUserRewardBlockNum(user, i));
        } else {
            return 0;
        }
    }

    function getWaveBalance(address account) public view returns (uint256) {
        return ITOKEN(_wave).balanceOf(account);
    }

    function getWaveBalanceByLpID(uint256 i) public view returns (uint256) {
        return getWaveBalance(getLpTokenById(i));
    }

    function blocksInHours(uint256 n) public view returns (uint256) {
        return _oneHour.mul(n);
    }

    function maxCDT() public view returns (uint256) {
        return _maxCDT;
    }

    function maxStakeBlocks() public view returns (uint256) {
        return _maxStakeBlocks;
    }

    function coolDownTime(address user) public view returns (uint256) {
        return maxCDT().sub(uint256(getUserLevelByAddress(user)).mul(blocksInHours(_coolDownHours)));
    }

    function userStakedBlocks(address user, uint256 i) public view returns (uint256) {
        require(i<lpTokenInfos.length, "FarmV1: POOL_ID_NOT_FOUND");
        uint256 staked = getUserStaked(user, i);
        uint256 start = getUserRewardBlockNum(user, i);
        if (staked>0) {
            uint256 blocks = block.number.sub(start);
            return blocks<_maxStakeBlocks ? blocks : _maxStakeBlocks;
        } else {
            return 0;
        }
    }

    function userStakedBlocksByLp(address user, address pool) public view returns (uint256) {
        uint256 id = getIdByLpToken(pool);
        return userStakedBlocks(user, id);
    }

    function isCoolDown(address user, uint256 i) public view returns (bool) {
        require(i<lpTokenInfos.length, "FarmV1: POOL_ID_NOT_FOUND");
        uint256 cdt = coolDownTime(user);
        if (userStakedBlocks(user, i) > cdt) {
            return true;
        } else {
            return false;
        }
    }

    function getLpRewardBaseById(uint256 id) public view returns (uint256) {
        require(id<lpTokenInfos.length, "FarmV1: POOL_ID_NOT_FOUND");
        LpTokenInfo memory lpt = lpTokenInfos[id];
        return lpt.rewardBase;
    }

    function getLpRewardBase(address pool) public view returns (uint256) {
        uint256 id = getIdByLpToken(pool);
        return getLpRewardBaseById(id);
    }

    function getRealRewardBaseById(uint256 id) public view returns (uint256) {
        require(id<lpTokenInfos.length, "FarmV1: POOL_ID_NOT_FOUND");
        LpTokenInfo memory lpt = lpTokenInfos[id];
        uint256 zeroBase = lpTokenInfos[0].rewardBase;

        if (id>0) {
            uint256 zeroPool = getWaveBalanceByLpID(0);
            uint256 pool = getWaveBalanceByLpID(id);
            uint256 realBase = (zeroBase.mul(zeroPool)).div(pool);
            if (realBase < lpt.rewardBase) {
                return realBase > 0 ? realBase : 1;
            } else {
                return lpt.rewardBase;
            }
        } else {
            return zeroBase;
        } 
    }

    function getRealRewardBase(address pool) public view returns (uint256) {
        uint256 id = getIdByLpToken(pool);
        return getRealRewardBaseById(id);
    }


    function getPendingRewardById(address user, uint256 i) public view returns (uint256) {
        require(i<lpTokenInfos.length, "FarmV1: LP_TOKEN_ID_NOT_FOUND");
        uint256 staked = getUserStaked(user, i);
        uint256 blocks = userStakedBlocks(user, i);
        uint256 base = getRealRewardBaseById(i);
        uint256 unclaim = getUserUnclaim(user, i);
        uint256 pending = base.mul(blocks).mul(staked).div(10**18).mul(_multiplicator);
        return unclaim.add(pending);
    }

    function getPendingReward(address user, address pool) external view returns (uint256) {
        return getPendingRewardById(user, getIdByLpToken(pool));
    }

    // =============== Ownable  ================
    function setOneHour( uint256 blocks ) external onlyOwner {
        _oneHour = blocks;
    }

    function setMaxCDT( uint256 blocks ) external onlyOwner {
        _maxCDT = blocks;
    }

    function setMaxStakeBlocks( uint256 blocks ) external onlyOwner {
        _maxStakeBlocks = blocks;
    }

    function setCoolDownHours( uint256 h ) external onlyOwner {
        _coolDownHours = h;
    }

    function addLpToken( address pool, uint256 rewardBase ) external onlyOwner {
        require(pool != address(0), "FarmV1: POOL_INVALID");

        uint256 len = lpTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            require(
                pool != lpTokenInfos[i].pool,
                "FarmV1: TOKEN_ALREADY_ADDED"
            );
        }

        LpTokenInfo storage lpt = lpTokenInfos.push();
        lpt.pool = pool;
        lpt.rewardBase = rewardBase;

        emit NewLpToken(len, pool);
    }

    function removeLpToken(address pool) external onlyOwner {
        uint256 len = lpTokenInfos.length;
        for (uint256 i = 0; i < len; i++) {
            if (pool == lpTokenInfos[i].pool) {
                if(i != len - 1) {
                    lpTokenInfos[i] = lpTokenInfos[len - 1];
                }
                lpTokenInfos.pop();
                emit RemoveLpToken(pool);
                break;
            }
        }
    }

    function setRewardBase(uint256 i, uint256 newRewardBase)
        external
        onlyOwner
    {
        require(i < lpTokenInfos.length, "FarmV1: LP_TOKEN_ID_NOT_FOUND");

        LpTokenInfo storage lpt = lpTokenInfos[i];

        lpt.rewardBase = newRewardBase;
        emit UpdateRewardBase(i, newRewardBase);
    }

    function lockAccount(address user, bool isLock) external onlyOwner {
        _userLocked[user] = isLock;
        if (isLock) {
          emit Lock(user);
        } else {
          emit UnLock(user);
        }
    }

    // ============ Internal  ============
  function _updateReward(address user, uint256 id) internal {
      LpTokenInfo storage lpt = lpTokenInfos[id];
      uint256 pending = getPendingRewardById(user, id);
      lpt.userRewardBlockNum[user] = block.number;
      lpt.userRewardUnclaim[user] = pending;
      lpt.totalReward = lpt.totalReward.add(pending);
  }

}

contract Mariculture is Base {
    using SafeToken for ITOKEN;
    using SafeMath for uint256;

    // ============ Storage ============
    string private _name;

    // ============ Init  ============
    function init(address owner, address wave, address can, address kanagawa) external {
        super.initOwner(owner);
        _name = "Mariculture";
        _wave = wave;
        _can = can;
        _kanagawa = kanagawa;
        _oneHour = 12*60;
        _coolDownHours = 12;
        _maxCDT = _coolDownHours*_oneHour*10 + 120;
        _maxStakeBlocks = _oneHour*24*365;
        _multiplicator = 10**8;
    }

    // ============ Event  ============
    event Deposit(address indexed user, address indexed lpToken, uint256 amount);
    event Withdraw(address indexed user, address indexed lpToken, uint256 amount);
    event Claim(uint256 indexed i, address indexed user, uint256 reward);

    // ============ View  ============
    function name() external view returns (string memory) {
        return _name;
    }

    // ============ Deposit && Withdraw ============
    function deposit(uint256 amount, address lpToken) external {
        require(amount > 0, "FarmV1: CANNOT_DEPOSIT_ZERO");

        _updateReward(msg.sender, getIdByLpToken(lpToken));

        LpTokenInfo storage lpt = lpTokenInfos[getIdByLpToken(lpToken)];

        uint256 originBalance = ITOKEN(lpt.pool).balanceOf(address(this));
        ITOKEN(lpt.pool).safeTransferFrom(msg.sender, address(this), amount);
        uint256 actualStakeAmount = ITOKEN(lpt.pool).balanceOf(address(this)).sub(originBalance);

        require(amount == actualStakeAmount, "FarmV1: AMOUNTS_NOT_MATCH");

        lpt.totalStaked = lpt.totalStaked.add(amount);
        lpt.userStaked[msg.sender] = lpt.userStaked[msg.sender].add(amount);
        lpt.userRewardBlockNum[msg.sender] = block.number;

        emit Deposit(msg.sender, lpToken, amount);
    }

    function withdraw(uint256 amount, address lpToken) external unlock {
        require(amount > 0, "FarmV1: CANNOT_WITHDRAW_ZERO");
        require(userStakedBlocksByLp(msg.sender, lpToken) > 12, "FarmV1: CANNOT_WITHDRAW_NOW");

        _updateReward(msg.sender, getIdByLpToken(lpToken));

        LpTokenInfo storage lpt = lpTokenInfos[getIdByLpToken(lpToken)];

        require(amount <= getUserStakedByLp(msg.sender, lpToken), "FarmV1: CANNOT_WITHDRAW_MORE");

        lpt.totalStaked = lpt.totalStaked.sub(amount);
        lpt.userStaked[msg.sender] = lpt.userStaked[msg.sender].sub(amount);
        ITOKEN(lpt.pool).safeTransfer(msg.sender, amount);
        lpt.userRewardBlockNum[msg.sender] = block.number;

        emit Withdraw(msg.sender, lpToken, amount);
    }

    // ============ Claim ============
    function claimReward(uint256 i) public unlock {
        require(i<lpTokenInfos.length, "FarmV1: LP_TOKEN_ID_NOT_FOUND");
        require(isCoolDown(msg.sender, i), "FarmV1: NOT_COOL_DOWN");

        _updateReward(msg.sender, i);

        LpTokenInfo storage lpt = lpTokenInfos[i];

        uint256 reward = lpt.userRewardUnclaim[msg.sender];
        if (reward > 0) {
            lpt.userRewardUnclaim[msg.sender] = 0;
            ITOKEN(_can).mint(reward, msg.sender);
            emit Claim(i, msg.sender, reward);
        }
    }

}