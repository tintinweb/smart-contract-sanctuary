/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function transfer(address to, uint256 value) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
    function approve(address spender, uint256 value) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);
}

/**
 * Simple ERC-20 implementation
 */
contract WRVN is IERC20 {
    address internal owner;

    address public issuer;

    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;

    string public override name;
    string public override symbol;

    uint8 public override decimals;

    uint256 public override totalSupply;

    modifier onlyIssuer() {
        require(msg.sender == issuer); // dev: requires issuer
        _;
    }

    /**
     * Sets the token fields: owner, issuer, name, and symbol
     *
     */
    constructor(address tokenOwner, address tokenIssuer, string memory tokenName, string memory tokenSymbol) {
        owner = tokenOwner;
        issuer = tokenIssuer;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = 8;
    }

    function setIssuer(address newIssuer)
    external {
        require(msg.sender == owner); // dev: requires owner

        issuer = newIssuer;
    }

    /**
     * Mints {value} tokens to the {to} wallet.
     *
     * @param to The address receiving the newly minted tokens
     * @param value The number of tokens to mint
     */
    function mint(address to, uint256 value)
    external
    onlyIssuer {
        require(to != address(0)); // dev: requires non-zero address

        totalSupply += value;
        balanceOf[to] += value;

        emit Transfer(address(0), to, value);
    }

    /**
     * Burn {value} tokens of the {from} wallet.
     *
     * @param from The address to burn tokens from
     * @param value The number of tokens to burn
     */
    function burn(address from, uint256 value)
    external
    onlyIssuer {
        uint256 balance = balanceOf[from];
        require(balance >= value); // dev: exceeds balance
    
        balanceOf[from] = balance - value;
        totalSupply -= value;
    
        emit Transfer(from, address(0), value);
    }

    /**
     * Approves the `spender` to transfer `value` tokens of the caller.
     *
     * @param spender The address which will spend the funds
     * @param value The value approved to be spent by the spender
     * @return A boolean that indicates if the operation was successful
     */
    function approve(address spender, uint256 value)
    external
    override
    returns(bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    /**
     * Transfers {value} tokens from the caller, to {to}
     *
     * @param to The address to transfer tokens to
     * @param value The number of tokens to be transferred
     * @return A boolean that indicates if the operation was successful
     */
    function transfer(address to, uint256 value)
    external
    override
    returns (bool) {
        move(msg.sender, to, value);

        return true;
    }

    /**
     * Transfers {value} tokens of {from} to {to}, on behalf of the caller.
     *
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param value The number of tokens to be transferred
     * @return A boolean that indicates if the operation was successful
     */
    function transferFrom(address from, address to, uint256 value)
    external
    override
    returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        require(currentAllowance >= value); // dev: exceeds allowance
        move(from, to, value);
        allowance[from][msg.sender] = currentAllowance - value;

        return true;
    }

    function move(address from, address to, uint256 value)
    internal {
        require(to != address(0)); // dev: requires non-zero address
        uint256 balance = balanceOf[from];
        require(balance >= value); // dev: exceeds balance
        balanceOf[from] = balance - value;
        balanceOf[to] += value;

        emit Transfer(from, to, value);
    }

}