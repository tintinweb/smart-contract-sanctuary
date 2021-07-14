/**
 *Submitted for verification at polygonscan.com on 2021-07-14
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
/* is ERC165 */
interface IERC1155 {
    /**
    @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    MUST revert if `_to` is the zero address.
    MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    MUST revert on any other error.
    MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
    @param _from    Source address
    @param _to      Target address
    @param _id      ID of the token type
    @param _value   Transfer amount
    @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
    @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
    @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    MUST revert if `_to` is the zero address.
    MUST revert if length of `_ids` is not the same as length of `_values`.
    MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
    MUST revert on any other error.        
    MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
    After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
    @param _from    Source address
    @param _to      Target address
    @param _ids     IDs of each token type (order and length must match _values array)
    @param _values  Transfer amounts per token type (order and length must match _ids array)
    @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
    @notice Get the balance of an account's tokens.
    @param _owner  The address of the token holder
    @param _id     ID of the token
    @return        The _owner's balance of the token type requested
    */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
    @notice Get the balance of multiple account/token pairs
    @param _owners The addresses of the token holders
    @param _ids    ID of the tokens
    @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
    */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
    @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    @dev MUST emit the ApprovalForAll event on success.
    @param _operator  Address to add to the set of authorized operators
    @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
    @notice Queries the approval status of an operator for a given owner.
    @param _owner     The owner of the tokens
    @param _operator  Address of authorized operator
    @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ILink {
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function approve(address spender, uint256 value) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/*************/
/* Aavegotchi raffles contract
/* Authors: Nick Mudge (mudgen) and Daniel Mathieu (coderdan)
/*************/

// All state variables are accessed through this struct
// To avoid name clashes and make clear a variable is a state variable
// state variable access starts with "s." which accesses variables in this struct
struct AppStorage {
    // IERC165
    mapping(bytes4 => bool) supportedInterfaces;
    Raffle[] raffles;
    // Nonces for VRF keyHash from which randomness has been requested.
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    // keyHash => nonce
    mapping(bytes32 => uint256) nonces;
    mapping(bytes32 => uint256) requestIdToRaffleId;
    bytes32 keyHash;
    uint96 fee;
    address contractOwner;
    address vrfCoordinator;
    ILink link;
}

struct Raffle {
    // associates ticket address and ticketId to raffleItems
    // if raffleItemIndexes == 0, then raffle item does not exist
    // This means all raffleItemIndexes have been incremented by 1
    // ticketAddress => (ticketId => index + 1)
    mapping(address => mapping(uint256 => uint256)) raffleItemIndexes;
    RaffleItem[] raffleItems;
    // maps what tickets entrants have entered into the raffle
    // entrant => tickets
    mapping(address => Entry[]) entries;
    // the addresses of people who have entered tickets into the raffle
    address[] entrants;
    // vrf randomness
    uint256 randomNumber;
    // requested vrf random number
    bool randomNumberPending;
    // date in timestamp seconds when a raffle ends
    uint256 raffleEnd;
}

// The minimum rangeStart is 0
// The maximum rangeEnd is raffleItem.totalEntered
// rangeEnd - rangeStart == number of ticket entered for raffle item by a entrant entry
struct Entry {
    uint24 raffleItemIndex; // Which raffle item is entered into the raffleEnd
    // used to prevent users from claiming prizes more than once
    bool prizesClaimed;
    uint112 rangeStart; // Raffle number. Value is between 0 and raffleItem.totalEntered - 1
    uint112 rangeEnd; // Raffle number. Value is between 1 and raffleItem.totalEntered
}

struct RaffleItemPrize {
    address prizeAddress; // ERC1155 token contract
    uint96 prizeQuantity; // Number of ERC1155 tokens
    uint256 prizeId; // ERC1155 token type
}

// Ticket numbers are numbers between 0 and raffleItem.totalEntered - 1 inclusive.
struct RaffleItem {
    address ticketAddress; // ERC1155 token contract
    uint256 ticketId; // ERC1155 token type
    uint256 totalEntered; // Total number of ERC1155 tokens entered into raffle for this raffle item
    RaffleItemPrize[] raffleItemPrizes; // Prizes that can be won for this raffle item
}

contract RafflesContract is IERC173, IERC165 {
    // State variables are prefixed with s.
    AppStorage internal s;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // Return value from `onERC1155Received` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`).
    event RaffleStarted(uint256 indexed raffleId, uint256 raffleEnd, RaffleItemInput[] raffleItems);
    event RaffleTicketsEntered(uint256 indexed raffleId, address entrant, TicketItemIO[] ticketItems);
    event RaffleRandomNumber(uint256 indexed raffleId, uint256 randomNumber);
    event RaffleClaimPrize(uint256 indexed raffleId, address entrant, address prizeAddress, uint256 prizeId, uint256 prizeQuantity);

    constructor(
        address _contractOwner,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) {
        s.contractOwner = _contractOwner;
        s.vrfCoordinator = _vrfCoordinator;
        s.link = ILink(_link);
        s.keyHash = _keyHash; //0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        s.fee = uint96(_fee);

        // adding ERC165 data
        s.supportedInterfaces[type(IERC165).interfaceId] = true;
        s.supportedInterfaces[type(IERC173).interfaceId] = true;
        // skip raffle 0
        s.raffles.push();
        // skip raffle 1
        s.raffles.push();
        // skip raffle 2
        s.raffles.push();
    }

    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        return s.supportedInterfaces[_interfaceId];
    }

    // VRF Functionality ////////////////////////////////////////////////////////////////
    function nonces(bytes32 _keyHash) external view returns (uint256 nonce_) {
        nonce_ = s.nonces[_keyHash];
    }

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     *
     * @dev See "SECURITY CONSIDERATIONS" above for more information on _seed.
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * @dev by the Oracle, and verified by the vrfCoordinator.
     *
     * @dev The _keyHash must already be registered with the VRFCoordinator, and
     * @dev the _fee must exceed the fee specified during registration of the
     * @dev _keyHash.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of LINK to send with the request
     * @param _seed seed mixed into the input of the VRF
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to *
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _seed
    ) internal returns (bytes32 requestId) {
        s.link.transferAndCall(s.vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        // So the seed doesn't actually do anything and is left over from an old API.
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, _seed, address(this), s.nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful Link.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input
        // seed, which would result in a predictable/duplicate output.
        s.nonces[_keyHash]++;
        return makeRequestId(_keyHash, vRFSeed);
    }

    /**
     * @notice returns the seed which is actually input to the VRF coordinator
     *
     * @dev To prevent repetition of VRF output due to repetition of the
     * @dev user-supplied seed, that seed is combined in a hash with the
     * @dev user-specific nonce, and the address of the consuming contract. The
     * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
     * @dev the final seed, but the nonce does protect against repetition in
     * @dev requests which are included in a single block.
     *
     * @param _userSeed VRF seed input provided by user
     * @param _requester Address of the requesting contract
     * @param _nonce User-specific nonce at the time of the request
     */
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    /**
     * @notice Returns the id for this request
     * @param _keyHash The serviceAgreement ID to be used for this request
     * @param _vRFInputSeed The seed to be passed directly to the VRF
     * @return The id for this request
     *
     * @dev Note that _vRFInputSeed is not the seed passed by the consuming
     * @dev contract, but the one generated by makeVRFInputSeed
     */
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }

