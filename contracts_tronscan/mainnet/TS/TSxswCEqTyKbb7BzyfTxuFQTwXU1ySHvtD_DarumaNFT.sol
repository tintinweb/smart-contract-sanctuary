//SourceUnit: DarumaNFT.sol

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./OwnableAndPausable.sol";

contract DarumaNFT is OwnableAndPausable {
    /**********************/
    // Data Structures and values
    struct Token {
        string token_type;
        string reference_identifier;
    }

    struct TrackingStep {
        string data;
    }

    Token[] private tokens;

    //mapping da tokenId a TrackingStep
    mapping(uint256 => TrackingStep[]) tokenTrackingSteps;

    // Mapping referenceIdentifier to a token id
    mapping(string => uint256) referenceToTokenId;

    /**********************/
    // Events
    event TokenCreated(uint256 tokenId, address creatorAddress, string referenceIdentifier);
    event TrackingStepAdded(uint256 tokenId, string data);

    /**********************/
    // Contract
    constructor() public {
    }

    // Transfers ownership of the contract to a new account (`newOwner`).
    function transferContractOwnership(address _newOwner) public {
        require(isOwner(), "Ownable: caller is not the owner");
        _transferOwnership(_newOwner);
    }

    // Internal function to add a token
    function _createToken(string memory _tokenType, string memory _referenceIdentifier) internal {
        Token memory newToken;
        newToken.token_type = _tokenType;
        newToken.reference_identifier = _referenceIdentifier;
        uint256 newTokenId = tokens.push(newToken) - 1;

        // map reference to token id
        referenceToTokenId[_referenceIdentifier] = newTokenId;

        emit TokenCreated(newTokenId, msg.sender, tokens[newTokenId].reference_identifier);
    }

    // Public function to add single token
    function createToken(string memory _tokenType, string memory _referenceIdentifier) public whenNotPaused {
        require(isOwner(), "Ownable: caller is not the owner");

        _createToken(_tokenType, _referenceIdentifier);
    }

    // Internal function to add a tracking step to a token
    function _addTrackingStep(uint256 _tokenId, string memory _data) internal {
        TrackingStep memory newTrackingStep;
        newTrackingStep.data = _data;
        tokenTrackingSteps[_tokenId].push(newTrackingStep);

        emit TrackingStepAdded(_tokenId, _data);
    }

    // Add a single tracking step to a specific token
    function addTrackingStep(uint256 _tokenId, string memory _data) public whenNotPaused {
        require(isOwner(), "Ownable: caller is not the owner");
        _addTrackingStep(_tokenId, _data);
    }

    /**********************/
    // Getters
    function getTokenById(uint256 _tokenId) public view returns (string memory tokenType, string memory referenceIdentifier){
        // copy the data into memory
        Token memory token = tokens[_tokenId];

        // break the struct's members out into a tuple
        // in the same order that they appear in the struct
        return (token.token_type, token.reference_identifier);
    }

    function getTokenByReferenceIdentifier(string memory _referenceIdentifier) public view returns (uint, string memory, string memory){
        // get token id by reference
        uint tokenId = referenceToTokenId[_referenceIdentifier];
        // copy the data into memory
        Token memory token = tokens[tokenId];

        // break the structs members out into a tuple
        // in the same order that they appear in the struct
        return (tokenId, token.token_type, token.reference_identifier);
    }

    // Get all tracking steps of a token by id
    function getTrackingStepsOfToken(uint256 _tokenId) public view returns (string[] memory){
        // copy the data into memory
        TrackingStep[] memory trackingSteps = tokenTrackingSteps[_tokenId];

        string[] memory steps = new string[](trackingSteps.length);

        for (uint i = 0; i < trackingSteps.length; i++) {
            steps[i] = trackingSteps[i].data;
        }

        return (steps);
    }

    // Get all tracking steps of a token by reference_identifier
    function getTrackingStepsOfToken(string memory _tokenReferenceIdentifier) public view returns (string[] memory){
        // get token id by reference
        uint tokenId = referenceToTokenId[_tokenReferenceIdentifier];

        // copy the data into memory
        Token memory token = tokens[tokenId];
        // break the struct's members out into a tuple
        // in the same order that they appear in the struct

        // copy the data into memory
        TrackingStep[] memory trackingSteps = tokenTrackingSteps[tokenId];

        string[] memory steps = new string[](trackingSteps.length);

        for (uint i = 0; i < trackingSteps.length; i++) {
            steps[i] = trackingSteps[i].data;
        }

        return (steps);
    }
}


//SourceUnit: OwnableAndPausable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract OwnableAndPausable {
    address private _owner;
    bool private _paused;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    constructor () internal {
        _owner = msg.sender;
        _paused = false;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGenuino() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }
    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


    function paused() public view returns (bool) {
        return _paused;
    }
    
    function pause() public onlyGenuino whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyGenuino whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}