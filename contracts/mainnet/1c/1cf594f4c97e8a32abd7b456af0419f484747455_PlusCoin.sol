pragma solidity ^0.4.13;

/**
* @title PlusCoin Contract
* @dev The main token contract
*/



contract PlusCoin {
    address public owner; // Token owner address
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) allowed;

    string public standard = &#39;PlusCoin 2.0&#39;;
    string public constant name = "PlusCoin";
    string public constant symbol = "PLC";
    uint   public constant decimals = 18;
    uint public totalSupply;

    address public allowed_contract;

    //
    // Events
    // This generates a publics event on the blockchain that will notify clients
    
    event Sent(address from, address to, uint amount);
    event Buy(address indexed sender, uint eth, uint fbt);
    event Withdraw(address indexed sender, address to, uint eth);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //
    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    modifier onlyAllowedContract() {
        require(msg.sender == allowed_contract);
        _;
    }

    //
    // Functions
    // 

    // Constructor
    function PlusCoin() {
        owner = msg.sender;
        totalSupply = 28272323624 * 1000000000000000000;
        balances[owner] = totalSupply;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner {
      if (newOwner != address(0)) {
        owner = newOwner;
      }
    }

    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }

 

	function setAllowedContract(address _contract_address) public
        onlyOwner
        returns (bool success)
    {
        allowed_contract = _contract_address;
        return true;
    }


    function withdrawEther(address _to) public 
        onlyOwner
    {
        _to.transfer(this.balance);
    }



    /**
     * ERC 20 token functions
     *
     * https://github.com/ethereum/EIPs/issues/20
     */
    
    function transfer(address _to, uint256 _value) public
        returns (bool success) 
    {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public
        returns (bool success)
    {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public
        constant returns (uint256 remaining)
    {
      return allowed[_owner][_spender];
    }

}