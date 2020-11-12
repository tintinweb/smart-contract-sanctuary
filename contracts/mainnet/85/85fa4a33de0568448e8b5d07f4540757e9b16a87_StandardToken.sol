/**
 *Submitted for verification at Etherscan.io on 2020-07-15
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-24
*/

pragma solidity ^0.4.21;

interface ERC20 {
   function balanceOf(address who) public view returns (uint256);
   function transfer(address to, uint256 value) public returns (bool);
   function allowance(address owner, address spender) public view returns (uint256);
   function transferFrom(address from, address to, uint256 value) public returns (bool);
   function approve(address spender, uint256 value) public returns (bool);
   event Transfer(address indexed from, address indexed to, uint256 value);
   event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {
   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
           return 0;
       }
       uint256 c = a * b;
       assert(c / a == b);
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

contract StandardToken is ERC20 {
   using SafeMath for uint;

   string  internal _name;
   string  internal _symbol;
   uint8   internal _decimals;
   uint256 internal _totalSupply;

   mapping (address => uint256) internal balances;
   mapping (address => mapping (address => uint256)) internal allowed;

   function StandardToken() public {
       _name = "CommaOpenChat";                                  // Set the name for display purposes
       _decimals = 18;                                      // Amount of decimals for display purposes
       _symbol = "COC";                                     // Set the symbol for display purposes
       _totalSupply = 5000000000000000000000000000;         // Update total supply (100000 for example)
       balances[msg.sender] = 5000000000000000000000000000;               // Give the creator all initial tokens (100000 for example)       
   }

   function name()
   public
   view
   returns (string) {
       return _name;
   }

   function symbol()
   public
   view
   returns (string) {
       return _symbol;
   }

   function decimals()
   public
   view
   returns (uint8) {
       return _decimals;
   }

   function totalSupply()
   public
   view
   returns (uint256) {
       return _totalSupply;
   }

   function transfer(address _to, uint256 _value) public returns (bool) {
       require(_to != address(0));
       require(_value <= balances[msg.sender]);
       balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
       balances[_to] = SafeMath.add(balances[_to], _value);
       Transfer(msg.sender, _to, _value);
       return true;
   }

   function isContract(address _addr) private returns (bool is_contract) {
       uint length;
       assembly {
       //retrieve the size of the code on target address, this needs assembly
           length := extcodesize(_addr)
       }
       return (length>0);
   }

   function balanceOf(address _owner) public view returns (uint256 balance) {
       return balances[_owner];
   }

   function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
       require(_to != address(0));
       require(_value <= balances[_from]);
       require(_value <= allowed[_from][msg.sender]);

       balances[_from] = SafeMath.sub(balances[_from], _value);
       balances[_to] = SafeMath.add(balances[_to], _value);
       allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
       Transfer(_from, _to, _value);
       return true;
   }

   function approve(address _spender, uint256 _value) public returns (bool) {
       allowed[msg.sender][_spender] = _value;
       Approval(msg.sender, _spender, _value);
       return true;
   }

   function allowance(address _owner, address _spender) public view returns (uint256) {
       return allowed[_owner][_spender];
   }

   function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
       allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
       Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
       return true;
   }

   function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
       uint oldValue = allowed[msg.sender][_spender];
       if (_subtractedValue > oldValue) {
           allowed[msg.sender][_spender] = 0;
       } else {
           allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
       }
       Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
       return true;
   }
}