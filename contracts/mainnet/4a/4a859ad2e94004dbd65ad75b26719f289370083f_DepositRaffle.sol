/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

interface IReverseResolver {
    function claim(address owner) external returns (bytes32);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IDepositRaffleValidator {
    function validate (address account, bytes calldata metadata) external returns (bool);
}

/**
 * @title DepositRaffle
 * @dev Provides gas-war-free registration and distribution
 */
contract DepositRaffle {

    ///// Validator links /////
    IDepositRaffleValidator Validator;
    bool validatorActive = false;

    event TicketIssued(uint256 ticketId, address holder, bytes32 metadataHash);

    address payable public owner;

    ///// Pricing information /////
    uint256 immutable public deposit;
    uint256 immutable public price;

    uint256 immutable public quantity; // Number of winners to draw

    uint256 public startBlockNumber; // First block tickets are allowed to be bought in
    uint256 public endBlockNumber; // Final block tickets are allowed to be bought in

    bytes32 seedHash;
    uint256 seedBlock;
    uint256 offset = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 increment;

    bool incomeClaimed = false;

    address[] public holderByTicketId;

    uint256[8] internal Primes = [81918643972203779099,
                                  72729269248899238429,
                                  19314683338901247061,
                                  38707402401747623009,
                                  54451314435228525599,
                                  16972551169207064863,
                                  44527956848616763003,
                                  51240633499522341181];


    ///// Modifiers /////
    modifier onlyOwner () {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier issuanceOpen () {
        require(block.number <= endBlockNumber && startBlockNumber > 0, "Issuance Closed");
        _;
    }

    modifier issuanceClosed () {
        require(block.number > endBlockNumber, "Issuance Open");
        _;
    }

    modifier refundsReady () {
        // After ~30 days, if shuffle has not been performed, refunds become available;
        require(increment > 0 || (increment == 0 && block.number > (endBlockNumber + 200_000)), "Refunds Not Ready");
        _;
    }

    bool private notEntered = true;

    modifier nonReentrant() {
        require(notEntered, "Reentrant call");
        notEntered = false;
        _;
        notEntered = true;
    }

    /**
     * @dev How many tickets have been issued currently?
     */
    function ticketsIssued () public view returns (uint256) {
        return holderByTicketId.length;
    }

    /**
     * @dev Purchase a ticket for this raffle.
     * Allows purchasing a ticket "in the name of" another address.
     */
    function issueTicket (address holder, bytes calldata metadata) public payable issuanceOpen nonReentrant returns (uint256) {
        require(msg.value >= deposit, "Insufficient Deposit");
        require(!validatorActive || Validator.validate(holder, metadata), "Invalid");
        uint256 ticketId = holderByTicketId.length;
        holderByTicketId.push(holder);

        emit TicketIssued(ticketId, holder, keccak256(metadata));
        if (msg.value > deposit) {
            (bool success,) = payable(msg.sender).call{value: (msg.value - deposit)}("");
            require(success, "Overpay Refund Transfer Failed");
        }
        return ticketId;
    }

    /**
     * @dev Purchase a ticket in the name of the transaction sender.
     */
    function issueTicket(bytes calldata metadata) public payable returns (uint256) {
        return issueTicket(msg.sender, metadata);
    }

    /**
     * @dev Start a shuffle action.
     * The hash submitted here must be the keccak256 hash of a secret number that will be submitted to the next function
     */
    function prepareShuffleWinners (bytes32 _seedHash) public issuanceClosed onlyOwner {
        require(_seedHash != 0 && seedHash != _seedHash, "Invalid Seed Hash");
        require(seedBlock == 0 || block.number > seedBlock + 255, "Seed Already Set");
        seedHash = _seedHash;
        seedBlock = block.number;
    }

    /**
     * @dev Finalize the shuffle action.
     * Should be called after `prepareShuffleWinners`, after at leas two blocks have passed.
     */
    function shuffleWinners (uint256 seed) public issuanceClosed {
        require(increment == 0, "Already Shuffled");
        require(block.number <= (endBlockNumber + 170_000), "Shuffle Window Closed");

        if (holderByTicketId.length <= quantity) {
            increment = 1;
            return;
        }

        require(keccak256(abi.encodePacked(seed)) == seedHash, "Invalid Seed");
        require(block.number > seedBlock + 2 && block.number < seedBlock + 255, "Seed Block Error");

        uint256 randomSeed = uint256(keccak256(abi.encodePacked(seed, blockhash(seedBlock + 1), blockhash(seedBlock + 2))));

        offset = randomSeed % holderByTicketId.length;

        increment = Primes[uint256(keccak256(abi.encodePacked(randomSeed, randomSeed))) % 8];
    }

    /**
     * @dev What 'order' is a given ticket in, in the winning shuffle?
     * If all the tickets were to be put into a separate array in the "shuffled" order, what index would a given ticketID be at?
     */
    function drawIndex (uint256 ticketId) public view refundsReady returns (uint256) {
        return (increment * ticketId + offset) % holderByTicketId.length;
    }

    /**
     * @dev Is the given ticketId a winning ticket?
     */
    function isWinner (uint256 ticketId) public view refundsReady returns (bool) {
        if (increment == 0) {
            return false;
        } else if (holderByTicketId.length <= quantity) {
            require(ticketId < holderByTicketId.length, "Out of Range");
            return true;
        } else {
            return (increment * ticketId + offset) % holderByTicketId.length < quantity;
        }
    }

    /**
     * @dev Are non-winners able to withdraw their deposits yet?
     */
    function availableRefund (address holder, uint256[] calldata ticketIds) public view refundsReady returns (uint256) {
        uint256 refund = 0;
        for (uint i = 0; i < ticketIds.length; i++) {
            uint256 ticketId = ticketIds[i];
            if (holder == holderByTicketId[ticketId]) {
                refund += deposit;
                if (isWinner(ticketId)) {
                    refund -= price;
                }
           }
        }
        return refund;
    }

    /**
     * @dev Claim deposited funds after raffle is over.
     * For non-winning tickets, their entire deposit is refunded.
     * For winning tickets, the difference between the deposit price and the actual price is refunded.
     * In either case the ticket is destroyed after refunding. This refunds some gas to the ticket owner, making this operation less costly.
     */
    function claimRefund (uint256[] calldata ticketIds) public refundsReady {
        uint256 refund = 0;
        for (uint i = 0; i < ticketIds.length; i++) {
            uint256 ticketId = ticketIds[i];
            if (msg.sender == holderByTicketId[ticketId]) {
                refund += deposit;
                if (isWinner(ticketId)) {
                    refund -= price;
                }
                delete holderByTicketId[ticketId];
            }
        }
        if (refund > 0) {
            (bool success,) = payable(msg.sender).call{value: refund}("");
            require(success, "Refund Transfer Failed");
        }
    }

    /**
     * @dev Allow `owner` to claim remaining funds.
     * Losing raffle tickets have 90 days to claim their refunds. After that time the owner of the raffle is entitled to sweep the rest of the ETH.
     */
    function claimBalance () public onlyOwner {
        // After ~90 days, contract owner can claim all funds
        require (block.number > (endBlockNumber + 600_000));
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Claim Failed");
    }

    /**
     * @dev Allow `owner` to withdraw income from winning tickets after winners have been picked.
     */
    function claimIncome () public onlyOwner {
        require(increment > 0, "Not Shuffled");
        require(!incomeClaimed, "Income Claimed");
        incomeClaimed = true;
        uint256 balance;
        if (holderByTicketId.length <= quantity) {
            balance = holderByTicketId.length * price;
        } else {
            balance = quantity * price;
        }
        (bool success,) = owner.call{value: balance}("");
        require(success, "Claim Failed");
    }

    ///// Administration /////

    /**
     * @dev Start the raffle.
     */
    function openMinting (uint256 durationInBlocks) public onlyOwner {
        require(startBlockNumber == 0, "Minting Started");
        endBlockNumber = block.number + durationInBlocks;
        startBlockNumber = block.number;
    }

    /**
     * @dev Specify a contract to be used as a Validator of all ticket entries.
     */
    function activateValidation (address validatorContractAddress) public onlyOwner {
        validatorActive = true;
        Validator = IDepositRaffleValidator(validatorContractAddress);
    }

    /**
     * @dev Disable any Validator for this raffle.
     */
    function deactivateValidation () public onlyOwner {
        validatorActive = false;
    }

    /**
     * @dev Allow current `owner` to transfer ownership to another address
     */
    function transferOwnership (address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    /**
     * @dev Rescue ERC20 assets sent directly to this contract.
     */
    function withdrawForeignERC20 (address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721 (address tokenContract, uint256 tokenId) public onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), owner, tokenId);
    }

    constructor (uint256 depositWei, uint256 priceWei, uint256 totalQuantity) {
        require (depositWei >= priceWei, "Price > Deposit");
        deposit = depositWei;
        price = priceWei;
        quantity = totalQuantity;
        owner = payable(msg.sender);
        // https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
        IReverseResolver(0x084b1c3C81545d370f3634392De611CaaBFf8148).claim(msg.sender);
    }

}