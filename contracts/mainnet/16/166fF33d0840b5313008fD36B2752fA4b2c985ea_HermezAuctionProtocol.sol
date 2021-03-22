// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
import "../math/SafeMathUint128.sol";
import "../interfaces/IHEZToken.sol";
import "../interfaces/IHermezAuctionProtocol.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @dev Hermez will run an auction to incentivise efficiency in coordinators,
 * meaning that they need to be very effective and include as many transactions
 * as they can in the slots in order to compensate for their bidding costs, gas
 * costs and operations costs.The general porpouse of this smartcontract is to
 * define the rules to coordinate this auction where the bids will be placed
 * only in HEZ utility token.
 */
contract HermezAuctionProtocol is
    Initializable,
    ReentrancyGuardUpgradeable,
    IHermezAuctionProtocol
{
    using SafeMath128 for uint128;

    struct Coordinator {
        address forger; // Address allowed by the bidder to forge a batch
        string coordinatorURL;
    }

    // The closedMinBid is the minimum bidding with which it has been closed a slot and may be
    // higher than the bidAmount. This means that the funds must be returned to whoever has bid
    struct SlotState {
        address bidder;
        bool fulfilled;
        bool forgerCommitment;
        uint128 bidAmount; // Since the total supply of HEZ will be less than 100M, with 128 bits it is enough to
        uint128 closedMinBid; // store the bidAmount and closed minBid. bidAmount is the bidding for an specific slot.
    }

    // bytes4 private constant _PERMIT_SIGNATURE =
    //    bytes4(keccak256(bytes("permit(address,address,uint256,uint256,uint8,bytes32,bytes32)")));
    bytes4 private constant _PERMIT_SIGNATURE = 0xd505accf;

    // Blocks per slot
    uint8 public constant BLOCKS_PER_SLOT = 40;
    // Minimum bid when no one has bid yet
    uint128 public constant INITIAL_MINIMAL_BIDDING = 1000000 * (1e18);

    // Hermez Network Token with which the bids will be made
    IHEZToken public tokenHEZ;
    // HermezRollup smartcontract address
    address public hermezRollup;
    // Hermez Governance smartcontract address who controls some parameters and collects HEZ fee
    address public governanceAddress;
    // Boot Donation Address
    address private _donationAddress;
    // Boot Coordinator Address
    address private _bootCoordinator;
    // boot coordinator URL
    string public bootCoordinatorURL;
    // The minimum bid value in a series of 6 slots
    uint128[6] private _defaultSlotSetBid;
    // First block where the first slot begins
    uint128 public genesisBlock;
    // Number of closed slots after the current slot ( 2 Slots = 2 * 40 Blocks = 20 min )
    uint16 private _closedAuctionSlots;
    // Total number of open slots which you can bid ( 30 days = 4320 slots )
    uint16 private _openAuctionSlots;
    // How the HEZ tokens deposited by the slot winner are distributed ( Burn: 40.00% - Donation: 40.00% - HGT: 20.00% )
    uint16[3] private _allocationRatio; // Two decimal precision
    // Minimum outbid (percentage, two decimal precision) over the previous one to consider it valid
    uint16 private _outbidding; // Two decimal precision
    // Number of blocks after the beginning of a slot after which any coordinator can forge if the winner has not forged
    // any batch in that slot
    uint8 private _slotDeadline;

    // Mapping to control slot state
    mapping(uint128 => SlotState) public slots;
    // Mapping to control balances pending to claim
    mapping(address => uint128) public pendingBalances;
    // Mapping to register all the coordinators. The address used for the mapping is the bidder address
    mapping(address => Coordinator) public coordinators;

    event NewBid(
        uint128 indexed slot,
        uint128 bidAmount,
        address indexed bidder
    );
    event NewSlotDeadline(uint8 newSlotDeadline);
    event NewClosedAuctionSlots(uint16 newClosedAuctionSlots);
    event NewOutbidding(uint16 newOutbidding);
    event NewDonationAddress(address indexed newDonationAddress);
    event NewBootCoordinator(
        address indexed newBootCoordinator,
        string newBootCoordinatorURL
    );
    event NewOpenAuctionSlots(uint16 newOpenAuctionSlots);
    event NewAllocationRatio(uint16[3] newAllocationRatio);
    event SetCoordinator(
        address indexed bidder,
        address indexed forger,
        string coordinatorURL
    );
    event NewForgeAllocated(
        address indexed bidder,
        address indexed forger,
        uint128 indexed slotToForge,
        uint128 burnAmount,
        uint128 donationAmount,
        uint128 governanceAmount
    );
    event NewDefaultSlotSetBid(uint128 slotSet, uint128 newInitialMinBid);
    event NewForge(address indexed forger, uint128 indexed slotToForge);
    event HEZClaimed(address indexed owner, uint128 amount);

    // Event emitted when the contract is initialized
    event InitializeHermezAuctionProtocolEvent(
        address donationAddress,
        address bootCoordinatorAddress,
        string bootCoordinatorURL,
        uint16 outbidding,
        uint8 slotDeadline,
        uint16 closedAuctionSlots,
        uint16 openAuctionSlots,
        uint16[3] allocationRatio
    );

    modifier onlyGovernance() {
        require(
            governanceAddress == msg.sender,
            "HermezAuctionProtocol::onlyGovernance: ONLY_GOVERNANCE"
        );
        _;
    }

    /**
     * @dev Initializer function (equivalent to the constructor). Since we use
     * upgradeable smartcontracts the state vars have to be initialized here.
     * @param token Hermez Network token with which the bids will be made
     * @param hermezRollupAddress address authorized to forge
     * @param donationAddress address that can claim donated tokens
     * @param _governanceAddress Hermez Governance smartcontract
     * @param bootCoordinatorAddress Boot Coordinator Address
     */
    function hermezAuctionProtocolInitializer(
        address token,
        uint128 genesis,
        address hermezRollupAddress,
        address _governanceAddress,
        address donationAddress,
        address bootCoordinatorAddress,
        string memory _bootCoordinatorURL
    ) public initializer {
        __ReentrancyGuard_init_unchained();

        require(
            hermezRollupAddress != address(0),
            "HermezAuctionProtocol::hermezAuctionProtocolInitializer ADDRESS_0_NOT_VALID"
        );

        _outbidding = 1000;
        _slotDeadline = 20;
        _closedAuctionSlots = 2;
        _openAuctionSlots = 4320;
        _allocationRatio = [4000, 4000, 2000];
        _defaultSlotSetBid = [
            INITIAL_MINIMAL_BIDDING,
            INITIAL_MINIMAL_BIDDING,
            INITIAL_MINIMAL_BIDDING,
            INITIAL_MINIMAL_BIDDING,
            INITIAL_MINIMAL_BIDDING,
            INITIAL_MINIMAL_BIDDING
        ];

        require(
            genesis >= block.number,
            "HermezAuctionProtocol::hermezAuctionProtocolInitializer GENESIS_BELOW_MINIMAL"
        );

        tokenHEZ = IHEZToken(token);

        genesisBlock = genesis;
        hermezRollup = hermezRollupAddress;
        governanceAddress = _governanceAddress;
        _donationAddress = donationAddress;
        _bootCoordinator = bootCoordinatorAddress;
        bootCoordinatorURL = _bootCoordinatorURL;

        emit InitializeHermezAuctionProtocolEvent(
            donationAddress,
            bootCoordinatorAddress,
            _bootCoordinatorURL,
            _outbidding,
            _slotDeadline,
            _closedAuctionSlots,
            _openAuctionSlots,
            _allocationRatio
        );
    }

    /**
     * @notice Getter of the current `_slotDeadline`
     * @return The `_slotDeadline` value
     */
    function getSlotDeadline() external override view returns (uint8) {
        return _slotDeadline;
    }

    /**
     * @notice Allows to change the `_slotDeadline` if it's called by the owner
     * @param newDeadline new `_slotDeadline`
     * Events: `NewSlotDeadline`
     */
    function setSlotDeadline(uint8 newDeadline)
        external
        override
        onlyGovernance
    {
        require(
            newDeadline <= BLOCKS_PER_SLOT,
            "HermezAuctionProtocol::setSlotDeadline: GREATER_THAN_BLOCKS_PER_SLOT"
        );
        _slotDeadline = newDeadline;
        emit NewSlotDeadline(_slotDeadline);
    }

    /**
     * @notice Getter of the current `_openAuctionSlots`
     * @return The `_openAuctionSlots` value
     */
    function getOpenAuctionSlots() external override view returns (uint16) {
        return _openAuctionSlots;
    }

    /**
     * @notice Allows to change the `_openAuctionSlots` if it's called by the owner
     * @dev Max newOpenAuctionSlots = 65536 slots
     * @param newOpenAuctionSlots new `_openAuctionSlots`
     * Events: `NewOpenAuctionSlots`
     * Note: the governance could set this parameter equal to `ClosedAuctionSlots`, this means that it can prevent bids
     * from being made and that only the boot coordinator can forge
     */
    function setOpenAuctionSlots(uint16 newOpenAuctionSlots)
        external
        override
        onlyGovernance
    {
        _openAuctionSlots = newOpenAuctionSlots;
        emit NewOpenAuctionSlots(_openAuctionSlots);
    }

    /**
     * @notice Getter of the current `_closedAuctionSlots`
     * @return The `_closedAuctionSlots` value
     */
    function getClosedAuctionSlots() external override view returns (uint16) {
        return _closedAuctionSlots;
    }

    /**
     * @notice Allows to change the `_closedAuctionSlots` if it's called by the owner
     * @dev Max newClosedAuctionSlots = 65536 slots
     * @param newClosedAuctionSlots new `_closedAuctionSlots`
     * Events: `NewClosedAuctionSlots`
     * Note: the governance could set this parameter equal to `OpenAuctionSlots`, this means that it can prevent bids
     * from being made and that only the boot coordinator can forge
     */
    function setClosedAuctionSlots(uint16 newClosedAuctionSlots)
        external
        override
        onlyGovernance
    {
        _closedAuctionSlots = newClosedAuctionSlots;
        emit NewClosedAuctionSlots(_closedAuctionSlots);
    }

    /**
     * @notice Getter of the current `_outbidding`
     * @return The `_outbidding` value
     */
    function getOutbidding() external override view returns (uint16) {
        return _outbidding;
    }

    /**
     * @notice Allows to change the `_outbidding` if it's called by the owner
     * @dev newOutbidding between 0.01% and 100.00%
     * @param newOutbidding new `_outbidding`
     * Events: `NewOutbidding`
     */
    function setOutbidding(uint16 newOutbidding)
        external
        override
        onlyGovernance
    {
        require(
            newOutbidding > 1 && newOutbidding < 10000,
            "HermezAuctionProtocol::setOutbidding: OUTBIDDING_NOT_VALID"
        );
        _outbidding = newOutbidding;
        emit NewOutbidding(_outbidding);
    }

    /**
     * @notice Getter of the current `_allocationRatio`
     * @return The `_allocationRatio` array
     */
    function getAllocationRatio()
        external
        override
        view
        returns (uint16[3] memory)
    {
        return _allocationRatio;
    }

    /**
     * @notice Allows to change the `_allocationRatio` array if it's called by the owner
     * @param newAllocationRatio new `_allocationRatio` uint8[3] array
     * Events: `NewAllocationRatio`
     */
    function setAllocationRatio(uint16[3] memory newAllocationRatio)
        external
        override
        onlyGovernance
    {
        require(
            newAllocationRatio[0] <= 10000 &&
                newAllocationRatio[1] <= 10000 &&
                newAllocationRatio[2] <= 10000 &&
                newAllocationRatio[0] +
                    newAllocationRatio[1] +
                    newAllocationRatio[2] ==
                10000,
            "HermezAuctionProtocol::setAllocationRatio: ALLOCATION_RATIO_NOT_VALID"
        );
        _allocationRatio = newAllocationRatio;
        emit NewAllocationRatio(_allocationRatio);
    }

    /**
     * @notice Getter of the current `_donationAddress`
     * @return The `_donationAddress`
     */
    function getDonationAddress() external override view returns (address) {
        return _donationAddress;
    }

    /**
     * @notice Allows to change the `_donationAddress` if it's called by the owner
     * @param newDonationAddress new `_donationAddress`
     * Events: `NewDonationAddress`
     */
    function setDonationAddress(address newDonationAddress)
        external
        override
        onlyGovernance
    {
        require(
            newDonationAddress != address(0),
            "HermezAuctionProtocol::setDonationAddress: NOT_VALID_ADDRESS"
        );
        _donationAddress = newDonationAddress;
        emit NewDonationAddress(_donationAddress);
    }

    /**
     * @notice Getter of the current `_bootCoordinator`
     * @return The `_bootCoordinator`
     */
    function getBootCoordinator() external override view returns (address) {
        return _bootCoordinator;
    }

    /**
     * @notice Allows to change the `_bootCoordinator` if it's called by the owner
     * @param newBootCoordinator new `_bootCoordinator` uint8[3] array
     * Events: `NewBootCoordinator`
     */
    function setBootCoordinator(
        address newBootCoordinator,
        string memory newBootCoordinatorURL
    ) external override onlyGovernance {
        _bootCoordinator = newBootCoordinator;
        bootCoordinatorURL = newBootCoordinatorURL;
        emit NewBootCoordinator(_bootCoordinator, newBootCoordinatorURL);
    }

    /**
     * @notice Returns the minimum default bid for an slotSet
     * @param slotSet to obtain the minimum default bid
     * @return the minimum default bid for an slotSet
     */
    function getDefaultSlotSetBid(uint8 slotSet) public view returns (uint128) {
        return _defaultSlotSetBid[slotSet];
    }

    /**
     * @notice Allows to change the change the min bid for an slotSet if it's called by the owner.
     * @dev If an slotSet has the value of 0 it's considered decentralized, so the minbid cannot be modified
     * @param slotSet the slotSet to update
     * @param newInitialMinBid the minBid
     * Events: `NewDefaultSlotSetBid`
     */
    function changeDefaultSlotSetBid(uint128 slotSet, uint128 newInitialMinBid)
        external
        override
        onlyGovernance
    {
        require(
            slotSet < _defaultSlotSetBid.length,
            "HermezAuctionProtocol::changeDefaultSlotSetBid: NOT_VALID_SLOT_SET"
        );
        require(
            _defaultSlotSetBid[slotSet] != 0,
            "HermezAuctionProtocol::changeDefaultSlotSetBid: SLOT_DECENTRALIZED"
        );

        uint128 current = getCurrentSlotNumber();
        // This prevents closed bids from being modified
        for (uint128 i = current; i <= current + _closedAuctionSlots; i++) {
            // Save the minbid in case it has not been previously set
            if (slots[i].closedMinBid == 0) {
                slots[i].closedMinBid = _defaultSlotSetBid[getSlotSet(i)];
            }
        }
        _defaultSlotSetBid[slotSet] = newInitialMinBid;
        emit NewDefaultSlotSetBid(slotSet, newInitialMinBid);
    }

    /**
     * @notice Allows to register a new coordinator
     * @dev The `msg.sender` will be considered the `bidder`, who can change the forger address and the url
     * @param forger the address allowed to forger batches
     * @param coordinatorURL endopoint for this coordinator
     * Events: `NewCoordinator`
     */
    function setCoordinator(address forger, string memory coordinatorURL)
        external
        override
    {
        require(
            keccak256(abi.encodePacked(coordinatorURL)) !=
                keccak256(abi.encodePacked("")),
            "HermezAuctionProtocol::setCoordinator: NOT_VALID_URL"
        );
        coordinators[msg.sender].forger = forger;
        coordinators[msg.sender].coordinatorURL = coordinatorURL;
        emit SetCoordinator(msg.sender, forger, coordinatorURL);
    }

    /**
     * @notice Returns the current slot number
     * @return slotNumber an uint128 with the current slot
     */
    function getCurrentSlotNumber() public view returns (uint128) {
        return getSlotNumber(uint128(block.number));
    }

    /**
     * @notice Returns the slot number of a given block
     * @param blockNumber from which to calculate the slot
     * @return slotNumber an uint128 with the slot calculated
     */
    function getSlotNumber(uint128 blockNumber) public view returns (uint128) {
        return
            (blockNumber >= genesisBlock)
                ? ((blockNumber - genesisBlock) / BLOCKS_PER_SLOT)
                : uint128(0);
    }

    /**
     * @notice Returns an slotSet given an slot
     * @param slot from which to calculate the slotSet
     * @return the slotSet of the slot
     */
    function getSlotSet(uint128 slot) public view returns (uint128) {
        return slot.mod(uint128(_defaultSlotSetBid.length));
    }

    /**
     * @notice gets the minimum bid that someone has to bid to win the slot for a given slot
     * @dev it will revert in case of trying to obtain the minimum bid for a closed slot
     * @param slot from which to get the minimum bid
     * @return the minimum amount to bid
     */
    function getMinBidBySlot(uint128 slot) public view returns (uint128) {
        require(
            slot > (getCurrentSlotNumber() + _closedAuctionSlots),
            "HermezAuctionProtocol::getMinBidBySlot: AUCTION_CLOSED"
        );
        uint128 slotSet = getSlotSet(slot);
        // If the bidAmount for a slot is 0 it means that it has not yet been bid, so the midBid will be the minimum
        // bid for the slot time plus the outbidding set, otherwise it will be the bidAmount plus the outbidding
        return
            (slots[slot].bidAmount == 0)
                ? _defaultSlotSetBid[slotSet].add(
                    _defaultSlotSetBid[slotSet].mul(_outbidding).div(
                        uint128(10000) // two decimal precision
                    )
                )
                : slots[slot].bidAmount.add(
                    slots[slot].bidAmount.mul(_outbidding).div(uint128(10000)) // two decimal precision
                );
    }

    /**
     * @notice Function to process a single bid
     * @dev If the bytes calldata permit parameter is empty the smart contract assume that it has enough allowance to
     * make the transferFrom. In case you want to use permit, you need to send the data of the permit call in bytes
     * @param amount the amount of tokens that have been sent
     * @param slot the slot for which the caller is bidding
     * @param bidAmount the amount of the bidding
     */
    function processBid(
        uint128 amount,
        uint128 slot,
        uint128 bidAmount,
        bytes calldata permit
    ) external override {
        // To avoid possible mistakes we don't allow anyone to bid without setting a forger
        require(
            coordinators[msg.sender].forger != address(0),
            "HermezAuctionProtocol::processBid: COORDINATOR_NOT_REGISTERED"
        );
        require(
            slot > (getCurrentSlotNumber() + _closedAuctionSlots),
            "HermezAuctionProtocol::processBid: AUCTION_CLOSED"
        );
        require(
            bidAmount >= getMinBidBySlot(slot),
            "HermezAuctionProtocol::processBid: BELOW_MINIMUM"
        );

        require(
            slot <=
                (getCurrentSlotNumber() +
                    _closedAuctionSlots +
                    _openAuctionSlots),
            "HermezAuctionProtocol::processBid: AUCTION_NOT_OPEN"
        );

        if (permit.length != 0) {
            _permit(amount, permit);
        }

        require(
            tokenHEZ.transferFrom(msg.sender, address(this), amount),
            "HermezAuctionProtocol::processBid: TOKEN_TRANSFER_FAILED"
        );
        pendingBalances[msg.sender] = pendingBalances[msg.sender].add(amount);

        require(
            pendingBalances[msg.sender] >= bidAmount,
            "HermezAuctionProtocol::processBid: NOT_ENOUGH_BALANCE"
        );
        _doBid(slot, bidAmount, msg.sender);
    }

    /**
     * @notice function to process a multi bid
     * @dev If the bytes calldata permit parameter is empty the smart contract assume that it has enough allowance to
     * make the transferFrom. In case you want to use permit, you need to send the data of the permit call in bytes
     * @param amount the amount of tokens that have been sent
     * @param startingSlot the first slot to bid
     * @param endingSlot the last slot to bid
     * @param slotSets the set of slots to which the coordinator wants to bid
     * @param maxBid the maximum bid that is allowed
     * @param minBid the minimum that you want to bid
     */
    function processMultiBid(
        uint128 amount,
        uint128 startingSlot,
        uint128 endingSlot,
        bool[6] memory slotSets,
        uint128 maxBid,
        uint128 minBid,
        bytes calldata permit
    ) external override {
        require(
            startingSlot > (getCurrentSlotNumber() + _closedAuctionSlots),
            "HermezAuctionProtocol::processMultiBid AUCTION_CLOSED"
        );
        require(
            endingSlot <=
                (getCurrentSlotNumber() +
                    _closedAuctionSlots +
                    _openAuctionSlots),
            "HermezAuctionProtocol::processMultiBid AUCTION_NOT_OPEN"
        );
        require(
            maxBid >= minBid,
            "HermezAuctionProtocol::processMultiBid MAXBID_GREATER_THAN_MINBID"
        );
        // To avoid possible mistakes we don't allow anyone to bid without setting a forger
        require(
            coordinators[msg.sender].forger != address(0),
            "HermezAuctionProtocol::processMultiBid COORDINATOR_NOT_REGISTERED"
        );

        if (permit.length != 0) {
            _permit(amount, permit);
        }

        require(
            tokenHEZ.transferFrom(msg.sender, address(this), amount),
            "HermezAuctionProtocol::processMultiBid: TOKEN_TRANSFER_FAILED"
        );
        pendingBalances[msg.sender] = pendingBalances[msg.sender].add(amount);

        uint128 bidAmount;
        for (uint128 slot = startingSlot; slot <= endingSlot; slot++) {
            uint128 minBidBySlot = getMinBidBySlot(slot);
            // In case that the minimum bid is below the desired minimum bid, we will use this lower limit as the bid
            if (minBidBySlot <= minBid) {
                bidAmount = minBid;
                // If the `minBidBySlot` is between the upper (`maxBid`) and lower limit (`minBid`) we will use
                // this value `minBidBySlot` as the bid
            } else if (minBidBySlot > minBid && minBidBySlot <= maxBid) {
                bidAmount = minBidBySlot;
                // if the `minBidBySlot` is higher than the upper limit `maxBid`, we will not bid for this slot
            } else {
                continue;
            }

            // check if it is a selected slotSet
            if (slotSets[getSlotSet(slot)]) {
                require(
                    pendingBalances[msg.sender] >= bidAmount,
                    "HermezAuctionProtocol::processMultiBid NOT_ENOUGH_BALANCE"
                );
                _doBid(slot, bidAmount, msg.sender);
            }
        }
    }

    /**
     * @notice function to call token permit function
     * @param _amount the quantity that is expected to be allowed
     * @param _permitData the raw data of the call `permit` of the token
     */
    function _permit(uint256 _amount, bytes calldata _permitData) internal {
        bytes4 sig = abi.decode(_permitData, (bytes4));

        require(
            sig == _PERMIT_SIGNATURE,
            "HermezAuctionProtocol::_permit: NOT_VALID_CALL"
        );
        (
            address owner,
            address spender,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = abi.decode(
            _permitData[4:],
            (address, address, uint256, uint256, uint8, bytes32, bytes32)
        );
        require(
            owner == msg.sender,
            "HermezAuctionProtocol::_permit: OWNER_NOT_EQUAL_SENDER"
        );
        require(
            spender == address(this),
            "HermezAuctionProtocol::_permit: SPENDER_NOT_EQUAL_THIS"
        );
        require(
            value == _amount,
            "HermezAuctionProtocol::_permit: WRONG_AMOUNT"
        );

        // we call without checking the result, in case it fails and he doesn't have enough balance
        // the following transferFrom should be fail. This prevents DoS attacks from using a signature
        // before the smartcontract call
        /* solhint-disable avoid-low-level-calls avoid-call-value */
        address(tokenHEZ).call(
            abi.encodeWithSelector(
                _PERMIT_SIGNATURE,
                owner,
                spender,
                value,
                deadline,
                v,
                r,
                s
            )
        );
    }

    /**
     * @notice Internal function to make the bid
     * @dev will only be called by processBid or processMultiBid
     * @param slot the slot for which the caller is bidding
     * @param bidAmount the amount of the bidding
     * @param bidder the address of the bidder
     * Events: `NewBid`
     */
    function _doBid(
        uint128 slot,
        uint128 bidAmount,
        address bidder
    ) private {
        address prevBidder = slots[slot].bidder;
        uint128 prevBidValue = slots[slot].bidAmount;
        require(
            bidAmount > prevBidValue,
            "HermezAuctionProtocol::_doBid: BID_MUST_BE_HIGHER"
        );

        pendingBalances[bidder] = pendingBalances[bidder].sub(bidAmount);

        slots[slot].bidder = bidder;
        slots[slot].bidAmount = bidAmount;

        // If there is a previous bid we must return the HEZ tokens
        if (prevBidder != address(0) && prevBidValue != 0) {
            pendingBalances[prevBidder] = pendingBalances[prevBidder].add(
                prevBidValue
            );
        }
        emit NewBid(slot, bidAmount, bidder);
    }

    /**
     * @notice function to know if a certain address can forge into a certain block
     * @param forger the address of the coodirnator's forger
     * @param blockNumber block number to check
     * @return a bool true in case it can forge, false otherwise
     */
    function canForge(address forger, uint256 blockNumber)
        external
        override
        view
        returns (bool)
    {
        return _canForge(forger, blockNumber);
    }

    /**
     * @notice function to know if a certain address can forge into a certain block
     * @param forger the address of the coodirnator's forger
     * @param blockNumber block number to check
     * @return a bool true in case it can forge, false otherwise
     */
    function _canForge(address forger, uint256 blockNumber)
        internal
        view
        returns (bool)
    {
        require(
            blockNumber < 2**128,
            "HermezAuctionProtocol::canForge WRONG_BLOCKNUMBER"
        );
        require(
            blockNumber >= genesisBlock,
            "HermezAuctionProtocol::canForge AUCTION_NOT_STARTED"
        );

        uint128 slotToForge = getSlotNumber(uint128(blockNumber));
        // Get the relativeBlock to check if the slotDeadline has been exceeded
        uint128 relativeBlock = uint128(blockNumber).sub(
            (slotToForge.mul(BLOCKS_PER_SLOT)).add(genesisBlock)
        );
        // If the closedMinBid is 0 it means that we have to take as minBid the one that is set for this slot set,
        // otherwise the one that has been saved will be used
        uint128 minBid = (slots[slotToForge].closedMinBid == 0)
            ? _defaultSlotSetBid[getSlotSet(slotToForge)]
            : slots[slotToForge].closedMinBid;

        // if the relative block has exceeded the slotDeadline and no batch has been forged, anyone can forge
        if (
            !slots[slotToForge].forgerCommitment &&
            (relativeBlock >= _slotDeadline)
        ) {
            return true;
            //if forger bidAmount has exceeded the minBid it can forge
        } else if (
            (coordinators[slots[slotToForge].bidder].forger == forger) &&
            (slots[slotToForge].bidAmount >= minBid)
        ) {
            return true;
            //if it's the boot coordinator and it has not been bid or the bid is below the minimum it can forge
        } else if (
            (_bootCoordinator == forger) &&
            ((slots[slotToForge].bidAmount < minBid) ||
                (slots[slotToForge].bidAmount == 0))
        ) {
            return true;
            // if it is not any of these three cases will not be able to forge
        } else {
            return false;
        }
    }

    /**
     * @notice function to process the forging
     * @param forger the address of the coodirnator's forger
     * Events: `NewForgeAllocated` and `NewForge`
     */
    function forge(address forger) external override {
        require(
            msg.sender == hermezRollup,
            "HermezAuctionProtocol::forge: ONLY_HERMEZ_ROLLUP"
        );
        require(
            _canForge(forger, block.number),
            "HermezAuctionProtocol::forge: CANNOT_FORGE"
        );
        uint128 slotToForge = getCurrentSlotNumber();

        if (!slots[slotToForge].forgerCommitment) {
            // Get the relativeBlock to check if the slotDeadline has been exceeded
            uint128 relativeBlock = uint128(block.number).sub(
                (slotToForge.mul(BLOCKS_PER_SLOT)).add(genesisBlock)
            );
            if (relativeBlock < _slotDeadline) {
                slots[slotToForge].forgerCommitment = true;
            }
        }

        // Default values:** Burn: 40% - Donation: 40% - HGT: 20%
        // Allocated is used to know if we have already distributed the HEZ tokens
        if (!slots[slotToForge].fulfilled) {
            slots[slotToForge].fulfilled = true;

            if (slots[slotToForge].bidAmount != 0) {
                // If the closedMinBid is 0 it means that we have to take as minBid the one that is set for this slot set,
                // otherwise the one that has been saved will be used
                uint128 minBid = (slots[slotToForge].closedMinBid == 0)
                    ? _defaultSlotSetBid[getSlotSet(slotToForge)]
                    : slots[slotToForge].closedMinBid;

                // If the bootcoordinator is forging and there has been a previous bid that is lower than the slot min bid,
                // we must return the tokens to the bidder and the tokens have not been distributed
                if (slots[slotToForge].bidAmount < minBid) {
                    // We save the minBid that this block has had
                    pendingBalances[slots[slotToForge]
                        .bidder] = pendingBalances[slots[slotToForge].bidder]
                        .add(slots[slotToForge].bidAmount);
                    // In case the winner is forging we have to allocate the tokens according to the desired distribution
                } else {
                    uint128 bidAmount = slots[slotToForge].bidAmount;
                    // calculation of token distribution

                    uint128 amountToBurn = bidAmount
                        .mul(_allocationRatio[0])
                        .div(uint128(10000)); // Two decimal precision
                    uint128 donationAmount = bidAmount
                        .mul(_allocationRatio[1])
                        .div(uint128(10000)); // Two decimal precision
                    uint128 governanceAmount = bidAmount
                        .mul(_allocationRatio[2])
                        .div(uint128(10000)); // Two decimal precision

                    // Tokens to burn
                    require(
                        tokenHEZ.burn(amountToBurn),
                        "HermezAuctionProtocol::forge: TOKEN_BURN_FAILED"
                    );

                    // Tokens to donate
                    pendingBalances[_donationAddress] = pendingBalances[_donationAddress]
                        .add(donationAmount);
                    // Tokens for the governace address
                    pendingBalances[governanceAddress] = pendingBalances[governanceAddress]
                        .add(governanceAmount);

                    emit NewForgeAllocated(
                        slots[slotToForge].bidder,
                        forger,
                        slotToForge,
                        amountToBurn,
                        donationAmount,
                        governanceAmount
                    );
                }
            }
        }
        emit NewForge(forger, slotToForge);
    }

    function claimPendingHEZ(uint128 slot) public {
        require(
            slot < getCurrentSlotNumber(),
            "HermezAuctionProtocol::claimPendingHEZ: ONLY_IF_PREVIOUS_SLOT"
        );
        require(
            !slots[slot].fulfilled,
            "HermezAuctionProtocol::claimPendingHEZ: ONLY_IF_NOT_FULFILLED"
        );
        // If the closedMinBid is 0 it means that we have to take as minBid the one that is set for this slot set,
        // otherwise the one that has been saved will be used
        uint128 minBid = (slots[slot].closedMinBid == 0)
            ? _defaultSlotSetBid[getSlotSet(slot)]
            : slots[slot].closedMinBid;

        require(
            slots[slot].bidAmount < minBid,
            "HermezAuctionProtocol::claimPendingHEZ: ONLY_IF_NOT_FULFILLED"
        );

        slots[slot].closedMinBid = minBid;
        slots[slot].fulfilled = true;

        pendingBalances[slots[slot].bidder] = pendingBalances[slots[slot]
            .bidder]
            .add(slots[slot].bidAmount);
    }

    /**
     * @notice function to know how much HEZ tokens are pending to be claimed for an address
     * @param bidder address to query
     * @return the total claimable HEZ by an address
     */
    function getClaimableHEZ(address bidder) public view returns (uint128) {
        return pendingBalances[bidder];
    }

    /**
     * @notice distributes the tokens to msg.sender address
     * Events: `HEZClaimed`
     */
    function claimHEZ() public nonReentrant {
        uint128 pending = getClaimableHEZ(msg.sender);
        require(
            pending > 0,
            "HermezAuctionProtocol::claimHEZ: NOT_ENOUGH_BALANCE"
        );
        pendingBalances[msg.sender] = 0;
        require(
            tokenHEZ.transfer(msg.sender, pending),
            "HermezAuctionProtocol::claimHEZ: TOKEN_TRANSFER_FAILED"
        );
        emit HEZClaimed(msg.sender, pending);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath128 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint128 a,
        uint128 b,
        string memory errorMessage
    ) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        uint128 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint128 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint128 a, uint128 b) internal pure returns (uint128) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint128 a,
        uint128 b,
        string memory errorMessage
    ) internal pure returns (uint128) {
        require(b > 0, errorMessage);
        uint128 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint128 a, uint128 b) internal pure returns (uint128) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint128 a,
        uint128 b,
        string memory errorMessage
    ) internal pure returns (uint128) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;

