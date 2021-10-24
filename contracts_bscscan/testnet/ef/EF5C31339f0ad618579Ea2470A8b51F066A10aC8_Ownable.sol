/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

pragma solidity ^0.8.9;

//SPDX-License-Identifier: MIT Licensed

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (address payable _Owner) {
        _owner = _Owner;
        emit OwnershipTransferred(address(0), _owner);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// Bep20 standards for token creation

contract token is Ownable {
    
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping (address=>uint256) private balances;
    mapping (address=>mapping (address=>uint256)) private allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(address payable _Owner) Ownable(_Owner){
        
        
        name = "token";
        symbol = "token";
        decimals = 18;
        totalSupply = 1000000000000e18;   
        balances[owner()] = totalSupply;
    }

    function balanceOf(address _owner) view public returns (uint256) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256) {
      return allowed[_owner][_spender];
    }
    
    function increaseAllowance(address user,uint256 value)public returns(bool){
        
        require(allowance(msg.sender,user)>0,"you have not approved tokens equal to parameter");
        
        allowed[msg.sender][user]=allowed[msg.sender][user].add(value);
        
        return true;
    }
    
    function decreaseAllowance(address user,uint256 value)public returns(bool){
        
        require(allowance(msg.sender,user)>=value,"you have not approved tokens equal to parameter");
        
        allowed[msg.sender][user]=allowed[msg.sender][user].sub(value);
        
        return true;
    }
    
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require (balances[msg.sender] >= _amount, "BEP20: user balance is insufficient");
        require(_amount > 0, "BEP20: amount can not be zero");
        
        balances[msg.sender]=balances[msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
    
    function transferFrom(address _from,address _to,uint256 _amount) public returns (bool success) {
        require(_amount > 0, "BEP20: amount can not be zero");
        require (balances[_from] >= _amount ,"BEP20: user balance is insufficient");
        require(allowed[_from][msg.sender] >= _amount, "BEP20: amount not approved");
        
        balances[_from]=balances[_from].sub(_amount);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(_spender != address(0), "BEP20: address can not be zero");
        require(balances[msg.sender] >= _amount ,"BEP20: user balance is insufficient");
        
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

}
 
 
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}