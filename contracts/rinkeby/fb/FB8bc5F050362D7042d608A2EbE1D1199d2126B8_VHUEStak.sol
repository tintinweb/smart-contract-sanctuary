/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

//Safe Math Interface

contract SafeMath {

    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


//ERC Token Standard #20 Interface

abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract VHUEStak is SafeMath {
    address owner;
    ERC20Interface utilityToken;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event CreateContract(string contractName, address owner);
    event CreateTemplate(uint templateIndex, string templateName);
    event CreateStake(address stakerAddress, uint256 stakeAmount, uint256 aprNumerator, uint256 aprDenominator, uint256 completionDate);
    event RedeemStake(address staker);

    struct Timebox {
        uint256 secs;
        uint256 mins;
        uint256 hourz;
        uint256 dayz;
        uint256 weekz;
    }

    struct Fraction {
        uint256 numerator;
        uint256 denominator;
    }

    struct StakeTemplate {
        string name;
        uint256 secs;
        uint256 mins;
        uint256 hourz;
        uint256 dayz;
        uint256 weekz;
        uint256 withdrawalPeriod;
        uint256 aprNumerator;
        uint256 aprDenominator;
        uint256 instantReturnNumerator;
        uint256 instantReturnDenominator;
        uint256 minimumDSCInvestment;
        string [] otherRewards;
        bool isActive;
        bool isWhitelisted;
    }

    StakeTemplate [] templates;

   struct Stake {
        bool exists;
        string name;
        uint256 secs;
        uint256 mins;
        uint256 hourz;
        uint256 dayz;
        uint256 weekz;
        uint256 withdrawalPeriod;
        uint256 aprNumerator;
        uint256 aprDenominator;
        uint256 minimumDSCInvestment;
        uint256 instantReturnNumerator;
        uint256 instantReturnDenominator;
        string [] otherRewards;
        bool isActive;
        bool isWhitelisted;
        uint256 utilityTokenAmount;
        uint256 startTimestamp;
        uint256 duration;
        uint256 completionTimestamp;
    }

    mapping(address => Stake) addressMap;
    address [] stakedAddresses;

    string contractName;
 
    constructor() {
        contractName = "Vivihue Staking";
        owner = msg.sender;
        emit CreateContract(contractName, owner);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setUtilityToken(ERC20Interface token) external returns(bool success) {
        success = false;
        require(msg.sender == owner, "Not the Owner");
        //require(utilityTokenAddress == address(0), "Utility Token Already Set");
        utilityToken = token;
        success = true;
    }

    function getUtilityToken() public view returns (ERC20Interface) {
        return utilityToken;
    }
    
    function getTemplateCount() external view returns (uint256 count) {
        require(msg.sender == owner, "Not the Owner");
        count = templates.length;
    }

    function createTemplate(
        string calldata name, Timebox calldata timebox,
        uint256 withdrawalPeriod, Fraction calldata apr,  uint256 minimumDSCInvestment,
        Fraction calldata instantReturn, string [] calldata otherRewards,
        bool isActive, bool isWhitelisted)
        external returns (uint256 index) {
        require(msg.sender == owner, "Must be the owner");
        StakeTemplate memory template = StakeTemplate(
            name,
            timebox.secs, timebox.mins, timebox.hourz, timebox.dayz, timebox.weekz,
            withdrawalPeriod,
            apr.numerator, apr.denominator, 
            instantReturn.numerator, instantReturn.denominator, minimumDSCInvestment,
            otherRewards,
            isActive, isWhitelisted
        );
        index = templates.length;
        templates.push(template);
        emit CreateTemplate(index, template.name);
    }
    
    function readTemplate(uint256 templateIndex) external view returns (StakeTemplate memory template) {
        require(msg.sender == owner, "Must be the owner");
        template = templates[templateIndex];
    }

    function getUtilityTokenBalance() public view returns (uint256 availableTokenBalance) {
        //ERC20Interface token = ERC20Interface(utilityTokenAddress);
        availableTokenBalance =  utilityToken.balanceOf(msg.sender);
   }

    function getMinimumDSCInvestment(uint256 index) external view returns (uint256) {
        StakeTemplate memory template = templates[index];
        uint256 minimumDSCInvestment = template.minimumDSCInvestment;
        return minimumDSCInvestment;
    }

    function getTemplateName(uint256 index) external view returns (string memory) {
        StakeTemplate memory template = templates[index];
        string memory name = template.name;
        return name;
    }

    function stakeTemplate(uint256 stakeIndex, uint256 utilityTokenAmount) external returns (uint256 completionTimestamp) {
        completionTimestamp = 0;
//      require(utilityTokenAddress != address(0), "Utility Token is Not Defined");
        require(stakeIndex < templates.length, "Illegal stakeIndex");
        StakeTemplate memory template = templates[stakeIndex];
        Stake memory existingStake = addressMap[msg.sender];
        //require(false "marker reached");
        require(!existingStake.exists, "Stake Already Defined for The Caller's Address");
        require(utilityTokenAmount >= template.minimumDSCInvestment, "Investment below minimum threshold");
        uint256 availableTokenBalance =  utilityToken.balanceOf(msg.sender);
        require(availableTokenBalance >= utilityTokenAmount, "Insufficient Token Balance");
        //require(false, "marker reached");
        require(utilityToken.transferFrom(msg.sender, address(this), utilityTokenAmount), "register failed, stable token transfer in");
        //require(false, "marker reached");
        require(utilityToken.transfer(owner, utilityTokenAmount), "register failed, stable token transfer out");
        uint duration =
            template.secs +
            template.mins * 60 +
            template.hourz * 3600 +
            template.dayz * 24 * 3600 +
            template.weekz * 7 * 24 * 3600;
        completionTimestamp = block.timestamp + duration;
        Stake memory stake = Stake(
            true, template.name,
            template.secs, template.mins, template.hourz, template.dayz, template.weekz,
            template.withdrawalPeriod,
            template.aprNumerator, template.aprDenominator, template.minimumDSCInvestment,
            template.instantReturnNumerator, template.instantReturnDenominator, template.otherRewards,
            template.isActive, template.isWhitelisted,
            utilityTokenAmount, block.timestamp, duration, completionTimestamp
        );
        templates.push(template);
        addressMap[msg.sender] = stake;
        stakedAddresses.push(msg.sender);
        emit CreateStake(msg.sender, utilityTokenAmount, template.aprNumerator, template.aprDenominator, completionTimestamp);
    }

    function readStake(address staker) external view returns (Stake memory stake) {
        require(msg.sender == owner, "Not the Owner");
        stake = addressMap[staker];
    }
}