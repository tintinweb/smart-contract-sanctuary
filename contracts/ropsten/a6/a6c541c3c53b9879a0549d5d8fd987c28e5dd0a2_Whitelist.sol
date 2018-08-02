pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/ownership/HasNoEther.sol

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5123343c323e1163">[email&#160;protected]</a>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

// File: contracts/Whitelist.sol

contract Whitelist is HasNoEther {

  bool public open = true;

  mapping(address => bool) public whitelisted;
  uint public totalWhitelisted;
  mapping(address => bool) public blacklisted;
  uint public totalBlacklisted;

  modifier whenOpen() {
    require(open);
    _;
  }

  function close()
  external
  onlyOwner
  {
      open = false;
  }

  function whitelist(
    address[] addrs
  )
  external
  onlyOwner
  whenOpen
  {
    for (uint a = 0; a < addrs.length; a++) {
      if (addrs[a] != address(0) && !whitelisted[addrs[a]] && !blacklisted[addrs[a]]) {
        whitelisted[addrs[a]] = true;
        totalWhitelisted++;
      }
    }
  }

  function blacklist(
    address[] addrs
  )
  external
  onlyOwner
  {
    for (uint a = 0; a < addrs.length; a++) {
      if (!blacklisted[addrs[a]]) {
        if (whitelisted[addrs[a]]) {
          whitelisted[addrs[a]] = false;
          totalWhitelisted--;
        }
        blacklisted[addrs[a]] = true;
        totalBlacklisted++;
      }
    }
  }

  function reset(
    address[] addrs
  )
  external
  onlyOwner
  whenOpen
  {
    for (uint a = 0; a < addrs.length; a++) {
      if (whitelisted[addrs[a]]) {
        whitelisted[addrs[a]] = false;
        totalWhitelisted--;
      } else if (blacklisted[addrs[a]]) {
        blacklisted[addrs[a]] = false;
        totalBlacklisted--;
      }
    }
  }

}