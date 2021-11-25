/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract CookieCoin {
    // ERC20 info
    string public constant name = "CookieCoin";
    string public constant symbol = "COK";
    uint8  public constant decimals = 0;

    // factory state
    address public baker;
    uint public cookiesStored;
    uint cookiesTotal;
    mapping(address => uint) cookiesOwned;
    mapping(address => mapping(address => uint)) cookiesAllowed;

    // ERC20 events
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    // factory events
    event NewCookiesBaked(uint count);

    error OnlyBakerAllowed();
    error NotEnoughCookies(uint cookiesOwned);

    constructor() {
        baker = msg.sender;
    }

    // modifiers
    modifier kitchenAccess() {
        if (msg.sender != baker)
            revert OnlyBakerAllowed();
        _;
    }

    modifier haveCookies(uint count) {
        if (cookiesOwned[msg.sender] < count)
            revert NotEnoughCookies(cookiesOwned[msg.sender]);
        _;
    }

    // ERC20 read methods
    function totalSupply() public view returns (uint) {
        return cookiesTotal;
    }

    function balanceOf(address owner) public view returns (uint balance) {
        return cookiesOwned[owner];
    }

    function allowance(address owner, address spender) public view returns (uint remaining) {
        return cookiesAllowed[owner][spender];
    }

    // factory write methods
    function transferFactory(address newOwner) external kitchenAccess {
        baker = newOwner;
    }

    function bakeCookies(uint count) external kitchenAccess {
        cookiesStored += count;

        emit NewCookiesBaked(count);
    }

    function deliverCookies(uint count, address to) external kitchenAccess {
        require(cookiesStored >= count);

        cookiesStored -= count;
        cookiesOwned[to] += count;
        cookiesTotal += count;

        emit Transfer(address(0), to, count);
    }

    function consumeCookie() external haveCookies(1) {
        cookiesOwned[msg.sender]--;
        cookiesTotal--;

        emit Transfer(msg.sender, address(0), 1);
    }

    // ERC20 write methods
    function transfer(address to, uint value) public returns (bool success) {
        require(cookiesOwned[msg.sender] >= value);

        cookiesOwned[msg.sender] -= value;
        cookiesOwned[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool success) {
        require(cookiesAllowed[from][msg.sender] >= value);
        require(cookiesOwned[from] >= value);

        cookiesAllowed[from][msg.sender] -= value;
        cookiesOwned[from] -= value;
        cookiesOwned[to] += value;

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns (bool success) {
        cookiesAllowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }
}