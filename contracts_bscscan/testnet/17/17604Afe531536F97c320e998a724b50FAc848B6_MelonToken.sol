/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-13
*/

pragma solidity ^0.5.0;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/*
 * @dev provides information about the current execution context, including the
 * sender of the transaction and its data. while these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with gsn meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * this contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * this module is used through inheritance. it will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "ownable: meloncaller is not the owner");
        _;
    }

    /**
     * @dev returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev leaves the contract without owner. it will not be possible to call
     * `onlyOwner` functions anymore. can only be called by the current owner.
     *
     * note: renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev transfers ownership of the contract to a new account (`newOwner`).
     * can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "ownable: new melonowner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title roles
 * @dev library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "melon mint: caller does not have minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract CanTransferRole is Context {
    using Roles for Roles.Role;

    event CanTransferAdded(address indexed account);
    event CanTransferRemoved(address indexed account);

    Roles.Role private _canTransfer;

    constructor () internal {
        _addCanTransfer(_msgSender());
    }

    modifier onlyCanTransfer() {
        require(canTransfer(_msgSender()), "cant: melon caller is not can transfer");
        _;
    }

    function canTransfer(address account) public view returns (bool) {
        return _canTransfer.has(account);
    }

    function addCanTransfer(address account) public onlyCanTransfer {
        _addCanTransfer(account);
    }

    function renounceCanTransfer() public {
        _removeCanTransfer(_msgSender());
    }

    function _addCanTransfer(address account) internal {
        _canTransfer.add(account);
        emit CanTransferAdded(account);
    }

    function _removeCanTransfer(address account) internal {
        _canTransfer.remove(account);
        emit CanTransferRemoved(account);
    }
}


contract MelonToken is Ownable, MinterRole, CanTransferRole {
    using SafeMath for uint256;
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping (address => uint256) private _balances;

    uint256 private _totalSupply;
    uint256 private _totalClaimed;
    string public name = "Melon";
    string public symbol = "Melon";
    uint8 public decimals = 18;

    /**
     * @dev total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // returns the total claimed melon
    // this is just purely used to display the total melon claimed by users on the frontend
    function totalClaimed() public view returns (uint256) {
        return _totalClaimed;
    }

    // add melon claimed
    function addClaimed(uint256 _amount) public onlyCanTransfer {
        _totalClaimed = _totalClaimed.add(_amount);
    }

    // set melon claimed to a custom value, for if we wanna reset the counter anytime
    function setClaimed(uint256 _amount) public onlyCanTransfer {
        require(_amount >= 0, "no cant be negative");
        _totalClaimed = _amount;
    }

    // as this token is non tradable, only minters are allowed to transfer tokens between accounts
    function transfer(address receiver, uint numTokens) public onlyCanTransfer returns (bool) {
        require(numTokens <= _balances[msg.sender]);
        _balances[msg.sender] = _balances[msg.sender].sub(numTokens);
        _balances[receiver] = _balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    // as this token is non tradable, only minters are allowed to transfer tokens between accounts
    function transferFrom(address owner, address buyer, uint numTokens) public onlyCanTransfer returns (bool) {
        require(numTokens <= _balances[owner]);

        _balances[owner] = _balances[owner].sub(numTokens);
        _balances[buyer] = _balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    /**
     * @dev gets the balance of the specified address.
     * @param owner the address to query the balance of.
     * @return a uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }

    function burn(address _account, uint256 value) public onlyCanTransfer {
        require(_balances[_account] >= value, "cant burn more than address has");
        _burn(_account, value);
    }

    /**
     * @dev internal function that mints an amount of the token and assigns it to
     * an account. this encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account the account that will receive the created tokens.
     * @param value the amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0), "melonbep20: mint to the zero address");

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "melonbep20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
}