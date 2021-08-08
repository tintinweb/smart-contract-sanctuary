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
    uint256 private investor_max_return = 100000000000000000000000; // 100k * 10**18 
    // max amount of tokens for presale
    uint256 private max_cap = 15000000000000000000000; //15k*10**18
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
        uint256 pending_reward;
    }
    mapping(address => UserInfo) public user_info;

    // state of ICO
    enum IcoStage {PreICO,ICO,PostICO}
    IcoStage stage;
    

    // tokens of ico
    address public ico_token;
    address public contribution_token;

    constructor(address _ico_token, address _contribution_token){
        ico_token = _ico_token;
        contribution_token = _contribution_token;
        //stage = IcoStage.PreICO;
    }

    function buy_token(uint256 _amount) public{
        require(total_contributed < max_cap, 'sorry maximum cap reached');
        //require(user_info[_msgSender()].isWhitelisted,'not in whitelist');
        require(stage==IcoStage.ICO,'Cant buy before or after ICO');
        require(_amount > 0 && _amount <= investor_max_inversion,'Please set an amount between 1 and 1000 tokens');
        require(user_info[_msgSender()].contribution < investor_max_inversion && (user_info[_msgSender()].contribution + _amount) <= investor_max_inversion, 'You are trying to buy more than u can');

        IERC20(contribution_token).safeTransferFrom(_msgSender(), address(this), _amount);
        user_info[_msgSender()].contribution = user_info[_msgSender()].contribution + _amount;
        total_contributed = total_contributed + _amount;
        user_info[_msgSender()].pending_reward=user_info[_msgSender()].pending_reward + (user_info[_msgSender()].contribution * rate);

    }

    function claim_token() public{
        require(stage==IcoStage.PostICO,'ICO is still on going');
        require(total_rewards > 0,'no more tokens');
        require(!user_info[_msgSender()].didClaim, 'u already claimed');
        require(user_info[_msgSender()].pending_reward > 0, 'no rewards for this address');

        //user_info[_msgSender()].pending_reward=(user_info[_msgSender()].contribution * rate);
        IERC20(ico_token).safeTransfer(_msgSender(), user_info[_msgSender()].pending_reward);

        total_rewards=total_rewards-user_info[_msgSender()].pending_reward;
        user_info[_msgSender()].pending_reward=0;
        user_info[_msgSender()].didClaim=true;
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
}