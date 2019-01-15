pragma solidity ^0.5.2;

contract VirtuDollar {
    // ERC20 standard specs
    string public name = "Virtu Dollar";
    string public symbol = "V$";
    string public standard = "Virtu Dollar v1.0";
    uint8 public decimals = 18;

    // VirtuDollar total supply which is publicly visible on the ethereum blockchain.
    uint256 public VDollars;

    // Map for owner addresses that holds the balances.
    mapping( address => uint256) public balanceOf;

    // Map for owner addresses that holds the allowed addresses and remaining allowance
    mapping(address => mapping(address => uint256)) public allowance;

    // Virtu dollar owner identity
    address owner;

    // The smart contract will start initially with a zero total supply
    constructor(uint256 _initialSupply) public {
        // Initiate the owner
        owner = msg.sender;
        // Update the owner balance
        balanceOf[owner] = _initialSupply * 10 ** uint256(decimals);
        // Mint the initial virtu dollar supply
        VDollars = balanceOf[owner];
    }

    // Implementing the ERC 20 transfer function
    function transfer (address _to, uint256 _value) public returns (bool success) {
        // Require the value to be already present in the balance
        require(balanceOf[msg.sender] >= _value);
        // Decrement the balance of the sender
        balanceOf[msg.sender] -= _value;
        // Increment the balance of the recipient
        balanceOf[_to] += _value;
        // Fire the Transfer event
        emit Transfer(msg.sender, _to, _value);
        // Return the success flag
        return true;
    }

    // Implementing the ERC 20 transfer event
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    // Implementing the ERC 20 delegated transfer function
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Checking the value is available in the balance
        require(_value <= balanceOf[_from]);
        // Checking the value is allowed
        require(_value <= allowance[_from][msg.sender]);
        // Performing the transfer
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        // Decrementing the allowance
        allowance[_from][msg.sender] -= _value;
        // Firing the transfer event
        emit Transfer(_from, _to, _value);
        // Returning the success flag
        return true;
    }

    // Implementing the ERC 20 approval event
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // Impelmenting the ERC 20 approve function
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // Setting the allowance to the new amount
        allowance[msg.sender][_spender] = _value;
        // Firing the approval event
        emit Approval(msg.sender, _spender, _value);
        // Returning the success flag
        return true;
    }

    // Implementing the Burn event
    event Burn (
        address indexed _from,
        uint256 _value
    );

    // Implementing the burn function
    function burn (uint256 _value) public returns (bool success) {
        // Checking the owner has enough balance
        require(balanceOf[msg.sender] >= _value);
        // Decrementing the balance
        balanceOf[msg.sender] -= _value;
        // Burning the tokens
        VDollars -= _value;
        // Firing the burn event
        emit Burn(msg.sender, _value);
        // Returning the success flag
        return true;
    }

    // Implementing the delegated burn function
    function burnFrom (address _from, uint256 _value) public returns (bool success) {
        // Check if the owner has enough balance
        require(balanceOf[_from] >= _value);
        // Check if the spender has enough allowance
        require(allowance[_from][msg.sender] >= _value);
        // Decrement the owner balance
        balanceOf[_from] -= _value;
        // Decrement the allowance value
        allowance[_from][msg.sender] -= _value;
        // Burn the tokens
        VDollars -= _value;
        // Fire the burn event
        emit Burn(_from, _value);
        // Returning the success flag
        return true;
    }

    // Implementing the Mint event
    event Mint(
        address indexed _from,
        uint256 _value
    );

    // Implementing the mint function
    function mint (uint256 _value) public returns (bool success) {
        // Checking the owner is the owner of the coin
        require(msg.sender == owner);
        // Incrementing the owner balance
        balanceOf[owner] += _value;
        // Minting the tokens
        VDollars += _value;
        // Firing the mint event
        emit Mint(msg.sender, _value);
        // Returning the success flag
        return true;
    }
}