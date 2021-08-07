/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; 

contract Owned {
    
    /// Modifier for owner only function call
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    address public owner;
   
    /// Function to transfer ownership 
    /// Only owner can call this function
    function changeOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
}

contract Freeze is Owned {
    
    /// To check if the contract is frozen
    modifier freezeCheck() {
        require(isFreeze==false,"Contract have frozen");
        _;
    }
    bool public isFreeze;
    
    /// Changes freeze status of Contract
    /// Only owner can call this function
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
    
    mapping (address=>uint256) internal balances;
    mapping (address=>mapping (address=>uint256)) internal allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    /// Returns the token balance of the address which is passed in parameter
    function balanceOf(address _owner) view public  returns (uint256 balance) {return balances[_owner];}
    
    /**
     * Requirements:
     *
     * - recipient cannot be the zero address.
     * - the caller must have a balance of at least amount.
     */
    function transfer(address _to, uint256 _amount) public freezeCheck returns (bool success) {
        
        require(_to != address(0), "Transfer to zero address");
        require (balances[msg.sender]>=_amount && _amount>0 && balances[_to]+_amount>balances[_to], "Insufficient amount or allowance error");
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
  
     /**
     * Requirements:
     *
     * - sender and recipient cannot be the zero address.
     * - sender must have a balance of at least amount.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * amount.
     */
    function transferFrom(address _from,address _to,uint256 _amount) public freezeCheck returns (bool success) {
      
        require(_from != address(0), "Sender cannot be zero address");
        require(_to != address(0), "Recipient cannot be zero address");
        require (balances[_from]>=_amount && allowed[_from][msg.sender]>=_amount && _amount>0 && balances[_to]+_amount>balances[_to], "Insufficient amount or allowance error");
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    /**
     * Requirements:
     *
     * - spender cannot be the zero address.
     */
    function approve(address _spender, uint256 _amount) public returns (bool success) {

require(_spender != address(0), "Approval for zero address");
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    /**
     *  Returns allowance for an address approved for contract
     */
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    /** @dev Creates amount tokens and assigns them to account, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with from set to the zero address.
     *
     * Requirements:
     *
     * - account cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal  virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    /**
     * @dev Destroys amount tokens from account, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with to set to the zero address.
     *
     * Requirements:
     *
     * - account cannot be the zero address.
     * - account must have at least amount tokens.
     */ 
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
    
    mapping(address => LockedAccounts) internal lock;
    
    /**
     * @dev Owner locks 'amount' tokens on behalf of an address
     * 
     * Requirements:
     * 
     * - 'amount' has to be greater than zero
     * - '_lockAccount' cannot be zero address
     */ 
    function timeLock(address _lockAccount, uint time, uint amount) external onlyOwner  freezeCheck returns (bool) {
        require(amount > 0, "TimeLock: Amount cannot be zero");
        require(_lockAccount != address(0), "TimeLock: Cannot lock for zero address");
        transfer(address(this), amount);
        lock[_lockAccount].account = _lockAccount;
        lock[_lockAccount].amount = amount;
        lock[_lockAccount].time = time;
        lock[_lockAccount].locked.push(Locked(time, amount, block.timestamp));
        return true;
    }
    
    /**
     * @dev User can release their tokens after lock time has been reached
     * 
     * Requirements:
     * 
     * - msg.sender must not have an empty array of locked amount
     * - lock time must be reached before releasing
     */ 
    function release() external freezeCheck returns (bool) {
        
        LockedAccounts storage lockedAccount = lock[msg.sender];
        uint len = lockedAccount.locked.length;
        require(len > 0);
        
        for(uint i = 0; i < len; i++) {
            Locked storage loc = lockedAccount.locked[i];
            require(block.timestamp >= (loc.time + loc.lockedAt), "TimeLock: Release time not reached");
            uint amount = loc.amount;
            BEP(address(this)).transfer(msg.sender, amount);

delete loc.amount;
            delete loc.time;
            delete loc.lockedAt;
        }
        return true;
    }
    
    /**
     * @return Account details for address for which tokens have been locked
     */ 
    function lockedAccountDetails(address user) external view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory, uint) {
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

contract TORN is TimeLock {
    
    /**
     * @dev Sets symbol, name, decimals and totalSupply of the token
     * 
     * - Sets msg.sender as the owner of the contract
     * - Transfers totalSupply to owner
     */ 
    constructor()   {
        symbol = "TORN";
        name = "TORN Token";
        decimals = 18;                                    
        totalSupply = 9999999 * 10**18;           
       
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    /**
     * @dev Calls mint function from BEP20 contract
     * 
     * Requirements:
     * 
     * - only owner can call this function
     * - 'to' address cannot be zero address
     */
    function mint(address to, uint amount) external freezeCheck {
        require(msg.sender == owner, "only admin");
        require(to != address(0), "No mint to zero address");
        _mint(to, amount);
    }
    
    /**
     * @dev Calls burn function from BEP20 contract
     * 
     * Requirements:
     * 
     * - only owner can call this function
     * - 'from' address cannot be zero address
     */
    function burn(address from, uint amount) external freezeCheck {
        require(msg.sender == owner, "only admin");
        require(from != address(0), "No burn from zero address");
        _burn(from, amount);
    }
    
    
   
}