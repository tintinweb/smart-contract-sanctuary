/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

pragma solidity >=0.4.17;

contract GOCP {
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private owner;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Supply(string date, uint256 _value);
    event Burn(address indexed _owner, uint256 _value);

    
    constructor(string memory _tokenName, string memory _tokenSymbol) public payable {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = 8;
        _totalSupply = 0;

        owner = 0x01dfc9c3789dEBa770eAF2eC75b61f8C530301Bc;
        
        balances[owner] = _totalSupply;
        
        uint256 unit = 6678750000000;
        
        balances[0x3a22d9F57665c523387ff85F8C56ADb2E67a137b] = unit;
        balances[0x618Ae5efD41A28FAac4E383912E8bE8753A44F19] = unit;
        balances[0xa7ed28C25BB959cD08851F3916fcD356a6917Cb5] = unit;
        balances[0xc42A0b069dE537622ef047049Cea162bBF85F530] = unit;
        balances[0xa6bFfd59B0d97d887FfCd0a887f119BD1b5fE5ae] = unit;
        
        balances[0xe75A55634A05a022DC6cc2396A4d4beBEc868F20] = unit;
        balances[0xa31c4BDC21b0380351C07dd9F883E6acA2145BF0] = unit;
        balances[0xE532D9de7371E1179fc5A074D0509360498aEEbb] = unit;
        balances[0x07226bA841D130daf422cD12D7b90f3E7d08FA6D] = unit;
        balances[0xb6B661c0a735D80345CC38f9375BdeE2Ca27A6dB] = unit;
        
        balances[0xcf14459d0aF98a21F7C9D48A5C2ED5738CCE88cc] = unit;
        balances[0x00536F5700D4720057a3760f9FCd811870497Ece] = unit;
        balances[0xA5c782bc6926c6352eBf2227E0a13946FD59D770] = unit;
        balances[0xf3065b0B60B5aa40384a608d0eA7661EFe9158b3] = unit;
        balances[0xBb7932C223c98b299991bEB64755DDE5b60bFD7A] = unit;
        
        balances[0xdCc4839CE4560A8bCc2550C5878486D9D414cCb5] = unit;
        balances[0xDec6a0C2Ac6cC5D6208F63C12642a7071e684808] = unit;
        balances[0xC18c0F578cfb3F774e310506B3c37B4dB672f027] = unit;
        balances[0x305e5B2CCAB0A72E10b21b218Ecf2c0a14986c46] = unit;
        balances[0xA769Bed2E703a4698d8650B13FB333B01F9C6D95] = unit;
        
    }
    
    
    function name() public view returns (string memory) { return _name; }

    function symbol() public view returns (string memory) { return _symbol; }
    
    function decimals() public view returns (uint8) { return _decimals; }
    
    function totalSupply() public view returns (uint256) { return _totalSupply; }

    function balanceOf(address _owner) public view returns (uint256 balance) { return balances[_owner]; }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(this));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]);
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value > balances[_to]);
        
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;
         
        emit Transfer(_from, _to, _value);
         
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value > 0);
        
        allowed[msg.sender][_spender] = _value;
         
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    
    function supply(string memory date, uint256 _value) public returns (bool success) { 
        require(msg.sender == owner);
        
        balances[msg.sender] += _value;
        _totalSupply += _value;
        
        emit Supply(date, _value);
        
        return true;
    }

    function burn(uint256 _value) public returns (bool success) { 
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] -= _value;
        _totalSupply -= _value;
        
        emit Burn(msg.sender, _value);
        
        return true;
    }

    function burnFor(address _recipient, uint256 _value) public returns (bool success) { 
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        
        balances[msg.sender] -= _value;
        _totalSupply -= _value;
        
        emit Burn(_recipient, _value);
        
        return true;
    }
    
    function destroy() public {
        require(msg.sender == owner);
        
        selfdestruct(msg.sender);
    }
    
    function transferOwnership(address _owner) public {
        require(msg.sender == owner);
        
        owner = _owner;
    }
    
    
}