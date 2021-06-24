/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity 0.5.4;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

contract XFLAirdrop is Ownable {
    
    address public contractAddress;
    
    function setContractAddress(address _contractAddress) external onlyOwner {
        contractAddress = _contractAddress;
    }
    
    function sendToMultipleAddresses(address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            IERC20(contractAddress).transfer(_addresses[i],_amounts[i]);
        }
    }
    
    function withdrawTokens() external onlyOwner {
        IERC20(contractAddress).transfer(msg.sender,IERC20(contractAddress).balanceOf(address(this)));
    }
}