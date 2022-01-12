/**
 *Submitted for verification at snowtrace.io on 2022-01-11
*/

// SPDX-License-Identifier: --🌲--

pragma solidity ^0.8.0;

/**
 * @title Treedefi Farmers Cashback Version 1.0
 *
 * @author treedefi
 */
contract FarmersCashbackV1 {
    
    // Address of an owner
    address public owner;

    //-----Cashback parameters-----//
    bool public isCashbackActive;

    uint256 public cashbackAmount;

    uint256 public receivers;

    uint256 public claimedAmount;

    // Mapping from address to cashback amount
    mapping(address => uint256) public cashback;

    // Mapping from address to claimed amount
    mapping(address => bool) public isClaimed;
    
    /**
	 * @dev Fired in transferOwnership() when ownership is transferred
	 *
	 * @param _previousOwner an address of previous owner
	 * @param _newOwner an address of new owner
	 */
    event OwnershipTransferred(
        address indexed _previousOwner,
        address indexed _newOwner
    );

    /**
	 * @dev Fired in claim() when cashback is claimed
	 *
	 * @param _by an address to whom cashback is claimed 
	 * @param _amount cashback amount
     * @param _at timestamp of claim
	 */
    event Claimed(
        address indexed _by,
        uint256 _amount,
        uint256 _at
    );

    /**
	 * @dev Creates/deploys Treedefi Farmers Cashback Version 1.0
	 *
	 * @param owner_ address of owner
	 */
    constructor(address owner_) {
        
        // Record owner address
        owner = owner_;

    }

    /**
	 * @dev Transfer ownership to given address
	 *
	 * @notice restricted function, should be called by owner only
	 * @param newOwner_ address of new owner
	 */
    function transferOwnership(address newOwner_) external {
        
        require(msg.sender == owner, "Treedefi: only owner can transfer ownership");

        // Update owner address
        owner = newOwner_;

        // Emits an event
        emit OwnershipTransferred(msg.sender, newOwner_);
        
    }

    /**
	 * @dev Activates cashback claiming
	 *
	 * @notice restricted function, should be called by owner only
	 */
    function activeCashback() external {
        
        require(
            msg.sender == owner,
            "Treedefi: Invalid access"
        );

        // Activate cashback
        isCashbackActive = true;

    }

    /**
	 * @dev Pauses cashback claiming
	 *
	 * @notice restricted function, should be called by owner only
	 */
    function pauseCashback() external {
        
        require(
            msg.sender == owner,
            "Treedefi: Invalid access"
        );

        // Pause cashback
        isCashbackActive = false;
        
    }

    /**
	 * @dev Adds beneficiary details
	 *
	 * @notice restricted function, should be called by owner only
     *
	 * @param to_ array containing beneficiary addresses to be added
     * @param amount_ array contains beneficiary amount
	 */
    function addToCashback(address[] memory to_, uint256[] memory amount_) external {

        require(
            msg.sender == owner,
            "Treedefi: Invalid access"
        );

        require(
            to_.length == amount_.length,
            "Treedefi: Invalid inputs"
        );

        for(uint i; i < to_.length; i++) {
        
            require(
                cashback[to_[i]] == 0,
                "Treedefi: Duplicate entry"
            );

            // Add cashback for given address
            cashback[to_[i]] = amount_[i];

            // Increment total cashback counter by given amount
            cashbackAmount = cashbackAmount + amount_[i];

            // Increment receiver counter
            receivers++;

        }

    }

    /**
	 * @dev Removes beneficiary details
	 *
	 * @notice restricted function, should be called by owner only
     *
	 * @param to_ array containing beneficiary addresses to be removed
     */
    function removeFromCashback(address[] memory to_) external {

        require(
            msg.sender == owner,
            "Treedefi: Invalid access"
        );

        for(uint i; i < to_.length; i++) {
        
            require(
                !isClaimed[to_[i]],
                "Treedefi: Claimed already"
            );

            // Decrement total cashback counter by given amount 
            cashbackAmount = cashbackAmount - cashback[to_[i]];

            // Remove cashback for given address
            cashback[to_[i]] = 0;

            // Decrement receiver counter
            receivers--;

        }

    }

    /**
	 * @dev Deposits amount to be given in cashback
	 */
    function depositCashback() external payable {}

    /**
	 * @dev Withdraw amount from cashback contract
	 *
	 * @notice restricted function, should be called by owner only
     *
	 * @param amount_ amount to be withdrawn
	 */
    function withdraw(uint256 amount_) external {
      
        require(
            msg.sender == owner,
            "Treedefi: Only Owner can withdraw funds"
        );
        
        // Withdraw given amount to owner
	    payable(owner).transfer(amount_);
  
    }

    /**
	 * @dev Claims cashback amount for sender
	 */
    function claim() external {
        
        require(
            isCashbackActive,
            "Treedefi: Cashback not active"
        );

        require(
            !isClaimed[msg.sender],
            "Treedefi: Claimed already"
        );

        require(
            cashback[msg.sender] > 0,
            "Treedefi: No cashback"
        );

        // Transfer cashback to given address
        payable(msg.sender).transfer(cashback[msg.sender]);

        // Update claimed status
        isClaimed[msg.sender] = true;

        // Increment claimed amount counter by given amount
        claimedAmount = claimedAmount + cashback[msg.sender];

        // Emits an event
        emit Claimed(msg.sender, cashback[msg.sender], block.timestamp);

    }

}