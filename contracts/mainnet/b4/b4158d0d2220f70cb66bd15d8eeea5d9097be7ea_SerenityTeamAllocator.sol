pragma solidity ^0.4.11;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


// Time-locked wallet for Serenity advisors tokens
contract SerenityTeamAllocator {
    // Address of team member to allocations mapping
    mapping (address => uint256) allocations;

    ERC20Basic erc20_contract = ERC20Basic(0xBC7942054F77b82e8A71aCE170E4B00ebAe67eB6);
    uint unlockedAt;
    address owner;

    function SerenityTeamAllocator() {
        unlockedAt = now + 11 * 30 days;
        owner = msg.sender;

        allocations[0x4bA894C02BC92FC59573F1A4D0d82361AC3a6284] = 840497 ether;
        allocations[0xA71703676002410fa62EE74052b991B1b5F6c891] = 133333 ether;
        allocations[0x530f065d63FD73480e34da84E5aE1dfD6f77Aa73] = 66666 ether;
        allocations[0xa33def7d09B1CE511f7d5675B2C374526fAB44c7] = 66666 ether;
        allocations[0x11C6F9ccf49EBE938Dae82AE6c50a64eB5778dCC] = 40000 ether;
        allocations[0x4296C27536553c59e57Fa8EA47913F5000311f03] = 66666 ether;
    }

    // Unlock team member&#39;s tokens by transferring them to his address
    function unlock() external {
        require (now >= unlockedAt);

        var amount = allocations[msg.sender];
        allocations[msg.sender] = 0;

        if (!erc20_contract.transfer(msg.sender, amount)) {
            revert();
        }
    }
}