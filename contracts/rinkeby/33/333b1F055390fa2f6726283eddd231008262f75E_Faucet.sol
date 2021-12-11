/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
// File: contracts/Fault.sol



pragma solidity ^0.8.6;


/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Faucet {

    uint256 public withdrawLimit;
    mapping(address => bool) public addressLimit;
    address public owner;
    address public tokenAddress;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WithdrawToken(address user, uint256 amount);
    
    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        withdrawLimit = 5000000000000000000000;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    
    function withdrawToken () public {
        require(!addressLimit[msg.sender], 'did withdraw');
        
        addressLimit[msg.sender] = true;
        TransferHelper.safeTransfer(tokenAddress, msg.sender, withdrawLimit);
        emit WithdrawToken(msg.sender, withdrawLimit);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner{
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function withdrawAllToken (uint256 vault) public onlyOwner  {
        TransferHelper.safeTransfer(tokenAddress, owner, vault);
        emit WithdrawToken(owner, vault);
    }
}