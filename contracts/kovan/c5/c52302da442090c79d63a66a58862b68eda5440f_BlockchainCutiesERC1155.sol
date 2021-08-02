pragma solidity ^0.5.0;

import "./ERC1155MixedFungible.sol";
import "./ERC1155Metadata_URI.sol";
import "./ERC1155URIProvider.sol";
import "./IERC1155Mintable.sol";
import "./Operators.sol";
import "./ERC20.sol";
import "./ERC721.sol";
import "./MintCallbackInterface.sol";

/**
    @title Blockchain Cuties Collectible contract.
    @dev Mixed Fungible Mintable form of ERC1155
    Shows how easy it is to mint new items
*/
contract BlockchainCutiesERC1155 is ERC1155MixedFungible, Operators, ERC1155Metadata_URI, IERC1155Mintable {

    mapping (uint256 => uint256) public maxIndex;

    mapping(uint256 => ERC721) public proxy721;
    mapping(uint256 => ERC20) public proxy20;

    mapping(uint256 => bool) public disallowSetProxy721;
    mapping(uint256 => bool) public disallowSetProxy20;

    ERC1155URIProvider public uriProvider;
    MintCallbackInterface public mintCallback;

    bytes4 constant private INTERFACE_SIGNATURE_ERC1155_URI = 0x0e89341c;

    function supportsInterface(bytes4 _interfaceId) public view returns (bool) {
        return
            super.supportsInterface(_interfaceId) ||
            _interfaceId == INTERFACE_SIGNATURE_ERC1155_URI;
    }

    // This function only creates the type.
    // _type must be shifted by 128 bits left
    // for NFT TYPE_NF_BIT should be added to _type
    function create(uint256 _type) onlyOwner external {
        // emit a Transfer event with Create semantic to help with discovery.
        emit TransferSingle(msg.sender, address(0x0), address(0x0), _type, 0);
    }

    function setMintCallback(MintCallbackInterface _newCallback) external onlyOwner {
        mintCallback = _newCallback;
    }

    function mintNonFungibleSingleShort(uint128 _type, address _to) external onlyOperator {
        uint tokenType = (uint256(_type) << 128) | (1 << 255);
        _mintNonFungibleSingle(tokenType, _to);
    }

    function mintNonFungibleSingle(uint256 _type, address _to) external onlyOperator {
        // No need to check this is a nf type
        require(isNonFungible(_type), "ERC1155: unknown NFT token type");
        require(getNonFungibleIndex(_type) == 0, "ERC1155: unknown NFT token type");

        _mintNonFungibleSingle(_type, _to);
    }

    function _mintNonFungibleSingle(uint256 _type, address _to) internal {

        // Index are 1-based.
        uint256 index = maxIndex[_type] + 1;

        uint256 id  = _type | index;

        nfOwners[id] = _to;

        onTransferNft(address(0x0), _to, id);

        balances[_type][_to] = balances[_type][_to].add(1);

        emit TransferSingle(msg.sender, address(0x0), _to, id, 1);

        maxIndex[_type] = maxIndex[_type].add(1);

        if (address(mintCallback) != address(0)) {
            mintCallback.onMint(id);
        }

        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, _to, id, 1, '');
        }
    }

    function mintNonFungibleShort(uint128 _type, address[] calldata _to) external onlyOperator {
        uint tokenType = (uint256(_type) << 128) | (1 << 255);
        _mintNonFungible(tokenType, _to);
    }

    function mintNonFungible(uint256 _type, address[] calldata _to) external onlyOperator {
        // No need to check this is a nf type
        require(isNonFungible(_type), "ERC1155: token is not non-fungible");
        _mintNonFungible(_type, _to);
    }

    function _mintNonFungible(uint256 _type, address[] memory _to) internal {

        // Index are 1-based.
        uint256 index = maxIndex[_type] + 1;

        for (uint256 i = 0; i < _to.length; ++i) {
            address dst = _to[i];
            uint256 id  = _type | index + i;

            nfOwners[id] = dst;

            onTransferNft(address(0x0), dst, id);

            balances[_type][dst] = balances[_type][dst].add(1);

            emit TransferSingle(msg.sender, address(0x0), dst, id, 1);

            if (address(mintCallback) != address(0)) {
                mintCallback.onMint(id);
            }
            if (dst.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, dst, id, 1, '');
            }
        }

        maxIndex[_type] = _to.length.add(maxIndex[_type]);
    }

    function mintFungibleSingle(uint256 _id, address _to, uint256 _quantity) external onlyOperator {
        require(isFungible(_id), "ERC1155: token is not fungible");

        // Grant the items to the caller
        balances[_id][_to] = _quantity.add(balances[_id][_to]);

        // Emit the Transfer/Mint event.
        // the 0x0 source address implies a mint
        // It will also provide the circulating supply info.
        emit TransferSingle(msg.sender, address(0x0), _to, _id, _quantity);
        onTransfer20(address(0x0), _to, _id, _quantity);

        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, _to, _id, _quantity, '');
        }
    }

    function mintFungible(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external onlyOperator {
        require(isFungible(_id), "ERC1155: token is not fungible");

        for (uint256 i = 0; i < _to.length; ++i) {
            address to = _to[i];
            uint256 quantity = _quantities[i];

            // Grant the items to the caller
            balances[_id][to] = quantity.add(balances[_id][to]);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), to, _id, quantity);
            onTransfer20(address(0x0), to, _id, quantity);

            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, to, _id, quantity, '');
            }
        }
    }

    function setURI(string calldata _uri, uint256 _id) external onlyOperator {
        emit URI(_uri, _id);
    }

    function setUriProvider(ERC1155URIProvider _uriProvider) onlyOwner external {
        uriProvider = _uriProvider;
    }

    function uri(uint256 _id) external view returns (string memory) {
        return uriProvider.uri(_id);
    }

    function withdraw() external onlyOwner {
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    function withdrawERC20(ERC20 _tokenContract) external onlyOwner {
        uint256 balance = _tokenContract.balanceOf(address(this));
        if (balance > 0) {
            _tokenContract.transfer(msg.sender, balance);
        }
    }

    function approveERC721(ERC721 _tokenContract) external onlyOwner {
        _tokenContract.setApprovalForAll(msg.sender, true);
    }

    function totalSupplyNonFungible(uint256 _type) view external returns (uint256) {
        // No need to check this is a nf type
        require(isNonFungible(_type), "ERC1155: token type is not non-fungible");
        return maxIndex[_type];
    }

    function totalSupplyNonFungibleShort(uint128 _type) view external returns (uint256) {
        uint tokenType = (uint256(_type) << 128) | (1 << 255);
        return maxIndex[tokenType];
    }

    function setProxy721(uint256 nftType, ERC721 proxy) external onlyOwner {
        require(!disallowSetProxy721[nftType], "ERC1155-ERC721: token setup forbidden");
        proxy721[nftType] = proxy;
    }

    // @dev can be only disabled. There is not way to enable later.
    function disableSetProxy721(uint256 nftType) external onlyOwner {
        disallowSetProxy721[nftType] = true;
    }

    function setProxy20(uint256 _type, ERC20 proxy) external onlyOwner {
        require(!disallowSetProxy20[_type], "ERC1155-ERC20: token setup forbidden");
        proxy20[_type] = proxy;
    }

    // @dev can be only disabled. There is not way to enable later.
    function disableSetProxy20(uint256 _type) external onlyOwner {
        disallowSetProxy20[_type] = true;
    }

    /**
     * @dev Transfer token when proxy contract transfer is called
     * @param _from address representing the previous owner of the given token ID
     * @param _to address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
     * @param _data bytes some arbitrary data
     */
    function proxyTransfer721(address _from, address _to, uint256 _tokenId, bytes calldata _data) external {
        uint256 nftType = getNFTType(_tokenId);
        ERC721 proxy = proxy721[nftType];

        require(msg.sender == address(proxy), "ERC1155-ERC721: caller is not token contract");
        require(_ownerOf(_tokenId) == _from, "ERC1155-ERC721: cannot transfer token to itself");

        // gives approval for proxy token contracts
        operatorApproval[_from][address(proxy)] = true;

        safeTransferFrom(_from, _to, _tokenId, 1, _data);
    }

    // override
    function onTransferNft(address _from, address _to, uint256 _tokenId) internal {
        uint256 nftType = getNFTType(_tokenId);
        uint256 nftIndex = getNonFungibleIndex(_tokenId);
        ERC721 proxy = proxy721[nftType];

        // if a token has proxy contract call onTransfer
        if (address(proxy) != address(0x0)) {
            proxy.onTransfer(_from, _to, nftIndex);
        }
    }

    function proxyTransfer20(address _from, address _to, uint256 _tokenId, uint256 _value) external {
        ERC20 proxy = proxy20[_tokenId];

        require(msg.sender == address(proxy), "ERC1155-ERC20: caller is not token contract");
        require(_to != address(0x0), "ERC1155-ERC20: cannot send to zero address");

        balances[_tokenId][_from] = balances[_tokenId][_from].sub(_value);
        balances[_tokenId][_to]   = balances[_tokenId][_to].add(_value);

        emit TransferSingle(msg.sender, _from, _to, _tokenId, _value);
        onTransfer20(_from, _to, _tokenId, _value);
    }

    // override
    function onTransfer20(address _from, address _to, uint256 _tokenId, uint256 _value) internal {
        ERC20 proxy = proxy20[_tokenId];

        // if a token has proxy contract call onTransfer
        if (address(proxy) != address(0x0)) {
            proxy.onTransfer(_from, _to, _value);
        }
    }

    // override
    function burn(address _from, uint256 _id, uint256 _value) external {
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "ERC1155: Need operator approval for 3rd party transfers.");

        address to = address(0x0);

        if (isNonFungible(_id)) {
            require(nfOwners[_id] == _from, "ERC1155: not a token owner");
            nfOwners[_id] = to;

            onTransferNft(_from, to, _id);

            uint256 baseType = getNonFungibleBaseType(_id);
            balances[baseType][_from] = balances[baseType][_from].sub(_value);
            balances[baseType][to] = balances[baseType][to].add(_value);
        } else {
            onTransfer20(_from, to, _id, _value);

            balances[_id][_from] = balances[_id][_from].sub(_value);
            balances[_id][to]   = balances[_id][to].add(_value);
        }

        emit TransferSingle(msg.sender, _from, to, _id, _value);
    }
}