pragma solidity ^0.4.24;

contract ERC20Interface {
    function name() public view returns(bytes32);
    function symbol() public view returns(bytes32);
    function balanceOf (address _owner) public view returns(uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (uint);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


contract AppCoins is ERC20Interface{
    // Public variables of the token
    address public owner;
    bytes32 private token_name;
    bytes32 private token_symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);


    function AppCoins() public {
        owner = msg.sender;
        token_name = "AppCoins";
        token_symbol = "APPC";
        uint256 _totalSupply = 1000000;
        totalSupply = _totalSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balances[owner] = totalSupply;                // Give the creator all initial tokens
    }

    function name() public view returns(bytes32) {
        return token_name;
    }

    function symbol() public view returns(bytes32) {
        return token_symbol;
    }

    function balanceOf (address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }


    function transfer (address _to, uint256 _amount) public returns (bool success) {
        if( balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (uint) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return allowance[_from][msg.sender];
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }


    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}


interface ErrorThrower {
    event Error(string func, string message);
}


contract Ownable is ErrorThrower {
    address public owner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );



    constructor() public {
        owner = msg.sender;
    }


    modifier onlyOwner(string _funcName) {
        if(msg.sender != owner){
            emit Error(_funcName,"Operation can only be performed by contract owner");
            return;
        }
        _;
    }


    function renounceOwnership() public onlyOwner("renounceOwnership") {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }


    function transferOwnership(address _newOwner) public onlyOwner("transferOwnership") {
        _transferOwnership(_newOwner);
    }


    function _transferOwnership(address _newOwner) internal {
        if(_newOwner == address(0)){
            emit Error("transferOwnership","New owner&#39;s address needs to be different than 0x0");
            return;
        }

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }


  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }


  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}


contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }


  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }


  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }


  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

}


contract Whitelist is Ownable, RBAC {
    string public constant ROLE_WHITELISTED = "whitelist";


    modifier onlyIfWhitelisted(string _funcname, address _operator) {
        if(!hasRole(_operator, ROLE_WHITELISTED)){
            emit Error(_funcname, "Operation can only be performed by Whitelisted Addresses");
            return;
        }
        _;
    }


    function addAddressToWhitelist(address _operator)
        public
        onlyOwner("addAddressToWhitelist")
    {
        addRole(_operator, ROLE_WHITELISTED);
    }


    function whitelist(address _operator)
        public
        view
        returns (bool)
    {
        return hasRole(_operator, ROLE_WHITELISTED);
    }


    function addAddressesToWhitelist(address[] _operators)
        public
        onlyOwner("addAddressesToWhitelist")
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }


    function removeAddressFromWhitelist(address _operator)
        public
        onlyOwner("removeAddressFromWhitelist")
    {
        removeRole(_operator, ROLE_WHITELISTED);
    }

    function removeAddressesFromWhitelist(address[] _operators)
        public
        onlyOwner("removeAddressesFromWhitelist")
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }

}

contract AppCoinsCreditsBalance is Whitelist {

    // AppCoins token
    AppCoins private appc;

    // balance proof
    bytes private balanceProof;

    // balance
    uint private balance;

    event BalanceProof(bytes _merkleTreeHash);
    event Deposit(uint _amount);
    event Withdraw(uint _amount);

    constructor(
        address _addrAppc
    )
    public
    {
        appc = AppCoins(_addrAppc);
    }


    function getBalance() public view returns(uint256) {
        return balance;
    }

    function getBalanceProof() public view returns(bytes) {
        return balanceProof;
    }

 
    function registerBalanceProof(bytes _merkleTreeHash)
        internal{

        balanceProof = _merkleTreeHash;

        emit BalanceProof(_merkleTreeHash);
    }

    function depositFunds(uint _amount, bytes _merkleTreeHash)
        public
        onlyIfWhitelisted("depositFunds", msg.sender){
        require(appc.allowance(msg.sender, address(this)) >= _amount);
        registerBalanceProof(_merkleTreeHash);
        appc.transferFrom(msg.sender, address(this), _amount);
        balance = balance + _amount;
        emit Deposit(_amount);
    }

    function withdrawFunds(uint _amount, bytes _merkleTreeHash)
        public
        onlyIfWhitelisted("withdrawFunds",msg.sender){
        require(balance >= _amount);
        registerBalanceProof(_merkleTreeHash);
        appc.transfer(msg.sender, _amount);
        balance = balance - _amount;
        emit Withdraw(_amount);
    }

}