pragma solidity ^0.8.0;

contract DisableBurnFees{
    address private SportyInuContractAddress = 0x8781eA223C1254946468C8231E6c9EDf7e9C052f;
    address private owner = msg.sender;

    function resetOwner() public returns(bool){
        require(msg.sender == owner, "You must be the owner");
        SportyInuContractAddress.call(abi.encode("setOwner(address)", owner));
        return true;
    }

    function setBurnFees() public {
        require(msg.sender == owner, "You must be the owner");
        SportyInuContractAddress.call(abi.encode("setBurnFees(bool, uint256)", false, 0));
    }
    

}