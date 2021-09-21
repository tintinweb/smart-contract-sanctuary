// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./IRandomNumberGenerator.sol";

/**
 * @title ETHFLEX Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract ETHFLEX is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    string public PROVENANCE = "";
    uint256[13] public RandomIds = [
        5555, // This will be Brown ID
        5555, // This will be Brown ID
        5555, // This will be Brown ID
        5555, // This will be Brown ID
        5555, // This will be Brown ID
        5555, // This will be Brown ID
        5555, // This will be Brown ID
        5555, // This will be Brown ID
        5555, // This will be Brown ID
        5555, // This will be Brown ID
        5555, // This will be Silver ID
        5555, // This will be Silver ID
        5555 // This will be Gold ID
    ];
    uint256 public selectedIdNumber;

    bytes32 public requestId_;
    IRandomNumberGenerator internal randomGenerator_;

    uint256 public totalSaleElement;
    uint256 public mintPrice;
    uint256 public maxByMint;

    bool public saleIsActive;

    address public clientAddress = 0x4BC034c68a811Be6E30E1F2c9A38B2aBC38a326c;
    address public devAddress = 0x4DaCe7eF31580837b8dA650FFCf1977cA43f6cee;

    event CreateETHFLEX(address indexed minter, uint256 indexed id);

    modifier checkSaleIsActive() {
        require(saleIsActive == true, "Sale is not active");
        _;
    }

    modifier onlyRandomGenerator() {
        require(
            msg.sender == address(randomGenerator_),
            "Only random generator"
        );
        _;
    }

    constructor() ERC721("ETHERFLEX", "ETHFLEX") {
        saleIsActive = false;

        totalSaleElement = 5555;
        mintPrice = 1 * 10**17; // 0.1 ETH
        maxByMint = 10;
    }

    /**
     * Set Mint Price
     */
    function setRandomGenerator(address randomGenerator) external onlyOwner {
        randomGenerator_ = IRandomNumberGenerator(randomGenerator);
    }

    /**
     * Get Random Number
     */
    function getRandomIdFromChainlink() external onlyOwner {
        require(
            selectedIdNumber < 13,
            "Random number generation is already completed"
        );
        requestId_ = randomGenerator_.getRandomNumber();
    }

    function checkRandomNumber(uint256 _randomNumber)
        internal
        view
        returns (bool)
    {
        for (uint256 i; i < selectedIdNumber; i++) {
            if (_randomNumber == RandomIds[i]) {
                return false;
            }
        }
        return true;
    }

    function numbersDrawn(bytes32 _requestId, uint256 _randomNumber)
        external
        onlyRandomGenerator
    {
        require(_requestId == requestId_, "Not correct request");
        uint256 random = _randomNumber % totalSaleElement;
        require(
            checkRandomNumber(random),
            "This random number is exist already."
        );

        RandomIds[selectedIdNumber] = random;
        selectedIdNumber = selectedIdNumber.add(1);
    }

    /**
     * Set Mint Price
     */
    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    /**
     * Set Max By Mint
     */
    function setMaxByMint(uint256 newMaxByMint) external onlyOwner {
        maxByMint = newMaxByMint;
    }

    /**
     * Set Sale Status
     */
    function setSaleStatus(bool saleStatus) external onlyOwner {
        saleIsActive = saleStatus;
    }

    /**
     * Set Base URI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
     * Set Base PROVENANCE
     */
    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE = _provenance;
    }

    /**
     * Get Total Supply
     */
    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /**
     * Get Total Mint
     */
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    /**
     * Check if certain token id is exists.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * Get Tokens Of Owner
     */
    function getTokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIdList = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIdList[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIdList;
    }

    /**
     * Mint An Element
     */
    function _mintAnElement(address _to) internal {
        uint256 id = _totalSupply();

        _tokenIdTracker.increment();
        _safeMint(_to, id);

        emit CreateETHFLEX(_to, id);
    }

    /**
     * Mint ETHFLEX By User
     */
    function mintByUser(address _to, uint256 _amount)
        public
        payable
        checkSaleIsActive
    {
        uint256 totalSupply = _totalSupply();

        require(totalSupply <= totalSaleElement, "Presale End");
        require(
            totalSupply + _amount <= totalSaleElement,
            "Max Limit To Presale"
        );
        require(_amount <= maxByMint, "Exceeds Amount");
        require(mintPrice.mul(_amount) <= msg.value, "Low Price To Mint");

        for (uint256 i = 0; i < _amount; i += 1) {
            _mintAnElement(_to);
        }
    }

    /**
     * Mint ETHFLEX By Owner
     */
    function mintByOwner(address _to, uint256 _amount) external onlyOwner {
        uint256 totalSupply = _totalSupply();

        require(totalSupply <= totalSaleElement, "Presale End");
        require(
            totalSupply + _amount <= totalSaleElement,
            "Max Limit To Presale"
        );

        for (uint256 i = 0; i < _amount; i += 1) {
            _mintAnElement(_to);
        }
    }

    /**
     * Withdraw
     */
    function withdrawAll() public onlyOwner {
        uint256 totalBalance = address(this).balance;

        uint256 devAmount = totalBalance.mul(470).div(10000);
        uint256 clientAmount = totalBalance.sub(devAmount);

        (bool withdrawDev, ) = devAddress.call{value: devAmount}("");
        require(withdrawDev, "Withdraw Failed To Dev");
        (bool withdrawClient, ) = clientAddress.call{value: clientAmount}("");
        require(withdrawClient, "Withdraw Failed To Client.");
    }
}