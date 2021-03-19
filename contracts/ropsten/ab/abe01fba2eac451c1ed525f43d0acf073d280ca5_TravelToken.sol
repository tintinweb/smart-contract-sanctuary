/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity ^0.7.4;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------

contract TravelToken {
    string  public name = "Travel Token";
    string  public symbol = "ETT";
    string  public standard = "Travel Token v1.0";

    // The number of decimals the token uses - e.g. 8, means to divide the token amount by 100000000 to get its user representation
    uint8 public decimals;
    uint256 public _totalSupply;

    //Events -> emit notifications that consumers of the contract can subscribe to and also meant for use in logging transactions

    // Event reads: A transfer occurred where account _from sent _value travel tokens to _to account
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    // Event reads: The _owner approved account _spender to spend _value amount of tokens
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // Master list of all addresses who own travel tokens
    mapping(address => uint256) public balances;

    // Master list of which accounts have been granted permission to spend travel tokens on behalf of address
    // This is used for example when you allow a exchange to sell/exchange travel tokens on your behalf
    mapping(address => mapping(address => uint256)) public allowances;

    constructor() {
        // 18 decimal places is the standard most tokens use
        decimals = 18;

        // total supply is actually 100,000,000 because we have to also account for the 18 decimal places in the entire totalSupply number
        _totalSupply = 100000000000000000000000000;

        // When the contract is deployed, initiate the entire supply to the deploying address (msg.sender) of the contract.  msg is a global variable in solidity that has many different fields
        // but the sender field represents the address of the caller
        // can find more : https://docs.soliditylang.org/en/v0.8.2/units-and-global-variables.html
        balances[msg.sender] = _totalSupply;

        // Fire the transfer event so that listeners can catch the transfer
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // Returns the account balance of another account with address _owner
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // Returns the amount which _spender is still allowed to withdraw from _owner.
    // Example of usage:
    //  - you delegate an exchange to sell a limited amount of tokens on your behalf
    //  - the return value of this function is how much you allowed to the exchange to transact from your account
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    // How much supply is left
    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    // Transfers _value amount of tokens from caller to address _to
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // check that that sender has enough tokens to actually transfer the requested _value
        require(balances[msg.sender] >= _value);

        // complete the transfer: remove _value amount of tokens from caller and add them to the _to address
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        // Fire the transfer event so that listeners can catch the transfer
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    // Allows _spender to withdraw from your account multiple times, up to the _value amount. If this function is called again it overwrites the current allowance with _value
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // Transfer the _value amount to the _spender
        allowances[msg.sender][_spender] = _value;

        // Fire the Approval event
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    //
    // The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies. The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
    //
    // Note 1: that this function is meant to be used in tandem with approve:  after approval, we actually execute the transfer of _value tokens from account _from to account _to
    //
    // Note 2: msg.sender here is the delegated party to preform the transfer
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // validate that caller has at least _value tokens in their account
        require(balances[_from] >= _value);
        // validate that the allowance is big enough: does the account _from have enough tokens approved (_value) from the caller (msg.sender)
        require(allowances[_from][msg.sender] >= _value);

        // Change the balances
        balances[_from] -= _value;
        balances[_to] += _value;

        // update the allowance: now the delegated party (msg.sender) cannot transact _value tokens on behalf of the _from address
        allowances[_from][msg.sender] -= _value;

        // emit the transfer event
        emit Transfer(_from, _to, _value);

        return true;
    }
}