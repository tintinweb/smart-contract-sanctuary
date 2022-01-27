// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// This is an airdrop NFT for Pulsr www.pulsr.ai 
//
// Thanks to Galactic and 0x420 for their gas friendly ERC721S implementation.
//

import "./ERC721S.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract CryptoMofayasNFT is
    ERC721Sequential,
    ReentrancyGuard,
    Ownable
{
    event PaymentReceived(address from, uint256 amount);

    string public baseURI = "https://ipfs.io/ipfs/QmT5xEGKtTC439i8iS93pE8CyT5ZHJHn9Qctp9Y7hxRvGa/";
    string private constant _name = "CryptoMofayas";
    string private constant _symbol = "CMS";

    uint256 public maxMint = 20;
    uint256 public presaleLimit = 100;
    uint256 public mintPrice = 0.05 ether;
    uint256 public constant maxSupply = 1299;
	bool public status = false;
	bool public presale = false;

    constructor() ERC721Sequential(_name, _symbol) payable {
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

	// @dev admin can mint to a list of addresses
	function gift(address[] calldata recipients) external onlyOwner {
        uint256 numTokens;

        numTokens = recipients.length;
        require(totalMinted() + numTokens <= maxSupply, "PulsrNFT: Sold Out");

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(recipients[i]);
        }
	}

    // @dev public minting
	function mint(uint256 _mintAmount) external payable nonReentrant{
        uint256 s = totalMinted();

        require(status || presale, "CryptoMofayas: Minting not started yet");
        require(_mintAmount > 0, "CryptoMofayas: Cant mint 0");
        require(_mintAmount <= maxMint, "CryptoMofayas: Must mint less than the max");
        require(s + _mintAmount <= maxSupply, "CryptoMofayas: Cant mint more than max supply");
        if (presale) {
            require(s + _mintAmount <= presaleLimit, "CryptoMofayas: Cant mint more during presale");
        }
        require(msg.value >= mintPrice * _mintAmount, "CryptoMofayas: Must send eth of cost per nft");
 
        for (uint256 i = 0; i < _mintAmount; ++i) {
            _safeMint(msg.sender);
	    }
	}

    // @dev set cost of minting
	function setMintPrice(uint256 _newmintPrice) external onlyOwner {
    	mintPrice = _newmintPrice;
	}
	
    // @dev max mint during presale
	function setPresaleLimit(uint256 _newLimit) external onlyOwner {
    	presaleLimit = _newLimit;
	}
	
    // @dev max mint amount per transaction
    function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
	    maxMint = _newMaxMintAmount;
	}

    // @dev unpause main minting stage
	function setSaleStatus(bool _status) external onlyOwner {
    	status = _status;
	}
	
    // @dev unpause presale minting stage
	function setPresaleStatus(bool _presale) external onlyOwner {
    	presale = _presale;
	}

    // @dev Return the base url path to the metadata used by opensea
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    function withdraw(address payable to) external onlyOwner {
        Address.sendValue(to,address(this).balance);
    }
}