// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";


contract Statues is ERC721Enumerable, ReentrancyGuard, Ownable {
    string public _baseTokenURI;
    uint256 public _reserved = 50;
    uint256 public _maxStatuesPerWallet = 2;
    uint256 public _totalToBeMinted = 5555;
    uint256 public _price = 0.2 ether;
    bool public _paused = true;
    bytes32 public _merkleRoot;
    // team addresses
    address immutable _team;
    bool public _presale = true;
    uint256 public _presaleReserved = 0;

    constructor(
        string memory baseURI,
        address team,
        uint256 totalToBeMinted,
        uint256 reserved,
        uint256 presaleReserved,
        bytes32 merkleRoot
    ) ERC721("Statues", "STAT") {
        setBaseURI(baseURI);
        _merkleRoot = merkleRoot;
        _team = team;
        _reserved = reserved;
        _totalToBeMinted = totalToBeMinted;
        _presaleReserved = presaleReserved;
        // team gets the  first congressman for giveaway
        _safeMint(team, 0);
    }

    function summon(uint256 amount) external payable {
        require(!_paused, "Paused");
        require(!_presale, "presale");
        require(
            amount + balanceOf(msg.sender) <= _maxStatuesPerWallet && amount > 0,
            "!StatuesAmount"
        );
        uint256 supply = totalSupply();
        require(supply + amount <= _totalToBeMinted - _reserved, ">MaxSupply");

        require(msg.value >= _price * amount, "!EthAmount");

        for (uint256 i; i < amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // only accessible for whitelisted sender
    function whitelistSummon(uint256 amount, bytes32[] memory proof)
        external
        payable
    {
        require(!_paused, "Paused");
        require(_presale, "!presale");
        require(verify(proof, _merkleRoot), "!whitelist");
        require(
            amount + balanceOf(msg.sender) <= _maxStatuesPerWallet && amount > 0,
            "!StatuesAmount"
        );
        uint256 supply = totalSupply();
        require(
            amount <= _presaleReserved &&
                supply + amount <= _totalToBeMinted - _reserved,
            ">availableSupply"
        );

        require(msg.value >= _price * amount, "!EthAmount");

        for (uint256 i; i < amount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        _presaleReserved -= amount;
    }

    function setPresalesParam(
        bytes32 merkleRootWhitelist,
        uint256 newAvailableAmount
    ) external onlyOwner {
        require(merkleRootWhitelist != bytes32(0), "!merkleRoot");
        // we change the merkleroot to take into account the new whitelist
        _merkleRoot = merkleRootWhitelist;
        // we add the newly available nft to the presale reserve
        _presaleReserved = newAvailableAmount;
    }

    function setMaxStatuesPerWallet(uint256 _newMax) external onlyOwner {
        _maxStatuesPerWallet = _newMax;
    }

    // Just in case Eth does some crazy stuff
    function setPrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= _reserved, ">reserved");
        require(_amount > 0, "_amount==0");
        require(_to != address(0), "_to==0");
        uint256 supply = totalSupply();
        for (uint256 i; i < _amount; i++) {
            _safeMint(_to, supply + i);
        }

        _reserved -= _amount;
    }

    function isWhitelisted(address account, bytes32[] memory proof)
        external
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function getTeam() public view returns (address) {
        return _team;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_team).send(address(this).balance), "NoEth");
    }

    function presale(bool val) public onlyOwner {
        _presale = val;
    }

    function verify(bytes32[] memory proof, bytes32 root)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}