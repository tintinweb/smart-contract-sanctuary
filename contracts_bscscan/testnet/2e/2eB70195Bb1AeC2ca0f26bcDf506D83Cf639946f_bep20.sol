/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

pragma solidity ^0.8.4;
contract bep20{
    using SafeMath for uint256;
    uint private totalsupply=200000000000;
    string public name="Bucks"; 
    string public symbol="BKS";
    uint public decimal=9;
    address public owner;
    // uint public presale;
    // uint public airdrop;
     address public marketing = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
     address public dev =  0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
     address public launch=0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
     address public own=0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    event Transfer(address indexed from,address indexed to,uint value);
    event Approval(address owner,address indexed spender,uint value);
    mapping(address=>uint)public balances;
    mapping(address=> mapping(address=>uint))public allowances;
    constructor(){
         owner=msg.sender;
        balances[owner]+=totalsupply.mul(60).div(100);
        balances[marketing] += totalsupply.mul(10).div(100);
        balances[dev] += totalsupply.mul(10).div(100);
        balances[launch] += totalsupply.mul(10).div(100);
        balances[own] += totalsupply.mul(10).div(100);
       
    
    }
    function balanceof(address Owner)public view returns(uint){
        return balances[Owner];
    }
    
   
     function Transfor(address to,uint value)public returns(bool){
        require(balanceof(msg.sender)>=value, 'balances too low');
        balances[to] +=value;
        balances[msg.sender] -= value;
        emit Transfer (msg.sender,to,value);
        return true;
    }
    
    function approve(address spender,uint value)public returns(bool){
        allowances[msg.sender][spender]=value;
        emit Approval(msg.sender,spender,value);
        return true;
    }
    function transfrom(address from,address to, uint value)public returns(bool){
        require(balanceof(from)>=value,"balane too low");
        require(allowances[from][msg.sender]>=value,'allowancestoo low');
        emit Transfer(from,to,value);
        balances[to] +=value;
        balances[from] -= value;
        return true;
        
        
    }
    
}
// contract airdrop is bep20{
    
        
// }
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}