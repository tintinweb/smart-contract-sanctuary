/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

interface ERC20Interface {
    
    function totalSupply() external view returns (uint);

    function balanceOf(address _account) external view returns (uint);

    function decimals() external view returns (uint8);

    function transfer(address _recipient, uint _amount) external returns (bool);

    function allowance(address _owner, address _spender) external view returns (uint);

    function approve(address _spender, uint _amount) external returns (bool);

    function transferFrom(
        address _sender,
        address _recipient,
        uint _amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

contract Ownable is Context {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
       owner = _msgSender();
  }

  modifier onlyOwner() {
    require(_msgSender() == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract TESTCODECOIN is ERC20Interface,Ownable {
  using SafeMath for uint256;
  
  string public name;
  string public symbol;
  uint256 private supply;
  uint8 private _decimals;
  address public taxAddress;
  
  uint256 public dexTaxFee = 50;

  mapping (address => uint256) private balances;

  mapping (address => mapping (address => uint256)) private allowed;

  constructor() public {
        name = "TESTCCOIN";
        symbol = "TCOIN";
        _decimals = 8;
        supply = 10 * 10**9 * 10**9;
        balances[_msgSender()] = supply;
        taxAddress = msg.sender;
        emit Transfer(address(0), _msgSender(), supply);
    }

  function setTaxAddress(address _taxAddress) public onlyOwner {
        taxAddress = _taxAddress;
  }
    
  function totalSupply() external view returns (uint256) {
    return supply;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
  
  function decimals() external view returns (uint8) {
    return _decimals;
  }
  
  
  function transfer(address _recipient, uint _amount) external returns (bool){
      _transfer(_msgSender(), _recipient, _amount);
      return true;
  }

    function allowance(address _owner, address _spender) external view returns (uint){
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint _amount) external returns (bool){
        allowed[_msgSender()][_spender] = _amount;
        emit Approval(_msgSender(), _spender, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint _amount
    ) external returns (bool){
         _transfer(_sender, _recipient, _amount);
        allowed[_sender][_msgSender()] = allowed[_sender][_msgSender()].sub(_amount);
        return true;
    }
    
    
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal  {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = balances[_sender];
        require(senderBalance >= _amount, "ERC20: transfer amount exceeds balance");

        
        uint256 taxFee = _amount.mul(dexTaxFee).div(100);
        balances[taxAddress] = balances[taxAddress].add(taxFee);
        emit Transfer(_sender, taxAddress, taxFee);
        _amount = _amount.sub(taxFee);

        
        balances[_recipient] = balances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }
}