// MEE Pair
pragma solidity 0.5.12;

interface IERC20 {
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
}

contract IMPool is IERC20 {
    function isBound(address t) external view returns (bool);
    function getFinalTokens() external view returns(address[] memory);
    function getBalance(address token) external view returns (uint);
    function setSwapFee(uint swapFee) external;
    function setController(address controller) external;
    function setPublicSwap(bool public_) external;
    function finalize() external;
    function bind(address token, uint balance, uint denorm) external;
    function rebind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
    function joinswapExternAmountIn(
        address tokenIn, uint tokenAmountIn, uint minPoolAmountOut
    ) external returns (uint poolAmountOut);
}

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract PairERC20 is IERC20 {
    using SafeMath for uint;

    string public constant name = 'Mercurity Pair Token';
    string public constant symbol = 'MPT';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function _mint(uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[address(this)] = balanceOf[address(this)].add(value);
        emit Transfer(address(0), address(this), value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        require(balanceOf[from] >= value, "ERR_INSUFFICIENT_BAL");
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function _move(address from, address to, uint value) internal {
        _transfer(from, to, value);
    }
}

contract PairToken is PairERC20 {
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount;           // How many LP tokens or gp amount the user has provided.
        uint256 rewardDebt;       // Reward debt. See explanation below.
    }
    // Controller.
    address private _controller;
    // Pair tokens created per block.
    uint256 private _pairPerBlock;
    // Set gp share reward rate 0%~15%
    uint256 private _gpRate;
    // Pool contract
    IMPool private _pool;
    // Info of each gp.
    address[] private _gpInfo;
    // Info of each user that stakes LP shares;
    mapping(address => UserInfo) public lpInfoList;
    // Info of each user that stakes GP shares;
    mapping(address => UserInfo) public gpInfoList;

    uint256 private _endBlock;
    uint256 public _totalGpSupply;
    uint256 public _totalLpSupply;
    // Pool Status
    uint256 public _poolLastRewardBlock;
    uint256 public _poolAccPairPerShare;
    uint256 public _poolAccPairGpPerShare;

    event Deposit(bool isGp, address indexed user, uint256 amount);
    event Withdraw(bool isGp, address indexed user, uint256 amount);

    constructor(
        address pool,
        uint256 pairPerBlock,
        uint256 rate
    ) public {
        _pool = IMPool(pool);
        _controller = msg.sender;

        _pairPerBlock = pairPerBlock;
        _endBlock = block.number.add(12500000);
        _poolLastRewardBlock = block.number;

        require(rate < 100, "ERR_OVER_MAXIMUM");
        _gpRate = rate;
    }

    function isGeneralPartner(address _user)
    external view
    returns (bool) {
        return gpInfoList[_user].amount > 0;
    }

    // View function to see pending Pairs on frontend.
    function pendingPair(bool gpReward, address _user) external view returns (uint256) {

        UserInfo storage user = gpReward ? gpInfoList[_user] : lpInfoList[_user];

        if (user.amount == 0) {return 0;}
        uint256 rate = gpReward ? _gpRate : 100 - _gpRate;
        uint256 accPerShare = gpReward ? _poolAccPairGpPerShare: _poolAccPairPerShare ;
        uint256 lpSupply = gpReward? _totalGpSupply: _totalLpSupply;

        if (block.number > _poolLastRewardBlock && lpSupply != 0) {
            uint256 blockNum = block.number.sub(_poolLastRewardBlock);
            uint256 pairReward = blockNum.mul(_pairPerBlock);
            if (_gpRate > 0) {
                pairReward = pairReward.mul(rate).div(100);
            }
            accPerShare = accPerShare.add(pairReward.mul(1e12)).div(lpSupply);
        }
        return user.amount.mul(accPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables of the given user to be up-to-date.
    function updatePool() public {
        if (block.number <= _poolLastRewardBlock) {return;}

        if (_totalLpSupply == 0) {
            _poolLastRewardBlock = block.number;
            return;
        }

        if (_poolLastRewardBlock == _endBlock) {return;}

        uint256 blockNum;
        if (block.number < _endBlock) {
            blockNum = block.number.sub(_poolLastRewardBlock);
            _poolLastRewardBlock = block.number;
        } else {
            blockNum = _endBlock.sub(_poolLastRewardBlock);
            _poolLastRewardBlock = _endBlock;
        }

        uint256 pairReward = blockNum.mul(_pairPerBlock);
        _mint(pairReward);

        uint256 lpPairReward;
        if (_gpRate == 0) {
            lpPairReward = pairReward;
        } else {
            uint256 gpReward = pairReward.mul(_gpRate).div(100);
            _poolAccPairGpPerShare = _poolAccPairGpPerShare.add(gpReward.mul(1e12).div(_totalGpSupply));
            lpPairReward = pairReward.sub(gpReward);
        }

        _poolAccPairPerShare = _poolAccPairPerShare.add(lpPairReward.mul(1e12).div(_totalLpSupply));
    }

    // add liquidity LP tokens to PairBar for Pair allocation.
    function addLiquidity(bool isGp, address _user, uint256 _amount) external {
        require(msg.sender == address(_pool), "ERR_POOL_ONLY");
        _addLiquidity(isGp, _user, _amount);
    }

    function _addLiquidity(bool isGp, address _user, uint256 _amount) internal {
        UserInfo storage user = isGp ? gpInfoList[_user] : lpInfoList[_user];

        if (isGp) { require(_gpRate > 0, "ERR_NO_GP_SHARE_REMAIN"); }

        updatePool();

        uint256 accPerShare = isGp ? _poolAccPairGpPerShare: _poolAccPairPerShare ;
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                _move(address(this), _user, pending);
            }
        }

        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            if (isGp) {
                _totalGpSupply += _amount;
            } else {
                _totalLpSupply += _amount;
            }
            emit Deposit(isGp, _user, _amount);
        }
        user.rewardDebt = user.amount.mul(accPerShare).div(1e12);
    }

    function claimPair(bool isGp, address _user) external {
        UserInfo storage user = isGp ? gpInfoList[_user] : lpInfoList[_user];

        if (isGp) { require(_gpRate > 0, "ERR_NO_GP_SHARE_REMAIN"); }

        updatePool();

        uint256 accPerShare = isGp ? _poolAccPairGpPerShare: _poolAccPairPerShare ;
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                _move(address(this), _user, pending);
            }
        }
        user.rewardDebt = user.amount.mul(accPerShare).div(1e12);
        return;
    }

    // remove liquidity LP tokens from PairBar.
    function removeLiquidity(bool isGp, address _user, uint256 _amount) external {
        require(msg.sender == address(_pool), "ERR_POOL_ONLY");
        _removeLiquidity(isGp, _user, _amount);
    }

    function _removeLiquidity(bool isGp, address _user, uint256 _amount) internal {
        UserInfo storage user = isGp ? gpInfoList[_user] : lpInfoList[_user];
        require(user.amount >= _amount, "ERR_UNDER_WITHDRAW_AMOUNT_LIMIT");

        updatePool();

        uint256 accPerShare = isGp ? _poolAccPairGpPerShare : _poolAccPairPerShare;
        uint256 totalSupply = isGp ? _totalGpSupply: _totalLpSupply ;

        uint256 pending = user.amount.mul(accPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            _move(address(this), _user, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            totalSupply -= _amount;
            emit Withdraw(isGp, _user, _amount);
        }
        user.rewardDebt = user.amount.mul(accPerShare).div(1e12);
    }

    function updateGPInfo(address[] calldata gps, uint256[] calldata amounts) external {
        require(msg.sender == address(_pool), "ERR_POOL_ONLY");
        require(_gpRate > 0, "ERR_NO_GP_SHARE_REMAIN");
        require(gps.length == amounts.length, "ERR_INVALID_PARAM");

        // init setup
        if (_totalGpSupply == 0) {
            for (uint i = 0; i < gps.length; i++) {
                UserInfo memory user = gpInfoList[gps[i]];
                if (user.amount == 0) {
                    _totalGpSupply += amounts[i];
                    _gpInfo.push(gps[i]);
                }
            }
            for (uint i = 0; i < gps.length; i++) {
                _addLiquidity(true, gps[i], amounts[i]);
            }
            return;
        }

        for (uint i = 0; i < gps.length; i++) {
            if (gps[i] == address(0)) {
                continue;
            }
            UserInfo memory user = gpInfoList[gps[i]];
            // add new gp
            if (user.amount == 0) {
                _totalGpSupply += amounts[i];
                _addLiquidity(true, gps[i], amounts[i]);
                _gpInfo.push(gps[i]);
            }else if (user.amount > amounts[i]) {
                uint256 shareChange = user.amount.sub(amounts[i]);
                _totalGpSupply -= shareChange;
                _removeLiquidity(true, gps[i], shareChange);
            }else if (user.amount < amounts[i]) {
                uint256 shareChange = amounts[i].sub(user.amount);
                _totalGpSupply += shareChange;
                _addLiquidity(true, gps[i], shareChange);
            }
        }

        // filter gpInfo find out which gp need to remove
        for (uint i = 0; i < _gpInfo.length; i++) {
            bool needRemove = true;
            for (uint j = 0; j < gps.length; i++) {
                if (gps[i] == _gpInfo[j]) {
                    needRemove = false;
                }
            }
            if (needRemove) {
                UserInfo memory user = gpInfoList[gps[i]];
                _removeLiquidity(true, gps[i], user.amount);
                _totalGpSupply -= user.amount;
            }
        }
    }

    function setController(address controller) public {
        require(msg.sender == _controller, "ERR_CONTROLLER_ONLY");
        _controller = controller;
    }

}

contract PairFactory {
    address private _controller;

    mapping(address => address) private _hasPair;

    constructor() public {
        _controller = msg.sender;
    }

    function newPair(address pool, uint256 perBlock, uint256 rate)
    external
    returns (PairToken pair)
    {
        require(_hasPair[address(pool)] == address(0), "ERR_ALREADY_HAS_PAIR");

        pair = new PairToken(pool, perBlock, rate);
        _hasPair[address(pool)] = address(pair);

        pair.setController(msg.sender);
        return pair;
    }


    function getPairToken(address pool)
    external view
    returns (address)
    {
        return _hasPair[pool];
    }
}