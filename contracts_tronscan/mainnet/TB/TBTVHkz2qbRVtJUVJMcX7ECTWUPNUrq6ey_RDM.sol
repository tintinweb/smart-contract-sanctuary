//SourceUnit: RDLOTTERY_MEMBER.sol

pragma solidity 0.5.12;
/*! RDLOTTERY_MEMBER.sol | SPDX-License-Identifier: MIT License */
interface ITRC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() external view returns(uint256);
    function balanceOf(address _owner) external view returns(uint256);
    function transactionTime(address _to) external view returns(uint40);
    function approve(address _spender, uint256 _value) external returns(bool);
    function transfer(address _to, uint256 _value) external returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function allowance(address _owner, address _spender) external view returns(uint256);
    
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x + y) >= x, "SafeMath: MATH_ADD_OVERFLOW");
    }

    function sub(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x - y) <= x, "SafeMath: MATH_SUB_UNDERFLOW");
    }

    function mul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "SafeMath: MATH_MUL_OVERFLOW");
    }
}

contract TRC20 is ITRC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping (address => uint40) public transactionTime;
    
    function _mint(address _to, uint256 _value) internal {
        totalSupply = totalSupply.add(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(address(0), _to, _value);
    }
     
      function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);

        emit Transfer(from, address(0), value);
    }

   function transfer (address _to, uint256 _value) public returns (bool surccess) {
        require (balanceOf[msg.sender] >= _value, "RDM SAY: You don't have enough balance");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        transactionTime[_to] = uint40(block.timestamp);
        emit Transfer(msg.sender,   _to,  _value);
        return true;
    }
    
    function approve ( address _spender, uint256 _value) public returns (bool surccess){
       allowance[msg.sender][_spender] = _value;
      emit  Approval(msg.sender, _spender, _value);
      return true;
    }
    
    function transferFrom (address _from, address _to, uint256 _value) public returns (bool surccess){
        require(balanceOf[_from] >= _value,"RDM SAY: You don't have enough balance");
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from] [msg.sender] = allowance[_from] [msg.sender].sub(_value);
        transactionTime[_to] = uint40(block.timestamp);
        emit Transfer( _from, _to, _value);
        return true;
        
    }
}

contract RDM is TRC20 {
    address public Owner;
     modifier onlyOnwer() {
        require(msg.sender == Owner, "RDM SAY: Only Admin can do this");
        _;
    }
    
    constructor(address _TokenOwner) public {
        Owner = msg.sender;
        name = "RDLOTTERY MEMBER";
        symbol = "RDM";
        decimals = 6;

        _mint(_TokenOwner, 1000000000000 * uint256(10) ** decimals);
    }
    
     function burn(uint256 value) external onlyOnwer {
        require(value < totalSupply,"RDM SAY: You Can't burn the whole supply");
        require(balanceOf[msg.sender] >= value, "RDM SAY: You don't have enough balance for this");
        if (totalSupply == 1000000 * uint256(10) ** decimals)revert();
         
        _burn(msg.sender, value);
    }
  
    
}