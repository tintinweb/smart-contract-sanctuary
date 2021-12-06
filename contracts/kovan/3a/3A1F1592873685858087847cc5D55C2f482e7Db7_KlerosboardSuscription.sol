//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract KlerosboardSuscription is Ownable {
    /* Events */
    /**
    *  @dev Emitted when the maintainer is changed.
    *  @param oldMaintainer address of the new maintainer.
    *  @param newMaintainer address of the new maintainer.
    */
    event MaintainerChanged(address indexed oldMaintainer, address indexed newMaintainer);

    /**
    *  @dev Emitted when the maintenance fee is changed.
    *  @param maintenanceFeeMultiplier new value of maintainance fee
    */
    event MaintenanceFeeChanged(uint maintenanceFeeMultiplier);

    /**
    *  @dev Emitted when the contract of ubiburner is changed.
    *  @param oldUbiburner address of the old contract.
    *  @param ubiburner address of the new contract.
    */
    event UBIBurnerChanged(address oldUbiburner, address ubiburner);

    /**
    *  @dev Emitted when the amount per month required of donation is changed.
    *  @param oldDonationAmount previous donation Amount
    *  @param donationAmount new donation Amount
    */
    event donationPerMonthChanged(uint256 oldDonationAmount, uint256 donationAmount);

    /**
    *  @dev Emitted when a donation it's made
    *  @param from who made the donation.
    *  @param amount amount of ETH donated.
    *  @param ethToUbiBurner amount of ETH sent to UBI Burner
    */
    event Donation(address indexed from, uint256 amount, uint256 ethToUbiBurner);

    /* Constants */
    /// @dev Contract Maintainer
    address public maintainer;
    /// @dev Maintenance Fee expresed in tens of thousands
    uint public maintenanceFeeMultiplier;
    /// @dev ubiburner Contract
    address public ubiburner;
    /// @dev Amount per month to Enable klerosboard Features
    uint256 public donationPerMonth;
    
    constructor(address _ubiburner, uint _maintenanceFee, uint96 _donationPerMonth) {
        maintainer = msg.sender;
        changeMaintenanceFee(_maintenanceFee);
        changeUBIburner(_ubiburner);
        changeDonationPerMonth(_donationPerMonth);
    }

    /**
    *  @dev Donate ETH
    */
    function donate() payable external {
        uint256 maintenanceFee = msg.value * maintenanceFeeMultiplier / 10000;
        uint256 ETHToBurnUBI = msg.value - maintenanceFee;

        // Send ETH - maintainanceFee to ubiburner
        (bool successTx, ) = ubiburner.call{value: ETHToBurnUBI}("");
        require(successTx, "ETH to ubiburner fail");

        emit Donation(msg.sender, msg.value, ETHToBurnUBI);
    }

    function changeMaintainer (address _maintainer) public onlyOwner {
        require(_maintainer != address(0), 'Maintainer could not be null');
        address oldMaintainer = maintainer;
        maintainer = _maintainer;
        emit MaintainerChanged(oldMaintainer, maintainer);
    }

    function changeMaintenanceFee (uint _newFee) public onlyOwner {
        require(_newFee <= 5000, '50% it is the max fee allowed');
        maintenanceFeeMultiplier = _newFee;
        // express maintainance as a multiplier in tens of thousands .
        emit MaintenanceFeeChanged(maintenanceFeeMultiplier);
    }

    function changeUBIburner (address _ubiburner) public onlyOwner {
        require(_ubiburner != address(0), 'UBIBurner could not be null');
        address oldUbiburner = ubiburner;
        ubiburner = _ubiburner;
        emit UBIBurnerChanged(oldUbiburner, ubiburner);
    }

    function changeDonationPerMonth (uint256 _donationPerMonth) public onlyOwner {
        require(_donationPerMonth > 0, 'donationPerMonth should not be zero');
        uint256 oldDonation = donationPerMonth;
        donationPerMonth = _donationPerMonth;
        emit donationPerMonthChanged(oldDonation, donationPerMonth);
    }

    function withdrawMaintenance() external {
        require(msg.sender == maintainer, 'Only maintainer can withdraw');
        payable(msg.sender).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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