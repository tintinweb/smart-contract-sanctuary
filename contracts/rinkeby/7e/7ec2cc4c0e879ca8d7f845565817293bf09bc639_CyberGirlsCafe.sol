// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
/*import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";*/

/*contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}*/

error Mint_SoldOut();
error Mint_InvalidCount();
error Mint_NotEnoughEther();
//, ContextMixin, NativeMetaTransaction
contract CyberGirlsCafe is ERC721Enumerable, Ownable
{
    uint256 public constant MAX_TOKENS = 30;
    uint256 public constant TOKEN_PRICE = 10000000000000000; //0.07ETH

    uint256 public currentTokenId = 0;
    string public provenance = "";

    string private _baseTokenURI;
    address private proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseTokenURI/*,
        address _proxyRegistryAddress*/
    ) ERC721(_name, _symbol) {
		_baseTokenURI = baseTokenURI;
        /*proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);*/
    }

    function _baseURI() internal view override returns (string memory) {
		return _baseTokenURI;
	}

    function setBaseURI(string memory baseURI) public onlyOwner {
		_baseTokenURI = baseURI;
	}

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function mint(uint256 count) external payable {
        uint256 _totalSupply = totalSupply();

        if(_totalSupply >= MAX_TOKENS)
            revert Mint_SoldOut();
        
        if(count <= 0 || count > 20 || _totalSupply + count > MAX_TOKENS)
            revert Mint_InvalidCount();
        
        if(msg.value < TOKEN_PRICE * count)
            revert Mint_NotEnoughEther();

		for (uint i = 0; i < count; i++) {
			currentTokenId++;
			_safeMint(msg.sender, currentTokenId);
		}
	}

    /*function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }*/

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        
        require(_balance > 0, "Balance must be positive");
        payable(msg.sender).transfer(_balance);
    }

    /*function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }*/
}