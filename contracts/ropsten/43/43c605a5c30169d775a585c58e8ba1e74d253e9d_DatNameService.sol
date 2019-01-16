pragma solidity ^0.4.25;

contract Ownable {
    
    address public owner;

    /**
     * The address whcih deploys this contrcat is automatically assgined ownership.
     * */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * Functions with this modifier can only be executed by the owner of the contract. 
     * */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

    /**
    * Transfers ownership to new Ethereum address. This function can only be called by the 
    * owner.
    * @param _newOwner the address to be granted ownership.
    **/
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract DatNameService is Ownable {
    
    mapping (string => string) private datURLs;

    
    function addDat(string _datName, string _URL) public onlyOwner {
        datURLs[_datName] = _URL;
    }
    
    function removeDat(string _datName) public onlyOwner {
        datURLs[_datName] = "";
    }
    
    function getDatURL(string _datName) public view returns(string URL) {
        URL = datURLs[_datName];
    }
}