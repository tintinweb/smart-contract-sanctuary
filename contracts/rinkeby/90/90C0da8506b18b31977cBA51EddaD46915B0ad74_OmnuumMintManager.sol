// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OmnuumMintManager is Ownable {
    struct NftProject {
        // max mint possible count per tx;
        uint32 maxMintPerTx;

        // base price - not whitelist
        uint256 basePrice;

        // open to everyone not only restricted to whitelist
        bool isAllOpen;

        mapping (address => MintTicket[]) mintTickets;
    }

    struct MintTicket {
        uint16 quantity;
        uint256 price;
    }

    // contract address -> NFT minting info
    mapping (address => NftProject) public NftProjects;

    constructor () {
    }

    function registerNftContract(uint32 maxMintPerTx, uint256 basePrice, bool isAllOpen) external {
        NftProject storage newContract = NftProjects[msg.sender];

        newContract.maxMintPerTx = maxMintPerTx;
        newContract.basePrice = basePrice;
        newContract.isAllOpen = isAllOpen;
    }

    function removeNftContract(address contractAddress) external {
        delete NftProjects[contractAddress];
    }


    function prepareMint(address minter, uint16 quantity, uint256 value, uint256 price) public returns (bool) {
        NftProject storage project = NftProjects[msg.sender];

        MintTicket[] storage tickets = project.mintTickets[minter];
        uint256 ticketLength = tickets.length;

        bool found;

        if (ticketLength == 0) {
            require(project.isAllOpen == true, "not allowed address");
            require(project.maxMintPerTx > quantity, "cannot mint more than possible amount per tx");
            require(project.basePrice * quantity > value, "payment amount is less than required amount");
            return true;
        } else {
            bool isDeleted;
            for (uint16 i; i < ticketLength; i++) {
                MintTicket storage ticket = tickets[i];

                if (isDeleted) {
                    if (ticketLength > i + 1) {
                        tickets[i] = tickets[i + 1];
                    } else {
                        tickets.pop();
                    }
                    continue;
                }

                if (found) {
                    continue;
                }

                if (ticket.price == price) {
                    found = true;
                    require(ticket.quantity >= quantity, "should have more quantity than mint");
                    uint16 restQuantity = ticket.quantity - quantity;
                    if (restQuantity == 0) {
                        isDeleted = true;
                        if (ticketLength > i + 1) {
                            tickets[i] = tickets[i + 1];
                        } else {
                            tickets.pop();
                        }
                    } else {
                        ticket.quantity = restQuantity;
                    }
                }
            }
        }

        require(found, "not correct price");

        return true;
    }

    function flushTickets(address projectAddress, address[] calldata targetAddresses) public onlyOwner {
        NftProject storage project = NftProjects[projectAddress];
        uint256 len = targetAddresses.length;

        for (uint16 i; i < len; i++) {
            delete project.mintTickets[targetAddresses[i]];
        }
    }

    // 민팅 티켓 주기 -  allocate? set? give? provide? empower? authorize? assign? guarantee?
    function giveMintTicketBatch(address projectContract, address[] calldata targets, MintTicket[] calldata tickets) public onlyOwner {
        require(targets.length == tickets.length, "address length and ticket length not equal");

        uint256 len = targets.length;
        NftProject storage project = NftProjects[projectContract];

        for (uint16 i; i < len; i++) {
            project.mintTickets[targets[i]].push(tickets[i]);
        }
    }

    function getMintTickets(address projectContract, address target) public view returns (MintTicket[] memory) {
        NftProject storage project = NftProjects[projectContract];

        MintTicket[] storage tickets = project.mintTickets[target];

        return tickets;

//        return NftProjects[projectContract].mintTickets[target];
    }

    function mergeTickets(MintTicket[] storage prevTickets, MintTicket calldata ticket) internal {

    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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