/**
 *Submitted for verification at Etherscan.io on 2019-11-06
*/

pragma  solidity ^0.5.1;
library KPIlib {
    function mul(uint256 _numA, uint256 _numB) internal pure returns (uint256) {uint256 numC = _numA * _numB; assert(_numA == 0 || numC / _numA == _numB); return numC;}
    function add(uint256 _numA, uint256 _numB) internal pure returns (uint256) {uint256 numC = _numA + _numB; assert(numC >= _numA); return numC;}
    function div(uint256 _numA, uint256 _numB) internal pure returns (uint256) {return(_numA < _numB || _numA == 0 || _numB == 0) ? 0: _numA / _numB;}
    function sub(uint256 _numA, uint256 _numB) internal pure returns (uint256) {assert(_numB <= _numA); return _numA - _numB;}}

contract Kelpie {using   KPIlib for  uint256;
    bytes32  constant    name        = "Kelpie";
    bytes32  constant    symbol      = "KPI";
    uint8    constant    decimals    = 8;
    uint256  constant    totalSupply = 1e20;
    address  payable     creator;
    mapping  (address => uint256) internal balances;
    event    Transfer(   address  indexed  _owner, address indexed _receiver, uint256 _amount);
    constructor(address  initial) public   {creator = msg.sender; balances[initial] = 1e14; balances[creator] = totalSupply.sub(1e14);}
    function() external  payable  {transfer(creator, msg.sender, msg.value.div(price(0)));}
    function balanceOf(  address  Address) public view returns (uint Balance) {return balances[Address];}
    function price(      uint256  _amt) public view returns(uint Price) {return totalSupply.sub(balances[creator].add(_amt)).div(1e8);}
    function transfer(   address  payable Address, uint256 Kelpies) public payable {transfer(msg.sender, Address, Kelpies);}
    function transfer(   address  payable _from,   address payable _to, uint256 _amt) internal {
        require(_amt > 0 && _amt <= balances[_from]); _to = (_to == address(this)) ? creator: _to;
        balances[_from] = balances[_from].sub(_amt); balances[_to] = balances[_to].add(_amt);
        if (_to == creator) _from.transfer(price(_amt).mul(_amt)); emit Transfer(_from, _to, _amt);}}

//  Kelpies can be brought by sending ether to this contract or sold by sending them to this contract.