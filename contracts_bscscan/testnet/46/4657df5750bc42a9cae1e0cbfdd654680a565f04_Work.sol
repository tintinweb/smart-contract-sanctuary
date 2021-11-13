pragma solidity ^0.8.0;
import "./MetaFarm.sol";
import "./SafeMath.sol";
import "./seeds.sol";
contract Work{
    using SafeMath for uint256;
    MetaFarm Metafarmer;
    seed _seed;
    address payable admin=payable(msg.sender);
    mapping(uint256=>uint256) Stealtime;
    function addcontract (address payable farm,address payable pet_seed)public{
     require(msg.sender == admin, "only admin can do this");
     Metafarmer=MetaFarm(farm);  
     _seed=seed(pet_seed);
    }
    
    modifier onlyOwnerOf(uint tokenId){ 
    bool isOwner;
    isOwner=Metafarmer._isApprovedOrOwner(msg.sender, tokenId);
    require(isOwner, "ERC721:  is not owner nor approved");
        _;
    }
    //添加种子

    
    //系统出售种子
    event _buyseeds_sys(string seed_name,uint256 amount,uint256 tokenId);
    function buyseeds_sys(uint256 seedId,uint256 amount,uint256 tokenId)public onlyOwnerOf(tokenId) {
    uint256 coins;
    uint256 level;
    address tokenowner=Metafarmer.ownerOf(tokenId);
    (level)=_seed.getseeds(seedId);
    uint256 price=10+2*level*level-3*level;
    (,,,coins,,,)=Metafarmer.MyFramer(tokenId);
    require(coins>=price.mul(amount), "ERC721:  not enough coin");
    _seed.opr_seeds(tokenowner,seedId,amount,1);
    Metafarmer._farmerOprcoin(tokenId,amount.mul(price),0);
    Metafarmer._farmerOprcoin(0,amount.mul(price),1);
    string memory seed_name=_seed.getseeds_name(seedId);
    emit _buyseeds_sys( seed_name, amount, tokenId);
    }
    
    //系统回收种子
    event _sellseeds_sys(string seed_name,uint256 amount,uint256 tokenId);
    function sellseeds_sys(uint256 seedId,uint256 amount,uint256 tokenId)public onlyOwnerOf(tokenId){
   uint256 level;
   (level)=_seed.getseeds(seedId);
    uint256 price=(10+2*level*level-3*level)/5;
    address tokenowner=Metafarmer.ownerOf(tokenId);
    require(_seed.getseedsowner(tokenowner,seedId)>=amount, "ERC721:  not enough seeds");
    _seed.opr_seeds(tokenowner,seedId,amount,0);
    uint256 amountprice=amount.mul(price);
    Metafarmer._farmerOprcoin(tokenId,amountprice.mul(80).div(100),1);
    commissionCoin(tokenId,amountprice);
    string memory seed_name=_seed.getseeds_name(seedId);
    emit _sellseeds_sys(seed_name,amount,tokenId);  //这里显示的是总金额，其中用户获得80%，推荐人获得80%
    }
    
    function getseedlevel(uint256 seedId) internal view returns(uint256){
    uint256 seed_level;
    (seed_level)=_seed.getseeds(seedId);
    return(seed_level);
    }

    
    //耕种
    event _cultivation(uint256 tokenId,uint256 land_index,string seed_name,uint256 seedlevel,uint256 amount,uint256 times);
    function cultivation(uint256 tokenId,uint256 landId,uint256 seedId)public onlyOwnerOf(tokenId){
    address tokenowner=Metafarmer.ownerOf(tokenId);    
    require(_seed.getseedsowner(tokenowner,seedId)>=1, "ERC721:  not enough seeds");
    require(landId<4, "ERC721:  out of landId");
    require(landId>0, "ERC721:  out of landId");
    uint256 times;
    uint256 amount;
    uint256 land_index;
    uint256 farmerlevel;
    uint256 industrious;
    (times,,amount)=Metafarmer.getland(tokenId,landId);
    land_index=Metafarmer.getland_index(tokenId,landId);
    require(times==0, "ERC721:  land on using");
    (,farmerlevel,,,,,)=Metafarmer.MyFramer(tokenId);
    (,,industrious,,,)=Metafarmer.GetFramer_nature(tokenId);
    require(farmerlevel>=getseedlevel(seedId), "ERC721:  out of level");
    //种子收益（小于平均收益的随机数/2+(农民等级-种子等级）*收益平均数/10+勤劳值*收益平均数/(种子等级+农民等级）*10
     amount=uint256(keccak256(abi.encode(tokenowner, tokenId,landId,land_index,block.timestamp,block.number,industrious)))%5+(farmerlevel-getseedlevel(seedId))/2+((industrious/20)+5/(getseedlevel(seedId)+farmerlevel));
    if(amount>=9){
      amount=9;
    }
    
    Metafarmer._farmerOprexp(tokenId,(20*getseedlevel(seedId)-10)*amount,1);
    _seed.opr_seeds(tokenowner,seedId,1,0);
    Metafarmer.cultivation(land_index,80+block.timestamp,seedId,amount);
    string memory seed_name=_seed.getseeds_name(seedId);
    //times=28800;
    times=80;
    emit _cultivation(tokenId,landId,seed_name,getseedlevel(seedId),amount,times);
}

    event _harvest(uint256 tokenId,uint256 landId,string seed_name,uint256 seed_level,uint256 amount);
    function harvest(uint256 tokenId,uint256 landId)public onlyOwnerOf(tokenId){
    uint256 land_index;
    uint256 times;
    uint256 amount;
    uint256 seedid;
    address tokenowner=Metafarmer.ownerOf(tokenId); 
    (times,seedid,amount)=Metafarmer.getland(tokenId,landId);
    land_index=Metafarmer.getland_index(tokenId,landId);
    require(block.timestamp>=times, "ERC721: Not mature yet");
    _seed.opr_seeds(tokenowner,seedid,amount,1);
    Metafarmer.cultivation(land_index,0,0,0);
    string memory seed_name=_seed.getseeds_name(seedid);
    uint256 seed_level=getseedlevel(seedid);
    emit _harvest(tokenId,landId,seed_name,seed_level,amount);
    }
    //推荐人分佣10%
    event _commissionCoin(uint256 tokenId,uint256 inviteTokenId,uint256 amount,string status);
    function commissionCoin(uint256 tokenId,uint256 amount)internal{
       bytes4 My_invite;
       uint256 inviteTokenId;
       uint256 level;
       uint256 invitelevel;
       if(tokenId!=0){
       (,level,,,,My_invite,)=Metafarmer.MyFramer(tokenId);
       inviteTokenId=Metafarmer.z_gettokenID(My_invite); 
        (,invitelevel,,,,My_invite,)=Metafarmer.MyFramer(inviteTokenId);
       if(invitelevel>=level){
       Metafarmer._farmerOprcoin(inviteTokenId,amount.mul(10).div(100),1);
       Metafarmer._farmerOprcoin(0,amount.mul(10).div(100),1);
       emit _commissionCoin(tokenId,inviteTokenId,amount.mul(10).div(100),"succss");
       }
       if(invitelevel<level)
       {Metafarmer._farmerOprcoin(0,amount.mul(20).div(100),1);
       emit _commissionCoin(tokenId,inviteTokenId,amount.mul(10).div(100),"loss level");    
       //因为等级低于被推荐，错失佣金
       }
       
       }

       
    }
       event _commissionBNB(uint256 tokenId,uint256 amount,string status);
       function commissionBNB(uint256 tokenId,uint256 amount)internal{
       bytes4 My_invite;
       address payable invite_address;
       if(tokenId!=0){
       (,,,,,My_invite,)=Metafarmer.MyFramer(tokenId);
       invite_address=Metafarmer.z_getaddre(My_invite);
       admin=Metafarmer.z_getaddre(0x00000000);
       invite_address.transfer(amount.mul(10).div(100));
       admin.transfer(amount.mul(90).div(100));
    }
           if(tokenId==0){
       admin.transfer(amount);
    }
    
       }
    
    
   function BuyPET(uint256 tokenId,string memory _name) public payable onlyOwnerOf(tokenId){
        uint256 pet_level;//宠物等级
        (,pet_level,,,,)=_seed.MyPet(tokenId);
        require(pet_level==0, "You already have pet ");
        uint256 amount=1e17;
       require(msg.value ==amount, "0.1BNB IS REQUIRED");
       commissionBNB(tokenId,amount);
        Buy_PET(tokenId,_name);
        emit _commissionBNB(tokenId, amount.mul(10).div(100),"BuyPET");
        //购买宠物，推荐人获得金额10%推广
    }
    
    function Buy_PET(uint256 tokenId,string memory _name) internal {
        uint256 nowtime;
        nowtime = block.timestamp;//now 
        string memory  pet_name=_name;//宠物名字
        uint256 pet_level;//宠物等级
        uint256 pet_attribute;//宠物战斗力(50-100)
        uint256 pet_exp;//宠物经验
        string memory pet_rarity;//稀有度，普通，精英，传说  （普通<80，精英80-94，传说>=95）
        uint256 pet_growth;//成长值百分比 普通1-10，精英5-10，传说7-10
        pet_level=1;
        pet_exp=0;
        pet_attribute=uint256(keccak256(abi.encode(msg.sender, nowtime,block.number,tokenId,"farmer.pet_attribute")))%51+50;

        if(pet_attribute<=80)
        {
          pet_rarity="Command";
          pet_growth=uint256(keccak256(abi.encode(msg.sender, nowtime,block.number,tokenId,"Command")))%10+1;
        }
                if(pet_attribute<=94 && pet_attribute>80)
        {
          pet_rarity="Elite";
          pet_growth=uint256(keccak256(abi.encode(msg.sender, nowtime,block.number,tokenId,"Elite")))%6+5;
        }
                        if(pet_attribute>95)
        {
          pet_rarity="Legend";
          pet_growth=uint256(keccak256(abi.encode(msg.sender, nowtime,block.number,tokenId,"Legend")))%4+7;
        }
       
        _seed.changePet(tokenId,pet_name,pet_attribute,pet_growth,pet_rarity,pet_exp,pet_level);
         }

 function Employ(bytes4 _invite) public payable  {
        uint256 amount=2e17;
        require(msg.value == amount, "0.2BNB IS REQUIRED");
        address invite_address=Metafarmer.z_getaddre(_invite);
        require(invite_address!=msg.sender, "Can't invite yourself!  you can use inviteCode as '0x00000000' ");
        if(invite_address == address(0))
        {
            _invite=0x00000000;
        }
        Metafarmer.FM_safeMint(_invite,msg.sender);
        uint256 tokenId=Metafarmer.getlasttokenId();
        _seed.addPet(tokenId);
        commissionBNB(tokenId,amount);
        emit _commissionBNB(tokenId, amount.mul(10).div(100),"Employ");
        //雇佣农民，推荐人获得金额10%推广
 }

        function pet_transfer(uint256 from, uint256 to)public  onlyOwnerOf(from){
        _seed.PetTransfer(from,to); 
}

        function Set_FramerPetName(uint256 tokenId,string memory _petname) public onlyOwnerOf(tokenId){
        _seed.Set_FramerPetName(tokenId,_petname);    
        }
        function BurnPET (uint256 tokenId)public onlyOwnerOf(tokenId){
        _seed.BurnPET (tokenId);    
        }
        
        function PetUpLevel(uint256 tokenId)public onlyOwnerOf(tokenId){
         uint256 farmerlevel;
         uint256 petlevel;
         (,farmerlevel,,,,,)=Metafarmer.MyFramer(tokenId); 
         (,petlevel,,,,)=_seed.MyPet(tokenId);
         require(farmerlevel>petlevel, "Petlevel cannot be greater than farmerlevel");
         _seed._PetLevelUP(tokenId);   
        }
        
        function Set_FramerName(uint256 tokenId,string memory _petname) public onlyOwnerOf(tokenId){
        Metafarmer.Set_FramerName(tokenId,_petname);    
        }
        
        function FarmerUpLevel(uint256 tokenId)public onlyOwnerOf(tokenId){
         Metafarmer._farmerLevelUP(tokenId);   
        }
        
        function Farmer_transfer(address from,address to,uint256 tokenId)public  onlyOwnerOf(tokenId){
        Metafarmer.transferFrom( from, to, tokenId);
}

}