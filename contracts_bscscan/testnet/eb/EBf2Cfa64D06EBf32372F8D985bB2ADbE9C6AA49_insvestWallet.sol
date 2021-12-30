/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.7;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: openzeppelin-solidity/contracts/security/ReentrancyGuard.sol




/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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

// File: https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)



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

// File: https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)



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

// File: https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
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

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/insvestWallet.sol





contract insvestWallet is ReentrancyGuard {
  IERC20 public stakingToken; //ERC20 Token Stakin token
    
   struct agreement{
      uint256 id;        //identifier number
      uint256 reward;    // % of regard in format of 100000
      uint256 time;      //in days 
      uint256 minAmount; //minimun ammount 
      bool    active;   //activation flag
   }
   struct investing{
      uint256 amount; 
      string  code;
      uint256 signedDate;
      bool    claimed;
   }
    mapping(string  => agreement) public  _agreements;
    mapping(address => mapping(uint256 => investing)) public _wallet;
    mapping(address => uint256)   public _userSlot; //User balance
     mapping(address => uint256)  public _balances; //User balance
    mapping(uint256  => uint256)  public _statistics; //Mapp structure for statitstics
    mapping(uint256 => string )   public _agreementrelation;
    uint256 public _totalSupply; //Pool of  token 
    uint256 public _agreementCount; 
    address private _ownerAddr; //owner address
    event Stake(address account, uint256 amount, uint256 amountSoFar);
    event Withdraw(address account, uint256 amount, uint256 amountRemaining);

    constructor(address _stakingToken)
        ReentrancyGuard()
    {
        stakingToken = IERC20(_stakingToken); //initialization of ERC20 stakingToken    
        _ownerAddr = msg.sender; //set owner 
        _agreementCount = 0;  

          addAgreement( 
                      "init05", //code
                       17,  //0.017 daily = .05 per 30 days /% of regard in format of 100000  = 100%+3 decimals
                       0,   //no locked
                       0,
                       true   //minimun ammount  
                        );
          addAgreement( 
                      "init1",
                       34, // =0.034 daily = 1.2% month
                       30, // 30 days locked
                       0, //minimun ammount  
                       
                       true);              
          addAgreement( 
                      "init3",
                      100,  //0.1 daily 30%
                      90,  //days locked    
                      0, //Min amount 
                      true);
          addAgreement( 
                      "init6", 
                      234,  //0.234
                      180, //182 days locked
                      0,  //
                      true);
          addAgreement( 
                      "init12",
                      534, //0.534
                      365, //days locked
                      0,  //Min amount 
                      true
                      );          
    }
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        uint256 a = x / z;
        uint256 b = x % z; // x = a * z + b
        uint256 c = y / z;
        uint256 d = y % z; // y = c * z + d
        return a * b * z + a * d + b * c + (b * d) / z;
    }
   //agreement  
    function addAgreement(  
     string  memory code,    
     uint256 reward,
     uint256 time,
     uint256 minAmount,
     bool    active
       )public{
         require (msg.sender == _ownerAddr, "Just admin can access" );      
         if(_agreements[code].id == 0  ){
             _agreementCount += 1;
             _agreements[code].id         = _agreementCount;
             _agreements[code].reward     = reward;
             _agreements[code].active     = active; 
             _agreements[code].time       = time;
             _agreements[code].minAmount  = minAmount;   
             _agreementrelation[_agreementCount] =code;
         }else{
           _agreements[code].active     = active; 
         }

         //desactivation
    }
    function readAgreements(bool active) public view returns( string memory agreements){
          string memory time; 
          string memory id;      
          string memory reward;
          string memory minAmount;
          agreements = string (abi.encodePacked('{', '"', "agreements", '"',':', '['));   
            for (uint i = 1; i <= _agreementCount; i++ ){
               if( _agreements[_agreementrelation[i]].active == active){
                id = Strings.toString(i);
                reward = Strings.toString(_agreements[_agreementrelation[i]].reward );              
                time =  Strings.toString(_agreements[_agreementrelation[i]].time );
                minAmount = Strings.toString(_agreements[_agreementrelation[i]].minAmount ); 
                _agreementrelation[_agreementCount]; 
                   if(i ==  _agreementCount ){
                            agreements = string (abi.encodePacked(
                            agreements,'{','"', 
                              "code",'"',':', '"',_agreementrelation[i],'"',',','"',
                              "id",'"',':', '"', id,'"',',','"',
                              "reward",'"',':', '"', reward ,'"',',','"',
                              "time",'"',':', '"' ,time,'"' , 
                              "minAmount",'"',':', '"' ,minAmount,'"' ,                          
                            '}' )); 
                    } else{ 
                            agreements = string (abi.encodePacked(
                           agreements,'{','"', 
                            "code",'"',':', '"',_agreementrelation[i],'"',',','"',
                            "id",'"',':', '"', id,'"',',','"',
                            "reward",'"',':', '"', reward ,'"',',','"',
                            "time",'"',':', '"' ,time,'"' , 
                            "minAmount",'"',':', '"' ,minAmount,'"' ,                        
                            '}',',' ));                
                     }
             

               }

            } 
           agreements = string (abi.encodePacked(agreements,']','}'));
    } 
 

  //stake
   function stake(uint256 _amount,string memory _code) external {
         //require(staking == token);
      
		    require(_agreements[_code].active == true,"Agreement not active");
        _totalSupply += _amount; // Update the value of old token in pool
       _balances[msg.sender] += _amount; // Add amount to user that can be disposed in a future
        _statistics[_agreements[_code].id] += _amount;    //statistics by agreement   
        _wallet[msg.sender][_userSlot[msg.sender]].amount = _amount;
         _wallet[msg.sender][_userSlot[msg.sender]].code = _code;
         _wallet[msg.sender][_userSlot[msg.sender]].signedDate = block.timestamp;
         _wallet[msg.sender][_userSlot[msg.sender]].claimed = false;
         _userSlot[msg.sender] += 1;
        stakingToken.transferFrom(msg.sender, address(this), _amount); //get token 
        // rewards[msg.sender] = earned(msg.sender);
       
    }
    function withdraw(uint256 slot) external nonReentrant {
           
             uint256 rewardDate = _wallet[msg.sender][slot].signedDate;
              if (_agreements[_wallet[msg.sender][slot].code].time > 0){
                 rewardDate += _agreements[_wallet[msg.sender][slot].code].time * 1 days;
               }else{
                 rewardDate = _wallet[msg.sender][slot].signedDate;
               }
                  
            require( _wallet[msg.sender][slot].claimed == false, "Already claimed");
            require(block.timestamp > rewardDate, "Rewards still locked");   
            uint256 amount =_wallet[msg.sender][slot].amount;

             //get days for reward
              uint256 rewardDays = block.timestamp - _wallet[msg.sender][slot].signedDate ;
             //convert secons in days 
              rewardDays = rewardDays / 1 days;
            //get reward %      
            uint256 percent =_agreements[_wallet[msg.sender][slot].code].reward * rewardDays;
            //get rewards % in tokens
            uint256 reward = mulDiv(percent,amount , 100000) ;                              
            //add reward to amount
             reward =  reward + amount;
            bool sent = stakingToken.transfer(msg.sender, reward);
            require(sent, "rewardsToken transfer failed"); //validate if transfer fail
            //change status to claimed
            _wallet[msg.sender][slot].claimed = true;
            _totalSupply -= amount; // rest the amount transfered 
            _balances[msg.sender] -= amount; //rest from user balance
           _statistics[_agreements[_wallet[msg.sender][slot].code].id] -= amount;
            emit Withdraw(msg.sender, reward, _balances[msg.sender]); //commit tranction            
                   
     }
    
     function getWallet(address account)public view returns( string memory wallet, address raccount ){
  
               uint256 rewardDate = 0;   
               string memory amount;
               string memory rewarDstr;
               string memory signedDstr;
               wallet = "User not allowed";
              raccount = account;
        
              rewardDate = 0; 
               wallet = string (abi.encodePacked('{', '"', "wallet", '"',':', '['));                        
               for (uint i = 0; i < _userSlot[msg.sender]; i++ ){
                   if(_wallet[account][i].claimed == false ){
                       rewardDate = _wallet[msg.sender][i].signedDate;
                       if(_agreements[_wallet[msg.sender][i].code].time > 0 ){
                         rewardDate += _agreements[_wallet[msg.sender][i].code].time * 1 days;
                       }
                           amount     = Strings.toString( _wallet[account][i].amount );
                        rewarDstr  = Strings.toString( rewardDate);
                        signedDstr = Strings.toString( _wallet[account][i].signedDate);
                     if(i ==  _userSlot[msg.sender] -1 ){
                            wallet = string (abi.encodePacked(
                            wallet,'{','"', 
                              "code",'"',':', '"',_wallet[account][i].code,'"',',','"',
                              "cantidad",'"',':', '"', amount ,'"',',','"',
                              "signed",'"',':', '"', signedDstr,'"',',','"',
                              "rewardD",'"',':', '"' ,rewarDstr,'"' ,                        
                            '}' )); 
                    } else{ 
                            wallet = string (abi.encodePacked(
                            wallet,'{','"', 
                            "code",'"',':', '"',_wallet[account][i].code,'"',',','"',
                            "cantidad",'"',':', '"', amount,'"',',','"',
                            "signed",'"',':', '"', signedDstr,'"',',','"',
                            "rewardD",'"',':', '"' ,rewarDstr,'"' ,                        
                            '}',',' ));                
                     }
                   }
               }   
              wallet = string (abi.encodePacked(wallet,']','}'));          
             
     }
  function viewStcs(string memory _code)public view returns( string memory wallet){
            if(msg.sender == _ownerAddr ){
            string memory quantt= Strings.toString( _statistics[_agreements[_code].id]);
               wallet = string (abi.encodePacked('{', '"', "wallet", '"',':', '['));
                    wallet = string (abi.encodePacked(
                            wallet,'{','"', 
                            "code",'"',':', '"',_code,'"',',','"',
                            "cantidad",'"',':', '"',quantt ,'"',',','"',                          
                            '}' ));                                    
              wallet = string (abi.encodePacked(wallet,']','}'));               
             }
     }
    function ownerWithdraw(uint256 _amount) external nonReentrant {
        require(msg.sender == _ownerAddr, "You can withdraw.");
        bool sent = stakingToken.transfer(msg.sender, _amount);
        _totalSupply -= _amount;
        require(sent, " transfer failed"); //validate if transfer fail      
    } 

    function getTIme()public view returns(uint256 timestamp){
            timestamp = block.timestamp;
    }
}