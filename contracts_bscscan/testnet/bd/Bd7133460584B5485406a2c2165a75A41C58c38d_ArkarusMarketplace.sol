// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./IArkarusNFT.sol";

contract ArkarusMarketplace is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    string private baseTokenURI;
    address private marketWalletAddress;
    address private companyWalletAddress;
    address private aksAddress;
    address private aksNftAddress;

    struct orderItems {
        address sellerAddress;
        uint price; 
        bool available;
    }
    
    uint8 constant ROBOT = 1;
    
    mapping(uint256 => orderItems) public sellItems;
    
    event eventSellRobotOrder(uint tokenID, uint price);
    event eventCancelRobotOrder(uint tokenID);
    event eventBuyRobotOrder(uint tokenID, address buyer, uint price);
    event eventDeleteSellItems(uint tokenID);
    event eventCompareAddresses(address recorded, address current);
    
    Counters.Counter private _tokenIdCounter;

    function setMarketWalletAddress(address _marketWalletAddress) public onlyOwner {
        marketWalletAddress = _marketWalletAddress;
    }

    function setCompanyWalletAddress(address _companyWalletAddress) public onlyOwner {
        companyWalletAddress = _companyWalletAddress;
    }

    function placeRobotOrder(uint256 _tokenID, uint256 _price) public
    {
        IERC721 arkarusNFT = IERC721(aksNftAddress);
        require(msg.sender == arkarusNFT.ownerOf(_tokenID), "You are not the owner of this robot");
        require(msg.sender != sellItems[_tokenID].sellerAddress, "You already placed an order for this robot");
        
        IArkarusNFT IarkarusNFT = IArkarusNFT(aksNftAddress);
        require(IarkarusNFT.tokenType(_tokenID) == ROBOT, "Invalid token type");
        
        sellItems[_tokenID].sellerAddress = msg.sender;
        sellItems[_tokenID].price = _price;
        sellItems[_tokenID].available = true;
        
        emit eventSellRobotOrder(_tokenID, sellItems[_tokenID].price);
    }
    
    function cancelOrder(uint _tokenID) public {
        require(msg.sender == sellItems[_tokenID].sellerAddress, "You are not the owner of this robot");
        delete sellItems[_tokenID];
        
        emit eventCancelRobotOrder(_tokenID);
    }
    
    function setArkarusAddress(address newAksAddress) public onlyOwner
    {
        aksAddress = newAksAddress;
    }
    
    function setArkarusNftAddress(address newAksNftAddress) public onlyOwner
    {
        aksNftAddress = newAksNftAddress;
    }
    
    function buy(uint256 _tokenID) public
    {
        IERC20 AKStoken = IERC20(aksAddress);
        IERC721 AKSNFTtoken = IERC721(aksNftAddress);
        require(AKStoken.balanceOf(msg.sender) >= sellItems[_tokenID].price, "Your balance is insufficient.");
        AKStoken.transferFrom(msg.sender, AKSNFTtoken.ownerOf(_tokenID), calculationFee(sellItems[_tokenID].price, 95395));
        AKStoken.transferFrom(msg.sender, marketWalletAddress, calculationFee(sellItems[_tokenID].price, 4105));
        AKStoken.transferFrom(msg.sender, companyWalletAddress, calculationFee(sellItems[_tokenID].price, 500));
        AKSNFTtoken.transferFrom(AKSNFTtoken.ownerOf(_tokenID), msg.sender, _tokenID);
        
        emit eventBuyRobotOrder(_tokenID, msg.sender, sellItems[_tokenID].price);
        delete sellItems[_tokenID];
    }

    function checkSellItemOwner(uint256 _tokenID) view public onlyOwner returns (bool)
    {
        IERC721 AKSNFTtoken = IERC721(aksNftAddress);
        address recordedOwner = sellItems[_tokenID].sellerAddress;
        address currentOwner = AKSNFTtoken.ownerOf(_tokenID);
        if (recordedOwner != currentOwner){
            return false;
        }
        return true;
    }

    function deleteSellItems(uint256 _tokenID) public onlyOwner
    {
        delete sellItems[_tokenID];
        emit eventDeleteSellItems(_tokenID);
    }
    
    function calculationFee(uint amount, uint percentx1000) pure internal returns(uint)
    {
        return (amount.div(100000)).mul(percentx1000);
    }
}