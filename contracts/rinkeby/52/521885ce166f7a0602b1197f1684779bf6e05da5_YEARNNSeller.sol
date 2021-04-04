/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface IERC721 {

    function mint(address to, uint32 _assetType, uint32 _customDetails) external returns (bool success);

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

contract YEARNNSeller is Ownable {
    
    address public tokenAddress;
    address public nftAddress;
    address public sellingWallet;
    
    struct assetDescription {
        uint256 price;
        uint32 details;
    }
    mapping(uint => assetDescription) public assets;
    
    constructor() {
        sellingWallet = 0x742c6aFf3cC30E6AC1576aaAade52d356E4C85B4;
        nftAddress = 0xcc863A5FD47B6121691c191F1eb8A97E83A90329;
        tokenAddress = 0xeAA2484Dc3CdC2fA34098e2e2A1e70047355e3F0;
        fillAssets(1, (1800 ether), 825241649);
        fillAssets(2, (3600 ether), 825241649);
        fillAssets(3, (9000 ether), 825241650);
        fillAssets(4, (12000 ether), 825241651);
        fillAssets(5, (18000 ether), 825241652);
        fillAssets(6, (90000 ether), 825241653);
        fillAssets(7, (78600 ether), 825241654);
        fillAssets(8, (48000 ether), 825241655);
        fillAssets(9, (108000 ether), 825241656);
        fillAssets(10, (66000 ether), 825241905);
        fillAssets(11, (126000 ether), 825241906);
        fillAssets(12, (60000 ether), 825241907);
        fillAssets(13, (27000 ether), 825241908);
        fillAssets(14, (36000 ether), 825241909);
        fillAssets(15, (54000 ether), 825241910);
    }
    
    function fillAssets(uint256 _id, uint256 _price, uint32 _details) private {
        assets[_id].price = _price;
        assets[_id].details = _details;
    }
    
    function bytesToUint(bytes memory b) private pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
        return number;
    }
    
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public returns (bool success) {
        require(tokenAddress == _token);
        uint assetType = bytesToUint(_extraData);
        require(assets[assetType].price <= _value);
        IERC20Token token = IERC20Token(tokenAddress);
        require(token.transferFrom(_from, sellingWallet, assets[assetType].price), "ERC20 Transfer error");
        IERC721 nft = IERC721(nftAddress);
        require(nft.mint(_from, uint32(assetType), assets[assetType].details));
        return true;
    }
    
    function setPrice(uint256 _assetId, uint256 _newPrice) public onlyOwner {
        assets[_assetId].price = _newPrice;
    }
    
    
    
    
    
    
    
    
    
}