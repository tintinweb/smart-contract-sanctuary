/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

//SPDX-License-Identifier: MIT License

/** 



████████ ██    ██ ██████  ██████   ██████      ██     ██  █████  ██      ██      ███████ ████████ 
   ██    ██    ██ ██   ██ ██   ██ ██    ██     ██     ██ ██   ██ ██      ██      ██         ██    
   ██    ██    ██ ██████  ██████  ██    ██     ██  █  ██ ███████ ██      ██      █████      ██    
   ██    ██    ██ ██   ██ ██   ██ ██    ██     ██ ███ ██ ██   ██ ██      ██      ██         ██    
   ██     ██████  ██   ██ ██████   ██████       ███ ███  ██   ██ ███████ ███████ ███████    ██    
                                                                                                  

██████  ██    ██                                                                                  
██   ██  ██  ██                                                                                   
██████    ████                                                                                    
██   ██    ██                                                                                     
██████     ██                                                                                     
                                                                                      
                                                                                                  
██████  ███████ ███████ ██████  ███    ███  █████  ███████ ███████                                
██   ██ ██      ██      ██   ██ ████  ████ ██   ██    ███  ██                                     
██   ██ █████   █████   ██████  ██ ████ ██ ███████   ███   █████                                  
██   ██ ██      ██      ██      ██  ██  ██ ██   ██  ███    ██                                     
██████  ███████ ███████ ██      ██      ██ ██   ██ ███████ ███████                                
                                                                                                                                                                                    

DEEPMAZE is the world's first crowding pool backed auto-liquidity DeFi token.
2022


title: MIT License
spdx-id: MIT
featured: true
hidden: false

description: A short and simple permissive license with conditions only requiring preservation of copyright and license notices. Licensed works, modifications, and larger works may be distributed under different terms and without source code.

how: Create a text file (typically named LICENSE or LICENSE.txt) in the root of your source code and copy the text of the license into the file. Replace 2022 with the current year and DEEPMAZE FOUNDATION with the name (or names) of the copyright holders.

using:
  Babel: https://github.com/babel/babel/blob/master/LICENSE
  .NET Core: https://github.com/dotnet/runtime/blob/master/LICENSE.TXT
  Rails: https://github.com/rails/rails/blob/master/MIT-LICENSE

permissions:
  - commercial-use
  - modifications
  - distribution
  - private-use

conditions:
  - include-copyright

limitations:
  - liability
  - warranty

---

SPDX-License-Identifier: MIT License

Copyright (c) 2022 DeepMaze Foundation

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


 **/


pragma solidity ^0.6.0;

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function totalSupply() external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

