/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

/**
 *Submitted for verification at BscScan.com on 2021-04-26
*/

/**
 *Submitted for verification at Etherscan.io on 2019-10-11
*/

pragma solidity 0.5.10;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
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

    constructor(address initialOwner) internal {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Caller has no permission");
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

contract MinterRole is Ownable {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor() internal {
        _minters.add(_owner);
        emit MinterAdded(_owner);
    }

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
 * @dev BurnableToken
 */
contract BurnableToken is ERC20 {

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }

}

/**
 * @dev MintableToken
 */
contract MintableToken is BurnableToken, MinterRole {

    bool public mintingFinished;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address account, uint256 amount) public onlyMinter canMint returns (bool) {
        _mint(account, amount);
        return true;
    }

    function finishMinting() external onlyOwner canMint {
        mintingFinished = true;
    }

}

/**
 * @title LockableToken
 */
contract LockableToken is MintableToken {

    mapping (address => uint256) private _locked;

    event Locked(address indexed account, uint256 amount, address indexed by);
    event Unlocked(address indexed account, uint256 amount, address indexed by);

    /**
     * @dev prevent any transfer of locked tokens.
     */
    modifier canTransfer(address from, uint256 value) {
        if (_locked[from] > 0) {
            require(balanceOf(from).sub(value) >= _locked[from]);
        }
        _;
    }

    /**
     * @dev lock tokens of array of addresses.
     * Available only to the owner.
     * @param accounts array of addresses.
     * @param amounts array of amounts of tokens.
     */
    function lock(address[] calldata accounts, uint256[] calldata amounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _locked[accounts[i]] = _locked[accounts[i]].add(amounts[i]);
            emit Locked(accounts[i], amounts[i], msg.sender);
        }
    }

    /**
     * @dev unlock tokens of array of addresses.
     * Available only to the owner.
     * @param accounts array of addresses.
     * @param amounts array of amounts of tokens.
     */
    function unlock(address[] calldata accounts, uint256[] calldata amounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _locked[accounts[i]] = _locked[accounts[i]].sub(amounts[i]);
            emit Unlocked(accounts[i], amounts[i], msg.sender);
        }
    }

    /**
     * @dev amount of locked tokens of specific address.
     * @param account holder address.
     * @return amount of locked tokens.
     */
    function lockedOf(address account) external view returns(uint256) {
        return _locked[account];
    }

    /**
     * @dev modified internal transfer function that prevents any transfer of locked tokens.
     * @param from address The address which you want to send tokens from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal canTransfer(from, value) {
        super._transfer(from, to, value);
    }

}

/**
 * @title ApproveAndCall Interface.
 * @dev ApproveAndCall system allows to communicate with smart-contracts.
 */
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external;
}

/**
 * @title The Bitcoin Finance Token project contract.
 * @author https://webport.technology/
 */
contract BFToken is LockableToken {

    // name of the token
    string private _name = "Bitcoin Finance Token";
    // symbol of the token
    string private _symbol = "BFT";
    // decimals of the token
    uint8 private _decimals = 8;

    // initial supply
    uint256 internal constant INITIAL_SUPPLY = 5000000000 * (10 ** 8);

    // registered contracts (to prevent loss of token via transfer function)
    mapping (address => bool) private _contracts;

    /**
     * @dev constructor function that is called once at deployment of the contract.
     * @param recipient Address to receive initial supply.
     */
    constructor(address recipient, address initialOwner) public Ownable(initialOwner) {

        _mint(recipient, INITIAL_SUPPLY);

    }

    /**
     * @dev Allows to send tokens (via Approve and TransferFrom) to other smart contract.
     * @param spender Address of smart contracts to work with.
     * @param amount Amount of tokens to send.
     * @param extraData Any extra data.
     */
    function approveAndCall(address spender, uint256 amount, bytes memory extraData) public returns (bool) {
        require(approve(spender, amount));

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

    /**
     * @dev Allows to register other smart contracts (to prevent loss of tokens via transfer function).
     * @param addr Address of smart contracts to work with.
     */
    function registerContract(address addr) public onlyOwner {
        require(isContract(addr));
        _contracts[addr] = true;
    }

    /**
     * @dev Allows to unregister registered smart contracts.
     * @param addr Address of smart contracts to work with.
     */
    function unregisterContract(address addr) external onlyOwner {
        _contracts[addr] = false;
    }

    /**
     * @dev modified transfer function that allows to safely send tokens to smart contract.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {

        if (_contracts[to]) {
            approveAndCall(to, value, new bytes(0));
        } else {
            super.transfer(to, value);
        }

        return true;

    }

    /**
     * @dev modified transferFrom function that allows to safely send tokens to exchange contract.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {

        if (_contracts[to] && !_contracts[msg.sender]) {
            ApproveAndCallFallBack(to).receiveApproval(msg.sender, value, address(this), new bytes(0));
        } else {
            super.transferFrom(from, to, value);
        }

        return true;
    }

    /**
     * @dev Allows to any owner of the contract withdraw needed ERC20 token from this contract (promo or bounties for example).
     * @param ERC20Token Address of ERC20 token.
     * @param recipient Account to receive tokens.
     */
    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {

        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);

    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @return true if the address is a сontract
     */
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}