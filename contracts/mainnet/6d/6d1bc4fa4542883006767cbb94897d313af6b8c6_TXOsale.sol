pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
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
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


/**
 * @title TREON token sale
 * @dev This contract receives money. Redirects money to the wallet. Verifies the correctness of transactions.
 * @dev Does not produce tokens. All tokens are sent manually, after approval.
 */
contract TXOsale is Ownable {

    event ReceiveEther(address indexed from, uint256 value);

    address public TXOtoken = 0xe3e0CfBb19D46DC6909C6830bfb25107f8bE5Cb7;

    bool public goalAchieved = false;

    address public constant wallet = 0x8dA7477d56c90CF2C5b78f36F9E39395ADb2Ae63;
    //  Monday, May 21, 2018 12:00:00 AM
    uint public  constant saleStart = 1526860800;
    // Tuesday, July 17, 2018 11:59:59 PM
    uint public constant saleEnd = 1531871999;

    function TXOsale() public {
    }

    /**
    * @dev fallback function
    */
    function() public payable {
        require(now >= saleStart && now <= saleEnd);
        require(!goalAchieved);
        require(msg.value >= 0.1 ether);
        require(msg.value <= 65 ether);
        wallet.transfer(msg.value);
        emit ReceiveEther(msg.sender, msg.value);
    }

    /**
     * @dev The owner can suspend the sale if the HardCap has been achieved.
     */
    function setGoalAchieved(bool _goalAchieved) public onlyOwner {
        goalAchieved = _goalAchieved;
    }
}