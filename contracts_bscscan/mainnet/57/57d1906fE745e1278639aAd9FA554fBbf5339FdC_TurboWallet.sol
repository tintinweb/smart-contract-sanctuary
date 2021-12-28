/**
 *Submitted for verification at BscScan.com on 2021-12-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-21
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

contract TurboWallet is Owned {
    
    //initializing safe computations
    using SafeMath for uint256;

    address public deep;
    uint256 public totalStaked;
    uint256 public minimumStakeValue;
    uint256 public maximumStakeValue;

    uint256 public COMPENSATION_RATE_BP;
    uint256 public provision;
    uint256 public activeStaked;
    uint256 public stakeWallets;
    uint256 public totalPaid;
    uint256 public _baserate;
    uint256 public _icorate;
    uint256 public _longterm;

    bool public active = true;
    bool public icoreward_active=true;
    
    //mapping of stakeholder's addresses to data
    mapping(address => uint256) public stakes;
    mapping(address => uint256) private staking_clock;
    mapping(address => uint256) private ending_clock;

    mapping(address => bool) public registered;
    mapping(address => bool) public done;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public totalReturn;

    mapping(address => uint256) public icoRewardDict;
    mapping(address => uint256) public baseRewardDict;
    mapping(address => uint256) public longtermRewardDict;
    mapping(uint256    => uint256) public reward_rates;

    //Events
    event CurrentAllowance(address owner, uint256 current_allowance);
    event OnWithdrawal(address sender, uint256 amount);
    event OnRegisterAndStake(address stakeholder, uint256 amount,uint256 totalReturn);
    
    /**
     * @dev Sets the initial values
     */
    constructor(address _token) public 
    {
            
        //set initial state variables
        deep = _token;

        //90  DAYS APY - 3.12x +  - 90/365*312   = 76 %  =   7693 bps + 10000 bps base
        //180 DAYS APY - 4.17x +  - 180/365*417  = 205%  =  20564 bps + 10000 bps base
        //270 DAYS APY - 5.19x +  - 270/365*519  = 383%  =  38391 bps + 10000 bps base
        //360 DAYS APY - 6.21x +  - 360/365*621  = 612%  =  61249 bps + 10000 bps base

        reward_rates[90]=7693;
        reward_rates[180]=20564;
        reward_rates[270]=38391;
        reward_rates[360]=61249;
        COMPENSATION_RATE_BP=500;
        provision=0;
        activeStaked=0;
        stakeWallets=0;
        totalPaid=0;
        minimumStakeValue=1000 * 10**18;
        _baserate=2000;
        _icorate=5000;
        _longterm=3000;

        maximumStakeValue=1000000 * 10**18;
        icoreward_active=true;
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
     * transfers DEEP from sender's address into the smart contract
     * Emits an {OnRegisterAndStake} event..
     */
    function registerAndStake(uint256 days_to_stake) external onlyUnregistered() whenActive() returns (bool success){

        uint256 _amount=IERC20(deep).balanceOf(msg.sender);
        if (_amount>maximumStakeValue)
        {
            _amount=maximumStakeValue;
        }
        require(_amount > minimumStakeValue , "More than minimum To Stake");
        require(reward_rates[days_to_stake] > 0, "Rewards Defined Date");

        uint256 REWARD_RATE_BP=reward_rates[days_to_stake];

        if (icoreward_active==false)
        {
            uint256 aje=REWARD_RATE_BP.mul(_icorate).div(10000);
            REWARD_RATE_BP=REWARD_RATE_BP.sub(aje);
        }

        uint256 reward=_amount.mul(REWARD_RATE_BP).div(10000);
        uint256 base_reward=reward.add(_amount);
        uint256 full_bp=10000;
        uint256 divisor=full_bp.sub(COMPENSATION_RATE_BP);
        uint256 compensate=base_reward.mul(COMPENSATION_RATE_BP).div(divisor);
        uint256 totalreward_=base_reward.add(compensate);
        
        
        
        uint256 icoReward=reward.mul(_icorate).div(10000);
        uint256 ltReward=reward.mul(_longterm).div(10000);
        uint256 baseReward=reward.sub(icoReward).sub(ltReward);
        
        if (icoreward_active==false)
        {
            icoReward=0;
            uint256 tots=_longterm.add(_baserate);
            ltReward=reward.mul(_longterm).div(tots);
            baseReward=reward.sub(icoReward).sub(ltReward);
        }

         



        require(reward > 0, "Correct Calculation");
        //require(IERC20(deep).approve(address(this), _amount), "Stake failed due to failed approve.");
        require(IERC20(deep).transferFrom(msg.sender, address(this), _amount), "Stake failed due to failed amount transfer.");
        require (IERC20(deep).balanceOf(address(this)).sub(totalreward_) > 0, "No more DEEP to distribute");
        

        provision=provision.add(totalreward_);
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
        totalReturn[msg.sender] = totalReturn[msg.sender].add(totalreward_);
        
        icoRewardDict[msg.sender]=icoRewardDict[msg.sender].add(icoReward);
        baseRewardDict[msg.sender]=baseRewardDict[msg.sender].add(baseReward);
        longtermRewardDict[msg.sender]=longtermRewardDict[msg.sender].add(ltReward);

        emit OnRegisterAndStake(msg.sender, _amount,totalReturn[msg.sender]);
        return true;
    }


    
    //transfers total active earnings to stakeholder's wallet
    function withdrawReturns() external returns (bool success) {
        //calculates the total redeemable rewards
        //makes sure user has rewards to withdraw before execution
        require(totalReturn[msg.sender] > 0, "No reward to withdraw"); 
        require(now >=ending_clock[msg.sender],"Time is not due"); 
        require (done[msg.sender]==false,"Already Withdrawn");
        require (registered[msg.sender],"Not Registered");

        done[msg.sender]=true;
        activeStaked=activeStaked.sub(stakes[msg.sender]);
        totalPaid=totalPaid.add(totalReturn[msg.sender]);
        provision=provision.sub(totalReturn[msg.sender]);

        
        //transfers total rewards to stakeholder
        IERC20(deep).transfer(msg.sender, totalReturn[msg.sender]);
        //emit event
        emit OnWithdrawal(msg.sender, totalReturn[msg.sender]);
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

    function calculateEarned(address _myaddress) public view returns(uint256 earned_deep) 
    {
        uint256 result=0;
        uint256 total_base=icoRewardDict[_myaddress].add(longtermRewardDict[_myaddress]).add(baseRewardDict[_myaddress]);

        if (registered[_myaddress] && done[_myaddress]==false)
        {
            uint256 time_total=ending_clock[_myaddress].sub(staking_clock[_myaddress]);
            uint256 current_time=now;
            if (current_time<staking_clock[_myaddress])
            {
                current_time=staking_clock[_myaddress];
            }
            uint256 time_passed=current_time.sub(staking_clock[_myaddress]);
            if (time_passed>time_total)
            {
                time_passed=time_total;
            }


            uint256 realized=time_passed.mul(100000000).div(time_total);
            result=total_base.mul(realized);
        }

        if (registered[_myaddress] && done[_myaddress])
        {
            result=total_base.mul(100000000);
        }
        return (result);
    }
    
    function GetStakeDetails(address _myaddress) external view returns(uint256 staked_amount,uint256 stake_start,uint256 stake_end,uint256 ico_reward,uint256 lt_reward,uint256 base_reward,uint256 earned) 
    {

        return (stakes[_myaddress],staking_clock[_myaddress],ending_clock[_myaddress],icoRewardDict[_myaddress],longtermRewardDict[_myaddress],baseRewardDict[_myaddress],calculateEarned(_myaddress));
    }

    function GetStakeStatus(address _myaddress) external view returns(bool IsWIthDrawn,bool IsStaked) 
    {
        return (done[_myaddress],registered[_myaddress]);
    }
    function IsStaked(address _myaddress) external view returns(bool is_staked) 
    {

        return (registered[_myaddress]);
    }

    function IsWithdrawn(address _myaddress) external view returns(bool is_withdrawn) 
    {

        return (done[_myaddress]);
    }


    function calculateRewardDetailAmount(uint256 days_to_stake,uint256 amount) external view returns(uint256 icoReward_,uint256 ltReward_,uint256 baseReward_,uint256 totalReward) 
    {
        uint256 REWARD_RATE_BP=reward_rates[days_to_stake];

        if (icoreward_active==false)
        {
            uint256 aje=REWARD_RATE_BP.mul(_icorate).div(10000);
            REWARD_RATE_BP=REWARD_RATE_BP.sub(aje);
        }

        uint256 reward=amount.mul(REWARD_RATE_BP).div(10000);
        
        
        uint256 icoReward=reward.mul(_icorate).div(10000);
        uint256 ltReward=reward.mul(_longterm).div(10000);
        uint256 baseReward=reward.sub(icoReward).sub(ltReward);
        
        if (icoreward_active==false)
        {
            icoReward=0;
            uint256 tots=_longterm.add(_baserate);
            ltReward=reward.mul(_longterm).div(tots);
            baseReward=reward.sub(icoReward).sub(ltReward);
        }

        return (icoReward,ltReward,baseReward,reward);
    }
    
    function calculateRewardDetailPercent(uint256 days_to_stake,uint256 amount) external view returns(uint256 icoRewardPercent_,uint256 ltRewardPercent_,uint256 baseRewardPercent_,uint256 apys_) 
    {
        uint256 REWARD_RATE_BP=reward_rates[days_to_stake];

        if (icoreward_active==false)
        {
            uint256 aje=REWARD_RATE_BP.mul(_icorate).div(10000);
            REWARD_RATE_BP=REWARD_RATE_BP.sub(aje);
        }

        uint256 reward=amount.mul(REWARD_RATE_BP).div(10000);
        
        
        uint256 icoReward=reward.mul(_icorate).div(10000);
        uint256 ltReward=reward.mul(_longterm).div(10000);
        uint256 baseReward=reward.sub(icoReward).sub(ltReward);
        
        if (icoreward_active==false)
        {
            icoReward=0;
            uint256 tots=_longterm.add(_baserate);
            ltReward=reward.mul(_longterm).div(tots);
            baseReward=reward.sub(icoReward).sub(ltReward);

        }
        uint256 totalR=reward.add(amount);

        uint256 _rois=totalR.mul(10000).div(amount).sub(10000);
        uint256 _apys=_rois.mul(365).div(days_to_stake);
        uint256 icoRewardPercent=icoReward.mul(10000).div(reward);
        uint256 ltRewardPercent=ltReward.mul(10000).div(reward);
        uint256 bp_number=10000;
        uint256 baseRewardPercent=bp_number.sub(ltRewardPercent).sub(icoRewardPercent);

        return (icoRewardPercent.mul(_rois).div(10000),ltRewardPercent.mul(_rois).div(10000),baseRewardPercent.mul(_rois).div(10000),_apys);
    }

    function changeActiveStatus(bool status_bool) external onlyOwner() 
    {
        active=status_bool;
    }
    

    function setMinimumStakeValue(uint256 _minimumStakeValue) external onlyOwner() 
    {
        minimumStakeValue = _minimumStakeValue;
    }
    
    function setMaximumStakeValue(uint256 _maximumStakeValue) external onlyOwner() 
    {
        maximumStakeValue = _maximumStakeValue;
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
    
    function changeBaseRate(uint256 new_bp_rate) external onlyOwner() 
    {
        _baserate=new_bp_rate;
    }
    function changeIcoRate(uint256 new_bp_rate) external onlyOwner() 
    {
        _icorate=new_bp_rate;
    }
    
    function changeLongTerm(uint256 new_bp_rate) external onlyOwner() 
    {
        _longterm=new_bp_rate;
    }
    
    function changeICObool(bool new_ico_bool) external onlyOwner() 
    {
        icoreward_active=new_ico_bool;
    }

    function withdrawFreeDEEP(address send_address, uint256 _myamount) external onlyOwner returns (bool success) 
    {
        //makes sure _amount is not more than required balance
        //transfers _amount to _address
        uint256 withdrawable_amount=IERC20(deep).balanceOf(address(this)).sub(provision);
        if (_myamount==0)
        {
            _myamount=withdrawable_amount;
        }
         
        require (_myamount > 0,"Not Enough To Withdraw");
        require (_myamount <= withdrawable_amount,"Cannot Withdraw");
        
        IERC20(deep).transfer(send_address, _myamount);
        //emit event
        emit OnWithdrawal(send_address, _myamount);
        return true;
    }
}