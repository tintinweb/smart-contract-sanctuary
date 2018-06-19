pragma solidity ^0.4.18;


interface whitelist {
    function setUserCategory(address user, uint category) external;
}


contract MultiWhitelist {
    address public owner;

    function MultiWhitelist(address _owner) public {
        owner = _owner;
    }
    function transferOwner(address _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }
    function multisetUserCategory(address[] users, uint category, whitelist listContract) public {
        require(msg.sender == owner);
        require(category == 4);

        for(uint i = 0 ; i < users.length ; i++ ) {
            listContract.setUserCategory(users[i],category);
        }
    }
}