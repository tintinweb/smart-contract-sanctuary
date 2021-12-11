// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./IERC1155.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract DigitalSigilOwnableDelegateProxy {}

contract DigitalSigilProxyRegistry {
    mapping(address => DigitalSigilOwnableDelegateProxy) public proxies;
}

contract DigitalSigil is
    ERC721Enumerable,
    Ownable,
    ContextMixin,
    NativeMetaTransaction
{
    using SafeMath for uint256;
    using Strings for uint256;
    
    address proxyRegistryAddress;

    IERC1155 private whitelistContract;
    uint256[] private whitelistedTokensArr = [535178, 532250, 580360, 581049, 582700, 610719];
    uint256[] private whitelistedTokensSupplyArr = [18, 18, 18, 18, 18, 18];
    mapping(uint256 => bool) private whitelistedTokens;
    mapping(uint256 => uint256) private tokensAlreadyUsedToMint;
    mapping(address => uint256) private addAlreadyUsedToMint;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public mintPrice = 0.0666 ether; 

    uint256 public constant maxPurchase = 6;

    uint256 public maxSupply;

    bool public saleIsActive = true;

    uint256 public saleTimeStamp;
    uint256 public revealTimeStamp;

    string private BASE_URI;

    address private dev = 0xAE77beeda3c1BB43B1cAEaE04815F68e1c07e077;
    address private par = 0x57237e61aBa03690AAcd30CBed852D350F476a60;
    address private art = 0x934d84A98BD08edBF6b2465AD6Cf022eFd81F2Bc;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxNftSupply,
        uint256 saleStart,
        address _proxyRegistryAddress,
        address _whitelistContract
    ) ERC721(name, symbol) {
        maxSupply = maxNftSupply;
        saleTimeStamp = saleStart;
        revealTimeStamp = saleStart + (86400 * 9);
        proxyRegistryAddress = _proxyRegistryAddress;
        whitelistContract = IERC1155(_whitelistContract);
        whitelistedTokens[535178] = true;
        whitelistedTokens[532250] = true;
        whitelistedTokens[580360] = true;
        whitelistedTokens[581049] = true;
        whitelistedTokens[582700] = true;
        whitelistedTokens[610719] = true;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(dev).transfer(balance.div(4));
        payable(par).transfer(balance.div(4));
        payable(art).transfer(address(this).balance);
    }

    function setWhitelistContract(address _whitelistContract) public onlyOwner {
        whitelistContract = IERC1155(_whitelistContract);
    }

    function whitelistTokens(uint256[] memory tokenIds, uint256[] memory supplies) public onlyOwner {
        require(tokenIds.length == supplies.length, "Invalid inputs");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            whitelistedTokensArr.push(tokenIds[i]);
            whitelistedTokensSupplyArr.push(supplies[i]);
            whitelistedTokens[tokenIds[i]] = true;
        }
    }

    function setSupplyForWhitelistToken(uint256 index, uint256 supply) public onlyOwner {
        whitelistedTokensSupplyArr[index] = supply;
    }

    function isWhitelistedTokenAvailableToMint(uint256 index) public view returns (bool) {
        return tokensAlreadyUsedToMint[whitelistedTokensArr[index]] < whitelistedTokensSupplyArr[index];
    }

    function isWhitelistAvailableToMintForAddress(address _add) public view returns (bool) {
        uint256 maxWhitelist = 0;
        for (uint256 i = 0; i < whitelistedTokensArr.length; i++) {
            if (isWhitelistedTokenAvailableToMint(i)) {
                maxWhitelist += Math.min(whitelistContract.balanceOf(_add, whitelistedTokensArr[i]), whitelistedTokensSupplyArr[i]-tokensAlreadyUsedToMint[whitelistedTokensArr[i]]);
            }
        }
        return maxWhitelist > addAlreadyUsedToMint[_add];
    }

    function numberOfMintsUsingWhitelistedToken(uint256 index) public view returns (uint256) {
        return tokensAlreadyUsedToMint[whitelistedTokensArr[index]];
    }

    function reserve(uint256 num, address _to) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < num; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function setSaleTimestamp(uint256 timeStamp) public onlyOwner {
        saleTimeStamp = timeStamp;
    }

    function setRevealTimestamp(uint256 timeStamp) public onlyOwner {
        revealTimeStamp = timeStamp;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    function setMaxSupply(uint256 supply) public onlyOwner {
        maxSupply = supply;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        BASE_URI = baseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function isWhitelisted(address _add) public view returns (bool, uint256) {
        uint256 maxWhitelist = 0;
        for (uint256 i = 0; i < whitelistedTokensArr.length; i++) {
            if (tokensAlreadyUsedToMint[whitelistedTokensArr[i]] < whitelistedTokensSupplyArr[i]) {
                maxWhitelist += Math.min(whitelistContract.balanceOf(_add, whitelistedTokensArr[i]), whitelistedTokensSupplyArr[i]-tokensAlreadyUsedToMint[whitelistedTokensArr[i]]);
            }
            if (maxWhitelist > addAlreadyUsedToMint[_add]) {
                return (true, whitelistedTokensArr[i]);
            }
        }
        return (false, 0);
    }

    function mintWhitelist() public payable {
        (bool checkWhitelist, uint256 tokenId) = isWhitelisted(msg.sender);
        require(checkWhitelist == true, "Not whitelisted");
        tokensAlreadyUsedToMint[tokenId] += 1;
        addAlreadyUsedToMint[msg.sender] += 1;
        mintNoValueCheck(1);
    }

    function mint(uint256 numberOfTokens) public payable {
        require(
            numberOfTokens <= maxPurchase,
            "Can only mint 20 tokens at a time"
        );
        require(
            mintPrice.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );
        mintNoValueCheck(numberOfTokens);
    }

    function mintNoValueCheck(uint256 numberOfTokens) private {
        require(saleIsActive && block.timestamp >= saleTimeStamp, "Sale must be active to mint");
        require(
            numberOfTokens <= maxPurchase,
            "Can only mint 6 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= maxSupply,
            "Purchase would exceed max supply"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < maxSupply) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        if (
            startingIndexBlock == 0 &&
            (totalSupply() == maxSupply || block.timestamp >= revealTimeStamp)
        ) {
            startingIndexBlock = block.number;
        }
    }

    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % maxSupply;
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint256(blockhash(block.number - 1)) % maxSupply;
        }
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return block.timestamp >= revealTimeStamp 
        ? string(abi.encodePacked(BASE_URI, _tokenId.toString(), ".json")) 
        : contractURI();
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        DigitalSigilProxyRegistry proxyRegistry = DigitalSigilProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmZy7tTePn9ugcfWeTpAbT1Mj87wUZdDz1U8xH57Xop2z3";
    }
}