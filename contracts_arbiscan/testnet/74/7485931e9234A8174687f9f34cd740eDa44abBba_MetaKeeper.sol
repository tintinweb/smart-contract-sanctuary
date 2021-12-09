pragma solidity ^0.8.0;


contract MetaKeeper {
    event Test(
        address indexed sender
    );
    
    address public owner;
    mapping(address => bool) public permitted;

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
         _;
    }

    modifier onlyPermitted() {
        require(permitted[msg.sender] == true, "NOT_PERMITED");
         _;
    }


    constructor(){
        owner = msg.sender;
        permitted[msg.sender] = true;
    }

    function permit(address _new) external onlyOwner
    {
        permitted[_new] = true;
    }

    function forbid(address _old) external onlyOwner
    {
        permitted[_old] = false;
    }

    function test() external onlyPermitted{
        emit Test(
            msg.sender
        );
    }

}