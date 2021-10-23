//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import 'openzeppelin-solidity/contracts/utils/Context.sol'; //mi serve per _msgSender

//ricolve l'errore su override dopo l'importazione di Context.sol - TODO: ?????
import 'openzeppelin-solidity/contracts/token/ERC20/extensions/IERC20Metadata.sol';

contract Alitalia is Context, IERC20, IERC20Metadata{

    //---VARIABLES---
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address ownerTokenAddress = 0x5ceB8921ED386990485feA601cf6d3A1393Ea13f;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    //---PARTE DEL TOKEN---
    constructor (){
        _name = "Alitalia";
        _symbol = "ITA";

        _mint(msg.sender, 10**(18+3));
    }


    function name() public view virtual override returns(string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory){
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }


    //---IMPLEMENTATIONS OF INTERFACE---

    //return the amount of token existance
    //NB se il token è infinito mi restituisce l'attuale
    function totalSupply() public view virtual override returns(uint256){
        return _totalSupply;
    }

    //return the amount of tokens owned by an account
    function balanceOf(address account) public view virtual override returns(uint256) {
        return _balances[account];
        
    }

    /*move AMOUNT tokens from the caller to RECIPIENT
    return:
    - true if success
     */
    //TODO: cosa controlla che l'address non è zero?
    function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
        _transfer(_msgSender(),recipient, amount);
        return true;
    }

    /* restituisce il numero di token rimanenti spendibili per conto del owner
    questo è zero di default e varia ad ogni chiamata di:
    - approve 
    - transferFrom

    TODO ??????
    */
    function allowance(address owner,address spender) public view virtual override returns(uint256){
        return _allowances[owner][spender];
    }

    /* set's amount as the allowance of 'spender' over the caller's tokens.
     TODO ?????
    */
    function approve(address spender,uint256 amount) public virtual override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /* emette un evento "approva" che indica l'avvenuto aggiornamento di allowance

    require:
    - mitt, dest != zero
    - mitt.saldo >= amount
    - il chimante deve avere un permesso di SENDER > di amount
    */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool){
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20 transfer amount excedes allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    /* equivalente ad APPROVE ma mitiga i problemi descritti in IERC20-APPROVE

    require:
    - spender != 0 

    TODO: capire i problemi e le differenze
    */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /*equivalente ad APPROVE ma mitiga i problemi descritti in IERC20-APPROVE

    require:
    - spender != 0 
    - `spender` must have allowance for the caller of at least `subtractedValue`.

    TODO: capire i problemi e le differenze, cos'è il secondo require ????
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /* move amount of token from SENDER to RECIPIENT

    QUESTA FUNZIONE È EQUIVALENTE A TRANSFER E PUÒ ESSERE USATA
    PER IMPLEMENTARE LE TOKEN FEE 

    require:
    - sender, recipient  != 0
    - sender.balance >= amount
    */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual{
        require(sender != address(0), "ERC20 transfer from the zero address");
        require(recipient != address(0), "ERC20 transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20 transfer amount exceeds balance");

        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        //calcolo delle fee
        uint256 fee = amount / 100;
        emit Transfer(sender, ownerTokenAddress, fee);

        _afterTokenTransfer(sender, recipient, amount);
        
    }

     /* crea AMOUNT tokens (nuovi) e gli assegna ad un account incrementando la total supply



     @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }


    /////-----------------------------------
     /* imposta la quantita AMOUNT come quantità spendibile (SPENDER) attraverso i
     token del proprietario

     require:
     - owner, spender != o

    TODO si può usare per impostare automatic allowances for subsystem ????????
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /*come da nome viene chiamato prima di ogni trasferimento di token (minting e burn inglusi)

    condizioni:
    - if (from, to != 0) FROM.amount trasferiti a TO
    - if (from == 0) AMOUNT saranno minted per TO TODO: ?????
    - if (to == 0) FROM.AMOUNT vengono burned
    - in generale/sempre ( from && to ) != o
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /* come da nome viene chaiamto dopo ogni trasferimento inclusi mint e burn

    condizioni:
    SONO UGUALI A QUELLE DI BEFORETOKENTRANSFER 

     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}