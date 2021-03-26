/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity 0.6.4;

/**
 * @title Manage the owner for the BulkSender contract.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(this), _owner);
    }

    /**
     * Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: the caller is not the owner");
        _;
    }

    /**
     * Sets the new address as the owner.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0), "Ownable: the new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Sending bulk transactions from the whitelisted wallets.
 */
contract BulkSender is Ownable {

    mapping(address => bool) whitelist;

    /**
     * Throws if called by any account other than the whitelisted address.
     */
    modifier onlyWhiteListed() {
        require(whitelist[msg.sender], "Whitelist: the caller is not whitelisted");
        _;
    }

    /**
     * Approves the address as the whitelisted address.
     */
    function approve(address addr) onlyOwner external {
        whitelist[addr] = true;
    }

    /**
     * Removes the whitelisted address from the whitelist.
     */
    function remove(address addr) onlyOwner external {
        whitelist[addr] = false;
    }

    /**
     * Returns true if the address is the whitelisted address.
     */
    function isWhiteListed(address addr) public view returns (bool) {
        return whitelist[addr];
    }

    /**
     * @dev Gets the list of addresses and the list of amounts to make bulk transactions.
     * @param addresses - address[]
     * @param amounts - uint256[]
     */
    function distribute(address[] calldata addresses, uint256[] calldata amounts) onlyWhiteListed external payable  {
        require(addresses.length > 0, "BulkSender: the length of addresses should be greater than zero");
        require(amounts.length == addresses.length, "BulkSender: the length of addresses is not equal the length of amounts");

        for (uint256 i; i < addresses.length; i++) {
            uint256 value = amounts[i];
            require(value > 0, "BulkSender: the value should be greater then zero");
            address payable _to = address(uint160(addresses[i]));
            _to.transfer(value);
        }

        require(address(this).balance == 0, "All received funds must be transfered");
    }

    /**
     * @dev This contract shouldn't accept payments.
     */
    receive() external payable {
        revert("This contract shouldn't accept payments.");
    }

}