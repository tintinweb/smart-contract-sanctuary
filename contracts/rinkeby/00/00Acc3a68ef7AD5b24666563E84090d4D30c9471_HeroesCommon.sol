// SPDX-License-Identifier: MIT
// Galaxy Heroes NFT game 
pragma solidity 0.8.6;

import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract HeroesCommon is ERC721Enumerable, Ownable {

    struct Partners {
        uint256 limit;
        uint256 nftMinted;
    }

    uint256 constant public MAX_TOTAL_SUPPLY = 6000;
    uint256 constant public MAGIC_BOX_TOKENID = 777777777777777777777777777;
    uint256 constant public MAX_MINT_PER_TX = 100;
    uint256 constant public MAX_BUY_PER_TX = 3;

    uint256 public mintPrice = 5e16;
    uint256 public stopMintAfter = 2000; //First Wave ofCommon Heroes
    uint256 public reservedForPartners;
    uint256 public enableBuyAfterTimestamp;

    mapping (uint256 => uint256)  internal isMagicBox;
    mapping (address => Partners) public   partnersLimit;
    mapping (address => uint256)  public   tokensForMint;

    //Event for track mint channel:
    // 1 - MagicBox
    // 2 - With Ethere
    // 3 - Partners White List
    // 4 - With ERC20
    event MintSource(uint256 tokenId, uint8 channel);
    event PartnesChanged(address partner, uint256 limit);
    
    /**
     * @dev Set _mintMagicBox to true for enable this feature 
     * 
     */
    constructor(uint256 _amount, bool _mintMagicBox) ERC721("Sidus NFT Heroes", "Sidus")  {
        //Let's mint MagicBox if need
        if (_mintMagicBox) {
            _mint(owner(),MAGIC_BOX_TOKENID);
            isMagicBox[MAGIC_BOX_TOKENID] = _amount;
        }
        enableBuyAfterTimestamp = block.timestamp + 150;
        
    }

    
    /**
     * @dev Mint new NFTs with ether or free for partners. 
     * 
     */
    function multiMint() external payable {
        uint256 mintAmount = _availableFreeMint(msg.sender);
        if(mintAmount > 0) {
            require(msg.value == 0, "No need Ether");
            mintAmount = _multiMint(msg.sender, mintAmount, 3);
            partnersLimit[msg.sender].nftMinted += mintAmount;
            reservedForPartners -= mintAmount;
        } else {
            require(enableBuyAfterTimestamp <= block.timestamp, "To early");
            require(msg.value >= mintPrice, "Less ether for mint");
            uint256 estimateAmountForMint = msg.value / mintPrice;
            require(estimateAmountForMint <= MAX_BUY_PER_TX, "So much payable mint");
            require(stopMintAfter - reservedForPartners >= totalSupply()  +  estimateAmountForMint, "Minting is paused");
            mintAmount = _multiMint(msg.sender, estimateAmountForMint, 2);
            if  ((msg.value - mintAmount * mintPrice) > 0) {
                address payable s = payable(msg.sender);
                s.transfer(msg.value - mintAmount * mintPrice);
            }
        }
    }


    
    /**
     * @dev Mint new NFTs with ERC20 payment 
     * 
     */
    function mintWithERC20(address _withToken, uint256 _nftAmountForMint) external  {
        require(enableBuyAfterTimestamp <= block.timestamp, "To early");
        require(tokensForMint[_withToken] > 0, "No mint with this Token");
        require(stopMintAfter - reservedForPartners >= totalSupply()  + _nftAmountForMint, "Minting is paused");
        require(_nftAmountForMint <= MAX_BUY_PER_TX, "So much payable mint");
        IERC20(_withToken).transferFrom(
            msg.sender, 
            address(this), 
            tokensForMint[_withToken] * _nftAmountForMint
        );
        require(
            _multiMint(msg.sender, _nftAmountForMint, 4) == _nftAmountForMint,
            "Error in multi mint"
        );   
    }

    
    /**
     * @dev Returns avilable for free mint NFTs for address
     * 
     */
    function availableFreeMint(address _partner) external view returns (uint256) {
        return _availableFreeMint(_partner);    
    }
    

   
    ///////////////////////////////////////////////////////////////////
    /////  Owners Functions ///////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////
    function setPartner(address _partner, uint256 _limit) external onlyOwner {
        _setPartner(_partner, _limit);
    }

    function setPartnerBatch(address[] memory _partners, uint256[] memory _limits) external onlyOwner {
        require(_partners.length == _limits.length, "Array params must have equal length");
        require(_partners.length <= 256, "Not more than 256");
        for (uint8 i; i < _partners.length; i ++) {
            _setPartner(_partners[i], _limits[i]);
        }

    } 

    function setMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function withdrawEther() external onlyOwner {
        address payable o = payable(msg.sender);
        o.transfer(address(this).balance);
    }

    function withdrawTokens(address _erc20) external onlyOwner {
        IERC20(_erc20).transfer(msg.sender, IERC20(_erc20).balanceOf(address(this)));
    }

    function editMagicBox(uint256 _tokenId, uint256 _amount) external onlyOwner {
        isMagicBox[_tokenId] = _amount;
    }

    function setMintPause(uint256 _newTotalSupply) external onlyOwner {
        stopMintAfter = _newTotalSupply;
    }

    function setPriceInToken(address _token, uint256 _pricePerMint) external onlyOwner {
        require(_token != address(0), "No zero");
        tokensForMint[_token] = _pricePerMint;
    }

    function setEnableTimestamp(uint256 _newTimestamp) external onlyOwner {
        enableBuyAfterTimestamp = _newTimestamp;
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

    function _setPartner(address _partner, uint256 _limit) internal {
        require(_partner != address(0), "No zero");
        uint256 av = _availableFreeMint(_partner);
        require(_limit  >= partnersLimit[_partner].nftMinted, "Cant decrease more then minted");
        if (partnersLimit[_partner].limit < _limit) {
            reservedForPartners += _limit;
        } else {
            reservedForPartners -= _limit;
        }
        partnersLimit[_partner].limit = _limit;
        emit PartnesChanged(_partner, _limit);
    }

    function _multiMint(address to, uint256 amount, uint8 channel) internal returns (uint256) {
        require((totalSupply() + reservedForPartners + amount) <= MAX_TOTAL_SUPPLY, "No more common heroes");
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