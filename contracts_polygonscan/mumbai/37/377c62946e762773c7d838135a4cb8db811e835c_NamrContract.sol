/**
 *Submitted for verification at polygonscan.com on 2022-01-03
*/

pragma solidity >=0.7.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract NamrContract is Ownable {
    string private name;
    string private premiumName;

    uint premiumNamePrice = 0.001 ether;

    event onNewName(string name);
    event onPremiumName(string name);

    function setName(string memory newName) public {
        name = newName;
        emit onNewName(name);
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function setPremiumName(string memory newPremiumName) public payable {
        require(msg.value == premiumNamePrice);
        premiumName = newPremiumName;
    }

    function getPremiumName() public view returns (string memory) {
        return premiumName;
    }

    function withdraw() external onlyOwner {
      address payable _owner = address(uint160(owner()));
      _owner.transfer(address(this).balance);
    }
}