// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import './Ownable.sol';


contract PassSale is Ownable{
    using Counters for Counters.Counter;
    
    Counters.Counter private _passesSold;
    uint public passCost = 0.1 ether; //cost for the pass
    uint public maxPassesAllowed = 5; //passes allowed per address
    uint public numberOfPassesOwned; // # of Treasure Pass Owners
    bool public passesOnSale; // Are passes on sale?
    address payable private projectWallet; //project wallet address
    mapping (address => uint) public passOwners; //list for pass owners amount
    mapping (address => bool) public freePassList; // addresses on freePassList

    event PassesPurchased(address indexed purchaser, uint amount);
    event ReceiveCalled(address _caller, uint _value);

    modifier costs(uint amount){
        require(msg.value >= amount, "Not enough ether sent for pass");
        _;
        if(msg.value > amount){
            (bool success, ) = payable(msg.sender).call{value : msg.value - amount}("");
            require(success, "transaction not successful");
        }
    }

    constructor(address payable _withdrawalWallet){
        projectWallet = _withdrawalWallet;
        }

    receive() external payable {
        emit ReceiveCalled(msg.sender, msg.value);
    }

    function purchasePass(uint _numPasses) public payable costs(passCost*_numPasses){
        require(passesOnSale, "passes are not on sale yet");
        require(passOwners[msg.sender] + _numPasses <= maxPassesAllowed, "cannot purchase this many passes");
        require(numberOfPassesOwned + _numPasses <= 1000, "All 1,000 passes already claimed!");
        passOwners[msg.sender] += _numPasses;
        numberOfPassesOwned += _numPasses;
        emit PassesPurchased(msg.sender, _numPasses);
        
    }

    function noCostUserPass(uint _numPasses) public{
        require(passesOnSale, "passes are not on sale yet");
        require(freePassList[msg.sender], "not on free pass list");
        require(passOwners[msg.sender] + _numPasses <= maxPassesAllowed, "cannot purchase this many passes");
        require(numberOfPassesOwned + _numPasses <= 1000, "All 1,000 passes already claimed!");
        passOwners[msg.sender] += _numPasses;
        numberOfPassesOwned += _numPasses;
        emit PassesPurchased(msg.sender, _numPasses);
    }

    function ownerPaysUserPass(address _freePass, uint _numPasses) public onlyOwner{
        require(passesOnSale, "passes are not on sale yet");
        require(passOwners[_freePass] + _numPasses <= maxPassesAllowed, "cannot purchase this many passes");
        require(numberOfPassesOwned + _numPasses <= 1000, "All 1,000 passes already claimed!");
        passOwners[_freePass] += _numPasses;
        numberOfPassesOwned += _numPasses;
        emit PassesPurchased(_freePass, _numPasses);
    }

    function setCost(uint _amount) public onlyOwner{
        passCost = _amount;
    }

    function setPassesOnSale() public onlyOwner{
        require(!passesOnSale, "already on sale");
        passesOnSale = true;
    }

    function setNewWallet(address payable _newWallet) public onlyOwner{
        projectWallet = _newWallet;
    }

    function setMaxPassesAllowed(uint _amount) public onlyOwner{
        maxPassesAllowed = _amount;
    }

    function addToFreePassList(address[] memory _passList) public onlyOwner{
        for(uint i=0; i<_passList.length; i++){
            if(!freePassList[_passList[i]]){
                freePassList[_passList[i]]=true;
            }
        }
    }

    function pausePasses() public onlyOwner{
        require(passesOnSale, "not on sale");
        passesOnSale = false;
    }

    function transferToWallet() public onlyOwner {
        (bool success, ) = projectWallet.call{value: address(this).balance}("");
        require(success, "transaction not successful");
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