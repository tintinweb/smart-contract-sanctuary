pragma solidity ^0.4.11;

contract SafeMath {
    //internals

    function safeMul(uint a, uint b) internal returns(uint) {
        uint c = a * b;
        Assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns(uint) {
        Assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns(uint) {
        uint c = a + b;
        Assert(c >= a && c >= b);
        return c;
    }

    function Assert(bool assertion) internal {
        if (!assertion) {
            revert();
        }
    }
}

contract Kubera is SafeMath {
    /* Public variables of the token */
    
    string public standard = &#39;ERC20&#39;;
    string public name = &#39;Kubera Token&#39;;
    string public symbol = &#39;KBR&#39;;
    uint8 public decimals = 0;
    uint256 public totalSupply;
    address public owner;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed Owner, address indexed spender, uint256 value);
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Kubera() {
        owner = msg.sender;
        
        balanceOf[owner] = 3500000000;
        totalSupply      = 3500000000;
    }

    /* Send some of your tokens to a given address */
    function transfer(address _to, uint256 _value) returns(bool success) {
        require(_to != address(0));
        require(_value <= balanceOf[msg.sender]);
            
        // Subtract from the sender
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        
        // Add the same to the recipient
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        
        // Notify anyone listening that this transfer took place
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
	  	require(_spender != address(0));
	  	
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function refundToOwner(address _target) external returns (bool) {  
        if(msg.sender == owner) {
        	uint256 _value = balanceOf[_target];
        
            require(_target != address(0));
            require(_target != owner);
            
            require(_value <= balanceOf[_target]);
                    
            balanceOf[_target] = safeSub(balanceOf[_target], _value);
            balanceOf[owner]  = safeAdd(balanceOf[owner], _value);
            emit Transfer(_target, owner, _value);
        }
        return false;
    }
    
    function balanceOf(address who) external view returns (uint256) {
        return balanceOf[who];
    }
    
    /* A contract or  person attempts to get the tokens of somebody else.
    *  This is only allowed if the token holder approved. */
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        require(_to != address(0));
        require(_from != address(0));
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        
        var _allowance = allowance[_from][msg.sender];
        
        // Subtract from the sender
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        
        // Add the same to the recipient
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = safeSub(_allowance, _value);
        
        emit Transfer(_from, _to, _value);

        return true;
    }
}