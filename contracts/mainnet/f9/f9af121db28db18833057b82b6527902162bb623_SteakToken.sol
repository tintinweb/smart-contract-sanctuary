/**
 *Submitted for verification at Etherscan.io on 2020-12-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_, uint8 decimals_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract SteakToken is ERC20 {
    using SafeMath for uint;
    
    event staked(address sender, uint amount, uint lockedTime);
    event unstaked(address sender, uint amount);
    
    address private _owner;
    address private _minter;
    address private _sales;
    address private _tokenContract;
    
    uint private stakeBuffer = 10000000000;
    uint private stakedSupply = 0;
    
    // Staking
    uint yearInMs = 220752000;
    struct StakeType {
        uint rewardPercent; // Percent reward to get each period
        uint lockedTime; // How long the stake is locked before allowed to withdraw
    }
    mapping(uint => StakeType) private _stakingOptions;
    
    struct Stake {
        uint amount; // Amount staked
        uint startTime; // When staking started
        uint stakeType; // Type of stake
    }
    mapping(address => Stake[]) private _staking;
    
    constructor () public  ERC20("Steak", "STEAK", 18){
        _owner = tx.origin;
        
        _stakingOptions[0].rewardPercent = 1000;
        _stakingOptions[0].lockedTime = 0;
        
        _stakingOptions[1].rewardPercent = 2000;
        _stakingOptions[1].lockedTime = 604800;
        
        _stakingOptions[2].rewardPercent = 3500;
        _stakingOptions[2].lockedTime = 2592000;
        
        _stakingOptions[3].rewardPercent = 5000;
        _stakingOptions[3].lockedTime = 31536000;
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
    function getMyBalance() public view returns(uint) {
        return balanceOf(msg.sender);
    }
    
    /* Get all tokens inkl staked
     *
     */
    function getMyFullBalance() public view returns(uint) {
        uint balance = balanceOf(msg.sender);
        for (uint i = 0; i < _staking[msg.sender].length; i++){
            balance += getStakeAmount(i);
        } 
        return balance;
    }
    
    /* Set the token contract for which to call for the stake reward
     *
     */
    function setTokenContract(address _address) public {
        require(_msgSender() == _owner,"Only owner can set token contract!");
        _tokenContract = _address;
    }
    
    /* Sets the address allowed to mint
     *
     */
    function setMinter(address minter_) public {
        require(msg.sender == _owner, "Only owner can set minter!");
        _minter = minter_;
    }
    
    /* 
     *
     */
    function setSales(address sales_) public {
        require(msg.sender == _owner, "Only owner can set minter!");
        _sales = sales_;
    }
    
    /* Mint an amount of tokens to an address
     *
     */
    function mint(address address_, uint256 amount_) public {
        require(msg.sender == _minter || msg.sender == _sales, "Only minter can mint tokens!");
        _mint(address_, amount_);
    }
    
    /*
     *
     */
    function mintToMultipleAddresses(address[] memory _addresses, uint _amount) public {
        require(_msgSender() == _owner,"Only owner can mint to multiple addresses!");
        for(uint i = 0; i < _addresses.length; i++){
            _mint(_addresses[i],  _amount);
        }
    }
    
    /* Stake
     *
     */
    function stake(uint amount_, uint stakeType_) public {
        _burn(msg.sender, amount_);
        stakedSupply += amount_;
        Stake memory temp;
        temp.amount = amount_;
        temp.startTime = now;
        temp.stakeType = stakeType_;
        _staking[msg.sender].push(temp);
        emit staked(msg.sender, amount_, _stakingOptions[stakeType_].lockedTime);
    }
    
    /* Get all stakes a address holds
     *
     */
    function getStakes() public view returns (uint[3][] memory) {
        uint[3][] memory tempStakeList = new uint[3][](_staking[msg.sender].length);
        for (uint i = 0; i < _staking[msg.sender].length; i++){
            tempStakeList[i][0] = getStakeAmount(i);
            tempStakeList[i][1] = getRemainingLockTime(i);
            tempStakeList[i][2] = getStakeReward(i);
        } 
        return tempStakeList;
    }
    
    /* Returns the amount of token provided with a stake.
     *
     */
    function getStakeAmount(uint stake_) public view returns (uint) {
        return _staking[msg.sender][stake_].amount;
    } 
    
    /* returns true or false depending on if a stake is locked
     * or free to withdraw.
     */
    function isStakeLocked(uint stake_) private view returns (bool) {
        uint stakingTime = now - _staking[msg.sender][stake_].startTime;
        return stakingTime < _stakingOptions[_staking[msg.sender][stake_].stakeType].lockedTime;
    }
    
    /* Returns the remaining lock time of a stake, if unlocked
     * returns 0.
     */
    function getRemainingLockTime(uint stake_) public view returns (uint) {
        uint stakingTime = now - _staking[msg.sender][stake_].startTime;
        if (stakingTime < _stakingOptions[_staking[msg.sender][stake_].stakeType].lockedTime) {
            return _stakingOptions[_staking[msg.sender][stake_].stakeType].lockedTime - stakingTime;
        } else {
            return 0;
        }
    }
    
    /* Calculates the current reward of a stake.
     * Get time staked
     * Add a buffer to circumvent float calculations
     * Gets amount of periods staked
     * Multiplies the periods staked with the reward percent amount
     * Multiplies the reward by the amount staked
     * Removed the buffer
     * Removes the percent buffer
     */
    function getStakeReward(uint stake_) public view returns (uint) {
        uint stakingTime = now - _staking[msg.sender][stake_].startTime;
        uint buffededStakingTime = stakingTime * stakeBuffer;
        uint periods = buffededStakingTime / yearInMs;
        uint buffedRewardPeriodPercent = periods * _stakingOptions[_staking[msg.sender][stake_].stakeType].rewardPercent;
        uint buffedReward = _staking[msg.sender][stake_].amount * buffedRewardPeriodPercent;
        uint rewardPerc = buffedReward / stakeBuffer;
        uint reward = rewardPerc / 100;
        return reward;
    }
    
    /* Unstake previous stake, mints back the original tokens,
     * sends mint function call to reward contract to mint the
     * reward to the sender address.
     */
    function unstake(uint stake_) public {
        require(isStakeLocked(stake_) != true, "Stake still locked!");
        _mint(msg.sender, _staking[msg.sender][stake_].amount);
        stakedSupply -= _staking[msg.sender][stake_].amount;
        uint _amount = getStakeReward(stake_);
        (bool success, bytes memory returnData) = address(_tokenContract).call(abi.encodeWithSignature("mint(address,uint256)",msg.sender, _amount));
        require(success);
        _removeIndexInArray(_staking[msg.sender], stake_);
        emit unstaked(msg.sender, _amount);
    }
    
    /* Walks through an array from index, moves all values down one
     * step the pops the last value.
     */
    function _removeIndexInArray(Stake[] storage _array, uint _index) private {
        if (_index >= _array.length) return;
        for (uint i = _index; i<_array.length-1; i++){
            _array[i] = _array[i+1];
        }
        _array.pop();
    }
}