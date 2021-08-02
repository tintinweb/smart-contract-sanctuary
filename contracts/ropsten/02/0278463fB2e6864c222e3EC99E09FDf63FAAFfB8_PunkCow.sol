// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract PunkCow is ERC721, Ownable {
    using SafeMath for uint256;

    string public PUNKCOW_PROVENANCE = "";

    bool public hasSaleStarted = false;
    uint256 public MAX_PUNKCOW_SUPPLY = 10000;
    uint256 public nftPrice = 0.1 ether;

    address payable private constant _team =
        payable(0xD6170A12b133005fAbCf877d636340a4B183b165);
    uint256 private _teamFee = 5;
    address public _treasuryAddress;

    constructor(string memory baseURI) ERC721("Punk Cow", "PUNKCOW") {
        _setBaseURI(baseURI);
        _treasuryAddress = msg.sender;
    }

    function deposit() external payable {}

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
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
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function getMintableCount() public view returns (uint256) {
        uint256 punkcowSupply = totalSupply();

        if (punkcowSupply >= MAX_PUNKCOW_SUPPLY) {
            return 0;
        } else {
            return 30;
        }
    }

    function getPunkCowPrice() public view returns (uint256) {
        uint256 punkcowSupply = totalSupply();

        if (punkcowSupply >= MAX_PUNKCOW_SUPPLY) {
            return 0;
        } else {
            return nftPrice;
        }
    }

    function setPrice(uint256 price) external onlyOwner {
        nftPrice = price;
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        MAX_PUNKCOW_SUPPLY = maxSupply;
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        PUNKCOW_PROVENANCE = _provenance;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function mintPunkCow(address to, uint256 count) public payable {
        uint256 punkcowSupply = totalSupply();
        require(hasSaleStarted);
        require(count > 0 && count <= getMintableCount());
        require(SafeMath.add(punkcowSupply, count) <= MAX_PUNKCOW_SUPPLY);
        require(SafeMath.mul(getPunkCowPrice(), count) == msg.value);

        for (uint8 i; i < count; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(to, mintIndex);
        }
    }

    function withdraw() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        uint256 teamAmount = ethBalance.mul(_teamFee).div(100);
        _team.transfer(teamAmount);
        payable(owner()).transfer(ethBalance.sub(teamAmount));
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function setTreasuryAddress(address treasuryAddress) public {
        require(msg.sender == _treasuryAddress);
        _treasuryAddress = treasuryAddress;
    }
}