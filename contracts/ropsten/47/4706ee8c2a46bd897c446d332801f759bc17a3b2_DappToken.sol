/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

pragma solidity ^0.5.16;

contract DappToken {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    string public standard;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /**
     * @param _from Sender's address.
     * @param _to Receiver's address.
     * @param _value Amount of token.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * @param _owner Owner's address.
     * @param _spender Spender's address.
     * @param _value Amount of token.
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @param _name Token name.
     * @param _symbol Token symbol.
     * @param _totalSupply Token total supply.
     * @param _standard Token standard version.
     */
    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _totalSupply, string memory _standard) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        standard = _standard;
        balanceOf[msg.sender] = _totalSupply;
    }

    /**
     * @dev Transfer amount of token.
     * @param _to Address will receive amount of token.
     * @param _value Amount of token.
     * @return true If successful.
     */
    function transfer(address _to, uint256 _value) public returns(bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Approves delegated transfer.
     * @param _spender.
     * @param _value.
     * @return true If successful.
     */
    function approve(address _spender, uint256 _value) public returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @param _from.
     * @param _to.
     * @param _value.
     * @return true If successful.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}