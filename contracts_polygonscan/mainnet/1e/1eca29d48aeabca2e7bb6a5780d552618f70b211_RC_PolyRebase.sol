/**
 *Submitted for verification at polygonscan.com on 2021-07-10
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

    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);

    constructor() {
        address msgSender = _msgSender();
        _admin = msgSender;
        emit NewAdmin(address(0), msgSender);
    }

    /**
     * @dev modifier for admin only functions.
     */
    modifier onlyAdmin() {
        require(admin() == _msgSender(), "Controllers: admin only!");
        _;
    }

    /**
     * @dev modifier for owner or admin only functions.
     */
    modifier onlyControllers() {
        require((owner() == _msgSender()) || (admin() == _msgSender()), "Controllers: controller only!");
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
        require(_newAdmin != address(0), "Controllers: admin can not be zero address");
        emit NewAdmin(_admin, _newAdmin);
        _admin = _newAdmin;
    }
}


/**
 * @title PolyRebase (Release Candidate)
 * @dev Platform token conforming to EIP-20(ERC-20 Token Standard).
 * PolyRebase is an elastic supply token pegged to USDC stablecoin, utilizing TWAP oracle controlled supply adjustments to
 * maintain target peg.
 *
 * PolyRebase elasticity is achieved by implementing Vernier Caliper MAIN & AUXILIARY scales topology where supply is basically
 * defining the units of measure on AUXILIARY scale, balances are essentially % of total Caliper size in supply units, hence 
 * adjusting supply results in balance variance with equal proportions while balance to supply ratio remains unchanged.  
 *
 * PolyRebase protocol supply is capped @ 340,282,366,920,938,463,463.374607431768211454, i.e. uint128 max value in 18 decimals.
 *
 * This implementation stands in inline with AMPLFORTH elastic supply, the "gold-standard" for elastic supply adjustments.
 *
 * Built using openzeppelin libraries, for details see https://docs.openzeppelin.com/
 */
contract RC_PolyRebase is Controllers {

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    uint256 private constant DECIMALS = 18;
    uint256 private constant INITIAL_SUPPLY = 10 * 10**6 * 10**DECIMALS;
    uint256 private constant MAXIMUM_SUPPLY = type(uint128).max - 1;
    
    uint256 private MAIN_SCALE = type(uint256).max - (type(uint256).max % INITIAL_SUPPLY);
    uint256 private AUX_SCALE = MAIN_SCALE / INITIAL_SUPPLY;

    bool private _paused;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Rebase(uint256 indexed timestamp, uint256 indexed totalSupply, uint256 beforeRebase);

    constructor() {
        _name = "RC_PolyRebase";
        _symbol = "rc2PR";
        _paused = false;
        _mint(_msgSender(), MAIN_SCALE);
    }

    /**
     * @dev modifier for blocking invalid transfer recipients.
     */
    modifier validRecipient(address recipient) {
        require((recipient != address(0)) || (recipient != address(this)), "PolyRebase: invalid recipient!");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return uint8(DECIMALS);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return (_balances[account] / AUX_SCALE);
    }

    function transfer(address recipient, uint256 amount) external validRecipient(recipient) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public validRecipient(recipient) returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "PolyRebase: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - (amount * AUX_SCALE));

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "PolyRebase: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "PolyRebase: transfer from the zero address");
        require(recipient != address(0), "PolyRebase: transfer to the zero address");
        require(!paused(), "PolyRebase: transfer paused");

        uint256 _amount = amount * AUX_SCALE;
        uint256 _balance = _balances[sender];
        require(_balance >= _amount, "PolyRebase: transfer amount exceeds balance");
        _balances[sender] = _balance - _amount;
        _balances[recipient] += _amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "PolyRebase: mint to the zero address");

        _totalSupply += (MAIN_SCALE / AUX_SCALE);
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "PolyRebase: approve from the zero address");
        require(spender != address(0), "PolyRebase: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

     function rebase(uint256 shift, uint8 shiftDecimals) external onlyControllers returns (uint256) {
        uint256 _beforeRebase = _totalSupply;
        _totalSupply = (_totalSupply * shift / 10**shiftDecimals);

        if (_totalSupply > MAXIMUM_SUPPLY) {
            _totalSupply = MAXIMUM_SUPPLY;
        }

        AUX_SCALE = MAIN_SCALE / (_totalSupply);

        emit Rebase(block.timestamp, _totalSupply, _beforeRebase);

        return _totalSupply;
    }
    
   function pause(bool set) external onlyControllers {
        _paused = set;
    }

    function paused() public view returns (bool) {
        return _paused;
    }
}