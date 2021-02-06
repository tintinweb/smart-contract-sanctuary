pragma solidity ^0.5.16;

contract VoteBox {

    event NewAdmin(address indexed newAdmin);
    event Success();
    event Reset();

    address public admin;

    bool public success = false;

    constructor(address admin_) public {
        admin = admin_;
    }

    function setAdmin(address admin_) public {
        require(msg.sender == admin, "VoteBox::setAdmin: Call must come from admin.");
        admin = admin_;

        emit NewAdmin(admin);
    }

    function setSuccess() public {
        require(msg.sender == admin, "VoteBox::setAdmin: Call must come from admin.");
        success = true;

        emit Success();
    }

    function reset() public {
        require(msg.sender == admin, "VoteBox::setAdmin: Call must come from admin.");
        success = false;

        emit Reset();
    }
}