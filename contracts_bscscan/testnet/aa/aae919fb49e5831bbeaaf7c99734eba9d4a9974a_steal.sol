pragma solidity ^0.8.0;
import "./MetaFarm.sol";
import "./SafeMath.sol";
import "./seeds.sol";
import "./work.sol";
contract steal{
    using SafeMath for uint256;
    MetaFarm Metafarmer;
    seed _seed;
    Work _work;
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

    function Steal(uint256 farmer,uint256 Stealer,uint256 landId)public onlyOwnerOf(Stealer){
             require(block.timestamp>=Stealtime[Stealer]+10, "Less than half an hour");
             //+1800
             Stealtime[Stealer]=block.timestamp;
             uint256 times;
             uint256 amount;
             uint256 seedid;

             (times,seedid,amount)=Metafarmer.getland(farmer,landId);
            require(amount>=2, "no seeds to steal");
            require(block.timestamp>=times, "ERC721: Not mature yet");
            uint256 fromlevel;
            uint256 tolevel;
            uint256 tocoins;
            (,fromlevel,,,,,)=Metafarmer.MyFramer(farmer);
            (,tolevel,,tocoins,,,)=Metafarmer.MyFramer(Stealer);
            require(tolevel>=fromlevel, "The level cannot be lower than the other");
            uint256 level;
            (level)=_seed.getseeds(seedid);
            uint256 seed_price=1+(10+2*level*level-3*level)/5;
            require(tocoins>=seed_price, "ERC721: Insufficient funds");
            uint256 exp=20*level-10;
            _Steal( farmer, Stealer, landId, seed_price,seedid,exp);
        }

            function _Steal(uint256 from,uint256 to,uint256 landId,uint256 seed_price,uint256 seedid,uint256 exp)internal {
            uint256 fromwisdom;
            uint256 tocourage;
            uint256 frompet;
            uint256 topet;
            (,fromwisdom,,,,)=Metafarmer.GetFramer_nature(from);
            (,,,tocourage,,)=Metafarmer.GetFramer_nature(to);
            (,,frompet,,,)=_seed.MyPet(from);
            (,,topet,,,)=_seed.MyPet(to);
            uint256 st_defense=fromwisdom+frompet+uint256(keccak256(abi.encode(from, fromwisdom,Stealtime[from])))%100;
            uint256 st_steal=tocourage+topet+uint256(keccak256(abi.encode(to, fromwisdom,Stealtime[to])))%100;
            string memory status;
            if(st_defense>=st_steal){
             defense(from,to,seed_price,seedid,exp);

            }
            else{
             _Stealsuscss(from,to,landId,seedid,exp);

            }

        }
        event _Stealstatus(uint256 st_defense,uint256 st_steal,string status);
        event Stealstatus(uint256 from,uint256 to,string name,uint256 coin,uint256 seedamount,uint256 exp,string status);
        function defense(uint256 from,uint256 to,uint256 seed_price,uint256 seedid,uint256 exp)internal{
         Metafarmer._farmerOprcoin(to,seed_price,0);
         Metafarmer._farmerOprcoin(from,seed_price.mul(80).div(100),1);
        uint256 pet_exp=0;
        uint256 pet_level;
        (,pet_level,,,,)=_seed.MyPet(from);
        if(pet_level>0){pet_exp=exp;}
         string memory seed_name=_seed.getseeds_name(seedid);
         _seed.addPetexp(from,pet_exp);
         commissionCoin(from,seed_price);
         emit Stealstatus( from, to,seed_name,seed_price,0,pet_exp,"defense success");
        }
        function _Stealsuscss(uint256 from,uint256 to,uint256 landId,uint256 seedid,uint256 exp)internal{
        uint256 pet_exp=0;
        uint256 pet_level;
        (,pet_level,,,,)=_seed.MyPet(to);
        if(pet_level>0){pet_exp=exp;}
        _seed.addPetexp(to,pet_exp);
        _seed.opr_seeds(Metafarmer.ownerOf(to),seedid,1,1);
        uint256 amount;
        uint256 times;
        (times,,amount)=Metafarmer.getland(from,landId);
         Metafarmer.cultivation(Metafarmer.getland_index(from,landId),times,seedid,amount-1);
         string memory seed_name=_seed.getseeds_name(seedid);
        emit Stealstatus( from, to,seed_name,0,1,pet_exp,"Steal success");
        }
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
}