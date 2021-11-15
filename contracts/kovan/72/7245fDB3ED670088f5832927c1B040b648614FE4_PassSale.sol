// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import './Ownable.sol';


contract PassSale is Ownable{
    using Counters for Counters.Counter;
    
    Counters.Counter private _passesSold;
    uint public passCost = 0.1 ether; //cost for the pass
    uint public numberOfPassOwners; // # of Treasure Pass Owners
    bool public passesOnSale; // Are passes on sale?
    address payable private projectWallet; //project wallet address
    mapping (address => bool) public passOwners; //list for pass owners

    event PassPurchased(address indexed purchaser);
    event ReceiveCalled(address _caller, uint _value);

    modifier costs(uint amount){
        require(msg.value >= amount, "Not enough ether sent for pass");
        _;
        if(msg.value > amount){
            payable(msg.sender).transfer(msg.value - amount);
        }
    }

    constructor(address payable _withdrawalWallet) public{
        projectWallet = _withdrawalWallet;
        }

    receive() external payable {
        emit ReceiveCalled(msg.sender, msg.value);
    }

    function purchasePass() public payable costs(passCost){
        require(passesOnSale, "passes are not on sale yet");
        require(!passOwners[msg.sender], "already purchased a pass");
        require(numberOfPassOwners <1000, "All 1,000 passess already claimed!");
        passOwners[msg.sender] = true;
        numberOfPassOwners++;
        emit PassPurchased(msg.sender);
        
    }

    function setCost(uint _amount) public isOwner{
        passCost = _amount;
    }

    function setPassesOnSale() public isOwner{
        require(!passesOnSale, "already on sale");
        passesOnSale = true;
    }

    function pausePasses() public isOwner{
        require(passesOnSale, "not on sale");
        passesOnSale = false;
    }

    function transferToWallet() public isOwner {
        projectWallet.transfer(address(this).balance);
    }
}

pragma solidity >=0.5.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
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

