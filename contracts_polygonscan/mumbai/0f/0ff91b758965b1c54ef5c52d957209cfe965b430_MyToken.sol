/**
 *Submitted for verification at polygonscan.com on 2021-11-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;


interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);    
   


}  


contract MyToken is IERC20 {
   
   
    string public name;
    string public symbol;
    uint8 public decimals ;
   
   
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
   

    uint256 totalSupply__;
    address admin;
   
   
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _tsupply) public{
    totalSupply__ = _tsupply;
    balances[msg.sender] = totalSupply__;
    name = _name;
    symbol = _symbol;
    decimals =_decimals;
    admin = msg.sender;
    }
   
   
function totalSupply() public override view returns (uint256) {
    return totalSupply__;
    }

function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
}


function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= balances[msg.sender];
        balances[receiver] += balances[receiver];
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin can run this function");
        _;
    }

    function mint(uint256 _qty) public onlyAdmin returns(uint256){
        totalSupply__ += _qty;
        balances[msg.sender] += _qty;

        return totalSupply__;
    }
     function burn(uint256 _qty) public onlyAdmin returns(uint256){
        require(balances[msg.sender] >= _qty);
        totalSupply__ -= _qty;
        balances[msg.sender] -= _qty;

        return totalSupply__;
    }

   function allowance(address _owner, address _spender) public view returns (uint remining) {
        return allowed[_owner][_spender];
    }
   
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender,_value);
        return true;
    }


function transferFrom(address _from, address _to, uint256 _value) public   returns (bool success) {
        uint256 allowance1 = allowed[_from][msg.sender];
        require (balances[_from] >= _value && allowance1 >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
   
        emit Transfer(_from, _to, _value);
        return true;
    }  
   
}