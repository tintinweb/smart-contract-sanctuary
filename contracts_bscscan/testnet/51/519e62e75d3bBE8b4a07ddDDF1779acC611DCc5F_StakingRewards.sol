// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract StakingRewards {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint public rewardRate;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    address  public  admin;
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    constructor(address _stakingToken, address _rewardsToken,uint _speed) {
        rewardRate = _speed;
         admin = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    
    
    }


modifier onlyOwner(){
    require(msg.sender == admin ,"you are not admin");
    _;
}
function setnewOwner(address _newadmin) external onlyOwner{
admin = _newadmin;

}
function setnew(uint _newspeed) external onlyOwner{
rewardRate=_newspeed;
}

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return 0;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }
    //this is optional function
    function Totalstakes(address account) public view returns(uint) {
    return _balances[account];

}




    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Cannot stake 0");
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, reward);
    }
     function Totalfullstake() public view returns(uint) {
        return _totalSupply;
    }
  function Endpool() public{
    // check if admin has clicked the function
    require(msg.sender == admin , ' you are not the admin');
    // transfer all the remaining tokens to admin
    rewardsToken.transfer(msg.sender,rewardsToken.balanceOf(address(this))-_totalSupply);
    // transfer all the etherum to admin and self selfdestruct the contract

    }


}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}