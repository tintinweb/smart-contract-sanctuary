pragma solidity ^0.4.24;

contract Whitelist {
    address public owner;
    mapping(address => uint256) public whitelist;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Whitelisted(address indexed who);

    uint256 public nextUserId = 1;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function addAddress(address who) external onlyOwner {
        require(who != address(0));
        require(whitelist[who] == 0);
        whitelist[who] = nextUserId;
        nextUserId++;
        emit Whitelisted(who); // solhint-disable-line
    }

    function addAddresses(address[] addresses) external onlyOwner {
        require(addresses.length <= 100);
        address who;
        uint256 userId = nextUserId;
        for (uint256 i = 0; i < addresses.length; i++) {
            who = addresses[i];
            require(whitelist[who] == 0);
            whitelist[who] = userId;
            userId++;
            emit Whitelisted(who); // solhint-disable-line
        }
        nextUserId = userId;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
       require(_newOwner != address(0));
       emit OwnershipTransferred(owner, _newOwner);
       owner = _newOwner;
    }
}