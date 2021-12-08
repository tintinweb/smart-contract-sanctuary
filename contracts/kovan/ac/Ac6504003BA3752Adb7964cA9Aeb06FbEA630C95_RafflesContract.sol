//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC1155.sol";
import "./chainlink/LinkTokenInterface.sol";
import "./interfaces/IERC173.sol";
import "./interfaces/IERC165.sol";
import "./interfaces/IAavegotchi.sol";

import "./libraries/LibAppStorage.sol";
//import "@openzeppelin/contracts-upgradeable";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


// All state variables are accessed through this struct
// To avoid name clashes and make clear a variable is a state variable
// state variable access starts with "s." which accesses variables in this struct
struct AppStorage {
    // IERC165
    mapping(bytes4 => bool) supportedInterfaces;
    Raffle[6] raffles;
    // Nonces for VRF keyHash from which randomness has been requested.
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    // keyHash => nonce
    mapping(bytes32 => uint256) nonces;
    mapping(bytes32 => uint256) requestIdToRaffleId;
    bytes32 keyHash;
    uint96 fee;
    address contractOwner;
    IAavegotchi aavegotchiDiamond;

}


struct Raffle {
    
    //an array of all the itemIds that have been entered
    uint256[] itemsEntered;
    
    //a mapping of who has entered what item
    mapping(address => uint256) entrantsMapping;
    address[] entrants;

    uint256 brsMultiplier;
  
    // vrf randomness
    uint256 randomNumber;
    // requested vrf random number
    bool randomNumberPending;
    
