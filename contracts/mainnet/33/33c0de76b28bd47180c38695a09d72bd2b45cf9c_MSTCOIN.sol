pragma solidity ^0.4.17;


contract Ownable {
    
    address public owner;

    /**
     * The address whcih deploys this contrcat is automatically assgined ownership.
     * */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * Functions with this modifier can only be executed by the owner of the contract. 
     * */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

    /**
    * Transfers ownership to new Ethereum address. This function can only be called by the 
    * owner.
    * @param _newOwner the address to be granted ownership.
    **/
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}




library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a / b;
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




contract ERC20Basic {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}




contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public  returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract BasicToken is ERC20Basic {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) internal balances;
    
    /**
    * Returns the balance of the qeuried address
    *
    * @param _who The address which is being qeuried
    **/
    function balanceOf(address _who) public view returns(uint256) {
        return balances[_who];
    }
    
    /**
    * Allows for the transfer of MSTCOIN tokens from peer to peer. 
    *
    * @param _to The address of the receiver
    * @param _value The amount of tokens to send
    **/
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(balances[msg.sender] >= _value && _value > 0 && _to != 0x0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
}




contract StandardToken is BasicToken, ERC20 {
    
    mapping (address => mapping (address => uint256)) internal allowances;
    
    /**
    * Returns the amount of tokens one has allowed another to spend on his or her behalf.
    *
    * @param _owner The address which is the owner of the tokens
    * @param _spender The address which has been allowed to spend tokens on the owner&#39;s
    * behalf
    **/
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }
    
    /**
    * Allows for the transfer of tokens on the behalf of the owner given that the owner has
    * allowed it previously. 
    *
    * @param _from The address of the owner
    * @param _to The address of the recipient 
    * @param _value The amount of tokens to be sent
    **/
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
        require(allowances[_from][msg.sender] >= _value && _to != 0x0 && balances[_from] >= _value && _value > 0);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    /**
    * Allows the owner of tokens to approve another to spend tokens on his or her behalf
    *
    * @param _spender The address which is being allowed to spend tokens on the owner&#39; behalf
    * @param _value The amount of tokens to be sent
    **/
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != 0x0 && _value > 0);
        if(allowances[msg.sender][_spender] > 0 ) {
            allowances[msg.sender][_spender] = 0;
        }
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}




contract Pausable is Ownable {
   
    event Pause();
    event Unpause();
    event Freeze ();
    event LogFreeze();

    address public constant IcoAddress = 0xe9c5c1c7dA613Ef0749492dA01129DDDbA484857;  
    address public constant founderAddress = 0xF748D2322ADfE0E9f9b262Df6A2aD6CBF79A541A;

    bool public paused = true;
    
    /**
    * @dev modifier to allow actions only when the contract IS paused or if the 
    * owner or ICO contract is invoking the action
    */
    modifier whenNotPaused() {
        require(!paused || msg.sender == IcoAddress || msg.sender == founderAddress);
        _;
    }

    /**
    * @dev modifier to allow actions only when the contract IS NOT paused
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public onlyOwner {
        paused = true;
        Pause();
    }
    

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyOwner {
        paused = false;
        Unpause();
    }
    
}




contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }
}




contract MSTCOIN is PausableToken {
    
    function MSTCOIN() public {
        name = "MSTCOIN";
        symbol = "MSTCOIN";
        decimals = 6;
        totalSupply = 500000000e6;
        balances[founderAddress] = totalSupply;
        Transfer(address(this), founderAddress, totalSupply);
    }
    
    event Burn(address indexed burner, uint256 value);
    
    /**
    * Allows the owner to burn his own tokens.
    * 
    * @param _value The amount of token to be burned
    */
    function burn(uint256 _value) public onlyOwner {
        _burn(msg.sender, _value);
    }
    
    /**
    * Function is internally called by the burn function. 
    *
    * @param _who Will always be the owners address
    * @param _value The amount of tokens to be burned
    **/
    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(_who, _value);
        Transfer(_who, address(0), _value);
    }
}