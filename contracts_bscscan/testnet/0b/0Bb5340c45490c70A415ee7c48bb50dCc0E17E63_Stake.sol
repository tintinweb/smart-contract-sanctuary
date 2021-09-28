/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

pragma solidity = 0.8.4;
// SPDX-License-Identifier: MIT
interface Masterchef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function poolInfo(uint256 _pid)external returns(address,uint256,uint256,uint256);
    function withdraw(uint256 _pid,uint _amount)external;
    function pendingCake(uint256 _pid, address _user)external view returns(uint256);
    function cake()external returns(address);
}

interface Itoken {
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
contract Stake {
    
    struct user {
        uint depositAmount;
        uint earnings;
    }
    
    address public  owner;
    uint public commissionFee = 30;
    address public commissionAddr;
    bool public lockStatus;
    
    event Deposit(address indexed from,uint _type,uint Poolid,uint amount,uint _commission,uint time);
    event Withdraw(address indexed from,uint _type,uint poolid,uint amount,uint _commisson,uint time);
    
    mapping(uint => address)public stakeAddress;
    mapping(uint => uint)public totalSupply;
    mapping(uint => uint)public totalDeposit;
    mapping(uint => uint)public beforeBal;
    mapping(address => mapping(uint => user))public users;
    
    constructor (address _owner) {
        owner = _owner;
        commissionAddr = _owner;
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
     /**
     * @dev Throws if lockStatus is true
     */
    modifier isLock() {
        require(lockStatus == false, "Jupiter: Contract Locked");
        _;
    }
    
    receive()external payable{}
    
    function updateAddress(address _stake1,address _stake2) public onlyOwner {
        stakeAddress[1] = _stake1;
        stakeAddress[2] = _stake2;
    }
    
    function deposit(uint _type,uint256 _pid,uint256 amount) public isLock {
         require(_type == 1 || _type == 2,"Invalid type");
         require (_pid != 0, 'deposit reward by staking');
         user storage userInfo = users[msg.sender][_pid];
         address stake = stakeAddress[_type];
         (address lp,,,) = Masterchef(stake).poolInfo(_pid);
         Itoken(lp).transferFrom(msg.sender,address(this),amount);
         uint commission = amount*commissionFee/100;
         Itoken(lp).transfer(commissionAddr,commission);
         amount = amount - commission;
         Itoken(lp).approve(stake,amount);
         Masterchef(stake).deposit(_pid,amount);
         totalDeposit[_pid] += amount;
         userInfo.depositAmount += amount;
         emit Deposit(msg.sender,_type,_pid,amount,commission,block.timestamp);
    }
    
    function withdraw(uint _type,uint256 _pid,uint256 _amount) public isLock {
         user storage userInfo = users[msg.sender][_pid];
         require(userInfo.depositAmount > 0,"Invest amount zero");
         require(_type == 1 || _type == 2,"Invalid type");
         require (_pid != 0, 'deposit reward by staking');
         address stake = stakeAddress[_type];
         Masterchef(stake).withdraw(_pid,_amount);
         totalSupply[_pid] += Itoken(Masterchef(stake).cake()).balanceOf(address(this));
         userWithdraw(_type,_pid,_amount,msg.sender);
    }
    
    function userWithdraw(uint _type,uint256 _pid,uint256 _amount,address _user)internal {
         user storage userInfo = users[_user][_pid];
         address stake = stakeAddress[_type];
         address _cake = Masterchef(stake).cake();
         uint percent = userInfo.depositAmount*100e18/totalDeposit[_pid];
         uint amt = Itoken(Masterchef(stake).cake()).balanceOf(address(this));
         uint reward = percent*amt/100e18;
         userInfo.earnings += reward;
         Itoken(_cake).transfer(_user,reward);
         
         if (_amount > 0) {
             (address lp,,,) = Masterchef(stake).poolInfo(_pid);
             Itoken(lp).transfer(msg.sender,_amount);
             userInfo.depositAmount -= _amount;
             totalDeposit[_pid] -= _amount;
         }
         emit Withdraw(msg.sender,_type,_pid,_amount,reward,block.timestamp);
        
    }
    
    function pendingReward(uint _type,uint256 _pid, address _user) public view returns(uint256) {
         require(_type == 1 || _type == 2,"Invalid type");
         user storage userInfo = users[_user][_pid];
         address stake = stakeAddress[_type];
         uint256 amt = Masterchef(stake).pendingCake(_pid,address(this));
          uint256 percent = userInfo.depositAmount*100e18/totalDeposit[_pid];
          uint256 reward = percent*amt/100e18;
          return reward;
    }
    
    function updateCommission (address _commission,uint _value) public onlyOwner {
        commissionAddr = _commission;
        commissionFee = _value;
    }
    
    function failSafe(uint _type,address to,uint amount) public onlyOwner {
        require(to != address(0));
        require(_type == 1 || _type ==2);
        address stake = stakeAddress[_type];
        address _cake = Masterchef(stake).cake();
        require(amount > 0 && amount <= Itoken(_cake).balanceOf(address(this)),"Invalid amount");
        Itoken(_cake).transfer(to,amount);
    }
    
    function updateLock(bool _lock) public onlyOwner {
        lockStatus = _lock;
    }
    
    function checkBlock()public view returns(uint) {
        return block.number;
    }
}