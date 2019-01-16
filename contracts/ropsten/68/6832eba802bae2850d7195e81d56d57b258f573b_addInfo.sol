pragma solidity ^0.4.22;
contract addInfo {
     //tokenid属性 
  struct ShopInfo {
      uint256 tokenId;//tokenId
      string holderName;//持有人姓名 
      string remarkOne;//备注1 
      string remarkTwo;//备注2
  }
  mapping(uint256 =>ShopInfo) shopInfoToken;
  uint256[] shopInfos;
  
   /**
   *添加tokenId属性  
   */
  function addshop(uint256 _tokenId,string _holderName,string _remarkOne,string _remarkTwo) public{
      shopInfoToken[_tokenId].tokenId = _tokenId;
      shopInfoToken[_tokenId].holderName = _holderName;
      shopInfoToken[_tokenId].remarkOne = _remarkOne;
      shopInfoToken[_tokenId].remarkTwo = _remarkTwo;
      shopInfos.push(_tokenId);
  }
  
  /**
    * 返回 tokenId属性 
   */
    function getShop(uint256 _tokenId)public view returns(uint256 tokenId,string holderName,
    string remarkOne,string remarkTwo){
                
         ShopInfo memory shopInfo = shopInfoToken[_tokenId];
        
        return (shopInfo.tokenId,shopInfo.holderName,shopInfo.remarkOne,shopInfo.remarkTwo);
    }
  
}