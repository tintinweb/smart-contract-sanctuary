/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity ^0.4.16;

contract Ownable {
    address public owner;

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


contract Pausable is Ownable {
    bool public paused = false;

    event Pause();
    event Unpause();

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}


contract Register is Pausable {
    mapping(address => string) public registry;

    // map 中添加新用户相关信息, eth 地址为合约调用者,仅未暂停状态下可以调用
    function addUser(string info) public whenNotPaused {
        registry[msg.sender] = info;
    }
   
    //返回 map 中eth 地址对应的信息
    function getInfo(address ethAddress) public constant returns (string) {
        return registry[ethAddress];
    }
}