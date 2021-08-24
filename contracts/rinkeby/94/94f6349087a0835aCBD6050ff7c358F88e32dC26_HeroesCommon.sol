// SPDX-License-Identifier: MIT
// Galaxy Heroes NFT game 
pragma solidity 0.8.6;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract HeroesCommon is ERC721Enumerable, Ownable {

    struct Partners {
        uint256 limit;
        uint256 nftMinted;
    }

    uint256 constant public MAX_TOTAL_SUPPLY = 6000;
    uint256 constant public MAGIC_BOX_TOKENID = 777777777777777777777777777;

    uint256 public mintPrice = 55e15;

    mapping(uint256 => bool)   internal isMagicBox;
    mapping(address => Partners) public partnersLimit;

    constructor(string memory name_,
        string memory symbol_) ERC721(name_, symbol_)  {
        //Let's mint MagicBox
        _mint(owner(),MAGIC_BOX_TOKENID);
        isMagicBox[MAGIC_BOX_TOKENID] = true;
    }

    function mintHero() external payable {
         if (_availableFreeMint(msg.sender) > 0) {
            _mintHero(msg.sender);
            partnersLimit[msg.sender].nftMinted += 1;    
         } else {
            require(msg.value >= mintPrice,"Less ether for mint");
            _mintHero(msg.sender);
            if  ((msg.value - mintPrice) > 0) {
                address payable s = payable(msg.sender);
                s.transfer(msg.value - mintPrice);
            }

         }
    }

    function availableFreeMint(address _partner) external view returns (uint256) {
        return _availableFreeMint(_partner);    
    }
    

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. E
     */
    ///////////////////////////////////////////////////////////////////
    /////  Owners Functions ///////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////
    function setPartner(address _partner, uint256 _limit) external onlyOwner {
        require(_partner != address(0), "No zero");
        partnersLimit[_partner].limit = _limit;
    } 

    function setMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function withdrawEther() external onlyOwner {
        address payable o = payable(msg.sender);
        o.transfer(address(this).balance);
    }  

    ///////////////////////////////////////////////////////////////////
    /////  INTERNALS      /////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////
    function _availableFreeMint(address _partner) internal view returns (uint256) {
        return partnersLimit[_partner].limit - partnersLimit[_partner].nftMinted;
    } 


    function _baseURI() internal view override returns (string memory) {
        //return "https://dev.nftstars.app/backend/api/v1/nfts/metadata/{address}/{tokenId}";
        return string(abi.encodePacked(
            "https://dev.nftstars.app/backend/api/v1/nfts/metadata/",
            abi.encodePacked(address(this)),
            "/")
        );
    }

    function _mintHero(address to) internal {
        require((totalSupply() + 1) < MAX_TOTAL_SUPPLY, "No more common heroes");
        _mint(to, totalSupply());
    }

    /**
     * @dev Override standart OpenZeppelin hook
     * for check partners limit
     * 
     */
    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal  override {
    //     if (from == address(0)) {
    //         //This is MINT event
    //         _addTokenToAllTokensEnumeration(tokenId);
    //     }
    //     super._beforeTokenTransfer(from, to, tokenId);
    // }

    /**
     * @dev Override standart OpenZeppelin hook
     * due MagicBox never be transfered
     *
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {

        if (isMagicBox[tokenId]) {
            _mintHero(to);
            return;
        } else {
            super._transfer(from, to, tokenId);
        }
    }


}