// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        require(initialOwner != address(0), "Ownable: initial owner is the zero address");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_isOwner(msg.sender), "Ownable: caller is not the owner");
        _;
    }

    function _isOwner(address account) internal view returns (bool) {
        return account == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0));

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
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

}

/**
 * @dev Custom extension of {ERC20} that adds a set of Minter accounts,
 * which have permission to mint (create) new tokens as they see fit.
 */
abstract contract ERC20Mintable is ERC20Burnable, Ownable {

    address[] internal _minters;

    mapping (address => Minter) public minterInfo;
    struct Minter {
        bool active;
        uint256 limit;
        uint256 minted;
    }

    modifier canMint(uint256 amount) virtual {
        require(isMinter(msg.sender), "Caller has no permission");
        require(minterInfo[msg.sender].minted.add(amount) <= minterInfo[msg.sender].limit, "Minter limit overflow");
        minterInfo[msg.sender].minted = minterInfo[msg.sender].minted.add(amount);
        _;
    }

    function mint(address account, uint256 amount) public canMint(amount) returns (bool) {
        _mint(account, amount);
        return true;
    }

    function setMinter(address account, uint256 limit) public onlyOwner {
        require(account != address(0));

        if (!minterInfo[account].active && limit > 0) {
            _minters.push(account);
            minterInfo[account].active = true;
        }

        if (limit > minterInfo[account].minted) {
            minterInfo[account].limit = limit;
        } else {
            minterInfo[account].limit = minterInfo[account].minted;
        }
    }

    function isMinter(address account) public view returns (bool) {
        return(minterInfo[account].active);
    }

    function getMinters() public view returns(address[] memory) {
        return _minters;
    }

    function getMintersInfo() public view returns(uint256 amountOfMinters, uint256 totalLimit, uint256 totalMinted) {
        amountOfMinters = _minters.length;
        for (uint256 i = 0; i < amountOfMinters; i++) {
            totalLimit += minterInfo[_minters[i]].limit;
            totalMinted += minterInfo[_minters[i]].minted;
        }
        return (amountOfMinters, totalLimit, totalMinted);
    }

}

/**
 * @title ApproveAndCall Interface.
 * @dev ApproveAndCall system allows to communicate with smart-contracts.
 */
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) virtual external;
}

/**
 * @title The main project contract.
 */
contract FinandyToken is ERC20Mintable {

    // initial supply
    uint256 public INITIAL_SUPPLY = 100000000 * 10 ** 8;

    // maximum cap
    uint256 public MAXIMUM_SUPPLY = 200000000 * 10 ** 8;

    // registered contracts (to prevent loss of token via transfer function)
    mapping (address => bool) private _contracts;

    // modified canMint modifier (to prevent exceeding the maximum cap)
    modifier canMint(uint256 amount) override {
        require(isMinter(msg.sender), "Caller has no permission");
        require(minterInfo[msg.sender].minted.add(amount) <= minterInfo[msg.sender].limit, "Minter limit overflow");
        require(totalSupply().add(amount) <= MAXIMUM_SUPPLY, "Total supply cannot exceed the cap");
        minterInfo[msg.sender].minted = minterInfo[msg.sender].minted.add(amount);
        _;
    }

    /**
      * @dev constructor function that is called once at deployment of the contract.
      * @param recipient Address to receive initial supply.
      */
    constructor(address initialOwner, address recipient) public Ownable(initialOwner) {

        // name of the token
        _name = "Finandy";
        // symbol of the token
        _symbol = "FIN";
        // decimals of the token
        _decimals = 8;

        // creation of initial supply
        _mint(recipient, INITIAL_SUPPLY);

    }

    /**
     * @dev modified transfer function that allows to safely send tokens to smart-contract.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public override returns (bool) {

        if (_contracts[to]) {
            approveAndCall(to, value, new bytes(0));
        } else {
            super.transfer(to, value);
        }

        return true;

    }

    /**
    * @dev Allows to send tokens (via Approve and TransferFrom) to other smart-contract.
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
     * @dev Allows to register other smart-contracts (to prevent loss of tokens via transfer function).
     * @param account Address of smart contracts to work with.
     */
    function registerContract(address account) external onlyOwner {
        require(_isContract(account), "DigexToken: account is not a smart-contract");
        _contracts[account] = true;
    }

    /**
     * @dev Allows to unregister registered smart-contracts.
     * @param account Address of smart contracts to work with.
     */
    function unregisterContract(address account) external onlyOwner {
        require(isRegistered(account), "DigexToken: account is not registered yet");
        _contracts[account] = false;
    }

    /**
    * @dev Allows to any owner of the contract withdraw needed ERC20 token from this contract (for example promo or bounties).
    * @param ERC20Token Address of ERC20 token.
    * @param recipient Account to receive tokens.
    */
    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {

        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);

    }

    /**
     * @return true if the address is registered as contract
     * @param account Address to be checked.
     */
    function isRegistered(address account) public view returns (bool) {
        return _contracts[account];
    }

    /**
     * @return true if `account` is a contract.
     * @param account Address to be checked.
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}