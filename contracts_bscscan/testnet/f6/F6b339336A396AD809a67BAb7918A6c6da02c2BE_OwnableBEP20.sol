// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import './Ownable.sol';
import './IBEP20.sol';

contract OwnableBEP20 is Ownable, IBEP20 {
  
  mapping (address => uint256) public balances;

  mapping (address => mapping (address => uint)) public allowances;

  uint256 public override totalSupply = 0;
  uint8 public constant override decimals = 18;
  string public override symbol;
  string public override name;

  constructor(string memory _name, string memory _symbol) {
      name = _name;
      symbol = _symbol;
  }

  function getOwner() public view override returns (address) { return owner; }
  
  function balanceOf(address account) external view override returns (uint256) {
    return balances[account];
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, allowances[sender][msg.sender] - amount);
    return true;
  }

  function mint(uint256 amount) public virtual onlyOwner returns (bool) {
    _mint(msg.sender, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    balances[sender] -= amount;
    balances[recipient] += amount;
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal {
    totalSupply = totalSupply += amount;
    balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

contract Ownable {

	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		owner = msg.sender;
		emit OwnershipTransferred(address(0), owner);
	}

	modifier onlyOwner() {
		require(owner == msg.sender, "Ownable: caller is not the owner");
		_;
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
  
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface IBEP20 {
  function totalSupply() external view returns (uint);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

