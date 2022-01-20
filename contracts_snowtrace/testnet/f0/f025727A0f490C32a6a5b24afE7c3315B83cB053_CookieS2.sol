/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-19
*/

// SPDX-License-Identifier: Unlicense

/* COOKIE GAME SEASON 2
https://cookie.game
https://twitter.com/cookiegamenft
https://discord.gg/hPGTmwqkvN
*/

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/s2/CookieS2.sol


pragma solidity ^0.8.4;

// Season 2 cookies are a purely in-game currency, so they are non-transferable.
// The contract is based on OpenZeppelin ERC20 and the ERC20 standard, but only provides
// a few ERC20 functions.

contract CookieS2 is Ownable {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    address public bakerAddress;
    address public bakeryAddress;
    address public exchangeAddress;
    address public pantryAddress;

    string public name = "Season 2 Cookie";
    string public symbol = "COOKIE";
    uint256 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function setAddresses(
        address _bakerAddress,
        address _bakeryAddress,
        address _exchangeAddress,
        address _pantryAddress
    ) external onlyOwner {
        bakerAddress = _bakerAddress;
        bakeryAddress = _bakeryAddress;
        exchangeAddress = _exchangeAddress;
        pantryAddress = _pantryAddress;
    }

    function mint(address _to, uint256 _amount) external {
        require(
            _msgSender() == bakeryAddress || _msgSender() == exchangeAddress,
            "Only the Bakery or Exchange contract can mint"
        );
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(
            _msgSender() == bakerAddress || _msgSender() == exchangeAddress,
            "Only the Baker or Exchange contract can burn"
        );
        _burn(_from, _amount);
    }

    function transfer(address _from, address _to, uint256 _amount) external {
        require(_msgSender() == pantryAddress, "Only the Pantry contract can transfer");
        require(
            _from == pantryAddress || _to == pantryAddress,
            "Transfers can only be to or from the pantry"
        );
        _transfer(_from, _to, _amount);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
}