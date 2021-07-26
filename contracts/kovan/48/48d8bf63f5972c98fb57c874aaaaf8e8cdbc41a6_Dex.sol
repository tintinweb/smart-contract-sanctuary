/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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



interface IBEP20 {
   
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}



contract Owned is Context {

    address public _owner;
    address public _newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(_msgSender() == _owner, "Dex: Only Owner can perform this task");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Dex: Approve to the zero address");
        _newOwner = newOwner;
    }

    function acceptOwnership() external {
        require(_msgSender() == _newOwner, "Dex: Token Contract Ownership has not been set for the address");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
        _newOwner = address(0);
    }
}



abstract contract BEP20 is Context, IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;


    string private _name;
    string private _symbol;
    uint8 private _decimals;

    bool public _paused;

    mapping(address => bool) public _blacklists;




  
    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    

  
    function name() external view returns (string memory) {
        return _name;
    }



    function symbol() external view returns (string memory) {
        return _symbol;
    }

   
    function decimals() external view returns (uint8) {
        return _decimals;
    }

   
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

  
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Dex: transfer from the zero address");
        require(recipient != address(0), "Dex: transfer to the zero address");
        require(!_paused, "Dex: token contract is not available");
        require(!_blacklists[sender],"Dex: sender account already blacklisted");
        require(!_blacklists[recipient],"Dex: sender account already blacklisted");


        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "Dex: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Dex: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Dex: decreased allowance below zero"));
        return true;
    }


     function _pause() internal virtual returns (bool)  {
        require(!_paused, "Dex: token transfer is unavailable");
        _paused = true;
        return true;
    }

    
    function _unpause() internal virtual returns (bool)  {
        require(_paused, "Dex: token transfer is available");
        _paused = false;
        return true;
    }

   
    function _blacklist(address _address) internal virtual returns (bool) {
        require(!_blacklists[_address], "Dex: account already blacklisted");
        _blacklists[_address] = true;
        return true;
    }

   
    function _whitelist(address _address) internal virtual returns (bool) {
        require(_blacklists[_address], "Dex: account already whitelisted");
        _blacklists[_address] = false;
        return true;
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Dex: mint to the zero address");
        require(!_paused, "Dex: token contract is not available");
        require(!_blacklists[account],"Dex: account to mint to already blacklisted");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Dex: burn from the zero address");
        require(!_paused, "Dex: token contract is not available");
        require(!_blacklists[account],"Dex: account to burn from already blacklisted");



        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "Dex: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }


   
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Dex: approve from the zero address");
        require(spender != address(0), "Dex: approve to the zero address");
        require(!_paused, "Dex: token contract approve is not available");
        require(!_blacklists[owner],"Dex: owner account already blacklisted");
        require(!_blacklists[spender],"Dex: spender account already blacklisted");



        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}