contract TurboWallet_Test is Owned {
    
    //initializing safe computations
    using SafeMath for uint256;

    address public deep;
    uint256 public totalStaked;
    uint256 public minimumStakeValue;
    uint256 public COMPENSATION_RATE_BP;
    uint256 public provision;
    uint256 public activeStaked;
    uint256 public stakeWallets;
    uint256 public totalPaid;

    bool public active = true;
    
    //mapping of stakeholder's addresses to data
    mapping(address => uint256) public stakes;
    mapping(address => uint256) private staking_clock;
    mapping(address => uint256) private ending_clock;

    mapping(address => bool) public registered;
    mapping(address => bool) public done;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public compensations;
    mapping(address => uint256) public totalReturn;

    mapping(uint256    => uint256) public reward_rates;

    //Events
    event OnWithdrawal(address sender, uint256 amount);
    event OnRegisterAndStake(address stakeholder, uint256 amount,uint256 totalReturn);
    
    /**
     * @dev Sets the initial values
     */
    constructor(address _token) public 
    {
            
        //set initial state variables
        deep = _token;

        //90  DAYS APY - 3x +  - 90/365*300 = 73% =   7300 bps + 10000 bps base
        //180 DAYS APY - 4x +  - 180/365*400 = 197% = 19700 bps + 10000 bps base
        //270 DAYS APY - 5x +  - 270/365*500 = 369% =  36900 bps + 10000 bps base
        //360 DAYS APY - 6x +  - 90/365*300 = 591% =   59100 bps+ 10000 bps base

        reward_rates[90]=7300;
        reward_rates[180]=19700;
        reward_rates[270]=36900;
        reward_rates[360]=59100;
        COMPENSATION_RATE_BP=500;
        provision=0;
        activeStaked=0;
        stakeWallets=0;
        totalPaid=0;
        minimumStakeValue=1000 * 10**18;
    }
    

    
    //exclusive access for unregistered address
    modifier onlyUnregistered() {
        require(registered[msg.sender] == false, "Stakeholder is already registered");
        _;
    }
        
    //make sure contract is active
    modifier whenActive() {
        require(active == true, "Smart contract is curently inactive");
        _;
    }
    
    /**
     * registers and creates stakes for new stakeholders
     * deducts the registration tax and staking tax
     * calculates refferal bonus from the registration tax and sends it to the _referrer if there is one
     * transfers DEEP from sender's address into the smart contract
     * Emits an {OnRegisterAndStake} event..
     */
    function registerAndStake(uint256 days_to_stake) external onlyUnregistered() whenActive() {

        uint256 _amount=IERC20(deep).balanceOf(msg.sender);
        require(_amount > minimumStakeValue , "More than minimum To Stake");

        require(reward_rates[days_to_stake] > 0, "Rewards Defined Date");

        uint256 REWARD_RATE_BP=reward_rates[days_to_stake];
        uint256 reward=_amount.mul(REWARD_RATE_BP).div(10000);
        uint256 compensate=_amount.mul(COMPENSATION_RATE_BP).div(10000);

        require(reward > 0, "Correct Calculation");
        require(IERC20(deep).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");
        require (IERC20(deep).balanceOf(address(this)).sub(reward).sub(_amount).sub(compensate).sub(provision) > 0, "No more DEEP to distribute");
        
        provision=provision.add(reward);
        provision=provision.add(_amount);
        provision=provision.add(compensate);

        registered[msg.sender] = true;
        done[msg.sender]=false;

        staking_clock[msg.sender] = now;
        uint256 stakeTime= days_to_stake.mul(86400);
        ending_clock[msg.sender] = staking_clock[msg.sender].add(stakeTime);
        totalStaked = totalStaked.add(_amount);
        activeStaked=activeStaked.add(_amount);
        stakes[msg.sender] = (stakes[msg.sender]).add(_amount);
        stakeWallets=stakeWallets.add(1);
        rewards[msg.sender] = (rewards[msg.sender]).add(reward);
        compensations[msg.sender]=compensations[msg.sender].add(compensate);
        totalReturn[msg.sender] = totalReturn[msg.sender].add(reward).add(_amount).add(compensate);

        emit OnRegisterAndStake(msg.sender, _amount,totalReturn[msg.sender]);
    }
    
    
    
    //transfers total active earnings to stakeholder's wallet
    function withdrawReturns() external returns (bool success) {
        //calculates the total redeemable rewards
        uint256 totalReward = totalReturn[msg.sender];
        //makes sure user has rewards to withdraw before execution
        require(totalReward > 0, 'No reward to withdraw'); 
        require(now >=ending_clock[msg.sender],'Time is not due'); 
        require (done[msg.sender]==false,"Already Withdrawn");
        require (registered[msg.sender],"Not Registered");

        done[msg.sender]=true;
        totalReturn[msg.sender]=0;
        rewards[msg.sender]=0;
        stakes[msg.sender]=0;
        ending_clock[msg.sender]=0;
        compensations[msg.sender]=0;
        rewards[msg.sender]=0;
        totalPaid=totalPaid.add(totalReward);
        provision=provision.sub(totalReward);
        activeStaked=activeStaked.sub(totalReward);
        //transfers total rewards to stakeholder
        IERC20(deep).transfer(msg.sender, totalReward);
        //emit event
        emit OnWithdrawal(msg.sender, totalReward);
        return true;
    }

    //used to view the current reward pool
    
    function DEEPBalance() external view returns(uint256 deep_balance) {
        return (IERC20(deep).balanceOf(address(this)));
    }

    function FreeDEEPBalance() external view returns(uint256 free_deep_balance) 
    {
        return (IERC20(deep).balanceOf(address(this)).sub(provision));
    }

    function CommitedDEEP() external view returns(uint256 committed_deep) 
    {
        return (provision);
    }

    function GetStakeDetails() external view returns(uint256 staked_amount,uint256 stake_start,uint256 stake_end,uint256 reward,uint256 compensation) 
    {
        return (stakes[msg.sender],staking_clock[msg.sender],ending_clock[msg.sender],rewards[msg.sender],compensations[msg.sender]);
    }

    function IsStaked() external view returns(bool is_staked) 
    {
        bool return_staked=false;
        if (stakes[msg.sender]>0)
        {
            return_staked=true;
        }
        return (return_staked);
    }

    function calculateReward(uint256 days_to_stake,uint256 amount) external view returns(uint256 reward,uint256 compensation,uint256 total_reward,uint256 amount_) 
    {
        uint256 _amount=amount;
        uint256 REWARD_RATE_BP=reward_rates[days_to_stake];
        uint256 _reward=_amount.mul(REWARD_RATE_BP).div(10000);
        uint256 compensate=_amount.mul(COMPENSATION_RATE_BP).div(10000);
        uint256 _total_reward=_amount.add(compensate).add(_reward);
        return (_reward,compensate,_total_reward,_amount);
    }
    //used to pause/start the contract's functionalities
    function changeActiveStatus(bool status_bool) external onlyOwner() 
    {
        active=status_bool;
    }
    

    function setMinimumStakeValue(uint256 _minimumStakeValue) external onlyOwner() 
    {
        minimumStakeValue = _minimumStakeValue;
    }
    function setRewardRate(uint256 days_to_stake, uint256 reward_rate_in_bp) external onlyOwner() 
    {
        reward_rates[days_to_stake] = reward_rate_in_bp;
    }
    function setCompensationRate(uint256 _compensation_rate_bp) external onlyOwner() 
    {
        COMPENSATION_RATE_BP = _compensation_rate_bp;
    }
    function changeStakeEnd(uint256 _endingTime,address staker) external onlyOwner() 
    {
        ending_clock[staker]=_endingTime;
    }

    function withdrawFreeDEEP() external onlyOwner returns (bool success) 
    {
        //makes sure _amount is not more than required balance
        //transfers _amount to _address
        uint256 _amount=IERC20(deep).balanceOf(address(this)).sub(provision);
        require (_amount > 0);
        
        IERC20(deep).transfer(msg.sender, _amount);
        //emit event
        emit OnWithdrawal(msg.sender, _amount);
        return true;
    }
}