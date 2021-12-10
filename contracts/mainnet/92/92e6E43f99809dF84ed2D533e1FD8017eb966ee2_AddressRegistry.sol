// SPDX-License-Identifier: MIT
// Votium Address Registry

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract AddressRegistry is Ownable {
  struct Registry {
    uint256 start;      // when first registering, there is a delay until the next vlCVX voting epoch starts
    address to;         // forward rewards to alternate address OR 0x0 address for OPT OUT of rewards
    uint256 expiration; // when ending an active registration, expiration is set to the next vlCVX voting epoch
                        // an active registration cannot be changed until after it is expired (one vote round delay when changing active registration)
  }
  mapping(address => Registry) public registry;

  mapping(address => bool) public inOptOutHistory;
  mapping(address => bool) public inForwardHistory;
  address[] public optOutHistory;
  address[] public forwardHistory;

  // address changes do not take effect until the next vote starts
  uint256 public constant eDuration = 86400 * 14;


  // Set forwarding address or OPT OUT of rewards by setting to 0x0 address
  // Registration is active until setToExpire() is called, and then remains active until the next reward period
  function setRegistry(address _to) public {
    uint256 current = currentEpoch();
    require(registry[msg.sender].start == 0 || registry[msg.sender].expiration <= current,"Registration is still active");
    registry[msg.sender].start = current+eDuration;
    registry[msg.sender].to = _to;
    registry[msg.sender].expiration = 0xfffffffff;
    if(_to == address(0)) {
      // prevent duplicate entry in optOutHistory array
      if(!inOptOutHistory[msg.sender]) {
        optOutHistory.push(msg.sender);
        inOptOutHistory[msg.sender] = true;
      }
    } else if(!inForwardHistory[msg.sender]) {
        forwardHistory.push(msg.sender);
        inForwardHistory[msg.sender] = true;
    }
    emit setReg(msg.sender, _to, registry[msg.sender].start);
  }

  // Sets a registration to expire on the following epoch (cannot change registration during an epoch)
  function setToExpire() public {
    uint256 next = nextEpoch();
    require(registry[msg.sender].start > 0 && registry[msg.sender].expiration > next,"Not registered or expiration already pending");
    // if not started yet, nullify instead of setting expiration
    if(next == registry[msg.sender].start) {
      registry[msg.sender].start = 0;
      registry[msg.sender].to = address(0);
    } else {
      registry[msg.sender].expiration = next;
    }
    emit expReg(msg.sender, next);
  }

  // supply an array of addresses, returns their destination (same address for no change, 0x0 for opt-out, different address for forwarding)
  function batchAddressCheck(address[] memory accounts) external view returns (address[] memory) {
    uint256 current = currentEpoch();
    for(uint256 i=0; i<accounts.length; i++) {
      // if registration active return "to", otherwise return checked address (no forwarding)
      if(registry[accounts[i]].start <= current && registry[accounts[i]].start != 0 && registry[accounts[i]].expiration > current) {
        accounts[i] = registry[accounts[i]].to;
      }
    }
    return accounts;
  }

  // length of optOutHistory - needed for retrieving paginated results from optOutPage()
  function optOutLength() public view returns (uint256) {
    return optOutHistory.length;
  }

  // returns list of actively opted-out addresses using pagination
  function optOutPage(uint256 size, uint256 page) public view returns (address[] memory) {
    page = size*page;
    uint256 current = currentEpoch();
    uint256 n = 0;
    for(uint256 i=page; i<optOutHistory.length; i++) {
      if(registry[optOutHistory[i]].start <= current && registry[optOutHistory[i]].expiration > current && registry[optOutHistory[i]].to == address(0)) {
        n++;
        if(n == size) { break; }
      }
    }
    address[] memory optOuts = new address[](n);
    n = 0;
    for(uint256 i=page; i<optOutHistory.length; i++) {
      if(registry[optOutHistory[i]].start <= current && registry[optOutHistory[i]].expiration > current && registry[optOutHistory[i]].to == address(0)) {
        optOuts[n] = optOutHistory[i];
        n++;
        if(n == size) { break; }
      }
    }
    return optOuts;
  }

  // length of forwardHistory - needed for retrieving paginated results from forwardPage()
  function forwardLength() public view returns (uint256) {
    return forwardHistory.length;
  }

  // returns list of actively opted-out addresses using pagination
  function forwardPage(uint256 size, uint256 page) public view returns (address[] memory) {
    page = size*page;
    uint256 current = currentEpoch();
    uint256 n = 0;
    for(uint256 i=page; i<forwardHistory.length; i++) {
      if(registry[forwardHistory[i]].start <= current && registry[forwardHistory[i]].expiration > current && registry[forwardHistory[i]].to != address(0)) {
        n++;
        if(n == size) { break; }
      }
    }
    address[] memory forwards = new address[](n*2);
    n = 0;
    for(uint256 i=page; i<forwardHistory.length; i++) {
      if(registry[forwardHistory[i]].start <= current && registry[forwardHistory[i]].expiration > current && registry[forwardHistory[i]].to != address(0)) {
        forwards[n] = forwardHistory[i];
        forwards[n+1] = registry[forwardHistory[i]].to;
        n+=2;
        if(n == size*2) { break; }
      }
    }
    return forwards;
  }

  // returns start of current Epoch
  function currentEpoch() public view returns (uint256) {
    return block.timestamp/eDuration*eDuration;
  }

  // returns start of next Epoch
  function nextEpoch() public view returns (uint256) {
    return block.timestamp/eDuration*eDuration+eDuration;
  }

  // only used for rescuing mistakenly sent funds or other unexpected needs
  function execute(address _to, uint256 _value, bytes calldata _data) external onlyOwner returns (bool, bytes memory) {
    (bool success, bytes memory result) = _to.call{value:_value}(_data);
    return (success, result);
  }

  // multi-sig functions for edge cases
  function forceRegistry(address _from, address _to) public onlyOwner {
    uint256 current = currentEpoch();
    require(registry[_from].start == 0 || registry[_from].expiration < current,"Registration is still active");
    registry[_from].start = current+eDuration;
    registry[_from].to = _to;
    registry[_from].expiration = 0xfffffffff;
    if(_to == address(0)) {
      // prevent duplicate entry in optOutHistory array
      if(!inOptOutHistory[_from]) {
        optOutHistory.push(_from);
        inOptOutHistory[_from] = true;
      }
    } else if(!inForwardHistory[_from]) {
        forwardHistory.push(_from);
        inForwardHistory[_from] = true;
    }
    emit setReg(_from, _to, registry[_from].start);
  }

  function forceToExpire(address _from) public onlyOwner {
    uint256 next = nextEpoch();
    require(registry[_from].start > 0 && registry[_from].expiration > next,"Not registered or expiration already pending");
    // if not started yet, nullify instead of setting expiration
    if(next == registry[_from].start) {
      registry[_from].start = 0;
      registry[_from].to = address(0);
    } else {
      registry[_from].expiration = next;
    }
    emit expReg(_from, next);
  }

  event setReg(address indexed _from, address indexed _to, uint256 indexed _start);
  event expReg(address indexed _from, uint256 indexed _end);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {

	  address private _owner = 0xe39b8617D571CEe5e75e1EC6B2bb40DdC8CF6Fa3; // Votium multi-sig address

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}