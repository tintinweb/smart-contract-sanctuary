// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./IAcquisitionRoyale.sol";
import "./IAcquisitionRoyaleConsumables.sol";

contract AcquisitionRoyaleRPShop is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    IERC20 private _runwayPoints;
    IAcquisitionRoyale private _acquisitionRoyale;
    IAcquisitionRoyaleConsumables private _consumables;
    // Settable
    uint256 private _renameTokenRpPrice;
    uint256 private _rebrandTokenRpPrice;
    uint256 private _reviveTokenRpPrice;
    uint256 private _enterpriseRpPrice;

    function initialize(
        address _newRunwayPoints,
        address _newAcquisitionRoyale,
        address _newConsumables,
        uint256 _newRenameTokenRpPrice,
        uint256 _newRebrandTokenRpPrice,
        uint256 _newReviveTokenRpPrice,
        uint256 _newEnterpriseRpPrice
    ) public initializer {
        __Ownable_init();
        _runwayPoints = IERC20(_newRunwayPoints);
        _acquisitionRoyale = IAcquisitionRoyale(_newAcquisitionRoyale);
        _consumables = IAcquisitionRoyaleConsumables(_newConsumables);
        _renameTokenRpPrice = _newRenameTokenRpPrice;
        _rebrandTokenRpPrice = _newRebrandTokenRpPrice;
        _reviveTokenRpPrice = _newReviveTokenRpPrice;
        _enterpriseRpPrice = _newEnterpriseRpPrice;
    }

    function purchaseConsumable(uint256 _tokenId, uint256 _qty)
        external
        nonReentrant
    {
        require(_tokenId < 3, "Invalid Consumable ID");
        uint256 _tokenPrice;
        if (_tokenId == 0) {
            _tokenPrice = _renameTokenRpPrice;
        } else if (_tokenId == 1) {
            _tokenPrice = _rebrandTokenRpPrice;
        } else if (_tokenId == 2) {
            _tokenPrice = _reviveTokenRpPrice;
        }
        _runwayPoints.safeTransferFrom(
            msg.sender,
            owner(),
            _qty * _tokenPrice
        );
        _consumables.safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            _qty,
            ""
        );
    }

    function purchaseEnterprise(uint256 _qty) external nonReentrant {
        require(_qty > 0, "Quantity cannot be zero");
        require(
            _qty <= _acquisitionRoyale.balanceOf(address(this)),
            "Exceeds shop's Enterprise supply"
        );
        _runwayPoints.safeTransferFrom(
            msg.sender,
            owner(),
            _qty * _enterpriseRpPrice
        );
        for (uint256 i = 0; i < _qty; i++) {
            /**
             * Every transfer will update list of tokens owned by this
             * contract, so transfer the top element until we have sent
             * all the requested Enterprises.
             */
            _acquisitionRoyale.safeTransferFrom(
                address(this),
                msg.sender,
                _acquisitionRoyale.tokenOfOwnerByIndex(address(this), 0)
            );
        }
    }

    function ownerConsumablesWithdraw(uint256 _tokenId, uint256 _qty)
        external
        onlyOwner
    {
        _consumables.safeTransferFrom(
            address(this),
            owner(),
            _tokenId,
            _qty,
            ""
        );
    }

    function ownerEnterpriseWithdraw(uint256 _tokenId, uint256 _qty)
        external
        onlyOwner
    {
        require(_qty > 0, "Quantity cannot be zero");
        if (_qty == 1) {
            _acquisitionRoyale.safeTransferFrom(
                address(this),
                owner(),
                _tokenId
            );
        } else {
            require(
                _qty <= _acquisitionRoyale.balanceOf(address(this)),
                "Exceeds shop's Enterprise supply"
            );
            for (uint256 i = 0; i < _qty; i++) {
                /**
                 * Every transfer will update list of tokens owned by this
                 * contract, so transfer the top element until we have sent
                 * all the requested Enterprises.
                 */
                _acquisitionRoyale.safeTransferFrom(
                    address(this),
                    owner(),
                    _acquisitionRoyale.tokenOfOwnerByIndex(address(this), 0)
                );
            }
        }
    }

    function setRenameTokenRpPrice(uint256 _newRpPrice) external onlyOwner {
        _renameTokenRpPrice = _newRpPrice;
    }

    function setRebrandTokenRpPrice(uint256 _newRpPrice) external onlyOwner {
        _rebrandTokenRpPrice = _newRpPrice;
    }

    function setReviveTokenRpPrice(uint256 _newRpPrice) external onlyOwner {
        _reviveTokenRpPrice = _newRpPrice;
    }

    function setEnterpriseRpPrice(uint256 _newRpPrice) external onlyOwner {
        _enterpriseRpPrice = _newRpPrice;
    }

    function getRunwayPoints() external view returns (IERC20) {
        return _runwayPoints;
    }

    function getAcquisitionRoyale()
        external
        view
        returns (IAcquisitionRoyale)
    {
        return _acquisitionRoyale;
    }

    function getConsumables()
        external
        view
        returns (IAcquisitionRoyaleConsumables)
    {
        return _consumables;
    }

    function getRenameTokenRpPrice() external view returns (uint256) {
        return _renameTokenRpPrice;
    }

    function getRebrandTokenRpPrice() external view returns (uint256) {
        return _rebrandTokenRpPrice;
    }

    function getReviveTokenRpPrice() external view returns (uint256) {
        return _reviveTokenRpPrice;
    }

    function getEnterpriseRpPrice() external view returns (uint256) {
        return _enterpriseRpPrice;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // Added for supporting Enterprise transfers in the future.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}