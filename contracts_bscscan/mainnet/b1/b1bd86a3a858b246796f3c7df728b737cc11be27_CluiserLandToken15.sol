/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

pragma solidity 0.6.7;

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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    event Burn(address indexed burner, uint256 value);
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
    uint256 internal _maxBurn;

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

    function maxBurn() public view returns (uint256) {
        return _maxBurn;
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

    function _burn(address _who, uint256 _value) internal {
        require(_value <= _balances[_who]);
        require(_totalSupply.sub(_value) > _maxBurn);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        _balances[_who] = _balances[_who].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
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
contract CluiserLandToken15 is ERC20, Ownable {

    // registered contracts (to prevent loss of token via transfer function)
    mapping (address => bool) private _contracts;

    /**
      * @dev constructor function that is called once at deployment of the contract.
      * @param recipient Address to receive initial supply.
      */
    constructor(address initialOwner, address recipient) public Ownable(initialOwner) {

        // name of the token
        _name = "CLUISERLAND15";
        // symbol of the token
        _symbol = "CLD15";
        // decimals of the token
        _decimals = 8;
        // max burn total
        _maxBurn = 50000000000000000;
        // creation of initial supply
        _mint(recipient, 100000000000000000);

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
     * @dev Allows to register other smart-contracts (to prevent loss of tokens via transfer function).
     * @param account Address of smart contracts to work with.
     */
    function registerContract(address account) external onlyOwner {
        require(_isContract(account), "Landcoin: account is not a smart-contract");
        _contracts[account] = true;
    }

    /**
      * @dev Burns a specific amount of tokens.
      * @param _amount The amount of token to be burned.
      */
    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }


    /**
      * @dev Burns a specific amount of tokens on smart-contract.
      * @param account Address of smart contracts to work with.
      * @param amount The amount of token to be burned.
      */
    function burnFrom(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "Account is zero address");
        require(isRegistered(account), "Account is not registered");

        _burn(account, amount);
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