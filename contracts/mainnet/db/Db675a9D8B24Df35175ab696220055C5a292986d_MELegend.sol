// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Counters.sol";
import "./MerkleProof.sol";


//                                                                               
//   ,-.          ,-.  ,------.       ,--.                                   ,--. 
//  / .',--,--,--.'. \ |  .---',-----.|  |    ,---.  ,---.  ,---. ,--,--,  ,-|  | 
// |  | |        | |  ||  `--, '-----'|  |   | .-. :| .-. || .-. :|      \' .-. | 
// |  | |  |  |  | |  ||  `---.       |  '--.\   --.' '-' '\   --.|  ||  |\ `-' | 
//  \ '.`--`--`--'.' / `------'       `-----' `----'.`-  /  `----'`--''--' `---'  
//   `-'          `-'                               `---'                         
//
// Author: Richard Hutta
// Email: [email protected]
//
contract MELegend is ERC721Enumerable, Ownable, PaymentSplitter {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public maxMintSupply = 888;
    uint256 public maxGiftSupply = 50;

    uint256 public totalMinted;
    uint256 public totalGifted;

    uint256 presaleMintLimit = 3;

    string public baseURI;
    string public baseExtension = ".json";

    bool public publicState = false;
    bool public presaleState = false;

    mapping(address => uint256) public _presaleClaimed;

    uint256 _price = 150000000000000000; //0.15 ETH

    bytes32 public presaleRoot;

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [10, 1, 89];

    address[] private _team = [
        0xBD584cE590B7dcdbB93b11e095d9E1D5880B44d9,
        0x7c95D1209E2f95496C4c9A18aA653FdeD834503F,
        0x9b3397fcD9c19E6104D24Ff1542323Bd80f9109d
    ];

    constructor() 
        ERC721("(m)E-Legend", "MEL") 
        PaymentSplitter(_team, _teamShares) {}

    function enablePresale(bytes32 _presaleRoot) public onlyOwner {
        presaleState = true;
        presaleRoot = _presaleRoot;
    }

    function enablePublic() public onlyOwner {
        presaleState = false;
        publicState = true;
    }

    function disable() public onlyOwner {
        presaleState = false;
        publicState = false;
    }

    function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base,tokenId.toString(),baseExtension)) : "";
    }

    /**
     * Presale Mint, allows you to mint nft but you need to provide merkle proof,
     * see function verify().
     */
    function mint(uint256 _amount, bytes32[] memory proof) external payable {
        require(presaleState, "presale disabled");
        require(!publicState, "presale disabled");

        require(
            totalMinted + _amount <= maxMintSupply,
            "max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "value sent is not correct"
        );
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleMintLimit,
            "can't mint such a amount"
        );
        require(verify(msg.sender, proof), "not selected for the presale");

        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
            _presaleClaimed[msg.sender] = _presaleClaimed[msg.sender] + 1;
            totalMinted = totalMinted + 1;
        }
    }

    function mint(uint256 _amount) external payable {
        require(publicState, "mint disabled");

        require(_amount > 0, "zero amount");
        require(_amount <= 3, "can't mint so much tokens");

        require(
            totalMinted + _amount <= maxMintSupply,
            "max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "value sent is not correct"
        );
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
            totalMinted = totalMinted + 1;
        }
    }

    function gift(address[] calldata _addresses) external onlyOwner {
        require(
            totalGifted + _addresses.length <= maxGiftSupply,
            "max gift supply exceeded"
        );
        require(_addresses.length > 0, "no addresses to gift");

        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(_addresses[ind] != address(0), "null address");
            _tokenIds.increment();
            _safeMint(_addresses[ind], _tokenIds.current());
            totalGifted = totalGifted + 1;
        }
    }

    function gift(address _address, uint256 _amount) external onlyOwner {
        require(
            totalGifted + _amount <= maxGiftSupply,
            "max gift supply exceeded"
        );
        require(_address != address(0), "null address");
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _safeMint(_address, _tokenIds.current());
            totalGifted = totalGifted + 1;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function verify(address account, bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProof.verify(proof, presaleRoot, leaf);
    }

}