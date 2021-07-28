/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return payable(msg.sender);
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
        require(_msgSender() == _owner, "Zeca: Only Owner can perform this task");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zeca: Approve to the zero address");
        _newOwner = newOwner;
    }

    function acceptOwnership() external {
        require(_msgSender() == _newOwner, "Zeca: Token Contract Ownership has not been set for the address");
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
        require(sender != address(0), "Zeca: transfer from the zero address");
        require(recipient != address(0), "Zeca: transfer to the zero address");
        require(!_paused, "Zeca: contract paused");
        require(!_blacklists[sender],"Zeca: blacklisted sender account");
        require(!_blacklists[recipient],"Zeca: sender account blacklisted");
        require(!_blacklists[recipient],"Zeca: blacklisted sender account");


        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "Zeca: transfer amount exceeds balance");
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Zeca: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Zeca: decreased allowance below zero"));
        return true;
    }


     function _pause() internal virtual returns (bool)  {
        require(!_paused, "Zeca: contract paused");
        _paused = true;
        return true;
    }

    
    function _unpause() internal virtual returns (bool)  {
        require(_paused, "Zeca: contract not paused");
        _paused = false;
        return true;
    }

   
    function _blacklist(address _address) internal virtual returns (bool) {
        require(!_blacklists[_address], "Zeca: account blacklisted");
        _blacklists[_address] = true;
        return true;
    }

   
    function _whitelist(address _address) internal virtual returns (bool) {
        require(_blacklists[_address], "Zeca: account whitelisted");
        _blacklists[_address] = false;
        return true;
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Zeca: mint to the zero address");
        require(!_paused, "Zeca: contract paused");
        require(!_blacklists[account],"Zeca: blacklisted account");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Zeca: burn from the zero address");
        require(!_paused, "Zeca: contract paused");
        require(!_blacklists[account],"Zeca: blacklisted account");



        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "Zeca: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }


   
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Zeca: approve from the zero address");
        require(spender != address(0), "Zeca: approve to the zero address");
        require(!_paused, "Zeca: contract paused");
        require(!_blacklists[owner],"Zeca: blacklisted owner account");
        require(!_blacklists[spender],"Zeca: blacklisted spender account");



        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}



