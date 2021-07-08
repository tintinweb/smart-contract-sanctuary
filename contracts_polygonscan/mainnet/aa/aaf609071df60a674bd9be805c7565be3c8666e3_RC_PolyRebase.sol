/**
 *Submitted for verification at polygonscan.com on 2021-07-08
*/

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
        this;
        return msg.data;
    }
}

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
    constructor () {
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


/**
 * @title Controllers
 * @dev admin only access restriction, extends OpenZeppelin Ownable.
 */
contract Controllers is Ownable{

    // Contract controllers
    address private _admin;

    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() {
        address msgSender = _msgSender();
        _admin = msgSender;
        emit NewAdmin(address(0), msgSender);
    }

    /**
     * @dev modifier for admin only functions.
     */
    modifier onlyAdmin() {
        require(admin() == _msgSender(), "admin only!");
        _;
    }

    /**
     * @dev modifier for owner or admin only functions.
     */
    modifier onlyControllers() {
        require((owner() == _msgSender()) || (admin() == _msgSender()), "controller only!");
        _;
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Assigns new admin.
     * @param _newAdmin address of new admin
     */
    function setAdmin(address _newAdmin) external onlyOwner {
        // Check for non 0 address
        require(_newAdmin != address(0), "admin can not be zero address");
        emit NewAdmin(_admin, _newAdmin);
        _admin = _newAdmin;
    }
}


/**
 * @title PolyRebase (Release Candidate)
 * @dev Platform token conforming to EIP-20(ERC-20 Token Standard).
 * PolyRebase is an elastic supply token pegged to stablecoin(TBD), utilizing TWAP oracle controlled supply adjustments
 * to maintain target peg.
 *
 * Built using openzeppelin libraries, for details see https://docs.openzeppelin.com/  
 */
contract RC_PolyRebase is Controllers {

    string private _name;
    string private _symbol;
    uint256 private _wrapper;
    uint256 private _totalSupply;

    bool private _paused;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address sender, address recipient, uint256 amount);
    event Approval(address owner, address spender, uint256 amount);
    event Rebase(uint256 totalSupply);
    event NewOracle(address newOracle);

    constructor() {
        _name = "RC_PolyRebase";
        _symbol = "rcPR";
        _wrapper = 10**decimals();
        _paused = false;
        _mint(_msgSender(), 10000000 * 10**decimals());
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return wrap(_totalSupply);
    }

    function balanceOf(address account) external view returns (uint256) {
        return wrap(_balances[account]);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return wrap(_allowances[owner][spender]);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = wrap(_allowances[sender][_msgSender()]);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, wrap(_allowances[_msgSender()][spender]) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = wrap(_allowances[_msgSender()][spender]);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!paused(), "ERC20: transfer paused");

        uint256 senderBalance = wrap(_balances[sender]);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = unwrap(senderBalance - amount);
        _balances[recipient] += unwrap(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = unwrap(amount);
        emit Approval(owner, spender, amount);
    }

    function wrap(uint256 amount) internal view returns (uint256) {
        return (amount * _wrapper / 10**decimals());        
    }

    function unwrap(uint256 amount) internal view returns (uint256) {
        return (amount * 10**decimals() / _wrapper);        
    }

    function wrapper() public view returns (uint256) {
        return _wrapper;
    }

    function setWrapper(uint factor) external onlyControllers {
        _wrapper = (_wrapper * factor / 10**decimals());

        emit Rebase(totalSupply());

    }

    function pause(bool set) external onlyControllers {
        _paused = set;
    }

    function paused() public view returns (bool) {
        return _paused;        
    }
}