/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

// SPDX-License-Identifier: 0BSD

pragma solidity ^0.8.7;

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, address token, bytes calldata data) external returns (bytes4);
}

contract Meta {

    uint public totalSupply;
    uint public taxConstant = 100;
    uint public totalValueTransferred;
    uint public totalTokensBought;
    uint public minTangleToTaxEvade = 5000000 * 1e9;
    string public name = "Meta";
    string public symbol = "META";
    string public baseURI = "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/";
    address public feeTo;
    address public administrator;
    address public TangleAddress;
    address[] public mintedTokens;
    mapping(address => address) public ownerOf;
    mapping(address => uint) public balanceOf;
    mapping(address => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(address => address[]) public tokensOfOwner;
    mapping(address => mapping(address => uint)) public indexOfTokenInTokensOfOwner;

    struct Offer {
        bool isForSale;
        address token;
        address seller;
        uint minValue;
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        address token;
        address bidder;
        uint value;
    }

    mapping (address => Offer) public tokensOfferedForSale;
    mapping (address => Bid) public tokenBids;

    constructor() {
        feeTo = msg.sender;
        administrator = msg.sender;
        mint(msg.sender, address(this));
    }
    
    function changeFeeTo(address newFeeTo) public {
        require(msg.sender == administrator, "not administrator");
        feeTo = newFeeTo;
    }
    
    function changeTangleAddress(address newTangleAddress) public {
        require(msg.sender == administrator, "not administrator");
        TangleAddress = newTangleAddress; 
    }
    
    function changeAdministrator(address newAdministrator) public {
        require(msg.sender == administrator, "not administrator");
        administrator = newAdministrator;
    }
    
    function changeMinTangleToTaxEvade(uint newMinTangleToTaxEvade) public {
        require(msg.sender == administrator, "not administrator");
        minTangleToTaxEvade = newMinTangleToTaxEvade;
    }

    function increaseTaxConstant(uint newTaxConstant) public { // this decreases the total tax rate on accepted bids or buys
        require(msg.sender == feeTo, "only feeTo can change taxConstant");
        require(newTaxConstant > taxConstant, "taxConstant must increase");
        taxConstant = newTaxConstant;
    }

    function mint(address to, address token) public {
        require(ownerOf[token] == address(0), "cannot mint already owned token");
        ownerOf[token] = to;
        tokensOfOwner[to].push(token);
        indexOfTokenInTokensOfOwner[to][token] = balanceOf[to];
        balanceOf[to]++;
        emit Transfer(address(0), to, token);
        totalSupply++;
        mintedTokens.push(token);
    }

    function tokenLogo(address token) public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "0x", _toChecksumString(token), "/logo.png"));
    }

    function tokenInfo(address token) public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "0x", _toChecksumString(token), "/info.json"));
    }

    function approve(address to, address token) public {
        require(msg.sender == ownerOf[token] || isApprovedForAll[ownerOf[token]][msg.sender], "ERC721: approve caller is not owner nor approved for all");
        tokenApprovals[token] = to;
        emit Approval(ownerOf[token], to, token);
    }

    function getApproved(address token) public view returns (address) {
        return tokenApprovals[token];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "ERC721: approve to caller");
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, address token) public {
        require(_isApprovedOrOwner(msg.sender, token), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, token);
    }

    function _isApprovedOrOwner(address spender, address token) internal view returns (bool) {
        return (spender == ownerOf[token] || getApproved(token) == spender || isApprovedForAll[ownerOf[token]][spender]);
    }

    function _transfer(address from, address to, address token) internal {
        require(ownerOf[token] == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "cannot transfer to zero address");
        if (tokensOfferedForSale[token].isForSale)
            tokenNoLongerForSale(token);
        if (balanceOf[from] > 1) {
            if (indexOfTokenInTokensOfOwner[from][token] != balanceOf[from] - 1) {
                tokensOfOwner[from][indexOfTokenInTokensOfOwner[from][token]] = tokensOfOwner[from][balanceOf[from] - 1];
                indexOfTokenInTokensOfOwner[from][tokensOfOwner[from][balanceOf[from] - 1]] = indexOfTokenInTokensOfOwner[from][token];
            }
            tokensOfOwner[from].pop();
        }
        if (balanceOf[from] == 1) {
            delete tokensOfOwner[from];
        }
        indexOfTokenInTokensOfOwner[from][token] = 0;
        balanceOf[from]--;
        tokensOfOwner[to].push(token);
        indexOfTokenInTokensOfOwner[to][token] = balanceOf[to];
        balanceOf[to]++;
        ownerOf[token] = to;
        Bid memory bid = tokenBids[token];
        if (bid.bidder == to) {
            payable(bid.bidder).transfer(bid.value);
            tokenBids[token] = Bid(false, token, address(0), 0);
        }
        emit Transfer(from, to, token);
    }

    function tokenNoLongerForSale(address token) public {
        require(_isApprovedOrOwner(msg.sender, token), "not owner or approved");
        tokensOfferedForSale[token] = Offer(false, token, msg.sender, 0, address(0));
        emit TokenNoLongerForSale(token);
    }

    function offerTokenForSale(address token, uint minSalePriceInWei, address toAddress) public {
        require(_isApprovedOrOwner(msg.sender, token), "not owner or approved");
        tokensOfferedForSale[token] = Offer(true, token, msg.sender, minSalePriceInWei, toAddress);
        emit TokenOffered(token, minSalePriceInWei, toAddress);
    }

    function offerTokenForSale(address token, uint minSalePriceInWei) public {
        require(_isApprovedOrOwner(msg.sender, token), "not owner or approved");
        tokensOfferedForSale[token] = Offer(true, token, msg.sender, minSalePriceInWei, address(0));
        emit TokenOffered(token, minSalePriceInWei, address(0));
    }
    
    function transferModifier(uint toType, uint value, address seller) internal view returns (uint) {
        if (toType == 0)
            return ERC20(TangleAddress).balanceOf(seller) >= minTangleToTaxEvade ? value : value * (taxConstant - 1) / taxConstant;
        return ERC20(TangleAddress).balanceOf(seller) >= minTangleToTaxEvade ? 0 : value / taxConstant;
    }

    function buyToken(address token) payable public {
        Offer memory offer = tokensOfferedForSale[token];
        require(offer.isForSale, "token not for sale");
        require(offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender, "cannot buy restricted token sale");
        require(msg.value >= offer.minValue, "offer too low");
        require(offer.seller == ownerOf[token], "token owner changed since offer was made");
        tokenApprovals[token] = address(0);
        if (balanceOf[offer.seller] > 1) {
            if (indexOfTokenInTokensOfOwner[offer.seller][token] != balanceOf[offer.seller] - 1) {
                tokensOfOwner[offer.seller][indexOfTokenInTokensOfOwner[offer.seller][token]] = tokensOfOwner[offer.seller][balanceOf[offer.seller] - 1];
                indexOfTokenInTokensOfOwner[offer.seller][tokensOfOwner[offer.seller][balanceOf[offer.seller] - 1]] = indexOfTokenInTokensOfOwner[offer.seller][token];
            }
            tokensOfOwner[offer.seller].pop();
        }
        if (balanceOf[offer.seller] == 1) {
            delete tokensOfOwner[offer.seller];
        }
        indexOfTokenInTokensOfOwner[offer.seller][token] = 0;
        balanceOf[offer.seller]--;
        tokensOfOwner[msg.sender].push(token);
        indexOfTokenInTokensOfOwner[msg.sender][token] = balanceOf[msg.sender];
        balanceOf[msg.sender]++;
        ownerOf[token] = msg.sender;
        tokenNoLongerForSale(token);
        emit Transfer(offer.seller, msg.sender, token);
        payable(offer.seller).transfer(transferModifier(0, msg.value, offer.seller));
        payable(feeTo).transfer(transferModifier(1, msg.value, offer.seller));
        totalValueTransferred += msg.value;
        totalTokensBought++;
        emit TokenBought(token, msg.value, offer.seller, ownerOf[token]);
        Bid memory bid = tokenBids[token];
        if (bid.bidder == msg.sender) {
            payable(msg.sender).transfer(bid.value);
            tokenBids[token] = Bid(false, token, address(0), 0);
        }
    }

    function enterBidForToken(address token) payable public {
        require(ownerOf[token] != address(0), "token not owned");
        require(ownerOf[token] != msg.sender, "cannot bid on your own token");
        require(msg.value > 0, "invalid bid amount");
        Bid memory existing = tokenBids[token];
        require(msg.value > existing.value, "bid not greater than highest existing bid");
        if (existing.value > 0) payable(existing.bidder).transfer(existing.value);
        tokenBids[token] = Bid(true, token, msg.sender, msg.value);
        emit TokenBidEntered(token, msg.value, msg.sender);
    }

    function acceptBidForToken(address token, uint minPrice) public {
        require(_isApprovedOrOwner(msg.sender, token), "not owner or approved");
        Bid memory bid = tokenBids[token];
        address seller = ownerOf[token];
        require(bid.value > 0, "highest bid value must be greater than zero");
        require(bid.value >= minPrice, "bid must be greater than minimum price");
        tokenBids[token] = Bid(false, token, address(0), 0);
        _transfer(ownerOf[token], bid.bidder, token);
        tokensOfferedForSale[token] = Offer(false, token, bid.bidder, 0, address(0));
        payable(seller).transfer(transferModifier(0, bid.value, seller));
        payable(feeTo).transfer(transferModifier(1, bid.value, seller));
        totalValueTransferred += bid.value;
        totalTokensBought++;
        emit TokenBought(token, bid.value, ownerOf[token], bid.bidder);
    }

    function withdrawBidForToken(address token) public {
        Bid memory bid = tokenBids[token];
        require(bid.bidder == msg.sender, "not bidder");
        emit TokenBidWithdrawn(token, bid.value, msg.sender);
        tokenBids[token] = Bid(false, token, address(0), 0);
        payable(msg.sender).transfer(bid.value);
    }

    function _getAsciiOffset(uint8 nibble, bool caps) internal pure returns (uint8 offset) {
        if (nibble < 10) {
            offset = 48;
        } else if (caps) {
            offset = 55;
        } else {
            offset = 87;
        }
    }

    function _toAsciiString(bytes20 data) internal pure returns (string memory asciiString) {
        bytes memory asciiBytes = new bytes(40);
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;
        for (uint256 i = 0; i < data.length; i++) {
            b = uint8(uint160(data) / (2 ** (8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;
            asciiBytes[2 * i] = bytes1(leftNibble + (leftNibble < 10 ? 48 : 87));
            asciiBytes[2 * i + 1] = bytes1(rightNibble + (rightNibble < 10 ? 48 : 87));
        }
        return string(asciiBytes);
    }

    function _toChecksumCapsFlags(address account) internal pure returns (bool[40] memory characterCapitalized) {
        bytes20 a = bytes20(account);
        bytes32 b = keccak256(abi.encodePacked(_toAsciiString(a)));
        uint8 leftNibbleAddress;
        uint8 rightNibbleAddress;
        uint8 leftNibbleHash;
        uint8 rightNibbleHash;
        for (uint256 i; i < a.length; i++) {
            rightNibbleAddress = uint8(a[i]) % 16;
            leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
            rightNibbleHash = uint8(b[i]) % 16;
            leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;
            characterCapitalized[2 * i] = (leftNibbleAddress > 9 && leftNibbleHash > 7);
            characterCapitalized[2 * i + 1] = (rightNibbleAddress > 9 && rightNibbleHash > 7);
        }
    }

    function _toChecksumString(address account) internal pure returns (string memory asciiString) {
        bytes20 data = bytes20(account);
        bytes memory asciiBytes = new bytes(40);
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;
        bool leftCaps;
        bool rightCaps;
        uint8 asciiOffset;
        bool[40] memory caps = _toChecksumCapsFlags(account);
        for (uint256 i = 0; i < data.length; i++) {
            b = uint8(uint160(data) / (2**(8*(19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;
            leftCaps = caps[2*i];
            rightCaps = caps[2*i + 1];
            asciiOffset = _getAsciiOffset(leftNibble, leftCaps);
            asciiBytes[2 * i] = bytes1(leftNibble + asciiOffset);
            asciiOffset = _getAsciiOffset(rightNibble, rightCaps);
            asciiBytes[2 * i + 1] = bytes1(rightNibble + asciiOffset);
        }
        return string(asciiBytes);
    }

    function safeTransferFrom(address from, address to, address token) public {
        require(_isApprovedOrOwner(msg.sender, token), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, token, "");
    }

    function safeTransferFrom(address from, address to, address token, bytes memory data) public {
        require(_isApprovedOrOwner(msg.sender, token), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, token, data);
    }

    function _safeTransfer(address from, address to, address token, bytes memory _data) internal virtual {
        _transfer(from, to, token);
        require(_checkOnERC721Received(from, to, token, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _checkOnERC721Received(address from, address to, address token, bytes memory data) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, token, data) returns (bytes4 retval) {
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

    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function tokenByIndex(uint index) public view returns (address) {
        return mintedTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint index) public view returns (address) {
        require(index < balanceOf[owner], "index out of bounds");
        return tokensOfOwner[owner][index];
    }

    function getIndexOfTokenInTokensOfOwner(address owner, address token) public view returns (uint) {
        require (ownerOf[token] == owner, "owner does not own this token");
        return indexOfTokenInTokensOfOwner[owner][token];
    }

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Approval(address indexed owner, address indexed approved, address indexed token);
    event Transfer(address indexed from, address indexed to, address indexed token);
    event TokenOffered(address indexed token, uint minValue, address indexed toAddress);
    event TokenBidEntered(address indexed token, uint value, address indexed fromAddress);
    event TokenBidWithdrawn(address indexed token, uint value, address indexed fromAddress);
    event TokenBought(address indexed token, uint value, address indexed fromAddress, address indexed toAddress);
    event TokenNoLongerForSale(address indexed token);

}