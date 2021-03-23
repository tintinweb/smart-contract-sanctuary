pragma solidity 0.5.10;

import './LibInteger.sol';

/**
 * @title BlobFormation 
 * @dev HBF token contract adhering to ERC20 standard
 */
contract BlobFormation
{
    using LibInteger for uint;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    /**
     * @dev The admin of the contract
     */
    address payable private _admin;

    /**
     * @dev The current supply of token
     */
    uint private _supply;

    /**
     * @dev Permitted addresses to carry out special functions
     */
    mapping (address => bool) private _permissions;

    /**
     * @dev Number of tokens held by an address
     */
    mapping (address => uint) private _token_balances;

    /**
     * @dev Approved allowances for third party addresses
     */
    mapping (address => mapping(address => uint)) private _token_allowances;

    /**
     * Number of decimals in base currency
     */
    uint private constant _decimals = 18;

    /**
     * @dev The Maximum supply of token
     */
    uint private constant _max_supply = 400000 * 10**_decimals;

    /**
     * @dev The name of token
     */
    string private constant _name = "Hash Blob Formation";

    /**
     * @dev The symbol of token
     */
    string private constant _symbol = "HBF";

    /**
     * @dev Initialise the contract
     */
    constructor() public
    {
        //The contract creator becomes the admin
        _admin = msg.sender;

        //Mint max supply and send it to the admin
        _supply = _max_supply;
        _token_balances[_admin] = _supply;
        emit Transfer(address(0), _admin, _supply);
    }

    /**
     * @dev Allow access only for the admin of contract
     */
    modifier onlyAdmin()
    {
        require(msg.sender == _admin);
        _;
    }

    /**
     * @dev Allow access only for the permitted addresses
     */
    modifier onlyPermitted()
    {
        require(_permissions[msg.sender]);
        _;
    }

    /**
     * @dev Give or revoke permission of accounts
     * @param account The address to change permission
     * @param permission True if the permission should be granted, false if it should be revoked
     */
    function permit(address account, bool permission) public onlyAdmin
    {
        _permissions[account] = permission;
    }

    /**
     * @dev Withdraw from the balance of this contract
     * @param amount The amount to be withdrawn, if zero is provided the whole balance will be withdrawn
     */
    function clean(uint amount) public onlyAdmin
    {
        if (amount == 0){
            _admin.transfer(address(this).balance);
        } else {
            _admin.transfer(amount);
        }
    }

    /**
     * @dev Moves tokens from the caller's account to someone else
     * @param to The recipient address
     * @param value The number of tokens to send
     */
    function transfer(address to, uint value) public
    {
        _send(msg.sender, to, value);
    }

    /**
     * @dev Sets amount of tokens spender is allowed to transfer from caller's tokens
     * @param spender The spender to allow
     * @param value The number of tokens to allow
     */
    function approve(address spender, uint value) public
    {
        _token_allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    /**
     * @dev Moves tokens using the allowance mechanism
     * @param from The owner of tokens
     * @param to The recipient address
     * @param value The number of tokens to send
     */
    function transferFrom(address from, address to, uint value) public
    {
        _token_allowances[from][msg.sender] = _token_allowances[from][msg.sender].sub(value);
        _send(from, to, value);
    }

    /**
     * @dev Burn tokens forever
     * @param from The owner of tokens
     * @param value The number of tokens to be burned
     */
    function burn(address from, uint value) public onlyPermitted
    {
        //Must set number of tokens that needs to be burned
        require(value > 0);

        //The total supply must be greater than the tokens that needs to be burned
        require(_supply >= value);

        //The owner must have enough tokens available
        require(_token_balances[from] >= value);

        //Reduce supply
        _supply = _supply.sub(value);

        //Reduce owner's balance
        _token_balances[from] = _token_balances[from].sub(value);

        //Emit events and return
        emit Transfer(from, address(0), value);
    }

    /**
     * @dev Get the total number of tokens in existance
     * @return uint Number of tokens
     */
    function totalSupply() public view returns (uint)
    {
        return _supply;
    }

    /**
     * @dev Get the maximum number of tokens minted
     * @return uint Maximum number of tokens
     */
    function maxSupply() public pure returns (uint)
    {
        return _max_supply;
    }

    /**
     * @dev Get the total number of tokens spender is allowed to spend out of owner's tokens
     * @param owner The tokens owner
     * @param spender The allowed spender
     * @return uint Number of tokens allowed to spend
     */
    function allowance(address owner, address spender) public view returns (uint)
    {
        return _token_allowances[owner][spender];
    }

    /**
     * @dev Get number of tokens belonging to an account
     * @param account The address of account to check
     * @return uint The tokens balance
     */
    function balanceOf(address account) public view returns (uint)
    {
        return _token_balances[account];
    }

    /**
     * @dev Get name of token
     * @return string The name
     */
    function name() public pure returns (string memory)
    {
        return _name;
    }

    /**
     * @dev Get symbol of token
     * @return string The symbol
     */
    function symbol() public pure returns (string memory)
    {
        return _symbol;
    }

    /**
     * @dev Get number of decimals of token
     * @return uint The decimals count
     */
    function decimals() public pure returns (uint)
    {
        return _decimals;
    }

    /**
     * @dev Check whether the provided address is permitted
     * @param account The address to check
     * @return bool True if the address is permitted, otherwise false
     */
    function isPermitted(address account) public view returns (bool)
    {
        return _permissions[account];
    }

    /**
     * @dev Transfer tokens from one account to another
     * @param from The token owner
     * @param to The token receiver
     * @param value The number of tokens to transfer
     */
    function _send(address from, address to, uint value) private
    {
        //Reduce the balance from owner
        _token_balances[from] = _token_balances[from].sub(value);

        //Increase the balance of receiver
        _token_balances[to] = _token_balances[to].add(value);

        //Emit events
        emit Transfer(from, to, value);
    }
}