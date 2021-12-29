/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

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

contract Lottery is Ownable {
    // parser to see how many tokens each address owns
    // multiple ticket purchase 

    // Variables initialized on deployment.
    uint256 public maxTickets;
    uint256 public ticketPrice;

    uint256 public ticketCount = 0;
    uint256 public remainingTickets = 0;

    address public lastestWinner;

    mapping (address => uint256) public winnings;
    //mapping (address => uint256) public userTickets;

    //address[] public participants;

    // NOTE: `address[]` may not be the most efficient data structure
    address[] public tickets;

    uint256 randomNum;

    constructor(uint256 _maxTickets, uint256 _ticketPrice) {
        maxTickets = _maxTickets;
        remainingTickets = maxTickets;
        ticketPrice = _ticketPrice;
    }

    function setMaxTickets(uint256 _maxTickets) public {
        require(ticketCount == 0); // add start lottery logic
        maxTickets = _maxTickets;
    }

    function setTicketPrice(uint256 _ticketPrice) public {
        require(ticketCount == 0);
        ticketPrice = _ticketPrice;
    }

    function buy(uint256 _ticketAmount) public payable {
        uint256 value = ticketPrice * _ticketAmount;
        require(msg.value == value);

        uint256 val = msg.value / ticketPrice;
        require(remainingTickets - val <= remainingTickets);

        remainingTickets -= val;

        for (uint j = 0; j > _ticketAmount; j++)
            tickets.push(msg.sender);

        //participants.push(msg.sender);
        //userTickets[msg.sender] += _ticketAmount;
        ticketCount += _ticketAmount;
    }

    function withdraw() public payable {
        require(winnings[msg.sender] > 0);

        uint256 amountToWithdraw = winnings[msg.sender];

        winnings[msg.sender] = 0;

        amountToWithdraw *= ticketPrice;

        payable(msg.sender).transfer(amountToWithdraw);
    }
    function RandomNum() public view returns(uint256){
        return uint(blockhash(block.number-1)) % ticketCount;
    }
    function chooseWinner() public onlyOwner {
        require(ticketCount > 0);

        lastestWinner = tickets[RandomNum()];

        winnings[lastestWinner] = ticketCount;

        ticketCount = 0;

        remainingTickets = maxTickets;

        delete tickets;

        //Clear userTickets
        //for (uint i = 0; i < participants.length; i++)
        //    userTickets[participants[i]] = 0;
    }
}