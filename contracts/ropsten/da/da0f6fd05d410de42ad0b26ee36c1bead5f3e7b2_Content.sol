pragma solidity ^0.4.23;

// File: contracts/ContentManagerInterface.sol

contract ContentManagerInterface {
    function accept() public view returns (string);

    function reject() public view returns (string);
}

// File: contracts/Content.sol

contract Content {

    ContentManagerInterface public cm;

    constructor(address _contentManager) public {
        require(_contentManager != address(0));

        cm = ContentManagerInterface(_contentManager);
        emit Create(_contentManager);
    }

    function accept() public view returns (string) {
        return cm.accept();
    }

    event Create(address _address);
}