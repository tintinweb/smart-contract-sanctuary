/**
 *Submitted for verification at polygonscan.com on 2022-01-11
*/

pragma solidity 0.7.0;
// SPDX-License-Identifier: MIT

/**
 * @title partial ERC-20 Token interface according to official documentation:
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface Erc20Token {

    /**
     * Send `_value` of tokens from `msg.sender` to `_to`
     *
     * @param _to The recipient address
     * @param _value The amount of tokens to be transferred
     * @return success Indication if the transfer was successful
     */
    function transfer(address _to, uint256 _value) external returns (bool success);

    /**
     * Approve `_spender` to withdraw from sender's account multiple times, up to `_value`
     * amount. If this function is called again it overwrites the current allowance with _value.
     *
     * @param _spender The address allowed to operate on sender's tokens
     * @param _value The amount of tokens allowed to be transferred
     * @return success Indication if the approval was successful
     */
    function approve(address _spender, uint256 _value) external returns (bool success);

    /**
     * Transfer tokens on behalf of `_from`, provided it was previously approved.
     *
     * @param _from The transfer source address (tokens owner)
     * @param _to The transfer destination address
     * @param _value The amount of tokens to be transferred
     * @return success Indication if the approval was successful
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    /**
     * Returns the account balance of another account with address `_owner`.
     */
    function balanceOf(address _owner) external view returns (uint256);

    /// OPTIONAL in the standard
    function decimals() external pure returns (uint8);

    function allowance(address _owner, address _spender) external view returns (uint256);

}

contract DummyErc20Token is Erc20Token {

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowances;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// The whole supply is given to the deployer -- one million tokens with 18 decimals
    constructor() {
        uint256 initialSupply = 1000000 ether;
        balances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function decimals() public override pure returns (uint8) {
        return 18;
    }

    function balanceOf(address owner) public override view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public virtual override returns (bool success) {
        require(balances[msg.sender] >= value, "balance too low");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool success) {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override returns (bool success) {
        require(balances[from] >= value, "balance too low");
        require(allowances[from][msg.sender] >= value, "allowance too low");
        balances[from] -= value;
        allowances[from][msg.sender] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    /// Mints 100000 test tokens for anyone with balance less than 1000
    function mintMeTokens() public returns (bool success) {
        require(balances[msg.sender] <= 1000, "address already has tokens");
        balances[msg.sender] += 100000 ether;
        return true;
    }

}