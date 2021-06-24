/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: MIT
// File: contracts/StorageSlot.sol


/**
 * @dev Copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/StorageSlot.sol
 */

pragma solidity 0.8.4;


library StorageSlot {
    struct AddressSlot {
        address value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// File: contracts/Claimer.sol

pragma solidity ^0.8.4;



interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract Claimer {
    /**
    * @dev Emitted when ETH has claimed.
    */
    event Claimed(address recipient, uint256 amount);


    /**
    * @dev Emitted when ERC20 has claimed.
    */
    event ClaimedERC20(address recipient, address token, uint256 amount);


    /**
     * @dev Storage slot with the admin of the contract.
     *
     * Equals `bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)`.
     */
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;


    /**
     * @dev Transfer all contract ETH to recipient. Only owner can use it
     *
     * Emits an {Claimed} event.
     *
     * @param recipient Account for transfer ETH
     */
    function claim(address payable recipient)  public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = recipient.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit Claimed(recipient, amount);
    }


    /**
     * @dev Transfer all contract amount of specified tokent to recipient. Only owner can use it
     *
     * Emits an {ClaimedERC20} event.
     *
     * @param recipient Account for transfer ERC20 token
     * @param token Address of ERC20 token
     */
    function claimERC20(address payable recipient, address token) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(recipient, amount);
        emit ClaimedERC20(recipient, token, amount);
    }


    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }


    modifier onlyOwner {
        require(msg.sender == _getAdmin(), "Only the contract owner may perform this action");
        _;
    }

}