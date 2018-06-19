pragma solidity ^0.4.19;

interface ERC20 {
  function transfer(address to, uint256 value) public returns (bool);
}

/**
 * @title Airdrop contract used to perform bulk transfers within a single transaction.
 */
contract Airdrop {
  address _owner;

  modifier ownerOnly {
    if (_owner == msg.sender) _;
  }

  function Airdrop() public {
    _owner = msg.sender;
  }

  function transferOwnership(address newOwner) public ownerOnly {
    _owner = newOwner;
  }

  /**
   * @dev Perform the airdrop. Restricted to no more than 300 accounts in a single transactions
   * @notice More than 300 accounts will exceed gas block limit. It is recommended to perform
   * batches using no more than 250 accounts as the actual gas cost is dependent on the
   * tokenContractAddress&#39;s implementation of transfer())
   *
   * @param tokenContractAddress The address of the token contract being transfered.
   * @param recipients Array of accounts receiving tokens.
   * @param amounts Array of amount of tokens to be transferred. Index of amounts lines up with
   *                the index of recipients.
   */
  function drop(address tokenContractAddress, address[] recipients, uint256[] amounts) public ownerOnly {
    require(tokenContractAddress != 0x0);
    require(recipients.length == amounts.length);
    require(recipients.length <= 300);

    ERC20 tokenContract = ERC20(tokenContractAddress);

    for (uint8 i = 0; i < recipients.length; i++) {
      tokenContract.transfer(recipients[i], amounts[i]);
    }
  }
}