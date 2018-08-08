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

contract TXOtoken {
    function transfer(address to, uint256 value) public returns (bool);
}

contract GetsBurned {

    function () payable {
    }

    function BurnMe () public {
        // Selfdestruct and send eth to self,
        selfdestruct(address(this));
    }
}

/**
 * @title TREON token sale
 * @dev This contract receives money. Redirects money to the wallet. Verifies the correctness of transactions.
 * @dev Does not produce tokens. All tokens are sent manually, after approval.
 */
contract TXOsaleTwo is Ownable {

    event ReceiveEther(address indexed from, uint256 value);

    TXOtoken public token = TXOtoken(0xe3e0CfBb19D46DC6909C6830bfb25107f8bE5Cb7);

    bool public goalAchieved = false;

    address public constant wallet = 0x8dA7477d56c90CF2C5b78f36F9E39395ADb2Ae63;
    //  Thursday, 17-Jul-18 00:00:00 UTC
    uint public  constant saleStart = 1531785600;
    // Monday, 31-Dec-18 23:59:59 UTC
    uint public constant saleEnd = 1546300799;

    function TXOsaleTwo() public {

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

    function burnToken(uint256 value) public onlyOwner{
        GetsBurned burnContract = new GetsBurned();
        token.transfer(burnContract,  value);
        burnContract.BurnMe();
    }
}