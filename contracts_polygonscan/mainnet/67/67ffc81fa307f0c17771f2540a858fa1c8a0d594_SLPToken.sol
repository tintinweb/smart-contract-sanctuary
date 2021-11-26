/**
 *Submitted for verification at polygonscan.com on 2021-11-25
*/

// SPDX-License-Identifier: MIT

/*
A contract of
   ____     __     __    _____    _____  
  (    )   (_ \   / _)  (_   _)  / ___/  
  / /\ \     \ \_/ /      | |   ( (__    
 ( (__) )     \   /       | |    ) __)   
  )    (      / _ \       | |   ( (      
 /  /\  \   _/ / \ \_    _| |__  \ \___  
/__(  )__\ (__/   \__)  /_____(   \____\ 
                                  Origin

Game Token (Smooth Love Potion)
SLP Token

www.axieorigin.com
docs.axieorigin.com
[email protected]

Axie Origin Foundation                
*/

pragma solidity 0.8.9;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
 library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
} 

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() external view returns (uint256 _supply);
  function balanceOf(address _owner) external view returns (uint256 _balance);

  function approve(address _spender, uint256 _value) external returns (bool _success);
  function allowance(address _owner, address _spender) external view returns (uint256 _value);

  function transfer(address _to, uint256 _value) external returns (bool _success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract SysCtrl is Context {

  address public communityAdmin;
  bool public tokenPaused = false;
  mapping (address => bool) public communityMinter;

  constructor() {
      communityAdmin = _msgSender();
  }

  modifier onlyAdmin() {
    require(_msgSender() == communityAdmin, "Only for admin community");
    _;
  }

  function sAdmin(address _new) public onlyAdmin {
    communityAdmin = _new;
  }

  modifier onlyMinter() {
    require(communityMinter[_msgSender()], "Only for minter contract group");
    _;
  }

  function addMinter(address _new) public onlyAdmin {
      communityMinter[_new] = true;
  }

  function removeMinter(address _remove) public onlyAdmin {
      communityMinter[_remove] = false;
  }

  function pauseMarket(bool _paused) external onlyAdmin {
        tokenPaused = _paused;
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20, SysCtrl {
  using SafeMath for uint256;

  uint256 public totalSupply;
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) internal _allowance;

  function approve(address _spender, uint256 _value) public returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return _allowance[_owner][_spender];
  }

  function increaseAllowance(address _spender, uint256 _value) public returns (bool) {
    _approve(msg.sender, _spender, _allowance[msg.sender][_spender].add(_value));
    return true;
  }

  function decreaseAllowance(address _spender, uint256 _value) public returns (bool) {
    _approve(msg.sender, _spender, _allowance[msg.sender][_spender].sub(_value));
    return true;
  }

  function transfer(address _to, uint256 _value) public returns (bool _success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
    _transfer(_from, _to, _value);
    _approve(_from, msg.sender, _allowance[_from][msg.sender].sub(_value));
    return true;
  }

  function _approve(address _owner, address _spender, uint256 _amount) internal {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");

    _allowance[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }

  function _transfer(address _from, address _to, uint256 _value) internal {
    require(_from != address(0), "ERC20: transfer from the zero address");
    require(_to != address(0), "ERC20: transfer to the zero address");
    require(_to != address(this), "ERC20: transfer to this contract address");

    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(_from, _to, _value);
  }
}

/**
 * @title ERC20Detailed interface
 */
interface IERC20Detailed {
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function decimals() external view returns (uint8 _decimals);
}

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum/Polygon all the operations are done in wei.
 */
contract ERC20Detailed is ERC20, IERC20Detailed {
  string public name;
  string public symbol;
  uint8 public decimals;
}


contract ERC20Mintable is ERC20Detailed  {
  
  using SafeMath for uint256;

  function mint(address _to, uint256 _value) public onlyMinter returns (bool _success) {
    return _mint(_to, _value);
  }

  function _mint(address _to, uint256 _value) internal returns (bool success) {
    totalSupply = totalSupply.add(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(address(0), _to, _value);
    return true;
  }

  /**
  * @dev Tokens can only be burned by their owners. 
  * This function is mainly used by game contracts, usually burning received tokens to control inflation
  */
  function burn(uint256 _value) public returns (bool _success){
      require(balanceOf[msg.sender] >= _value);
      return _burn(msg.sender,_value);
  }

  function _burn(address _account, uint256 value) internal returns (bool success) {
    require(_account != address(0));
    totalSupply = totalSupply.sub(value);
    balanceOf[_account] = balanceOf[_account].sub(value);
    emit Transfer(_account, address(0), value);
    return true;
  }
}


/**
 * @title Smooth Love Potion (Official)
 * @dev 
 */
contract SLPToken is ERC20Mintable {

  using SafeMath for uint256;
  
  constructor() {
    name = "Smooth Love Potion";
    symbol = "SLP";
    decimals = 0;
    totalSupply = 0;
  }
}