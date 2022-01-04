// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../../openzeppelin-contracts-master/contracts/token/ERC20/IERC20.sol";
import "../../../openzeppelin-contracts-master/contracts/utils/Context.sol";
import "../../../openzeppelin-contracts-master/contracts/token/ERC20/extensions/IERC20Metadata.sol";


contract Snowball is IERC20, Context, IERC20Metadata {

    string private _name;
    string private _symbol;


    address private owner;


    uint256 private _totalSupply;


    mapping(address => uint) private balancesOfAccounts;
    mapping(address => mapping(address => uint256)) private _allowances;


    constructor(
        string memory name_,
        string memory symbol_
    ){
        owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 0;
    }


    function burn(address account, uint256 amount) external  virtual {
        _burn(account, amount);
    }


    function mint(address account, uint256 amount) external  virtual {
        require(account == owner, "Only owner can mint");
        _mint(account, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "mint to zero address");

        //beforeTokenTransfer hook

        _totalSupply += amount;
        balancesOfAccounts[account] += amount;

        emit Transfer(address(0), account, amount);

        //afterTokenTransfer hook
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "burn from the zero address");

        //before token hook

        uint256 accountBalance = balancesOfAccounts[account];
        require(accountBalance >= amount, "burn amount bigger than amount");
             
        unchecked{
            balancesOfAccounts[account] = accountBalance - amount;
        }

        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
        //afterTokenTransfer hook
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 18;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) external view returns (uint256){
        return balancesOfAccounts[account];
    }


    function transfer(address recipient, uint256 amount) external returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true; 
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {

        require(sender != address(0), "error: approve from zero address");
        require(recipient != address(0), "error: approve to zero address");

        require(balancesOfAccounts[msg.sender] >= amount, "Sender haven't enough amount");
        //need hook beforeTokenTransfer

        uint256 senderBalance = balancesOfAccounts[sender];

    unchecked {
        balancesOfAccounts[sender] = senderBalance - amount;
    }

        balancesOfAccounts[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        //afterTokenHook
    }


    function allowance(address _owner, address spender) external view returns (uint256){
        return _allowances[_owner][spender];
    }


    function approve(address spender, uint256 amount) external returns (bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(_owner != address(0), "approve from zero address");
        require(spender != address(0), "approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool){
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "transfer amount exceeds allowance");

        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
    }
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];

        require(currentAllowance >= subtractedValue, "decreased allowance less than zero");

        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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