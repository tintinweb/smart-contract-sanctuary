/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

pragma solidity ^0.8.2;
contract bep{
     using SafeMath for uint;
    string public name="Bucks";
    string public symbol="BKS";
    uint public   totalsupply=20000000000;
    uint public    decimal=9;
    uint public presale;
    uint public airdrop;
    uint public marketing;
    uint public dev;
    uint public launch;
    uint public owner;
    
    event Transfer(address indexed from,address indexed to,uint value);
    event Approval(address owner,address indexed spender,uint value);
    mapping(address=>uint)public balances;
    mapping(address=> mapping(address=>uint))public allowances;
      constructor(){
        balances[msg.sender]=totalsupply;
        dev=totalsupply*5/100;
        presale=totalsupply*25/100;
        airdrop=totalsupply*5/100;
        marketing=totalsupply*10/100;
        launch=totalsupply*35/100;
        owner=totalsupply*20/100;
        
    }
        function balanceof(address addr)public view returns(uint){
        return balances[addr];
        
    }
    function transfor(address to,uint value)public  {
        require(balanceof(msg.sender)>=value, 'balances too low');
      
        
        balances[to] +=value;
        balances[msg.sender] -= value;
        emit Transfer (msg.sender,to,value);
     }
    
    function approve(address spender,uint value)public{
        allowances[msg.sender][spender]=value;
        emit Approval(msg.sender,spender,value);
        
    }
        function transfrom(address from,address to, uint value)public{
        require(balanceof(from)>=value,"balane too low");
        require(allowances[from][msg.sender]>=value,'allowancestoo low');
        emit Transfer(from,to,value);
        balances[to] +=value;
        balances[from] -= value;
        
        
        
    }
    
}
    library SafeMath {
   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

     
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
 
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
         
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
 
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
 
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
 
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
 
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}