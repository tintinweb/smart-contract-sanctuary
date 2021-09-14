/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

pragma solidity >=0.8.6 <0.9.0;

contract QuickPunk {
    address private owner;

    uint256 private registerPrice;
    mapping(address => bool) private registeredUsers;

    constructor() {
        owner = msg.sender;
        registerPrice = 0.02 ether;
    }

    // Getters

    function getRegisterPrice() external view returns (uint256) {
        return (registerPrice);
    }

    function getOwner() external view returns (address) {
        return (owner);
    }

    function isAddressRegistered(address _account)
        external
        view
        returns (bool)
    {
        return (registeredUsers[_account]);
    }

    // Setters
    function setOwner(address _owner) external {
        require(msg.sender == owner, "Function only callable by owner!");

        owner = _owner;
    }

    function setRegisterPrice(uint256 _registerPrice) external {
        require(msg.sender == owner, "Function only callable by owner!");

        registerPrice = _registerPrice;
    }

    // Register functions
    receive() external payable {
        register();
    }

    function register() public payable {
        require(!registeredUsers[msg.sender], "Address already registered!");
        require(
            msg.value >= registerPrice,
            "Register price is lower than expected"
        );

        registeredUsers[msg.sender] = true;
    }

    // Withdraw Ether
    function withdraw(uint256 _amount, address _receiver) external {
        require(msg.sender == owner, "Function only callable by owner!");

        payable(_receiver).transfer(_amount);
    }
}