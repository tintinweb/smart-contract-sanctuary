// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 *    /$$$$$$   /$$$$$$  /$$$$$$$$
 *   /$$__  $$ /$$__  $$|__  $$__/
 *  | $$  \__/| $$  \ $$   | $$
 *  | $$      | $$$$$$$$   | $$
 *  | $$      | $$__  $$   | $$
 *  | $$    $$| $$  | $$   | $$
 *  |  $$$$$$/| $$  | $$   | $$    $$S
 *   \______/ |__/  |__/   |__/
 */

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract InnocentCats is ERC721A, Ownable {
    enum Status {
        Pending,
        PreSale,
        PublicSale,
        Finished
    }

    Status public status;
    string public baseURI;
    bytes32 public root;
    uint256 public tokensReserved;
    uint256 public immutable maxPresaleMint;
    uint256 public immutable maxPublicMint;
    uint256 public immutable maxSupply;
    uint256 public immutable reserveAmount;
    uint256 public constant PRICE = 0.02 ether;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event RootChanged(bytes32 root);
    event ReservedToken(address minter, address recipient, uint256 amount);
    event BaseURIChanged(string newBaseURI);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Contract is not allowed to mint.");
        _;
    }

    constructor(
        string memory initBaseURI,
        uint256 _maxPresaleMint,
        uint256 _maxPublicMint,
        uint256 _maxSupply,
        uint256 _reserveAmount
    )
        ERC721A(
            "InnocentCats",
            "InnocentCats",
            _maxPresaleMint > _maxPublicMint ? _maxPresaleMint : _maxPublicMint,
            _maxSupply
        )
    {
        baseURI = initBaseURI;
        maxPresaleMint = _maxPresaleMint;
        maxPublicMint = _maxPublicMint;
        maxSupply = _maxSupply;
        reserveAmount = _reserveAmount;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory uri = super.tokenURI(tokenId);
        return
            bytes(uri).length > 0 ? string(abi.encodePacked(uri, ".json")) : "";
    }

    function reserve(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Zero address");
        require(amount > 0, "Invalid amount");
        require(
            totalSupply() + amount <= collectionSize,
            "Max supply exceeded"
        );
        require(
            tokensReserved + amount <= reserveAmount,
            "Max reserve amount exceeded"
        );

        uint256 multiple = amount / maxBatchSize;
        for (uint256 i = 0; i < multiple; i++) {
            _safeMint(recipient, maxBatchSize);
        }
        uint256 remainder = amount % maxBatchSize;
        if (remainder != 0) {
            _safeMint(recipient, remainder);
        }
        tokensReserved += amount;
        emit ReservedToken(msg.sender, recipient, amount);
    }

    function presaleMint(uint256 amount, bytes32[] calldata proof)
        external
        payable
        callerIsUser
    {
        require(status == Status.PreSale, "Presale is not active.");
        require(
            MerkleProof.verify(proof, root, bytes32(abi.encode(msg.sender))),
            "Invalid proof."
        );
        require(
            numberMinted(msg.sender) + amount <= maxPresaleMint,
            "Max mint amount per wallet exceeded."
        );
        require(
            totalSupply() + amount + reserveAmount - tokensReserved <=
                collectionSize,
            "Max supply exceeded."
        );

        _safeMint(msg.sender, amount);
        refundIfOver(PRICE * amount);

        emit Minted(msg.sender, amount);
    }

    function mint(uint256 amount) external payable callerIsUser {
        require(status == Status.PublicSale, "Public sale is not active.");
        require(amount <= maxPublicMint, "Max mint amount per tx exceeded.");
        require(
            totalSupply() + amount + reserveAmount - tokensReserved <=
                collectionSize,
            "Max supply exceeded."
        );

        _safeMint(msg.sender, amount);
        refundIfOver(PRICE * amount);

        emit Minted(msg.sender, amount);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdraw() external onlyOwner {
        require(status == Status.Finished, "Invalid status for withdrawn.");

        payable(owner()).transfer(address(this).balance);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(_status);
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
        emit RootChanged(_root);
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}