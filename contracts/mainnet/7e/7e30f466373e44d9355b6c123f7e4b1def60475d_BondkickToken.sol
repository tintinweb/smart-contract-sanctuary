pragma solidity ^0.4.16;

contract ERC20 {

    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

    function transfer(address to, uint256 value) public returns (bool success);

    function transferFrom(address from, address to, uint256 value) public returns (bool success);

    function approve(address spender, uint256 value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract BondkickToken is ERC20 {

    string public name;
    string public symbol;
    uint8 public decimals;
    bool public paused;

    address public owner;
    address public minter;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }
    
    function BondkickToken(string _name, string _symbol, uint8 _decimals, uint256 _initialMint) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;
        minter = msg.sender;
        
        if (_initialMint > 0) {
            totalSupply += _initialMint;
            balanceOf[msg.sender] += _initialMint;

            Transfer(address(0), msg.sender, _initialMint);
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value);
        
        _transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        
        allowance[_from][msg.sender] -= _value;
        
        _transfer(_from, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));

        allowance[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);
        
        return true;
    }

    function mint(uint256 _value) public notPaused onlyMinter returns (bool success) {
        require(_value > 0 && (totalSupply + _value) >= totalSupply);
        
        totalSupply += _value;
        balanceOf[msg.sender] += _value;

        Transfer(address(0), msg.sender, _value);
        
        return true;
    }
    
    function mintTo (uint256 _value, address _to) public notPaused onlyMinter returns (bool success) {
        require(_value > 0 && (totalSupply + _value) >= totalSupply);
        
        totalSupply += _value;
        balanceOf[_to] += _value;

        Transfer(address(0), _to, _value);
        
        return true;
    }

    function unmint(uint256 _value) public notPaused onlyMinter returns (bool success) {
        require(_value > 0 && balanceOf[msg.sender] >= _value);

        totalSupply -= _value;
        balanceOf[msg.sender] -= _value;

        Transfer(msg.sender, address(0), _value);

        return true;
    }
    
    function changeOwner(address _newOwner) public onlyOwner returns (bool success) {
        require(_newOwner != address(0));

        owner = _newOwner;
        
        return true;
    }

    function changeMinter(address _newMinter) public onlyOwner returns (bool success) {
        require(_newMinter != address(0));

        minter = _newMinter;

        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        Transfer(_from, _to, _value);
    }
}