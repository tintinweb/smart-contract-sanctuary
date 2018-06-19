pragma solidity ^0.4.16;


interface Presale {
    function tokenAddress() constant returns (address);
}


interface Crowdsale {
    function tokenAddress() constant returns (address);
}


contract Admins {
    address public admin1;

    address public admin2;

    address public admin3;

    function Admins(address a1, address a2, address a3) public {
        admin1 = a1;
        admin2 = a2;
        admin3 = a3;
    }

    modifier onlyAdmins {
        require(msg.sender == admin1 || msg.sender == admin2 || msg.sender == admin3);
        _;
    }

    function setAdmin(address _adminAddress) onlyAdmins public {

        require(_adminAddress != admin1);
        require(_adminAddress != admin2);
        require(_adminAddress != admin3);

        if (admin1 == msg.sender) {
            admin1 = _adminAddress;
        }
        else
        if (admin2 == msg.sender) {
            admin2 = _adminAddress;
        }
        else
        if (admin3 == msg.sender) {
            admin3 = _adminAddress;
        }
    }

}


contract TokenERC20 {
    // Public variables of the token
    string public name;

    string public symbol;

    uint8 public decimals = 18;

    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
    uint256 initialSupply,
    string tokenName,
    string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        // Update total supply with the decimal amount
        balanceOf[this] = totalSupply;
        // Give the creator all initial tokens
        name = tokenName;
        // Set the name for display purposes
        symbol = tokenSymbol;
        // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        // Check if the sender has enough
        balanceOf[msg.sender] -= _value;
        // Subtract from the sender
        totalSupply -= _value;
        // Updates totalSupply
        Burn(msg.sender, _value);
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
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);
        // Check allowance
        balanceOf[_from] -= _value;
        // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;
        // Subtract from the sender&#39;s allowance
        totalSupply -= _value;
        // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}


contract TrimpoToken is Admins, TokenERC20 {

    uint public transferredManually = 0;

    uint public transferredPresale = 0;

    uint public transferredCrowdsale = 0;

    address public presaleAddr;

    address public crowdsaleAddr;

    modifier onlyPresale {
        require(msg.sender == presaleAddr);
        _;
    }

    modifier onlyCrowdsale {
        require(msg.sender == crowdsaleAddr);
        _;
    }


    function TrimpoToken(
    uint256 initialSupply,
    string tokenName,
    string tokenSymbol,
    address a1,
    address a2,
    address a3
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) Admins(a1, a2, a3) public {}


    function transferManual(address _to, uint _value) onlyAdmins public {
        _transfer(this, _to, _value);
        transferredManually += _value;
    }

    function setPresale(address _presale) onlyAdmins public {
        require(_presale != 0x0);
        bool allow = false;
        Presale newPresale = Presale(_presale);

        if (newPresale.tokenAddress() == address(this)) {
            presaleAddr = _presale;
        }
        else {
            revert();
        }

    }

    function setCrowdsale(address _crowdsale) onlyAdmins public {
        require(_crowdsale != 0x0);
        Crowdsale newCrowdsale = Crowdsale(_crowdsale);

        if (newCrowdsale.tokenAddress() == address(this)) {

            crowdsaleAddr = _crowdsale;
        }
        else {
            revert();
        }

    }

    function transferPresale(address _to, uint _value) onlyPresale public {
        _transfer(this, _to, _value);
        transferredPresale += _value;
    }

    function transferCrowdsale(address _to, uint _value) onlyCrowdsale public {
        _transfer(this, _to, _value);
        transferredCrowdsale += _value;
    }

}