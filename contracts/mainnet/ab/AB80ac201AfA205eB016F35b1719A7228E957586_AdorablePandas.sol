// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

/**
 * @title AdorablePandas
 * @dev art collection of 10,000 Adorable Pandas
 */
contract AdorablePandas is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Address of interface identifier for royalty standard
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Timestamp for activating crowdsale
    uint256 public activationTimestamp;

    // Timestamp for activating presale
    uint256 public presaleTimestamp;
    
    // Presale duration, secs
    uint256 public presaleDuration;

    // Prepend baseURI to tokenId
    string private baseURI;

    // Address of payment splitter contract
    address public beneficiary;

    // Max supply of total tokens
    uint256 public maxSupply = 10_000;

    // Max number of reserved tokens
    uint256 public maxReserve;

    // Boolean value for locking metadata
    bool public metadataFrozen = false;

    // Mint price of each token (0.01 ETH)
    uint256 public mintPrice = 10000000000000000;

    // Number of public tokens minted
    uint256 private numPublicMinted;

    // Number of reserve tokens claimed
    uint256 private numReserveClaimed;

    // Royalty percentage for secondary sales
    uint256 public royaltyPercentage = 3;

    /**
     * @dev Initializes contract and sets initial baseURI, activation timestamp and beneficiary
     * @param _initialBaseURI Temporary baseURI
     * @param _activationTimestamp Timestamp to determine start of crowdsale
     * @param _presaleTimestamp Timestamp to determine start of presale
     * @param _presaleDuration Duration of presale
     * @param _maxReserve Amount of reserved tokens
     * @param _beneficiary Address of payment splitter contract
     */
    constructor(
        string memory _initialBaseURI,
        uint256 _activationTimestamp,
        uint256 _presaleTimestamp,
        uint256 _presaleDuration,
        uint256 _maxReserve,
        address _beneficiary
    ) ERC721("Adorable Pandas", "PANDAS") {
        baseURI = _initialBaseURI;
        activationTimestamp = _activationTimestamp;
        presaleTimestamp = _presaleTimestamp;
        presaleDuration = _presaleDuration;
        beneficiary = _beneficiary;
        maxReserve = _maxReserve;
    }

    /**
     * @dev Mints specified number of tokens in a single transaction
     * @param _amount Total number of tokens to be minted and sent to `_msgSender()`
     *
     * Requirements:
     *
     * - `amount` must be less than max limit for a single transaction
     * - `msg.value` must be exact payment amount in wei
     * - `numPublicMinted` plus amount must not exceed max public supply
     */
    function mint(uint256 _amount) public payable {
        require(activationTimestamp <= block.timestamp || (presaleTimestamp + presaleDuration >= block.timestamp && presaleTimestamp <= block.timestamp), "Minting has not yet begun");
        require(_amount <= 20, "The max mint amount in a single transaction is 20");
        require(mintPrice * _amount == msg.value, "Incorrect payment amount");
        require(numPublicMinted + _amount <= maxSupply - maxReserve, "No more public tokens available to mint");

        numPublicMinted += _amount;
        _mint(_amount, _msgSender());

        payable(beneficiary).transfer(msg.value);
    }

    /**
     * @dev Mints specified number of tokens to a recipient
     * @param _amount Number of tokens to be minted
     * @param _recipient Address of recipient to transfer tokens to
     *
     * Requirements:
     *
     * - `activationTimestamp` must be less than or equal to the current block time
     * - `currentTotal` in addition to mint `amount` must not exceed the `maxSupply`
     */
    function _mint(uint256 _amount, address _recipient) private {
        require(_tokenIds.current() + _amount <= maxSupply, "Insufficienct number of tokens available");

        for (uint256 i = 0; i < _amount; i++) {
            uint256 newItemId = _tokenIds.current();
            _tokenIds.increment();
            _safeMint(_recipient, newItemId);
        }
    }

    /**
     * @dev Mints specified amount of tokens to list of recipients
     * @param _amount Number of tokens to be minted for each recipient
     * @param _recipients List of addresses to send tokens to
     *
     * Requirements:
     *
     * - `owner` must be function caller
     * - `numReserveClaimed` must not exceed the total max reserve
     */
    function mintReserved(uint256 _amount, address[] memory _recipients) public onlyOwner {
        numReserveClaimed += _recipients.length * _amount;
        require(numReserveClaimed <= maxReserve, "No more reserved tokens available to claim");

        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_amount, _recipients[i]);
        }
    }

    /**
     * @dev See {IERC721-baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the total number of tokens currently minted.
     */
    function totalSupply() public view returns (uint256) {
        return numPublicMinted + numReserveClaimed;
    }

    /**
     * @dev Sets the baseURI with the official metadataURI
     * @param _newBaseURI Metadata URI used for overriding initialBaseURI
     *
     * Requirements:
     *
     * - `owner` must be function caller
     * - `metadataFrozen` must be false
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(metadataFrozen == false, "Metadata can no longer be altered");

        baseURI = _newBaseURI;
    }

    /**
     * @dev freezes the metadata URI so it can't be changed
     *
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function freezeMetadata() public onlyOwner {
        metadataFrozen = true;
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice * royaltyPercentage) / 100;

        return (beneficiary, royaltyAmount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }
}