contract Zeca is BEP20, Owned {
     using SafeMath for uint;
    
    // ############   FILE DECLARATIONS  #############

    //Retrieve a file with it's uniqueID
    mapping(address => mapping(uint => File)) public file;

    //Number of files a particular address has uploaded
    mapping(address => uint) public fileCount;

    //File struct
    struct File {
        uint fileId;
        string fileHash;
        uint fileSize;
        string fileType;
        string fileName;
        string fileDescription;
        uint uploadTime;
        address uploader;
    }
    
    //Upload Event 
    event FileUploaded(
        uint fileId,
        string fileHash,
        uint fileSize,
        string fileType,
        string fileName,
        string fileDescription,
        uint uploadTime,
        address uploader
    );


   //############   STAKING DECLARATIONS    #############
    event Staked(address sender, uint amount, uint lockedTime);
    event Unstaked(address sender, uint amount);
    
    address private _minter;

    uint private stakedSupply = 0;


    struct StakeType {
        uint rewardPercent; //Percent reward to get each period
        uint lockedTime; //How long the stake is locked before allowed to withdraw
        uint maxWithdrawals; //Maximum number of withdrawals 
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

    
    constructor ()  BEP20("Zeca", "ZECA", 8){
                
        //STAKING PLANS
        //staking for 7days 
        _stakingOptions[1].rewardPercent = 15;
        _stakingOptions[1].lockedTime = 7 days;
        _stakingOptions[1].totalStaked = 0;
        _stakingOptions[1].maxWithdrawals = 7;
        
        
        //staking for 14days 
        _stakingOptions[2].rewardPercent = 30;
        _stakingOptions[2].lockedTime = 14 days;
        _stakingOptions[2].totalStaked = 0;
        _stakingOptions[2].maxWithdrawals = 14;


        //staking for 30days 
        _stakingOptions[3].rewardPercent = 55;
        _stakingOptions[3].lockedTime = 30 days;
        _stakingOptions[3].totalStaked = 0;
        _stakingOptions[3].maxWithdrawals = 30;


    
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
            tempStakeList[i][2] = calculateDailyStakeReward(i);
        } 
        return tempStakeList;
    }
    

    
    /* Sets the address allowed to mint
     *
     */
    function setMinter(address minter_) external onlyOwner {
        require(minter_ != address(0), "Zeca: approve to the zero address");
        _minter = payable(minter_);
    }

    /* Puts a hold on token movement in the contract
    *
    */
    function pause() external onlyOwner{
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
         uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "Zeca: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
        return(true);
    }


    /* Mint an amount of tokens to an address
     *
     */
    function mint(address address_, uint256 amount_) external {
        require(_msgSender() == _minter || _msgSender() == _owner, "Zeca: Only minter and owner can mint");
        _mint(address_, amount_);
    }
    
    /*Mint to multiple addresses in an array.
     *
     */
    function mintToMultipleAddresses(address[] memory _addresses, uint[] memory _amount) external onlyOwner {
        uint addressSize = _addresses.length;
        uint amountSize = _amount.length;
        require(addressSize == amountSize, "Zeca: inconsistency in array sizes");
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
        require(isStakeLocked(stake_), "Zeca: stake not locked");
        return _stakingOptions[_staking[_msgSender()][stake_].stakeType].lockedTime - stakingTime;
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
    function getHalvedReward() public view returns (uint) {
            
            uint reward;

            if (getTotalSupply() >= 100000 gwei && getTotalSupply() <= 111680 gwei) {//halvening 1
               reward =  8 gwei;
            }
            else if (getTotalSupply() > 111680 gwei && getTotalSupply() <= 117520 gwei) {//halvening 2
               
               reward =  4 gwei;
            }
            else if (getTotalSupply() > 117520 gwei && getTotalSupply() <= 120440 gwei) { //halvening 3
               
               reward =  2 gwei;
            }
            else if (getTotalSupply() > 120440 gwei && getTotalSupply() <= 121900 gwei) { //halvening 4
               
               reward =  1 gwei;
            }
            else if (getTotalSupply() > 121900 gwei && getTotalSupply() <= 122630 gwei) { //halvening 5
               
               reward =  0.5 gwei;
            }
            else if (getTotalSupply() > 122630 gwei && getTotalSupply() <= 122995 gwei) { //halvening 6
               
               reward =  0.25 gwei;
            }
            else if (getTotalSupply() > 122995 gwei && getTotalSupply() <= 123177.5 gwei) { //halvening 7
               
               reward =  0.125 gwei;
            }
            else if (getTotalSupply() > 123177.5 gwei) { //halvening 8
               
               reward =  0.0625 gwei;
            }
            else {

               reward =  0 gwei;
            }
            
            return reward;
        }

    
    
    
    /* Calculates the Daily Reward of the of a particular stake
    *
     */
    function calculateDailyStakeReward(uint stake_) public view returns (uint) {
        uint reward = getStakeAmount(stake_).mul(getHalvedReward()).mul(_stakingOptions[_staking[_msgSender()][stake_].stakeType].rewardPercent);
        return reward.div(getTotalStakedAmount(_staking[_msgSender()][stake_].stakeType)) / 100;
    }
    
    
            //WITHDRAWALS
    /* Withdraw the staked reward delegated
    *
     */
    function withdrawStakeReward(uint stake_) external {
        require(isStakeLocked(stake_) || (_staking[_msgSender()][stake_].noOfWithdrawals < _stakingOptions[_staking[_msgSender()][stake_].stakeType].maxWithdrawals), "Zeca: Withdrawal no longer available, you can only Unstake now!");
        require(block.timestamp >= _staking[_msgSender()][stake_].lastWithdrawTime + 1 days, "Zeca: withdraw not available");
        _staking[_msgSender()][stake_].noOfWithdrawals++;
        _staking[_msgSender()][stake_].lastWithdrawTime = block.timestamp;
        uint _amount = calculateDailyStakeReward(stake_);
        _mint(_msgSender(), _amount);    
    }
    
    
    
    
     /* Stake
     *
     */
    function stake(uint _amount, uint stakeType_) external {
        require(stakeType_ == 1 || stakeType_ == 2 || stakeType_ == 3, "Zeca: incorrect stake type ");
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
        _stakingOptions[stakeType_].totalStaked += _amount;
        emit Staked(_msgSender(), _amount, _stakingOptions[stakeType_].lockedTime);
    }
    
     function uploadFile(string memory _fileHash,
        uint _fileSize,
        string memory _fileType,
        string memory _fileName,
        string memory _fileDescription ) external {
            //Require fileHash
            require(bytes(_fileHash).length > 0,"DecDrive: No File Hash! ");
            //Require fileType
            require(bytes(_fileType).length > 0,"DecDrive: No File Type! ");
            //Require fileName
            require(bytes(_fileName).length > 0,"DecDrive: No File Name! ");
            //Require fileDescription
            require(bytes(_fileDescription).length > 0,"DecDrive: No File Description! ");
            //Require fileSize
            require(_fileSize > 0,"DecDrive: File Size must be greater than 0 ");
            //Require uploader address exist
            require(_msgSender() != address(0),"DecDrive: Address not valid! ");

            //Increment the number of files.
            fileCount[_msgSender()]++;
            
            //Mint Upload File Reward
            _mint(_msgSender(), 1 gwei);

            //Upload a new file.
            file[_msgSender()][fileCount[_msgSender()]] = File(fileCount[_msgSender()], _fileHash, _fileSize, _fileType, _fileName, _fileDescription, block.timestamp, payable(_msgSender())); 
            //Emit a corresponding event
            emit FileUploaded(fileCount[_msgSender()], _fileHash, _fileSize, _fileType, _fileName, _fileDescription, block.timestamp, payable(_msgSender()));  
    }
    
    
    /* Unstake previous stake, mints back the original tokens,
     * sends mint function call to reward contract to mint the
     * reward to the sender address.
     */
    function unstake(uint stake_) external {
        require(!isStakeLocked(stake_), "Zeca: stake still locked!");
        uint _amount = _staking[_msgSender()][stake_].amount;
        _mint(_msgSender(), _amount);
        stakedSupply.sub(_amount);
        _stakingOptions[_staking[_msgSender()][stake_].stakeType].totalStaked -= _amount;
        _staking[_msgSender()][stake_].stakeActive = false;        
        emit Unstaked(_msgSender(), _amount);
    }
}