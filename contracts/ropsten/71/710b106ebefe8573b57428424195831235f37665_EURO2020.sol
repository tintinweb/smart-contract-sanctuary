/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

/*
Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
.*/


pragma solidity ^0.4.21;


contract EURO2020 {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    
    uint256 constant private PRICE_PER_UNIT = 0.03 ether;
    uint256 constant private MAX_AVALIABLE = 1;
    uint256 constant private NUM_TEAMS = 4;
    uint256 private stop_selling;
    uint256 private start_release;
    address private owner;
    mapping (string => uint256) private TEAM_MAP;
    
    mapping (string => uint256) private PAYBACK;
    
    
    
    
    mapping (address => uint256) public balances;
    
    mapping (address => mapping (string => uint256)) private bets;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name = "Project Blockchain Polimi";                   //fancy name: eg Simon Bucks
    uint8 public decimals = 0;                //How many decimals to show.
    string public symbol = "EURO2020";                 //An identifier: eg SBX
    uint256 public totalSupply;

    function EIP20() public { 
        totalSupply = MAX_AVALIABLE*NUM_TEAMS;
        TEAM_MAP['ITA'] = MAX_AVALIABLE;
        TEAM_MAP['FRA'] = MAX_AVALIABLE;
        TEAM_MAP['GER'] = MAX_AVALIABLE;
        TEAM_MAP['ENG'] = MAX_AVALIABLE;
        
        PAYBACK['ITA'] = 0.02 ether;
        PAYBACK['FRA'] = 0.01 ether;
        PAYBACK['GER'] = 0.03 ether;
        PAYBACK['ENG'] = 0.06 ether;
        
        start_release =  now + 18 days; 
        stop_selling = now + 12 days;
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    function bet(string _team, uint256 _amount) public payable returns (bool success) {
        //require(now <= stop_selling);
        //require(msg.value >= _amount*PRICE_PER_UNIT);
        require(TEAM_MAP[_team] >= _amount);
        TEAM_MAP[_team] -= _amount;
        bets[msg.sender][_team] += _amount;
        balances[msg.sender] += _amount;
        return true;
        
    }
    
    function retrive(string _team) public returns (bool success) {
        //require(now >= start_release );
        require(bets[msg.sender][_team] >= 1);
        uint256 amount = bets[msg.sender][_team];
        bets[msg.sender][_team] = 0 ;
        balances[owner] += amount;
        balances[msg.sender] -= amount;
        msg.sender.transfer(PAYBACK[_team]*amount);
        return true;
        
    }
    
}