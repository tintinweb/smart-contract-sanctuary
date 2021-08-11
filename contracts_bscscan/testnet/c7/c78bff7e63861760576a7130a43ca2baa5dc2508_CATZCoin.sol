/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a98814b930910220d5b5ba25ed2d4dcf45e48315/contracts/utils/Context.sol

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a98814b930910220d5b5ba25ed2d4dcf45e48315/contracts/token/ERC20/IERC20.sol

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


// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a98814b930910220d5b5ba25ed2d4dcf45e48315/contracts/token/ERC20/extensions/IERC20Metadata.sol

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


// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a98814b930910220d5b5ba25ed2d4dcf45e48315/contracts/token/ERC20/ERC20.sol

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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

    string private _name = "CatzCoin";
    string private _symbol = "CATZ";

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */

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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
}


// File: catzCoin.sol

contract CATZCoin is ERC20 {
    
    constructor ()  ERC20() {
      // Set Contract's State
      _totalSupply = 100000000000 * (10 ** uint256(decimals()));
      _tokenMarketingAddress = 0xA1F7258EfcaF8EFb8D70EC14fa9F862eA5D7217a;
      _tokenExchangeAddress = 0x6520a4bEB513B96f9b2081874BC777229AeA0A5b;
      _catzCoinCreationTime = block.timestamp;
      _teamAddresses = [0xD1257dd8e2b87338f1618BF04Bba37a1C477cC78, 0x05196A0001B5552C7bC3e1f34EeA5255d1519d93, 0x3343b8C53676EbF357830910f233304BF60a0ce9, 0xB7332A228329896a3B286b8670880A3cA313094d];

      _mint(address(this), _totalSupply);
      
      // Liquidity Allocation
      exchangeLiquidity = (balanceOf(address(this)) * 40) / 100;
      airDropLiquidity = (balanceOf(address(this)) * 15) / 100;
      marketingLiquidity = (balanceOf(address(this)) * 5) / 100;
      burnLiquidity = (balanceOf(address(this)) * 20) / 100;
      teamDevLiquidity = (balanceOf(address(this)) * 20) / 100;
      
      //Vest EndTimes
      uint256 _secondsInAMonth = 2628288;
      firstVestEndTime = block.timestamp + (_secondsInAMonth * 3);
      secondVestEndTime = block.timestamp + (_secondsInAMonth * 6);
      thirdVestEndTime = block.timestamp + (_secondsInAMonth * 9);
      fourthVestEndTime = block.timestamp + (_secondsInAMonth * 12);
      
      //Burn EndTimes
      firstBurnTime = block.timestamp + (_secondsInAMonth * 6);
      secondBurnTime = block.timestamp + (_secondsInAMonth * 12);
      thirdBurnTime = block.timestamp + (_secondsInAMonth * 18);
      fourthBurnTime = block.timestamp + (_secondsInAMonth * 24);
      
      //initate liquidity
      _initateDevLiquidity();
      _initiateExchangeLiquidity();
    }
    
    //ERC20 State
    address _tokenMarketingAddress;
    address _tokenExchangeAddress;
    uint256 _totalSupply;
    uint256 _catzCoinCreationTime;
    address[] _teamAddresses;
    
    //Token Allocation
    uint256 exchangeLiquidity;
    uint256 airDropLiquidity;
    uint256 marketingLiquidity;
    uint256 burnLiquidity;
    uint256 teamDevLiquidity;
    
    //burn Mechanism
    uint256 firstBurnTime;
    uint256 secondBurnTime;
    uint256 thirdBurnTime;
    uint256 fourthBurnTime;
    uint256 tokensBurnt;
    bool firstBurnCompleted;
    bool secondBurnCompleted;
    bool thirdBurnCompleted;
    bool fourthBurnCompleted;
    
    //vest Mechanism
    uint256 firstVestEndTime;
    uint256 secondVestEndTime;
    uint256 thirdVestEndTime;
    uint256 fourthVestEndTime;
    uint256 tokensDistributed;
    bool initDevBalCompleted;
    bool firstVestCompleted;
    bool secondVestCompleted;
    bool thirdVestCompleted;
    bool fourthVestCompleted;
      
    
    function _initateDevLiquidity () private {
        uint256 _teamDevLiquidityForInitiate = (teamDevLiquidity * 50) / 100;
        uint256 _tokenDevSplit = _teamDevLiquidityForInitiate / _teamAddresses.length;
        for (uint i; i < _teamAddresses.length; i++) {
            _transfer(address(this), _teamAddresses[i], _tokenDevSplit);
            teamDevLiquidity -= _tokenDevSplit;
        }
    }
    function _initiateExchangeLiquidity () private {
        _transfer(address(this), _tokenExchangeAddress, exchangeLiquidity);
    }
    function useMarketingFunds (address[] memory addressesReceiving, uint256[] memory amounts) public {
        require (msg.sender == _tokenMarketingAddress, "You must be the marketing Manager");
        require (addressesReceiving.length == amounts.length, "Arrays must be equal in length");
        uint256 _totalAmount;
        for (uint i; i < addressesReceiving.length; i++) {
            _totalAmount += amounts[i];
        } 
        require (_totalAmount <= marketingLiquidity, "insufficient Balance");
        marketingLiquidity -= _totalAmount;
        for (uint i; i < addressesReceiving.length; i++) {
            _transfer(address(this), addressesReceiving[i], amounts[i]);
        }
    }
    function airDropCatz (address[] memory addressesReceiving, uint256[] memory amounts) public {
        require (msg.sender == _tokenMarketingAddress, "You must be the marketing Manager");
        require (addressesReceiving.length == amounts.length, "Arrays must be equal in length");
        uint256 _totalAmount;
        for (uint i; i < addressesReceiving.length; i++) {
            _totalAmount += amounts[i];
        } 
        require (_totalAmount <= airDropLiquidity, "insufficient Balance");
        airDropLiquidity -= _totalAmount;
        for (uint i; i < addressesReceiving.length; i++) {
            _transfer(address(this), addressesReceiving[i], amounts[i]);
        }
    }
    function releaseVesting () public {
        require(fourthVestCompleted != true, "All Vesting has been distributed");
        uint256 _teamDevCheckpoint = (teamDevLiquidity * 25) / 100;
        uint256 _tokenDevSplit = _teamDevCheckpoint / _teamAddresses.length;
        //Vest 1
        if (block.timestamp >= firstVestEndTime && firstVestCompleted != true) {
            for (uint i; i < _teamAddresses.length; i++) {
                _transfer(address(this), _teamAddresses[i], _tokenDevSplit);
                tokensDistributed += _tokenDevSplit;
            }
            firstVestCompleted = true;
            
        //Vest 2
        }else if (block.timestamp >= secondVestEndTime && secondVestCompleted != true) {
            for (uint i; i < _teamAddresses.length; i++) {
                _transfer(address(this), _teamAddresses[i], _tokenDevSplit);
                tokensDistributed += _tokenDevSplit;
            }
            secondVestCompleted = true;
            
        //Vest 3
        }else if (block.timestamp >= thirdVestEndTime && thirdVestCompleted != true) {
            for (uint i; i < _teamAddresses.length; i++) {
                _transfer(address(this), _teamAddresses[i], _tokenDevSplit);
                tokensDistributed += _tokenDevSplit;
            }
            thirdVestCompleted = true;
            
        //Vest 4
        }else if (block.timestamp >= fourthVestEndTime && fourthVestCompleted != true) {
            for (uint i; i < _teamAddresses.length; i++) {
                _transfer(address(this), _teamAddresses[i], _tokenDevSplit);
                tokensDistributed += _tokenDevSplit;
            }
            fourthVestCompleted = true;
        }
    }
    function burnCatzCoin () public {
        require(fourthBurnCompleted != true, "All allocated tokens to be burned have been burned");
        uint256 _liquidityToBurn = (burnLiquidity * 25) / 100;
        //burn 1
        if (block.timestamp >= firstBurnTime && firstBurnCompleted != true) {
            _burn(address(this), _liquidityToBurn);
            firstBurnCompleted = true;
            tokensBurnt += _liquidityToBurn;
            
        //burn 2
        }else if (block.timestamp >= secondBurnTime && secondBurnCompleted != true) {
            _burn(address(this), _liquidityToBurn);
            secondBurnCompleted = true;
            tokensBurnt += _liquidityToBurn;
            
        //burn 3
        }else if (block.timestamp >= thirdBurnTime && thirdBurnCompleted != true) {
            _burn(address(this), _liquidityToBurn);
            thirdBurnCompleted = true;
            tokensBurnt += _liquidityToBurn;
            
        //burn 4
        }else if (block.timestamp >= fourthBurnTime && fourthBurnCompleted != true) {
            _burn(address(this), _liquidityToBurn);
            fourthBurnCompleted = true;
            tokensBurnt += _liquidityToBurn;
        }
    }
    function getTimeBeforeNextVest () public view returns(uint256 timeBeforeVest) {
        if (firstVestCompleted != true && secondVestCompleted != true && thirdVestCompleted != true && fourthVestCompleted != true) {
            return firstVestEndTime - block.timestamp;
            
        //burn 2
        }else if (firstVestCompleted == true && secondVestCompleted != true && thirdVestCompleted != true && fourthVestCompleted != true) {
            return secondVestEndTime - block.timestamp;
            
        //burn 3
        }else if ( secondVestCompleted == true && thirdVestCompleted != true && fourthVestCompleted != true) {
            return thirdVestEndTime - block.timestamp;
            
        //burn 4
        }else if ( thirdVestCompleted == true && fourthVestCompleted != true) {
            return fourthVestEndTime - block.timestamp;
        } else {
            return 0;
        }
    }
    function getTimeBeforeNextBurn () public view returns(uint256 timeBeforeBurn) {
        if (firstBurnCompleted != true && secondBurnCompleted != true && thirdBurnCompleted != true && fourthBurnCompleted != true) {
            return firstBurnTime - block.timestamp;
            
        //burn 2
        }else if (firstBurnCompleted == true && secondBurnCompleted != true && thirdBurnCompleted != true && fourthBurnCompleted != true) {
            return secondBurnTime - block.timestamp;
            
        //burn 3
        }else if (secondBurnCompleted == true && thirdBurnCompleted != true && fourthBurnCompleted != true) {
            return thirdBurnTime - block.timestamp;
            
        //burn 4
        }else if (thirdBurnCompleted == true && fourthBurnCompleted != true) {
            return fourthBurnTime - block.timestamp;
        }else {
            return 0;
        }
    }
        
    function getAirDropLiquidity () public view returns(uint256) {
        return airDropLiquidity;
    }
    function getMarketingLiquidity () public view returns(uint256) {
        return marketingLiquidity;
    }
    function getBurnLiquidity () public view returns(uint256) {
        return burnLiquidity - tokensBurnt;
    }
    function getTeamDevLiquidity () public view returns(uint256) {
        return teamDevLiquidity - tokensDistributed;
    }
}