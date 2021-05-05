/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

/**
 *Submitted for verification at Etherscan.io on 2019-01-08
*/

pragma solidity ^0.4.24;



contract NKNToken {
    string public name = "NKN";
    string public symbol = "NKN";
    uint8 public decimals = 18;

    uint256 public totalSupplyCap = 7 * 10**8 * 10**uint256(decimals);

    uint256 public totalSupply;
    mapping(address => uint256) balances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address _issuer) public {
        totalSupply = totalSupplyCap;
        balances[_issuer] = totalSupplyCap;
        emit Transfer(address(0), _issuer, totalSupplyCap);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
        * @return An uint256 representing the amount owned by the passed address.
        */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}