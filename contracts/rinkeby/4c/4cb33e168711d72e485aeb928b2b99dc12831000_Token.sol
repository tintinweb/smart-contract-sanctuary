/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

pragma solidity >=0.4.22 <0.6.0;

contract owned {
    address public owner;
    address public miner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyMiner {
        require(msg.sender == miner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
    
    function setMiner(address newMiner) onlyOwner public {
        miner = newMiner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract TokenERC20 {

    string public name = 'BB Token';
    string public symbol = 'BB';
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
    uint256 public supplyLimit = 1000000000000000000000000;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Mint(address indexed from, address indexed to, uint256 value);
    event Swap(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);

    constructor() public {}

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

}


contract Token is owned, TokenERC20 {
    event SetSupply(uint256 value, string note);

    constructor() TokenERC20() public {}

    function setSupply(uint _value,string memory _note)  public {
        require (totalSupply <= _value);
        supplyLimit = _value;
        emit SetSupply(_value, _note);
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0x0));
        require (balanceOf[_from] >= _value);
        require (balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function mintToken(address _target, uint _value) onlyMiner public {
        require (_target != address(0x0));
        require (totalSupply <= supplyLimit);
        balanceOf[_target] += _value;
        totalSupply += _value;
        emit Transfer(address(0), address(this), _value);
        emit Transfer(address(this), _target, _value);
    }

    function swapToken(address _target, uint _value) onlyMiner public {
        require (_target != address(0x0));
        require (totalSupply <= supplyLimit);
        balanceOf[_target] += _value;
        totalSupply += _value;
        emit Swap(address(0), address(this), _value);
        emit Transfer(address(this), _target, _value);
    }
}