interface IHEZToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 value) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;

/**
 * @dev Hermez will run an auction to incentivise efficiency in coordinators,
 * meaning that they need to be very effective and include as many transactions
 * as they can in the slots in order to compensate for their bidding costs, gas
 * costs and operations costs.The general porpouse of this smartcontract is to
 * define the rules to coordinate this auction where the bids will be placed
 * only in HEZ utility token.
 */
interface IHermezAuctionProtocol {
    /**
     * @notice Getter of the current `_slotDeadline`
     * @return The `_slotDeadline` value
     */
    function getSlotDeadline() external view returns (uint8);

    /**
     * @notice Allows to change the `_slotDeadline` if it's called by the owner
     * @param newDeadline new `_slotDeadline`
     * Events: `NewSlotDeadline`
     */
    function setSlotDeadline(uint8 newDeadline) external;

    /**
     * @notice Getter of the current `_openAuctionSlots`
     * @return The `_openAuctionSlots` value
     */
    function getOpenAuctionSlots() external view returns (uint16);

    /**
     * @notice Allows to change the `_openAuctionSlots` if it's called by the owner
     * @dev Max newOpenAuctionSlots = 65536 slots
     * @param newOpenAuctionSlots new `_openAuctionSlots`
     * Events: `NewOpenAuctionSlots`
     * Note: the governance could set this parameter equal to `ClosedAuctionSlots`, this means that it can prevent bids
     * from being made and that only the boot coordinator can forge
     */
    function setOpenAuctionSlots(uint16 newOpenAuctionSlots) external;

