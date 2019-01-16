pragma solidity ^0.5.1;

contract AuraToken {

    mapping (address => uint256) balances;
    uint256 totalSupply;
    uint256 freeSupply;
    address owner1;
    address owner2;
    address owner3;
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;H1.6&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.

    uint256 rateBuy;
    uint256 amount1;
    uint256 amount2;
    uint256 amount3;
    address payable w_owner;
    uint256 w_amount;
    ///uint256 rateSell;

    constructor () public {
        owner2 = 0xEb5887409Dbf80de52cBE1dD441801F1f01c568b;
        owner1 = 0xBd1A0E79e12F9D7109d58D014C2A8fba1AA44935;
        owner3 = 0xc0eE5076F0D78D87AD992B6CE205d88133aD25c0;

        //balances[msg.sender] = 1000000000000000; // Give the creator all initial tokens (100000 for example)
        totalSupply = 0;                    // Update total supply (100000 for example)
        freeSupply = 0;                     // Update free supply (100000 for example)
        name = "atlant resourse";           // Set the name for display purposes
        decimals = 8;                        // Amount of decimals for display purposes
        symbol = "AURA";                     // Set the symbol for display purposes
        rateBuy = 200000000000;              // 20 eth per AURA
        ///rateSell = 404000000;
        emit TotalSupply(totalSupply);
        amount1 = 0;
        amount2 = 0;
        amount3 = 0;
        w_amount = 0;
    }

    /// @return total amount of tokens
    function total_supply() public view returns (uint256 _supply) {
        return totalSupply;
    }

    /// @return free amount of tokens
    function free_supply() public view returns (uint256 _supply) {
        return freeSupply;
    }

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] - _value >= 0 && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    /// @notice send `_value` token to `_to` from New Atlantis Central bank
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred. Negative value is allowed
    /// @return Whether the transfer was successful or not
    function transferFromNA(address _to, uint256 _value) public returns (bool success) {
        require((msg.sender == owner1) || (msg.sender == owner2) || (msg.sender == owner3));
        balances[_to] += _value;
        freeSupply -= _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event TotalSupply(uint256 _value);
    event Rates(uint256 _value);
    
    function () external payable {
        buyAura();
    }

    ///function setRates(uint256 _rateBuy, uint256 _rateSell) public {
    function setRates(uint256 _rateBuy) public {
        require((msg.sender == owner1) || (msg.sender == owner2) || (msg.sender == owner3));
        ///require(_rateBuy < _rateSell);
        rateBuy = _rateBuy;
        ///rateSell = _rateSell;
        emit Rates(rateBuy);
    }
    
    function printTokens(uint256 _amount) public {       // must be signed from all owners
        require(totalSupply<=1500000000000000000000000);  // 15 000 000 000 000 000 AURA
        require(_amount>0);
        require(_amount<=1500000000000000000);          // 15 000 000 000 AURA
        if(msg.sender == owner1) amount1 = _amount;
        if(msg.sender == owner2) amount2 = _amount;
        if(msg.sender == owner3) amount3 = _amount;
        if((amount1 == amount2) && (amount2 == amount3)) {
            totalSupply +=_amount;
            freeSupply += _amount;
            emit TotalSupply(_amount);
            amount1 = 0;
            amount2 = 0;
            amount3 = 0;
        }
    }
    
    function buyAura() public payable {
        require(msg.value > 0);
        require(msg.value <= 150000000000000000000000000000); //150 000 000 000 ether
        balances[msg.sender] += msg.value / rateBuy;
        freeSupply -= msg.value / rateBuy; // Negative value is allowed
    }
    
    ///function sellAura(uint256 _amount) public {
    ///    require(balances[msg.sender] > _amount);
    ///    balances[msg.sender] -= _amount;
    ///    msg.sender.transfer(_amount / rateSell);
    ///}
    
    function withdraw(uint256 _amount) public {  // must be signed from 2 owners
        require(_amount > 0);
        require((msg.sender == owner1) || (msg.sender == owner2) || (msg.sender == owner3));
        if((msg.sender != w_owner) && (_amount == w_amount)) {
            w_amount = 0;
            w_owner.transfer(_amount);
        }
        else {
            w_owner = msg.sender;
            w_amount = _amount;
        }
    }
}