/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

pragma solidity ^0.5.0;

/// @title Tanu Token
/// @author Nick Pala
/// @notice You can use this contract for stake and farm token
/// @dev All function calls are currently implemented without side effects

contract TanuToken {

    ///@dev basic token info
    string  public name = "Tanu Token";
    string  public symbol = "TANU";
    uint256 public totalSupply = 100000000000000000000000000; // 100 million tokens
    uint8   public decimals = 18;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    /**
    * @dev Moves `_value` tokens from the caller's account to `_to`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    ///@dev Sets `_value` as the allowance of `spender` over the caller's tokens.
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    ///@dev `_from` and `_to` cannot be the zero address.
    ///@dev `_from` must have a balance of at least `_value`.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}