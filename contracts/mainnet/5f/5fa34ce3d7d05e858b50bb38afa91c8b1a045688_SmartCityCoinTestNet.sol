/*
This is the contract for Smart City Coin Test Net(SCCTN) 

Smart City Coin Test Net(SCCTN) is utility token designed to be used as prepayment and payment in Smart City Shop.

Smart City Coin Test Net(SCCTN) is utility token designed also to be proof of membership in Smart City Club.

Token implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20

Smart City Coin Test Net is as the name implies Test Network - it was deployed in order to test functionalities, options, user interface, liquidity, price fluctuation, type of users, 
market research and get first-hand feedback from all involved. We ask all users to be aware of test nature of the token - have patience and preferably 
report all errors, opinions, shortcomings to our email address <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ff96919990bf8c929e8d8b9c968b869c909691d19c9092d1">[email&#160;protected]</a> Ask for bounty program for reporting shortcomings and improvement of functionalities. 

Smart City Coin Test Network is life real-world test with the goal to gather inputs for the Smart City Coin project.

Smart City Coin Test Network is intended to be used by a skilled professional that understand and accept technology risk involved. 

Smart City Coin Test Net and Smart City Shop are operated by Smart City AG.

Smart City AG does not assume any liability for damages or losses occurred due to the usage of SCCTN, since as name implied this is test Network design to test technology and its behavior in the real world. 

You can find all about the project on http://www.smartcitycointest.net
You can use your coins in https://www.smartcityshop.net/  
You can contact us at <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f69f989099b6859b978482959f828f95999f98d895999b">[email&#160;protected]</a> 
*/

pragma solidity ^0.4.24;
contract Token {

    /// return total amount of tokens
    function totalSupply() public pure returns (uint256) {}

    /// param _owner The address from which the balance will be retrieved
    /// return The balance
    function balanceOf(address) public payable returns (uint256) {}

    /// notice send `_value` token to `_to` from `msg.sender`
    /// param _to The address of the recipient
    /// param _value The amount of token to be transferred
    /// return Whether the transfer was successful or not
    function transfer(address , uint256 ) public payable returns (bool) {}

    /// notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// param _from The address of the sender
    /// param _to The address of the recipient
    /// param _value The amount of token to be transferred
    /// return Whether the transfer was successful or not
    function transferFrom(address , address , uint256 ) public payable returns (bool ) {}

    /// notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// param _spender The address of the account able to transfer the tokens
    /// param _value The amount of wei to be approved for transfer
    /// return Whether the approval was successful or not
    function approve(address , uint256 ) public payable returns (bool ) {}

    /// param _owner The address of the account owning tokens
    /// param _spender The address of the account able to transfer the tokens
    /// return Amount of remaining tokens allowed to spent
    function allowance(address , address ) public payable returns (uint256 ) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*
This implements implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public payable returns (bool ) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public payable returns (bool ) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public payable  returns (uint256 ) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public payable returns (bool ) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public payable returns (uint256 a ) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

/*
This Token Contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20) as well as the following OPTIONAL extras intended for use by humans.

This Token will be deployed, and then used by humans - members of Smart City Community - as an utility token as a prepayment for services and Smart House Hardware in SmartCityShop - www.smartcityshop.net .

This token specify
1) Initial Finite Supply (upon creation one specifies how much is minted).
2) In the absence of a token registry: Optional Decimal, Symbol & Name.
3) Optional approveAndCall() functionality to notify a contract if an approval() has occurred.

.*/

contract SmartCityCoinTestNet is StandardToken {

    function () public {
        //if ether is sent to this address, send it back.
        revert();
    }

    /* Public variables of the token */

    /*
    NOTE:
    We&#39;ve inlcuded the following variables as OPTIONAL vanities. 
    They in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;H0.1&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.

    constructor (
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public payable returns (bool )  {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
}