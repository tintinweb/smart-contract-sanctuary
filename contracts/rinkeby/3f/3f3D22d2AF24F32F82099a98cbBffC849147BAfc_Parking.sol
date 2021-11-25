// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Parking contract
/// @author Amadej Pevec
/// @notice A contract that allows buying/canceling/transfering parking tickets and verify if tickets are valid. Owner can withdraw funds.
contract Parking is Ownable, Pausable {
    enum ParkingZone {
        A,
        B,
        C
    }

    struct ParkingTicket {
        uint256 expirationTime;
        address buyer;
        ParkingZone zone;
    }

    mapping(ParkingZone => uint256) public zonePricePerMinute;
    mapping(string => ParkingTicket) private parkingTickets;

    event LogTicketBought(
        string indexed plate,
        uint256 numOfMinutes,
        ParkingZone zone
    );
    event LogTicketRenewed(
        string indexed plate,
        uint256 numOfMinutes,
        ParkingZone zone
    );
    event LogTicketCanceled(string indexed plate);
    event LogTicketTransfered(string indexed oldPlate, string newPlate);
    event LogZonePriceChanged(uint256 price, ParkingZone zone);

    /// @notice Check if owner of a ticket is trying to modify it
    /// @param plate The plate of a car that bought a ticket
    modifier isBuyer(string memory plate) {
        require(
            msg.sender == parkingTickets[plate].buyer,
            "Only ticket owner can modify it"
        );
        _;
    }

    constructor() {
        zonePricePerMinute[ParkingZone.A] = 0.00002 ether;
        zonePricePerMinute[ParkingZone.B] = 0.000015 ether;
        zonePricePerMinute[ParkingZone.C] = 0.00001 ether;
    }

    /// @notice Function that allows buying parking ticket or proloning an existing one. Can be called if the contract is not paused.
    /// @param plate The plate of a car
    /// @param numOfMinutes The duration of a parking ticket (in minutes)
    /// @param zone The zone in which a user parked a car (one from ParkingZone enum)
    function buyTicket(
        string memory plate,
        uint256 numOfMinutes,
        ParkingZone zone
    ) external payable whenNotPaused {
        require(
            numOfMinutes * zonePricePerMinute[zone] <= msg.value,
            "Amount is not sufficient"
        );

        ParkingTicket storage ticket = parkingTickets[plate];
        uint256 duration = numOfMinutes * 1 minutes;

        // if ticket not expired yet, then prolong it
        if (ticket.expirationTime > block.timestamp) {
            require(
                ticket.zone == zone,
                "You are trying to renew ticket for other parking zone"
            );
            ticket.expirationTime = ticket.expirationTime + duration;
            emit LogTicketRenewed(plate, numOfMinutes, zone);
        } else {
            uint256 expiration = block.timestamp + duration;
            parkingTickets[plate] = ParkingTicket(expiration, msg.sender, zone);
            emit LogTicketBought(plate, numOfMinutes, zone);
        }
    }

    /// @notice Function to change the parking price of a zone. Can be called by contract owner only.
    /// @param price Price per minute
    /// @param zone The zone for which owner want to set a price (one from ParkingZone enum)
    function changePrice(uint256 price, ParkingZone zone) external onlyOwner {
        zonePricePerMinute[zone] = price;
        emit LogZonePriceChanged(price, zone);
    }

    /// @notice Check if ticket is valid based on the plate and zone
    /// @param plate The plate of a car
    /// @param zone The zone in which the car is parked
    /// @return bool - Return ticket validity
    function isTicketValid(string memory plate, ParkingZone zone)
        public
        view
        returns (bool)
    {
        return
            parkingTickets[plate].zone == zone &&
            parkingTickets[plate].expirationTime > block.timestamp;
    }

    /// @notice Get ticket information
    /// @param plate The plate of a car
    /// @return tuple(Ticket expiration time, zone)
    function getTicket(string memory plate)
        external
        view
        returns (uint256, ParkingZone)
    {
        return (
            parkingTickets[plate].expirationTime,
            parkingTickets[plate].zone
        );
    }

    /// @notice Function to cancel ticket and get back remaining funds. Can be called by ticket owner only.
    /// @dev User get back only 90% of remaining funds
    /// @param plate The plate of a car
    function cancelTicket(string memory plate) external isBuyer(plate) {
        ParkingTicket storage ticket = parkingTickets[plate];
        uint256 minLeft = (ticket.expirationTime - block.timestamp) / 60;
        uint256 balanceLeft = (minLeft * zonePricePerMinute[ticket.zone] * 9) /
            10; // get back 90% of funds

        if (balanceLeft > 0) {
            delete parkingTickets[plate];
            (bool succeed, ) = msg.sender.call{value: balanceLeft}("");
            require(succeed, "Failed to withdraw Ether");
            emit LogTicketCanceled(plate);
        }
    }

    /// @notice Transfer ticket to other owner and car plate. Can be called by ticket owner only.
    /// @param oldPlate The plate user want to transfer
    /// @param newPlate Plate of a car where the ticket will be transfered to
    /// @param newOwner New owner of a ticket (address)
    function transferTicket(
        string memory oldPlate,
        string memory newPlate,
        address newOwner
    ) external isBuyer(oldPlate) {
        require(
            parkingTickets[newPlate].expirationTime <= block.timestamp,
            "You cannot transfer ticket to a plate with active subscription"
        );

        ParkingTicket storage old = parkingTickets[oldPlate];
        parkingTickets[newPlate] = ParkingTicket(
            old.expirationTime,
            newOwner,
            old.zone
        );
        delete parkingTickets[oldPlate];
        emit LogTicketTransfered(oldPlate, newPlate);
    }

    /// @notice Function to pause the contract. Can be called by contract owner only.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Function to unpause the contract. Can be called by contract owner only.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Function to withdraw ether from the contract. Can be called by contract owner only.
    /// @param value Amount of ether that user want to withdraw
    function withdraw(uint256 value) external onlyOwner {
        require(
            value <= address(this).balance,
            "Contract's balance too low to withdraw such amount"
        );
        (bool succeed, ) = msg.sender.call{value: value}("");
        require(succeed, "Failed to withdraw Ether");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}