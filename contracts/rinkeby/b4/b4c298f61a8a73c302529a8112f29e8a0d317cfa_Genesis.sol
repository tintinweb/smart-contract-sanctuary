// contracts/Genesis.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

contract Genesis is ERC721Enumerable, ERC721URIStorage {
    /*
  ________                            .__        
 /  _____/  ____   ____   ____   _____|__| ______
/   \  ____/ __ \ /    \_/ __ \ /  ___/  |/  ___/
\    \_\  \  ___/|   |  \  ___/ \___ \|  |\___ \ 
 \______  /\___  >___|  /\___  >____  >__/____  >
        \/     \/     \/     \/     \/        \/ 
*/


    //uint256s
    uint256 maxSupply = 200;

    //address
    address _owner;

    uint private _priceOne = 0;
    bool public paused = false;

    uint256 public presaleWindow = 24 hours; // 24 hours presale period
    uint256 public presaleStartTime = 1634342400; // 16th October 0800 SGT
    uint256 public publicSaleStartTime = 1634443200; // 17th October 1200 SGT

    // manual toggle for presale and public sale //
    bool public presaleOpen = false;
    bool public publicSaleOpen = true;

    mapping(address => uint256) private publicAddressMintedAmount; // number of NFT minted for each wallet during public sale
    mapping(address => uint256) private presaleAddressMintedAmount; // number of NFT minted for each wallet during presale
    mapping(address => bool) public whitelistedAddresses; // all address of whitelisted OGs
    uint256 public nftPerAddressLimitPublic = 3; // maximum number of mint per wallet for public sale
    uint256 public nftPerAddressLimitPresale = 3; // maximum number of mint per wallet for presale
    address payable public treasury;

    constructor() ERC721("Genesis", "GEN") {
        _owner = msg.sender;
        treasury = payable(_owner);
    }

    function setPriceOne(uint mintPrice) external onlyOwner {
        _priceOne = mintPrice;
    }

    // dev team mint
    function devMint(string memory _tokenURI) public onlyOwner {
        require(!paused); // contract is not paused
        uint256 supply = totalSupply(); // get current mintedAmount
        require(supply + 1 <= maxSupply); // total mint amount exceeded supply, try lowering amount
        _safeMint(msg.sender, supply + 1);
        _setTokenURI(supply + 1, _tokenURI);
    }

    // presale mint
    function presaleMint(
        string memory _tokenURI
    ) public payable {
        require(!paused); // contract is paused
        require((isPresaleOpen() || presaleOpen)); // presale has not started or it has ended
        require(whitelistedAddresses[msg.sender]); // you are not in the whitelist"
        uint256 supply = totalSupply();
        require(
            presaleAddressMintedAmount[msg.sender] + 1 <=
            nftPerAddressLimitPresale
        ); // you can only mint a maximum of two nft during presale
        require(msg.value >= _priceOne); // not enought ether sent for mint amount

        (bool success, ) = treasury.call{ value: msg.value }(""); // forward amount to treasury wallet
        require(success); // not able to forward msg value to treasury

        presaleAddressMintedAmount[msg.sender]++;
        _safeMint(msg.sender, supply + 1);
        _setTokenURI(supply + 1, _tokenURI);
    }

    function publicMint(string memory _tokenURI) public payable {
        require(!paused);
        require((isPublicSaleOpen() || publicSaleOpen)); // public sale has not started
        require(
            publicAddressMintedAmount[msg.sender] + 1 <=
            nftPerAddressLimitPublic
        ); // You have exceeded max amount of mints

        uint256 supply = totalSupply();
        require(supply + 1 <= maxSupply); // all have been minted
        require(msg.value >= _priceOne); // must send correct price

        (bool success, ) = treasury.call{ value: msg.value }(""); // forward amount to treasury wallet
        require(success); // not able to forward msg value to treasury

        publicAddressMintedAmount[msg.sender]++;
        _safeMint(msg.sender, supply + 1);
        _setTokenURI(supply + 1, _tokenURI);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        return ERC721URIStorage._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function isPublicSaleOpen() public view returns (bool) {
        return block.timestamp >= publicSaleStartTime;
    }

    function setPublicSaleOpen(bool _publicSaleOpen) public onlyOwner {
        publicSaleOpen = _publicSaleOpen;
    }

    function setPresaleOpen(bool _presaleOpen) public onlyOwner {
        presaleOpen = _presaleOpen;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        return whitelistedAddresses[_user];
    }

    function whitelistUsers(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelistedAddresses[_users[i]] = true;
        }
    }

    function isPresaleOpen() public view returns (bool) {
        return
        block.timestamp >= presaleStartTime &&
        block.timestamp < (presaleStartTime + presaleWindow);
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    /**
     * @dev Transfers ownership
     * @param _newOwner The new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    /**
     * @dev Modifier to only allow owner to call functions
     */
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}