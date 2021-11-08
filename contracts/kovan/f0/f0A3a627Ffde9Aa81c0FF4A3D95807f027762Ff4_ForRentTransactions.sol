/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: ForRentFactory

contract ForRentFactory {
    uint8 reservationPercentage = 20;

    struct ForRent {
        uint256 forRentId;
        string name;
        address lockBoxAddress;
        uint256 price;
        bool reservated;
        bool paid;
    }

    ForRent[] public forRentArray;
    // forRentId => ownerAddress
    mapping(uint256 => address) public forRentToOwner;
    // forRentId => renterAddress
    mapping(uint256 => address) public forRentToRenter;

    function _createForRent(
        string memory _name,
        address _lockBoxAddress,
        uint256 _price
    ) public {
        forRentArray.push(
            ForRent(
                forRentArray.length,
                _name,
                _lockBoxAddress,
                _price,
                false,
                false
            )
        );
        forRentToOwner[forRentArray.length - 1] = msg.sender;
    }

    function _freeForRent(uint256 _forRentId) public {
        //Declare forRent
        ForRent storage forRent = forRentArray[_forRentId];

        //Check if user is the owner
        require(
            forRentToOwner[_forRentId] == msg.sender,
            "Only owner can free"
        );

        //Free
        forRent.reservated = false;
        forRent.paid = false;
        forRentToRenter[_forRentId] = address(
            0x0000000000000000000000000000000000000000
        );
    }
}

// Part: OpenZeppelin/[email protected]/IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: ForRentReservation.sol

contract ForRentTransactions is ForRentFactory {
    IERC20 public drentalToken;

    constructor(address _drentalTokenAddress) public {
        drentalToken = IERC20(_drentalTokenAddress);
    }

    function reserve(uint256 _forRentId) public {
        //Declare forRent element
        ForRent storage forRent = forRentArray[_forRentId];

        //Check if forRent element isn't already reservated
        require(!forRent.reservated, "Oups, already reservated!");

        // Compute the reservation percentage
        uint256 amountExpected = (forRent.price * reservationPercentage) / 100;

        // Check that the user's token balance is enough to do the reservation
        uint256 renterBalance = drentalToken.balanceOf(msg.sender);
        require(
            renterBalance >= amountExpected,
            "Your balance is lower than the amount of tokens needed to reserve"
        );

        // Transaction from renter to owner
        drentalToken.approve(msg.sender, amountExpected + 1);
        bool sent = drentalToken.transferFrom(
            msg.sender,
            forRentToOwner[_forRentId],
            amountExpected
        );
        require(sent, "Failed to transfer tokens from renter to owner");

        // forRent element is now reservated and have a renter
        forRent.reservated = true;
        forRentToRenter[_forRentId] = msg.sender;
    }

    function cancelReservation(uint256 _forRentId) public {
        //Declare forRent element
        ForRent storage forRent = forRentArray[_forRentId];

        //Check if forRent element is reservated
        require(forRent.reservated, "Oups, it isn't reservated!");

        //Check if user is the owner
        require(
            forRentToOwner[_forRentId] == msg.sender,
            "Only the owner can cancel the reservation"
        );

        // Compute the reservation percentage
        uint256 amountExpected = (forRent.price * reservationPercentage) / 100;

        // Check that the user's token balance is enough to refund the reservation
        uint256 renterBalance = drentalToken.balanceOf(msg.sender);
        require(
            renterBalance >= amountExpected,
            "Your balance is lower than the amount of tokens needed to refund the reservation"
        );

        // Transaction from owner to renter
        drentalToken.approve(msg.sender, amountExpected + 1);
        bool sent = drentalToken.transferFrom(
            msg.sender,
            forRentToRenter[_forRentId],
            amountExpected
        );
        require(sent, "Failed to transfer tokens from owner to renter");
        // Now, forRent element isn't reservated and don't have renter
        forRent.reservated = false;
        forRentToRenter[_forRentId] = address(
            0x0000000000000000000000000000000000000000
        );
    }

    function paid(uint256 _forRentId) public {
        //Declare forRent element
        ForRent storage forRent = forRentArray[_forRentId];

        //Check if forRent element is reservated, not already paid and user is renter
        require(forRent.reservated, "Oups, need to reserve first");
        require(!forRent.paid, "Oups, already paid");
        require(
            msg.sender == forRentToRenter[_forRentId],
            "Oups, it's reservated by another renter"
        );

        // Compute price minus reservation percentage
        uint256 amountExpected = forRent.price -
            ((forRent.price * reservationPercentage) / 100);

        // Check that the user's token balance is enough to do the reservation
        uint256 renterBalance = drentalToken.balanceOf(msg.sender);
        require(
            renterBalance >= amountExpected,
            "Your balance is lower than the amount of tokens needed to paid"
        );

        // Transaction from renter to owner
        drentalToken.approve(msg.sender, amountExpected + 1);
        bool sent = drentalToken.transferFrom(
            msg.sender,
            forRentToOwner[_forRentId],
            amountExpected
        );
        require(sent, "Failed to transfer tokens from renter to owner");

        // forRent element is now paid
        forRent.paid = true;
    }
}