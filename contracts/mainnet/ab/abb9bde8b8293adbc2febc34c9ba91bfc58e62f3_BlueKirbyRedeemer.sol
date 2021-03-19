pragma solidity ^0.6.2;

import "./IERC1155-0.6.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";

/**
 * @title BlueKirbyRedeemer
 */
contract BlueKirbyRedeemer is Ownable, ERC1155Holder {
    IERC1155 private _collectible;
    address _owner;
    uint256 public nextRedeemableTokenIndex = 0;
    uint256 public nextAdditionalTokenIndex = 0;
    mapping(uint256 => uint256) public tokenIDs; 
    mapping(address => bool) public vouchers;

    event RedeemedBlueKirby(uint256 tokenID, address redeemer);

    constructor (address collectible) public {
        _collectible = IERC1155(collectible);
    }

    function _setCollectibleAddr(address _address) public onlyOwner {
        _collectible = IERC1155(_address);
    }

    function makeAddressesRedeemable(address[] calldata validAddrs) external onlyOwner {
        for (uint256 i = 0; i < validAddrs.length; i++) {
            vouchers[validAddrs[i]] = true;
        }
    }

    function revokeAddressVoucher(address _address) public onlyOwner {
        delete vouchers[_address];
    }
    
    function redeemAtIndex(uint256 index, address redeemer) public onlyOwner {
        uint256 tokenID = tokenIDs[index];
        require(tokenID > 0, "BlueKirbyRedeemer: No token at supplied index!");
        _collectible.safeTransferFrom(address(this), redeemer, tokenID, 1, "");
        emit RedeemedBlueKirby(tokenID, redeemer);
    }

    function redeem(address redeemer) public {
        require(vouchers[redeemer], "BlueKirbyRedeemer: Address does not have a voucher.");
        // require tokens are left to redeem
        require(nextRedeemableTokenIndex < nextAdditionalTokenIndex, "BlueKirbyRedeemer: No more tokens left to redeem!");
        uint256 tokenID = tokenIDs[nextRedeemableTokenIndex];
        nextRedeemableTokenIndex++;
        _collectible.safeTransferFrom(address(this), redeemer, tokenID, 1, "");
        emit RedeemedBlueKirby(tokenID, redeemer);
        delete vouchers[redeemer];
    }

    function setOwnedTokenIDs(uint256[] calldata _tokenIDs) external onlyOwner {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            require(_collectible.balanceOf(address(this), _tokenIDs[i]) == 1, "BlueKirbyRedeemer: Not an owner of token");
            tokenIDs[nextAdditionalTokenIndex] = _tokenIDs[i];
            nextAdditionalTokenIndex++;
        }
    }

    function resetTokenIDs(uint256 _fromIdx, uint256 _toIdx) public onlyOwner {
        for (uint256 i = _fromIdx; i < _toIdx; i++) {
            delete tokenIDs[i];
        }
    }

    function resetPointers(uint256 _nextRedeemableTokenIndex, uint256 _nextAdditionalTokenIndex) public onlyOwner {
        nextRedeemableTokenIndex = _nextRedeemableTokenIndex;
        nextAdditionalTokenIndex = _nextAdditionalTokenIndex;
    }
}