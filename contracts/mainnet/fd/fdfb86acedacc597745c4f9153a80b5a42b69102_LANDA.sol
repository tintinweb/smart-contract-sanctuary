pragma solidity 0.4.25;

contract Ownable {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Ownable {

    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

library ContractLib {
    /*
    * assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    */
    function isContract(address _addr) internal view returns (bool) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }
}

/*
* Contract that is working with ERC223 tokens
*/
contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public pure;
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {

    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint);
    function allowance(address tokenOwner, address spender) public constant returns (uint);
    function transfer(address to, uint tokens) public returns (bool);
    function approve(address spender, uint tokens) public returns (bool);
    function transferFrom(address from, address to, uint tokens) public returns (bool);

    function name() public constant returns (string);
    function symbol() public constant returns (string);
    function decimals() public constant returns (uint8);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}


/**
* ERC223 token by Dexaran
*
* https://github.com/Dexaran/ERC223-token-standard
*/

/* New ERC223 contract interface */
contract ERC223 is ERC20Interface {

    function transfer(address to, uint value, bytes data) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

}

contract LANDA is ERC223, Pausable {

    using SafeMath for uint256;
    using ContractLib for address;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    event Burn(address indexed from, uint256 value);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol      = "LANDA";
        name        = "LANDA";
        decimals    = 18;
        totalSupply = 20000000 * 10**uint(decimals);
        balances[msg.sender] = totalSupply;
        // emit Transfer(address(0), msg.sender, totalSupply);
    }

    // Function to access name of token .
    function name() public constant returns (string) {
        return name;
    }

    // Function to access symbol of token .
    function symbol() public constant returns (string) {
        return symbol;
    }

    // Function to access decimals of token .
    function decimals() public constant returns (uint8) {
        return decimals;
    }

    // Function to access total supply of tokens .
    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) public whenNotPaused returns (bool) {
        // require(_to != 0x0);
        if(_to.isContract()) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) public whenNotPaused returns (bool) {
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        // require(_to != 0x0);

        bytes memory empty;
        if(_to.isContract()) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

    // function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool) {
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to]        = balanceOf(_to).add(_value);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    // function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        balances[msg.sender]      = balanceOf(msg.sender).sub(_value);
        balances[_to]             = balanceOf(_to).add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    // get the address of balance
    function balanceOf(address _owner) public constant returns (uint) {
        return balances[_owner];
    }  

    function burn(uint256 _value) public whenNotPaused returns (bool) {
        require (_value > 0); 
        require (balanceOf(msg.sender) >= _value);                      // Check if the sender has enough
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);       // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                          // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public whenNotPaused returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function increaseApproval (address _spender, uint _addedValue) public whenNotPaused
        returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public whenNotPaused
        returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool) {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[from]            = balances[from].sub(tokens);
        balances[to]              = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

}