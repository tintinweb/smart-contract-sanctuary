// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Ownable.sol';
import './SafeERC20.sol';


//token price 0.01 - 10000000000000000
//100k tokens max per user - 100000000000000000000000
// por 1 usdc son 100 tokens

contract PolyDefiPreSale is Ownable{
    using SafeERC20 for IERC20;

    uint256 private usdc_price = 1000000000000000000; // 1usdc 
    uint256 private presale_price = 10000000000000000; //octagon presale price 0.01 * 10**16
    uint256 private rate = usdc_price / presale_price; // 100 tokens per user

    // max amount per investor
    uint256 public investor_max_inversion = 1000000000000000000000; // 1000 usdc
    // max amount investor will receive
    uint256 private investor_max_return = 100000000000000000000000; // 100k multis * 10**18 
    // max amount of tokens for presale
    uint256 private max_cap = 1500000000000000000000000; //1.5M *10**18
    // track the contributed amount
    uint total_contributed = 0;
    uint total_rewards = 0;
    
    // track the whitelisted users 
    struct UserInfo 
    {
        //bool isWhitelisted;
        bool didBuy;
        bool didClaim;
        uint256 contribution;
    }
    mapping(address => UserInfo) public user_info;

    // state of ICO
    enum IcoStage {PreICO,ICO,PostICO}
    IcoStage stage;
    

    // tokens of ico
    address public ico_token;
    address public contribution_token;


    event Buy(address indexed from, uint256 amount);
    event Claim(address indexed from, uint256 amount);


    constructor(address _ico_token, address _contribution_token){
        ico_token = _ico_token;
        contribution_token = _contribution_token;
        //stage = IcoStage.PreICO;
    }

    function buy_token(uint256 _amount) public{
        require(total_contributed < max_cap, 'sorry maximum cap reached');
        //require(user_info[_msgSender()].isWhitelisted,'not in whitelist');
        require(stage==IcoStage.ICO,'Cant buy before or after ICO');
        require(_amount > 0 && _amount <= investor_max_inversion,'Please set an amount between 1 and 1000 contribution tokens');
        uint256 contribution = user_info[_msgSender()].contribution;
        require(contribution < investor_max_inversion, 'Contribution is greater than allowed');
        require(contribution + _amount <= investor_max_inversion, 'You are trying to buy more than u can');

        // send the contribution from user to contract 
        IERC20(contribution_token).safeTransferFrom(_msgSender(), address(this), _amount);
        emit Buy(_msgSender(), _amount);
        // add contribution to user_info, 
        user_info[_msgSender()].contribution = contribution + _amount;
        total_contributed = total_contributed + _amount;
        //user_info[_msgSender()].pending_reward=user_info[_msgSender()].pending_reward + (user_info[_msgSender()].contribution * rate);
        
    }

    function claim_token() public{
        require(stage==IcoStage.PostICO,'ICO is still on going');
        require(total_rewards > 0,'no more tokens');
        require(!user_info[_msgSender()].didClaim, 'u already claimed');
        uint256 reward = calculate_reward(_msgSender());
        require(reward > 0, 'no rewards for this address');
        

        //user_info[_msgSender()].pending_reward=reward;
        IERC20(ico_token).safeTransfer(_msgSender(), reward);

        total_rewards=total_rewards-reward;
        //user_info[_msgSender()].pending_reward=0;
        user_info[_msgSender()].didClaim=true;
        emit Claim(_msgSender(), reward);
    }

    function calculate_reward(address _contributor) public view returns(uint256){
        return user_info[_contributor].contribution * rate;
    }
    
    function get_total_contributed() public view returns(uint256){return total_contributed;}
    function get_total_rewards() public view returns(uint256){return total_rewards;}
    //function set_investor_max_inversion(uint256 _amount) public onlyOwner{ investor_max_inversion=_amount; }
    //function add_to_whitelist(address contributor) public onlyOwner{user_info[contributor].isWhitelisted = true;}
    //function remove_from_whitelist(address contributor) public onlyOwner{user_info[contributor].isWhitelisted = false;}
    function change_stage(IcoStage _stage) public onlyOwner{stage=_stage;}
    function get_stage() public view onlyOwner returns(IcoStage){return stage;}

    function deposit_reward(uint256 _amount) external onlyOwner{
        require(_amount>0);
        IERC20(ico_token).safeTransferFrom(_msgSender(), address(this),_amount);
        total_rewards=total_rewards+_amount;
    }
    
    function withdraw_reward() external onlyOwner{
        uint256 amount = IERC20(ico_token).balanceOf(_msgSender());
        require(amount > 0);
        IERC20(ico_token).safeTransfer(_msgSender(),amount);
        total_rewards=0;
    }
    
    function skim_contribution() external onlyOwner{
        uint256 _amount = IERC20(contribution_token).balanceOf(address(this));
        IERC20(contribution_token).safeTransferFrom(_msgSender(), address(this),_amount);
    }
    
}