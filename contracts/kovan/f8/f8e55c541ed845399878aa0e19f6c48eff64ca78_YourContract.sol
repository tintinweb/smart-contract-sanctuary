pragma solidity 0.8.0;

contract YourContract {
    event SetPurpose(address sender, string purpose);
    event Deployed(address adr);

    string public purpose = "Programming Unstoppable Money";

    constructor() public {
        emit Deployed(address(this));
    }

    function setPurpose(string memory newPurpose) public {
        purpose = newPurpose;
        emit SetPurpose(msg.sender, purpose);
    }
}