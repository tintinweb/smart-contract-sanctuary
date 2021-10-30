// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./MinterRole.sol";
import "./Pausable.sol";
import "./ERC721.sol";

contract NormalBox is Context, Ownable, MinterRole, Pausable, ERC721 {
    using SafeMath for uint256;

    uint256 public constant CAP = 4800;
    uint256 public constant ROUND1_CAP = 1440;
    uint256 public constant ROUND2_CAP = 1920;
    uint256 public constant ROUND1_PRICE = 55 * 1e16;  // 0.55 BNB
    uint256 public constant ROUND2_PRICE = 60 * 1e16;  // 0.60 BNB
    uint256 public maxPerTime = 6;

    bool public saleIsActive;
    uint256 public currentRound;
    mapping(uint256 => uint256) private _roundToPrice;
    mapping(uint256 => uint256) private _roundToCap;

    event BuyNormalBox(address indexed to, uint256 indexed mintIndex, uint256 indexed roundNum);


    constructor() ERC721("Dracoo Normal Box", "DracooNBox") public {
        saleIsActive = false;
        currentRound = 1;
        _roundToPrice[1] = ROUND1_PRICE;
        _roundToPrice[2] = ROUND2_PRICE;
        _roundToCap[1] = ROUND1_CAP;
        _roundToCap[2] = ROUND1_CAP.add(ROUND2_CAP);
        _roundToCap[3] = CAP;
    }

    function setMaxPerTime(uint256 newMax) public onlyOwner {
        maxPerTime = newMax;
    }

    // Set round first, then active sale
    function setCurrentRound(uint256 roundNum) public onlyOwner {
        require(roundNum == 1 || roundNum == 2 || roundNum == 3, "roundNum must be 1 or 2 or 3");
        currentRound = roundNum;
    }

    function setSaleIsActive(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function checkCurrentRoundRemaining() public view returns (uint256) {
        require(saleIsActive, "this round sale does not start yet");
        return _roundToCap[currentRound].sub(totalSupply());
    }

    function mintbyMinter(address to, uint256 amounts) public onlyMinter {
        require(totalSupply().add(amounts) <= CAP, "can only mint 4800 normal boxes!");
        require(currentRound == 3, "must be in the 3rd round");
        
        for(uint256 i = 0; i < amounts; ++i) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < CAP) {
                _safeMint(to, mintIndex);

                emit BuyNormalBox(to, mintIndex, currentRound);
            }
        }
    }

    // start from tokenId = 0
    function buyNormalBox(uint256 amounts) public payable {
        require(_msgSender() == tx.origin, "contract can not buy");
        require(saleIsActive, "sale does not start yet");
        require(currentRound == 1 || currentRound == 2, "currentRound must be in Round #1 or #2");
        require(amounts <= maxPerTime, "can not excced maxPerTime limit");
        require(totalSupply().add(amounts) <= _roundToCap[currentRound], "can not exceed max cap in this round");
        require(amounts.mul(_roundToPrice[currentRound]) <= msg.value, "BNB value sent is not enough");

        for(uint256 i = 0; i < amounts; ++i) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < CAP) {
                _safeMint(_msgSender(), mintIndex);

                emit BuyNormalBox(_msgSender(), mintIndex, currentRound);
            }
        }

    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    } 

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        _setTokenURI(tokenId, tokenURI);
    }

    function withdrawBNB(address payable to) public onlyOwner {
        uint256 balance = address(this).balance;
        to.transfer(balance);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

}