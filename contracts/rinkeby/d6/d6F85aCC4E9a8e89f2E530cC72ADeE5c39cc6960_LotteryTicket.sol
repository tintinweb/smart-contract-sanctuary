/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// Part: ILotto

interface ILotto {
    function getCharityAddresses() external returns (address[] memory);

    function getTicketHolder(address _address)
        external
        returns (address[] memory);

    function getLottoStatus() external view returns (bool);

    function getWinner() external view returns (address);

    function isWinnerAboveTwoFifty(address _owner) external view returns (bool);

    function isHolderAboveTwoFifty(address _owner) external view returns (bool);

    function isWinnerBelowTwoFifty(address _owner) external view returns (bool);

    function isHolderBelowTwoFifty(address _owner) external view returns (bool);

    function getWinningCharityAddress() external view returns (address);

    function getOrganizer() external returns (address);

    function getCurrentHolders() external view returns (uint256);

    function getMaxTickets() external view returns (uint256);

    function getTicketsLeft() external view returns (uint256);

    function getPotValue() external view returns (uint256);

    function getWinnersBelowTwoFiftyPayoutValue()
        external
        view
        returns (uint256);

    function getWinnersAboveTwoFiftyPayoutValue()
        external
        view
        returns (uint256);

    function getDubFamNFTsPayout() external view returns (uint256);

    function getWinnerPayoutValue() external view returns (uint256);

    function geDonationPayoutValue() external view returns (uint256);
}

// Part: openzeppelin/[email protected]/Context

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

// Part: openzeppelin/[email protected]/Ownable

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

// File: LotteryTicket.sol

contract LotteryTicket is Ownable {
    address lottoAddress;
    uint256 public holderNumber;
    string public message;
    uint256 donationOption;
    uint256 guess;
    uint256 actual;
    bool messageUpdated;
    bool lottoStatus;
    bool played;

    constructor(address _lottoAddress) {
        lottoAddress = _lottoAddress;
        holderNumber = ILotto(lottoAddress).getCurrentHolders();
        lottoStatus = ILotto(lottoAddress).getLottoStatus();
        played = false;
        messageUpdated = false;
    }

    //restrict this to only Lotto contract
    function setLottoStatus(bool _lottoStatus, address _lotoAddress) external {
        lottoStatus = _lottoStatus;
    }

    function hasTicketBeenPlayed() public view returns (bool) {
        return played;
    }

    function getDonationOption() public view returns (uint256) {
        return donationOption;
    }

    function getGuessNumber() public view returns (uint256) {
        return guess;
    }

    function getActualNumber() public view returns (uint256) {
        return actual;
    }

    function isMessageUpdated() public view returns (bool) {
        return messageUpdated;
    }

    function getOwnerNumber() public view returns (uint256) {
        return holderNumber;
    }

    function playLotto(
        uint256 _guess,
        string memory _message,
        uint256 _donationOption
    ) public onlyOwner returns (bool) {
        require(lottoStatus = true, "Lottery is already closed");
        // 1) If message then save + wallet address to dynamic NFT
        // 2) Save donation option
        // 3) generate random number % maxNumber
        // compare random number to input
        // return true to close auction save as winner
        // return false to keep it pushing

        played = true;
        return played;
    }

    function updateDynamicNFT() private {
        require(lottoStatus = true, "Lottery is already closed");
        // add message then save + wallet address to dynamic NFT

        messageUpdated = true;
    }
}