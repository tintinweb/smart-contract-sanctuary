// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./RandomGenerator.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./CardCatalog.sol";

contract Cards is IERC721, ERC165 {
    struct Card {
        uint16 image;
        uint8 border;
        uint8[] runes;
        uint8[] crystals;
    }

    uint16[] private countDistribution = [6000, 9000];
    uint16[] private runesDistribution = [2220, 4040, 5460, 6660, 7660, 8460, 8860, 9160, 9360, 9510, 9610, 9690, 9750, 9774, 9789, 9799, 9800, 9900];
    uint16[] private crystalDistribution = [1400, 2600, 3600, 4520, 5340, 6070, 6720, 7270, 7780, 8230, 8640, 9000, 9310, 9560, 9770, 9900, 9990];
    uint16[] private borderDistribution = [1500, 2700, 3800, 4800, 5700, 6500, 7200, 7800, 8300, 8700, 9000, 9250, 9450, 9600, 9720, 9820, 9900, 9950, 9985];

    Card[] private _mintedCards;
//    uint64[] private _mintedCards1;
    address public minterAddress;
    address public stakerAddress;
    string private _name;
    string private _symbol;
    string private _baseUri;
    RandomGenerator private randomGeneratorContract;
    CardCatalog private cardCatalogContract;

    address[] private _owners;
    mapping (address => uint256[]) private _cardsByOwners;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    mapping (uint256 => uint256) private _tokenLockId;

    constructor(
        address _randomGeneratorContractAddress,
        address _stakerContractAddress,
        address _cardCatalogContractAddress,
        string memory name,
        string memory symbol,
        string memory baseUri
    ) {
        minterAddress = msg.sender;
        stakerAddress = _stakerContractAddress;
        randomGeneratorContract = RandomGenerator(_randomGeneratorContractAddress);
        cardCatalogContract = CardCatalog(_cardCatalogContractAddress);
        _name = name;
        _symbol = symbol;
        _baseUri = baseUri;
    }

    function generateBorder() private returns (uint8 border) {
        return getIntByDistribution(borderDistribution);
    }

    function generateCount() private returns (uint8 count) {
        return getIntByDistribution(countDistribution) + 1;
    }

    function generateRunes() private returns (uint8[] memory) {
        return getArrayByDistribution(generateCount(), runesDistribution);
    }

    function generateCrystals() private returns (uint8[] memory) {
        return getArrayByDistribution(generateCount(), crystalDistribution);
    }

    function getIntByDistribution(uint16[] memory distribution) private returns (uint8) {
        uint16 rnd = uint16(randomGeneratorContract.random() % 10000);
        uint8 j;
        for (j = 0; j < distribution.length && rnd >= distribution[j]; j++) {}
        return j;
    }

    function getArrayByDistribution(uint8 count, uint16[] memory distribution) private returns (uint8[] memory) {
        uint8[] memory values = new uint8[](count);
        uint8 k;
        bool isDuplicate;
        for (uint8 i = 0; i < count; i ++) {
            do {
                values[i] = getIntByDistribution(distribution);
                isDuplicate = false;
                for (k = 0; k < i; k ++) {
                    if (values[i] == values[k]) {
                        isDuplicate = true;
                    }
                }
            } while (isDuplicate);
        }

        return values;
    }

    function mintCard(address cardOwner, uint16 imageId) public onlyMinter {
        _mintedCards.push(Card(
            imageId,
            generateBorder(),
            generateRunes(),
            generateCrystals()
        ));
        _owners.push(cardOwner);
        uint256 tokenId = _mintedCards.length - 1;
        _cardsByOwners[cardOwner].push(tokenId);
    }

    function setBaseUri(string memory baseUri) public onlyMinter {
        _baseUri = baseUri;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k] = bytes1(uint8(48 + _i % 10));
            if (k > 0) {
                k--;
            }
            _i /= 10;
        }
        return string(bstr);
    }

    function _cardToUriParams(uint256 tokenId, Card memory card) internal pure returns (string memory) {
        uint8 i;
        bytes memory runesString;
        bytes memory crystalsString;

        bytes memory lowerDash = bytes("_");
        bytes memory dash = bytes("-");

        for (i = 0; i < card.runes.length; i++) {
            runesString = bytes.concat(runesString, bytes(uint2str(card.runes[i])), lowerDash);
        }
        for (i = 0; i < card.crystals.length; i++) {
            crystalsString = bytes.concat(crystalsString, bytes(uint2str(card.crystals[i])), lowerDash);
        }
        return string(bytes.concat(
                bytes(uint2str(tokenId)),
                dash,
                bytes(uint2str(card.image)),
                dash,
                bytes(uint2str(card.border)),
                dash,
                bytes(crystalsString),
                dash,
                bytes(runesString)
            ));
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return string(bytes.concat(bytes(_baseUri), bytes(_cardToUriParams(tokenId, _mintedCards[tokenId]))));
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(_tokenLockId[tokenId] == 0, "ERC721: token is locked for minting");

//        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _owners[tokenId] = to;

        _cardsByOwners[to][_cardsByOwners[to].length] = tokenId;

        for (uint256 i = 0; i < _cardsByOwners[from].length; i++) {
            if (_cardsByOwners[from][i] == tokenId) {
                _cardsByOwners[from][i] = _cardsByOwners[from][_cardsByOwners[from].length - 1];
                _cardsByOwners[from].pop();
                break;
            }
        }
        _cardsByOwners[from][_cardsByOwners[from].length] = tokenId;

        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return 1;
    }

    function getTokenRunes(uint256 tokenId) public view returns (uint8[] memory) {
        require(_exists(tokenId));
        return _mintedCards[tokenId].runes;
    }

    function getTokenCrystals(uint256 tokenId) public view returns (uint8[] memory) {
        require(_exists(tokenId));
        return _mintedCards[tokenId].crystals;
    }

    function getTokenImage(uint256 tokenId) public view returns (uint16) {
        require(_exists(tokenId));
        return _mintedCards[tokenId].image;
    }

    function isLocked(uint256 tokenId) public view returns (bool) {
        return _tokenLockId[tokenId] != 0;
    }

    function getLockId(uint256 tokenId) public view returns (uint256) {
        require(isLocked(tokenId));
        return _tokenLockId[tokenId];
    }

    function lockTokens(uint256[] memory tokenIds, uint256 lockId) public onlyStaker {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokenLockId[tokenIds[i]] = lockId;
        }
    }

    function unlockTokens(uint256[] memory tokenIds) public onlyStaker {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_tokenLockId[tokenIds[i]] != 0, "Some tokens are not locked");
            delete _tokenLockId[tokenIds[i]];
        }
    }

    function cardEnergy(uint256 tokenId) public view returns (uint16) {
        require(_exists(tokenId), "Getting energy of non-existent token");
        uint16 imageEnergy = cardCatalogContract.getCard(_mintedCards[tokenId].image).energy;
        uint16 addEnergy = 0;
        uint16 energyMultiplier = 1;
        for (uint256 i = 0; i < _mintedCards[tokenId].runes.length; i++) {
            if (_mintedCards[tokenId].runes[i] < 16) {
                addEnergy += _mintedCards[tokenId].runes[i];
            }
            else if (_mintedCards[tokenId].runes[i] == 16) {
                energyMultiplier *= 2;
            }
        }
        return energyMultiplier * imageEnergy + addEnergy;
    }

    function getCardsByOwner(address owner) public view onlyMinter returns (uint256[] memory) {
        return _cardsByOwners[owner];
    }

    modifier onlyMinter {
        require(
            msg.sender == minterAddress,
            "Only owner can call this function."
        );
        _;
    }

    modifier onlyStaker {
        require(
            msg.sender == stakerAddress,
            "Only staker can call this function."
        );
        _;
    }
}