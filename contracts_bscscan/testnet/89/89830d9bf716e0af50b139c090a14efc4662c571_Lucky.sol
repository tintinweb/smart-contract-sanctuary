// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./IAttr.sol";

// value
struct LuckyType{
    uint256 minRange;
    uint256 maxRange;
    uint256 typeId;
}


struct IndexValue { uint keyIndex; LuckyType value; }

struct KeyFlag { uint key; bool deleted; }

struct itmap {
    mapping(uint => IndexValue) data;
    KeyFlag[] keys;
    uint size;
}

library IterableMapping {
    function insert(itmap storage self, uint key, LuckyType memory value) internal returns (uint keyIndex, bool replaced) {
        keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0)
            replaced = true;
        else {
            keyIndex = self.keys.length;
            self.keys.push();
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            replaced = false;
        }
    }

    function remove_by_dict_key(itmap storage self, uint key) internal returns (bool success) {
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0)
            return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }

    function contains(itmap storage self, uint key) internal view returns (bool) {
        return self.data[key].keyIndex > 0;
    }

    function iterate_start(itmap storage self) internal view returns (uint keyIndex) {
        return iterate_next(self, 10000000);
    }

    function iterate_valid(itmap storage self, uint keyIndex) internal view returns (bool) {
        return keyIndex < self.keys.length;
    }

    function iterate_next(itmap storage self, uint keyIndex) internal view returns (uint r_keyIndex) {
        keyIndex++;
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return keyIndex;
    }

    function iterate_get_by_array_key(itmap storage self, uint keyIndex) internal view returns (uint key, LuckyType memory value) {
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }
    
    function iterate_get_by_dict_key(itmap storage self, uint k) internal view returns (uint key, LuckyType memory value) {
        value = self.data[k].value;
        key = self.data[k].keyIndex;
    }
}


/*
1. 开启use
2. 设置抽卡代币
3. 设置抽卡价格
4. 设置属性合约
5. 设置nft合约，nft合约同步设置抽卡合约
*/
contract Lucky is Ownable, Context, Attr {

   
  constructor() {
      mktAddress = _msgSender();
  }

  modifier onlyUse()
  {
    require(use, "contract not use!");
    _;
  }
  
  bool public use;
  
  function setUse(bool status)public onlyOwner{
      use = status;
  }
  
  IERC721 public nftAddress;
      
  function setNftAddress(address nft) public onlyOwner{
    require(nft != address(nftAddress), "nft address Currently in use!");
    nftAddress = IERC721(nft);
  }
  
  address public mktAddress;
  
  function setMktAddress(address mktAddr) public onlyOwner{
    require(mktAddr != address(mktAddress), "mktAddress address Currently in use!");
    mktAddress = mktAddr;
  }
  
  IERC20  public tokenAddress;
  uint256 public luckyPrice;
  
  function setLuckPrice(uint256 price) public onlyOwner{
    require(price > 100, "price must be gt 100!");
    luckyPrice = price;
  }
  
  function setTokenAddress(address token) public onlyOwner{
    require(token != address(tokenAddress), "token address Currently in use!");
    tokenAddress = IERC20(token);
  }
  
  function tokenAddressTransFrom() internal{
    if (address(tokenAddress) != address(0)){
        // token
        IERC20(tokenAddress).transferFrom(_msgSender(), mktAddress, luckyPrice);
    }else{
        // eth
        require(msg.value == luckyPrice, "msg.value Too little");
        payable(mktAddress).transfer(address(this).balance);
    }
  }
  
  itmap LuckyTypeMap;
  using IterableMapping for itmap;
    
  function getLuckyTypeMapByDictKey(uint key)public view returns(LuckyType memory value) {
    (, value) =  LuckyTypeMap.iterate_get_by_dict_key(key);
  }
  function getLuckyTypeMapByArrayKey(uint key)public view returns(LuckyType memory value) {
        (, value) =  LuckyTypeMap.iterate_get_by_array_key(key);
    }
  
  function addLuckyTypeMap(uint256 key, LuckyType memory template)public onlyOwner returns(uint, bool flag){
        return LuckyTypeMap.insert(key, template);
  }
  
  function DelLuckyTypeeMap(uint key)public onlyOwner returns(bool) {
        return LuckyTypeMap.remove_by_dict_key(key);
    }
  
  LuckyType[] public allTemplateList;
  function userGetAllLuckTypeMap()  public view returns(LuckyType[] memory){
    return allTemplateList;
  }
  
  function getAllLuckTypeMap()  public onlyOwner returns(LuckyType[] memory){
    delete allTemplateList;
    for(uint i = 0;i < LuckyTypeMap.keys.length; i++) {
            if (LuckyTypeMap.keys[i].deleted){
                continue;
            }
            ( ,LuckyType memory value) = LuckyTypeMap.iterate_get_by_array_key(i);
            allTemplateList.push(value);
        }
    return allTemplateList;
  }
  
  function rand(uint256 _length) internal view returns(uint256) {
    uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    return random%_length;
  }
  
  address public attrAddress;
  function setAttrAddress(address addr)public onlyOwner{
      require(attrAddress != address(addr), "address There is no change");
      attrAddress = addr;
  }
  
  event LuckyDog(address, uint256);
  
  function lucky() public payable onlyUse returns(NftInfo memory info , uint256 randomNum) {
      tokenAddressTransFrom();
      
      randomNum = rand(1000);

      uint256 typeId = 0;
      for(uint i = 0;i < LuckyTypeMap.keys.length; i++) {
            if (LuckyTypeMap.keys[i].deleted){
                continue;
            }
            ( ,LuckyType memory value) = LuckyTypeMap.iterate_get_by_array_key(i);
            if(randomNum >= value.minRange && randomNum <= value.maxRange){
                typeId = value.typeId;
                break;
            }
        }
      
      // 寻找attr合约生成卡牌对应详细属性
      info = nftAttrAddress.genearteNftInfo(typeId);  
      nftAddress.mint(_msgSender(), info.tokenId, info.uri);
      emit LuckyDog(_msgSender(), typeId);
  }
  
  receive()payable external{}
  function OwnerSafeWithdrawalEth(uint256 amount) public onlyOwner{
        if (amount == 0){
            payable(owner).transfer(address(this).balance);
            return;
        }
        payable(owner).transfer(amount);
    }

  function OwnerSafeWithdrawalToken(address token_address, uint256 amount) public onlyOwner{
        IERC20 token_t = IERC20(token_address);
        if (amount == 0){
            token_t.transfer(owner, token_t.balanceOf(address(this)));
            return;
        }
        token_t.transfer(owner, amount);
    }
  
}