    /**
     * @notice Getter of the current `_closedAuctionSlots`
     * @return The `_closedAuctionSlots` value
     */
    function getClosedAuctionSlots() external view returns (uint16);

    /**
     * @notice Allows to change the `_closedAuctionSlots` if it's called by the owner
     * @dev Max newClosedAuctionSlots = 65536 slots
     * @param newClosedAuctionSlots new `_closedAuctionSlots`
     * Events: `NewClosedAuctionSlots`
     * Note: the governance could set this parameter equal to `OpenAuctionSlots`, this means that it can prevent bids
     * from being made and that only the boot coordinator can forge
     */
    function setClosedAuctionSlots(uint16 newClosedAuctionSlots) external;

    /**
     * @notice Getter of the current `_outbidding`
     * @return The `_outbidding` value
     */
    function getOutbidding() external view returns (uint16);

    /**
     * @notice Allows to change the `_outbidding` if it's called by the owner
     * @dev newOutbidding between 0.00% and 655.36%
     * @param newOutbidding new `_outbidding`
     * Events: `NewOutbidding`
     */
    function setOutbidding(uint16 newOutbidding) external;

    /**
     * @notice Getter of the current `_allocationRatio`
     * @return The `_allocationRatio` array
     */
    function getAllocationRatio() external view returns (uint16[3] memory);

