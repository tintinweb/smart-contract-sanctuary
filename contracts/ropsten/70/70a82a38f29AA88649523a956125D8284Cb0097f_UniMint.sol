/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Mint is IERC20 {
    function mint(address account, uint256) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function owner() public view returns (address) {
        return _owner;
    }
}

contract UniMint is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct PoolInfo {
        // in
        uint256 amountDepositMax;
        uint256 amountDeposit;
        uint256 amountDepositHis;
        // out
        uint256 amountReward1Total;
        uint256 amountReward1Remain;
        uint256 amountReward2Total;
        uint256 amountReward2Remain;
        // tx options
        uint256 timeOfEndCollect;
        uint256 timeOfBeginMint;
        uint256 daysOfMint;
        uint256 timeOfEndMint;
    }

    struct UserInfo {
        uint256 poolId;
        uint256 amountDeposit;
        uint256 amountReward1Debt;
        uint256 amountReward2Debt;
        uint256 timeOfLastDeposit;
        bool isWithdrawed;
    }

    IERC20 public tokenDeposit;
    IERC20Mint public tokenReward1;
    IERC20Mint public tokenReward2;
    uint256 public amountDepositTotal;
    uint256 public amountDepositTotalHis;
    PoolInfo[] public pools;
    mapping(address => mapping(uint256 => UserInfo)) public userDeposits;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Claim(
        address indexed user,
        uint256 indexed poolId,
        uint256 amountReward1,
        uint256 amountReward2
    );
    event Withdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    // in
    constructor(
        IERC20 _tokenDeposit,
        IERC20Mint _tokenReward1,
        IERC20Mint _tokenReward2
    ) {
        tokenDeposit = _tokenDeposit;
        tokenReward1 = _tokenReward1;
        tokenReward2 = _tokenReward2;
    }

    // in onlyOwner
    function addPool(
        uint256 _amountDepositMax,
        uint256 _timeOfEndCollect,
        uint256 _timeOfBeginMint,
        uint256 _daysOfMint
    ) external onlyOwner {
        require(
            _amountDepositMax > 0,
            "add pool: deposit max must greater than 0 "
        );
        require(
            _timeOfEndCollect > block.timestamp,
            "add pool: time of end collect must after now"
        );
        require(
            _timeOfBeginMint >= _timeOfEndCollect,
            "add pool: time of begin mint must after or equal time of end collect time"
        );
        require(
            _daysOfMint > 0,
            "add pool: days of mint/lock must greater than 0 "
        );
        // TODO: need modify minutes to days on product env
        pools.push(
            PoolInfo({
                amountDepositMax: _amountDepositMax,
                amountDeposit: 0,
                amountDepositHis: 0,
                amountReward1Total: 0,
                amountReward1Remain: 0,
                amountReward2Total: 0,
                amountReward2Remain: 0,
                timeOfEndCollect: _timeOfEndCollect,
                timeOfBeginMint: _timeOfBeginMint,
                daysOfMint: _daysOfMint,
                timeOfEndMint: _timeOfBeginMint + (_daysOfMint * 1 minutes)
            })
        );
    }

    function updatePool(
        uint256 _poolId,
        uint256 _amountDepositMax,
        uint256 _timeOfEndCollect,
        uint256 _timeOfBeginMint,
        uint256 _daysOfMint
    ) external onlyOwner {
        // in check
        require(
            _timeOfEndCollect > 0,
            "update pool: _timeOfEndCollect invalid"
        );
        require(
            _timeOfBeginMint >= _timeOfEndCollect,
            "update pool: time of begin mint must after or equal time of end collect time"
        );
        require(
            _daysOfMint > 0,
            "update pool: days of mint/lock must greater than 0 "
        );
        // in check env
        require(
            _poolId >= 0 && _poolId < pools.length,
            "update pool: _poolId invalid"
        );
        PoolInfo storage pool = pools[_poolId];
        require(
            _amountDepositMax > pool.amountDepositHis,
            "update pool:_amountDepositMax must greater than had deposit amount"
        );
        // tx apply
        pool.amountDepositMax = _amountDepositMax;
        pool.timeOfEndCollect = _timeOfEndCollect;
        pool.timeOfBeginMint = _timeOfBeginMint;
        pool.daysOfMint = _daysOfMint;
        // TODO: need modify minutes to days on product env
        pool.timeOfEndMint = _timeOfBeginMint + (_daysOfMint * 1 minutes);
    }

    function addReward(
        uint256 _poolId,
        uint256 _amountReward1,
        uint256 _amountReward2
    ) external onlyOwner {
        // in check
        require(
            _amountReward1 > 0 || _amountReward2 > 0,
            "add reward: amount invalid,amount reward 1 or 2 must have one or double is greater than zero"
        );
        // in check env
        require(
            _poolId >= 0 && _poolId < pools.length,
            "deposit: _poolId invalid"
        );
        // in get
        PoolInfo storage pool = pools[_poolId];
        if (_amountReward1 > 0) {
            tokenReward1.mint(address(this), _amountReward1);
            pool.amountReward1Total = pool.amountReward1Total.add(
                _amountReward1
            );
            pool.amountReward1Remain = pool.amountReward1Remain.add(
                _amountReward1
            );
        }
        if (_amountReward2 > 0) {
            tokenReward2.mint(address(this), _amountReward2);
            pool.amountReward2Total = pool.amountReward2Total.add(
                _amountReward2
            );
            pool.amountReward2Remain = pool.amountReward2Remain.add(
                _amountReward2
            );
        }
    }

    // in from user
    function deposit(uint256 _poolId, uint256 _amount) external {
        // in check inputs
        require(_amount > 0, "deposit: _amount invalid");
        // in check env
        require(
            _poolId >= 0 && _poolId < pools.length,
            "deposit: _poolId invalid"
        );
        PoolInfo storage pool = pools[_poolId];
        require(
            block.timestamp < pool.timeOfEndCollect,
            "deposit: collect had ended"
        );
        require(pool.amountDepositHis.add(_amount)<=pool.amountDepositMax,"deposit: the deposit amount will overflow");
        // in get
        UserInfo storage user = userDeposits[_msgSender()][_poolId];

        // tx apply
        tokenDeposit.safeTransferFrom(
            address(_msgSender()),
            address(this),
            _amount
        );
        pool.amountDeposit = pool.amountDeposit.add(_amount);
        pool.amountDepositHis = pool.amountDepositHis.add(_amount);
        amountDepositTotal = amountDepositTotal.add(_amount);
        amountDepositTotalHis = amountDepositTotalHis.add(_amount);

        user.poolId = _poolId;
        user.amountDeposit = user.isWithdrawed?_amount:user.amountDeposit.add(_amount);
        user.timeOfLastDeposit = block.timestamp;
        user.isWithdrawed = false;
        // out logs
        emit Deposit(_msgSender(), _poolId, _amount);
    }

    function claim(uint256 _poolId) external {
        // in check env
        require(
            _poolId >= 0 && _poolId < pools.length,
            "claim: _poolId invalid"
        );
        PoolInfo storage pool = pools[_poolId];
        require(
            block.timestamp > pool.timeOfBeginMint,
            "claim: mint no begin,no reward can claim"
        );
        require(
            pool.amountDepositHis > 0,
            "claim: pool deposit amount is zero,no reward can claim"
        );
        require(
            (pool.amountReward1Total > 0 && pool.amountReward1Remain > 0) ||
                (pool.amountReward2Total > 0 && pool.amountReward2Remain > 0),
            "claim: pool reward1 and reward2 is all zero"
        );
        UserInfo storage user = userDeposits[_msgSender()][_poolId];
        require(
            user.amountDeposit > 0,
            "claim: the amount of user deposit is zero"
        );
        _claim(_poolId, pool, user);
    }

    function withdraw(uint256 _poolId) external {
        // in check env
        require(
            _poolId >= 0 && _poolId < pools.length,
            "claim: _poolId invalid"
        );
        PoolInfo storage pool = pools[_poolId];
        require(
            block.timestamp > pool.timeOfEndMint,
            "withdraw: mint no end, con not withdraw"
        );
        require(
            pool.amountDeposit > 0,
            "withdraw: pool deposit amount is zero,con not withdraw"
        );
        UserInfo storage user = userDeposits[_msgSender()][_poolId];
        require(
            user.amountDeposit > 0,
            "withdraw: the amount of user deposit is zero"
        );
        require(
            pool.amountDeposit >= user.amountDeposit &&
                amountDepositTotal >= user.amountDeposit,
            "withdraw: the amount of pool or all pools must greater than or equal the amount of user deposit "
        );
        require(user.isWithdrawed == false, "withdraw: had withdrawed");
        // tx apply
        _claim(_poolId, pool, user);
        tokenDeposit.safeTransfer(_msgSender(), user.amountDeposit);
        amountDepositTotal = amountDepositTotal.sub(user.amountDeposit);
        pool.amountDeposit = pool.amountDeposit.sub(user.amountDeposit);
        user.isWithdrawed = true;
        // out logs
        emit Withdraw(_msgSender(), _poolId, user.amountDeposit);
    }

    // out
    function poolLength() external view returns (uint256) {
        return pools.length;
    }

    function pendingReward1(uint256 _poolId) external view returns (uint256) {
        PoolInfo storage pool = pools[_poolId];
        if (block.timestamp < pool.timeOfEndCollect) {
            return 0;
        }
        if (
            pool.amountDepositHis == 0 ||
            pool.amountReward1Total == 0 ||
            pool.amountReward1Remain == 0
        ) {
            return 0;
        }
        UserInfo storage user = userDeposits[_msgSender()][_poolId];
        if (user.amountDeposit == 0) {
            return 0;
        }
        return _calcurateReward(1, pool, user);
    }

    function pendingReward2(uint256 _poolId) external view returns (uint256) {
        PoolInfo storage pool = pools[_poolId];
        if (block.timestamp < pool.timeOfEndCollect) {
            return 0;
        }
        if (
            pool.amountDepositHis == 0 ||
            pool.amountReward2Total == 0 ||
            pool.amountReward2Remain == 0
        ) {
            return 0;
        }
        UserInfo storage user = userDeposits[_msgSender()][_poolId];
        if (user.amountDeposit == 0) {
            return 0;
        }
        return _calcurateReward(2, pool, user);
    }

    // out internal
    function _claim(
        uint256 _poolId,
        PoolInfo storage _pool,
        UserInfo storage _user
    ) private {
        // in get
        uint256 reward1 = 0;
        uint256 reward2 = 0;
        if (_pool.amountReward1Total > 0 && _pool.amountReward1Remain > 0) {
            reward1 = _calcurateReward(1, _pool, _user);
        }
        if (_pool.amountReward2Total > 0 && _pool.amountReward2Remain > 0) {
            reward2 = _calcurateReward(2, _pool, _user);
        }
        // tx apply
        if (reward1 > 0) {
            _safeTokenTransfer(tokenReward1, _msgSender(), reward1);
            _pool.amountReward1Remain = _pool.amountReward1Remain.sub(reward1);
            _user.amountReward1Debt = _user.amountReward1Debt.add(reward1);
        }
        if (reward2 > 0) {
            _safeTokenTransfer(tokenReward2, _msgSender(), reward2);
            _pool.amountReward2Remain = _pool.amountReward2Remain.sub(reward2);
            _user.amountReward2Debt = _user.amountReward2Debt.add(reward2);
        }
        // out log
        if (reward1 > 0 || reward2 > 0) {
            emit Claim(_msgSender(), _poolId, reward1, reward2);
        }
    }

    function _calcurateReward(
        uint256 _rewardIndex,
        PoolInfo storage _pool,
        UserInfo storage _user
    ) private view returns (uint256 reward) {
        if (_rewardIndex == 1) {
            uint256 bipsScaled = _user.amountDeposit.mul(1e12).div(
                _pool.amountDepositHis
            );
            uint256 rewardTotal = _pool.amountReward1Total.mul(bipsScaled);
            reward = rewardTotal.div(1e12).sub(_user.amountReward1Debt);
        } else if (_rewardIndex == 2) {
            uint256 bipsScaled = _user.amountDeposit.mul(1e12).div(
                _pool.amountDepositHis
            );
            uint256 rewardTotal = _pool.amountReward2Total.mul(bipsScaled);
            reward = rewardTotal.div(1e12).sub(_user.amountReward2Debt);
        } else {
            reward = 0;
        }
    }

    function _safeTokenTransfer(
        IERC20Mint _token,
        address _to,
        uint256 _amount
    ) private {
        uint256 tokenBal = _token.balanceOf(address(this));
        if (_amount > tokenBal) {
            _token.transfer(_to, tokenBal);
        } else {
            _token.transfer(_to, _amount);
        }
    }
}