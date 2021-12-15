pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC2981PerTokenRoyalties.sol";

contract NFT is ERC1155, ERC2981PerTokenRoyalties, Ownable {

    uint256 public royalty = 500;
    uint256 public mintingFee = 500;
    uint256 public sellingFee = 500;
    string uri;

    event Sale(uint256 tokenId, address seller, address buyer, uint256 value);

    constructor(string memory _uri) ERC1155(_uri)
    public {
        uri = _uri;
    }

    function supportsInterface(bytes4 interfaceId)
    public view
    virtual override(ERC165, ERC2981Base)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRoyalty(uint256 tokenId, address recipient, uint256 value)
    external
    onlyOwner {
        if (value > 0) {
            _setTokenRoyalty(tokenId, recipient, value);
        }
    }

    function setMintingFee(uint256 tokenId, address recipient, uint256 value)
    external
    onlyOwner {
        if (value > 0) {
            _setMintingFee(tokenId, recipient, value);
        }
    }

    function setSellingFee(uint256 tokenId, address recipient, uint256 value)
    external
    onlyOwner {
        if (value > 0) {
            _setSellingFee(tokenId, recipient, value);
        }
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        address royaltyRecipient,
        uint256 royaltyValue,
        uint256 mintingValue)
    external
    payable {
        (address receiver, uint256 feeAmount) = mintingInfo(id);
        safeTransferFrom(to, msg.sender, id, feeAmount, '');

        _mint(to, id, amount, '1');

        if (royaltyValue > 0) {
            _setTokenRoyalty(id, royaltyRecipient, royaltyValue);
        }
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address[] calldata royaltyRecipients,
        uint256[] calldata royaltyValues,
        uint256[] calldata mintingValues)
    external onlyOwner {
        require(
            ids.length == royaltyRecipients.length &&
            ids.length == royaltyValues.length &&
            ids.length == mintingValues.length,
            'ERC1155: Arrays length mismatch'
        );


        uint256[] memory feeAmounts = new uint256[](ids.length);    

        (address receiver1, uint256 feeAmount1) = mintingInfo(ids[0]);

        for (uint256 i; i < ids.length; i++) {
            feeAmounts[i] = feeAmount1;
        }

        safeBatchTransferFrom(to, msg.sender, ids, feeAmounts, '');

        _mintBatch(to, ids, amounts, '');

        for (uint256 i; i < ids.length; i++) {
            if (royaltyValues[i] > 0) {
                _setTokenRoyalty(
                    ids[i],
                    royaltyRecipients[i],
                    royaltyValues[i]
                );
            }
        }
    }

    function transferNFT(
        address from,
        address to,
        uint256 id,
        uint256 amount)
    external
    payable {
        (address receiver, uint256 feeAmount) = sellingInfo(id);
        uint256 salePrice = amount - amount * feeAmount;
        to.call{value: salePrice}('');
        safeTransferFrom(from, to, id, salePrice, '');

        (address receiver2, uint256 royaltyAmount2) = royaltyInfo(id);
        uint256 royaltyPrice = amount - amount * royaltyAmount2;
        from.call{value: royaltyPrice}('');

        emit Sale(id, from, to, amount);
    }
}