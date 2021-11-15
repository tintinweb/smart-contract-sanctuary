/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

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

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
        token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

interface Token {
    function mint(address _to, uint256 _amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

contract StakingSingleToken is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    address public SMART_CHEF_FACTORY;
    address public devAddress;
    bool public hasUserLimit;
    bool public isInitialized;
    uint256 public accTokenPerShare;
    uint256 public bonusEndBlock;
    uint256 public startBlock;
    uint256 public lastRewardBlock;
    uint256 public poolLimitPerUser;
    uint256 public rewardPerBlock;
    uint256 public PRECISION_FACTOR;
    uint256 public txFee = 5;
    uint256 public stakingFee = 0;
    uint256 public withdrawFee = 0;
    uint256 public getRewardFee = 0;
    uint256 public staking_stock_length = 0;
    Token public rewardToken;
    IBEP20 public stakedToken;
    mapping(address => UserInfo) public userInfo;
    mapping(address => uint256) public pending_list;
    mapping(address => uint256) public staking_first_time;
    mapping(address => uint256) public staking_last_time;
    mapping(address => bool) public white_list;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);
    event Withdraw(address indexed user, uint256 amount);

    constructor() public {
        SMART_CHEF_FACTORY = msg.sender;
        devAddress = msg.sender;
    }

    function setDev(address _devAddress) public {
        require(msg.sender == owner() || msg.sender == devAddress, 'no p');
        devAddress = _devAddress;
    }

    function initialize(
        IBEP20 _stakedToken,
        Token _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        address _admin
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == SMART_CHEF_FACTORY, "Not factory");
        isInitialized = true;
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        if (_poolLimitPerUser > 0) {
            hasUserLimit = true;
            poolLimitPerUser = _poolLimitPerUser;
        }
        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR = uint256(10 ** (uint256(30).sub(decimalsRewardToken)));
        lastRewardBlock = startBlock;
        transferOwnership(_admin);
    }

    function setStakingStocklength(uint256 _staking_stock_length) public onlyOwner {
        staking_stock_length = _staking_stock_length;
    }

    function setTxFee(uint256 _txFee) public onlyOwner {
        txFee = _txFee;
    }

    function deposit(uint256 _amount) external nonReentrant {
        //_amount:100  tx:5 stakingFee:5
        uint256 txAmout = _amount.mul(txFee).div(100);
        uint256 stakingFeeAmout = _amount.mul(stakingFee).div(100);
        uint256 leftAmout = _amount.sub(txAmout).sub(stakingFeeAmout);
        UserInfo storage user = userInfo[msg.sender];
        if (staking_first_time[msg.sender] == 0) {
            staking_first_time[msg.sender] = block.number;
        }
        if (hasUserLimit) {
            require(leftAmout.add(user.amount) <= poolLimitPerUser, "User amount above limit");
        }
        _updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            if (pending > 0) {
                pending_list[msg.sender] = pending_list[msg.sender].add(pending);
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.add(leftAmout);
            stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (stakingFeeAmout > 0) {
                stakedToken.safeTransferFrom(address(this), devAddress, txAmout);
            }
        }
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);
        staking_last_time[msg.sender] = block.number;
        emit Deposit(msg.sender, _amount);
    }

    function getReward() public {
        UserInfo storage user = userInfo[msg.sender];
        if (!white_list[msg.sender]) {
            require(block.number > staking_last_time[msg.sender] + staking_stock_length, 'time limit');
        }
        _updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            if (pending > 0) {
                pending_list[msg.sender] = pending_list[msg.sender].add(pending);
            }
        }
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);
        emit Deposit(msg.sender, 0);
        require(pending_list[msg.sender] > 0, 'e0');
        safeCakeTransfer(msg.sender, pending_list[msg.sender]);
        pending_list[msg.sender] = 0;
    }

    function setWhiteList(address[] memory _address_list) public onlyOwner {
        for (uint256 i = 0; i < _address_list.length; i++) {
            white_list[_address_list[i]] = true;
        }
    }

    function setFees(uint256 _stakingFee, uint256 _withdrawFee, uint256 _getRewardFee) public onlyOwner {
        require(_stakingFee < 50 && _withdrawFee < 50 && _getRewardFee < 50, 'e0');
        stakingFee = _stakingFee;
        withdrawFee = _withdrawFee;
        getRewardFee = _getRewardFee;
    }

    function removeWhiteList(address[] memory _address_list) public onlyOwner {
        for (uint256 i = 0; i < _address_list.length; i++) {
            white_list[_address_list[i]] = false;
        }
    }

    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");
        _updatePool();
        uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            uint256 withdrawAmount = _amount.mul(withdrawFee).div(100);
            uint256 leftAmount = _amount.sub(withdrawAmount);
            if (withdrawAmount > 0) {
                stakedToken.safeTransfer(devAddress, withdrawAmount);
            }
            stakedToken.safeTransfer(address(msg.sender), leftAmount);
        }
        if (pending > 0) {
            pending_list[msg.sender] = pending_list[msg.sender].add(pending);
        }
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);
        emit Withdraw(msg.sender, _amount);
    }

    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        uint256 withdrawAmount = amountToTransfer.mul(withdrawFee).div(100);
        uint256 leftAmount = amountToTransfer.sub(withdrawAmount);
        user.amount = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            if (withdrawAmount > 0) {
                stakedToken.safeTransfer(devAddress, withdrawAmount);
            }
            stakedToken.safeTransfer(address(msg.sender), leftAmount);
        }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        safeCakeTransfer(address(msg.sender), _amount);
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        require(_tokenAddress != address(rewardToken), "Cannot be reward token");
        IBEP20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
    }

    function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        require(hasUserLimit, "Must be set");
        if (_hasUserLimit) {
            require(_poolLimitPerUser > poolLimitPerUser, "New limit must be higher");
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(poolLimitPerUser);
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        require(_startBlock < _bonusEndBlock, "New startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        lastRewardBlock = startBlock;
        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 pending = pending_list[_user];
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare =
            accTokenPerShare.add(cakeReward.mul(PRECISION_FACTOR).div(stakedTokenSupply));
            return pending.add(user.amount.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt));
        } else {
            return pending.add(user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt));
        }
    }

    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 cakeReward = multiplier.mul(rewardPerBlock);
        rewardToken.mint(address(this), cakeReward);
        accTokenPerShare = accTokenPerShare.add(cakeReward.mul(PRECISION_FACTOR).div(stakedTokenSupply));
        lastRewardBlock = block.number;
    }

    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    function safeCakeTransfer(address _to, uint256 _amount) internal {
        uint256 cakeBal = rewardToken.balanceOf(address(this));
        if (_amount > cakeBal) {
            rewardToken.transfer(_to, cakeBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }
}