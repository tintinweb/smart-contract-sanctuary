/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// SPDX-License-Identifier: MIT
// test contract!
// SquirtSquad - SQUIRT Tokens time-locked smart contract
//
// The following contract offers peace of mind to investors as the
// SQUIRT Tokens and any BNB that will go to the members of the Squirt Squad team
// will be time-locked whereby Neither xDai nor SQUIRT tokens cannot be withdrawn
// from the smart contract for a minimum of 7 days after the pre-sale ends, 
// and after this period, at a maximum rate of 5% per week over 20 weeks
//
// Withdraw functions can only be called when the current timestamp is 
// greater than the time specified in each function
// ----------------------------------------------------------------------------



// ERC20 token interface /////////////////////////////////////

pragma solidity ^0.8.0;


interface Token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// SQUIRT token contract ///////////////////////////////////////

abstract contract SQUIRTToken is Token {


event transferred(uint256 _value);


    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    
   
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}



///////////////////////////////////////////////////////////////////////////////
// Main withdrawal contract
//////////////////////////////////////////////////////////////////////////////

contract SquirtSquadTeamFunds {

    address public thisContractAddress;
    address public admin;
    
    // address of the SQUIRT token contract 
    ///////////////////////////////////////////////////////////////////////////////////
    address public tokenContractAddress = 0x35aF3C2560A4b3575770cE7717a4e5A2265585EF;
    ///////////////////////////////////////////////////////////////////////////////////
    

    // the first team withdrawal can be made after:
    // GMT: Friday, 19th November 2021 10:00:00
    // expressed as Unix epoch time (1637316000)
    // https://www.epochconverter.com/
    // uint256 public unlockDate = 1637316000;
    
    // for testing this contract the unlock date will be at 21:15pm November 8th (1636406100)
    uint256 public unlockDate = 1636406100;
    
    // percentage of SQUIRT tokens that can be withdrawn each week
    uint256 public weeklyPercentage = 5;
    
    // aactual amount to be withdrawn expressed as percentage of total SQUIRT
    uint256 public SSMember1Percentage = 15;
    uint256 public SSMember2Percentage = 15;
    uint256 public SSMember3Percentage = 15;
    uint256 public SSMember4Percentage = 15;
    uint256 public SSMember5Percentage = 10;
    uint256 public SSMember6Percentage = 10;
    uint256 public SSMember7Percentage = 10;
    uint256 public SSMember8Percentage = 10;
    
    // withdrawal stages (number of weeks)
    uint public numberOfStages = 20;
    
    // current withdrawal week
    uint public withdrawalweek;
    
    // wallet addresses of Squirt Sqaud members entitlted to claim
    address public SSMember1 = 0xe684c062E7578F16fB674979271Eb33A0DEF5D58;  // 15%
    address public SSMember2 = 0x98d0Da707789a0Bf2043d0E0f5aCa8B11162002B;  // 15%
    address public SSMember3 = 0x62382e49099bf04A29B603BaEe8aEae3f6B2e756;  // 15%
    address public SSMember4 = 0x295bD6488315b8f747D75cbDe1e493420984A8c0;  // 15%
    address public SSMember5 = 0xC62720b950545A8569136a1451376Ce00d3BDeDc;  // 10%
    address public SSMember6 = 0xc48900a74666554DCA7890ffFB17F8e8f5dF4718;  // 10%
    address public SSMember7 = 0xaC73f4c0b87167c7ca304e8639fb11D38B8639F2;  // 10%
    address public SSMember8 = 0xfb6a2E7A80a947B0472421764E958B6EE4f0b0Ad;  // 10%
    

    // time of the contract creation
    uint256 public createdAt;
    
    // first withdrawal confirms final contract balance
    uint256 public contractBalance;
    
    // confirm first withdrawal
    bool public firstWithdrawal;
    
    // confirm balance after unlock date
    bool public balanceConfirmed;
    
    event Received(address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    SQUIRTToken public token;

    constructor() {
        admin = msg.sender;
        thisContractAddress = address(this);
        createdAt = block.timestamp;
        token = SQUIRTToken(tokenContractAddress);
        thisContractAddress = address(uint160(address(this)));
    }


    // fallback
    fallback() external payable {}
    receive() external payable {}
    
    
    
    // check the xDai balance of THIS contract 
    function thisContractBalanceXDAI() public view returns(uint) {
        return address(this).balance;
    }
    
    // check the SQUIRT token balance of THIS contract  
    function thisContractBalanceSQUIRT() public view returns(uint) {
        return token.balanceOf(address(this));
    }
    
    
    // confirm contract balance and assign it to variable
    // anyone can call this after the unlock date
    function confirmBalance() public payable {
        require(token.balanceOf(address(this)) > 10);
        require(block.timestamp >= unlockDate);
        require(firstWithdrawal == false);
        require(balanceConfirmed == false);
        contractBalance = token.balanceOf(address(this));
        balanceConfirmed = true;
    }
    
    
    function payout() private {
        require(block.timestamp >= unlockDate);
                    token.transfer(SSMember1, ((contractBalance/100)*SSMember1Percentage)/20);
                    token.transfer(SSMember2, ((contractBalance/100)*SSMember2Percentage)/20);
                    token.transfer(SSMember3, ((contractBalance/100)*SSMember3Percentage)/20);
                    token.transfer(SSMember4, ((contractBalance/100)*SSMember4Percentage)/20);
                    token.transfer(SSMember5, ((contractBalance/100)*SSMember5Percentage)/20);
                    token.transfer(SSMember6, ((contractBalance/100)*SSMember6Percentage)/20);
                    token.transfer(SSMember7, ((contractBalance/100)*SSMember7Percentage)/20);
                    token.transfer(SSMember8, ((contractBalance/100)*SSMember8Percentage)/20);

                    withdrawalweek = withdrawalweek + 1;
    }
    
    
    
    

    //Main function - withdraw SQUIRT Team tokens after the unlock date
    // 7 days = 604800 seconds
    function withdrawSquirtForTeam() public payable {
        require(block.timestamp >= unlockDate);
        require(withdrawalweek < 21);
        require(unlockDate + 604800 < block.timestamp);
                    payout();
                    // push the new unlock date back an extra week
                    unlockDate = unlockDate + 604800;
    }
    
    

    
    
    function currentEpochtime() public view returns(uint256) {
        return block.timestamp;
    }
    
    
    
}