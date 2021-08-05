/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{ value : amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

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
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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


contract sVault {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    struct Reward {
        uint256 amount;
        uint256 timestamp;
        uint256 totalDeposit;
    }

    mapping(address => uint256) public _lastCheckTime;
    mapping(address => uint256) public _rewardBalance;
    mapping(address => uint256) public _depositBalances;

    uint256 public _totalDeposit;

    Reward[] public _rewards;

    string public _vaultName;
    IERC20 public token0;
    IERC20 public token1;
    address public feeAddress;
    address public vaultAddress;
    uint32 public feePermill;
    uint256 public delayDuration = 7 days;
    bool public withdrawable;
    uint256 public totalRate = 10000;
    uint256 public userRate = 8500;
    address public treasury;
    
    address public gov;

    uint256 public _rewardCount;

    event SentReward(uint256 amount);
    event Deposited(address indexed user, uint256 amount);
    event ClaimedReward(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor (address _token0, address _token1, address _feeAddress, address _vaultAddress, string memory name, address _treasury) payable {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        feeAddress = _feeAddress;
        vaultAddress = _vaultAddress;
        _vaultName = name;
        gov = msg.sender;
        treasury = _treasury;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "!governance");
        _;
    }

    function setGovernance(address _gov)
        external
        onlyGov
    {
        gov = _gov;
    }

    function setToken0(address _token)
        external
        onlyGov
    {
        token0 = IERC20(_token);
    }

    function setTotalRate(uint256 _totalRate)
        external
        onlyGov
    {
        totalRate = _totalRate;
    }

    function setTreasury(address _treasury)
        external
        onlyGov
    {
        treasury = _treasury;
    }

    function setUserRate(uint256 _userRate)
        external
        onlyGov
    {
        userRate = _userRate;
    }

    function setToken1(address _token)
        external
        onlyGov
    {
        token1 = IERC20(_token);
    }

    function setFeeAddress(address _feeAddress)
        external
        onlyGov
    {
        feeAddress = _feeAddress;
    }

    function setVaultAddress(address _vaultAddress)
        external
        onlyGov
    {
        vaultAddress = _vaultAddress;
    }

    function setFeePermill(uint32 _feePermill)
        external
        onlyGov
    {
        feePermill = _feePermill;
    }

    function setDelayDuration(uint32 _delayDuration)
        external
        onlyGov
    {
        delayDuration = _delayDuration;
    }

    function setWithdrawable(bool _withdrawable)
        external
        onlyGov
    {
        withdrawable = _withdrawable;
    }

    function setVaultName(string memory name)
        external
        onlyGov
    {
        _vaultName = name;
    }

    function balance0()
        external
        view
        returns (uint256)
    {
        return token0.balanceOf(address(this));
    }

    function balance1()
        external
        view
        returns (uint256)
    {
        return token1.balanceOf(address(this));
    }

    function getReward(address userAddress)
        internal
    {
        uint256 lastCheckTime = _lastCheckTime[userAddress];
        uint256 rewardBalance = _rewardBalance[userAddress];
        if (lastCheckTime > 0 && _rewards.length > 0) {
            for (uint i = _rewards.length - 1; lastCheckTime < _rewards[i].timestamp; i--) {
                rewardBalance = rewardBalance.add(_rewards[i].amount.mul(_depositBalances[userAddress]).div(_rewards[i].totalDeposit));
                if (i == 0) break;
            }
        }
        _rewardBalance[userAddress] = rewardBalance;
        _lastCheckTime[msg.sender] = block.timestamp;
    }

    function deposit(uint256 amount) external {
        getReward(msg.sender);

        uint256 feeAmount = amount.mul(feePermill).div(1000);
        uint256 realAmount = amount.sub(feeAmount);
        
        if (feeAmount > 0) {
            token0.safeTransferFrom(msg.sender, feeAddress, feeAmount);
        }
        if (realAmount > 0) {
            token0.safeTransferFrom(msg.sender, vaultAddress, realAmount);
            _depositBalances[msg.sender] = _depositBalances[msg.sender].add(realAmount);
            _totalDeposit = _totalDeposit.add(realAmount);
            emit Deposited(msg.sender, realAmount);
        }
    }

    function withdraw(uint256 amount) external {
        require(token0.balanceOf(address(this)) > 0, "no withdraw amount");
        require(withdrawable, "not withdrawable");
        getReward(msg.sender);

        if (amount > _depositBalances[msg.sender]) {
            amount = _depositBalances[msg.sender];
        }

        require(amount > 0, "can't withdraw 0");

        token0.safeTransfer(msg.sender, amount);

        _depositBalances[msg.sender] = _depositBalances[msg.sender].sub(amount);
        _totalDeposit = _totalDeposit.sub(amount);

        emit Withdrawn(msg.sender, amount);
    }

    function sendReward(uint256 amount) external {
        require(amount > 0, "can't reward 0");
        require(_totalDeposit > 0, "totalDeposit must bigger than 0");
        uint256 amountUser = amount.mul(userRate).div(totalRate);
        amount = amount.sub(amountUser);
        token1.safeTransferFrom(msg.sender, address(this), amountUser);
        token1.safeTransferFrom(msg.sender, treasury, amount);

        Reward memory reward;
        reward = Reward(amountUser, block.timestamp, _totalDeposit);
        _rewards.push(reward);
        emit SentReward(amountUser);
    }

    function claimReward(uint256 amount) external {
        getReward(msg.sender);

        uint256 rewardLimit = getRewardAmount(msg.sender);

        if (amount > rewardLimit) {
            amount = rewardLimit;
        }
        _rewardBalance[msg.sender] = _rewardBalance[msg.sender].sub(amount);
        token1.safeTransfer(msg.sender, amount);
    }

    function claimRewardAll() external {
        getReward(msg.sender);
        
        uint256 rewardLimit = getRewardAmount(msg.sender);
        
        _rewardBalance[msg.sender] = _rewardBalance[msg.sender].sub(rewardLimit);
        token1.safeTransfer(msg.sender, rewardLimit);
    }
    
    function getRewardAmount(address userAddress) public view returns (uint256) {
        uint256 lastCheckTime = _lastCheckTime[userAddress];
        uint256 rewardBalance = _rewardBalance[userAddress];
        if (_rewards.length > 0) {
            if (lastCheckTime > 0) {
                for (uint i = _rewards.length - 1; lastCheckTime < _rewards[i].timestamp; i--) {
                    rewardBalance = rewardBalance.add(_rewards[i].amount.mul(_depositBalances[userAddress]).div(_rewards[i].totalDeposit));
                    if (i == 0) break;
                }
            }
            
            for (uint j = _rewards.length - 1; block.timestamp < _rewards[j].timestamp.add(delayDuration); j--) {
                uint256 timedAmount = _rewards[j].amount.mul(_depositBalances[userAddress]).div(_rewards[j].totalDeposit);
                timedAmount = timedAmount.mul(_rewards[j].timestamp.add(delayDuration).sub(block.timestamp)).div(delayDuration);
                rewardBalance = rewardBalance.sub(timedAmount);
                if (j == 0) break;
            }
        }
        return rewardBalance;
    }

    function seize(address token, address to) external onlyGov {
        require(IERC20(token) != token0 && IERC20(token) != token1, "main tokens");
        if (token != address(0)) {
            uint256 amount = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(to, amount);
        }
        else {
            uint256 amount = address(this).balance;
            payable(to).transfer(amount);
        }
    }
        
    fallback () external payable { }
    receive () external payable { }
}