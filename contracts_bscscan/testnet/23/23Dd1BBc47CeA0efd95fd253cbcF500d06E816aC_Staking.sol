pragma solidity ^0.5.0;

import "./6_LDT.sol";

contract Staking {
    string public name = "Farming test";
    LDTToken public stkToken;

    //declaring owner state variable
    address public owner;

    //declaring default APY (default 0.1% daily or 36.5% APY yearly)
    uint256 public defaultAPY = 100;

    //declaring APY for custom staking ( default 0.137% daily or 50% APY yearly)
    uint256 public customAPY = 137;

    //declaring total staked
    uint256 public totalStaked;
    uint256 public customTotalStaked;

    //users staking balance
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public customStakingBalance;

    //mapping list of users who ever staked
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public customHasStaked;

    //mapping list of users who are staking at the moment
    mapping(address => bool) public isStakingAtm;
    mapping(address => bool) public customIsStakingAtm;

    //array of all stakers
    address[] public stakers;
    address[] public customStakers;

    constructor(LDTToken _stkToken) public payable {
        stkToken = _stkToken;

        //assigning owner on deployment
        owner = msg.sender;
    }

    function stakeTokens(uint256 _amount) public {
        //must be more than 0
        require(_amount > 0, "amount cannot be 0");

        //User adding tokens
        stkToken.transferFrom(msg.sender, address(this), _amount);
        totalStaked = totalStaked + _amount;

        //updating staking balance for user by mapping
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        //checking if user staked before or not, if NOT staked adding to array of stakers
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        //updating staking status
        hasStaked[msg.sender] = true;
        isStakingAtm[msg.sender] = true;
    }

    //unstake tokens function

    function unstakeTokens() public {
        //get staking balance for user

        uint256 balance = stakingBalance[msg.sender];

        //amount should be more than 0
        require(balance > 0, "amount has to be more than 0");

        //transfer staked tokens back to user
        stkToken.transfer(msg.sender, balance);
        totalStaked = totalStaked - balance;

        //reseting users staking balance
        stakingBalance[msg.sender] = 0;

        //updating staking status
        isStakingAtm[msg.sender] = false;
    }

    // different APY Pool
    function customStaking(uint256 _amount) public {
        require(_amount > 0, "amount cannot be 0");
        stkToken.transferFrom(msg.sender, address(this), _amount);
        customTotalStaked = customTotalStaked + _amount;
        customStakingBalance[msg.sender] =
        customStakingBalance[msg.sender] +
        _amount;

        if (!customHasStaked[msg.sender]) {
            customStakers.push(msg.sender);
        }
        customHasStaked[msg.sender] = true;
        customIsStakingAtm[msg.sender] = true;
    }

    function customUnstake() public {
        uint256 balance = customStakingBalance[msg.sender];
        require(balance > 0, "amount has to be more than 0");
        stkToken.transfer(msg.sender, balance);
        customTotalStaked = customTotalStaked - balance;
        customStakingBalance[msg.sender] = 0;
        customIsStakingAtm[msg.sender] = false;
    }

    //airdropp tokens
    function redistributeRewards() public {
        //only owner can issue airdrop
        require(msg.sender == owner, "Only contract creator can redistribute");

        //doing drop for all addresses
        for (uint256 i = 0; i < stakers.length; i++) {
            address recipient = stakers[i];

            //calculating daily apy for user
            uint256 balance = stakingBalance[recipient] * defaultAPY;
            balance = balance / 100000;

            if (balance > 0) {
                stkToken.transfer(recipient, balance);
            }
        }
    }

    //customAPY airdrop
    function customRewards() public {
        require(msg.sender == owner, "Only contract creator can redistribute");
        for (uint256 i = 0; i < customStakers.length; i++) {
            address recipient = customStakers[i];
            uint256 balance = customStakingBalance[recipient] * customAPY;
            balance = balance / 100000;

            if (balance > 0) {
                stkToken.transfer(recipient, balance);
            }
        }
    }

    //change APY value for custom staking
    function changeAPY(uint256 _value) public {
        //only owner can issue airdrop
        require(msg.sender == owner, "Only contract creator can change APY");
        require(
            _value > 0,
            "APY value has to be more than 0, try 100 for (0.100% daily) instead"
        );
        customAPY = _value;
    }

    //cliam test 100 Tst (for testing purpose only !!)
    function claimTst() public {
        address recipient = msg.sender;
        uint256 tst = 100;
        uint256 balance = tst;
        stkToken.transfer(recipient, balance);
    }
}