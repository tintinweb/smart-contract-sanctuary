// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WWWToken is Ownable {
    mapping(address => uint256) private balances;
    
    mapping(address => mapping(address => uint256)) private _allowances;
    
    string private name;
    string private symbol;
    
    uint256 private totalSupply;
    
    bool private paused;
    event Paused(address _account);
    event Unpaused(address _account);
    
    // constructor(string memory _name, string memory _symbol) {
    //     name = _name;
    //     symbol = _symbol;
    //     paused = false;
    // }
    constructor() {
        name = "WWWToken";
        symbol = "WWW";
        paused = false;
    }
    
    modifier whenNotPaused() {
        require(!getPaused(), "Pausable: not paused" );
        _;
    }
    
    function getName() public view virtual whenNotPaused() returns (string memory) {
        return name;
    }
    function getSymbol() public view virtual whenNotPaused() returns (string memory) {
        return symbol;
    }
    function getTotalSupply() public view virtual whenNotPaused() returns (uint256) {
        return totalSupply;
    }
    function getPaused() public view virtual returns(bool) {
        return paused;
    }
    function decimals() public view virtual whenNotPaused() returns (uint8) {
        return 9;
    }
    function balanceOf(address account) public view virtual whenNotPaused() returns(uint256) {
        return balances[account];
    }
    function transfer(address _recipient, uint256 _amount) public virtual onlyOwner() whenNotPaused() returns (bool) {
        _transfer(msg.sender,_recipient,_amount);
        return true;
    }
    function transferFrom(address _sender,address _recipient, uint256 _amount) public virtual whenNotPaused() returns (bool) {
        _transfer(_sender,_recipient,_amount);
        uint256 currentAllowance = _allowances[_sender][msg.sender];
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(_sender,msg.sender, currentAllowance - _amount);
        }
        return true;
    }
    function approve(address _spender, uint256 _amount) public virtual whenNotPaused() returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }   
    function allowance(address _owner, address _spender) public virtual whenNotPaused() view returns (uint256) {
        return _allowances[_owner][_spender];
    }
    function burn(uint256 _amount) public virtual whenNotPaused() returns (bool) {
        _burn(msg.sender,_amount);
        return true;    
    }
    function mint(address _account, uint256 _amount) public virtual onlyOwner() whenNotPaused() returns(bool) {
        _mint(_account,_amount);
        return true;
    }
    function pause() public virtual onlyOwner() whenNotPaused() {
        paused = true;
        emit Paused(_msgSender());
    }
    function unpause() public virtual onlyOwner()  {
        require(getPaused(), "Pausable: not paused");
        paused = false;
        emit Unpaused(_msgSender());
    }
    
    
    
    function _transfer(address _sender, address _recipient, uint256 _amount) internal virtual {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = balances[_sender];
        require(senderBalance >= _amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            balances[_sender] = senderBalance - _amount;
        }
        balances[_recipient] += _amount;
    }
    function _mint(address _account, uint256 _amount) internal virtual onlyOwner() {
        require(_account != address(0), "ERC20: mint to the zero address");
        require(totalSupply + _amount <= 10**decimals(), "Maximum number of tokens");
        totalSupply += _amount;
        balances[_account] +=_amount;
    }
    function _burn(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = balances[_account];
        require(accountBalance >= _amount, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[_account] = accountBalance - _amount;
        }
        totalSupply -= _amount;
    }
    function _approve(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][_spender] = _amount;
        
    }
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}