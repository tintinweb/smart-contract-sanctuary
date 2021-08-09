// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../Ownable.sol";
import "../Address.sol";

contract BuyKFAN is Ownable{
    
    event PriceUpdated(uint256 indexed newPrice);
    event WalletUpdated(address indexed newWallet);
    event KFANBought(address indexed buyer, uint256 indexed maticSpent, uint256 indexed kfanReceived);
    
    IERC20 public token;
    uint256 private _priceInWei; // MATIC per KFAN
    address payable public ownerWallet;
    
    
    constructor(address tokenAddress_, uint256 priceInWei_, address payable ownerWallet_) 
    Ownable() 
    {
        token = IERC20(tokenAddress_);
        _priceInWei = priceInWei_;
        ownerWallet = ownerWallet_;
    }
    
    function setPrice(uint256 newPrice)
    public onlyOwner
    {
        _priceInWei = newPrice;
        emit PriceUpdated(newPrice);
    }
    
    function setWallet(address payable newWallet)
    public onlyOwner
    {
        ownerWallet = newWallet;
        emit WalletUpdated(newWallet);
    }
    
    function _maticToKfanConverter(uint256 maticAmount)
    internal view returns (uint256)
    {
        return maticAmount * 1e18 / _priceInWei;
    }
    
    function getPrice()
    public view returns (string memory)
    {
        uint256 currentPrice = _priceInWei;
        uint256 front = currentPrice / 1e18;
        uint256 back = currentPrice - (front * 1e18);
        return string(abi.encodePacked("1 KFAN costs ", uint2str(front), ".", uint2str(back), " MATIC."));
    }
    
    function _forwardMatic()
    internal
    {
        Address.sendValue(ownerWallet, address(this).balance);
    }
    
    function buyKFAN()
    external payable
    {
        require(!Address.isContract(msg.sender), "Sorry, only EOA, or non-contract accounts, can buy from this contract.");
        require(msg.sender != address(0), "Cannot purchase from the 0 address.");
        require(msg.value != 0, "No value sent.");
        
        uint256 tokensToReceive = _maticToKfanConverter(msg.value);
        
        token.transfer(msg.sender, tokensToReceive);
        
        emit KFANBought(msg.sender, msg.value, tokensToReceive);
        
        _forwardMatic();
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}