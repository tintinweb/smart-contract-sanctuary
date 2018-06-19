pragma solidity ^0.4.19;

/*
@title Address Handle Service aka AHS
@author Ghilia Weldesselasie, founder of D-OZ and genius extraordinaire
@twitter: @ghiliweld, my DMs are open so slide through if you trynna chat ;)

This is a simple alternative to ENS I made cause ENS was too complicated
for me to understand which seemed odd since it should be simple in my opinion.

Please donate if you like it, all the proceeds go towards funding D-OZ, my project.
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract HandleLogic is Ownable {

    uint256 public price; // price in Wei

    mapping (bytes32 => mapping (bytes32 => address)) public handleIndex; // base => handle => address
    mapping (bytes32 => bool) public baseRegistred; // tracks if a base is registered or not
    mapping (address => mapping (bytes32 => bool)) public ownsBase; // tracks who owns a base and returns a bool

    event NewBase(bytes32 _base, address indexed _address);
    event NewHandle(bytes32 _base, bytes32 _handle, address indexed _address);
    event BaseTransfered(bytes32 _base, address indexed _to);

    function registerBase(bytes32 _base) public payable {
        require(msg.value >= price); // you have to pay the price
        require(!baseRegistred[_base]); // the base can&#39;t already be registered
        baseRegistred[_base] = true; // registers base
        ownsBase[msg.sender][_base] = true; // you now own the base
        NewBase(_base, msg.sender);
    }

    function registerHandle(bytes32 _base, bytes32 _handle, address _addr) public {
        require(baseRegistred[_base]); // the base must exist
        require(_addr != address(0)); // no uninitialized addresses
        require(ownsBase[msg.sender][_base]); // msg.sender must own the base
        handleIndex[_base][_handle] = _addr; // an address gets tied to your AHS handle
        NewHandle(_base, _handle, msg.sender);
    }

    function transferBase(bytes32 _base, address _newAddress) public {
        require(baseRegistred[_base]); // the base must exist
        require(_newAddress != address(0)); // no uninitialized addresses
        require(ownsBase[msg.sender][_base]); // .sender must own the base
        ownsBase[msg.sender][_base] = false; // relinquish your ownership of the base...
        ownsBase[_newAddress][_base] = true; // ... and give it to someone else
        BaseTransfered(_base, msg.sender);
    }

    //get price of a base
    function getPrice() public view returns(uint256) {
        return price;
    }

    // search for an address in the handleIndex mapping
    function findAddress(bytes32 _base, bytes32 _handle) public view returns(address) {
        return handleIndex[_base][_handle];
    }

    // check if a base is registered
    function isRegistered(bytes32 _base) public view returns(bool) {
        return baseRegistred[_base];
    }

    // check if an address owns a base
    function doesOwnBase(bytes32 _base, address _addr) public view returns(bool) {
        return ownsBase[_addr][_base];
    }
}


contract AHS is HandleLogic {

    function AHS(uint256 _price, bytes32 _ethBase, bytes32 _weldBase) public {
        price = _price;
        getBaseQuick(_ethBase);
        getBaseQuick(_weldBase);
    }

    function () public payable {} // donations are optional

    function getBaseQuick(bytes32 _base) public {
        require(msg.sender == owner); // Only I can call this function
        require(!baseRegistred[_base]); // the base can&#39;t be registered yet, stops me from snatching someone else&#39;s base
        baseRegistred[_base] = true; // I register the base
        ownsBase[owner][_base] = true; // the ownership gets passed on to me
        NewBase(_base, msg.sender);
    }

    function withdraw() public {
        require(msg.sender == owner); // Only I can call this function
        owner.transfer(this.balance);
    }

    function changePrice(uint256 _price) public {
        require(msg.sender == owner); // Only I can call this function
        price = _price;
    }

}