/**
 *Submitted for verification at BscScan.com on 2021-10-06
*/

contract TokenBank {
    
    // Stores CRASH token
    
    address token = 0x985B7575508993ec153442F6d7D5f79b1e530681;

    
    function withdraw(uint256 amount) external {
        (bool success, bytes memory returnData) = token.call(abi.encodeWithSignature("transfer(address, uint256)", msg.sender, amount));
        require(success);
    }
    
}