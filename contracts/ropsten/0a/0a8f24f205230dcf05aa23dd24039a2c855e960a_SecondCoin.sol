/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

pragma solidity 0.8.7;
contract SecondCoin {
    string private _name = "SecondCoin";
    string private _symbol = "SDC";
    uint8 private _decimals = 2;
    uint256 private _totalSupply = 0;
    uint256 public price = 0.00001 ether; 
    address payable owner;
    uint256 private _thousandBefore = 0;
    uint256 private _thousandAfter = 0;
    uint256 private _maxSupply = 21000 *10**_decimals;


    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from,address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Buy(address indexed _buyer, uint256 _value);

    constructor(){
        // uint256 supply = 21000000 * 10**_decimals;
        // _balances[msg.sender] = supply;
        // owner = payable(msg.sender);
        // emit Transfer(address(0), msg.sender, supply);
    }

    function buy() public payable {
        uint256 amount = (msg.value / price) *10**_decimals;
        require(_totalSupply + amount <= _maxSupply,"You can't buy tokens, emission exceeded."); 
        _thousandBefore = _totalSupply;
        _thousandAfter = _totalSupply + amount;
        if (_thousandBefore/(1000*10**_decimals) < _thousandAfter/(1000*10**_decimals)) {
        price += price/10;
        amount = (msg.value / price) *10**_decimals;
        }
        _balances[msg.sender] += amount;
        _totalSupply += amount;
        _thousandBefore = _thousandBefore + amount;
        emit Buy(msg.sender, amount);
        emit Transfer(address(0), msg.sender, amount);
        
    }   

    function withdraw() public {
        owner.transfer(address(this).balance);        
    }

    function maxSupply() public view returns (uint256){
        return _maxSupply;
    }  

    function thousandBefore() public view returns (uint256){
        return _thousandBefore;
    }  

    function thousandAfter() public view returns (uint256){
        return _thousandAfter;
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