/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

pragma solidity 0.8.7;

contract Duna {
    
    string private _name = "DunaToken";
    string private _symbol = "DUNA";
    uint8 private _decimals = 2;
    uint256 public maxTotalSupply = 21000;
    uint256 private stepUpPice = 1000 * 10**_decimals;
    uint256 private _totalSupply;
    address public _owner;
    uint256 public price = 0.001 ether;
    
    
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Buy(address indexed _buyer, uint256 _value);
    
    constructor(){
        _owner = msg.sender;
    }
    
    function buy() public payable returns(uint256 amount){

        uint256 amount = (msg.value / price) * 10**_decimals;
        while(amount >= stepUpPice) {
            amount -= stepUpPice;
            _balances[msg.sender] += stepUpPice;
            _totalSupply += stepUpPice;
            emit Buy(msg.sender, stepUpPice);
            emit Transfer(address(0), msg.sender, stepUpPice);
            price = price + price * 10 / 100;
        }
        if (amount > 0) {
            _balances[msg.sender] += amount;
            _totalSupply += amount;
            emit Buy(msg.sender, amount);
            emit Transfer(address(0), msg.sender, amount);
        }
        return amount;
    }
    
    function withdraw() public {
        payable(_owner).transfer(address(this).balance);
    }
    
    function destroy() public {
        require(msg.sender == _owner);
        selfdestruct(payable(_owner));
    }
    
    function birth(uint256 value) public returns(bool){
        require(msg.sender == _owner, "Available only to the owner");
        _balances[msg.sender] += value;
        _totalSupply += value;
        emit Transfer(address(0), msg.sender, value);
    }
    
    function name() public view returns(string memory){
        return _name;
    }
    
    function symbol() public view returns(string memory){
        return _symbol;
    }
    
    function decimals() public view returns(uint8){
        return _decimals;
    }
    
    function totalSypply() public view returns(uint256){
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns(uint256){
        return _balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns(bool){
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool succes){
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowances( address _owner, address _spender) public view returns (uint256) {
        return _allowances[_owner][_spender];
    }
    
    function transferFrom( address _from, address _to, uint256 _value) public returns (bool) {
        require(_allowances[_from][msg.sender] >= _value, "Not allowed");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}