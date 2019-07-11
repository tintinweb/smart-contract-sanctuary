/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity 0.5.6;

contract UBXTestToken {
    string public name = "UBX Test Token";
    string public symbol = "UBXT";
    string public standard = "UBX Test Token v1.0";

    //uint8 public decimals = 18; //Same as wei
    uint8 public decimals = 4;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    //This is how we will know if one account is allowed to spend on another account&#39;s behalf.
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer (
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval (
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    //Basically, this runs every time we migrate our contract.
    //constructor(uint256 _initialSupply) public {
    constructor() public {
        uint256 tot = 1000000;
        totalSupply = tot * (uint(10) ** decimals);
        //msg.sender is the account who deployed the contract.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }

    //This is the owner transferring tokens.
    function transfer(address _to, uint256 _value) public returns(bool success) {
        require(balanceOf[msg.sender] >= _value); //If true, continue function execution.
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    //Approves another account to spend tokens on the owner&#39;s behalf.
    //We are basically approving an exchange to transfer tokens on our behalf.
    function approve(address _spender, uint256 _value) public returns(bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //Hand-in-hand with approve(). 3rd party basically.
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