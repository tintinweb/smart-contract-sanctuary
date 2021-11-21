/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

pragma solidity ^0.8.10;


contract main_dev {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    uint256 public totalSupply;
    uint256 public maxSupply = 2000;
    uint256 public minSupply =1000;
    string public name = "KLTV2";
    string public symbol = "KLT";
    uint256 public decimals = 5;
    uint256 tootal_dprofit;
    uint256 unpaid_dprofit;
    
    address public owner;
    address public burning_address;
    address public liquid_address;
    
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
        
        totalSupply = 2000 * 10**5;
        balances[msg.sender] = totalSupply;
        
        burn_fee = 2 ;
        burning_address = address(0);
        tootal_dprofit = 0;
        unpaid_dprofit = 0;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
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


    function transfer(address to, uint256 value) public returns(bool) {
        require(to != address(0));
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
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(to != address(0));
        require(from != address(0));
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
    
    function burn(address _who,uint256 _value) public onlyOwner {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who] - _value;
        totalSupply = totalSupply - _value ;
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    function set_burn_fee_to_zero(uint256 confirm) public onlyOwner{ 
        require(confirm == 0,"wrong confirmationString");
        burn_fee = 0; 
    }
    
    
    function reveloution(address newOwner) public onlyOwner{owner =  newOwner;}
    function switch_burning_address(address newBurnAddr) public onlyOwner returns(bool){ burning_address = newBurnAddr; }

}