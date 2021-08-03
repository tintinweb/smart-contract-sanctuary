/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity ^0.8.4;
contract token{
    using SafeMath for uint256;
    uint private totalsupply=200000000000;
    string public name="Bucks";
    string public symbol="BKS";
    uint public decimal=9;
     uint public presale;
     uint public airdrop;
     uint public marketing;
     uint public dev;
     uint public launch;
     uint public Owner; 
    event Transfer(address indexed from,address indexed to,uint value);
    event Approval(address owner,address indexed spender,uint value);
    mapping(address=>uint)public balances;
    mapping(address=> mapping(address=>uint))public allowances;
    constructor(){
        balances[msg.sender]=totalsupply;
        presale=totalsupply*25/100;
        airdrop=totalsupply*5/100;
        marketing=totalsupply*10/100;
        dev=totalsupply*5/100;
        launch=totalsupply*35/100;
        Owner=totalsupply*20/100;
        
    }
    function balanceof(address owner)public view returns(uint){
        return balances[owner];
        
    }
    function transfor(address to,uint value)public returns(bool){
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