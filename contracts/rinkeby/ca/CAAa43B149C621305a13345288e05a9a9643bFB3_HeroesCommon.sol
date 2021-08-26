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
    uint256 constant public MAX_MINT_PER_TX = 100;

    uint256 public mintPrice = 55e15;

    mapping(uint256 => uint256)   internal isMagicBox;
    mapping(address => Partners) public partnersLimit;

    event MintSource(uint256 tokenId, uint8 channel);

    constructor(string memory name_,
        string memory symbol_, uint256 _amount) ERC721(name_, symbol_)  {
        //Let's mint MagicBox
        _mint(owner(),MAGIC_BOX_TOKENID);
        isMagicBox[MAGIC_BOX_TOKENID] = _amount;
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

    function multiMint() external payable {
        uint256 mintAmount = _availableFreeMint(msg.sender);
        if(mintAmount > 0) {
            mintAmount = _multiMint(msg.sender, mintAmount, 3);
            partnersLimit[msg.sender].nftMinted += mintAmount;
        } else {
            require(msg.value >= mintPrice, "Less ether for mint");
            mintAmount = _multiMint(msg.sender, msg.value / mintPrice, 2);
            if  ((msg.value - mintAmount * mintPrice) > 0) {
                address payable s = payable(msg.sender);
                s.transfer(msg.value - mintAmount * mintPrice);
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

    function editMagicBox(uint256 _tokenId, uint256 _amount) external onlyOwner {
        isMagicBox[_tokenId] = _amount;
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
            "https://dev.nftstars.app/backend/api/v1/nfts/metadata/0x",
            //string(abi.encodePacked(address(this))),
            toAsciiString(address(this)),
            "/")
        );
    }

    function _mintHero(address to) internal {
        require((totalSupply() + 1) < MAX_TOTAL_SUPPLY, "No more common heroes");
        _mint(to, totalSupply());
    }

    function _multiMint(address to, uint256 amount, uint8 channel) internal returns (uint256) {
        require((totalSupply() + 1) < MAX_TOTAL_SUPPLY, "No more common heroes");
        uint256 counter;
        if (amount  > MAX_MINT_PER_TX) {
            counter = MAX_MINT_PER_TX;
        } else {
            counter = amount;
        }

        if ((totalSupply() + counter) > MAX_TOTAL_SUPPLY) {
            counter = MAX_TOTAL_SUPPLY - totalSupply();
        }
        for(uint i = 0; i < counter; i++) {
            _mint(to, totalSupply());
            emit MintSource(totalSupply(), channel);
        }
        return counter;
    }

    function toAsciiString(address x) internal view returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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

        if (isMagicBox[tokenId] > 0) {
            uint256 counter = _multiMint(to, isMagicBox[tokenId], 1);
            return;
        } else {
            super._transfer(from, to, tokenId);
        }
    }


}