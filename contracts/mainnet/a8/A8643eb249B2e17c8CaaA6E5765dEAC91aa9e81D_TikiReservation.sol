//SPDX-License-Identifier: MIT

/*

 ____                     __               __          ______    __              ______           __                
/\  _`\                  /\ \__         __/\ \        /\__  _\__/\ \      __    /\__  _\       __/\ \               
\ \ \L\ \     __     __  \ \ ,_\   ___ /\_\ \ \/'\    \/_/\ \/\_\ \ \/'\ /\_\   \/_/\ \/ _ __ /\_\ \ \____     __   
 \ \  _ <'  /'__`\ /'__`\ \ \ \/ /' _ `\/\ \ \ , <       \ \ \/\ \ \ , < \/\ \     \ \ \/\`'__\/\ \ \ '__`\  /'__`\ 
  \ \ \L\ \/\  __//\ \L\.\_\ \ \_/\ \/\ \ \ \ \ \\`\      \ \ \ \ \ \ \\`\\ \ \     \ \ \ \ \/ \ \ \ \ \L\ \/\  __/ 
   \ \____/\ \____\ \__/.\_\\ \__\ \_\ \_\ \_\ \_\ \_\     \ \_\ \_\ \_\ \_\ \_\     \ \_\ \_\  \ \_\ \_,__/\ \____\
    \/___/  \/____/\/__/\/_/ \/__/\/_/\/_/\/_/\/_/\/_/      \/_/\/_/\/_/\/_/\/_/      \/_/\/_/   \/_/\/___/  \/____/
                                                                                                                                                                                                                                        
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract TikiReservation is Ownable {

    using Counters for Counters.Counter;

    event TikiReserved(address _address);
    
    mapping (address => bool) public allowedToSend;
    mapping (address => uint256) public reservedTikis;

    uint256 public reservationFee;
    uint256 public maxReservedTikis;

    Counters.Counter private _totalReservations;
    Counters.Counter private _totalAddresses;

    constructor () {
        reservationFee = 0.08 ether;
        maxReservedTikis = 1;
    }
    
    function addAddress(address _address) public onlyOwner {
        require(_address != address(0), "Cannot add null address");
        require(!allowedToSend[_address], "Address already in whitelist");
        
        allowedToSend[_address] = true;
        _totalAddresses.increment();  
    }

    function removeAddress(address _address) public onlyOwner {
        require(_address != address(0), "Cannot remove null address");
        require(allowedToSend[_address], "Address not in whitelist");
        
        allowedToSend[_address] = false;
        _totalAddresses.decrement();
    }

    function bulkaddAddresses(address[] calldata _addresses) public onlyOwner {
        for (uint i=0; i<_addresses.length; i++) {
            
            address _address = _addresses[i];
            
            if (!allowedToSend[_address] && _address != address(0)) {
                allowedToSend[_address] = true;
                _totalAddresses.increment();
            }

        }
            
    }

    function setReservationFee(uint256 _fee) public onlyOwner {
        reservationFee = _fee;
    }

    function setMaxReservedTikis(uint256 _tikis) public onlyOwner {
        maxReservedTikis = _tikis;
    }

    function getTotalReservations() public view onlyOwner returns (uint256) {
        return _totalReservations.current();
    }

    function getTotalAddresses() public view onlyOwner returns (uint256) {
        return _totalAddresses.current();
    }

    function isAddressAllowed(address _address) public view returns (bool) {
        return allowedToSend[_address];
    }

    function getTikisReservedBy(address _address) public view returns (uint256) {
        return reservedTikis[_address];
    }

    function getAddressStatus(address _address) public view returns (bool, uint256) {
        return (allowedToSend[_address], reservedTikis[_address]);
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    
    function reserveTiki() public payable {

        address _sender = _msgSender();
        require(allowedToSend[_sender], "Sender is not in allowed list");
        require(reservedTikis[_sender] < maxReservedTikis, "Cannot reserve any more tikis");
        require(msg.value >= reservationFee, "Insufficient funds to reserve tiki");

        address payable _payableSender = payable(_sender);
        _payableSender.transfer(msg.value - reservationFee);

        reservedTikis[_sender] += 1;
        _totalReservations.increment();

        emit TikiReserved(_sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}