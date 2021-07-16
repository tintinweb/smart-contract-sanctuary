//SourceUnit: ITRC20.sol

pragma solidity ^0.5.8;

/**
 * @title TRC20 Interface
 * @author @VibraVid @lapits
 */
interface ITRC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



//SourceUnit: Ownable.sol

pragma solidity ^0.5.8;

/**
 * @title Ownable
 * @dev Set & transfer owner
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnershipTransferred(owner, msg.sender);
    }
    
    // modifier to check if caller is owner
    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Transfer Ownership
     * @param _newOwner address of new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.8;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

//SourceUnit: wBTZC.sol

pragma solidity ^0.5.8;

import "./ITRC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title Wrapped BeatzCoin (wBTZC)
 * @author @VibraVid @LapitsTechnologies
 * @dev Implements a TRC20 wrapped token
 */
contract wBTZC is ITRC20, Ownable {
    using SafeMath for uint256;

    string public name = "Wrapped BeatzCoin"; // Token Name
    string public symbol = "wBTZC"; // Token Symbol
    uint256 public decimals = 6; // Token decimals
    uint256 internal _totalSupply;
    trcToken internal btzcTokenId = trcToken(1002413); // TRC10 token ID (which is to be wrapped/unwrapped)

    mapping(address => uint256) private  _balanceOf;
    mapping(address => mapping(address => uint)) private  _allowance;
    
    event  Wrap(address indexed account, uint256 value);
    event  Unwrap(address indexed account, uint256 value);

    constructor() public {
        _mint(msg.sender, 3000000000*10**decimals);
    }

    function() external payable {
        wrap();
    }

    /**
     * @dev Function to wrap BTZC
     */
    function wrap() public payable {
        require(msg.tokenid == btzcTokenId, "Wrap only BTZC[1002413] tokens");
        _mint(msg.sender, msg.tokenvalue);
        emit Transfer(address(0x00), msg.sender, msg.tokenvalue);
        emit Wrap(msg.sender, msg.tokenvalue);
    }

    /**
     * @dev Function to unwrap wBTZC
     * @param _amount of wBTZC token to unwrap.
     */
    function unwrap(uint256 _amount) public {
        require(_balanceOf[msg.sender] >= _amount, "Not enough wBTZC balance");
        require(_totalSupply >= _amount, "Not enough wBTZC totalSupply");
        _burn(msg.sender, _amount);
        msg.sender.transferToken(_amount, btzcTokenId);
        emit Transfer(msg.sender, address(0x00), _amount);
        emit Unwrap(msg.sender, _amount);
    }

    /**
     * @dev Burn tokens
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public onlyOwner returns (bool) {
        _burn(msg.sender, _value);
        return true;
    }

    /**
     * @dev Internal function
     * @param _account The account whose tokens will be burnt.
     * @param _amount The amount that will be burnt.
     */
    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0));
        require(_balanceOf[_account] >= _amount, "Insufficient balance to burn");

        _totalSupply = _totalSupply.sub(_amount);
        _balanceOf[_account] = _balanceOf[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    /**
     * @dev Internal function
     * @param _account account to mint the tokens.
     * @param _amount The amount that will be minted.
     */
    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0));

        _totalSupply = _totalSupply.add(_amount);
        _balanceOf[_account] = _balanceOf[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }
    
    /**
     * @dev _totalSupply
     */
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    
    /**
     * @dev Check balance
     * @param _account to check balance for
     */
    function balanceOf(address _account) public view returns (uint256){
        return _balanceOf[_account];
    }

    /**
     * @dev Return the token a spender can 
     * @param _owner the amount of money to burn
     * @param _spender to be burned from
     */
    function allowance(address _owner, address _spender) public view returns (uint256){
        return _allowance[_owner][_spender];
    }

    /**
     * @dev Approve spend limit
     * @param _spender to check balance for
     * @param _amount spending limit
     */
    function approve(address _spender, uint256 _amount) public returns (bool) {
        _allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev Transfer token
     * @param _to receiver address
     * @param _amount token value to send
     */
    function transfer(address _to, uint256 _amount) public returns (bool) {
        return transferFrom(msg.sender, _to, _amount);
    }

    /**
     * @dev Transfer token from address
     * @param _from sender address
     * @param _to receiver address
     * @param _amount token value to send
     */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(_balanceOf[_from] >= _amount, "Insufficient balance");
        if (_from != msg.sender && _allowance[_from][msg.sender] != uint256(- 1)) {
            require(_allowance[_from][msg.sender] >= _amount, "Amount exceeds the allowed limit");
            _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_amount);
        }
        
        _balanceOf[_from] = _balanceOf[_from].sub(_amount);
        _balanceOf[_to] = _balanceOf[_to].add(_amount);

        emit Transfer(_from, _to, _amount);
        return true;
    }
}