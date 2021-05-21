/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
interface ERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}
interface ERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}
interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata) external returns (bytes4);
}

contract IDS_LR_MARS is ERC721, ERC721Metadata, ERC721Enumerable, ERC165 {
    address payable private IDS;
    bool private __OTC = true;
    uint256 private __transactionFeePerMil = 1;

    mapping (uint256 => address) private __owners;
    mapping (address => uint256) private __balances;
    mapping (uint256 => address) private __tokenApprovals;
    mapping (address => mapping (address => bool)) private __operatorApprovals;
    uint256[] private __allTokens;
    mapping(uint256 => uint256) private __allTokensIndex;
    mapping(address => mapping(uint256 => uint256)) private __ownedTokens;
    mapping(uint256 => uint256) private __ownedTokensIndex;

    struct __trade {
        address seller;
        uint256 price;
        bytes16 status;
    }
    mapping (uint256 => __trade) private __trades;
    event TradeStatusChange(uint256 indexed _tokenId, address _from, address _to, uint256 _price, bytes16 _status);

    constructor() {
        IDS = payable(msg.sender);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return interfaceID == type(ERC721).interfaceId || interfaceID == type(ERC721Metadata).interfaceId || interfaceID == type(ERC721Enumerable).interfaceId || interfaceID == type(ERC165).interfaceId;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");

        return __balances[_owner];
    }
    function ownerOf(uint256 _tokenId) public view override returns (address) {
        address owner = __owners[_tokenId];
        require(owner != address(0), "ERC721: owner query for unregistered token");

        return owner;
    }
    function name() external pure override returns (string memory) {
        return "IDS-LR-MARS";
    }
    function symbol() external pure override returns (string memory) {
        return "MARS";
    }
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(__isRegistered(_tokenId), "ERC721Metadata: URI query for unregistered token");

        return string(abi.encodePacked("https://mars.departmentofspace.org/tokens/", __tokenString(_tokenId)));
    }
    function totalSupply() public view virtual override returns (uint256) {
        return __allTokens.length;
    }
    function tokenByIndex(uint256 _index) public view virtual override returns (uint256) {
        require(_index < totalSupply(), "ERC721Enumerable: global index out of bounds");

        return __allTokens[_index];
    }
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view virtual override returns (uint256) {
        require(_index < balanceOf(_owner), "ERC721Enumerable: owner index out of bounds");

        return __ownedTokens[_owner][_index];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public override {
        transferFrom(_from, _to, _tokenId);

        require(__checkOnERC721Received(_from, _to, _tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        address owner = ownerOf(_tokenId);

        require(__OTC, "IDS_LR_MARS: over-the-counter trading is currently prohibited");
        require(__trades[_tokenId].status != "Opened", "IDS_LR_MARS: token on sale");
        require(owner == msg.sender || __tokenApprovals[_tokenId] == msg.sender || __operatorApprovals[owner][msg.sender], "ERC721: transfer caller is not owner nor approved");
        require(owner == _from, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");

        __tokenApprovals[_tokenId] = address(0);
        emit Approval(owner, address(0), _tokenId);

        uint256 lastTokenIndex = balanceOf(_from) - 1;
        uint256 tokenIndex = __ownedTokensIndex[_tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = __ownedTokens[_from][lastTokenIndex];
            __ownedTokens[_from][tokenIndex] = lastTokenId;
            __ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        delete __ownedTokensIndex[_tokenId];
        delete __ownedTokens[_from][lastTokenIndex];
        uint256 length = balanceOf(_to);
        __ownedTokens[_to][length] = _tokenId;
        __ownedTokensIndex[_tokenId] = length;

        __owners[_tokenId] = _to;
        __balances[_from]--;
        __balances[_to]++;
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override {
        address owner = ownerOf(_tokenId);

        require(_approved != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || __operatorApprovals[owner][msg.sender], "ERC721: approve caller is not owner nor approved for all");

        __tokenApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }
    function setApprovalForAll(address _operator, bool _approved) external override {
        require(_operator != msg.sender, "ERC721: approve to caller");

        __operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    function getApproved(uint256 _tokenId) external view override returns (address) {
        require(__isRegistered(_tokenId), "ERC721: approved query for unregistered token");

        return __tokenApprovals[_tokenId];
    }
    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return __operatorApprovals[_owner][_operator];
    }

    
    function register(uint256 _tokenId) external payable {
        require(msg.sender != address(0), "ERC721: registration to the zero address");
        require(!__isRegistered(_tokenId), "ERC721: token already registered");
        require(__isValidToken(_tokenId), "IDS_LR_MARS: invalid token");
        require(msg.value == __registrationFeeOf(_tokenId), "IDS_LR_MARS: incorrect registration fee");

        __allTokensIndex[_tokenId] = __allTokens.length;
        __allTokens.push(_tokenId);
        uint256 length = balanceOf(msg.sender);
        __ownedTokens[msg.sender][length] = _tokenId;
        __ownedTokensIndex[_tokenId] = length;

        IDS.transfer(msg.value);
        __balances[msg.sender]++;
        __owners[_tokenId] = msg.sender;
        emit Transfer(address(0), msg.sender, _tokenId);

        require(__checkOnERC721Received(address(0), msg.sender, _tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");

        __trades[_tokenId] = __trade({
            seller: address(0),
            price: 0,
            status: "Registered"
        });
        emit TradeStatusChange(_tokenId, address(0), msg.sender, 0, "Registered");
    }
    function sell(uint256 _tokenId, uint256 _price) external {
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner || __operatorApprovals[owner][msg.sender], "ERC721: sell caller is not owner nor approved for all");
        require(__trades[_tokenId].status != "Opened", "IDS_LR_MARS: token already on sale");

        __trades[_tokenId] = __trade({
            seller: msg.sender,
            price: _price,
            status: "Opened"
        });
        emit TradeStatusChange(_tokenId, owner, address(0), _price, "Opened");
    }
    function cancelTrade(uint256 _tokenId) external {
        address owner = ownerOf(_tokenId);
        __trade memory trade = __trades[_tokenId];
        require(msg.sender == owner || __operatorApprovals[owner][msg.sender], "ERC721: cancle caller is not owner nor approved for all");
        require(trade.status == "Opened", "IDS_LR_MARS: token not for sale");

        __trades[_tokenId].status = "Canceled";
        emit TradeStatusChange(_tokenId, owner, owner, trade.price, "Canceled");
    }
    function buy(uint256 _tokenId) external payable {
        address owner = ownerOf(_tokenId);
        __trade memory trade = __trades[_tokenId];
        require(trade.status == "Opened", "IDS_LR_MARS: token not for sale");
        require(msg.value == trade.price, "IDS_LR_MARS: incorrect price");
        require(msg.sender != address(0), "ERC721: transfer to the zero address");

        __tokenApprovals[_tokenId] = address(0);
        emit Approval(owner, address(0), _tokenId);

        uint256 lastTokenIndex = balanceOf(owner) - 1;
        uint256 tokenIndex = __ownedTokensIndex[_tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = __ownedTokens[owner][lastTokenIndex];
            __ownedTokens[owner][tokenIndex] = lastTokenId;
            __ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        delete __ownedTokensIndex[_tokenId];
        delete __ownedTokens[owner][lastTokenIndex];
        uint256 length = balanceOf(msg.sender);
        __ownedTokens[msg.sender][length] = _tokenId;
        __ownedTokensIndex[_tokenId] = length;

        uint256 transactionFee = msg.value * __transactionFeePerMil / 1000;
        IDS.transfer(transactionFee);

        payable(owner).transfer(msg.value - transactionFee);
        __owners[_tokenId] = msg.sender;
        __balances[owner]--;
        __balances[msg.sender]++;
        emit Transfer(owner, msg.sender, _tokenId);

        require(__checkOnERC721Received(owner, msg.sender, _tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");

        __trades[_tokenId].status = "Settled";
        emit TradeStatusChange(_tokenId, owner, msg.sender, trade.price, "Settled");
    }

    function __registrationFeeOf(uint256 _tokenId) public pure returns (uint256) {
        require(__isValidToken(_tokenId), "IDS_LR_MARS: invalid token");

        uint256 section = (_tokenId / 100000000) % 10;
        if (section == 4) return   12500000000000000;
        if (section == 3) return  625000000000000000;
        if (section == 2) return 1250000000000000000;
        else              return 2500000000000000000;
    }
    function __dataOf(uint256 _tokenId) external view returns (address, bytes16, uint256) {
        address owner = ownerOf(_tokenId);
        __trade memory trade = __trades[_tokenId];
        return (owner, trade.status, trade.price);
    }
    function __delegate(address _to) external {
        require(msg.sender == IDS);

        IDS = payable(_to);
    }
    function __setOTC(bool _permission) external {
        require(msg.sender == IDS);

        __OTC = _permission;
    }
    function __setTransactionFee(uint256 _feePerMil) external {
        require(msg.sender == IDS);
        require(_feePerMil < 1000);

        __transactionFeePerMil = _feePerMil;
    }

    function __isRegistered(uint256 _tokenId) private view returns (bool) {
        return __owners[_tokenId] != address(0);
    }
    function __tokenString(uint256 _tokenId) private pure returns (string memory) {
        if (_tokenId == 0) {
            return "0";
        }
        uint256 temp = _tokenId;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_tokenId != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_tokenId % 10)));
            _tokenId /= 10;
        }
        return string(buffer);
    }
    function __checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory data) private returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            ERC721TokenReceiver receiver = ERC721TokenReceiver(_to);
            return receiver.onERC721Received(msg.sender, _from, _tokenId, data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        } else {
            return true;
        }
    }
    function __isValidToken(uint256 _tokenId) internal pure returns (bool) {
        uint256 section = _tokenId / 100000000;
        uint256 NS = (_tokenId / 10000000) % 10;
        uint256 lat = (_tokenId / 10000) % 1000;
        uint256 lng = _tokenId % 10000;

        return NS < 2 && ((section == 1 && lat > 80 && lat <= 90 && lng > 0 && lng <= 45)
                       || (section == 2 && lat > 70 && lat <= 80 && lng > 0 && lng <= 90)
                       || (section == 3 && lat > 60 && lat <= 70 && lng > 0 && lng <= 180)
                       || (section == 4 && lat > 0 && lat <= 300 && lng > 0 && lng <= 1800));
    }
}

// Copyright © 2021 INTERNATIONAL DEPARTMENT OF SPACE. All rights reserved.