    /**
     * @notice Allows to change the `_allocationRatio` array if it's called by the owner
     * @param newAllocationRatio new `_allocationRatio` uint8[3] array
     * Events: `NewAllocationRatio`
     */
    function setAllocationRatio(uint16[3] memory newAllocationRatio) external;

    /**
     * @notice Getter of the current `_donationAddress`
     * @return The `_donationAddress`
     */
    function getDonationAddress() external view returns (address);

    /**
     * @notice Allows to change the `_donationAddress` if it's called by the owner
     * @param newDonationAddress new `_donationAddress`
     * Events: `NewDonationAddress`
     */
    function setDonationAddress(address newDonationAddress) external;

    /**
     * @notice Getter of the current `_bootCoordinator`
     * @return The `_bootCoordinator`
     */
    function getBootCoordinator() external view returns (address);

    /**
     * @notice Allows to change the `_bootCoordinator` if it's called by the owner
     * @param newBootCoordinator new `_bootCoordinator` uint8[3] array
     * Events: `NewBootCoordinator`
     */
    function setBootCoordinator(
        address newBootCoordinator,
        string memory newBootCoordinatorURL
    ) external;

    /**
     * @notice Allows to change the change the min bid for an slotSet if it's called by the owner.
     * @dev If an slotSet has the value of 0 it's considered decentralized, so the minbid cannot be modified
     * @param slotSet the slotSet to update
     * @param newInitialMinBid the minBid
     * Events: `NewDefaultSlotSetBid`
     */
    function changeDefaultSlotSetBid(uint128 slotSet, uint128 newInitialMinBid)
        external;

