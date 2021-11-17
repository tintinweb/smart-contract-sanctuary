pragma solidity ^0.8.7;

import './IERC721.sol';
import './IERC721Enumerable.sol';
import './IERC721Metadata.sol';
import './IERC721Receiver.sol';
import './ERC165.sol';

contract MyNFT is ERC165, IERC721, IERC721Enumerable, IERC721Metadata {
    
    string constant private tokenName = "AD-NFT";
    string constant private tokenSymbol = "ADFT";
    address payable public owner;
    address payable public subOwner;
    
    uint256 public MAX_TOKENS = 1000;
    uint256 public MAX_ADFT_MINT = 5;
    uint256 public ADFT_MINT_PRICE = 20000000000000000;
    
    // Mapping from token ID to owner address
    mapping(uint256 => address) private tokenOwners;

    // Mapping owner address to token count
    mapping(address => uint256) private balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals;
    
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private allTokensIndex;
    
    constructor(address _subOwner, uint256 _initTokenSupply) {
        owner = payable(msg.sender);
        subOwner = payable(_subOwner);
    }
    
    function mintADFTs(uint _count) external payable {
        require(_count <= MAX_ADFT_MINT, "Mint too large");
        require(msg.value >= _count * ADFT_MINT_PRICE, "Mint price not met");
        require(allTokens.length + _count <= MAX_TOKENS, "Not enough tokens left");
        uint startLength = allTokens.length;
        for(uint i = allTokens.length; i < startLength + _count; i++) {
            safeMint(msg.sender, i);
        }
    }
    
    function mintADFTsOwner(uint _count) external {
        require(msg.sender == owner, "Minter not owner");
        require(_count <= MAX_ADFT_MINT, "Mint too large");
        require(allTokens.length + _count <= MAX_TOKENS, "Not enough tokens left");
        uint startLength = allTokens.length;
        for(uint i = allTokens.length; i < startLength + _count; i++) {
            safeMint(msg.sender, i);
        }
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    
    function name() external pure override returns (string memory) {
        return tokenName;
    }
    
    function symbol() external pure override returns (string memory) {
        return tokenSymbol;
    }
    
    function withdraw() external {
        require(msg.sender == owner, "Sender not owner");
        require(address(this).balance > 0, "No balance to withdraw");
        (bool ownerSent, bytes memory ownerData) = owner.call{value: address(this).balance / 2}("");
        require(ownerSent, "Failed to send to owner");
        (bool subSent, bytes memory subData) = subOwner.call{value: address(this).balance}("");
        require(subSent, "Failed to send to sub owner");
    }
    
    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        require(tokenOwners[_tokenId] != address(0), "ERC721: query for nonexistent token");
        return "https://adtestnft.s3.us-east-2.amazonaws.com/metadata/TestMetadata.json";
    }
    
    function balanceOf(address _owner) external view override returns (uint256) {
        require(_owner != address(0), "ERC721Enumerable: balance query for the zero address");
        return balances[_owner];
    }
    
    function ownerOf(uint256 _tokenId) external view override returns (address) {
        address tokenOwner = tokenOwners[_tokenId];
        require(tokenOwner != address(0), "ERC721: owner query for nonexistent token");
        return tokenOwner;
    }
    
    function ownerOf_internal(uint256 _tokenId) internal view returns (address) {
        address tokenOwner = tokenOwners[_tokenId];
        require(tokenOwner != address(0), "ERC721: owner query for nonexistent token");
        return tokenOwner;
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable override {
        require(isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        safeTransfer(_from, _to, _tokenId, _data);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable override {
        require(isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        safeTransfer(_from, _to, _tokenId, "");
    }
    
    function safeTransfer(address _from, address _to, uint256 _tokenId, bytes memory _data) internal virtual {
        transfer(_from, _to, _tokenId);
        require(checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable override {
        require(isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        transfer(_from, _to, _tokenId);
    }
    
    function transfer(address _from, address _to, uint256 _tokenId) internal virtual {
        require(ownerOf_internal(_tokenId) == _from, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");

        beforeTokenTransfer(_from, _to, _tokenId);

        // Clear approvals from the previous owner
        subApprove(address(0), _tokenId);

        balances[_from] -= 1;
        balances[_to] += 1;
        tokenOwners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }
    
    function totalSupply() external view override returns (uint256) {
        return allTokens.length;
    }
    
    function tokenByIndex(uint256 _index) external view override returns (uint256) {
        require(_index < allTokens.length, "ERC721Enumerable: global index out of bounds");
        return allTokens[_index];
    }
    
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view override returns (uint256) {
        require(_owner != address(0), "ERC721Enumerable: balance query for the zero address");
        return ownedTokens[_owner][_index];
    }
    
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view virtual returns (bool) {
        require(tokenOwners[_tokenId] != address(0), "ERC721: operator query for nonexistent token");
        address tokenOwner = ownerOf_internal(_tokenId);
        return (_spender == tokenOwner || getApproved(_tokenId) == _spender || isApprovedForAll(tokenOwner, _spender));
    }
    
    function getApproved(uint256 _tokenId) public view virtual override returns (address) {
        require(tokenOwners[_tokenId] != address(0), "ERC721: approved query for nonexistent token");
        return tokenApprovals[_tokenId];
    }
    
    function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool) {
        return operatorApprovals[_owner][_operator];
    }
    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        setApprovalForAll(msg.sender, operator, approved);
    }
    
    function setApprovalForAll(address _owner, address _operator, bool _approved) internal virtual {
        require(_owner != _operator, "ERC721: approve to caller");
        operatorApprovals[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }
    
    function approve(address _to, uint256 _tokenId) public virtual payable override {
        address tokenOwner = ownerOf_internal(_tokenId);
        require(_to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        subApprove(_to, _tokenId);
    }
    
    function subApprove(address _to, uint256 _tokenId) internal virtual {
        tokenApprovals[_tokenId] = _to;
        emit Approval(ownerOf_internal(_tokenId), _to, _tokenId);
    }
    
    function checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private returns (bool) {
        if (isContract(_to)) {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    function isContract(address _account) internal virtual returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        return size > 0;
    }
    
    function safeMint(address _to, uint256 _tokenId) internal virtual {
        safeMint(_to, _tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function safeMint(address _to, uint256 _tokenId, bytes memory _data) internal virtual {
        mint(_to, _tokenId);
        require(
            checkOnERC721Received(address(0), _to, _tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function mint(address _to, uint256 _tokenId) internal virtual {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(!(tokenOwners[_tokenId] != address(0)), "ERC721: token already minted");

        beforeTokenTransfer(address(0), _to, _tokenId);

        balances[_to] += 1;
        tokenOwners[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);
    }
    
    function beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual {
        if (_from == address(0)) {
            addTokenToAllTokensEnumeration(_tokenId);
        } else if (_from != _to) {
            removeTokenFromOwnerEnumeration(_from, _tokenId);
        }
        if (_to == address(0)) {
            removeTokenFromAllTokensEnumeration(_tokenId);
        } else if (_to != _from) {
            addTokenToOwnerEnumeration(_to, _tokenId);
        }
    }
    
    function addTokenToAllTokensEnumeration(uint256 _tokenId) private {
        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }
    
    function addTokenToOwnerEnumeration(address _to, uint256 _tokenId) private {
        uint256 length = balances[_to];
        ownedTokens[_to][length] = _tokenId;
        ownedTokensIndex[_tokenId] = length;
    }
    
    function removeTokenFromOwnerEnumeration(address _from, uint256 _tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balances[_from] - 1;
        uint256 tokenIndex = ownedTokensIndex[_tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedTokens[_from][lastTokenIndex];

            ownedTokens[_from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ownedTokensIndex[_tokenId];
        delete ownedTokens[_from][lastTokenIndex];
    }
    
    function removeTokenFromAllTokensEnumeration(uint256 _tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = allTokens.length - 1;
        uint256 tokenIndex = allTokensIndex[_tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete allTokensIndex[_tokenId];
        allTokens.pop();
    }
}