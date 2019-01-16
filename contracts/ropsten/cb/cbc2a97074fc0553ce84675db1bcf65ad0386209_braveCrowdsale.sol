pragma solidity 0.4.24;

contract braveCrowdsale {
    address public master;
    mapping (address => bool) public whitelistedAddress;
    event Receive(address indexed from, address indexed to, uint value);
    event ChangeMaster(address oldMaster, address newMaster);
    event Whitelist(address indexed master, address indexed addr, bool status);
    
    constructor(address _master) public {
        master = _master;
        whitelistedAddress[_master] = true;
    }
    
    modifier onlyMaster() {
        require(msg.sender == master);
        _;
    }
    
    modifier onlyWhitelisted() {
        require(whitelistedAddress[msg.sender] == true);
        _;
    }
    
    function () onlyWhitelisted public payable {
        require(msg.value > 0);
        master.transfer(msg.value);
        emit Receive(msg.sender, master, msg.value);
    }
    
    function changeMaster(address _newMaster) onlyMaster public {
        require(_newMaster != address(0));
        master = _newMaster;
        emit ChangeMaster(msg.sender, _newMaster);
    }
    
    function addWhitelist(address _address) onlyMaster public {
        require(whitelistedAddress[_address] == false);
        whitelistedAddress[_address] = true;
        emit Whitelist(master, _address, true);
    }
    
    function removeFromWhitelist(address _address) onlyMaster public {
        require(whitelistedAddress[_address] == true);
        whitelistedAddress[_address] = false;
        emit Whitelist(master, _address, false);
    }
}