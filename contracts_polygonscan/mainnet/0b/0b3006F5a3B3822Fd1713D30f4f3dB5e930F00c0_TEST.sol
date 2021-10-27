pragma solidity 0.5.16;

import { IERC20 } from "./IERC20.sol"; //Eth
//import { BEP20 } from "./BEP20.sol";
//import { IBEP20 } from "./IBEP20.sol"; // BSC
import { Context } from "./Context.sol";
import { SafeMath } from "./SafeMath.sol";
import { Ownable } from "./Ownable.sol";
import { LGEWhitelisted } from "./LGEWhitelisted.sol";


contract TEST is Context, IERC20,  Ownable, LGEWhitelisted {  
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    constructor() public {
        _name = "TEST";
        _symbol = "TEST";
        _decimals = 18;
        _totalSupply = 500000000 * 10 ** 18;
        _balances[_msgSender()] = _totalSupply;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }




    /**
    * @dev Returns the token owner.
    */
    function getOwner() external view returns (address) {
        return owner();
    }
    
    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    
    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory) {
        return _name;
    }
    
    /**
    * @dev See {ERC20-totalSupply}.
    */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    /**
    * @dev See {ERC20-balanceOf}.
    */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    
    /**
    * @dev See {ERC20-transfer}.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    /**
    * @dev See {ERC20-allowance}.
    */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**
    * @dev See {ERC20-approve}.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    /**
    * @dev See {ERC20-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {ERC20};
    *
    * Requirements:
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    * - the caller must have allowance for `sender`'s tokens of at least
    * `amount`.
    */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    /**
    * @dev Atomically increases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {ERC20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    /**
    * @dev Atomically decreases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {ERC20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    * - `spender` must have allowance for the caller of at least
    * `subtractedValue`.
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    /**
    * @dev Moves tokens `amount` from `sender` to `recipient`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        _applyLGEWhitelist(sender, recipient, amount);
        
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    *
    * This is internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `spender` cannot be the zero address.
    */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    } 
}