// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

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

contract pFDIVault {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    struct RewardDivide {
        uint256 amount;
        uint256 startTime;
        uint256 checkTime;
    }

    string public _vaultName;
    IERC20 public token0;
    IERC20 public token1;
    address public feeAddress;
    address public vaultAddress;
    uint32 public feePermill = 5;
    uint256 public delayDuration = 7 days;
    bool public withdrawable;
    
    address public gov;
    uint256 public totalDeposit;
    mapping(address => uint256) public depositBalances;
    mapping(address => uint256) public rewardBalances;
    address[] public addressIndices;

    mapping(uint256 => RewardDivide) public _rewards;
    uint256 public _rewardCount;

    event SentReward(uint256 amount);
    event Deposited(address indexed user, uint256 amount);
    event ClaimedReward(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor (address _token0, address _token1, address _feeAddress, address _vaultAddress, string memory name) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        feeAddress = _feeAddress;
        vaultAddress = _vaultAddress;
        _vaultName = name;
        gov = msg.sender;
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
        public
        view
        returns (uint256)
    {
        return token0.balanceOf(address(this));
    }

    function balance1()
        public
        view
        returns (uint256)
    {
        return token1.balanceOf(address(this));
    }

    function rewardUpdate()
        public
    {
        if (_rewardCount > 0) {
            uint256 i;
            uint256 j;

            for (i = _rewardCount - 1; _rewards[i].startTime < block.timestamp; --i) {
                uint256 duration;
                if (block.timestamp.sub(_rewards[i].startTime) > delayDuration) {
                    duration = _rewards[i].startTime.add(delayDuration).sub(_rewards[i].checkTime);
                    _rewards[i].startTime = uint256(-1);
                } else {
                    duration = block.timestamp.sub(_rewards[i].checkTime);
                }
                _rewards[i].checkTime = block.timestamp;
                uint256 timedAmount = _rewards[i].amount.mul(duration).div(delayDuration);
                uint256 addAmount;
                for (j = 0; j < addressIndices.length; j++) {
                    addAmount = timedAmount.mul(depositBalances[addressIndices[j]]).div(totalDeposit);
                    rewardBalances[addressIndices[j]] = rewardBalances[addressIndices[j]].add(addAmount);
                }
                if (i == 0) {
                    break;
                }
            }
        }
    }

    function depositAll()
        external
    {
        deposit(token0.balanceOf(msg.sender));
    }
    
    function deposit(uint256 _amount)
        public
    {
        require(_amount > 0, "can't deposit 0");

        rewardUpdate();

        uint256 arrayLength = addressIndices.length;
        bool found = false;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (addressIndices[i]==msg.sender){
                found=true;
                break;
            }
        }
        
        if(!found){
            addressIndices.push(msg.sender);
        }
        
        uint256 feeAmount = _amount.mul(feePermill).div(1000);
        uint256 realAmount = _amount.sub(feeAmount);
        
        
        token0.safeTransferFrom(msg.sender, feeAddress, feeAmount);
        token0.safeTransferFrom(msg.sender, vaultAddress, realAmount);
        
        totalDeposit = totalDeposit.add(realAmount);
        depositBalances[msg.sender] = depositBalances[msg.sender].add(realAmount);
        emit Deposited(msg.sender, realAmount);
    }
    
    function sendReward(uint256 _amount)
        external
    {
        require(_amount > 0, "can't reward 0");
        require(totalDeposit > 0, "totalDeposit must bigger than 0");
        token1.safeTransferFrom(msg.sender, address(this), _amount);

        rewardUpdate();

        _rewards[_rewardCount].amount = _amount;
        _rewards[_rewardCount].startTime = block.timestamp;
        _rewards[_rewardCount].checkTime = block.timestamp;
        _rewardCount++;
        emit SentReward(_amount);
    }
    
    function claimRewardAll()
        external
    {
        claimReward(uint256(-1));
    }
    
    function claimReward(uint256 _amount)
        public
    {
        require(_rewardCount > 0, "no reward amount");

        rewardUpdate();

        if (_amount > rewardBalances[msg.sender]) {
            _amount = rewardBalances[msg.sender];
        }

        require(_amount > 0, "can't claim reward 0");

        token1.safeTransfer(msg.sender, _amount);
        
        rewardBalances[msg.sender] = rewardBalances[msg.sender].sub(_amount);
        emit ClaimedReward(msg.sender, _amount);
    }

    function withdrawAll()
        external
    {
        withdraw(uint256(-1));
    }

    function withdraw(uint256 _amount)
        public
    {
        require(token0.balanceOf(address(this)) > 0, "no withdraw amount");
        require(withdrawable, "not withdrawable");
        rewardUpdate();

        if (_amount > depositBalances[msg.sender]) {
            _amount = depositBalances[msg.sender];
        }

        require(_amount > 0, "can't withdraw 0");

        token0.safeTransfer(msg.sender, _amount);

        depositBalances[msg.sender] = depositBalances[msg.sender].sub(_amount);
        totalDeposit = totalDeposit.sub(_amount);

        emit Withdrawn(msg.sender, _amount);
    }

    function availableRewardAmount(address owner)
        public
        view
        returns(uint256)
    {
        uint256 i;
        uint256 availableReward = rewardBalances[owner];
        if (_rewardCount > 0) {
            for (i = _rewardCount - 1; _rewards[i].startTime < block.timestamp; --i) {
                uint256 duration;
                if (block.timestamp.sub(_rewards[i].startTime) > delayDuration) {
                    duration = _rewards[i].startTime.add(delayDuration).sub(_rewards[i].checkTime);
                } else {
                    duration = block.timestamp.sub(_rewards[i].checkTime);
                }
                uint256 timedAmount = _rewards[i].amount.mul(duration).div(delayDuration);
                uint256 addAmount = timedAmount.mul(depositBalances[owner]).div(totalDeposit);
                    availableReward = availableReward.add(addAmount);
                if (i == 0) {
                    break;
                }
            }
        }
        return availableReward;
    }
}