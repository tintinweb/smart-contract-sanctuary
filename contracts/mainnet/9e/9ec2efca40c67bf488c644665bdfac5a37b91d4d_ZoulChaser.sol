// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import './Ownable.sol';
import "./ERC721Enumerable.sol";
import "./Pausable.sol";


contract ZoulChaser is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Strings for uint256;

    address public constant ZC_FOUNDERS_VAULT =
        0x450ac9514D324D29D81CaEBFD52583C98573d04C;

    address public constant ZC_DEVELOPMENT_VAULT =
        0xbE5DC4D62ba2222dB74Af72CEf092c247465B6A9;

    uint256 public constant GENESIS_ZOULS_TOTAL = 10000;

    uint256 public constant PUBLIC_MINT_PRICE = 0.07 ether;

    uint256 public PUBLIC_MAX_PER_MINT = 10;

    // uint256 public PRESALE_MAX_MINT = 5;

    uint256 public zoulsReserved = 100;

    uint256 public zoulsPresaleSupply;

    bool public preSaleLive;

    bool public publicSaleLive = false;

    bool public zoulsRevealed = false;

    string public baseTokenURI;
    
    string public notRevealedUri;

    string public baseExtension;

    mapping(address => bool) private _presaleAccess;

    mapping(address => uint256) private _totalZoulClaimed;

    constructor(string memory _baseTokenURI, string memory _notRevealedUri, uint256 _zoulsPresaleSupply)
        ERC721("ZoulChaser", "ZCHSR")
    {
        baseTokenURI = _baseTokenURI;
        notRevealedUri = _notRevealedUri;
        zoulsPresaleSupply = _zoulsPresaleSupply;
    }

    // INTERNAL
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // PUBLIC
    function _mintZoul(uint256 numZouls) internal returns (bool) {
        for (uint256 i = 0; i < numZouls; i++) {
            uint256 tokenIndex = totalSupply();
            if (tokenIndex < GENESIS_ZOULS_TOTAL) {
                _totalZoulClaimed[msg.sender] += 1;
                _safeMint(_msgSender(), tokenIndex);
            }
        }
        return true;
    }

    function mintPresale(uint256 numZouls)
        public
        payable
        whenNotPaused
        returns (bool)
    {
        uint256 currSupply = totalSupply();
        require(preSaleLive, "The Pre-Sales Window Has Not Been Opened Yet.");
        // require(_presaleAccess[msg.sender], "You are not on the presale list");
        // require(numZouls <= PRESALE_MAX_MINT,"You can not Mint that many Zouls during the Pre-Sales Window. Please Try Again.");
        require(numZouls > 0, "You Need to Mint at Least 1 Zoul From The Underworld. Please Try Again.");
        require(currSupply + numZouls < zoulsPresaleSupply,"You are Attempting to Exceeded Pre-Sale Supply. Please Try Again.");
        // require(_totalZoulClaimed[msg.sender] + numZouls <= PRESALE_MAX_MINT, "Purchase exceeds max allowed.");
        require(msg.value >= PUBLIC_MINT_PRICE * numZouls, "The Amount of Ethereum you are sending will cause an Insuffiecient Balance. Please Try Again.");
        return _mintZoul(numZouls);
    }

    function mintPublicSale(uint256 numZouls)
        public
        payable
        whenNotPaused
        returns (bool)
    {
        uint256 currSupply = totalSupply();
        require(publicSaleLive, "The Public-Sales Window Has Not Been Opened To The Public Yet.");
        require(numZouls > 0, "You Need to Mint at Least 1 Zoul From The Underworld. Please Try Again.");
        require(numZouls <= PUBLIC_MAX_PER_MINT, "You are Trying to Mint too many Zouls at Once. Please Try Again.");
        require(currSupply + numZouls < GENESIS_ZOULS_TOTAL - zoulsReserved, "You Have Exceeded The Total Supply. Please Try Again.");
        require(msg.value >= PUBLIC_MINT_PRICE * numZouls, "The Amount of Ethereum You have sent has caused an Insuffiecient Balance. Please Try Again.");
        return _mintZoul(numZouls);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);

            for (uint256 i; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }

            return result;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "The Token You're Looking For Is Nonexistent");

        // Toggle Default Reveal Image
        if(zoulsRevealed == false) {
            return notRevealedUri;
        }
    
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)): "";
        
    }

    // OWNER
    function togglePublicSaleLive() public onlyOwner {
        publicSaleLive = !publicSaleLive;
    }

    function togglePresale() public onlyOwner {
        preSaleLive = !preSaleLive;
    }

    function togglePublicReveal() public onlyOwner {
        zoulsRevealed = !zoulsRevealed;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
      
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setMaxMintCap(uint256 _maxMintCap) public onlyOwner {
        PUBLIC_MAX_PER_MINT = _maxMintCap;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent Balance Detected. Please Try Again.");
        require(payable(ZC_FOUNDERS_VAULT).send(address(this).balance));
    }

    function reserveZouls(uint256 numZouls) public onlyOwner {
        require(numZouls <= zoulsReserved, "Amount Exceeds Total Remaining Zouls Supply.");
        for (uint256 i; i < numZouls; i++) {
            uint256 mintIndex = totalSupply();

            _safeMint(msg.sender, mintIndex);
        }
        zoulsReserved -= numZouls;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addToPresale(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            require(_users[i] != address(0), "Cannot add null address");
            _presaleAccess[_users[i]] = true;
            _totalZoulClaimed[_users[i]] > 0 ? _totalZoulClaimed[_users[i]] : 0;
        }
    }

    function checkPresaleStatus(address _user) external view returns (bool) {
        return _presaleAccess[_user];
    }

    function amountClaimedBy(address _user) external view returns (uint256) {
        require(_user != address(0), "Cannot add null address");
        return _totalZoulClaimed[_user];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}