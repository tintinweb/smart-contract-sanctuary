/**
 *Submitted for verification at snowtrace.io on 2021-11-15
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

//- IERC20 Interface
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

//- SafeMath Library
library SafeMath {  
    //- Mode Try
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }   
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    
    //- Mode Standart
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SM: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SM: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory SafeMathError) internal pure returns (uint256) {
        require(b <= a, SafeMathError);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SM: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SM: division by zero");
    }
    function div(uint256 a, uint256 b, string memory SafeMathError) internal pure returns (uint256) {
        require(b > 0, SafeMathError);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SM: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory SafeMathError) internal pure returns (uint256) {
        require(b != 0, SafeMathError);
        return a % b;
    }
}

//- Address Library
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    } 
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory AddressError) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, AddressError);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory AddressError) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, AddressError);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory AddressError) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, AddressError);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory AddressError) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, AddressError);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory AddressError) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                 assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(AddressError);
            }
        }
    }
}

//- Context Library
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

//- Ownable Library
abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private  _lockTime;    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = time;
        emit OwnershipTransferred(_owner, address(0));
    }
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock.");
        require(block.timestamp > _lockTime , "Contract is locked.");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

//- ERC20 Safe (used on Stake)
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/*
Roco Stake Contract (Single only Stake)
*/

