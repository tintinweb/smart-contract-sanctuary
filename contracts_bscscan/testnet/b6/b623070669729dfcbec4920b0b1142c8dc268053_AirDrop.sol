/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

pragma solidity =0.8.7;

contract AirDrop {
    address public token;
    mapping(address => uint256) public balanceOf;

    constructor() {
        token = address(0xD1c76Bb0Ba2Ecc1d438600ef83289A8D2081aA71); 

        balanceOf[0x7D9049dd682C9F9A39737666C0c1C020d97DD190] = 300;
        balanceOf[0xC768a6Eed0eD2D6f6EBD837588f48C8457A2AEF9] = 300;
    }

    function claim() public {
        uint256 b = balanceOf[msg.sender];
        require(b > 0, "Cannot claim");
        safeTransfer(msg.sender, b * 10**18);
        balanceOf[msg.sender] = 0;
    }

    function safeTransfer(address _to, uint256 _value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, _to, _value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }
}