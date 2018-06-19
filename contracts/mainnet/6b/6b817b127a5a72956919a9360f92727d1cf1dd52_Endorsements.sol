pragma solidity ^0.4.21;

/// @title Endorsements
/// @author AlmavivA S.p.A. (Enrica D&#39;Agostini, Giuseppe Bertone, et al.)
/// @notice This contract add external/internal endorsement to supply chain actors and operations
/// @dev This contract is part of the WineSupplyChain contract, and it is not meant to be used as
/// a standalone contract
contract Endorsements {

    struct Endorsement {
        bool positive;
        string title;
        string description;
        address endorser;
    }

    mapping (address => Endorsement[]) public userEndorsements;
    mapping (bytes32 => Endorsement[]) public vineyardEndorsements;
    mapping (bytes32 => Endorsement[]) public harvestOperationEndorsements;
    mapping (bytes32 => Endorsement[]) public wineryOperationEndorsements;
    mapping (bytes32 => Endorsement[]) public productOperationEndorsements;

    function Endorsements() public { }

    /// @notice Add new endorsement to an actor
    /// @param user Actor&#39;s on-chain identity
    /// @param positive True if it is a `positive` endorsement
    /// @param title Endorsment&#39;s short description
    /// @param description Endorsement&#39;s full description
    function addUserEndorsement(
        address user,
        bool positive,
        string title,
        string description
    )
        external
        returns (bool success)
    {
        userEndorsements[user].push(Endorsement(positive, title, description, msg.sender));
        return true;
    }

    /// @notice Add new endorsement to a vineyard
    /// @param _mappingID On-chain key to identify the harvest operation
    /// @param _index Index of vineyard for the harvest
    /// @param positive True if it is a `positive` endorsement
    /// @param title Endorsement&#39;s short description
    /// @param description Endorsement&#39;s full description
    function addVineyardEndorsement(
        string _mappingID,
        uint _index,
        bool positive,
        string title,
        string description
    )
        external
        returns (bool success)
    {
        vineyardEndorsements[keccak256(_mappingID, _index)].push(
                Endorsement(positive, title, description, msg.sender)
        );
        return true;
    }

    /// @notice Add new endorsement to harvest operation
    /// @param _mappingID On-chain key to identify the harvest operation
    /// @param positive True if it is a `positive` endorsement
    /// @param title Endorsement&#39;s short description
    /// @param description Endorsement&#39;s full description
    function addHarvestOperationEndorsement(
        string _mappingID,
        bool positive,
        string title,
        string description
    )
        external
        returns (bool success)
    {
        harvestOperationEndorsements[keccak256(_mappingID)].push(
                Endorsement(positive, title, description, msg.sender)
        );
        return true;
    }

    /// @notice Add new endorsement to a winery operation
    /// @param _mappingID On-chain key to identify the winery operation
    /// @param _index Index of operation
    /// @param positive True if it is a `positive` endorsement
    /// @param title Endorsement&#39;s short description
    /// @param description Endorsement&#39;s full description
    function addWineryOperationEndorsement(
        string _mappingID,
        uint _index,
        bool positive,
        string title,
        string description
    )
        external
        returns (bool success)
    {
        wineryOperationEndorsements[keccak256(_mappingID, _index)].push(
                Endorsement(positive, title, description, msg.sender)
        );
        return true;
    }

    /// @notice Add new endorsement to product winery operation
    /// @param _mappingID On-chain key to identify the winery operation
    /// @param _operationIndex Index of operation
    /// @param _productIndex Index of operation product
    /// @param positive True if it is a `positive` endorsement
    /// @param title Endorsement&#39;s short description
    /// @param description Endorsement&#39;s full description
    function addProductEndorsement(
        string _mappingID,
        uint _operationIndex,
        int _productIndex,
        bool positive,
        string title,
        string description
    )
        external
        returns (bool success)
    {
        require(_productIndex > 0);
        productOperationEndorsements[keccak256(_mappingID, _operationIndex, _productIndex)].push(
                Endorsement(positive, title, description, msg.sender)
        );
        return true;
    }

}