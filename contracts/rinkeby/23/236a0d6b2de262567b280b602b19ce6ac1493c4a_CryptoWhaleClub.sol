// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract CryptoWhaleClub is ERC721Burnable, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;
    
    // metadata
    bool public metadataLocked = false;
    string public baseURI = "";

    // supply and phases
    uint256 public mintIndex = 1;
    bool public presaleEnded = true;
    bool public publicSaleEnded = false;
    bool public mintPaused = false;
    uint256 public currentPhase = 0;

    // presale whitelist
    mapping(uint256 => mapping(address => uint256)) public mintedDuringPresaleAtPhase;
    
    // limits and parameters
    uint256 public priceEth = 0.06 ether;
    uint256 public priceBlub = 1000;
    uint256 public maxOwnedPerWallet = 2499;
    uint256 public maxMintedPerWallet = 0;
    uint256 public minBlubForPresaleAccess = 3000;

    uint256 public maxSupplyForPhase = 1750;
    uint256 public maxMintedPerWalletForPhasePresale = 5;
    uint256 public maxMintedPerTxForPhaseSale = 20;
    uint256 public maxMintedPerWalletForPhaseWithBlub = 3;

    mapping (address => uint256) public minted;
    mapping (address => mapping(uint256 => uint256)) public mintedPerPhase;
    mapping (address => mapping(uint256 => uint256)) public mintedWithBlubPerPhase;

    // external addresses
    IERC20 public blubToken;

    // shareholders
    address public shareholderMBWallet;
    address public shareholderRewardsWallet;
    uint256 public constant SHAREHOLDER_PERCENTAGE_MB = 25;
    uint256 public constant SHAREHOLDER_PERCENTAGE_OWNER = 65;
    uint256 public constant SHAREHOLDER_PERCENTAGE_REWARDS = 10;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection
     */
    constructor()
        ERC721("CryptoWhaleClub", "WHALE")
    {
        shareholderMBWallet = 0xbCc4CD9BDdaCeFff7e0E7B9dd7a7d7FbC622a960;
        shareholderRewardsWallet = 0x0252799e6CCD2C26371774F178dd4497C2219699;
    }
    
    /**
     * ------------ METADATA ------------ 
     */

    /**
     * @dev Gets base metadata URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    /**
     * @dev Sets base metadata URI, callable by owner
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        require(metadataLocked == false);
        baseURI = _uri;
    }
    
    /**
     * @dev Lock metadata URI forever, callable by owner
     */
    function lockMetadata() external onlyOwner {
        require(metadataLocked == false);
        metadataLocked = true;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }
    
    /**
     * ------------ SALE AND PRESALE ------------ 
     */
     
    /**
     * @dev Ends public sale forever, callable by owner
     */
    function endSaleForever() external onlyOwner {
        publicSaleEnded = true;
    }
    
    /**
     * @dev Ends the presale, callable by owner
     */
    function endPresaleForCurrentPhase() external onlyOwner {
        presaleEnded = true;
    }

    /**
     * @dev Advance sale phase
     */
    function advanceToPresaleOfNextPhase() public onlyOwner {
        require(presaleEnded);
        currentPhase++;
        presaleEnded = false;

        if (currentPhase == 2) {
            mintIndex = 2001;
        }
    }

    /**
     * @dev Set mint index manually
     */
    function setMintIndexManually(uint256 _mintIndex) public onlyOwner {
        mintIndex = _mintIndex;
    }

    /**
     * @dev Pause/unpause sale or presale
     */
    function togglePauseMinting() external onlyOwner {
        mintPaused = !mintPaused;
    }

    /**
     * ------------ CONFIGURATION ------------ 
     */

    /**
     * @dev Set BLUB token address
     */
    function setBlubTokenAddress(address _token) external onlyOwner {
        blubToken = IERC20(_token);
    }

    /**
     * @dev Edit general sale parameters
     */
    function editGeneralParameters(uint256 _priceEth, uint256 _priceBlub, uint256 _maxOwnedPerWallet, uint256 _maxMintedPerWallet, uint256 _minBlubForPresaleAccess) external onlyOwner {
        priceEth = _priceEth;
        priceBlub = _priceBlub;
        maxOwnedPerWallet = _maxOwnedPerWallet;
        maxMintedPerWallet = _maxMintedPerWallet;
        minBlubForPresaleAccess = _minBlubForPresaleAccess;
    }


    /**
     * @dev Edit phase-specific parameters
     */
    function editPhaseParameters(uint256 _maxSupplyForPhase, uint256 _maxMintedPerWalletForPhasePresale, uint256 _maxMintedPerTxForPhaseSale, uint256 _maxMintedPerWalletForPhaseWithBlub) public onlyOwner {
        maxSupplyForPhase = _maxSupplyForPhase;
        maxMintedPerWalletForPhasePresale = _maxMintedPerWalletForPhasePresale;
        maxMintedPerTxForPhaseSale = _maxMintedPerTxForPhaseSale;
        maxMintedPerWalletForPhaseWithBlub = _maxMintedPerWalletForPhaseWithBlub;
    }

    /**
     * @dev Edit phase-specific parameters and advance to next phase in a single tx
     */
    function advancePhaseAndSetParameters(uint256 _maxSupplyForPhase, uint256 _maxMintedPerWalletForPhasePresale, uint256 _maxMintedPerTxForPhaseSale, uint256 _maxMintedPerWalletForPhaseWithBlub) external onlyOwner {
        editPhaseParameters(_maxSupplyForPhase, _maxMintedPerWalletForPhasePresale, _maxMintedPerTxForPhaseSale, _maxMintedPerWalletForPhaseWithBlub);
        advanceToPresaleOfNextPhase();
    }

    /**
     * @dev Before transfer hook
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if (maxOwnedPerWallet > 0) {
            require(balanceOf(to) < maxOwnedPerWallet, "Receiver holds too many");
        }
    }
     
    /**
     * ------------ MINTING ------------ 
     */
    
    /**
     * @dev Mints `count` tokens to `to` address; internal
     */
    function mintInternal(address to, uint256 count) internal {
        for (uint256 i = 0; i < count; i++) {
            _mint(to, mintIndex);
            mintIndex++;
        }
    }
    
    /**
     * @dev Manual minting by owner, callable by owner;
     */
    function mintOwner(address[] calldata owners, uint256[] calldata tokenIds) external onlyOwner {
        require(owners.length == tokenIds.length, "Bad length");
         
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] >= 1751 && tokenIds[i] <= 2000);
            _mint(owners[i], tokenIds[i]);
        }
    }
    
    /**
     * @dev Check presale eligibility
     */
    function isEligibleForPresale(address wallet) public view returns (bool) {
        if (currentPhase == 1) {
            return true;
        }

        if (address(blubToken) != address(0)) {
            if (blubToken.balanceOf(wallet) >= minBlubForPresaleAccess) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Public minting during public sale or presale - internal
     */
    function mint(uint256 count) internal {
        require(!mintPaused, "Minting is currently paused");
        require(currentPhase > 0, "Sale not started");
        require(publicSaleEnded == false, "Sale ended");

        require(maxSupplyForPhase >= count, "Supply exceeded");

        if (maxMintedPerWallet > 0) {
            require(minted[msg.sender] + count <= maxMintedPerWallet, "Minted per wallet limit exceeded");
        }
        
        if (presaleEnded) {
            // public sale checks
            require(count <= maxMintedPerTxForPhaseSale, "Too many tokens");
        } else {
            // presale checks
            require(mintedPerPhase[msg.sender][currentPhase] + count <= maxMintedPerWalletForPhasePresale, "Limit exceeded");
            mintedPerPhase[msg.sender][currentPhase] += count;

            require(isEligibleForPresale(msg.sender), "Not eligible");
        }
        
        maxSupplyForPhase -= count;
        minted[msg.sender] += count;
        mintInternal(msg.sender, count);
    }

    
    /**
     * @dev Public minting (paying with ETH)
     */
    function mintWithEth(uint256 count) external payable{
        require(msg.value == count * priceEth, "Eth value incorrect");        
        mint(count);
    }

    /**
     * @dev Public minting (paying with BLUB)
     */
    function mintWithBlub(uint256 count) external {
        require(currentPhase >= 2, "Not available yet");
        require(mintedWithBlubPerPhase[msg.sender][currentPhase] + count <= maxMintedPerWalletForPhaseWithBlub, "Blub mint limit exceeded");
        
        mintedWithBlubPerPhase[msg.sender][currentPhase] += count;
        blubToken.transferFrom(msg.sender, address(this), priceBlub * count);
        mint(count);
    }

    /**
     * @dev Withdraw ETH from this contract, callable by owner
     */
    function withdrawEth() external nonReentrant {
        require(msg.sender == shareholderMBWallet || msg.sender == owner() || msg.sender == shareholderRewardsWallet, "Only Shareholder");

        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");

        uint256 availableToWithdrawMB = balance * SHAREHOLDER_PERCENTAGE_MB / 100;
        uint256 availableToWithdrawOwner = balance * SHAREHOLDER_PERCENTAGE_OWNER / 100;
        uint256 availableToWithdrawRewards = balance * SHAREHOLDER_PERCENTAGE_REWARDS / 100;

        payable(owner()).transfer(availableToWithdrawOwner);
        payable(shareholderMBWallet).transfer(availableToWithdrawMB);
        payable(shareholderRewardsWallet).transfer(availableToWithdrawRewards);
    }

    /**
     * @dev Withdraw BLUB from this contract, callable by owner
     */
    function withdrawBlub() external nonReentrant {
        require(msg.sender == shareholderMBWallet || msg.sender == owner() || msg.sender == shareholderRewardsWallet, "Only Shareholder");

        uint256 balance = blubToken.balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");

        uint256 availableToWithdrawMB = balance * SHAREHOLDER_PERCENTAGE_MB / 100;
        uint256 availableToWithdrawOwner = balance * SHAREHOLDER_PERCENTAGE_OWNER / 100;
        uint256 availableToWithdrawRewards = balance * SHAREHOLDER_PERCENTAGE_REWARDS / 100;

        blubToken.transfer(owner(), availableToWithdrawOwner);
        blubToken.transfer(shareholderMBWallet, availableToWithdrawMB);
        blubToken.transfer(shareholderRewardsWallet, availableToWithdrawRewards);
    }
}