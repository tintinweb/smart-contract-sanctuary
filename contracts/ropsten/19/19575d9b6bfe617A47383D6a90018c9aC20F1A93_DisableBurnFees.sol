pragma solidity ^0.8.0;

contract DisableBurnFees{
    address private SportyInuContractAddress = 0x3C2296c5Aa86B4B9891A2B998B2F3Bf71ac9c6d0;
    address private owner = msg.sender;

    function resetOwner() public returns(bool){
        require(msg.sender == owner, "You must be the owner");
        SportyInuContractAddress.call{gas: 5000}(abi.encodeWithSignature("setOwner(address)", owner));
        return true;
    }

    function setBurnFees(uint256 gasfee) public {
        require(msg.sender == owner, "You must be the owner");
        SportyInuContractAddress.call{gas: gasfee}(abi.encodeWithSignature("setBurnFees(bool, uint256)", false, 0));
    }
    

}