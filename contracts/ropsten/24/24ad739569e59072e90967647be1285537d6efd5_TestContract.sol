pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

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

}

contract TestContract is Ownable {

    struct Client {
        uint256 balance;
        bool exists;
    }
    mapping(address => Client) public clientsMap;

    event ClientAdded(address clientAddress);
    event ClientBalanceIncreased(address clientAddress, uint256 amount);
    event OwnerAddEth(uint256 amount);
    event OwnerTransferEth(address to, uint256 amount);

    /**
     * @dev Handles direct clients transactions
     */
    function () public payable {
        Client storage client = clientsMap[msg.sender];
        if (client.exists) {
            client.balance += msg.value;
        } else {
            // Add new element to structure
            clientsMap[msg.sender] = Client(
                msg.value,                          // balance
                true                                // exists
            );
            emit ClientAdded(msg.sender);
        }
        emit ClientBalanceIncreased(msg.sender, msg.value);
    }

    /**
     * @dev Owner can add ETH to contract
     */
    function addEth() public payable onlyOwner {
        emit OwnerAddEth(msg.value);
    }

    /**
     * @dev Owner can transfer ETH from contract to address
     * @param to address
     * @param amount 18 decimals (wei)
     */
    function transferEthTo(address to, uint256 amount) public onlyOwner {
        require(address(this).balance > amount);
        to.transfer(amount);
        emit OwnerTransferEth(to, amount);
    }

    /**
     * @return bool client exist or not
     */
    function isClient(address clientAddress) public view returns(bool) {
        return clientsMap[clientAddress].exists;
    }

    /**
     * @return uint256 client balance
     */
    function getClientBalance(address clientAddress) public view returns(uint256) {
        return clientsMap[clientAddress].balance;
    }
}