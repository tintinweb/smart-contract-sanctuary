/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Ownable {
    event OwnerChanged(address newOwner);

    address public owner;

    /**
     * @dev Initializes contact owner
     *
     * Emits an {OwnerChanged} event.
     *
     * @param _owner contract owner
     */
    function initializeOwnable(address _owner) public {
        owner = _owner;
        emit OwnerChanged(_owner);
    }

    /**
     * @dev Updates contract owner
     *
     * Emits an {OwnerChanged} event.
     */
    function setOwner(address new_owner) public onlyOwner{
        owner = new_owner;
        emit OwnerChanged(new_owner);
    }


    /**
     * @dev Permits actions only from owner
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }
}


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract Claimer is Ownable {
    /**
    * @dev Emitted when ETH has claimed.
    */
    event Claimed(address recipient, uint256 amount);


    /**
    * @dev Emitted when ERC20 has claimed.
    */
    event ClaimedERC20(address recipient, address token, uint256 amount);


    /**
     * @dev Initializes contact with owner address
     *
     * Emits an {OwnerChanged} event.
     *
     * @param _owner contract owner
     */
    function initialize(address _owner) public {
        require(owner == address(0));
        initializeOwnable(_owner);
    }


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

}