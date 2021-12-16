// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ECDSA.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract MetaVax is ERC721, Ownable {
    using ECDSA for bytes32;
    using Strings for uint;
    constructor(string memory hiddenURI_) ERC721("MetaVax","VAX") {
        hiddenURI = hiddenURI_;
    }

    modifier verifyEtherSent(uint amount, uint cost) {
        require(msg.value == amount * cost, "Invalid ether amount sent");
        _;
    }

    modifier verifySignature(bytes memory signature) {
        require(keccak256(abi.encodePacked(msg.sender)).toEthSignedMessageHash().recover(signature) == signer, "Invalid signature");
        _;
    }

    modifier directOnly {
        assert(msg.sender == tx.origin);
        _;
    }

    modifier onlyStaking {
        require(msg.sender == stakingAddress);
        _;
    }

    modifier publicSaleActive {
        require(publicSale);
        _;
    }

    modifier whitelistSaleActive {
        require(whitelistSale);
        _;
    }

    // Constants

    uint constant maxPerTX = 10;
    uint constant maxWhitelistPerAddress = 5;

    uint constant ethPublicCost = 0.069 ether;
    uint constant ethWhitelistCost = 0.059 ether;

    uint constant minPublicId = 1;
    uint constant maxPublicId = 5934;
    uint constant minPrivateId = 5935;
    uint constant maxPrivateId = 6019;
    uint constant minId = 1;

    // Storage Variables

    uint nextPublicId = minPublicId;
    uint nextPrivateId = minPrivateId;

    string baseURI;
    string hiddenURI;

    address signer = 0x571A7D7a73077d74f241dF9e627981720E354E6A;
    address public stakingAddress = address(0);
    
    bool public publicSale;
    bool public whitelistSale;

    mapping(address => uint) public whitelistMints;

    // Minting

    function publicMint(uint amount) external payable directOnly verifyEtherSent(amount, ethPublicCost) publicSaleActive {
        require(amount <= maxPerTX,string(abi.encodePacked("You can only mint up to ", maxPerTX.toString(), " in a single transaction")));
        mint(amount);
    }

    function whitelistMint(uint amount, bytes memory signature) external payable directOnly verifySignature(signature) verifyEtherSent(amount, ethWhitelistCost) whitelistSaleActive {
        require(whitelistMints[msg.sender] + amount <= maxWhitelistPerAddress, string(abi.encodePacked("You can only mint up to ", maxWhitelistPerAddress.toString(), " times using your whitelist!")));
        mint(amount);
        whitelistMints[msg.sender] += amount;
    }

    function mint(uint amount) internal {    
        uint nextId = nextPublicId;
        require(nextId + amount <= maxPublicId + minId, "Mint would exceed supply");
        _batchMint(msg.sender,amount,nextId);
        nextPublicId += amount;
    }

    // View

    function totalSupply() external view returns(uint) {
        return ((nextPublicId - minPublicId) + (nextPrivateId - minPrivateId));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(bytes(baseURI).length != 0 ){
            return string(abi.encodePacked(baseURI, tokenId.toString(),".json"));
        } else {
            return string(hiddenURI);
        }
    }

    // Internal

    function _batchMint(address addr, uint amount, uint startId) internal {
        for(uint i = 0; i < amount; i++) {
            _mint(addr, startId + i);
        }
    }


    // Only Owner

    function adminMint(address[] memory addresses) external onlyOwner {
        unchecked {
            uint nextId = nextPrivateId;
            require(nextId + addresses.length <= maxPrivateId + minId,"Limit reached");

            for(uint i = 0; i < addresses.length; i++) {
                _mint(addresses[i],nextId + i);
            }
            nextPrivateId += addresses.length;
        }
    }

    function adminSetBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function adminSetSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    function adminSetStakingAddress(address stakingAddress_) external onlyOwner {
        stakingAddress = stakingAddress_;
    }

    function adminSetSales(bool publicSale_, bool whitelistSale_) external onlyOwner {
        publicSale = publicSale_;
        whitelistSale = whitelistSale_;
    }
    
    address payable constant devs = payable(0x0408CFcde646bbADa944BF4312e6a2EF61ce8e7b);   // 10%
    address payable constant moey = payable(0xe1afF414c96EF6b10C2a51cDB95C7db60c04Bfe6);   // 42.5%
    address payable constant carts = payable(0x936c5150DA2e79C1fAE4c92Fd17FD3bCbC3957DC);  // 42.5%
    address payable constant artist = payable(0xDDbBCb27f07BA44A4c63E9d208278523f7225835); // 5%

    function adminWithdraw() external onlyOwner {
        uint balance = address(this).balance;
        devs.transfer(balance * 100 / 1000);  // 10%
        moey.transfer(balance * 425 / 1000);  // 42.5%
        carts.transfer(balance * 425 / 1000); // 42.5%
        artist.transfer(balance * 50 / 1000); // 5%
    }

    // Future Staking

    function stakingTakeToken(address from, uint id) external onlyStaking {
        _transfer(from,msg.sender,id);
    }
}