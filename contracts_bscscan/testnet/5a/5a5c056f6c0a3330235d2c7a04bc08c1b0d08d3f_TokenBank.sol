/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

contract TokenBank {
    
    // Stores CRASH token
    
    function withdraw(address token, uint256 amount) external {
        (bool success, bytes memory returnData) = token.call(abi.encodeWithSignature("transfer(address, uint256)", msg.sender, amount));
        require(success);
    }
    
}