    function drawRandomNumber(uint256 _raffleId) external {
        require(_raffleId < s.raffles.length, "Raffle: Raffle does not exist");
        Raffle storage raffle = s.raffles[_raffleId];
        require(raffle.raffleEnd < block.timestamp, "Raffle: Raffle time has not expired");
        require(raffle.randomNumber == 0, "Raffle: Random number already generated");
        require(raffle.randomNumberPending == false || msg.sender == s.contractOwner, "Raffle: Random number is pending");
        raffle.randomNumberPending = true;
        // Use Chainlink VRF to generate random number
        require(s.link.balanceOf(address(this)) >= s.fee, "Not enough LINK");
        bytes32 requestId = requestRandomness(s.keyHash, s.fee, 0);
        s.requestIdToRaffleId[requestId] = _raffleId;
    }

    function drawRandomNumberTest(uint256 _raffleId) external {
        require(msg.sender == s.contractOwner, "Raffle: Must be contract owner");
        require(_raffleId < s.raffles.length, "Raffle: Raffle does not exist");
        Raffle storage raffle = s.raffles[_raffleId];
        require(raffle.raffleEnd < block.timestamp, "Raffle: Raffle time has not expired");
        require(raffle.randomNumber == 0, "Raffle: Random number already generated");
        require(raffle.randomNumberPending == false || msg.sender == s.contractOwner, "Raffle: Random number is pending");
        raffle.randomNumberPending = true;
        // Use Chainlink VRF to generate random number
        require(s.link.balanceOf(address(this)) >= s.fee, "Not enough LINK");
        bytes32 requestId = requestRandomness(s.keyHash, s.fee, 0);
        s.requestIdToRaffleId[requestId] = _raffleId;

        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp)));
        s.raffles[_raffleId].randomNumber = randomness;
        raffle.randomNumberPending = false;
        emit RaffleRandomNumber(_raffleId, randomness);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRFproof.
    /**
     * @notice Callback function used by VRF Coordinator
     * @dev This is where you do something with randomness!
     * @dev The VRF Coordinator will only send this function verified responses.
     * @dev The VRF Coordinator will not pass randomness that could not be verified.
     */
    function rawFulfillRandomness(bytes32 _requestId, uint256 _randomness) external {
        require(msg.sender == s.vrfCoordinator, "Only VRFCoordinator can fulfill");
        uint256 raffleId = s.requestIdToRaffleId[_requestId];
        require(raffleId < s.raffles.length, "Raffle: Raffle does not exist");
        Raffle storage raffle = s.raffles[raffleId];
        require(raffle.raffleEnd < block.timestamp, "Raffle: Raffle time has not expired");
        require(raffle.randomNumber == 0, "Raffle: Random number already generated");
        s.raffles[raffleId].randomNumber = _randomness;
        raffle.randomNumberPending = false;
        emit RaffleRandomNumber(raffleId, _randomness);
    }

    // Change the fee amount that is paid for VRF random numbers
    function changeVRFFee(uint256 _newFee, bytes32 _keyHash) external {
        require(msg.sender == s.contractOwner, "Raffle: Must be contract owner");
        s.fee = uint96(_newFee);
        s.keyHash = _keyHash;
    }

    function changeVRF(
        uint256 _newFee,
        bytes32 _keyHash,
        address _vrfCoordinator,
        address _link
    ) external {
        require(msg.sender == s.contractOwner, "Raffle: Must be contract owner");
        s.fee = uint96(_newFee);
        s.keyHash = _keyHash;
        s.vrfCoordinator = _vrfCoordinator;
        s.link = ILink(_link);
    }

    // Remove the LINK tokens from this contract that are used to pay for VRF random number fees
    function removeLinkTokens(address _to, uint256 _value) external {
        require(msg.sender == s.contractOwner, "Raffle: Must be contract owner");
        s.link.transfer(_to, _value);
    }

    function linkBalance() external view returns (uint256 linkBalance_) {
        linkBalance_ = s.link.balanceOf(address(this));
    }

    /////////////////////////////////////////////////////////////////////////////////////

    function owner() external view override returns (address) {
        return s.contractOwner;
    }

    function transferOwnership(address _newContractOwner) external override {
        address previousOwner = s.contractOwner;
        require(msg.sender == previousOwner, "Raffle: Must be contract owner");
        s.contractOwner = _newContractOwner;
        emit OwnershipTransferred(previousOwner, _newContractOwner);
    }

    // structs with IO at the end of their name mean they are only used for
    // arguments and/or return values of functions
    struct RaffleItemInput {
        address ticketAddress;
        uint256 ticketId;
        RaffleItemPrizeIO[] raffleItemPrizes;
    }
    struct RaffleItemPrizeIO {
        address prizeAddress;
        uint256 prizeId;
        uint256 prizeQuantity;
    }

    /**
     * @notice Starts a raffle
     * @dev The _raffleItems argument tells what ERC1155 tickets can be entered for what ERC1155 prizes.
     * The _raffleItems get stored in the raffleItems state variable
     * The raffle prizes that can be won are transferred into this contract.
     * @param _raffleDuration How long a raffle goes for, in seconds
     * @param _raffleItems What tickets to enter for what prizes
     */
    function startRaffle(uint256 _raffleDuration, RaffleItemInput[] calldata _raffleItems) external {
        require(msg.sender == s.contractOwner, "Raffle: Must be contract owner");
        require(_raffleDuration >= 0, "Raffle: _raffleDuration must be greater than 0");
        uint256 raffleEnd = block.timestamp + _raffleDuration;
        require(_raffleItems.length > 0, "Raffle: No raffle items");
        uint256 raffleId = s.raffles.length;
        emit RaffleStarted(raffleId, raffleEnd, _raffleItems);
        Raffle storage raffle = s.raffles.push();
        raffle.raffleEnd = raffleEnd;
        for (uint256 i; i < _raffleItems.length; i++) {
            RaffleItemInput calldata raffleItemInput = _raffleItems[i];
            require(raffleItemInput.raffleItemPrizes.length > 0, "Raffle: No prizes");
            // ticketAddress is ERC1155 contract address of tickets
            // ticketId is the ERC1155 type id, which type is it
            require(
                // The index is one greater than actual index.  If index is 0 it means the value does not exist yet.
                raffle.raffleItemIndexes[raffleItemInput.ticketAddress][raffleItemInput.ticketId] == 0,
                "Raffle: Raffle item already using ticketAddress and ticketId"
            );
            // A raffle item is a ticketAddress, ticketId and what prizes can be won.
            RaffleItem storage raffleItem = raffle.raffleItems.push();
            // The index is one greater than actual index.  If index is 0 it means the value does not exist yet.
            raffle.raffleItemIndexes[raffleItemInput.ticketAddress][raffleItemInput.ticketId] = raffle.raffleItems.length;
            raffleItem.ticketAddress = raffleItemInput.ticketAddress;
            raffleItem.ticketId = raffleItemInput.ticketId;
            for (uint256 j; j < raffleItemInput.raffleItemPrizes.length; j++) {
                RaffleItemPrizeIO calldata raffleItemPrizeIO = raffleItemInput.raffleItemPrizes[j];
                raffleItem.raffleItemPrizes.push(
                    RaffleItemPrize(raffleItemPrizeIO.prizeAddress, uint96(raffleItemPrizeIO.prizeQuantity), raffleItemPrizeIO.prizeId)
                );
                IERC1155(raffleItemPrizeIO.prizeAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    raffleItemPrizeIO.prizeId,
                    raffleItemPrizeIO.prizeQuantity,
                    abi.encode(raffleId)
                );
            }
        }
    }

    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external view returns (bytes4) {
        _operator; // silence not used warning
        _from; // silence not used warning
        _id; // silence not used warning
        _value; // silence not used warning
        require(_data.length == 32, "Raffle: Data of the wrong size sent on transfer");
        uint256 raffleId = abi.decode(_data, (uint256));
        require(raffleId < s.raffles.length, "Raffle: Raffle does not exist");
        Raffle storage raffle = s.raffles[raffleId];
        uint256 raffleEnd = raffle.raffleEnd;
        require(raffleEnd > block.timestamp, "Raffle: Can't accept transfer for expired raffle");
        return ERC1155_ACCEPTED;
    }

    struct RaffleIO {
        uint256 raffleId;
        uint256 raffleEnd;
        bool isOpen;
    }

    /**
     * @notice Get simple raffle information
     */
    function getRaffles() external view returns (RaffleIO[] memory raffles_) {
        raffles_ = new RaffleIO[](s.raffles.length);
        for (uint256 i; i < s.raffles.length; i++) {
            uint256 raffleEnd = s.raffles[i].raffleEnd;
            raffles_[i].raffleId = i;
            raffles_[i].raffleEnd = raffleEnd;
            raffles_[i].isOpen = raffleEnd > block.timestamp;
        }
    }

    /**
     * @notice Get total number of raffles that exist.
     */
    function raffleSupply() external view returns (uint256 raffleSupply_) {
        raffleSupply_ = s.raffles.length;
    }

    struct RaffleItemOutput {
        address ticketAddress;
        uint256 ticketId;
        uint256 totalEntered;
        RaffleItemPrizeIO[] raffleItemPrizes;
    }

    /**
     * @notice Get simple raffle info and all the raffle items in the raffle.
     * @param _raffleId Which raffle to get info about.
     */
    function raffleInfo(uint256 _raffleId)
        external
        view
        returns (
            uint256 raffleEnd_,
            RaffleItemOutput[] memory raffleItems_,
            uint256 randomNumber_
        )
    {
        require(_raffleId < s.raffles.length, "Raffle: Raffle does not exist");
        Raffle storage raffle = s.raffles[_raffleId];
        raffleEnd_ = raffle.raffleEnd;
        if (raffle.randomNumberPending == true) {
            randomNumber_ = 1;
        } else {
            randomNumber_ = raffle.randomNumber;
        }
        // Loop over and get all the raffle itmes, which includes ERC1155 tickets and ERC1155 prizes
        raffleItems_ = new RaffleItemOutput[](raffle.raffleItems.length);
        for (uint256 i; i < raffle.raffleItems.length; i++) {
            RaffleItem storage raffleItem = raffle.raffleItems[i];
            raffleItems_[i].ticketAddress = raffleItem.ticketAddress;
            raffleItems_[i].ticketId = raffleItem.ticketId;
            raffleItems_[i].totalEntered = raffleItem.totalEntered;
            raffleItems_[i].raffleItemPrizes = new RaffleItemPrizeIO[](raffleItem.raffleItemPrizes.length);
            for (uint256 j; j < raffleItem.raffleItemPrizes.length; j++) {
                RaffleItemPrize storage raffleItemPrize = raffleItem.raffleItemPrizes[j];
                raffleItems_[i].raffleItemPrizes[j].prizeAddress = raffleItemPrize.prizeAddress;
                raffleItems_[i].raffleItemPrizes[j].prizeId = raffleItemPrize.prizeId;
                raffleItems_[i].raffleItemPrizes[j].prizeQuantity = raffleItemPrize.prizeQuantity;
            }
        }
    }

    struct EntryIO {
        address ticketAddress; // ERC1155 contract address
        uint256 ticketId; // ERC1155 type id
        uint256 ticketQuantity; // Number of ERC1155 tokens
        uint256 rangeStart;
        uint256 rangeEnd;
        uint256 raffleItemIndex;
        bool prizesClaimed;
    }

    /**
     * @notice Get get ticket info for a single entrant (address)
     * @param _raffleId Which raffle to get ticket stats about
     * @param _entrant Who to get stats about
     */
    function getEntries(uint256 _raffleId, address _entrant) external view returns (EntryIO[] memory entries_) {
        require(_raffleId < s.raffles.length, "Raffle: Raffle does not exist");
        Raffle storage raffle = s.raffles[_raffleId];
        entries_ = new EntryIO[](raffle.entries[_entrant].length);
        for (uint256 i; i < raffle.entries[_entrant].length; i++) {
            Entry memory entry = raffle.entries[_entrant][i];
            RaffleItem storage raffleItem = raffle.raffleItems[entry.raffleItemIndex];
            entries_[i].ticketAddress = raffleItem.ticketAddress;
            entries_[i].ticketId = raffleItem.ticketId;
            entries_[i].ticketQuantity = entry.rangeEnd - entry.rangeStart;
            entries_[i].rangeStart = entry.rangeStart;
            entries_[i].rangeEnd = entry.rangeEnd;
            entries_[i].raffleItemIndex = entry.raffleItemIndex;
            entries_[i].prizesClaimed = entry.prizesClaimed;
        }
    }

    struct TicketStatsIO {
        address ticketAddress; // ERC1155 contract address
        uint256 ticketId; // ERC1155 type id
        uint256 numberOfEntrants; // number of unique addresses that entered tickets
        uint256 totalEntered; // Number of ERC1155 tokens
    }

    /**
     * @notice Returns what tickets have been entered, by how many addresses, and how many ERC1155 tickets entered
     * @dev It is possible for this function to run out of gas when called off-chain if there are very many users (Infura has gas limit for off-chain calls)
     * @param _raffleId Which raffle to get info about
     */
    function ticketStats(uint256 _raffleId) external view returns (TicketStatsIO[] memory ticketStats_) {
        require(_raffleId < s.raffles.length, "Raffle: Raffle does not exist");
        Raffle storage raffle = s.raffles[_raffleId];
        ticketStats_ = new TicketStatsIO[](raffle.raffleItems.length);
        // loop through raffle items
        for (uint256 i; i < raffle.raffleItems.length; i++) {
            RaffleItem storage raffleItem = raffle.raffleItems[i];
            ticketStats_[i].ticketAddress = raffleItem.ticketAddress;
            ticketStats_[i].ticketId = raffleItem.ticketId;
            ticketStats_[i].totalEntered = raffleItem.totalEntered;
            // count the number of users that have ticketd for the raffle item
            for (uint256 j; j < raffle.entrants.length; j++) {
                address entrant = raffle.entrants[j];
                for (uint256 k; k < raffle.entries[entrant].length; k++) {
                    if (i == raffle.entries[entrant][k].raffleItemIndex) {
                        ticketStats_[i].numberOfEntrants++;
                        break;
                    }
                }
            }
        }
    }

    struct TicketItemIO {
        address ticketAddress; // ERC1155 contract address (entry ticket), not prize
        uint256 ticketId; // ERC1155 type id
        uint256 ticketQuantity; // Number of ERC1155 tokens
    }

    /**
     * @notice Enter ERC1155 tokens for raffle prizes
     * @dev Creates a new entry in the userEntries array
     * @param _raffleId Which raffle to ticket in
     * @param _ticketItems The ERC1155 tokens to ticket
     */
    function enterTickets(uint256 _raffleId, TicketItemIO[] calldata _ticketItems) external {
        require(_raffleId < s.raffles.length, "Raffle: Raffle does not exist");
        require(_ticketItems.length > 0, "Raffle: No tickets");
        Raffle storage raffle = s.raffles[_raffleId];
        require(raffle.raffleEnd > block.timestamp, "Raffle: Raffle time has expired");
        emit RaffleTicketsEntered(_raffleId, msg.sender, _ticketItems);
        // Collect unique entrant addresses
        if (raffle.entries[msg.sender].length == 0) {
            raffle.entrants.push(msg.sender);
        }
        for (uint256 i; i < _ticketItems.length; i++) {
            TicketItemIO calldata ticketItem = _ticketItems[i];
            require(ticketItem.ticketQuantity > 0, "Raffle: Ticket quantity cannot be zero");
            // get the raffle item
            uint256 raffleItemIndex = raffle.raffleItemIndexes[ticketItem.ticketAddress][ticketItem.ticketId];
            require(raffleItemIndex > 0, "Raffle: Raffle item doesn't exist for this raffle");
            raffleItemIndex--;
            RaffleItem storage raffleItem = raffle.raffleItems[raffleItemIndex];
            uint256 totalEntered = raffleItem.totalEntered;
            // Create a range of unique numbers for ticket ids
            raffle.entries[msg.sender].push(
                Entry(uint24(raffleItemIndex), false, uint112(totalEntered), uint112(totalEntered + ticketItem.ticketQuantity))
            );
            // update the total quantity of tickets that have been entered for this raffle item
            raffleItem.totalEntered = totalEntered + ticketItem.ticketQuantity;
            // transfer the ERC1155 tokens to ticket to this contract
            IERC1155(ticketItem.ticketAddress).safeTransferFrom(
                msg.sender,
                address(this),
                ticketItem.ticketId,
                ticketItem.ticketQuantity,
                abi.encode(_raffleId)
            );
        }
    }

    // Get the unique addresses of entrants in a raffle
    function getEntrants(uint256 _raffleId) external view returns (address[] memory entrants_) {
        require(_raffleId < s.raffles.length, "Raffle: Raffle does not exist");
        Raffle storage raffle = s.raffles[_raffleId];
        entrants_ = raffle.entrants;
    }

    /* This struct information can be gotten from the return results of the winners function */
    struct ticketWinIO {
        uint256 entryIndex; // index into a user's array of tickets (which staking attempt won)
        PrizesWinIO[] prizes;
    }

    // Ticket numbers are numbers between 0 and raffleItem.totalEntered - 1 inclusive.
    // Winning ticket numbers are ticket numbers that won one or more prizes
    // Prize numbers are numbers between 0 and raffleItemPrize.prizeQuanity - 1 inclusive.
    // Prize numbers are used to calculate ticket numbers
    // Winning prize numbers are prize numbers used to calculate winning ticket numbers
    struct PrizesWinIO {
        uint256 raffleItemPrizeIndex; // index into the raffleItemPrizes array (which prize was won)
        uint256[] winningPrizeNumbers; // ticket numbers between 0 and raffleItem.totalEntered that won
    }

    /**
     * @notice Claim prizes won
     * @dev All items in _wins are verified as actually won by the address that calls this function and reverts otherwise.
     * @dev Each entrant address can only claim prizes once, so be sure to include all entries and prizes won.
     * @dev Prizes are transfered to the address that calls this function.
     * @dev Due to the possibility that an entrant does not claim all the prizes he/she won or the gas cost is too high,
     * the contractOwner can claim prizes for an entrant. This needs to be used with care so that contractOwner does not
     * accidentally claim prizes for an entrant that have already been claimed for or by the entrant.
     * @param _entrant The entrant that won the prizes
     * @param _raffleId The raffle that prizes were won in.
     * @param _wins Contains only winning entries and prizes that were won.
     */
    function claimPrize(
        uint256 _raffleId,
        address _entrant,
        ticketWinIO[] calldata _wins
    ) external {
        require(_raffleId < s.raffles.length, "Raffle: Raffle does not exist");
        Raffle storage raffle = s.raffles[_raffleId];
        uint256 randomNumber = raffle.randomNumber;
        require(randomNumber > 0, "Raffle: Random number not generated yet");
        // contractOwner can claim prizes for the entrant.  Prizes are only transferred to the entrant
        require(msg.sender == _entrant || msg.sender == s.contractOwner, "Raffle: Not claimed by owner or contractOwner");
        // Logic:
        // 1. Loop through wins
        // 2. Verify provided entryIndex exists and is not a duplicate
        // 3. Loop through prizes
        // 4. Verify provided prize exists and is not a duplicate
        // 5. Loop through winning prize numbers
        // 6. Verify winning prize number exists and is not a duplicate
        // 7. Verify that winning prize number actually won
        // 8. Transfer prizes to winner
        //--------------------------------------------
        // lastValue serves two purposes:
        // 1. Ensures that a value is less than the length of an array
        // 2. Prevents duplicates. Subsequent values must be lesser
        // lastValue gets reused by inner loops
        uint256 lastValue = raffle.entries[_entrant].length;
        for (uint256 i; i < _wins.length; i++) {
            ticketWinIO calldata win = _wins[i];
            // Serves two purposes: 1. Ensure is less than raffle.entries[_entrant].length. 2. prevents duplicates
            require(win.entryIndex < lastValue, "Raffle: User entry does not exist or is not lesser than last value");
            Entry memory entry = raffle.entries[_entrant][win.entryIndex];
            require(entry.prizesClaimed == false, "Raffles: Entry prizes have already been claimed");
            raffle.entries[_entrant][win.entryIndex].prizesClaimed = true;
            // total number of tickets that have been entered for a raffle item
            uint256 totalEntered = raffle.raffleItems[entry.raffleItemIndex].totalEntered;
            lastValue = raffle.raffleItems[entry.raffleItemIndex].raffleItemPrizes.length;
            for (uint256 j; j < win.prizes.length; j++) {
                PrizesWinIO calldata prize = win.prizes[j];
                // Serves two purposes: 1. Ensure is less than raffleItemPrizes.length. 2. prevents duplicates
                require(prize.raffleItemPrizeIndex < lastValue, "Raffle: Raffle prize type does not exist or is not lesser than last value");
                RaffleItemPrize memory raffleItemPrize = raffle.raffleItems[entry.raffleItemIndex].raffleItemPrizes[prize.raffleItemPrizeIndex];
                lastValue = raffleItemPrize.prizeQuantity;
                for (uint256 k; k < prize.winningPrizeNumbers.length; k++) {
                    uint256 prizeNumber = prize.winningPrizeNumbers[k];
                    // Serves two purposes: 1. Ensure is less than raffleItemPrize.prizeQuantity. 2. prevents duplicates
                    require(prizeNumber < lastValue, "Raffle: prizeNumber does not exist or is not lesser than last value");
                    uint256 winningTicketNumber =
                        uint256(keccak256(abi.encodePacked(randomNumber, entry.raffleItemIndex, prize.raffleItemPrizeIndex, prizeNumber))) %
                            totalEntered;
                    require(winningTicketNumber >= entry.rangeStart && winningTicketNumber < entry.rangeEnd, "Raffle: Did not win prize");
                    lastValue = prizeNumber;
                }
                emit RaffleClaimPrize(_raffleId, _entrant, raffleItemPrize.prizeAddress, raffleItemPrize.prizeId, prize.winningPrizeNumbers.length);
                IERC1155(raffleItemPrize.prizeAddress).safeTransferFrom(
                    address(this),
                    _entrant,
                    raffleItemPrize.prizeId,
                    prize.winningPrizeNumbers.length,
                    ""
                );
                lastValue = prize.raffleItemPrizeIndex;
            }
            lastValue = win.entryIndex;
        }
    }
}