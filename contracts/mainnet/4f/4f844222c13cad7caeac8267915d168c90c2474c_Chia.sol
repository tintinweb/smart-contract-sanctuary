/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity 0.5.10;

/**
 * Chia Network
 * Website: https://www.chia.net/
 * 
 * A new blockchain and smart transaction platform that is easier to use, more efficient, and secure
 * 
 * We believe that cryptocurrency should be easier to use than cash, harder to lose, and nearly impossible to steal 
 * Anyone who wants to validate transactions should be able to farm without single-use hardware or a big electricity bill
 * 
 * Chia Network develops a blockchain and smart transaction platform created by the inventor of BitTorrent, Bram Cohen 
 * It implements the first new Nakamoto consensus algorithm since Bitcoin in 2008. Proofs of Space and Time replace energy intensive “proofs of work”
 */
 
library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Caller is not the owner");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }


    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title MinterRole
 * @dev role for addresses who has permission to mint tokens.
 */
contract MinterRole is Ownable {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Caller has no permission");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return(_minters.has(account) || isOwner(account));
    }

    function addMinter(address account) public onlyOwner {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function removeMinter(address account) public onlyOwner {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

/**
 * @title HalterRole
 * @dev role for addresses who has permission to pause any token movement.
 */
contract HalterRole is Ownable {
    using Roles for Roles.Role;

    event HalterAdded(address indexed account);
    event HalterRemoved(address indexed account);

    Roles.Role private _halters;

    modifier onlyHalter() {
        require(isHalter(msg.sender), "Caller has no permission");
        _;
    }

    function isHalter(address account) public view returns (bool) {
        return(_halters.has(account) || isOwner(account));
    }

    function addHalter(address account) public onlyOwner {
        _halters.add(account);
        emit HalterAdded(account);
    }

    function removeHalter(address account) public onlyOwner {
        _halters.remove(account);
        emit HalterRemoved(account);
    }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * See https://eips.ethereum.org/EIPS/eip-20
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0));

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(amount));
    }

}

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for.
 */
contract ERC20Burnable is ERC20 {

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }

}

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 */
contract ERC20Mintable is ERC20Burnable, MinterRole {

    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

}

/**
 * @dev Extension of {ERC20} that adds a possibility to temporary prevent any token movements.
 */
contract ERC20Haltable is ERC20Mintable, HalterRole {

    bool public paused;

    event Paused(address by);
    event Unpaused(address by);

    modifier notPaused() {
        require(!paused);
        _;
    }

    function pause() public onlyHalter {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyHalter {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function _transfer(address from, address to, uint256 value) internal notPaused {
        super._transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal notPaused {
        super._mint(account, value);
    }

    function _burn(address account, uint256 amount) internal notPaused {
        super._burn(account, amount);
    }

}

/**
 * @title ApproveAndCall Interface.
 * @dev ApproveAndCall system allows to communicate with smart-contracts.
 */
interface IApproveAndCallFallBack {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external;
}

/**
 * @title The main project contract.
 */
contract Chia is ERC20Haltable {

    string private _name = "Chia Network";
    string private _symbol = "XCH";
    uint8 private _decimals = 18;

    uint256 internal constant _emission = 1000000000 * (10 ** 18);

    mapping (address => bool) private _contracts;

    bool public mintingFinished;

    mapping (address => uint256) internal holderMap;

    address[] public holderList;

    modifier onlyMinter() {
        if (mintingFinished) {
            revert();
        }
        require(isMinter(msg.sender), "Caller has no permission");
        _;
    }

    constructor() public {
        _addHolder(address(0));
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (value != 0) {
            if (holderMap[to] == 0) {
                _addHolder(to);
            }
            if (balanceOf(from).sub(value) == 0) {
                _removeHolder(from);
            }
        }

        super._transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _emission);

        if (value != 0 && holderMap[account] == 0) {
            _addHolder(account);
        }

        super._mint(account, value);
    }

    function _burn(address account, uint256 amount) internal {
        if (balanceOf(account).sub(amount) == 0) {
            _removeHolder(account);
        }

        super._burn(account, amount);
    }

    function _addHolder(address account) internal {
        holderList.push(account);
        holderMap[account] = holderList.length.sub(1);
    }

    function _removeHolder(address account) internal {
        if (holderList.length > 1) {
            holderList[holderMap[account]] = holderList[holderList.length.sub(1)];
            holderMap[holderList[holderList.length.sub(1)]] = holderMap[account];
        }
        holderMap[account] = 0;
        holderList.length = holderList.length.sub(1);
    }

    function approveAndCall(address spender, uint256 amount, bytes memory extraData) public returns (bool) {
        require(approve(spender, amount));

        IApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {

        if (_contracts[to]) {
            approveAndCall(to, value, new bytes(0));
        } else {
            super.transfer(to, value);
        }

        return true;

    }

    function registerContract(address addr) public onlyOwner {
        require(isContract(addr));
        _contracts[addr] = true;
    }

    function unregisterContract(address addr) external onlyOwner {
        _contracts[addr] = false;
    }

    function finishMinting() external onlyMinter {
        mintingFinished = true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function isRegistered(address addr) public view returns (bool) {
        return _contracts[addr];
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function amountOfHolders() public view returns (uint256) {
        return holderList.length.sub(1);
    }

    function holders() public view returns (address[] memory) {
        return holderList;
    }

}