contract ROCOSTAKE is Context, Ownable {

    using SafeMath  for uint;
    using SafeERC20 for IERC20;

    bool StakeStatus;                       //- Contract Start / Stop
    bool EmergencyStatus;                   //- Emergency Withdraw Status
    uint FeeRate;                           //- Fee Rate in UnStake
    string public Name;                     //- Contract Name
    uint256 public Balance;                 //- Contract Roco Balance
    uint256 public BalanceFee;              //- Contract Roco Balance Fee (only UnStake)
    uint256 public BalanceTemp;             //- Temp Balance for APR Calculation
    uint public RocoPerSecond;              //- Second Per Roco
    uint public mintCumulation;             //- Total Pending
    IERC20 immutable public StakeToken;     //- Roco Token

    //- Stake Variable (pooling)
    uint256 public lastRewardTimeStamp;
    uint256 public totalRocoStake;
    uint256 accRocoPerShare;

    //- User Stake Pool
    struct UserInfo {
        uint amount;        // How many LP tokens the user has provided.
        uint rewardDebt;    // Reward debt.
    }

    event EStake(address User, uint256 Amount);
    event EUnStake(address User, uint256 Amount);

    //- User Pool
    mapping(address => UserInfo) public Users;
    //- Stake
    mapping(address => uint) public stakePool;

    //- Min Max Stake Control
    uint256 public minStake = 1 * 10 ** 18;             //- Mininum Stake (1)
    uint256 public maxStake = 10000 * 10 ** 18;         //- Maximum Stake (10.000)
    uint256 public TotalPool = 10000000 * 10 ** 18;     //- Total Stake Pool Value;

    //- Stake Modifier
    modifier AllowanceCheck(address _staker) {
        require(StakeToken.allowance(_staker, address(this)) > 0, "You have no confirmed balance!");
        _;
    }

    /* Constructor
    _StakeToken : $Roco Token
    _Name : Pool Name
    _RocoPerSecond : Roco per second for Stake (Avalanche BlockChain)
    _BalanceTemp : Pool size required to calculate APR.
    */
    constructor(address _StakeToken, string memory _Name, uint256 _RocoPerSecond, uint256 _BalanceTemp) {
        require(_StakeToken != address(0), "Stake Contract Constructor Error: Address cannot be Zero.");
        StakeToken = IERC20(_StakeToken);
        Name = _Name;
        StakeStatus = true;
        EmergencyStatus = true;
        FeeRate = 1;
        RocoPerSecond = _RocoPerSecond; //- Interest Rate
        BalanceTemp = _BalanceTemp;
    }

    //- Roco per second Value (first start 47500000000000000)
    function UpdatePerRocoSecond(uint value) external returns (bool) {
        uint oldSecond = RocoPerSecond;
        require(value != oldSecond, 'Roco Stake Err: No Change!');
        RocoPerSecond = value;
        return true;
    }

    //- Update Pool
    function RocoUpdate() internal {
        uint256 lastTimeStamp = block.timestamp;
        if (lastTimeStamp <= lastRewardTimeStamp) {
            lastTimeStamp = lastRewardTimeStamp;
        }
        if (totalRocoStake == 0) {
            lastRewardTimeStamp = block.timestamp;
            return;
        }
        uint256 RocoOfSeconds = lastTimeStamp.sub(lastRewardTimeStamp);
        uint256 reward = RocoOfSeconds.mul(RocoPerSecond);
        accRocoPerShare = accRocoPerShare.add(reward.mul(1e36).div(totalRocoStake)); // block.number 1e12 - block.timestamp 1e36
        lastRewardTimeStamp = block.timestamp;
    }

    //- Start Stake
    function Stake(uint _amount) public AllowanceCheck(msg.sender) returns (bool) {
        require(StakeStatus == true, "Staking Off!");
        address staker = msg.sender;

        require(staker != address(0), "Staker Address cannot be zero!");
        require(_amount > 0, "Stakes must be greater than zero!");
        require(minStake > 0, "The minimum stake cannot be zero!");
        require(maxStake > 0, "The maximum stake cannot be zero!");

        /* Approval
        * For approval, a request is first received from the Roco contract.
        * @notice : First event "Approve" second event "StartStake"
        */

        //- StakePool Amount Control
        if (totalRocoStake.add(_amount) > TotalPool) {
            revert("You are exceeding the total stake pool size! Enter a lower stake amount.");
        }

        UserInfo storage userInfo = Users[staker];
        // User to Contract Transfer (RocoSafeControl)
        uint256 stakeBalance = StakeToken.balanceOf(staker);
        require(stakeBalance > 0, "You have no balance!");

        //- Amount Contral & Balance Transfer to Stake Contract
        if ( _amount > stakeBalance ) {
            _amount = stakeBalance;
        }
        //- Stake Amount Control
        if (_amount < minStake) {
            revert("You did not reach the minimum stake!");
        }
        if (_amount > maxStake) {
            revert("You have exceeded the maximum stake!");
        }

        //- Maximum Stake Control for User
        if (userInfo.amount.add(_amount) > maxStake) {
            revert("The user has exceeded the maximum bet amount!");
        }

        StakeToken.safeTransferFrom(staker, address(this), _amount);
        stakePool[staker] = stakePool[staker].add(_amount);
        //- Pool Update
        RocoUpdate();
        //- Pending Reward Calc
        if (userInfo.amount > 0) {
            uint pending = userInfo.amount.mul(accRocoPerShare).div(1e36).sub(userInfo.rewardDebt);
            Balance = Balance.sub(pending);
            BalanceTemp = BalanceTemp.sub(pending);
            StakeToken.safeTransfer(staker, pending);
            mintCumulation = mintCumulation.add(pending);
        }
        //- Add Amount
        totalRocoStake = totalRocoStake.add(_amount);
        userInfo.amount = userInfo.amount.add(_amount);
        userInfo.rewardDebt = userInfo.amount.mul(accRocoPerShare).div(1e36);
        emit EStake(msg.sender, _amount);
        return true;
    }
    //- End Stake

    /*
    @Notice Just send the UnStake amount to 0 "Zero" to get the reward Won.
    */
    //- Start UnStake
    function UnStake(uint _amount) public returns (bool) {
        require(StakeStatus == true, "Staking Off!");
        address staker = msg.sender;
        require(staker != address(0), "Staker Address cannot be zero!");

        UserInfo storage userInfo = Users[staker];
        if (_amount > userInfo.amount) _amount = userInfo.amount;
        if (_amount > 0) {
            stakePool[staker] = stakePool[staker].sub(_amount);
        }

        //- Pool Update
        RocoUpdate();
        uint256 pending = userInfo.amount.mul(accRocoPerShare).div(1e36).sub(userInfo.rewardDebt);
        if (pending > 0) {
            Balance = Balance.sub(pending);
            BalanceTemp = BalanceTemp.sub(pending);
            //- Stake Fee
            uint256 pendingFee = pending.mul(FeeRate).div(100);
            BalanceFee = BalanceFee.add(pendingFee);
            //- Balance Calc & Transfer Pending Reward
            uint256 pFee = pending.sub(pendingFee);
            StakeToken.safeTransfer(staker, pFee);
            mintCumulation = mintCumulation.add(pending);
        }

        //- Sub Amount
        totalRocoStake = totalRocoStake.sub(_amount);
        userInfo.amount = userInfo.amount.sub(_amount);
        userInfo.rewardDebt = userInfo.amount.mul(accRocoPerShare).div(1e36);

        //- Transfer Amount to Stake Owner
        if (_amount > 0) { StakeToken.safeTransfer(staker, _amount); }
        emit EUnStake(staker, _amount);
        return true;
    }
    //- End UnStake

    //- User Pending Reward
    function showPendingReward() external view returns (uint) {
        UserInfo storage userInfo = Users[msg.sender];
        uint256 lastTimeStamp = block.timestamp;
        uint _accRocoPerShare = accRocoPerShare;
        if (lastTimeStamp > lastRewardTimeStamp && totalRocoStake != 0) {
            uint256 RocoOfSeconds = lastTimeStamp.sub(lastRewardTimeStamp);
            uint256 reward = RocoOfSeconds.mul(RocoPerSecond);
            _accRocoPerShare = _accRocoPerShare.add(reward.mul(1e36).div(totalRocoStake));
        }
        return userInfo.amount.mul(_accRocoPerShare).div(1e36).sub(userInfo.rewardDebt);
    }

    function getProductivity(address user) public view returns (uint, uint) {
        return (Users[user].amount, totalRocoStake);
    }

    function RocoPerSecondView() public view returns (uint) {
        return accRocoPerShare;
    }

    function getUserInfo(address user) public view returns (uint256, uint256) {
        return (Users[user].amount, Users[user].rewardDebt);
    }

    // Min Max Stake Amount
    function getMinMaxStakeAmount() public view returns (uint256, uint256) {
        return (minStake,maxStake);
    }

    //- Set Minimum Stake Amount
    function UpdateMinStake(uint256 _minamount) public onlyOwner returns(bool) {
        require(_minamount > 0, "The minimum stake must be greater than Zero!");
        require(_minamount < maxStake, "The minimum stake must be smaller than the maximum stake!");
        minStake = _minamount;
        return true;
    }

    //- Set Maximum Stake Amount
    function UpdateMaxStake(uint256 _maxamount) public onlyOwner returns(bool) {
        require(_maxamount > 0, "The maximum stake must be greater than Zero!");
        require(_maxamount > minStake, "The maximum stake must be greater than the minimum stake!");
        maxStake = _maxamount;
        return true;
    }

    //- Update Fee Rate
    function UpdateFeeRate(uint _feerate) public onlyOwner returns(bool) {
        if (FeeRate == _feerate) revert("Fee Rate No Change!");
        FeeRate = _feerate;
        return true;
    }

    //- Stake Status Change
    function StakeStatusChange(bool _state) public onlyOwner returns(bool) {
        if (StakeStatus == _state) revert("Stake Status No Change!");
        StakeStatus = _state;
        return true;
    }

    //- Emergency Status Change
    function EmergencyStatusChange(bool _state) public onlyOwner returns(bool) {
        if (EmergencyStatus == _state) revert("Emergency Status No Change!");
        EmergencyStatus = _state;
        return true;
    }

    //- Roco Deposit Balance Allowance
    function AllowanceBalance() private view returns(uint256) {
        return StakeToken.allowance(owner(), address(this));
    }

    //- Deposit Contract Operations
    function Deposit() public onlyOwner returns(bool) {
        uint256 _amount = AllowanceBalance();
        require(_amount > 0, "No balance allocated for Allowance!");
        Balance = Balance.add(_amount);
        StakeToken.transferFrom(msg.sender, address(this), _amount);
        return true;
    }

    //- Withdraw Contract Operations
    function Withdraw(uint _amount) public onlyOwner returns(bool) {
        Balance = Balance.sub(_amount);
        StakeToken.transfer(msg.sender, _amount);
        return true;
    }

    /* Total Pool
    @Notice Total Pool and Balance Template Update
    */
    function UpdateTotalPool(uint256 _amount) public onlyOwner returns(bool) {
        if (TotalPool == _amount) revert("Total Pool Value No Change!");
        TotalPool = _amount;
        return true;
    }
    
    function UpdateBalanceTemp(uint256 _temp) public onlyOwner returns(bool) {
        if (BalanceTemp == _temp) revert("Balance Temp Value No Change!");
        BalanceTemp = _temp;
        return true;    
    }

    /* APR
    @Notice APR Calc (Balance * 100) / totalRocoStake; 
    */
    function APR() public view returns(uint256) {
        uint256 apr;
        if (totalRocoStake == 0) { apr = 0;} else
        { apr = BalanceTemp.mul(100).div(totalRocoStake); }
        return apr;
    }

    /* Withdraw Balance Fee
    @Notice Balance fees can only be collected by the Owner for distribution to Stakers.
    */
    function WithdrawStakerFee() public onlyOwner returns(bool) {
        require(BalanceFee > 0, "Fee must be greater than zero!");
        StakeToken.transfer(msg.sender, BalanceFee);
        BalanceFee=0;
        return true;
    }

    /* Withdraw Emergency for Users
    @Notice Withdrawal for emergency users!
    */
    function WithdrawEmergencyUser() public returns(bool) {
        require(EmergencyStatus == false,"This operation cannot be performed!");
        UserInfo storage userInfo = Users[msg.sender];
        uint256 _amount = userInfo.amount;
        userInfo.amount = 0;
        userInfo.rewardDebt = 0;
        //- Transfer Amount to Stake Owner
        StakeToken.safeTransfer(msg.sender, _amount);
        return true;
    }
    
    //- Allowance Amount
    function AllowanceAmount() public view returns(uint256) {
        return StakeToken.allowance(msg.sender, address(this));
    }


}