/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    function decimals() external view returns (uint256);
}


library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


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
contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint256 decimals_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
    function decimals() public view virtual override returns (uint256) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}


contract BaseERC20Token is ERC20Burnable {



    /**
     * @dev Tokens can be moved only after if transfer enabled or if you are an approved operator.
     */
    

    /**
     * @param name Name of the token
     * @param symbol A symbol to be used as ticker
     * @param decimals Number of decimals. All the operations are done using the smallest and indivisible token unit
     * @param initialSupply Initial token supply
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 decimals,
        uint256 initialSupply
    ) public
        
        ERC20(name, symbol, decimals)
    {
        if (initialSupply > 0) {
            ERC20._mint(owner(), initialSupply);
        }
    }



    /**
     * @return if transfer is enabled or not.
     */
   

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public returns (bool) {
        return mint(to, value);
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transfer(address to, uint256 value) public override returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        return super.transferFrom(from, to, value);
    }




}

contract ERC20Token is BaseERC20Token {
    constructor (string memory name_, string memory symbol_, uint256 decimals_, uint256 initialSupply_)  BaseERC20Token(name_,symbol_,decimals_,initialSupply_*10**decimals_) public {
    }
}

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface I1inch {

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 minReturn, uint256[] calldata distribution, uint256 flags)
    external payable
    returns(uint256);
    
    function getExpectedReturn(IERC20 fromToken, IERC20 toToken, uint256 amount, uint256 parts, uint256 featureFlags) external
        view
        returns(
            uint256,
            uint256[] calldata
        );

    function makeGasDiscount(uint256 gasSpent, uint256 returnAmount, bytes calldata msgSenderCalldata) external;

}

interface IUni {

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external payable
    returns (uint[] memory amounts);
    
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) 
    external 
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function WETH() external pure returns (address);
}

