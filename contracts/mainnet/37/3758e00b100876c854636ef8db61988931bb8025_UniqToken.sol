/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

// Contracts interaction interface
abstract contract IContract {
    function balanceOf(address owner) external virtual returns (uint256);

    function transfer(address to, uint256 value) external virtual;
}

// https://eips.ethereum.org/EIPS/eip-20
contract UniqToken {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    uint256 public totalSupply;
    address public owner;
    address constant ZERO = address(0);

    modifier notZeroAddress(address a) {
        require(a != ZERO, "Address 0x0 not allowed");
        _;
    }

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customize the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public constant name = "Uniqly"; // Token name
    string public constant symbol = "UNIQ"; // Token symbol
    uint8 public constant decimals = 18; // Token decimals

    constructor(uint256 _initialAmount) {
        balances[msg.sender] = _initialAmount; // Give the creator all initial tokens
        totalSupply = _initialAmount; // Update total supply
        owner = msg.sender; // Set owner
        emit Transfer(ZERO, msg.sender, _initialAmount); // Emit event
    }

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value)
        external
        notZeroAddress(_to)
        returns (bool)
    {
        require(
            balances[msg.sender] >= _value,
            "ERC20 transfer: token balance too low"
        );
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external notZeroAddress(_to) returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];
        require(
            balances[_from] >= _value && _allowance >= _value,
            "ERC20 transferFrom: token balance or allowance too low"
        );
        balances[_from] -= _value;
        if (_allowance < (2**256 - 1)) {
            _approve(_from, msg.sender, _allowance - _value);
        }
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value)
        external
        notZeroAddress(_spender)
        returns (bool)
    {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        allowed[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {_burn}.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {_burn} and {allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = allowed[account][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount)
        internal
        notZeroAddress(account)
    {
        require(
            balances[account] >= amount,
            "ERC20: burn amount exceeds balance"
        );
        balances[account] -= amount;
        totalSupply -= amount;

        emit Transfer(account, ZERO, amount);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only for Owner");
        _;
    }

    // change ownership in two steps to be sure about owner address
    address public newOwner;

    // only current owner can delegate new one
    function giveOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    // new owner need to accept ownership
    function acceptOwnership() external {
        require(msg.sender == newOwner, "You are not New Owner");
        newOwner = address(0);
        owner = msg.sender;
    }

    /**
    @dev Function to recover accidentally send ERC20 tokens
    @param _token ERC20 token address
    */
    function rescueERC20(address _token) external onlyOwner {
        uint256 amt = IContract(_token).balanceOf(address(this));
        require(amt > 0, "Nothing to rescue");
        IContract(_token).transfer(owner, amt);
    }

    /**
    @dev Function to recover any ETH send to contract
    */
    function rescueETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}