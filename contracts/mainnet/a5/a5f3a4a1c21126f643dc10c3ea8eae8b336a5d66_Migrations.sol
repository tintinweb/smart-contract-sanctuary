pragma solidity 0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * @dev Based on https://github.com/OpenZeppelin/zeppelin-soliditysettable
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Can only be called by the owner");
        _;
    }

    modifier onlyValidAddress(address addr) {
        require(addr != address(0), "Address cannot be zero");
        _;
    }

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner)
        public
        onlyOwner
        onlyValidAddress(newOwner)
    {
        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;
    }
}


/**
 * @title Truffle Migrations contract
 * @dev It violates standard naming convention for compatibility with Truffle suite
 * @dev It extends standard implementation with changeable owner.
 */
contract Migrations is Ownable {
    // solhint-disable-next-line var-name-mixedcase
    uint256 public last_completed_migration;

    function setCompleted(uint256 completed) public onlyOwner {
        last_completed_migration = completed;
    }

    // solhint-disable-next-line func-param-name-mixedcase
    function upgrade(address new_address) public onlyOwner {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}