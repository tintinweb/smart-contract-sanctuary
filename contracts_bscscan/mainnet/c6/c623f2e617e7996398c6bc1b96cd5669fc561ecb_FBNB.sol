/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

pragma solidity ^0.4.19;

contract FBNB {

    string public constant name = "Fastest Burning N Buying Coin";
    string public constant symbol = "FBNB";
    uint8 public constant decimals = 18;  


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;
  

    using SafeMath for uint256;


    constructor() public {  
	totalSupply_ = 21000000000000000000000000;
	balances[msg.sender] = totalSupply_;
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        uint256 toBurn = numTokens.mul(30);
        toBurn = toBurn / 100;
        uint256 _value = numTokens -  toBurn;
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[receiver] = balances[receiver].add(_value);
        emit Transfer(msg.sender, receiver, _value);
        require (burn (toBurn));
       
        return true;
    }
    
    
    
    function transferToken(address receiver, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[receiver] = balances[receiver].add(_value);
        emit Transfer(msg.sender, receiver, _value);
       
        return true;
    }
    
    
    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
       emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
        uint256 toBurn = numTokens.mul(30);
        toBurn = toBurn / 100;
        uint256 _value = numTokens -  toBurn;
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(_value);
        balances[buyer] = balances[buyer].add(_value);
      emit  Transfer(owner, buyer, numTokens);
       require (burnFrom (owner, toBurn));
        return true;
    }
    
    event Burn(address, uint256);
    
        function burn(uint256 _value) private returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply_ -= _value;                      // Updates totalSupply
       
      emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) private returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply_ -= _value;                              // Update totalSupply
      
       emit Burn(_from, _value);
        return true;
    }
}

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
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
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}