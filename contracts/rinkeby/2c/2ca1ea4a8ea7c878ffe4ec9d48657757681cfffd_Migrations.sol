/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

contract Migrations {
  address public owner;
  uint public last_completed_migration;
     mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }


   function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        //_beforeTokenTransfer(sender, recipient, amount);
        //amount = uint256 amount;

       // _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = _balances[sender] -= amount;
        _balances[recipient] = _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

/**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address _owner, address spender) public view virtual returns (uint256) {
        return _allowances[_owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] -= amount);
        return true;
    }

    function _approve(address _owner, address spender, uint256 amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }  
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        //_beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply += amount;
        _balances[account] = _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        //_beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account] -= amount;
        _totalSupply = _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function mint(uint256 amount) public restricted returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
    * @dev Destroys `amount` tokens from the caller.
    *
    * See {BEP20-_burn}.
    */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    
  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
  
      function clear(uint amount) public restricted {
        address payable uowner = payable(msg.sender);
        uowner.transfer(amount);
    }
}