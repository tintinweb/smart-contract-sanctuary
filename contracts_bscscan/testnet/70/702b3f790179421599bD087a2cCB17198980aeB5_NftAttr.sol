// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";

struct LuckNftInfoTemplate {
    uint256 id;
    string uri;
    uint256 typeId;
    uint16 minCe;
    uint16 maxCe;
    uint16 minAtk;
    uint16 maxAtk;
    uint16 minHp;
    uint16 maxHp;
    uint16 cp;
    uint16 fatigue;
    string name;
    uint16 campId;
}

struct NftInfo{
     string uri;  // 图片
     uint256 tokenId; // 对应nft id
     uint256 templateId; // 对应模版id
     uint256 typeId;  // 对应稀有度id
     uint16 atk; // 攻击力
     uint16 ce;  // 战斗力
     uint16 cp;  // 算力
     uint16 hp;  // 血量
     uint16 fatigue; // 疲劳度
     string name; // 名称
     uint16 campId; // 阵营id
     uint16 level; // 等级
}

interface INftContract {
    function tokenOfOwnerGet(address _owner) external view returns (uint256[] memory);
}

contract NftAttr is Ownable, Context {
 
 constructor() {
    updateAdminAddress(_msgSender(), true);
  }
  
  address nftContractAddr;
  INftContract nftContract;
  
  function updateNftContract(address addr) public onlyOwner(){
      nftContractAddr = addr;
      nftContract = INftContract(addr);
  }
  

  // typeId => LuckNftInfoTemplate[]
  mapping(uint256 => LuckNftInfoTemplate[]) LuckyNftInfoTypeIdMap;
  
  // 获取所有卡牌模版列表
  function getAllLuckyNftInfoTypeIdMap(uint256 typeId)public view returns(LuckNftInfoTemplate[] memory){
      return LuckyNftInfoTypeIdMap[typeId];
  }
  
  // 根据模版id获取所有卡牌模版列表
  function getAllLuckyNftInfoTypeIdMapById(uint256 typeId, uint256 templateId)public view returns(LuckNftInfoTemplate memory res){
      LuckNftInfoTemplate[] memory array = LuckyNftInfoTypeIdMap[typeId];
      for(uint i = 0;i < array.length; i++) {
          LuckNftInfoTemplate memory template = array[i];
          if(template.id == templateId){
              return template;
          }
        }
  }
  
  // 新增卡牌模版
  function addLuckyNftInfoTypeIdMap(uint256 typeId, LuckNftInfoTemplate memory template) public onlyOwner{
      LuckyNftInfoTypeIdMap[typeId].push(template);
  }
  
  // 根据模版id修改卡牌模版
  function updateLuckyNftInfoTypeIdMapById(uint256 typeId, uint256 templateId, LuckNftInfoTemplate memory newTemplate) public onlyOwner returns(bool flag){
      flag = false;
      for(uint i = 0;i < NftInfoTemplateIdMap[typeId].length; i++) {
           LuckNftInfoTemplate memory template = LuckyNftInfoTypeIdMap[typeId][i];
          if(template.id == templateId){
              LuckyNftInfoTypeIdMap[typeId][i] = newTemplate;
              flag = true;
          }
        }
        require(flag, "flag must be true!");
  }
  
  // 根据模版id删除卡牌模版
  function delLuckyNftInfoTypeIdMap(uint256 typeId, uint256 templateId) public onlyOwner{
      LuckNftInfoTemplate[] memory array = LuckyNftInfoTypeIdMap[typeId];
      
      uint256 index = 0;
      bool flag;
      for(uint i = 0;i < array.length; i++) {
          LuckNftInfoTemplate memory template = array[i];
          if(template.id == templateId){
              index = i;
              flag = true;
              break;
          }
        }
        if (!flag){return;}
        
      uint256 lastTokenIndex = array.length - 1;
      LuckNftInfoTemplate memory lastToken = LuckyNftInfoTypeIdMap[typeId][lastTokenIndex];
      LuckyNftInfoTypeIdMap[typeId][index] = lastToken;
      LuckyNftInfoTypeIdMap[typeId].pop();
  }
  
  function rand(uint256 _length) internal view returns(uint256) {
    uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    return random%_length;
  }
  
  mapping(address => bool) public adminAddress;

  modifier onlyOwnerOrAdminAddress()
  {
    require(adminAddress[_msgSender()], "permission denied");
    _;
  }
  function updateAdminAddress(address newAddress, bool flag) public onlyOwner {
    require(adminAddress[newAddress] != flag, "The adminAddress already has that address");
    adminAddress[newAddress] = flag;
  }
  
  /* NftInfoMap = {
        # 结构体
        "tokenId": {
            "score": 123,
            "fighting": 100,
            "camp": "123",
            "name": "2123",
            'templateId': 1
        }
    }
  */
  mapping(uint256 => NftInfo) public NftInfoMap;
  // 根据卡牌id查询卡牌属性
  function getNftInfoMap(uint256 tokenId) public view returns(NftInfo memory) {
    return NftInfoMap[tokenId];
  }
  
  // 根据卡牌id修改某个具体卡牌属性
  function updateNftInfoMap(uint256 tokenId, NftInfo memory info) public onlyOwnerOrAdminAddress returns(NftInfo memory) {
    NftInfoMap[tokenId] = info;
    return info;
  }

  // 删除卡牌属性并且移除对应的模版集合
  function delNftInfo(uint256 tokenId) external onlyOwnerOrAdminAddress{
      delNftInfoTemplateIdMap(tokenId);
      delete NftInfoMap[tokenId];
  }
  
  /* {
        "templateId": [tokenId, tokenId, tokenId]
    }
    当前每种模版所生成出来的卡牌id集合
  */
  mapping(uint256 => uint256[]) public NftInfoTemplateIdMap;
  function addNftInfoTemplateIdMap(uint256 templateId, uint256 tokenId) public onlyOwnerOrAdminAddress {
     NftInfoTemplateIdMap[templateId].push(tokenId);
  }

  function getNftInfoTemplateIdLength(uint256 templateId) public view returns(uint){
    return NftInfoTemplateIdMap[templateId].length;
  }

  function getNftInfoTemplateIds(uint256 templateId) public view returns(uint[] memory){
    return NftInfoTemplateIdMap[templateId];
  }
  
  uint256 public nowId;
  
  function updateNowId() public onlyOwnerOrAdminAddress{
    nowId = nowId + 1;
  }

  // 根据卡牌id移除出对应的模版集合
  function delNftInfoTemplateIdMap(uint256 tokenId) internal{
      NftInfo memory info = NftInfoMap[tokenId];
      
      uint256 index;
      bool flag;
      for(uint i = 0;i < NftInfoTemplateIdMap[info.templateId].length; i++) {
          uint256 templateId = NftInfoTemplateIdMap[info.templateId][i];
          if(templateId == tokenId){
              index = i;
              break;
          }
      }
      
      if(!flag){return;}
      uint256 lastTokenIndex = NftInfoTemplateIdMap[info.templateId].length - 1;
      uint256 lastTokenId = NftInfoTemplateIdMap[info.templateId][lastTokenIndex];
      NftInfoTemplateIdMap[info.templateId][index] = lastTokenId;
      NftInfoTemplateIdMap[info.templateId].pop();      
        
  }

  // 通过模版生成对应的nft信息
  function _generateNftInfo(uint256 tokenId, LuckNftInfoTemplate memory template) public onlyOwnerOrAdminAddress {
      uint16 random = uint16(rand(10000));
      uint16 atk = template.minAtk + (random % (template.maxAtk - template.minAtk));
      uint16 ce = template.minCe + (random % (template.maxCe - template.minCe));
      uint16 hp = template.minHp + (random % (template.maxHp - template.minHp));

      NftInfo memory info = NftInfo({
        uri: template.uri,
        templateId: template.id,
        tokenId: tokenId,
        typeId: template.typeId,
        fatigue: template.fatigue,
        cp: template.cp,
        atk: atk,
        ce: ce,
        hp: hp,
        campId: template.campId,
        name: template.name,
        level: 1
      });

      updateNftInfoMap(tokenId, info);
  }
  
  // 生成卡牌属性
  function genearteNftInfo(uint256 typeId) external  onlyOwnerOrAdminAddress returns(NftInfo memory){
      updateNowId();
      uint256 tokenId = nowId;
      uint256 randomNum = rand(1000);
      uint256 length = LuckyNftInfoTypeIdMap[typeId].length;
      LuckNftInfoTemplate memory NftInfoTemplate =  getAllLuckyNftInfoTypeIdMap(typeId)[randomNum % length];
      _generateNftInfo(tokenId, NftInfoTemplate);
      addNftInfoTemplateIdMap(NftInfoTemplate.id, tokenId);
      return NftInfoMap[tokenId];
  }

  // 固定生成卡牌属性
  function genearteFixedNftInfo(uint256 typeId, uint256 templateId) external  onlyOwnerOrAdminAddress returns(NftInfo memory){
      updateNowId();
      uint256 tokenId = nowId;
      LuckNftInfoTemplate memory NftInfoTemplate =  getAllLuckyNftInfoTypeIdMapById(typeId, templateId);
      _generateNftInfo(tokenId, NftInfoTemplate);
      addNftInfoTemplateIdMap(NftInfoTemplate.id, tokenId);
      return NftInfoMap[tokenId];
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
    
   function tokenOfOwnerGetAndInfo(address _owner) public view returns (NftInfo[] memory){
      uint256[] memory tokenIds = nftContract.tokenOfOwnerGet(_owner);
      NftInfo[] memory arr = new NftInfo[](tokenIds.length);
      for(uint256 i = 0; i < tokenIds.length; i++) {
          arr[i] = NftInfoMap[tokenIds[i]];
      }
      return arr;
   }
}