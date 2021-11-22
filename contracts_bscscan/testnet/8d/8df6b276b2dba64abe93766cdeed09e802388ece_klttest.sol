/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;


contract klttest {
    mapping(address => uint) internal balances;
    mapping(address => mapping(address => uint)) internal allowance;

    uint256 public totalSupply;
    uint256 public maxSupply = 99132589839;
    uint256 public minSupply = 49566294919;
    string public name = "kltrre";
    string public symbol = "KLT";
    uint256 public decimals = 12;
    uint256 tootal_dprofit;
    uint256 unpaid_dprofit;
    
    address public owner;
    address public burning_address;
    address public liquid_address;
    bool isPause;
    
    //additional fees by MHSN_AL
    uint burn_fee;
    uint liquid_fee = 1;
    uint divi_fee = 2;
    

    //Dividend Mechanism Defenitions
    struct account{
         uint256 GottenDividend;
     }
    mapping(address => account) internal Accounts;
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);

    
    constructor() {
        owner = msg.sender;
        
        totalSupply = 99132589839 * 10**12;
        balances[msg.sender] = totalSupply;
        
        burn_fee = 2 ;
        burning_address = address(0);
        tootal_dprofit = 0;
        unpaid_dprofit = 0;
        
        isPause = false;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
        modifier pauseStat() {
        require(isPause == false,"chain paused!");
        _;
    }
    
    
    function disburse_divStak(address investor) internal returns(bool) {
        uint256 profit = tootal_dprofit - Accounts[investor].GottenDividend;
        if(profit > 0) {
            
            balances[investor] +=  profit;
            Accounts[investor].GottenDividend = tootal_dprofit;
            unpaid_dprofit -= profit;
            }
     return true;
    }
    
    function pcnt(uint256 value,uint percent)  internal pure returns(uint256){  return ((value * percent)/100); }
    
    
    
    function estimatedValueForBurning() public view returns(uint256){
        return totalSupply - minSupply;
    }
    
    function balanceOf(address wallete) public view returns(uint) {
        return balances[wallete];
    }


    function transfer(address to, uint256 value) public pauseStat returns(bool) {
        require(to != address(0));
        require(msg.sender != to);
        require(value > 0,"paying value should be more than 0");
        
        uint256 bfee = pcnt(value,burn_fee);
        uint256 dfee = pcnt(value,divi_fee);
        uint256 lfee = pcnt(value,liquid_fee);
        //uint256 paying_value = value + pcnt(value,burn_fee) + pcnt(value, divi_fee) + pcnt(value,liquid_fee);
        uint256 paying_value = value + bfee + dfee + lfee;
        require(balances[msg.sender] >= paying_value, 'CRSDE:balance too low');
        
        disburse_divStak(msg.sender);
        disburse_divStak(to);
        
        balances[to] += value;
            balances[burning_address] += bfee;
            balances[liquid_address] += dfee;
            unpaid_dprofit = pcnt(value, lfee);
        balances[msg.sender] -= paying_value;
        
        emit Transfer(msg.sender, to, value);
            emit Transfer(msg.sender, burning_address, bfee);
            emit Transfer(msg.sender, liquid_address, lfee);
            
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public pauseStat returns(bool) {
        require(to != address(0));
        require(from != address(0));
        require(from != to);
        require(value > 0,"paying value should be more than 0");
        
        uint256 bfee = pcnt(value,burn_fee);
        uint256 dfee = pcnt(value,divi_fee);
        uint256 lfee = pcnt(value,liquid_fee);
        //uint256 paying_value = value + pcnt(value,burn_fee) + pcnt(value, divi_fee) + pcnt(value,liquid_fee);
        uint256 paying_value = value + bfee + dfee + lfee;
        require(balances[msg.sender] >= paying_value, 'CRSDE:balance too low');
        
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        
        disburse_divStak(from);
        disburse_divStak(to);

        balances[to] += value;
            balances[burning_address] += bfee;
            balances[liquid_address] += dfee;
            unpaid_dprofit = pcnt(value, lfee);
        balances[msg.sender] -= paying_value;
        
        emit Transfer(msg.sender, to, value);
            emit Transfer(msg.sender, burning_address, bfee);
            emit Transfer(msg.sender, liquid_address, lfee);
            
        return true;   
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function burn(uint256 _value) public onlyOwner {
        require(_value <= balances[burning_address]);
        balances[burning_address] -= _value;
        totalSupply -=  _value ;
        emit Burn(burning_address, _value);
        emit Transfer(burning_address, address(0), _value);
    }
    function set_burn_fee_to_zero(uint256 confirm) public onlyOwner{ 
        require(confirm == 0,"wrong confirmationString");
        burn_fee = 0; 
    }
    
    
    function reveloution(address newOwner) public onlyOwner{owner =  newOwner;}
    function switch_burning_address(address newBurnAddr) public onlyOwner { burning_address = newBurnAddr; }
    function switch_liquidity_address(address newlAddr) public onlyOwner { liquid_address = newlAddr; }
    function pause(bool stat) public onlyOwner { isPause = stat; }

}