abstract contract Router {

    // address payable owner;
    
    enum OrderType {EthForTokens, TokensForEth, TokensForTokens}

    // modifier onlyOwner {
    //     require(msg.sender == owner);
    //     _;
    // }

    // modifier onlyUser {
    //     require(validUser[msg.sender] == true);
    //     _;
    // }

    event Received(address, uint);
    event Error(address);

    receive() external payable {
        // if (validUser[msg.sender] == true) {
        //     balance[msg.sender][ETH] += msg.value;
        //     emit Received(msg.sender, msg.value);
        // } else {
        //     balance[owner][ETH] += msg.value;
        // }
    }

    fallback() external payable {
        revert();
    }

    I1inch OneSplit;
    IUni Uni;
    IUni Sushi;
    address ETH = address(0);
    constructor(address _oneSplit, address _Uni, address _sushi) public payable {
        // owner = payable(msg.sender);
        OneSplit = I1inch(_oneSplit);
        Uni = IUni(_Uni);
        Sushi = IUni(_sushi);
    }

    // function addUser(address _user) external onlyOwner {
    //     validUser[_user] = true;
    // }

    // function removeUser(address _user) external onlyOwner {
    //     validUser[_user] = false;
    // }
    
    function getBestQuote(address[] memory path, uint256 amountIn, OrderType orderType) public view returns (uint) {
        uint256 returnAmount;
        uint256[] memory uniAmounts;
        uint256[] memory sushiAmounts;
        if(orderType == OrderType.EthForTokens){
            path[0] = ETH;
            (returnAmount, ) = OneSplit.getExpectedReturn(IERC20(path[0]), IERC20(path[1]), amountIn, 100, 0);
            path[0] = Uni.WETH();
            (uniAmounts) = Uni.getAmountsOut(amountIn, path);
            (sushiAmounts) = Sushi.getAmountsOut(amountIn, path);
        } else if(orderType == OrderType.TokensForEth){
            path[1] = ETH;
            (returnAmount,) = OneSplit.getExpectedReturn(IERC20(path[0]), IERC20(path[1]), amountIn, 100, 0);
            path[1] = Uni.WETH();
            (uniAmounts) = Uni.getAmountsOut(amountIn, path);
            (sushiAmounts) = Sushi.getAmountsOut(amountIn, path);
        } else{
            (returnAmount,) = OneSplit.getExpectedReturn(IERC20(path[0]), IERC20(path[1]), amountIn, 100, 0);
            (uniAmounts) = Uni.getAmountsOut(amountIn, path);
            (sushiAmounts) = Sushi.getAmountsOut(amountIn, path);
        }
        
        
        
        if(returnAmount>uniAmounts[0]){
            if(returnAmount>sushiAmounts[0])
            {
                return(0);
            }else{
                return(2);
            }
        } else if(uniAmounts[0]>sushiAmounts[0]){
            return(1);
        } else {
            return(2);
        }
    }

    function swap(address _fromToken, address _toToken, uint256 amountIn, uint256 minReturn, uint256[] memory distribution, uint256 flags)
    internal {
        if (_fromToken == ETH) {
            try OneSplit.swap{value: amountIn}(IERC20(ETH), IERC20(_toToken), amountIn, minReturn, distribution, flags)
             returns (uint256 amountOut){
                 TransferHelper.safeTransferFrom(_toToken, address(this), msg.sender, amountOut);
            } catch {
                emit Error(msg.sender);
                revert();
            }
        } else {
             try OneSplit.swap(IERC20(_toToken), IERC20(ETH), amountIn, minReturn, distribution, flags)
              returns (uint256 amountOut){
                  if(_toToken == ETH){
                      msg.sender.transfer(amountOut);
                  } else {
                      TransferHelper.safeTransferFrom(_toToken, address(this), msg.sender, amountOut);
                  }
             } catch {
                emit Error(msg.sender);
                revert();
            }
        }
    }

    // function swapETHForTokens(address token, uint amountIn, uint amountOutMin) external payable onlyUser {
    //     require(balance[msg.sender][ETH] >= amountIn, 'Insufficient Balance');
    //     address[] memory path = new address[](2);
    //     path[0] = Uni.WETH();
    //     path[1] = token;

    //     try Uni.swapExactETHForTokens{ value: amountIn }(amountOutMin, path, address(this), block.timestamp)
    //     returns (uint[] memory amounts) {
    //         balance[msg.sender][ETH] -= amountIn;
    //         balance[msg.sender][token] += amounts[1];
    //     } catch {
    //         emit Error(msg.sender);
    //         revert();
    //      }
    // }

    // function swapTokensForETH(address token, uint amountIn, uint amountOutMin) external payable onlyUser {
    //     require(balance[msg.sender][token] >= amountIn, 'Insufficient Balance');
    //     require(IERC20(token).approve(address(Uni), amountIn), 'approve failed.');
    //     address[] memory path = new address[](2);
    //     path[0] = token;
    //     path[1] = Uni.WETH();
    //     try Uni.swapExactTokensForETH(amountIn, amountOutMin, path, address(this), block.timestamp)
    //     returns (uint[] memory amounts) {
    //         balance[msg.sender][token] -= amountIn;
    //         balance[msg.sender][ETH] += amounts[1];
    //     } catch {
    //         emit Error(msg.sender);
    //         revert();
    //     }
    // }

    // function removeEth() external payable {
    //     payable(msg.sender).transfer(address(this).balance);
    // }

    // function removeTokens(IERC20 _token) external payable {
    //     require(_token.approve(msg.sender, balance[msg.sender][address(_token)]), 'approve failed.');
    //     _token.transferFrom(address(this), msg.sender, balance[msg.sender][address(_token)]);
    // }

    // function drainETH() external payable {
    //     owner.transfer(address(this).balance);
    // }

    // function drainToken(IERC20 _token) external payable{
    //      require(_token.approve(msg.sender, _token.balanceOf(address(this))), 'approve failed.');
    //     _token.transferFrom(address(this), owner, _token.balanceOf(address(this)));
    // }

    // function getUserBalance(address user, address token) external view returns (uint256) {
    //     return balance[user][token];
    // }
}

