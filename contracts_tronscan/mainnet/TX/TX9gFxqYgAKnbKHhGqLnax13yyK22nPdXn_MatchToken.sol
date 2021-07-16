//SourceUnit: ITRC20.sol

pragma solidity ^0.5.10;

/**
 * @title TRC20 interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//SourceUnit: MatchToken.sol

pragma solidity ^0.5.10;

import "./ITRC20.sol";
import "./SafeMath.sol";

contract Owner {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract TRC20 is ITRC20 {
    using SafeMath for uint256;
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 6;
    uint256 private _totalSupply;
    uint256 public circulationSupply;

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Burn(address indexed from, uint256 value);

   
    constructor(
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        uint256 initialSupply = 2500000;
        _totalSupply = (initialSupply * 10 ** uint256(decimals))*10 ; 
        _balances[msg.sender] = initialSupply  * 10 ** uint256(decimals) ;  
        circulationSupply = _balances[msg.sender];                 
        name = tokenName;                                      
        symbol = tokenSymbol;                                   
    }

   
     function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner,address spender)public view returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function transferFrom(address from, address to,uint256 value) public returns (bool)
    {
        require(_balances[from] >= value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);

        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
       return _transfer(msg.sender, _to, _value);
    
    }

     function _transfer(address _from, address _to, uint _value) internal returns (bool success){
        require(_to != address(0x0));
       
        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit Transfer(_from, _to, _value);

        return true;
    }

    function _burn(address _from, uint256 _value) internal returns (bool success) {
      
        _balances[_from] = _balances[_from].sub(_value)  ;        
        _totalSupply =_totalSupply.sub(_value);                     
        circulationSupply = circulationSupply.sub(_value);
        emit Burn(_from, _value);
        return true;
    }

  
    function _burnFrom(address _from, uint256 _value)  internal {
        require(_value <= _allowed[_from][msg.sender]);
        _balances[_from] = _balances[_from].sub(_value); 
         _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);                            
        circulationSupply = circulationSupply.sub(_value);
        emit Burn(_from, _value);
    }

 
}

/******************************************/
/*             MATCH Token                 */
/******************************************/

contract MatchToken is TRC20, Owner {



    constructor() TRC20("Match", "MATCH") public {}


    /// mineToken
    function mineToken(address target, uint256 mintedAmount) onlyOwner public {

        require( circulationSupply.add(mintedAmount) <= totalSupply());
        circulationSupply = circulationSupply.add(mintedAmount);
        _balances[target] = _balances[target].add(mintedAmount);
        //_totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }

     //burn
    function burn( uint256 _value)  public returns (bool success) {
        _burn(msg.sender,_value);
        return true;
    }

}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}