/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

pragma solidity <=0.6.6;

contract Dustdex7 {
    string public name = "Dustdex7";
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transferFrom(address,address,uint256)'))), from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }


    function stakeTokens(address _token, uint _amount) public {
        // Require amount greater than 0
        require(_amount > 0, "amount cannot be 0");

        // Trasnfer Mock Dai tokens to this contract for staking
        safeTransferFrom(_token, msg.sender, address(this), _amount);
    }
}