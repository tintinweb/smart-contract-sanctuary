pragma solidity ^0.4.4;

contract Token {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}


contract YFLAND is StandardToken  {

    string public name;                  
    uint8 public decimals;               
    string public symbol;                
    string public version = 'Y2.1';       
    Token public usdtToken ;
    address public contractOwner;
    uint256 public totalUSDTFarm;
    uint256 public totalcountUSDTFarm;
    uint256 public farmRate;
    uint256 public timeReceiveFarm;
    struct listFarm {
    uint256 amount;
    uint256 timeReceive;
    }

    mapping(address => listFarm) public allFarm;  
    address[] private listAddressFarm;  
    constructor( ) public {
                usdtToken = Token(0xdac17f958d2ee523a2206206994597c13d831ec7); //usdt contract
                totalSupply = 30000000000000000000000;                       
                name = "YFLAND";                                   
                decimals = 18;                            
                symbol = "YFLAND";    
                contractOwner = msg.sender;
                balances[contractOwner] = totalSupply;
                Transfer(address(0),contractOwner,totalSupply);
                totalUSDTFarm = 0;
                totalcountUSDTFarm =0;
                farmRate = 10;
				timeReceiveFarm = 24 * 3600; 
    }
    function transferUSDTtoContractOwner( uint256 _amount) public  returns (bool) {
            require(msg.sender == contractOwner);
            require(usdtToken.balanceOf(address(this)) >= _amount);
            if(msg.sender == contractOwner && usdtToken.balanceOf(address(this)) >= _amount){          
            return usdtToken.transfer(contractOwner,_amount);
            }else{
            return false;    
            }
    }
    function setTimeReceiveFarm( uint256 _hours) public  returns (bool) {
                require(msg.sender == contractOwner);
                if(msg.sender == contractOwner){          
                timeReceiveFarm = _hours * 3600;
                return true;
                }else{
                return false;    
                }                

    }    
    function setFarmRate( uint256 _rate) public  returns (bool) {
            require(msg.sender == contractOwner);
            if(msg.sender == contractOwner){          
            farmRate = _rate;
            return true;
            }else{
            return false;    
            }
    }      
    function getAllFarmAddress()public view returns( address  [] memory){
        return listAddressFarm;
    }
    
    function removeListAddress( address _addr) private  returns (bool) {
        for(uint256 i = 0 ; i < listAddressFarm.length ; i++ ){
            if(listAddressFarm[i] == _addr){
                delete listAddressFarm[i];
            }
        }
        return true;
    }

    function createFarm( uint256 _amount) public returns (bool) {
           require(usdtToken.allowance(msg.sender,address(this)) >= _amount);
           if(usdtToken.allowance(msg.sender,address(this)) >= _amount){
           usdtToken.transferFrom(msg.sender,address(this),_amount);
            allFarm[msg.sender].amount += _amount;
            allFarm[msg.sender].timeReceive = now + timeReceiveFarm;
            removeListAddress(msg.sender);
            listAddressFarm.push(msg.sender);
            totalUSDTFarm  += _amount;
            totalcountUSDTFarm++;
            return true;
            }else{
            return false;    
            }
    }
    function getContractUSDTBalance( ) public view returns (uint256) {
            return usdtToken.balanceOf(address(this));
    }
    function cancelFarm() public  returns (bool) {
            require(allFarm[msg.sender].amount > 0);
            if(allFarm[msg.sender].amount > 0)
            {
            totalcountUSDTFarm--;
            totalUSDTFarm -= allFarm[msg.sender].amount;
            removeListAddress(msg.sender);
            usdtToken.transfer(msg.sender , allFarm[msg.sender].amount);
            allFarm[msg.sender].amount = 0;
            allFarm[msg.sender].timeReceive = 0;                 
            return true;
            }
    }  
    function receiveFarm() public  returns (bool) {
            require(allFarm[msg.sender].amount > 0);
            require(allFarm[msg.sender].timeReceive <= now);
            if(allFarm[msg.sender].amount > 0 && allFarm[msg.sender].timeReceive <= now)
            {
            StandardToken(address(this)).transfer(msg.sender , allFarm[msg.sender].amount * farmRate / 100);
            allFarm[msg.sender].timeReceive = now + timeReceiveFarm;
            return true;
            }
    }   



   

}