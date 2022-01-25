// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract BlueprintedNFT is ERC721Enumerable, Ownable {
    string  public              baseURI;
    
    address public              proxyRegistryAddress;
    address public              payee1;
    address public              payee2;

    bytes32 public              whitelistMerkleRoot1;
    bytes32 public              whitelistMerkleRoot2;
    uint256 public              saleStatus          = 0; // 0 closed, 1 BL, 2 WL, 3 PUBLIC
    uint256 public constant     MAX_SUPPLY          = 7000;
    uint256 public              MAX_GIVEAWAY        = 50;

    uint256 public constant     MAX_PER_TX          = 20;
    uint256 public constant     priceInWei          = 0.06 ether;

    uint256 public constant     BL_MAX_PER_TX       = 3;
    uint256 public constant     BL_priceInWei       = 0.02 ether;

    uint256 public constant     WL_MAX_PER_TX       = 10;
    uint256 public constant     WL_priceInWei       = 0.05 ether;

    mapping(address => bool) public projectProxy;
    mapping(address => uint) public addressToMinted;

    constructor(
        string memory _baseURI, 
        address _proxyRegistryAddress, 
        address _payee1,
        address _payee2
    )
        ERC721("BlueprintedNFT", "BP")
    {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        payee1 = _payee1;
        payee2 = _payee2;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }


    function setWhitelistMerkleRoot1(bytes32 _whitelistMerkleRoot) external onlyOwner {
        // don't forget to prepend: 0x
        whitelistMerkleRoot1 = _whitelistMerkleRoot;
    }

    function setWhitelistMerkleRoot2(bytes32 _whitelistMerkleRoot) external onlyOwner {
        // don't forget to prepend: 0x
        whitelistMerkleRoot2 = _whitelistMerkleRoot;
    }

    function setSaleStatus(uint256 _status) external onlyOwner {
        require(saleStatus < 4 && saleStatus >= 0, "Invalid status.");
        saleStatus = _status;
    }


    function mint(uint256 count, bytes32[] calldata proof) public payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_SUPPLY, "Excedes max supply.");
        if (saleStatus == 1) {
            require(MerkleProof.verify(proof, whitelistMerkleRoot1, leaf), 'Not on bluelist. Merkle Proof fail.');
            require(addressToMinted[_msgSender()] + count <= BL_MAX_PER_TX, "Exceeds bluelist supply"); 
            require(count * BL_priceInWei == msg.value, "Invalid funds provided.");
            addressToMinted[_msgSender()] += count;
        } else if (saleStatus == 2) {
            require(MerkleProof.verify(proof, whitelistMerkleRoot2, leaf), 'Not on whitelist. Merkle Proof fail.');
            require(addressToMinted[_msgSender()] + count <= WL_MAX_PER_TX, "Exceeds whitelist supply"); 
            require(count * WL_priceInWei == msg.value, "Invalid funds provided.");
            addressToMinted[_msgSender()] += count;
        }  else if (saleStatus == 3) {
            require(count < MAX_PER_TX, "Exceeds max per transaction.");
            require(count * priceInWei == msg.value, "Invalid funds provided.");
            addressToMinted[_msgSender()] += count;
        } else {
            require(false, "Sale not open.");
        }
        
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function promoMint(uint _qty, address _to) public onlyOwner {
        require(MAX_GIVEAWAY - _qty >= 0, "Exceeds max giveaway.");
        uint256 totalSupply = _owners.length;
        for (uint i = 0; i < _qty; i++) {
            _mint(_to, totalSupply + i);
        }
        MAX_GIVEAWAY -= _qty;
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function withdraw() public  {
        (bool success, ) = payee1.call{value: address(this).balance * 8 / 100}("");
        require(success, "Failed to send to payee1.");
        (bool success2, ) = payee2.call{value: address(this).balance}("");
        require(success2, "Failed to send to payee2.");
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}