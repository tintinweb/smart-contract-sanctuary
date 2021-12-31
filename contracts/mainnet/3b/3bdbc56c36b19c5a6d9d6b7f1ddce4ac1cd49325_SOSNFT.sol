// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

contract SOSNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public constant maxTokens = 10000;
    uint256 public mintPrice = 29000000 ether;
    bool public mintStarted = false;
    uint256 public batchLimit = 50;
    string public baseURI =
        "https://sosnftsos.mypinata.cloud/";

    IERC20 public sosToken;

    address public thiscontract = address(this);

    constructor() ERC721("SOSNFT", "SOS") {
        sosToken = IERC20(0x3b484b82567a09e2588A13D54D032153f0c0aEe0);
    }

    function mint(uint256 tokensToMint) public payable {
        uint256 supply = totalSupply();
        require(mintStarted, "Mint is not started");
        require(tokensToMint <= batchLimit, "Not in batch limit");
        require(
            (supply % 2000) + tokensToMint <= 2000,
            "Minting crosses price bracket"
        );
        require(
            supply.add(tokensToMint) <= maxTokens,
            "Minting exceeds supply"
        );

        uint256 cost = tokensToMint * mintPrice;
        uint256 allowance = sosToken.allowance(msg.sender, address(this));
        require(allowance >= cost, "Not enough allowance of SOS");

        sosToken.transferFrom(msg.sender, address(this), cost);
        for (uint16 i = 1; i <= tokensToMint; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

  
    function withdraw() public onlyOwner {
        sosToken.transfer(owner(), sosToken.balanceOf(address(this)));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function startMint() external onlyOwner {
        mintStarted = true;
    }

    function pauseMint() external onlyOwner {
        mintStarted = false;
    }

    function reserveSOS(uint256 numberOfMints) public onlyOwner {
        uint256 supply = totalSupply();
        for (uint256 i = 1; i <= numberOfMints; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
}