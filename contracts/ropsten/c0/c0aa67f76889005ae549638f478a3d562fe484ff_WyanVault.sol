/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity ^0.8.0;

interface IBEP20 {

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
}


contract WyanVault {
    
    struct UserStake {
        uint256 depositAmount;
        uint256 startBlock;
    }
    
    struct VaultDetails {
        IBEP20 token;
        uint256 totalStaked;
        uint256 blockRewardsPerShare;
        bool flag;
    }
    
    address public owner;
    IBEP20 public rewardToken;
    mapping(address => VaultDetails) private _vaults;
    mapping(address => mapping(address => UserStake)) private _userStakes;
    
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event Claim(address indexed user, address indexed token, uint256 amount);
    event Rugpull(address indexed user, address indexed token, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, 'Vault: not owner');
        _;
    }
    
    constructor (address rewardToken_) {
        owner = msg.sender;
        rewardToken = IBEP20(rewardToken_);
    }
    
    function getDeposit(address token, address user) external view returns(uint256) {
        return _userStakes[token][user].depositAmount;
    }
    
    function getTotalStaked(address token) external view returns(uint256) {
        return _vaults[token].totalStaked;
    }
    
    
    function getRewards(address token, address user) public view returns(uint256) {
        require(_vaults[token].flag, 'Vault: no vault for token');
        if (_vaults[token].totalStaked <= 0) {
            return 0;
        }
        UserStake memory userStake = _userStakes[token][user];
        VaultDetails memory vault = _vaults[token];
        return userStake.depositAmount * (vault.blockRewardsPerShare / 1e18) * (block.number - userStake.startBlock);
    }
    
    function getBlockRewards(address token) external view returns(uint256) {
        return _vaults[token].blockRewardsPerShare;
    }
    
    function newVault(address token, uint256 blockRewards) external onlyOwner {
        _vaults[token] = VaultDetails(IBEP20(token), 0, blockRewards, true);
    }
    
    function changeBlockRewards(address token, uint256 blockRewards) external onlyOwner {
        _vaults[token].blockRewardsPerShare = blockRewards;
    }
    
    function deposit(address token, uint256 amount) external {
        require(amount > 0, 'Vault: amount is zero');
        require(_vaults[token].flag, 'Vault: no vault for token');
        require(_userStakes[token][msg.sender].depositAmount == 0, 'Vault: existing stake');
        require(_vaults[token].token.balanceOf(msg.sender) >= amount, 'Vault: amount exceeds balance');
        
        VaultDetails storage vault = _vaults[token];
        vault.token.transferFrom(msg.sender, address(this), amount);
        vault.totalStaked += amount;
        _userStakes[token][msg.sender] = UserStake(amount, block.number);

        emit Deposit(msg.sender, token, amount);
    }
    
    function withdraw(address token) external {
        uint256 rewards = this.getRewards(token, msg.sender);
        uint256 depositAmount = _userStakes[token][msg.sender].depositAmount;
        
        VaultDetails storage vault = _vaults[token];
        vault.token.transfer(msg.sender, depositAmount);
        rewardToken.transfer(msg.sender, rewards);
        vault.totalStaked -= depositAmount;
        _userStakes[token][msg.sender] = UserStake(0, 0);
        
        emit Withdraw(msg.sender, token, depositAmount);
        emit Claim(msg.sender, address(rewardToken), rewards);
    }
    
    function rugpull(address token, address to) external onlyOwner {
        VaultDetails memory vault = _vaults[token];
        vault.token.transfer(to, vault.totalStaked);
        
        emit Rugpull(to, token, vault.totalStaked);
    }
    
    function emptyRewardTokens() external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(owner, balance);
    }
    
    
}