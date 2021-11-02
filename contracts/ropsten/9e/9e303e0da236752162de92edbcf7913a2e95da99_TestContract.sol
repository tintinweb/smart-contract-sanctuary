/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

pragma solidity >=0.7.0 <0.9.0;


contract TestContract {

    address owner;
    
    modifier onlyowner {
        require(owner == msg.sender);
        _;
    }

     function withdraw(address usdtContractAddress, address receiver, uint256 amount) public {
        bytes memory payload = abi.encodeWithSignature("transfer(address, uint256)", receiver, amount);
        (bool success, ) = usdtContractAddress.call(payload);
        require(success);
     }
}