    /**
     * @notice Allows to register a new coordinator
     * @dev The `msg.sender` will be considered the `bidder`, who can change the forger address and the url
     * @param forger the address allowed to forger batches
     * @param coordinatorURL endopoint for this coordinator
     * Events: `NewCoordinator`
     */
    function setCoordinator(address forger, string memory coordinatorURL)
        external;

    /**
     * @notice Function to process a single bid
     * @dev If the bytes calldata permit parameter is empty the smart contract assume that it has enough allowance to
     * make the transferFrom. In case you want to use permit, you need to send the data of the permit call in bytes
     * @param amount the amount of tokens that have been sent
     * @param slot the slot for which the caller is bidding
     * @param bidAmount the amount of the bidding
     */
    function processBid(
        uint128 amount,
        uint128 slot,
        uint128 bidAmount,
        bytes calldata permit
    ) external;

    /**
     * @notice function to process a multi bid
     * @dev If the bytes calldata permit parameter is empty the smart contract assume that it has enough allowance to
     * make the transferFrom. In case you want to use permit, you need to send the data of the permit call in bytes
     * @param amount the amount of tokens that have been sent
     * @param startingSlot the first slot to bid
     * @param endingSlot the last slot to bid
     * @param slotSets the set of slots to which the coordinator wants to bid
     * @param maxBid the maximum bid that is allowed
     * @param minBid the minimum that you want to bid
     */
    function processMultiBid(
        uint128 amount,
        uint128 startingSlot,
        uint128 endingSlot,
        bool[6] memory slotSets,
        uint128 maxBid,
        uint128 minBid,
        bytes calldata permit
    ) external;

    /**
     * @notice function to process the forging
     * @param forger the address of the coodirnator's forger
     * Events: `NewForgeAllocated` and `NewForge`
     */
    function forge(address forger) external;

    /**
     * @notice function to know if a certain address can forge into a certain block
     * @param forger the address of the coodirnator's forger
     * @param blockNumber block number to check
     * @return a bool true in case it can forge, false otherwise
     */
    function canForge(address forger, uint256 blockNumber)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}