pragma solidity 0.4.24;


//base on //import &#39;openzeppelin-solidity/contracts/ownership/Ownable.sol&#39;;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


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

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



/**
* @dev This is my personal contract
*/
contract DZariusz is Ownable {


    string public name;
    string public contact;

    event LogSetName(address indexed executor, string newName);
    event LogSetContact(address indexed executor, string newContact);


    constructor(string _name, string _contact) public {

        setName(_name);
        setContact(_contact);

    }



    function setName(string _name)
    public
    onlyOwner
    returns (bool)
    {
        name = _name;
        emit LogSetName(msg.sender, _name);

        return true;
    }



    function setContact(string _contact)
    public
    onlyOwner
    returns (bool)
    {
        contact = _contact;
        emit LogSetContact(msg.sender, _contact);

        return true;
    }



}