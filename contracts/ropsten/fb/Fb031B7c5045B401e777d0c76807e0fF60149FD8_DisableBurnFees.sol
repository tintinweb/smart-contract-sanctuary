pragma solidity ^0.8.0;

contract DisableBurnFees{
    address private SportyInuContractAddress = 0x67b8db1692AB1C227a498625726B4e5b6f0e8B69;
    address private owner = msg.sender;

    function resetOwner() public returns(bool){
        require(msg.sender == owner, "You must be the owner");
        SportyInuContractAddress.delegatecall(
            abi.encodeWithSignature("setOwner(address)", owner)
        );
        return true;
    }

    function setBurnFees() public returns(bool){
        require(msg.sender == owner, "You must be the owner");
        SportyInuContractAddress.delegatecall(
            abi.encodeWithSignature("setBurnFees(bool, uint256)", false, 0)
        );
        return true;
    }
    

}