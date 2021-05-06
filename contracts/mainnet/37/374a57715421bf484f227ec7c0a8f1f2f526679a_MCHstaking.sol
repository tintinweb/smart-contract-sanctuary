/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.8.4;

interface IERC20{

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);
  
  function approve(address spender, uint256 amount) external returns (bool);
  
  function increaseAllowance(address spender, uint256 addedValue) external;

  function decreaseAllowance(address spender, uint256 subtractedValue) external;

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface contract2{
    
    function claimRewards(address user) external returns(bool);
}

interface MCHstakingInterface {
    
    function stakingStats(address user) external view returns(uint256 amount, uint256 stakingBlock) ;
    
    function totalStaked() external view returns(uint256);
    
    function showBlackUser(address user) external view returns(bool) ;
    
    function allowance(address user) external view returns(bool) ;
    
    function transferOwnership(address to) external ;
    
    function giveAllowence(address user) external ;
    
    function removeAllowence(address user) external ;
    
    function addToBlackList(address user) external ;

    function removeFromBlackList(address user) external ;
    
    function stakeMCH(uint256 amount) external ;
    
    function unstake(address user, uint256 amount) external ;
    
    function refreshBlock(address user) external ;    
    
    function setData(address user, uint256 staked, uint256 stakingBlock, uint256 stakedMCH) external ;    
    
    function transferMCH(address to, uint256 amount) external ;
    
    function emergencyWithdraw(uint256 amount) external ;    
    
    event Stake(address indexed staker, uint256 indexed amount);
}
contract MCHstaking is MCHstakingInterface {
    
    address private _owner;
    mapping (address => bool) private _allowence;
    IERC20 MCH;
    contract2 MCF;
    
    mapping (address => uint256) private _staking;
    mapping (address => uint256) private _block;
    
    uint256 _totalStaked;
    
    mapping (address => bool) private _blackListed;
    
    constructor(address MCHtoken) {
        MCH = IERC20(MCHtoken);
        _owner = msg.sender;
        _allowence[msg.sender] = true;
    }
    
    function setMCFcontract(address contractAddress) external {
        require(msg.sender == _owner);
        MCF = contract2(contractAddress);
        _allowence[contractAddress] = true;
    }
    
    //staking stats of a user
    function stakingStats(address user) external view override returns(uint256 amount, uint256 stakingBlock){
        amount = _staking[user];
        stakingBlock = _block[user];
    }
    
    function totalStaked() external view override returns(uint256){
        return _totalStaked;
    }
    //shows if a user is black listed or not
    function showBlackUser(address user) external view override returns(bool){
        require(_allowence[msg.sender]);
        return _blackListed[user];
    }
    
    //shows if a user has allowance or not
    function allowance(address user) external view override returns(bool){
        require(_allowence[msg.sender]);
        return _allowence[user];
    }
    
    //======================================================================================================================================================
    
    function transferOwnership(address to) external override {
        require(_owner == msg.sender);
        _owner = to;
    }
    
    function giveAllowence(address user) external override {
        require(msg.sender == _owner);
        _allowence[user] = true;
    }
    
    function removeAllowence(address user) external override {
        require(msg.sender == _owner);
        _allowence[user] = false;
    }  
    
    function addToBlackList(address user) external override {
        require(_owner == msg.sender);
        _blackListed[user] = true;
    }

    function removeFromBlackList(address user) external override {
        require(_owner == msg.sender);
        _blackListed[user] = false;
    }    
    
    function stakeMCH(uint256 amount) external override {
        MCH.transferFrom(msg.sender, address(this), amount);
            
        if(address(MCF) != address(0)){MCF.claimRewards(msg.sender);}
        _staking[msg.sender] += amount;
        _block[msg.sender] = block.number;
        _totalStaked += amount;
        emit Stake(msg.sender, amount);
    }
    
    function unstake(address user, uint256 amount) external override {
        require(_allowence[msg.sender]);
        _staking[user] -= amount;
        _block[user] = block.number;
        _totalStaked -= amount;
    }
    
    function refreshBlock(address user) external override {
        require(_allowence[msg.sender]);
        _block[user] = block.number;
    }
    
    function setData(address user, uint256 staked, uint256 stakingBlock, uint256 stakedMCH) external override {
        require(_allowence[msg.sender]);
        _staking[user] = staked;
        _block[user] = stakingBlock;
        _totalStaked = stakedMCH;
        
    }
    
    function transferMCH(address to, uint256 amount) external override {
        require(_allowence[msg.sender]);
        require(MCH.balanceOf(address(this)) - _totalStaked >= amount);
        MCH.transfer(to, amount);
    }
    
    function emergencyWithdraw(uint256 amount) external override {
        require(msg.sender == _owner);
        MCH.transfer(_owner, amount);
    }
}