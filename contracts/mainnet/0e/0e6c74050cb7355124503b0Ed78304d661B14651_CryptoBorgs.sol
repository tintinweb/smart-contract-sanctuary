pragma solidity 0.8.2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CryptoBorgs is Ownable, ERC721Enumerable {

    // Hash of Images
    string public imageHash = "fe41f92777f82f792735f759a3a028d7ff50f5ab0d716d35ea4bb598801a1a83";

    // Address of contract owner
    address payable private beneficiary;

    // Maximum supply of tokens
    uint256 public constant MAX_SUPPLY = 10000;

    constructor() ERC721("CryptoBorgs", "CBG") {
        beneficiary = payable(owner());
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Get price of the token
     */
    function getPrice(uint256 tokenId) public pure returns (uint256) {
        if (tokenId > 9500) {
            return 10000000 gwei;
        } else if (tokenId > 8000) {
            return 50000000 gwei;
        } else if (tokenId > 5000) {
            return 100000000 gwei;
        } else if (tokenId > 3000) {
            return 250000000 gwei;
        } else if (tokenId > 1000) {
            return 500000000 gwei;
        } else if (tokenId > 5) {
            return 1000000000 gwei;
        } else {
            return 5000000000 gwei;
        }
    }

    /**
     * @dev Mint a token
     */
    function mintToken(uint256 tokenId) public payable returns (bool) {
        require(tokenId > 0 && tokenId <= MAX_SUPPLY);
        uint amount = msg.value;
        require(getPrice(tokenId) == amount, "Ether sent should be correct");

        _safeMint(msg.sender, tokenId);
        beneficiary.transfer(amount);
        return true;
    }

    /**
     * @dev Check whether a token has been minted
     */
    function isMinted(uint256 tokenId) public view returns (bool) {
        require(tokenId > 0 && tokenId <= MAX_SUPPLY);
        return _exists(tokenId);
    }

    /**
     * @dev Return list of minted tokens
     */
    function mintedTokens() public view returns (uint256[] memory) {
        return _allTokens;
    }

    /**
     * @dev Check number of tokens still available for sale
     */
    function numAvailable() public view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    /**
     * @dev Withdraw money from the contract
     */
    function withdraw(uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract should have money");
        require(amount <= balance, "Cannot withdraw amount larger than balance");
        beneficiary.transfer(amount);
    }
}