//ascii art
//some other stuff

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./modules/WhitelistV2.sol";

contract WhitelistDemo is WhitelistV2 {
}

/***
 *     ██████╗ ██████╗ ███╗   ██╗████████╗███████╗██╗  ██╗████████╗
 *    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔════╝╚██╗██╔╝╚══██╔══╝
 *    ██║     ██║   ██║██╔██╗ ██║   ██║   █████╗   ╚███╔╝    ██║   
 *    ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══╝   ██╔██╗    ██║   
 *    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ███████╗██╔╝ ██╗   ██║   
 *     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝   
 * This is a re-write of @openzeppelin/contracts/utils/Context.sol
 * Rewritten by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Upgraded with _msgValue() and _txOrigin() as ContextV2 on 31 Dec 2021
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
abstract contract ContextV2 {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint) {
        return msg.value;
    }

    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }
}

/***
 *    ██╗    ██╗██╗  ██╗██╗████████╗███████╗
 *    ██║    ██║██║  ██║██║╚══██╔══╝██╔════╝
 *    ██║ █╗ ██║███████║██║   ██║   █████╗  
 *    ██║███╗██║██╔══██║██║   ██║   ██╔══╝  
 *    ╚███╔███╔╝██║  ██║██║   ██║   ███████╗
 *     ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝
 *                                          
 *    ██╗     ██╗███████╗████████╗          
 *    ██║     ██║██╔════╝╚══██╔══╝          
 *    ██║     ██║███████╗   ██║             
 *    ██║     ██║╚════██║   ██║             
 *    ███████╗██║███████║   ██║             
 *    ╚══════╝╚═╝╚══════╝   ╚═╝             
 * @title Whitelist
 * @author @MaxFlowO2 (Twitter/GitHub)
 * @dev provides a use case of Library Whitelist use in v2.2
 *      Written on 22 Jan 2022, using LBL Tech!
 *
 * Can be used on all "Tokens" ERC-20, ERC-721, ERC-777, ERC-1155 or whatever
 * Solidity contract you can think of!
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../access/MaxAccessControl.sol";
import "../lib/Whitelist.sol";

abstract contract WhitelistV2 is MaxAccess {
  using Whitelist for Whitelist.List;
  
  Whitelist.List private whitelist;

  constructor () {}

  function addWhitelist(address newAddress) public onlyDeveloper {
    whitelist.add(newAddress);
  }

  function addBatchWhitelist(address[] memory newAddresses) public onlyDeveloper {
    for(uint x = 0; x < newAddresses.length; x++) {
      whitelist.add(newAddresses[x]);
    }
  }

  function removeWhitelist(address newAddress) public onlyDeveloper {
    whitelist.remove(newAddress);
  }

  function removeBatchWhitelist(address[] memory newAddresses) public onlyDeveloper {
    for(uint x = 0; x < newAddresses.length; x++) {
      whitelist.remove(newAddresses[x]);
    }
  }

  function enableWhitelist() public onlyDeveloper {
    whitelist.enable();
  }

  function disableWhitelist() public onlyDeveloper {
    whitelist.disable();
  }

  // @notice rename this to whatever you want timestamp/quant of tokens sold
  // @dev will set the ending uint of whitelist
  // @param endNumber - uint for the end (quant or timestamp)
  function setEndOfWhitelist(uint endNumber) public onlyDeveloper {
    whitelist.setEnd(endNumber);
  }

  // @dev will return user status on whitelist
  // @return - bool if whitelist is enabled or not
  // @param myAddress - any user account address, EOA or contract
  function myWhitelistStatus(address myAddress) external view returns (bool) {
    return whitelist.onList(myAddress);
  }

  // @dev will return status of whitelist
  // @return - bool if whitelist is enabled or not
  function whitelistStatus() external view returns (bool) {
    return whitelist.status();
  }

  // @dev will return whitelist end (quantity or time)
  // @return - uint of either number of whitelist mints or
  //  a timestamp
  function whitelistEnd() external view returns (uint) {
    return whitelist.showEnd();
  }

  // @dev will return totat on whitelist
  // @return - uint from CountersV2.Count
  function TotalOnWhitelist() external view returns (uint) {
    return whitelist.totalAdded();
  }

  // @dev will return totat used on whitelist
  // @return - uint from CountersV2.Count
  function TotalWhiteListUsed() external view returns (uint) {
    return whitelist.totalRemoved();
  }

  // @dev will return totat used on whitelist
  // @return - uint aka xxxx = xx.xx%
  function WhitelistEfficiency() external view returns (uint) {
    if(whitelist.totalRemoved() == 0) {
      return 0;
    } else {
      return whitelist.totalRemoved() * 1000 / whitelist.totalAdded();
    }
  }
}

/***
 *    ██╗    ██╗██╗  ██╗██╗████████╗███████╗██╗     ██╗███████╗████████╗
 *    ██║    ██║██║  ██║██║╚══██╔══╝██╔════╝██║     ██║██╔════╝╚══██╔══╝
 *    ██║ █╗ ██║███████║██║   ██║   █████╗  ██║     ██║███████╗   ██║   
 *    ██║███╗██║██╔══██║██║   ██║   ██╔══╝  ██║     ██║╚════██║   ██║   
 *    ╚███╔███╔╝██║  ██║██║   ██║   ███████╗███████╗██║███████║   ██║   
 *     ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚═╝╚══════╝   ╚═╝   
 * @title Whitelist
 * @author @MaxFlowO2 on Twitter/GitHub
 *  Written on 12 Jan 2022, post Laid Back Llamas, aka LLAMA TECH!
 * @dev Provides a whitelist capability that can be added to and removed easily. With
 *  a modified version of Countes.sol from openzeppelin 4.4.1 you can track numbers of who's
 *  on the whitelist and who's been removed from the whitelist, showing clear statistics of
 *  your contract's whitelist usage.
 *
 * Include with 'using Whitelist for Whitelist.List;'
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./CountersV2.sol";

library Whitelist {
  using CountersV2 for CountersV2.Counter;

  event WhiteListEndChanged(uint _old, uint _new);
  event WhiteListChanged(bool _old, bool _new, address _address);
  event WhiteListStatus(bool _old, bool _new);

  struct List {
    // These variables should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    bool enabled; //default is false,
    CountersV2.Counter _added; // default 0, no need to _added.set(uint)
    CountersV2.Counter _removed; // default 0, no need to _removed.set(uint)
    uint end; // default 0, this can be time or quant
    mapping(address => bool) _list; // all values default to false
  }

  function add(List storage list, address _address) internal {
    require(!list._list[_address], "Whitelist: Address already whitelisted.");
    // since now all previous values are false no need for another variable
    // and add them to the list!
    list._list[_address] = true;
    // increment counter
    list._added.increment();
    // emit event
    emit WhiteListChanged(false, list._list[_address], _address);
  }

  function remove(List storage list, address _address) internal {
    require(list._list[_address], "Whitelist: Address already not whitelisted.");
    // since now all previous values are true no need for another variable
    // and remove them from the list!
    list._list[_address] = false;
    // increment counter
    list._removed.increment();
    // emit event
    emit WhiteListChanged(true, list._list[_address], _address);
  }

  function enable(List storage list) internal {
    require(!list.enabled, "Whitelist: Whitelist already enabled.");
    list.enabled = true;
    emit WhiteListStatus(false, list.enabled);
  }

  function disable(List storage list) internal {
    require(list.enabled, "Whitelist: Whitelist already enabled.");
    list.enabled = false;
    emit WhiteListStatus(true, list.enabled);
  }

  function setEnd(List storage list, uint newEnd) internal {
    require(list.end != newEnd, "Whitelist: End already set to that value.");
    uint old = list.end;
    list.end = newEnd;
    emit WhiteListEndChanged(old, list.end);
  }

  function status(List storage list) internal view returns (bool) {
    return list.enabled;
  }

  function totalAdded(List storage list) internal view returns (uint) {
    return list._added.current();
  }

  function totalRemoved(List storage list) internal view returns (uint) {
    return list._removed.current();
  }

  function onList(List storage list, address _address) internal view returns (bool) {
    return list._list[_address];
  }

  function showEnd(List storage list) internal view returns (uint) {
    return list.end;
  }
}

/***
 *     ██████╗ ██████╗ ██╗   ██╗███╗   ██╗████████╗███████╗██████╗ ███████╗
 *    ██╔════╝██╔═══██╗██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝
 *    ██║     ██║   ██║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝███████╗
 *    ██║     ██║   ██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗╚════██║
 *    ╚██████╗╚██████╔╝╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║███████║
 *     ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝
 * @title CountersV2
 * @author Matt Condon (@shrugs), and @MaxFlowO2 (edits)
 * @dev Provides counters that can only be incremented, decremented, reset or set. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Edited by @MaxFlowO2 for more NFT functionality on 13 Jan 2022
 * added .set(uint) so if projects need to start at say 1 or some random number they can
 * and an event log for numbers being reset or set.
 *
 * Include with `using CountersV2 for CountersV2.Counter;`
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library CountersV2 {

  event CounterNumberChangedTo(uint _number);

  struct Counter {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    unchecked {
      counter._value += 1;
    }
  }

  function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
    require(value > 0, "Counter: decrement overflow");
    unchecked {
      counter._value = value - 1;
    }
  }

  function reset(Counter storage counter) internal {
    counter._value = 0;
    emit CounterNumberChangedTo(counter._value);
  }

  function set(Counter storage counter, uint number) internal {
    counter._value = number;
    emit CounterNumberChangedTo(counter._value);
  }  
}

/***
 *     █████╗  ██████╗ ██████╗███████╗███████╗███████╗
 *    ██╔══██╗██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝
 *    ███████║██║     ██║     █████╗  ███████╗███████╗
 *    ██╔══██║██║     ██║     ██╔══╝  ╚════██║╚════██║
 *    ██║  ██║╚██████╗╚██████╗███████╗███████║███████║
 *    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝
 * @title Access
 * @author @MaxFlowO2
 * @dev Library function for EIP 173 Ownable standards in EVM, this is useful
 *  for granting role based modifiers, and by using this blah blah blah, you'll
 *  see in the code, currently I feel like death warmed over. Seriously If I kick
 *  the bucket put MaxFlowO2 on my tombstone... please.
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Access {

  event AccessTransferred(address indexed oldAddress, address indexed newAddress);

  struct Role {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    address _active; // who's the active role
    address _pending; // who's the pending role
    // address[] _historical; // array of addresses with the role (useful for "reclaiming" roles)
  }

  function active(Role storage role) internal view returns (address) {
    return role._active;
  }

  function pending(Role storage role) internal view returns (address) {
    return role._pending;
  }

//  function historical(Role storage role) internal view returns (address[] memory) {
  //  return role._historical;
//  }

  function transfer(Role storage role, address newAddress) internal {
    role._pending = newAddress;
  }

  function accept(Role storage role) internal {
//    role._historical.push(role._active);
    address oldAddy = role._active;
    role._active = role._pending;
    role._pending = address(0);
    emit AccessTransferred(
      oldAddy,
      role._active
//      role._historical[role._historical.length - 2],
//      role._historical[role._historical.length - 1]
    );
  }

  function decline(Role storage role) internal {
    role._pending = address(0);
  }

  function push(Role storage role, address newAddress) internal {
//    role._historical.push(role._active);
    address oldAddy = role._active;
    role._active = newAddress;
    emit AccessTransferred(
      oldAddy,
      role._active
//      role._historical[role._historical.length - 2],
//      role._historical[role._historical.length - 1]
    );
  }
}

/***
 *    ███╗   ███╗ █████╗ ██╗  ██╗███████╗██╗      ██████╗ ██╗    ██╗
 *    ████╗ ████║██╔══██╗╚██╗██╔╝██╔════╝██║     ██╔═══██╗██║    ██║
 *    ██╔████╔██║███████║ ╚███╔╝ █████╗  ██║     ██║   ██║██║ █╗ ██║
 *    ██║╚██╔╝██║██╔══██║ ██╔██╗ ██╔══╝  ██║     ██║   ██║██║███╗██║
 *    ██║ ╚═╝ ██║██║  ██║██╔╝ ██╗██║     ███████╗╚██████╔╝╚███╔███╔╝
 *    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝ 
 *                                                                  
 *     █████╗  ██████╗ ██████╗███████╗███████╗███████╗              
 *    ██╔══██╗██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝              
 *    ███████║██║     ██║     █████╗  ███████╗███████╗              
 *    ██╔══██║██║     ██║     ██╔══╝  ╚════██║╚════██║              
 *    ██║  ██║╚██████╗╚██████╗███████╗███████║███████║              
 *    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝              
 *                                                                  
 *     ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  ██████╗ ██╗      
 *    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗██║      
 *    ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║██║      
 *    ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║██║      
 *    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║╚██████╔╝███████╗ 
 *     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝ 
 * @title MaxFlowO2 Access Control
 * @author @MaxFlowO2 on twitter/github
 * @dev this is an EIP 173 compliant ownable plus access control mechanism where you can 
 * copy/paste what access role(s) you need or want. This is due to Library Access, and 
 * using this line of 'using Role for Access.Role' after importing my library
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../lib/Access.sol";
import "../utils/ContextV2.sol";

abstract contract MaxAccess is ContextV2 {
  using Access for Access.Role;

  // events

  // Roles  
  Access.Role private _owner;
  Access.Role private _developer;
  Access.Role private _artist;

  // Constructor to init()
  constructor() {
    _owner.push(_msgSender());
    _developer.push(_msgSender());
    _artist.push(_msgSender());
  }

  // Modifiers
  modifier onlyOwner() {
    require(_owner.active() == _msgSender(), "EIP173: You are not Owner!");
    _;
  }

  modifier onlyNewOwner() {
    require(_owner.pending() == _msgSender(), "EIP173: You are not the Pending Owner!");
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner.active();
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "EIP173: Transfer can not be address(0)");
    _owner.transfer(newOwner);
  }

  function acceptOwnership() public virtual onlyNewOwner {
    _owner.accept();
  }

  function declineOwnership() public virtual onlyNewOwner {
    _owner.decline();
  }

  function pushOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "EIP173: Transfer can not be address(0)");
    _owner.push(newOwner);
  }

  function renounceOwnership() public virtual onlyOwner {
    _owner.push(address(0));
  }

  // Modifiers
  modifier onlyDeveloper() {
    require(_developer.active() == _msgSender(), "EIP173: You are not Developer!");
    _;
  }

  modifier onlyNewDeveloper() {
    require(_developer.pending() == _msgSender(), "EIP173: You are not the Pending Developer!");
    _;
  }

  function developer() public view virtual returns (address) {
    return _developer.active();
  }

  function transferDeveloper(address newDeveloper) public virtual onlyDeveloper {
    require(newDeveloper != address(0), "EIP173: Transfer can not be address(0)");
    _developer.transfer(newDeveloper);
  }

  function acceptDeveloper() public virtual onlyNewDeveloper {
    _developer.accept();
  }

  function declineDeveloper() public virtual onlyNewDeveloper {
    _developer.decline();
  }

  function pushDeveloper(address newDeveloper) public virtual onlyDeveloper {
    require(newDeveloper != address(0), "EIP173: Transfer can not be address(0)");
    _developer.push(newDeveloper);
  }

  function renounceDeveloper() public virtual onlyDeveloper {
    _developer.push(address(0));
  }

  // Modifiers
  modifier onlyArtist() {
    require(_artist.active() == _msgSender(), "EIP173: You are not Artist!");
    _;
  }

  modifier onlyNewArtist() {
    require(_artist.pending() == _msgSender(), "EIP173: You are not the Pending Artist!");
    _;
  }

  function artist() public view virtual returns (address) {
    return _artist.active();
  }

  function transferArtist(address newArtist) public virtual onlyArtist {
    require(newArtist != address(0), "EIP173: Transfer can not be address(0)");
    _artist.transfer(newArtist);
  }

  function acceptArtist() public virtual onlyNewArtist {
    _artist.accept();
  }

  function declineArtist() public virtual onlyNewArtist {
    _artist.decline();
  }

  function pushArtist(address newArtist) public virtual onlyArtist {
    require(newArtist != address(0), "EIP173: Transfer can not be address(0)");
    _artist.push(newArtist);
  }

  function renounceArtist() public virtual onlyArtist {
    _artist.push(address(0));
  }
}