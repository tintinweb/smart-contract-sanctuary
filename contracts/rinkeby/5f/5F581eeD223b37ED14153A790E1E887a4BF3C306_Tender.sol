/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: OpenZeppelin/[email protected]/Context

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/Ownable

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: Tender.sol

contract Tender is Ownable {
    address public winner;
    //bidders
    address[] public bidders;
    //(address => amount bidded)
    mapping(address => uint256) address_to_amount;
    enum TENDER_STATE {
        CLOSED,
        OPEN,
        WINNER_ANNOUNCED
    }

    TENDER_STATE public tender_status;

    constructor() public {
        tender_status = TENDER_STATE.CLOSED;
    }

    function start_tender() public onlyOwner {
        require(tender_status == TENDER_STATE.CLOSED, "cant start the tender");
        tender_status = TENDER_STATE.OPEN;
    }

    function start_refund(uint256 winner_idx) private {
        uint256 amount;
        for (uint256 i = 0; i < bidders.length; i++) {
            if (i == winner_idx) {
                continue;
            }
            amount = address_to_amount[bidders[i]];
            payable(bidders[i]).transfer(amount);
        }
        tender_status = TENDER_STATE.WINNER_ANNOUNCED;
    }

    function calculate_winner() private {
        uint256 max = 0;
        uint256 winner_idx;
        for (uint256 i = 0; i < bidders.length; i++) {
            if (address_to_amount[bidders[i]] > max) {
                max = address_to_amount[bidders[i]];
                winner_idx = i;
            }
        }
        winner = bidders[winner_idx];
        start_refund(winner_idx);
    }

    function end_tender() public onlyOwner {
        require(tender_status == TENDER_STATE.OPEN, "cant end the tender");
        tender_status = TENDER_STATE.CLOSED;
        calculate_winner();
    }

    function check_the_bidder(address bidder) private view returns (bool) {
        for (uint256 i = 0; i < bidders.length; i++) {
            if (bidder == bidders[i]) {
                return true;
            }
        }
        return false;
    }

    function bid_for_tender() public payable {
        require(tender_status == TENDER_STATE.OPEN, "cant bid for the tender");
        //TODO check for minimum entry for the tender
        address_to_amount[msg.sender] += msg.value;
        if (!check_the_bidder(msg.sender)) {
            bidders.push(msg.sender);
        }
    }

    function withdraw() public onlyOwner {
        require(
            tender_status == TENDER_STATE.WINNER_ANNOUNCED,
            "cant withdraw now ..!"
        );
        payable(msg.sender).transfer(address(this).balance);
    }
}