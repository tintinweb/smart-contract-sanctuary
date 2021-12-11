/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// https://tronscan.io/#/contract/TJ8TutTbUvvhM27Ka8vAxzAKGgTLUaSvm8/code
// SPDX-License-Identifier: MIT

// ==0.5.17
pragma solidity ^0.5.0;

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
    function average(uint a, uint b) internal pure returns (uint) {
        
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        return c;
    }
    
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function burn(address account, uint amount) external;
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    
    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {

        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract LPWrapper {
    using SafeMath for uint;
    // using SafeERC20 for IERC20;

    IERC20 public LP; 

    uint private _totalSupply;
    mapping(address => uint) private _balances;
    // mapping(address => uint) private _balances2;

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function deposit(uint amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        LP.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        LP.transfer(msg.sender, amount);
    }
}

contract PunkMinV3 is LPWrapper {
    IERC20 public DAK;
    uint public LengthDay = 150 days;

    uint public totalDAKAmount = 1500 * 10000 * 1e18;
    uint public StartTimestamp = block.timestamp + 10;
    uint public EndTimestamp = StartTimestamp + LengthDay;
    uint public StartRewardTime; // 开始结算奖励时间
    uint public MintPerSecond = totalDAKAmount.div(LengthDay);

    uint public lastRewardTimestamp = StartTimestamp;
    uint public lastRewardTimestamp2 = StartTimestamp;
    uint public accTokenPerShareStored; // 相当于acc
    uint public accTokenPerShareStored2; // 相当于acc

    mapping(address => uint) public userAccTokenPerShare;
    mapping(address => uint) public userAccTokenPerShare2; // 邀请的每股分红
    mapping(address => uint) internal rewards; // 待领取奖金表
    mapping(address => uint) internal rewards2; // 待领取邀请奖金表
    
    mapping(address => address) public inviters; // 邀请列表，传入用户，返回邀请人
    mapping(address => uint) public invitersAmount; // 作为团长的邀请总数，用来计算奖励
    uint public totalInvitersAmount;

    address public DEAD = address(0x000000000000000000000000000000000000dEaD);

    // 这个仅仅沦为显示，计算奖励不用他了，用的是invitersAmount和totalInvitersAmount
    struct InviterList {
        address Customer;
        uint DepositAmount;
        uint InviterTime;
    }
    mapping(address => InviterList[] ) public invitations;

    event RewardAdded(uint reward);
    event Staked(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RewardPaid(address indexed user, uint reward);

    modifier updateReward(address account) {
        accTokenPerShareStored = accTokenPerShare();
        lastRewardTimestamp = nowTimestamp();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userAccTokenPerShare[account] = accTokenPerShareStored;
        }
        _;
    }

    // 在deposit里已经判断了是否真实邀请，这里必须是account，谁调用这里谁自己解决团长问题，比如参数写nviters[msg.sender] 
    function updateReward2(address account) internal {
        accTokenPerShareStored2 = accTokenPerShare2();
        lastRewardTimestamp2 = nowTimestamp();
        if (account != address(0)) {
            rewards2[account] = earned2(account);
            userAccTokenPerShare2[account] = accTokenPerShareStored2;
        }
    }

    constructor (address _DAK, IERC20 _LP) public{
      DAK = IERC20(_DAK);
      LP = _LP;
    }

    function nowTimestamp() public view returns (uint) {
        return Math.min(block.timestamp, EndTimestamp);
    }

    function accTokenPerShare() public view returns (uint) {
        if (totalSupply() == 0) {
            return accTokenPerShareStored;
        }
        return
            accTokenPerShareStored.add(
                nowTimestamp()
                    .sub(lastRewardTimestamp)
                    .mul(MintPerSecond)
                    .mul(6)
                    .div(10)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    // 这个也要加入是否是真实邀请的判断，总额是totalInvitersAmount
    function accTokenPerShare2() public view returns (uint) {
        if (totalInvitersAmount == 0) {
            return accTokenPerShareStored2;
        }
        return
            accTokenPerShareStored2.add(
                nowTimestamp()
                    .sub(lastRewardTimestamp2)
                    .mul(MintPerSecond)
                    .mul(4)
                    .div(10)
                    .mul(1e18)
                    .div(totalInvitersAmount)
            );
    }

    function earned(address account) public view returns (uint) {
        return
            balanceOf(account)
                .mul(accTokenPerShare().sub(userAccTokenPerShare[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // 这个还没改，计算邀请奖励
    function earned2(address account) public view returns (uint) {
        return
            invitersAmount[account]
                .mul(accTokenPerShare2().sub(userAccTokenPerShare2[account]))
                .div(1e18)
                .add(rewards2[account]);
    }

    // 合并挖矿奖励和邀请奖励
    function currentReward (address account) public view returns(uint) {
        return earned(account) + earned2(account);
    }

    function deposit(uint amount, address _inviter) public updateReward(msg.sender)  checkStart{ 
        require(amount > 0, "Cannot Deposit 0");
        require(block.timestamp < EndTimestamp, "mint finish");

        if (LP.balanceOf(address(this)) == 0) {
            StartRewardTime = block.timestamp;
            lastRewardTimestamp = block.timestamp;
        }

        if (totalInvitersAmount == 0) {
            lastRewardTimestamp2 = block.timestamp;
        }

        // 新用户添加邀请者
        if (inviters[msg.sender] == address(0)) {
            inviters[msg.sender] = _inviter;
            invitations[_inviter].push(InviterList({
                Customer : msg.sender,
                DepositAmount : amount,
                InviterTime : block.timestamp // 仅仅前端查询用，不影响结算
            }));
        }

        // 重读 ，如果是真实邀请才给上级计数
        address inviter = inviters[msg.sender];
        if (inviter != address(0) && inviter != address(DEAD)) {
            updateReward2(inviter); // 这里应该结算上级的，改成inviters[msg.sender];
            InviterList[] storage invitation = invitations[inviters[msg.sender]];
            for (uint i = 0; i < invitation.length; i++) {
                if (invitation[i].Customer == msg.sender) {
                    invitation[i].DepositAmount += amount;
                }
            }

            totalInvitersAmount += amount;
            invitersAmount[inviter] += amount;
        }

        super.deposit(amount); // 拿走LP
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint amount) public updateReward(msg.sender) checkStart{
        require(amount > 0, "Cannot withdraw 0");

        if (inviters[msg.sender] != address(0) && inviters[msg.sender] != address(DEAD)) {
            updateReward2(inviters[msg.sender]); // 更新团长的lastRewardTimestamp2

            // 提走后LP，需要更新团长的数量了
            InviterList[] storage invitation = invitations[inviters[msg.sender]];
            for (uint i = 0; i < invitation.length; i++) {
                if (invitation[i].Customer == msg.sender) {
                    invitation[i].DepositAmount -= amount;
                }
            }
            totalInvitersAmount -= amount;
            invitersAmount[inviters[msg.sender]] -= amount;
        }

        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    // 紧急提款
    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    // 每个人过来提奖励都是提自己的，提自己作为团长的奖励
    function getReward() public updateReward(msg.sender) checkStart{
        require(block.timestamp > StartRewardTime, "NoBody Deposit LP Yet");
        uint reward = earned(msg.sender);
        uint reward2;

        // 这里不需要判断上级是不是DEAD，因为是算自己作为团长的
        updateReward2(msg.sender); //更新自己作为团长的last
        reward2 = earned2(msg.sender);

        rewards[msg.sender] = 0;
        rewards2[msg.sender] = 0;

        transfer(msg.sender, reward + reward2);
        emit RewardPaid(msg.sender, reward + reward2);
    }

    function transfer(address _to, uint _amount) internal {
        uint tokenBalance = DAK.balanceOf(address(this));
        if(_amount > tokenBalance) {
            DAK.transfer(_to, tokenBalance);
        } else {
            DAK.transfer(_to, _amount);
        }

    }

    modifier checkStart(){
        require(block.timestamp > StartTimestamp,"Game Not Start");
        _;
    }

}