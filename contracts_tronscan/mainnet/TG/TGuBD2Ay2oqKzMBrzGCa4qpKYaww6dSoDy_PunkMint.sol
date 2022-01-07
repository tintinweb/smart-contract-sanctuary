//SourceUnit: PunkMint.sol

// SPDX-License-Identifier: MIT
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

        
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract LPWrapper {
    using SafeMath for uint;
    IERC20 public LP; 
    uint private _totalSupply;
    mapping(address => uint) private _balances;

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

contract PunkMint is LPWrapper {
    IERC20 public DAK;
    uint public LengthDay = 150 days;
    uint public totalDAKAmount = 1500 * 10000 * 1e18;
    uint public StartTimestamp = 1641787200;// 2022-01-10 12:00:00 BJS
    uint public EndTimestamp = StartTimestamp + LengthDay;
    uint public StartRewardTime;
    uint public MintPerSecond = totalDAKAmount.div(LengthDay);
    uint public lastRewardTimestamp = StartTimestamp;
    uint public lastRewardTimestamp2 = StartTimestamp;
    uint public accTokenPerShareStored;
    uint public accTokenPerShareStored2;
    mapping(address => uint) public userAccTokenPerShare;
    mapping(address => uint) public userAccTokenPerShare2; 
    mapping(address => uint) internal rewards; 
    mapping(address => uint) internal rewards2;
    mapping(address => address) public inviters; 
    mapping(address => uint) public invitersAmount; 
    uint public totalInvitersAmount;
    address public DEAD = address(0x000000000000000000000000000000000000dEaD);
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

    
    function earned2(address account) public view returns (uint) {
        return
            invitersAmount[account]
                .mul(accTokenPerShare2().sub(userAccTokenPerShare2[account]))
                .div(1e18)
                .add(rewards2[account]);
    }

    
    function currentReward (address account) public view returns(uint) {
        return earned(account) + earned2(account);
    }

    function deposit(uint amount, address _inviter) public updateReward(msg.sender)  checkStart{ 
        require(amount > 0, "Cannot Deposit 0");        
        require(block.timestamp > StartTimestamp, "Mint Not Start");
        require(block.timestamp < EndTimestamp, "Mint Finish");

        if (LP.balanceOf(address(this)) == 0) {
            StartRewardTime = block.timestamp;
            lastRewardTimestamp = block.timestamp;
        }
        if (totalInvitersAmount == 0) {
            lastRewardTimestamp2 = block.timestamp;
        }
        address _tempInviter = inviters[msg.sender] ;
        if (inviters[msg.sender] == address(0)) {
            inviters[msg.sender] = _inviter;
            invitations[_inviter].push(InviterList({
                Customer : msg.sender,
                DepositAmount : amount,
                InviterTime : block.timestamp 
            }));
        }
        if (inviters[msg.sender] != address(0) && inviters[msg.sender] != address(DEAD)) {
            updateReward2(inviters[msg.sender]); 
            if (_tempInviter != address(0)) {
                InviterList[] storage invitation = invitations[inviters[msg.sender]];
                for (uint i = 0; i < invitation.length; i++) {
                    if (invitation[i].Customer == msg.sender) {
                        invitation[i].DepositAmount += amount;
                    }
                }
            }
            totalInvitersAmount += amount;
            invitersAmount[inviters[msg.sender]] += amount;
        }

        super.deposit(amount); 
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint amount) public updateReward(msg.sender) checkStart{
        require(amount > 0, "Cannot withdraw 0");

        if (inviters[msg.sender] != address(0) && inviters[msg.sender] != address(DEAD)) {
            updateReward2(inviters[msg.sender]); 

            
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

    
    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    
    function getReward() public updateReward(msg.sender) checkStart{
        require(block.timestamp > StartRewardTime, "NoBody Deposit LP Yet");
        uint reward = earned(msg.sender);
        uint reward2;
        updateReward2(msg.sender); 
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
    
    function getInviterList(address _account) public view returns( address[] memory, uint[] memory, uint[] memory) {
        address[] memory Customers = new address[](invitations[_account].length);
        uint[] memory DepositAmounts = new uint[](invitations[_account].length);
        uint[] memory InviterTimes = new uint[](invitations[_account].length);
        for (uint i = 0; i< invitations[_account].length; i++) {
            InviterList storage _userlist = invitations[_account][i];
            Customers[i] = _userlist.Customer;
            DepositAmounts[i] = _userlist.DepositAmount;
            InviterTimes[i] = _userlist.InviterTime;
        }
        return (Customers, DepositAmounts, InviterTimes);
    }

    modifier checkStart(){
        require(block.timestamp > StartTimestamp,"Game Not Start");
        _;
    }

}