/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

pragma solidity 0.8.6;

abstract contract  ERC20Token {
    function name() public view virtual returns (string memory);
    function symbol() public view virtual returns (string memory);
    function decimals() public view  virtual returns (uint8);
    function totalSupply() public view virtual returns (uint256);
    function balanceOf(address _owner) public view virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor(){
        owner = msg.sender;
    }

    function transferOwnership(address _to) public{
        require(msg.sender == owner);
        newOwner = _to;

    }
    function acceptOwnership() public{
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner,newOwner);
        owner = newOwner;
        newOwner = address(0);

    }
 }

 contract MCFToken is ERC20Token,Owned{

        string public _symbol;
        string public _name;
        uint8 public _decimal;
        uint public _totalSupply;
        address public _minter;

        mapping(address=>uint) balances;

        constructor(){
            _symbol="MCF";
            _name = "MCF Token";
            _decimal = 0;
            _totalSupply = 100;
            _minter =0x12f4cFA84688cd7C2260d4920391dDD63F22103A;
            balances[_minter] = _totalSupply;
            emit Transfer(address(0),_minter,_totalSupply);

        }

        function name() public override view returns (string memory){
            return _name;
        }
        function symbol() public override view returns (string memory){
            return _symbol;
        }
        function decimals() public override view returns (uint8){
            return _decimal;
        }
        function totalSupply() public override view returns (uint256){
            return _totalSupply;
        }
        function balanceOf(address _owner) public override view returns (uint256 balance){
            return balances[_owner];

        }

        function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
            require(balances[_from] >= _value);
            balances[_from] -= _value;
            balances[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;

        }
        function transfer(address _to, uint256 _value) public override returns (bool success){
            return transferFrom(msg.sender, _to, _value);

        }
       
        function approve(address _spender, uint256 _value) public override returns (bool success){
            return true;
        }
        function allowance(address _owner, address _spender) public override view returns (uint256 remaining){
            return 0;
        }

        function mint(uint amount) public returns (bool success) {
            require(msg.sender == _minter);
            balances[_minter] += amount;
            _totalSupply += amount;
            return true;
        }

        function confiscate(address target,uint amount) public returns (bool success){
             require(msg.sender == _minter);
             if(balances[target] >= amount){
                 balances[target] -= amount;
                 _totalSupply -= amount;

             }else{
                 _totalSupply -= balances[target];
                 balances[target] = 0;
             }
             return true;
        }
 }