    bool raffleActive;
 
    
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

contract RafflesContract is IERC173, IERC165, Initializable {
    // State variables are prefixed with s.
    AppStorage internal s;
    // Immutable values are prefixed with im_ to easily identify them in code
    LinkTokenInterface internal  im_link;
    address internal  im_vrfCoordinator;
    address internal  im_diamondAddress;
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // Return value from `onERC1155Received` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`).
    
     function getCoordinator() public view returns(address){
         return im_vrfCoordinator;
     }
  
    function initialize (
        address _aavegotchiDiamond,
        address _contractOwner,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) public initializer{
        s.contractOwner = _contractOwner;
        im_vrfCoordinator = _vrfCoordinator;
        im_link = LinkTokenInterface(_link);
        im_diamondAddress = _aavegotchiDiamond;
        s.keyHash = _keyHash; //0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        s.fee = uint96(_fee);
        s.aavegotchiDiamond = IAavegotchi(_aavegotchiDiamond);
        // adding ERC165 data
        s.supportedInterfaces[type(IERC165).interfaceId] = true;
        s.supportedInterfaces[type(IERC173).interfaceId] = true;
       
        s.raffles[0].brsMultiplier = 1;     //common
        s.raffles[1].brsMultiplier = 2;     //uncommon
        s.raffles[2].brsMultiplier = 5;     //rare
        s.raffles[3].brsMultiplier = 10;    //legendary
        s.raffles[4].brsMultiplier = 20;    //mythical
        s.raffles[5].brsMultiplier = 50;    //godlike
        
        for(uint256 i = 0; i < 6; i++){
            s.raffles[i].raffleActive = true;
        }

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
        im_link.transferAndCall(im_vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
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
        require(raffle.randomNumber == 0, "Raffle: Random number already generated");
        require(raffle.randomNumberPending == false || msg.sender == s.contractOwner, "Raffle: Random number is pending");
        raffle.randomNumberPending = true;
        // Use Chainlink VRF to generate random number
        require(im_link.balanceOf(address(this)) >= s.fee, "Not enough LINK");
        bytes32 requestId = requestRandomness(s.keyHash, s.fee, 0);
        s.requestIdToRaffleId[requestId] = _raffleId;
        
        s.raffles[_raffleId].raffleActive = false;
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRFproof.
    /**
     * @notice Callback function used by VRF Coordinator
     * @dev This is where you do something with randomness!
     * @dev The VRF Coordinator will only send this function verified responses.
     * @dev The VRF Coordinator will not pass randomness that could not be verified.
     */
    function rawFulfillRandomness(bytes32 _requestId, uint256 _randomness) external {
        require(msg.sender == im_vrfCoordinator, "Only VRFCoordinator can fulfill");
        uint256 raffleId = s.requestIdToRaffleId[_requestId];
        require(raffleId < s.raffles.length, "Raffle: Raffle does not exist");
        Raffle storage raffle = s.raffles[raffleId];
        require(raffle.randomNumber == 0, "Raffle: Random number already generated");
        s.raffles[raffleId].randomNumber = _randomness;
        raffle.randomNumberPending = false;
    }

    // Change the fee amount that is paid for VRF random numbers
    function changeVRFFee(uint256 _newFee, bytes32 _keyHash) external {
        require(msg.sender == s.contractOwner, "Raffle: Must be contract owner");
        s.fee = uint96(_newFee);
        s.keyHash = _keyHash;
    }

    // Remove the LINK tokens from this contract that are used to pay for VRF random number fees
    function removeLinkTokens(address _to, uint256 _value) external {
        require(msg.sender == s.contractOwner, "Raffle: Must be contract owner");
        im_link.transfer(_to, _value);
    }

    function linkBalance() external view returns (uint256 linkBalance_) {
        linkBalance_ = im_link.balanceOf(address(this));
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
        _data;
        return ERC1155_ACCEPTED;
    }


    function enterWearable(address _tokenAddress, uint256 _id) public{
        require(IERC1155(_tokenAddress).balanceOf(msg.sender,_id) > 0, "Insufficient Balance!");
        ItemType memory thisItem = s.aavegotchiDiamond.getItemType(_id);
        require(thisItem.category == 0, "can only enter wearables");
        
        for(uint256 i = 0; i < s.raffles.length; i++){
            if(thisItem.rarityScoreModifier == s.raffles[i].brsMultiplier){
                require(s.raffles[i].raffleActive, "raffle not active");
                require(s.raffles[i].entrantsMapping[msg.sender] == 0,"already entered in this raffle");
                s.raffles[i].entrants.push(msg.sender);
                s.raffles[i].entrantsMapping[msg.sender] = _id;
            }
        }
        
        IERC1155(_tokenAddress).safeTransferFrom(msg.sender,address(this),_id,1,"");
    }
    
    function itemBalances(address _account) external view returns (ItemIdIO[] memory bals_) {
        return s.aavegotchiDiamond.itemBalances(_account);   
    }
    
    function isApproved(address _account) public view returns (bool){
        IERC1155(im_diamondAddress).isApprovedForAll(_account,address(this));
    }

    function getEntrants(uint256 _raffleId) public view returns(address[] memory _entrants){
        _entrants = s.raffles[_raffleId].entrants;
    }

    function getWinner(uint256 _raffleId) public view returns(address _winner){
        require(_raffleId < s.raffles.length, "Raffle: Raffle does not exist");
        Raffle storage raffle = s.raffles[_raffleId];
        uint256 randomNumber = raffle.randomNumber;
        require(randomNumber > 0, "Raffle: Random number not generated yet");

        uint256 winningIndex = uint256(
                        keccak256(abi.encodePacked(randomNumber, _raffleId))
                    ) % raffle.entrants.length;
                    
        return raffle.entrants[winningIndex];
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
     * 
     */
    function claimPrize(
        uint256 _raffleId,
        address _entrant
    ) public {
        require(_raffleId < s.raffles.length, "Raffle: Raffle does not exist");
        Raffle storage raffle = s.raffles[_raffleId];
        uint256 randomNumber = raffle.randomNumber;
        require(randomNumber > 0, "Raffle: Random number not generated yet");
        // contractOwner can claim prizes for the entrant.  Prizes are only transferred to the entrant
        require(msg.sender == _entrant || msg.sender == s.contractOwner, "Raffle: Not claimed by owner or contractOwner");
                    
        require(getWinner(_raffleId) == _entrant, "not a winner");
        
        //cycle through each entry and send wearable to the winner
        for(uint256 i = 0; i<raffle.entrants.length; i++){
            uint256 entrantItem = raffle.entrantsMapping[raffle.entrants[i]];
            IERC1155(im_diamondAddress).safeTransferFrom(address(this),_entrant,entrantItem,1,"");
        }
        
        
        
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
/* is ERC165 */
interface IERC1155 {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

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

interface LinkTokenInterface {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibAppStorage.sol";



interface IAavegotchi{
        function getItemType(uint256 _itemId) external view returns (ItemType memory itemType_);
        
        function itemBalances(address _account) external view returns (ItemIdIO[] memory bals_);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;
uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant TRAIT_BONUSES_NUM = 5;
uint256 constant PORTAL_AAVEGOTCHIS_NUM = 10;

//  switch (traitType) {
//         case 0:
//             return energy(value);
//         case 1:
//             return aggressiveness(value);
//         case 2:
//             return spookiness(value);
//         case 3:
//             return brain(value);
//         case 4:
//             return eyeShape(value);
//         case 5:
//             return eyeColor(value);

struct Aavegotchi {
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables; //The currently equipped wearables of the Aavegotchi
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int8[NUMERIC_TRAITS_NUM] temporaryTraitBoosts;
    int16[NUMERIC_TRAITS_NUM] numericTraits; // Sixteen 16 bit ints.  [Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    string name;
    uint256 randomNumber;
    uint256 experience; //How much XP this Aavegotchi has accrued. Begins at 0.
    uint256 minimumStake; //The minimum amount of collateral that must be staked. Set upon creation.
    uint256 usedSkillPoints; //The number of skill points this aavegotchi has already used
    uint256 interactionCount; //How many times the owner of this Aavegotchi has interacted with it.
    address collateralType;
    uint40 claimTime; //The block timestamp when this Aavegotchi was claimed
    uint40 lastTemporaryBoost;
    uint16 hauntId;
    address owner;
    uint8 status; // 0 == portal, 1 == VRF_PENDING, 2 == open portal, 3 == Aavegotchi
    uint40 lastInteracted; //The last time this Aavegotchi was interacted with
    bool locked;
    address escrow; //The escrow address this Aavegotchi manages.
}

struct Dimensions {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct ItemType {
    string name; //The name of the item
    string description;
    string author;
    // treated as int8s array
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int8[NUMERIC_TRAITS_NUM] traitModifiers; //[WEARABLE ONLY] How much the wearable modifies each trait. Should not be more than +-5 total
    //[WEARABLE ONLY] The slots that this wearable can be added to.
    bool[EQUIPPED_WEARABLE_SLOTS] slotPositions;
    // this is an array of uint indexes into the collateralTypes array
    uint8[] allowedCollaterals; //[WEARABLE ONLY] The collaterals this wearable can be equipped to. An empty array is "any"
    // SVG x,y,width,height
    Dimensions dimensions;
    uint256 ghstPrice; //How much GHST this item costs
    uint256 maxQuantity; //Total number that can be minted of this item.
    uint256 totalQuantity; //The total quantity of this item minted so far
    uint32 svgId; //The svgId of the item
    uint8 rarityScoreModifier; //Number from 1-50.
    // Each bit is a slot position. 1 is true, 0 is false
    bool canPurchaseWithGhst;
    uint16 minLevel; //The minimum Aavegotchi level required to use this item. Default is 1.
    bool canBeTransferred;
    uint8 category; // 0 is wearable, 1 is badge, 2 is consumable
    int16 kinshipBonus; //[CONSUMABLE ONLY] How much this consumable boosts (or reduces) kinship score
    uint32 experienceBonus; //[CONSUMABLE ONLY]
}

struct ItemIdIO {
        uint256 itemId;
        uint256 balance;
    }

struct WearableSet {
    string name;
    uint8[] allowedCollaterals;
    uint16[] wearableIds; // The tokenIdS of each piece of the set
    int8[TRAIT_BONUSES_NUM] traitsBonuses;
}

struct Haunt {
    uint256 hauntMaxSize; //The max size of the Haunt
    uint256 portalPrice;
    bytes3 bodyColor;
    uint24 totalCount;
}

struct SvgLayer {
    address svgLayersContract;
    uint16 offset;
    uint16 size;
}

struct AavegotchiCollateralTypeInfo {
    // treated as an arary of int8
    int16[NUMERIC_TRAITS_NUM] modifiers; //Trait modifiers for each collateral. Can be 2, 1, -1, or -2
    bytes3 primaryColor;
    bytes3 secondaryColor;
    bytes3 cheekColor;
    uint8 svgId;
    uint8 eyeShapeSvgId;
    uint16 conversionRate; //Current conversionRate for the price of this collateral in relation to 1 USD. Can be updated by the DAO
    bool delisted;
}

struct ERC1155Listing {
    uint256 listingId;
    address seller;
    address erc1155TokenAddress;
    uint256 erc1155TypeId;
    uint256 category; // 0 is wearable, 1 is badge, 2 is consumable, 3 is tickets
    uint256 quantity;
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timeLastPurchased;
    uint256 sourceListingId;
    bool sold;
    bool cancelled;
}

struct ERC721Listing {
    uint256 listingId;
    address seller;
    address erc721TokenAddress;
    uint256 erc721TokenId;
    uint256 category; // 0 is closed portal, 1 is vrf pending, 2 is open portal, 3 is Aavegotchi
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timePurchased;
    bool cancelled;
}

struct ListingListItem {
    uint256 parentListingId;
    uint256 listingId;
    uint256 childListingId;
}

struct GameManager {
    uint256 limit;
    uint256 balance;
    uint256 refreshTime;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}