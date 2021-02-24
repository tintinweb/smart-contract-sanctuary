/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Token {
    function transfer(address _to, uint256 _value) external  returns (bool success);
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

contract POLNSeller is Ownable {
    
    address public tokenAddress;
    address public nftAddress;
    address public sellingWallet;
    
    mapping(uint => uint) public assetPrice;
    
    constructor() {
        sellingWallet = 0xAD334543437EF71642Ee59285bAf2F4DAcBA613F;
        nftAddress = 0x57E9a39aE8eC404C08f88740A9e6E306f50c937f;
        tokenAddress = 0xaA8330FB2B4D5D07ABFE7A72262752a8505C6B37;
        assetPrice[1] = 1500 ether;
        assetPrice[2] = 3000 ether;
        assetPrice[3] = 7500 ether;
        assetPrice[4] = 10000 ether;
        assetPrice[5] = 15000 ether;
        assetPrice[6] = 75000 ether;
        assetPrice[7] = 65500 ether;
        assetPrice[8] = 40000 ether;
        assetPrice[9] = 90000 ether;
        assetPrice[10] = 55000 ether;
        assetPrice[11] = 105000 ether;
        assetPrice[12] = 50000 ether;
        assetPrice[13] = 22500 ether;
        assetPrice[14] = 30000 ether;
        assetPrice[15] = 45000 ether;
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
        require(assetPrice[assetType] <= _value);
        IERC20Token token = IERC20Token(tokenAddress);
        require(token.transferFrom(_from, sellingWallet, assetPrice[assetType]), "ERC20 Transfer error");
        IERC721 nft = IERC721(nftAddress);
        uint32 assetDetail = uint32(assetType * 1000000);
        require(nft.mint(_from, uint32(assetType), assetDetail));
        return true;
    }
    
    function setPrice(uint256 _assetId, uint256 _newPrice) public onlyOwner {
        assetPrice[_assetId] = _newPrice;
    }
    
    
    
    
    
    
    
    
    
}