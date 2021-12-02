/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

pragma solidity 0.8.7;
contract SecondToken {
    string private _name = "SecondToken";
    string private _symbol = "SDT";
    uint8 private _decimals = 2;
    uint256 private _totalSupply;
    uint256 private _maxSupply = 21000 *10**_decimals;
    uint256 private price;
    address payable owner;


    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from,address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Buy(address indexed _buyer, uint256 _value);

    constructor(){
        // uint256 supply = 0;
        // _balances[msg.sender] = supply;
        price = 0.0001 ether;
        _totalSupply = 0;
        // owner = payable(msg.sender);
        // emit Transfer(address(0), msg.sender, supply);

    }

      
    function buy() public payable {
        uint256 amount = (msg.value / price) *10**_decimals;
        require(_totalSupply + amount <= _maxSupply,"You can't buy tokens, emission exceeded."); 
        _maxSupply -= amount;
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        emit Buy(msg.sender, amount);
        emit Transfer(address(0), msg.sender, amount);
        while ((_totalSupply - amount)/1000 < _totalSupply/1000) {
        price += price/100*10;
        }
    }   

    function withdraw() public {
        owner.transfer(address(this).balance);        
    }

    function destroy() public {
        require(msg.sender == owner, "Only owner can call this function");
        selfdestruct(owner);
    }

    function name () public view returns(string memory){
        return _name;
    }

    function symbol () public view returns(string memory){
        return _symbol;
    }

    function decimals () public view returns(uint8){
        return _decimals;   
    }

    function maxSupply() public view returns (uint256){
    return _maxSupply;
    }  

    function totalSupply() public view returns(uint256){
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

    function approve(address _spender,uint256 _value) public returns (bool){
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256){
        return _allowances[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(_allowances[_from][msg.sender] >= _value, "You are not allowed to spend this amount of tokens.");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

}