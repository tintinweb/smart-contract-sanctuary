/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

interface IERC20Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface IERC721 {
    function getTokenDetails(uint256 index) external view returns (uint32 aType, uint32 customDetails, uint32 lastTx, uint32 lastPayment, uint256 initialvalue, string memory coin);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Ownable {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }


    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract MarketFees is Ownable {
    IERC721 nftContract;
    struct ArtGallery {
        uint128 offset;
        uint128 paid;
        bool initialized;
    }
    
    struct FeeFactor {
        uint256 mulFactor;
        uint256 divFactor;
    }
    
    mapping (uint256 => ArtGallery) public aGallery;
    uint256 public aGalleryEarnings;
    uint256 aGalleryCount;

    mapping (uint32 => bool) public zerofeeAssets;
    mapping (address => FeeFactor) public tokenFee;
    
    address public marketContract;
    address public tokenAddress;
    address public walletAddress;
    
    constructor() {
        nftContract = IERC721(0xd6EB2D21a6267ae654eF5dbeD49D93F8b9FEEad9);
        marketContract = 0xe45fD2B2457a5411ed2d007Ca34B87b034FF8a89;
        tokenAddress = 0x6Ae9701B9c423F40d54556C9a443409D79cE170a;
        walletAddress = 0xf7A9F6001ff8b499149569C54852226d719f2D76;
        tokenFee[0x6Ae9701B9c423F40d54556C9a443409D79cE170a].mulFactor = 1;
        tokenFee[0x6Ae9701B9c423F40d54556C9a443409D79cE170a].divFactor = 100;
        zerofeeAssets[24] = true;
    }
    
    function calcByToken(address _seller, address _token, uint256 _amount) public returns (uint256 fee) {
        if (tokenFee[_token].mulFactor == 0) {
            return (0);
        } else {
            if (checkZeroFeeAsset(_seller)) {
                return (0);
            } else {
                uint256 totalFee = ((_amount*tokenFee[_token].mulFactor)/tokenFee[_token].divFactor);
                if (msg.sender == marketContract) {
                    aGalleryEarnings += ((totalFee / 2) / aGalleryCount);
                }
                return (totalFee);
            }
        }
    }
    
    function checkZeroFeeAsset(address _seller) private view returns (bool free) {
        uint256 assetCount = nftContract.balanceOf(_seller);
        bool freeTrade;
        if (assetCount > 0) {
            for (uint i=0; i<assetCount; i++) {
            (uint32 assetType,,,,,) = (nftContract.getTokenDetails(nftContract.tokenOfOwnerByIndex(_seller, i)));
                if (zerofeeAssets[assetType] == true) {
                    freeTrade = true;
                }
            } 
        }

        return (freeTrade);
    }
    
    function setTokenFee(address _token, uint256 _mulFactor, uint256 _divFactor) public onlyOwner {
        tokenFee[_token].mulFactor = _mulFactor;
        tokenFee[_token].divFactor = _divFactor;
    }

    function initGallery(uint256 _assetId) public onlyOwner {
        aGallery[_assetId].initialized = true;
        aGallery[_assetId].offset = uint128(aGalleryEarnings);
        aGalleryCount += 1;
    }
    
    function removeGallery(uint256 _assetId) public onlyOwner {
        aGallery[_assetId].initialized = false;
        aGalleryCount -= 1;
    }
    
    function claimGalleryProfits(uint256 _assetId) public {
        require(aGallery[_assetId].initialized == true, "Asset not set");
        (uint32 assetType,,,,, ) = nftContract.getTokenDetails(_assetId);
        address assetOwner = nftContract.ownerOf(_assetId);
        require(assetType == 25, "Invalid asset");
        uint256 toPay = aGalleryEarnings - uint256(aGallery[_assetId].offset);
        if (toPay > 0) {
            aGallery[_assetId].offset = uint128(aGalleryEarnings);
            IERC20Token token = IERC20Token(tokenAddress);
            require(token.transferFrom(walletAddress, assetOwner, toPay), "ERC20 transfer fail");
        }
    }
    

}