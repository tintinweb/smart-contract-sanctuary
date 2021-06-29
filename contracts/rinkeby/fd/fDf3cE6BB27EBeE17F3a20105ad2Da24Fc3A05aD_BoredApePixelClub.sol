pragma solidity ^0.7.0;

import "./BoredApeYachtClub.sol";


contract BoredApePixelClub is ERC721, Ownable {
    using SafeMath for uint256;

    BoredApeYachtClub boredApeYachtClub;

    // TODO add provenance
    string private constant _PROVENANCE_HASH = '';

    uint256 private constant _PRICE = 100000000000000000;

    uint public constant MAX_PURCHASE = 20;

    uint256 private _maxSupply;

    bool private _activeSale = false;

    address private _boredApeYachtClubAddress = 0x37461d1277223a9c9956865D2301D4B8E93B9409;

    mapping (address => bool) private _userRedeemed;

    uint256 public revealTimestamp;

    uint256 public constant SALE_DURATION_DAYS = 14;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    event WithdrawCompleted(address indexed recipient, uint256 amount);

    event ReserveCompleted(address indexed recipient, uint numberOfTokens);

    event BaseURIUpdated(string newBaseURI);

    event PurchaseCompleted(address indexed recipient, uint numberOfTokens, uint256 payment);

    event RedeemCompleted(address indexed recipient);

    constructor(string memory name, string memory symbol, uint maxSupply) ERC721(name, symbol) {
        boredApeYachtClub = BoredApeYachtClub(_boredApeYachtClubAddress);
        _maxSupply = maxSupply;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);

        emit BaseURIUpdated(baseURI);
    }

    function setBoredApeYachtClubAddress(address boredApeYachtClubAddress) public onlyOwner {
        _boredApeYachtClubAddress = boredApeYachtClubAddress;
        boredApeYachtClub = BoredApeYachtClub(_boredApeYachtClubAddress);
    }

    function setRevealTimestamp() private onlyOwner {
        revealTimestamp = uint256(block.timestamp) + (86400 * SALE_DURATION_DAYS);
    }

    function flipSaleState() public onlyOwner {
        _activeSale = !_activeSale;

        if (_activeSale) {
            setRevealTimestamp();
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);

        emit WithdrawCompleted(msg.sender, balance);
    }

    function reserve(uint numberOfTokens) public onlyOwner {
        _mintToSender(numberOfTokens);

        emit ReserveCompleted(msg.sender, numberOfTokens);
    }

    function purchase(uint numberOfTokens) public payable {
        require(numberOfTokens <= MAX_PURCHASE, "Can only purchase a maximum of 20");
        require(_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        _mintToSender(numberOfTokens);

        emit PurchaseCompleted(msg.sender, numberOfTokens, msg.value);
    }

    function hasBoughtBoredApe() public view returns (bool) {
        uint256 balance = boredApeYachtClub.balanceOf(msg.sender);
        return balance > 0;
    }

    function hasRedeemed() public view returns (bool) {
        return _userRedeemed[msg.sender];
    }

    function redeem() public {
        require(hasBoughtBoredApe(), "User hasn't bought a BoredApe before");
        require(!hasRedeemed(), "User already redeemed a token");
        _mintToSender(1);

        _userRedeemed[msg.sender] = true;

        emit RedeemCompleted(msg.sender);
    }

    function _mintToSender(uint numberOfTokens) internal {
        require(_activeSale, "Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= _maxSupply, "Minting would exceed max supply");

        for (uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (totalSupply() == _maxSupply || block.timestamp >= revealTimestamp)) {
            startingIndexBlock = block.number;
        }
    }

    function provenanceHash() public view virtual returns (string memory) {
        return _PROVENANCE_HASH;
    }

    function price() public view virtual returns (uint256) {
        return _PRICE;
    }

    function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }

    function setStartingIndex() public {
        require(startingIndexBlock != 0, "Starting index block must be set");
        require(startingIndex == 0, "Starting index is already set");

        startingIndex = uint(blockhash(startingIndexBlock)) % _maxSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % _maxSupply;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }
}