//SourceUnit: bzAgreement.sol

// Specify version of solidity file (https://solidity.readthedocs.io/en/v0.4.24/layout-of-source-files.html#version-pragma)
pragma solidity >=0.4.23 <0.6.0;

contract BzAgreement {
    
    
    event Registration(address indexed user, address indexed referrer, uint indexed amount);
    
    function registration(address bzOwnerAddress, address referrerAddress, uint256 amount) external payable {
        address(uint160(bzOwnerAddress)).transfer(amount);
        emit Registration(msg.sender, referrerAddress, amount);
    }
    
}