// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./IAcquisitionRoyaleConsumables.sol";

contract AcquisitionRoyaleConsumables is
    ERC1155Supply,
    IAcquisitionRoyaleConsumables,
    Ownable
{
    ///@dev OpenSea requires a name & symbol for ERC1155 collections, else they will show up as "unidentified contract"
    string public name;
    string public symbol;

    string private _renameUri;
    string private _rebrandUri;
    string private _reviveUri;
    address private _acquisitionRoyale;

    modifier onlyAcquisitionRoyale {
        require(
            _msgSender() == _acquisitionRoyale,
            "caller is not Acquisition Royale"
        );
        _;
    }

    /// @dev Pass in blank URI for OZ ERC1155 constructor since custom URIs are used for each consumable.
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _newRenameUri,
        string memory _newRebrandUri,
        string memory _newReviveUri,
        address _newAcquisitionRoyale
    ) ERC1155("") {
        name = _name;
        symbol = _symbol;
        _acquisitionRoyale = _newAcquisitionRoyale;
        _renameUri = _newRenameUri;
        _rebrandUri = _newRebrandUri;
        _reviveUri = _newReviveUri;
        // 10000 Rename tokens
        _mint(owner(), 0, 10000, "");
        // 1000 Rebrand tokens
        _mint(owner(), 1, 1000, "");
        // 100 Revive tokens
        _mint(owner(), 2, 100, "");
    }

    function setRenameUri(string memory _newRenameUri)
        external
        override
        onlyOwner
    {
        _renameUri = _newRenameUri;
        ///@dev mandated by ERC-1155 standard
        emit URI(_renameUri, 0);
    }

    function setRebrandUri(string memory _newRebrandUri)
        external
        override
        onlyOwner
    {
        _rebrandUri = _newRebrandUri;
        ///@dev mandated by ERC-1155 standard
        emit URI(_rebrandUri, 1);
    }

    function setReviveUri(string memory _newReviveUri)
        external
        override
        onlyOwner
    {
        _reviveUri = _newReviveUri;
        ///@dev mandated by ERC-1155 standard
        emit URI(_reviveUri, 2);
    }

    function setName(string memory _newName) external override onlyOwner {
        name = _newName;
        emit NameChanged(name);
    }

    function setSymbol(string memory _newSymbol) external override onlyOwner {
        symbol = _newSymbol;
        emit SymbolChanged(symbol);
    }

    function burn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) external override onlyAcquisitionRoyale {
        _burn(_account, _id, _amount);
    }

    function getRenameUri() external view override returns (string memory) {
        return _renameUri;
    }

    function getRebrandUri() external view override returns (string memory) {
        return _rebrandUri;
    }

    function getReviveUri() external view override returns (string memory) {
        return _reviveUri;
    }

    function getAcquisitionRoyale() external view override returns (address) {
        return _acquisitionRoyale;
    }

    function uri(uint256 _id)
        public
        view
        override(ERC1155, IERC1155MetadataURI)
        returns (string memory)
    {
        if (_id == 0) {
            return _renameUri;
        } else if (_id == 1) {
            return _rebrandUri;
        } else if (_id == 2) {
            return _reviveUri;
        } else {
            return "";
        }
    }
}