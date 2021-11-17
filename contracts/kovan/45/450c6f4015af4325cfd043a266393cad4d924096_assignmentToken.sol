/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // Specify maximum supply of token to 1 million
    uint256 private constant MAXSUPPLY = 1000000;
    // Set supply to 50,000 on contract creation
    uint256 public supply = 50000;
    // Define flat transaction fee
    uint256 public constant transferFee = 1;
    // Initial minter is the contract creator
    address public minter = msg.sender;

    // Event to be emitted on token transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Event to be emitted on approval
    event Approve(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // Event to be emitted on mintership transfer
    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    // Create mapping for balances
    mapping(address => uint256) public balances;

    // Create mapping for allowances
    // A nested mapping where a token "owner" can allow a "spender" to transfer tokens
    // accessed like this -> allowances[_owner][_spender]
    mapping(address => mapping(address => uint256)) public allowances;

    // Constructor run on contract creation
    constructor() {
        // Set sender's balance to total supply
        balances[msg.sender] = supply;
    }

    function totalSupply() public view returns (uint256) {
        // Return total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // Return the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // Forbid minting to 0 address
        require(receiver != address(0), "Minting to 0 address is forbidden");
        // Ensure sender is authorised minter
        require(msg.sender == minter, "Only a minter can mint a token");
        // Ensure amount is valid (between 0 and max supply)
        require(amount >= 0 && amount <= MAXSUPPLY, "Invalid amount, must be between 0 and maximum supply");
        // Total supply must not exceed `MAXSUPPLY`
        require(
            (supply + amount) <= MAXSUPPLY,
            "New total supply must not exceed max supply"
        );
        // Mint tokens by updating receiver's balance and total supply
        supply += amount;
        balances[receiver] += amount;
        emit Transfer(address(0), receiver, amount);

        return true;
    }

    function burn(address account, uint256 amount) public returns (bool) {
        // Only minter is allowed to burn tokens 
        require(msg.sender == minter, "Only minters are allowed to burn tokens");
        // Ensure sender is not at 0 address
        require(account != address(0), "Burn from 0 address forbidden");
        // Ensure sender must have enough balance to burn
        require(
            amount <= balances[account],
            "Tokens to burn exceeds sender balance"
        );
        // Burn tokens by sending tokens to `address(0)`
        balances[account] -= amount;
        supply -= amount;
        emit Transfer(account, address(0), amount);

        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // Ensure only incumbent minter can transfer mintership
        require(
            msg.sender == minter,
            "Only incumbent minter can transfer mintership"
        );
        // Transfer mintership to newminter
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // Forbid transfer to and from 0 address
        require(_to != address(0), "Transfer to 0 address forbidden");
        require(msg.sender != address(0), "Transfer from 0 address forbidden");
        // Ensure sender has enough tokens to transfer
        require(
            _value <= balances[msg.sender],
            "Sender does not have enough tokens to transfer"
        );
        // Ensure value to transfer can cover transfer fee
        require(
            _value > transferFee,
            "Transfer value cannot be less than transaction fee"
        );
        // Update balance of sender and receiver
        uint256 leviedValue = _value - transferFee;
        balances[msg.sender] -= _value;
        balances[_to] += leviedValue;
        emit Transfer(msg.sender, _to, leviedValue);
        // Reward minter with transfer fee
        balances[minter] += transferFee;
        emit Transfer(msg.sender, minter, transferFee);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // Forbid transfer to and from 0 address
        require(_to != address(0), "Transfer to 0 address forbidden");
        require(_from != address(0), "Transfer from 0 address forbidden");
        // Ensure owner has enough tokens to make transfer
        require(
            _value <= balances[_from],
            "Owner does not have enough tokens to transfer"
        );
        // Ensure spender's allowance is not exceeded
        require(
            _value <= allowances[_from][msg.sender],
            "Spender has no allowance or allowance is too low"
        );
        // Ensure value to transfer can cover transaction fees
        require(
            _value > transferFee,
            "Transfer value cannot be smaller than transaction fee"
        );
        // Update balance of sender and receiver
        uint256 leviedValue = _value - transferFee;
        balances[_from] -= _value;
        allowances[_from][msg.sender] -= _value;
        balances[_to] += leviedValue;
        emit Transfer(_from, _to, leviedValue);
        // Reward minter with transfer fee
        balances[minter] += transferFee;
        emit Transfer(_from, minter, transferFee);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // allow `_spender` to spend `_value` on sender's behalf
        // Overwrite existing allowances
        // NOTE: owner IS allowed to allocate more value than in current balance
        allowances[msg.sender][_spender] = _value;
        emit Approve(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        // Return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];
    }
}