/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

pragma solidity >=0.4.24 <0.9.0;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership (address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract AdvancedToken is Ownable {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint public totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    event Transfer(address indexed _from, address indexed _to, uint tokens);
    event Approval(address indexed _tokenOwner, address indexed _spender, uint tokens);
    event Burn(address indexed _from, uint256 value);


    constructor(string memory tokenName, string memory tokenSymbol, uint initialSupply) public {
        totalSupply = initialSupply*10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address _from, address _to, uint256 value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= value);
        require(balanceOf[_to] <= balanceOf[_to] + value);
        balanceOf[_from] -= value;
        balanceOf[_to] += value;
        emit Transfer(_from, _to, value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // msg.sender = middleman. after approval.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    // company allows spender/employee to spend money
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender,  _value);
        return true;
    }

    function mintToken(address _target, uint256 _mintedAmount) external onlyOwner {
        balanceOf[_target] += _mintedAmount;
        totalSupply += _mintedAmount;
        emit Transfer(address(0), owner, _mintedAmount);
        emit Transfer(owner, _target, _mintedAmount);
    }

    function burn(uint256 _value) external onlyOwner returns(bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }
}