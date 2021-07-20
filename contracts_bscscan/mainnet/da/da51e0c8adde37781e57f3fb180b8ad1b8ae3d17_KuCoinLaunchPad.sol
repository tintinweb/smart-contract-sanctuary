/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// SPDX-License-Identifier: none
pragma solidity 0.8.4; 

contract Owned {
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    address public owner;
   
    function changeOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
}

contract Freeze is Owned {
    modifier freezeCheck() {
        require(isFreeze==false,"Contract have frozen");
        _;
    }
    bool public isFreeze;
   
    function changeFreezeStatus(bool freezeStatus) public onlyOwner {
        isFreeze = freezeStatus;
    }
    
}

interface BEP {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BEP20 is Freeze{
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function balanceOf(address _owner) view public  returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount) public freezeCheck returns (bool success) {
      
        require (balances[msg.sender]>=_amount && _amount>0 && balances[_to]+_amount>balances[_to], "Insufficient amount or allowance error");
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public freezeCheck returns (bool success) {
      
        require (balances[_from]>=_amount && allowed[_from][msg.sender]>=_amount && _amount>0 && balances[_to]+_amount>balances[_to], "Insufficient amount or allowance error");
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function _mint(address account, uint256 amount) internal  virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    
     function _burn(address account, uint256 amount) internal  virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract TimeLock is Owned, BEP20 {
    
    struct LockedAccounts {
        address account;
        uint amount;
        uint time;
        Locked[] locked;
    }
    
    struct Locked {
        uint time;
        uint amount;
        uint lockedAt;
    }
    
    mapping(address => LockedAccounts) lock;
    
    function timelock(address _lockAccount, uint time, uint amount) public onlyOwner  freezeCheck returns (bool) {
        require(amount > 0, "TimeLock: Amount cannot be zero");
        transfer(address(this), amount);
        lock[_lockAccount].account = _lockAccount;
        lock[_lockAccount].amount = amount;
        lock[_lockAccount].time = time;
        lock[_lockAccount].locked.push(Locked(time, amount, block.timestamp));
        return true;
    }
    
    function release() public freezeCheck returns (bool) {
        
        LockedAccounts storage lockedAccount = lock[msg.sender];
        uint len = lockedAccount.locked.length;
        
        for(uint i = 0; i < len; i++) {
            Locked storage loc = lockedAccount.locked[i];
            require(block.timestamp >= (loc.time + loc.lockedAt), "TimeLock: Release time not reached");
            uint amount = loc.amount;
            BEP(address(this)).transfer(msg.sender, amount);
            loc.amount = 0;
            loc.time = 0;
            loc.lockedAt = 0;
        }
        return true;
    }
    
    function lockedAccountDetails(address user) public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory, uint) {
        uint lockedLength = lock[user].locked.length;
        uint[] memory lockedAmounts = new uint[](lockedLength);
        uint[] memory lockTimes = new uint[](lockedLength);
        uint[] memory lockedAt = new uint[](lockedLength);
        uint[] memory totalLockTime = new uint[](lockedLength);
        uint currentTime = block.timestamp;
        
        
        for(uint i = 0; i < lockedLength; i++) {
            lockedAmounts[i] = lock[user].locked[i].amount;
            lockTimes[i] = lock[user].locked[i].time;
            lockedAt[i] = lock[user].locked[i].lockedAt;
            totalLockTime[i] = lock[user].locked[i].time + lock[user].locked[i].lockedAt;
        }
        return(lockedAmounts, lockTimes, lockedAt, totalLockTime, currentTime);
    }
    
  
}

contract KuCoinLaunchPad  is TimeLock {

    constructor()   {
        symbol = "KCLP";
        name = "KuCoin LaunchPad";
        decimals = 18;                                    
        totalSupply = 350000000 * 10**18;           
       
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    function mint(address to, uint amount) external freezeCheck {
        require(msg.sender == owner, 'only admin');
        _mint(to, amount);
    }

    function burn(address from, uint amount) external freezeCheck {
        require(msg.sender == owner, 'only admin');
        _burn(from, amount);
    }
    
    
   
}