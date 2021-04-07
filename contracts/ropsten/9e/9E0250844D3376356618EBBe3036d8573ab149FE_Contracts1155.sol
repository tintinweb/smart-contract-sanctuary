pragma solidity ^0.5.0;

import "./ERC1155MixedFungibleMintable.sol";
import "./ERC1155MockReceiver.sol";

contract Contracts1155 is ERC1155MixedFungibleMintable, ERC1155MockReceiver {
    constructor() public {
//        uint256 GOLD_TYPE = _create("https://cdn.test.com", false);
//        _mintFungible(GOLD_TYPE, [msg.sender], [10 ** 18]);
    }

//    modifier creatorOnlyPrivate(uint256 _id) {
//        require(creators[_id] == msg.sender);
//        _;
//    }
//
//    function _create(
//        string memory _uri,
//        bool   _isNF)
//    private returns(uint256 _type) {
//
//        // Store the type in the upper 128 bits
//        _type = (++nonce << 128);
//
//        // Set a flag if this is an NFI.
//        if (_isNF)
//            _type = _type | TYPE_NF_BIT;
//
//        // This will allow restricted access to creators.
//        creators[_type] = msg.sender;
//
//        // emit a Transfer event with Create semantic to help with discovery.
//        emit TransferSingle(msg.sender, address(0x0), address(0x0), _type, 0);
//
//        if (bytes(_uri).length > 0)
//            emit URI(_uri, _type);
//    }
//
//    function _mintFungible(uint256 _id, address[] memory _to, uint256[] memory _quantities) private creatorOnlyPrivate(_id) {
//
//        require(isFungible(_id));
//
//        for (uint256 i = 0; i < _to.length; ++i) {
//
//            address to = _to[i];
//            uint256 quantity = _quantities[i];
//
//            // Grant the items to the caller
//            balances[_id][to] = quantity.add(balances[_id][to]);
//
//            // Emit the Transfer/Mint event.
//            // the 0x0 source address implies a mint
//            // It will also provide the circulating supply info.
//            emit TransferSingle(msg.sender, address(0x0), to, _id, quantity);
//
//            if (to.isContract()) {
//                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, to, _id, quantity, '');
//            }
//        }
//    }
}