/**
 * ropsten 0xa813ced560126ea76efbd80d5b10293434dc9ddc
 */
pragma solidity ^ 0.4.17;

contract SafeMath {
    function safeMul(uint a, uint b) pure internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) pure internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) pure internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public view returns(uint);

    function allowance(address owner, address spender) public view returns(uint);

    function transfer(address to, uint value) public returns(bool ok);

    function transferFrom(address from, address to, uint value) public returns(bool ok);

    function approve(address spender, uint value) public returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) 
            owner = newOwner;
    }

    function kill() public {
        if (msg.sender == owner) 
            selfdestruct(owner);
    }

    modifier onlyOwner() {
        if (msg.sender == owner)
            _;
    }
}





// The PPP token
contract Token is ERC20, SafeMath, Ownable {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals; // How many decimals to show.
    string public version = "v0.1";
    uint public initialSupply;
    uint public totalSupply;
    bool public locked;   
    address public preSaleAddress;       
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // Lock transfer for contributors during the ICO 
    modifier onlyUnlocked() {
        if (msg.sender != preSaleAddress && locked) 
            revert();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != owner) 
            revert();
        _;
    }

    // The PPP Token created with the time at which the crowdsale ends
    function Token() public {
        // Lock the transfCrowdsaleer function during the crowdsale
        locked = true;
        initialSupply = 165000000e18;
        totalSupply = initialSupply;
        name = "PayPie"; // Set the name for display purposes
        symbol = "PPP"; // Set the symbol for display purposes
        decimals = 18; // Amount of decimals for display purposes        
        preSaleAddress = 0xEb33D8E293aCe758752F90FC07a7B668eddef8A5;      

        // Allocate tokens for pre-sale customers - private sale 
        balances[preSaleAddress] = 82499870672369211638818601 - 2534559883e16;
        // Allocate tokens for the team/reserve/advisors/
        balances[0x05ad8B53bfcd47C6B789C78cB1e654F49779db7f] = totalSupply - balances[preSaleAddress];       
    }

    function unlock() public onlyAuthorized {
        locked = false;
    }

    function lock() public onlyAuthorized {
        locked = true;
    }

    function burn( address _member, uint256 _value) public onlyAuthorized returns(bool) {
        balances[_member] = safeSub(balances[_member], _value);
        totalSupply = safeSub(totalSupply, _value);
        Transfer(_member, 0x0, _value);
        return true;
    }

    function transfer(address _to, uint _value) public onlyUnlocked returns(bool) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    
    function transferFrom(address _from, address _to, uint256 _value) public onlyUnlocked returns(bool success) {
        require(_to != address(0));
        require (balances[_from] >= _value); // Check if the sender has enough                            
        require (_value <= allowed[_from][msg.sender]); // Check if allowed is greater or equal        
        balances[_from] = safeSub(balances[_from], _value); // Subtract from the sender
        balances[_to] = safeAdd(balances[_to],_value); // Add the same to the recipient
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);  // decrease allowed amount
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns(uint balance) {
        return balances[_owner];
    }


  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public view returns(uint remaining) {
        return allowed[_owner][_spender];
    }


    /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender], _addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}