contract Dex is BEP20, Owned {
    using SafeMath for uint;
    
    event staked(address sender, uint amount, uint lockedTime);
    event unstaked(address sender, uint amount);
    
    address private _minter;

    uint private stakedSupply = 0;


    struct StakeType {
        uint rewardPercent; // Percent reward to get each period
        uint lockedTime; // How long the stake is locked before allowed to withdraw
        uint maxWithdrawals;
        uint totalStaked; //Total amount staked for a particular StakeType
    }
    
    mapping(uint => StakeType) private _stakingOptions;
    
    struct Stake {
        uint amount; // Amount staked
        uint startTime; // When staking started
        uint stakeType; // Type of stake
        uint lastWithdrawTime; // Track the last lastWithdrawTime time
        uint noOfWithdrawals; // Number of Withdrawals made
        bool stakeActive; //Tracks whether a stake is still active
    }
    
    //Each stake owned by an address
    mapping(address => mapping(uint => Stake)) private _staking;
    
    //Number of stakes owned by an address
    mapping(address => uint) private _stakesCount;

    //deployment time
    uint private deploymentTime;

    
    constructor ()  BEP20("Dex", "DEX", 8){
                
        //STAKING PLANS
        //staking for 3months 
        _stakingOptions[1].rewardPercent = 7;
        _stakingOptions[1].lockedTime = 12 weeks;
        _stakingOptions[1].totalStaked = 0;
        _stakingOptions[1].maxWithdrawals = 12;
        
        
        //staking for 6months 
        _stakingOptions[2].rewardPercent = 15;
        _stakingOptions[2].lockedTime = 24 weeks;
        _stakingOptions[2].totalStaked = 0;
        _stakingOptions[2].maxWithdrawals = 24;


        //staking for 12months 
        _stakingOptions[3].rewardPercent = 30;
        _stakingOptions[3].lockedTime = 48 weeks;
        _stakingOptions[3].totalStaked = 0;
        _stakingOptions[3].maxWithdrawals = 48;


    
        //OWNER
        _owner = _msgSender();
        
        //Time Contract was deployed
        deploymentTime = block.timestamp;

    }
    
  

    /* Set the token contract for which to call for the stake reward
     *
     */
    function getTotalSupply() public view returns(uint) {
        return totalSupply() + stakedSupply;
    }
    
    /* Get available tokens
     *
     */
    function getMyBalance() external view returns(uint) {
        return balanceOf(_msgSender());
    }

    
    /* Get all tokens including staked
     *
     */
    function getMyFullBalance() external view returns(uint) {
        uint balance = balanceOf(_msgSender());
        for (uint i = 1; i < _stakesCount[_msgSender()]; i++){
            balance += getStakeAmount(i);
        } 
        return balance;
    }



      /* Get all stakes a address holds
     */
    function getStakes() external view returns (uint[3][] memory) {
        uint[3][] memory tempStakeList = new uint[3][](_stakesCount[_msgSender()]+1);
        for (uint i = 1; i <= _stakesCount[_msgSender()]; i++){
            tempStakeList[i][0] = getStakeAmount(i);
            tempStakeList[i][1] = getRemainingLockTime(i);
            tempStakeList[i][2] = calculateWeeklyStakeReward(i);
        } 
        return tempStakeList;
    }
    

    
    /* Sets the address allowed to mint
     *
     */
    function setMinter(address minter_) external onlyOwner {
        require(minter_ != address(0), "Dex: approve to the zero address");
        _minter = minter_;
    }

    /* Puts a hold on token movement in the contract
    *
    */
    function pause() external onlyOwner  {
        _pause();
    }
    
    /* Release the hold on token movement in the contract
    *
    */
    function unpause() external onlyOwner {
        _unpause();
    }

      /* Blacklist address from making transfer of tokens.
     *
     */
    function blacklist(address _address) external onlyOwner {
        _blacklist(_address);
    }    

    /* Whitelist address to make transfer of tokens.
     *
     */
    function whitelist(address _address) external onlyOwner {
        _whitelist(_address);
    } 

     /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {BEP20-_burn}.
     */
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
    
    /**
    * @dev Internal function that burns an amount of the token of a given
    * account, deducting from the sender's allowance for said account. Uses the
    * internal burn function.
    * - account The account whose tokens will be burnt.
    * - amount The amount that will be burnt.
        */
    function burnFrom(address account, uint256 amount) external returns (bool) {
         uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "Dex: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
        return(true);
    }


    /* Mint an amount of tokens to an address
     *
     */
    function mint(address address_, uint256 amount_) external {
        require(_msgSender() == _minter || _msgSender() == _owner, "Dex: Only minter and owner can mint tokens!");
        _mint(address_, amount_);
    }
    
    /*Mint to multiple addresses in an array.
     *
     */
    function mintToMultipleAddresses(address[] memory _addresses, uint[] memory _amount) external onlyOwner {
        uint addressSize = _addresses.length;
        uint amountSize = _amount.length;
        require(addressSize == amountSize, "Dex: Inconsistency in array sizes");
        for(uint i = 0; i < addressSize; i++){
            _mint(_addresses[i],  _amount[i]);
        }
    }
    
    
  
   
     /* returns true or false depending on if a stake is locked
     * or free to withdraw.
     */
    function isStakeLocked(uint stake_) public virtual view returns (bool) {
        uint stakingTime = block.timestamp - _staking[_msgSender()][stake_].startTime;
        return stakingTime < _stakingOptions[_staking[_msgSender()][stake_].stakeType].lockedTime;
    }
    
    
    /* Returns the remaining lock time of a stake, if unlocked
     * returns 0.
     */
    function getRemainingLockTime(uint stake_) public view returns (uint) {
        uint stakingTime = block.timestamp - _staking[_msgSender()][stake_].startTime;
        require(isStakeLocked(stake_), "Dex: Stake is not locked");
        return _stakingOptions[_staking[_msgSender()][stake_].stakeType].lockedTime - stakingTime;
        
        
        // if (stakingTime < _stakingOptions[_staking[_msgSender()][stake_].stakeType].lockedTime) {
        //     return _stakingOptions[_staking[_msgSender()][stake_].stakeType].lockedTime - stakingTime;
        // } else {
        //     return 0;
        // }
    }
    
   /* Returns the last Withdrawal time.
     */
    function getLastWithdrawalTime(uint stake_) external view returns (uint) {
       return _staking[_msgSender()][stake_].lastWithdrawTime;
    }
    
    /* Gets the number of withdrawals made already.
     */
    function getNoOfWithdrawals(uint stake_) external view returns (uint) {
        return _staking[_msgSender()][stake_].noOfWithdrawals;
    }
    
    
      /* Returns the amount of token provided with a stake.
     *
     */
    function getStakeAmount(uint stake_) public view returns (uint) {
        return _staking[_msgSender()][stake_].amount;
    } 


    /* Returns the Total number of staked amount for a particular stake option
    *
    */
    function getTotalStakedAmount(uint stakeType_) public view returns (uint) {
        return _stakingOptions[stakeType_].totalStaked;
    }

    
    


    /* Calculates the halved reward of a staking.
    */
    function getHalvedRewardPercentage(uint stakeType_) public view returns (uint) {
            
            uint reward;
            uint percentage = _stakingOptions[stakeType_].rewardPercent;
            
            if (block.timestamp <= deploymentTime + 104 weeks ) {//halvening1 in 2 years
               reward = percentage;
            }
            else if (block.timestamp > deploymentTime + 104 weeks && block.timestamp <= deploymentTime + 208 weeks ) {//halvening2 in 4 years
               reward = percentage/2;
            }
            else if (block.timestamp > deploymentTime + 208 weeks && block.timestamp <= deploymentTime + 312 weeks ) {//halvening3 in 6 years
               reward = percentage/4;
            }
            else if (block.timestamp > deploymentTime + 312 weeks) {
               reward = percentage/6;
            }
            else {

               reward =  0;
            }
            
            return reward;
        }

    
    
    
    /* Calculates the Daily Reward of the of a particular stake
    *
     */
    function calculateWeeklyStakeReward(uint stake_) public view returns (uint) {
        uint reward = getStakeAmount(stake_).mul(getHalvedRewardPercentage(_staking[_msgSender()][stake_].stakeType));
        return reward.div(_stakingOptions[_staking[_msgSender()][stake_].stakeType].maxWithdrawals) / 100;
    }
    
    
            //WITHDRAWALS
    /* Withdraw the staked reward delegated
    *
     */
    function withdrawStakeReward(uint stake_) external {
        require(isStakeLocked(stake_) || (_staking[_msgSender()][stake_].noOfWithdrawals < _stakingOptions[_staking[_msgSender()][stake_].stakeType].maxWithdrawals), "Dex: Withdrawal no longer available, you can only Unstake now!");
        require(block.timestamp >= _staking[_msgSender()][stake_].lastWithdrawTime + 10 weeks, "Dex: Not yet time to withdraw reward");
        _staking[_msgSender()][stake_].noOfWithdrawals++;
        _staking[_msgSender()][stake_].lastWithdrawTime = block.timestamp;
        uint _amount = calculateWeeklyStakeReward(stake_);
        _mint(_msgSender(), _amount);    
    }
    
    
   
    
    
     /* Stake
     *
     */
    function stake(uint _amount, uint stakeType_) external {
        require(stakeType_ == 1 || stakeType_ == 2 || stakeType_ == 3, "Dex: Stake Type not available ");
        _burn(_msgSender(), _amount);
        stakedSupply.add(_amount);
        Stake memory temp;
        temp.amount = _amount;
        temp.startTime = block.timestamp;
        temp.stakeType = stakeType_;    
        temp.lastWithdrawTime = block.timestamp;
        temp.noOfWithdrawals = 0;
        temp.stakeActive = true;
        _stakesCount[_msgSender()]++;
        _staking[_msgSender()][_stakesCount[_msgSender()]] = temp;
        _stakingOptions[stakeType_].totalStaked.add(_amount);
        emit staked(_msgSender(), _amount, _stakingOptions[stakeType_].lockedTime);
    }
    
    
    
    /* Unstake previous stake, mints back the original tokens,
     * sends mint function call to reward contract to mint the
     * reward to the sender address.
     */
    function unstake(uint stake_) external {
        require(!isStakeLocked(stake_), "Dex: Stake still locked!");
        uint _amount = _staking[_msgSender()][stake_].amount;
        _mint(_msgSender(), _amount);
        stakedSupply.sub(_amount);
        _stakingOptions[_staking[_msgSender()][stake_].stakeType].totalStaked.sub(_amount);
        _staking[_msgSender()][stake_].stakeActive = false;        
        emit unstaked(_msgSender(), _amount);
    }
    
}