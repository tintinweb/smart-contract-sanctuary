// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract CyberGirlsCafe is IERC165, ERC721Metadata, ERC721Enumerable, Ownable {
    uint256 public immutable TOTAL_TOKENS;
    uint256 public constant MAX_TOKENS_PER_TXN = 20;
    uint256 public constant MAX_TOKENS_PER_WL = 3;
    uint256 public constant UNIQUE_TOKENS = 10;
    uint256 public constant TOKEN_PRICE = 70000000000000000; //0.07ETH
    uint256 public constant WL_TOKEN_PRICE = 45000000000000000; //0.045ETH
    string public constant PROVENANCE = "8fef626f47a65408f131274eefff04588dbd9a2eee69460efe986e72ae3c119c";

    mapping(address => uint256) public whiteList;
    address private _proxyRegistryAddress;
    string private _contractURL;
    uint256 private _mintState = 0;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory contractURL,
        address proxyAddress
    ) ERC721Metadata(name, symbol) {
        TOTAL_TOKENS = getTotalTokens();
		_baseTokenURI = baseTokenURI;
        _contractURL = contractURL;
        _proxyRegistryAddress = proxyAddress;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function getTotalTokens() internal virtual pure returns (uint256) {
        return 10000;
    }

    function setBaseURI(string calldata value) public onlyOwner {
		_baseTokenURI = value;
	}
    
    function contractURI() public view returns (string memory) {
        return _contractURL;
    }

    function setContractURI(string calldata value) public onlyOwner {
        _contractURL = value;
    }

    function addToWhiteList(address[] calldata addresses) external onlyOwner {
        address zeroAddress = address(0);

        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != zeroAddress, "Zero address");

            whiteList[addresses[i]] = MAX_TOKENS_PER_WL;
        }
    }

    function removeFromWhiteList(address[] calldata addresses) external onlyOwner {
        address zeroAddress = address(0);

        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != zeroAddress, "Zero address");

            delete whiteList[addresses[i]];
        }
    }

    // 0 - Not allow public and whitelist mint
    // 1 - Allow whitelist mint
    // 2 - Allow public mint
    function setMintState(uint256 value) public onlyOwner {
        _mintState = value;
    }

    function mint(uint256 count) external payable {
        require(_mintState == 2, "Public mint is not allowed");

        uint256 _totalSupply = totalSupply();

        require(_totalSupply < TOTAL_TOKENS, "Sold out");
        require(count > 0 && count <= MAX_TOKENS_PER_TXN, "Count should be from 1 to 20");
        require(_totalSupply + count <= TOTAL_TOKENS, "Purchase would exceed max supply of tokens");
        require(msg.value >= TOKEN_PRICE * count, "Ether value sent is not correct");
        
        _mint(msg.sender, count);
	}

    function presaleMint(uint256 count) external payable {
        require(_mintState == 1, "Whitelist mint is not allowed");
        require(count > 0 && count <= MAX_TOKENS_PER_WL, "Count should be from 1 to 3");

        uint256 allowedCount = whiteList[msg.sender];
        
        require(allowedCount > 0, "You are not in whitelist");
        require(allowedCount >= count, "Purchase would exceeds max allowed");
        require(msg.value >= WL_TOKEN_PRICE * count, "Ether value sent is not correct");
        
        whiteList[msg.sender] = allowedCount - count;
        _mint(msg.sender, count);
	}

    function mintGiveaway(address to, uint256 count) external onlyOwner {
        uint256 _totalSupply = totalSupply();
        uint256 _totalTokens = TOTAL_TOKENS + UNIQUE_TOKENS;

        require(_totalSupply < _totalTokens, "Sold out");
        require(count > 0 && count <= MAX_TOKENS_PER_TXN, "Count should be from 1 to 20");
        require(_totalSupply + count <= _totalTokens, "Purchase would exceed max supply of tokens");
        require(to != address(0), "Transfer to the zero address");
        
        _mint(to, count);
	}
    
    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        // https://github.com/ProjectOpenSea/opensea-creatures
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator)
            return true;

        return super.isApprovedForAll(owner, operator);
    }

    function withdrawAll() external onlyOwner {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "Balance must be positive");

        payable(msg.sender).transfer(_balance);
    }

    function withdrawTo(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Transfer to the zero address");
        require(address(this).balance >= amount, "Amount is greater than balance");

        payable(to).transfer(amount);
    }
}