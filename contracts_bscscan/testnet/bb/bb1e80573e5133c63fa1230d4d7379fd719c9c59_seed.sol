pragma solidity ^0.8.0;
import "./SafeMath.sol";

// PXA实现
contract seed{
    using SafeMath for uint256;
    address[] work;
    address payable admin=payable(msg.sender);
    string[]  seeds_name;//种子名字
    uint256[][] seeds;//种子属性列表
    mapping(string=>uint256) seeds_index;//种子索引
    //种子拥有者（地址-种子索引-种子数量）
    mapping(address=>mapping(uint256=>uint256)) seedowner;
    mapping(uint256=>uint256) pet_index;  //tokenId=>petId;
    uint256[]  PETlevels;
        struct _pet{
        string  pet_name;//宠物名字
        uint256 pet_level;//宠物等级
        uint256 pet_attribute;//宠物战斗力(50-100)
        uint256 pet_exp;//宠物经验
        string pet_rarity;//稀有度，普通，精英，传说  （普通<80，精英80-94，传说>=95）
        uint256 pet_growth;//成长值百分比 普通1-10，精英5-10，传说7-10
    }


    _pet[] pet;



    //添加工作合约
    function addwork(address _work)public{
        require(msg.sender == admin, "only admin can do this");
        work.push(_work);
    }
    //修改工作合约，弃用合约地址改为0
    function oprwork(uint256 _work_index,address _work)public{
        require(msg.sender == admin, "only admin can do this");
        work[_work_index]=_work;
    }

function checkwork(address _work)public view returns(bool)
{
  uint256 i=work.length;
  for(i=0;i<work.length;i++)
 {
     if(_work==work[i]){
         return(true);
     }
 }
    return(false);
}
        function getwork(uint256 _work_index)public view returns(address _work){
        require(msg.sender == admin, "only admin can do this");
        return(work[_work_index]);
    }
    function addSeed(string memory seed_name,uint256 seed_level)public{
    require(msg.sender == admin, "only admin can do this");
    seeds_name.push(seed_name);
    seeds_index[seed_name]=seeds_name.length-1;
    seeds.push([seed_level]);
    }
    //获取种子信息
    function getseeds(uint256 _seeds_index) external view returns(uint256){
    return(seeds[_seeds_index][0]);
    }
    //获取种子索引
    function getseeds_index(string memory _name) public view returns(uint256){
        return(seeds_index[_name]);
    }
    //更新种子信息
    function oprseeds(uint256 _seeds_index,uint256 seed_level)public{
        require(msg.sender == admin, "only admin can do this");
        seeds[_seeds_index][0]=seed_level;
    }
    //种子改名
    function remseeds(string memory _name1,string memory _rename)public{
       require(msg.sender == admin, "only admin can do this");
        seeds_index[_rename]=getseeds_index(_name1);
    }
    //种子操作，传入拥有者地址，1+0-
    event _opr_seeds (address addr,string seeds_name,uint256 amount,string opr);
    function opr_seeds(address addr,uint256 seeds_Index,uint256 amount,uint256 opr)public {
        require(checkwork(msg.sender), "ERC721: operator not allowed");
        string memory _opr;
        if(opr==1)
        {seedowner[addr][seeds_Index]=seedowner[addr][seeds_Index].add(amount);
        _opr="add";
        }
        if(opr==0)
        {
        seedowner[addr][seeds_Index]=seedowner[addr][seeds_Index].sub(amount);
        _opr="sub";
        }
        string memory seeds_Name;
       seeds_Name=getseeds_name(seeds_Index);
       emit _opr_seeds (addr,seeds_Name,amount,_opr);
    }
    function getseedsowner(address addr,uint256 seeds_Index)public view returns(uint256){
        return(seedowner[addr][seeds_Index]) ;
    }
        //设置宠物名字
    function Set_FramerPetName(uint256 tokenId,string memory _petname) public {
        require(checkwork(msg.sender), "ERC721: operator not allowed");
        _pet storage mypet = pet[pet_index[tokenId]];
        mypet.pet_name=_petname;
    }
    event _BurnPET(uint256 tokenId);
    function BurnPET (uint256 tokenId) public{
        require(checkwork(msg.sender), "ERC721: operator not allowed");
        _pet storage mypet = pet[pet_index[tokenId]];
        require(mypet.pet_level!=0, "You don't have pet");
            mypet.pet_level=0;
            mypet.pet_exp=0;
            mypet.pet_attribute=0;
            mypet.pet_rarity="NULL";
            mypet.pet_growth=0;
            emit _BurnPET(tokenId);
    }

           //转移宠物
        event _PetTransfer (uint256 From,uint256 To,string _name,uint256 level,string rarity);
        function PetTransfer (uint256 From,uint256 To) public  {
        require(checkwork(msg.sender), "ERC721: operator not allowed");
        _pet storage _from = pet[pet_index[From]];
        _pet storage _to = pet[pet_index[To]];
        require(_from.pet_level!=0, "You don't have pet ");
        require(_to.pet_level==0, "You already have pet ");

        _to.pet_name=_from.pet_name;
        _to.pet_level=_from.pet_level;
        _to.pet_attribute=_from.pet_attribute;
        _to.pet_exp=_from.pet_exp;
        _to.pet_rarity=_from.pet_rarity;
        _to.pet_growth=_from.pet_growth;

        _from.pet_name="MetaDoge";
        _from.pet_level=0;
        _from.pet_attribute=0;
        _from.pet_exp=0;
        _from.pet_rarity="null";
        _from.pet_growth=0;
        emit _PetTransfer (From,To,_to.pet_name,_to.pet_level,_to.pet_rarity);

      }
      function changePet(uint256 tokenId,string memory _name,uint256 attribute,uint256 growth,string memory rarity,uint256 exp,uint256 level) public{
        require(checkwork(msg.sender), "ERC721: operator not allowed");
        _pet storage _from = pet[pet_index[tokenId]];
         _from.pet_name=_name;
        _from.pet_level=level;
        _from.pet_attribute=attribute;
        _from.pet_exp=exp;
        _from.pet_rarity=rarity;
        _from.pet_growth=growth;
      }
        function addPetexp(uint256 tokenId,uint256 exp) public{
        require(checkwork(msg.sender), "ERC721: operator not allowed");
        _pet storage _from = pet[pet_index[tokenId]];
        _from.pet_exp=_from.pet_exp+exp;
      }

        function MyPet(uint256 tokenId)public view returns (string memory pet_name,uint256 pet_level,uint256 pet_attribute,uint256 pet_exp,string memory pet_rarity,uint256 pet_growth){
        _pet storage Mypet = pet[pet_index[tokenId]];
        return(Mypet.pet_name,Mypet.pet_level,Mypet.pet_attribute,Mypet.pet_exp,Mypet.pet_rarity,Mypet.pet_growth);}

        function addPet(uint256 tokenId)public{
        require(checkwork(msg.sender), "ERC721: operator not allowed");
         pet.push();
         pet_index[tokenId]=pet.length-1;
         _pet storage mypet = pet[pet_index[tokenId]];
        mypet.pet_name="MetaDoge";
        mypet.pet_level=0;
        mypet.pet_attribute=0;
        mypet.pet_exp=0;
        mypet.pet_rarity="null";
        mypet.pet_growth=0;
        }

        function getpet_index(uint256 tokenId)public view returns(uint256){
            return(pet_index[tokenId]);
        }

        function getseeds_name(uint256 seeds_Index) public view returns(string memory){
          return(seeds_name[seeds_Index]);
        }

event _Pet_LevelUP(uint256 tokenId,string pet_name,uint256 level,uint256 uplevel);
    //升级
    function _PetLevelUP(uint256 tokenId)public{
      require(checkwork(msg.sender), "ERC721: operator not allowed");
      _pet storage mypet = pet[pet_index[tokenId]];
      uint256 mypet_upexp=60*(mypet.pet_level+1)*(mypet.pet_level+1)-60*(mypet.pet_level+1)+15;
      require(mypet.pet_exp >= mypet_upexp, "not enough exp");
      mypet.pet_level=mypet.pet_level+1;
      mypet.pet_exp=mypet.pet_exp.sub(mypet_upexp);
      mypet.pet_attribute=mypet.pet_attribute.add(mypet.pet_growth);
    emit _Pet_LevelUP(tokenId,mypet.pet_name,mypet.pet_level-1,mypet.pet_level);
    }


      }