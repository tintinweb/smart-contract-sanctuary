/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

pragma solidity ^0.4.23;
        // -------------------------------------------------------------------------
        // MEMELLIONAIRE token contract
        // -------------------------------------------------------------------------

        contract MEMELLIONAIRE
        {
        string public constant symbol = 'MONY';
        string public constant name = 'MEMELLIONAIRE';
        uint8 public constant decimals = 0;
        uint256 _totalSupply = 13001000000;


        // Balances for each account
        mapping(address => uint256) balances;

        // Owner of account approves the transfer of an amount to another account
        mapping(address => mapping (address => uint256)) allowed;

        // Triggered when tokens are transferred.
        event Transfer(address indexed _from, address indexed _to, uint256 _value);

        // Triggered whenever approve(address _spender, uint256 _value) is called.
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);

        // Constructor
        function MEMELLIONAIRE() {

            balances[msg.sender] =_totalSupply;
            Transfer(0x00,msg.sender,_totalSupply);


        }

        function totalSupply() constant returns (uint256 totalSupply) {
            return _totalSupply;
        }

        // What is the balance of a particular account?
        function balanceOf(address _owner) constant returns (uint256 balance) {
            return balances[_owner];
        }

        // Transfer the balance from owner's account to another account
        function transfer(address _to, uint256 _amount) returns (bool success) {
            if (balances[msg.sender] >= _amount
                && _amount > 0
                && balances[_to] + _amount > balances[_to]) {
                balances[msg.sender] -= _amount;
                balances[_to] += _amount;
                Transfer(msg.sender, _to, _amount);
                return true;
            } else {
                return false;}
        }

        // Send _value amount of tokens from address _from to address _to
        function transferFrom(
            address _from,
            address _to,
            uint256 _amount
        ) returns (bool success) {
            if (balances[_from] >= _amount
                && allowed[_from][msg.sender] >= _amount
                && _amount > 0
                && balances[_to] + _amount > balances[_to]) {
                balances[_from] -= _amount;
                allowed[_from][msg.sender] -= _amount;
                balances[_to] += _amount;
                Transfer(_from, _to, _amount);
                return true;
            } else {
                return false;}
        }

        function approve(address _spender, uint256 _amount)
            returns (bool success) {
            allowed[msg.sender][_spender] = _amount;
            Approval(msg.sender, _spender, _amount);
            return true;
        }

        function allowance(address _owner, address _spender)
            constant returns (uint256 remaining) {
            return allowed[_owner][_spender];

            }

        }