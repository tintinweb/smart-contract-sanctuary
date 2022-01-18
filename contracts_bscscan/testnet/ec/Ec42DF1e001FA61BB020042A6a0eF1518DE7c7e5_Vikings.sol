/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

interface ERC20Interface{
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Vikings {
    mapping(address => uint) public balances;
    mapping(address => bool) whitelisted;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply;
    uint public burnedSupply;
    uint daoTax = 20;
    uint teamTax = 100;
    string public name = "Vikings";
    string public symbol = "SKOL";
    uint public decimals = 18;
    address public owner;
    address public burnWallet = 0x000000000000000000000000000000000000dEaD;
    address public daoWallet = 0x31dcE96Fbb2f08a74ec285aA2489fbba03cCC81E; //CHANGE TO DAO WALLET ADDRESS
    address public teamWallet = 0x6BE8d8C501C0ed97B77900Fd05d6cc4F658Ea1eF;
    address public pairAddress;  
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint value);
    

    //Grants ownership privileges to the address that deploys the contract
    constructor() {
        totalSupply = 7777777 * (10 ** decimals);
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    //Change contract ownership to a new address
    function changeOwner(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }

    //Change DAO tax percentage
    
    function setDAOtax(uint newTax) public onlyOwner{
        daoTax = newTax;
    }

    function setPairAddress(address pair)public onlyOwner{
        pairAddress = pair;
    }

    function setTeamTax(uint newTax) public onlyOwner{
        teamTax = newTax;
    }

    //Change DAO wallet address
    function changeDAOwallet(address newDAOwallet) public onlyOwner{
        daoWallet = newDAOwallet;
    }

    function changeTeamWallet(address newTeamWallet) public onlyOwner{
        teamWallet = newTeamWallet;
    }
    function whitelist(address account) public onlyOwner{
        whitelisted[account] = true;
    }
    function deWhitelist(address account) public onlyOwner{
        whitelisted[account] = false;
    }

    function balanceOf(address tokenOwner) public view returns(uint) {
        return balances[tokenOwner];
    }
    
    function isWhitelisted(address account) public view returns(bool) {
        return whitelisted[account];
    }

    function transfer(address to, uint value) public returns(bool success){
        if(to == pairAddress){
            if(whitelisted[msg.sender] == true && whitelisted[to] == true){
            balances[msg.sender] -= value;
            balances[to] += value;
            }else{
                uint dTax = value/daoTax;
                uint tTax = value/teamTax;
                balances[to] += value-dTax-tTax;
                balances[teamWallet] += tTax;
                balances[daoWallet] += dTax;
                balances[msg.sender] -= value;
            return true;
            }
        }else{
            balances[msg.sender] -= value;
            balances[to] += value;
        }
    }

    function transferFrom(address from, address to, uint tokens) public{
        require(balanceOf(from) >= tokens, 'balance too low');
        if(whitelisted[from] == true && whitelisted[to] == true){
            balances[from] -= tokens;
            balances[to] += tokens;
        }else{
            uint dTax = tokens/daoTax;
            uint tTax = tokens/teamTax;
            balances[to] += tokens-dTax-tTax;
            balances[teamWallet] += tTax;
            balances[daoWallet] += dTax;
            balances[from] -= tokens;
        }
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }


    function burn(address from, uint value) public returns (bool){
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[from] -= value;
        balances[burnWallet] += value;
        burnedSupply += value;
        return true;
    }
}