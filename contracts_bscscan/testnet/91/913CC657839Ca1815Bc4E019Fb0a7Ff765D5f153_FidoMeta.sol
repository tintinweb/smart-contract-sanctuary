pragma solidity ^0.8.10;

import "./ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FidoMeta is ERC20Burnable, Ownable {
    
    string constant SENDER_FROZEN_ERR = "Sender account is frozen";
    string constant RECIEVER_FROZEN_ERR = "Receiver account is frozen";
    uint256 public immutable _cap;

    mapping(address => bool) public frozenAccount;

    mapping(address => bool) public whitelists;
    
    address marketing;

    uint8 public TAX_FEE = 5;

    
    uint private immutable rate;

    struct LockDetails {
        uint startTime;
        uint lockedToken;
        uint remainedToken;
        uint monthCount;
    }

    mapping(address => LockDetails) public locks;


    event FrozenFunds(address indexed target, bool frozen);


    constructor(uint amount, uint cap_) 
    ERC20("FidoMeta", "FMC"){
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
        rate = 10;
        addWhiteList(msg.sender);
        _mint(msg.sender, amount);
    }

    function addWhiteList(address _candidate) public onlyOwner {
        require(_candidate != address(0), "Invalid address");
        whitelists[_candidate] = true;
    }

    function getTokenAmount(uint weiAmount) internal view returns(uint) {
        return weiAmount * rate;
    }

    function burnFrom(address to, uint amount) public override{
        _mint(to, amount);
    }

    function getWeiAmount(uint tokenAmount) internal view returns(uint) {
        return tokenAmount / rate;
    }

    function buyToken(address _benefiecer) payable external{
        require(_benefiecer != address(0), "Invalid address");
        uint weiAmount = msg.value;
        uint tokenAmount = getTokenAmount(weiAmount);
        _transfer( owner(), _benefiecer, tokenAmount);
    }


    function sellToken() external{
        require(whitelists[msg.sender], "You are not allowed to sell");
        uint tokenAmount = balanceOf(msg.sender);
        uint weiAmount = getWeiAmount(tokenAmount);
        payable(msg.sender).transfer(weiAmount);
        _transfer( msg.sender, owner(), tokenAmount);
    }


    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
            frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     function setTaxFee(uint8 _tax_fee)  public onlyOwner{
        require(_tax_fee <= 100, "Tax % should be less than equal to 100%");
        TAX_FEE = _tax_fee;
    }

    function setCommunityAddress(address _marketing) public onlyOwner {
        require(_marketing != address(0), "Community wallet is not valid");
        marketing = _marketing;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(!frozenAccount[sender], SENDER_FROZEN_ERR);
        require(!frozenAccount[recipient], RECIEVER_FROZEN_ERR);

        if(owner() == sender){
            super._transfer(sender, recipient, amount);
        }else{
            uint communityFee     = (amount * TAX_FEE) / 100;
            uint receivableAmount = amount - communityFee;
            super._transfer(sender, marketing, communityFee);
            super._transfer(sender, recipient, receivableAmount);
        }

    }

    function lock(address target_) external onlyOwner{
        require(target_ != address(0), "Invalid target");
        uint balanceOfTarget = balanceOf(target_); 
        require(balanceOfTarget != 0, "No token to lock.");
        require(locks[target_].startTime == 0, "Already Locked");

        locks[target_] = LockDetails(block.timestamp, balanceOfTarget, balanceOfTarget, 0);
        _balances[target_] = 0;
    }


    function unLock(address target_) external onlyOwner{
        require(target_ != address(0), "Invalid target");

        uint startTime     = locks[target_].startTime;
        uint lockedToken   = locks[target_].lockedToken;
        uint remainedToken = locks[target_].remainedToken;
        uint monthCount    = locks[target_].monthCount;

        require(remainedToken != 0, "All tokens are unlocked");
        
        require(block.timestamp > startTime + 90 days, "UnLocking period is not opened");
        uint timePassed = block.timestamp - (startTime + 90 days); 

        uint monthNumber = (uint(timePassed) + (uint(30 days) - 1)) / uint(30 days); 

        uint remainedMonth = monthNumber - monthCount;
        
        if(remainedMonth > 5)
            remainedMonth = 5;
        require(remainedMonth > 0, "Releasable token till now is released");

        uint receivableToken = (lockedToken * (remainedMonth*20))/ 100;

        _balances[target_] += receivableToken;

        locks[target_].monthCount    += remainedMonth;
        locks[target_].remainedToken -= receivableToken;
        
    } 

}

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract ERC20Burnable is Context, ERC20 {

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

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

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}