contract Degen is Router, ERC20Token {
    using SafeMath for uint256;
    address _oneSplit = address(0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E);
    address _Uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address _sushi = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    I1inch OneSplitt = I1inch(_oneSplit);
    IUni Unii = IUni(_Uni);
    IUni Sushii = IUni(_sushi);
    
    constructor() Router(_oneSplit, _Uni, _sushi) ERC20Token("GasToken", "GASG", 18, 10000) public {
    }
    
    
    
    function executeSwap(OrderType orderType, address[] memory path, uint256 assetInOffered, uint256 fees) external payable{
        uint256 gasTokens = 0;
        uint256 gasA = gasleft();
        if(orderType == OrderType.EthForTokens){
            require(msg.value >= assetInOffered.add(fees), "Payment = assetInOffered + fees");
            gasTokens = gasTokens + msg.value - assetInOffered;
        } else {
            require(msg.value >= fees, "fees not received");
            gasTokens = gasTokens + msg.value;
            TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), assetInOffered);
        }
        
        uint dexId = getBestQuote(path, assetInOffered, orderType);
        if(dexId == 0){
            if(orderType == OrderType.EthForTokens) {
                 path[0] = ETH;
            }
            else if (orderType == OrderType.TokensForEth) {
                path[1] = ETH;
            }
            (uint256 returnAmount, uint256[] memory distribution) = OneSplit.getExpectedReturn(IERC20(path[0]), IERC20(path[1]), assetInOffered, 100, 0);
            swap(path[0], path[1], assetInOffered, returnAmount, distribution, 0);
        } else if(dexId == 1){
            if(orderType == OrderType.EthForTokens) {
                 path[0] = Uni.WETH();
            }
            else if (orderType == OrderType.TokensForEth) {
                path[1] = Uni.WETH();
            }
            (uint256[] memory uniAmounts) = Uni.getAmountsOut(assetInOffered, path);
            uint[] memory swapResult;
            if (orderType == OrderType.EthForTokens) {
                swapResult = Uni.swapExactETHForTokens{value:assetInOffered}(uniAmounts[0], path, msg.sender, block.timestamp);
            } 
            else if (orderType == OrderType.TokensForEth) {
                TransferHelper.safeApprove(path[0], address(_Uni), assetInOffered);
                swapResult = Uni.swapExactTokensForETH(assetInOffered, uniAmounts[0], path, msg.sender, block.timestamp);
            }
            else if (orderType == OrderType.TokensForTokens) {
                TransferHelper.safeApprove(path[0], address(_Uni), assetInOffered);
                swapResult = Uni.swapExactTokensForTokens(assetInOffered, uniAmounts[0], path, msg.sender, block.timestamp);
            }
        } else if(dexId == 2){
            if(orderType == OrderType.EthForTokens) {
                 path[0] = Sushii.WETH();
            }
            else if (orderType == OrderType.TokensForEth) {
                path[1] = Sushii.WETH();
            }
            (uint256[] memory sushiAmounts) = Sushii.getAmountsOut(assetInOffered, path);
            uint[] memory swapResult;
            if (orderType == OrderType.EthForTokens) {
                swapResult = Sushii.swapExactETHForTokens{value:assetInOffered}(sushiAmounts[0], path, msg.sender, block.timestamp);
            } 
            else if (orderType == OrderType.TokensForEth) {
                TransferHelper.safeApprove(path[0], address(_sushi), assetInOffered);
                swapResult = Sushii.swapExactTokensForETH(assetInOffered, sushiAmounts[0], path, msg.sender, block.timestamp);
            }
            else if (orderType == OrderType.TokensForTokens) {
                TransferHelper.safeApprove(path[0], address(_sushi), assetInOffered);
                swapResult = Sushii.swapExactTokensForTokens(assetInOffered, sushiAmounts[0], path, msg.sender, block.timestamp);
            }
        }
        
        uint256 gasB = gasleft();
        gasTokens = gasTokens + gasA - gasB;
        
        _mint(msg.sender, gasTokens);
    }











}