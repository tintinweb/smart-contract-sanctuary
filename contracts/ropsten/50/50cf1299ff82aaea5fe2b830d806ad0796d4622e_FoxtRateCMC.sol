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

contract FoxtRateCMC is Ownable {
    
    address private botAddress;
    uint256 private rate;
    
    function changeBotAddress(address _newBotAddress) public onlyOwner returns(bool) {
        botAddress = _newBotAddress;
        return true;
    }
    
    
    modifier onlyBot {
        require(msg.sender == botAddress);
        _;
    }
    
    
    function updateRate(uint256 _rate) public onlyBot returns(bool){
        require(_rate != 0);
        if(_rate != rate) {
            rate = _rate;
        }
        return true;
    }
    
    function getRate() public view returns(uint256) {
        return rate;
    }
    
}