pragma solidity ^0.4.11;

/// @title Artcoin (ART) - democratizing culture.
contract Artcoin {

    string public constant name = "Artcoin";
    string public constant symbol = "ART";
    uint8 public constant decimals = 18;

    uint256 public authorizedSupply;
    uint256 public treasurySupply;

    mapping (address => uint) public balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /*
     * Initialize Artcoin.
     */
    function Artcoin(address consortium, uint256 _authorizedSupply, uint256 _treasurySupply) {
        authorizedSupply = _authorizedSupply;
        treasurySupply = _treasurySupply;
        if (authorizedSupply < treasurySupply) throw;

        // one-time issuance of ART to the consortium endowment
        balances[consortium] = authorizedSupply;

        // one-time issuance of ART to the consortium founders
        var founderSupply = ((authorizedSupply - treasurySupply) / 2) / 2;
        balances[0x00331BA52fa3A22d6C7904Be8910954184336bcc] = founderSupply;
        balances[0x210DdB647768B891472700CaE03043003A79384E] = founderSupply;

        balances[consortium] -= founderSupply * 2;
    }

    /// @return total amount of ART
    function totalSupply() external constant returns (uint256) {
        return authorizedSupply;
    }

    /// @param _owner The address from which the ART balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @notice send `_value` ART to `_to` from `msg.sender`
    /// to provided account address `_to`.
    /// @param _to The address of the ART recipient
    /// @param _value The amount of ART to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool) {
        var senderBalance = balances[msg.sender];
        var overflow = balanceOf(_to) + _value < balanceOf(_to);
        if (_value > 0 && senderBalance >= _value && !overflow) {
            senderBalance -= _value;
            balances[msg.sender] = senderBalance;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }
}