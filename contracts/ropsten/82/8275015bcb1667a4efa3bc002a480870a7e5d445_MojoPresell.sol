pragma solidity ^0.4.23;
/*
    owner  :  the contract owner
    callers:  only caller in the callers can call the set method
    the other contract(ex. logic ) who call the contract will be
    add to the callers
*/
contract AccessControl{
    // the contract valid owner
    address public owner;

    uint16 public totalCallers;

    mapping(address => bool) public callers;

    bool public isMaintaining;

    constructor() public {
        owner = msg.sender;
        totalCallers = 0;
    }

    modifier needOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier needAuth(){
        require(msg.sender == owner || callers[msg.sender] == true);
        _;
    }

    function changeOwner(address _newOwner) needOwner public {
        if(_newOwner != address(0)){
            owner = _newOwner;
        }
    }

    function addCaller(address _newCaller) needAuth public {
        if(callers[_newCaller] == false){
            callers[_newCaller] = true;
            totalCallers += 1;
        }
    }

    function removeCaller(address _oldCaller) needAuth public {
        if(callers[_oldCaller] == true){
            callers[_oldCaller] = false;
            totalCallers -= 1;
        }
    }
}

contract ERC20Interface {
    //当前合约中剩余的token数量
    function tokenLeft() public view returns (uint256);

    //owner 可以将合约中token 直接下发到指定的账户
    function assignToken(address _sendto, uint256 amount) public;

    // 获取总的支持量
    function totalSupply() public view returns (uint256);

    // 获取其他地址的余额
    function balanceOf(address _owner) public view returns (uint256);

    // 向其他地址发送token
    function transfer(address _to, uint256 _value) public returns (bool);

    // 从一个地址想另一个地址发送余额
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    //允许_spender从你的账户转出_value的余额，调用多次会覆盖可用量。某些DEX功能需要此功能
    function approve(address _spender, uint256 _value) public returns (bool);

    // 返回_spender仍然允许从_owner退出的余额数量
    function allowance(address _owner, address _spender) public view returns (uint256);

    // token转移完成后出发
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // approve(address _spender, uint256 _value)调用后触发
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


interface MojoDataInterface {

    /* write */
    function setCost(uint8 _lv, uint _cost, uint32 _cd)  external ;

    function setGeneral(uint32 _gid, uint8 _country, uint8 _rarity, uint16 hp, uint16 atk, uint16 lead, uint16 wit, uint32[4] _gids, uint32[4] _buffs,  uint8 discover)  external returns (uint32);

    function setSkill(uint32 _sid, uint8 _wt, uint32 _lv, uint32 _effect, uint32 _target, uint32 _base, uint32 _val)  external returns (uint32);

    /* read config*/
    function getGidOfRarity(uint8 _rarity, uint8 _idx) external view returns (uint32);

    function getCntByRarity(uint8 _rarity) external view returns (uint8 r5);

    function getCost(uint8 _lv) external view returns (uint cost,uint32 cd);

    function getGeneralLength() external view returns (uint8);

    function getGeneral(uint32 _gid) external view returns (
        uint8  country, uint8 rarity,  uint32[4] relations, uint32[4] buffs,
        uint8 discover );

    function getGeneralRelation(uint32 _gid) external view returns (uint32[4] relations);

    function getGeneralAttr(uint32 _gid,uint8 _type) external view returns (uint16);

    function getSkillLength() external view returns (uint8);

    function getSkill(uint32 _sid) external view returns (
        uint32 sid, uint8 _wt, uint32 _lv, uint32 _effect, uint32 _target, uint32 _base, uint32 _val);

    function getSkillIdByIndexAndLevel(uint8 idx,uint8 lv) external view returns(uint32);

    function getSkillTypeCnt() external view returns(uint8);
}

interface MojoAssetInterface {
    /* write */
    function addPlayerGeneral(address _owner, uint32 _gid, uint32 _sid, uint8 status)  external returns (uint64);

    function setPlayerGeneralCd(uint64 _id, uint32 _cdts) external;

    function setPlayerGeneralDt(uint64 _id, uint32 _dtts) external;

    function setPlayerGeneralLv(uint64 _id,  uint8 _lv)  external;

    function setPlayerGeneralAttr(uint64 _id,  uint32 _hpgrow, uint32 _atkgrow, uint32 _leadgrow, uint32 _witgrow)  external;

    function setPlayerGeneralAttrAdd(uint64 _id, uint8 _type, uint32 _val) external;

    function setPlayerDetectGroup(address _address,uint8 _idx, uint32 _ts)  external;

    function setPlayerHasGetFree(address _address,bool _hasGetFree)  external;

    function transfer(address _from, address _to, uint64 _id) external;

    /* read player */
    function getGidOfId(uint64 _id) external view returns (uint32);

    function getPlayerHasGetFree(address _address)  external view returns (bool);

    function getPlayerGeneral(uint64 _id)  external view returns (
        uint32 gid, uint32 sid, uint8 lv);

    function getPlayerGeneralAttr(uint64 _id,uint8 _type) external view returns(uint32);

    function getPlayerGeneralAll(uint32 _id)  external view returns (
        uint32 gid, uint32 sid, address owner, uint32 dtts, uint8 lv,uint32 hp,uint32 atk, uint32 lead, uint32 wit
    );

    function hasPlayer(address _player) external view returns(bool);

    function isOwn(address _owner,uint64 _id) external view returns(bool);

    function isIdle(address _owner, uint64 _id) external view returns(bool);

    function getPlayerState(address _owner)  external view returns (uint32[3] detect_ts );

    function getPlayerDetectGroup(address _owner) external view returns ( uint32[3] ts );
}

interface MojoAuctionInterface{
    function isOnAuction(uint64 _id) external view returns(bool);
}

contract MojoPresell is AccessControl(){
    struct PlayerGeneral{
        uint64 id;
        uint32 gid;
        address owner;
        /* detect over time */
        uint32 dtts;
        /* cd over time */
        uint32 cdts;
        uint8 lv;
        /* skill id */
        uint32 sid;
        /* low  16bit is the growth factor */
        /* high 16bit is the train value */
        uint32 hp;
        uint32 atk;
        uint32 lead;
        uint32 wit;
        /* the real value is base + lv * (base * attr growth factor) */
    }

    event CommonLog(address sender, uint8 t, uint256 p1, uint256 p2, uint64 p3, uint64 p4, uint32 ts);
    event InviteLog(address sender, address inviter);

    address public dataContract;
    address public assetContract;
    address public erc20Contract;

    /* random seed */
    uint64 seed;
    /* presell price */
    uint presellPrice ;
    /* presell is open  */
    bool presellOpen;

    uint16[3] presells;

    uint16 preselled;

    uint8[3] skillwts;

    uint16[5] freegets;
    /* random table */
    uint16[21] public rantbl;
    /* random section */
    uint16[21] public sections;

    uint256 public inviteAwardCoin;

    function setDataContract(address _dataContract) public {
        require(_dataContract  != address(0));
        dataContract    = _dataContract;
    }

    function setAssetContract(address _assetContract) public {
        require(_assetContract != address(0));
        assetContract   = _assetContract;
    }

    function setERC20Contract(address _erc20Contract) public{
        require(_erc20Contract != address(0));
        erc20Contract   = _erc20Contract;
    }

    constructor(address _dataContract, address _assetContract, address _erc20Contract) public {
        setDataContract(_dataContract);
        setAssetContract(_assetContract);
        setERC20Contract(_erc20Contract);

        dataContract    = _dataContract;
        assetContract   = _assetContract;
        presellPrice    = 0.05 ether;
        presellOpen     = true;
        presells        = [88, 1800, 0];
        freegets        = [1302,1303,2302,3301,4302];
        preselled       = 0;
        skillwts        = [25,65,80];
        sections        = [8,1,31,48,71,103,148,217,314,435,565,686,783,852,897,929,952,969,982,992,1000];
        rantbl          = [260,270,280,290,300,310,320,330,340,350,360,370,380,390,400,410,420,430,440,450,460];
        inviteAwardCoin = 10000;
    }

    function getTotalPreSelled() public view returns (uint16){
        return preselled;
    }

    function getWaitPreselled() public view returns (uint16[3]){
        return presells;
    }

    function getPreSelledInPool() public view returns (uint16){
        uint16 inpool;
        for(uint i = 0; i < presells.length; i++){
            inpool += presells[i];
        }
        return inpool;
    }

    function setPresellPrice(uint _presellPrice) needAuth public {
        presellPrice = _presellPrice;
    }

    function setPresellOpen(bool _presellOpen) needAuth public {
        presellOpen = _presellOpen;
    }

    function isPresellOpen() public view returns (bool){
        return presellOpen;
    }

    function withdrawEther(address _sendTo, uint _amount) needOwner public {
        require(_amount <= address(this).balance,&quot;not enough balance&quot;);
        _sendTo.transfer(_amount);
    }

    function getRandom256() public returns (uint256){
        seed = seed + 1;
        return uint256(sha256(now+seed));
    }

    function getAttrVal(uint64 _id,uint8 _t) internal view returns(uint32){
        MojoAssetInterface asset = MojoAssetInterface(assetContract);
        MojoDataInterface data   = MojoDataInterface(dataContract);

        uint32 gid;
        uint32 sid;
        uint8 lv;
        (gid, sid, lv) = asset.getPlayerGeneral(_id);

        uint16 base = data.getGeneralAttr(gid,_t);
        uint32 val  = asset.getPlayerGeneralAttr(_id,_t);
        return base + (lv - 1) * ( base * (val & 0xffff) / 10000 ) + ((val & 0xffff0000) >> 16);
    }


    function randomSkill() internal returns(uint32){
        MojoDataInterface data = MojoDataInterface(dataContract);
        uint8 r = uint8(getRandom256() % skillwts[2]);
        uint8 lv = 0;
        for(uint8 i = 0; i < 3; i++){
            if(r < skillwts[i]){
                lv = i;
                break;
            }
        }

        uint8 cnt = data.getSkillTypeCnt();
        uint8 idx = uint8(getRandom256() % cnt);
        return data.getSkillIdByIndexAndLevel(idx,lv);
    }


    function getOneFree(address _inviter)  public{
        /* presellOpen = false; */
        MojoAssetInterface asset = MojoAssetInterface(assetContract);
        ERC20Interface erc20 = ERC20Interface(erc20Contract);
        require(asset.getPlayerHasGetFree(msg.sender) == false , &quot;player has get free before&quot;);

        uint8 idx  = uint8(getRandom256() % freegets.length);
        uint32 gid = freegets[idx];
        uint32 sid = randomSkill();
        uint64 id  = asset.addPlayerGeneral( msg.sender, gid, sid,0);
        initGeneralAttr(gid,id);
        asset.setPlayerHasGetFree(msg.sender,true);
        if(asset.hasPlayer(_inviter)){
            erc20.assignToken(_inviter, inviteAwardCoin);
            emit InviteLog(msg.sender,  _inviter);
        }
        emit CommonLog(msg.sender,9,gid,0,0,0,uint32(now));
    }

    function presell() payable public {
        address _owner = msg.sender;
        // check presell is open
        require(presellOpen == true,&quot;presell is not open&quot;);
        // check price
        require(msg.value == presellPrice,&quot;presell value is not same with price&quot;);

        uint16 total = getPreSelledInPool();
        // check to preselled general&#39;s count must great than zero
        require(total > 0,&quot;there is no general in presell pool&quot;);

        MojoAssetInterface asset = MojoAssetInterface(assetContract);
        MojoDataInterface data  = MojoDataInterface(dataContract);

        preselled += 1;
        //random a general
        //random a rarity
        uint r   = uint16(getRandom256() % total);
        uint8 c5 = data.getCntByRarity(5);
        uint8 c4 = data.getCntByRarity(4);
        uint8 c3 = data.getCntByRarity(3);

        uint256 r1 = getRandom256();
        uint32 gid;
        uint8 idx;

        if(r < presells[0]){
            //five star
            idx = uint8(r1 % c5);
            gid = data.getGidOfRarity(5 , idx);
            presells[0] -= 1;
        }else if(r < presells[1] + presells[0]){
            //four star
            idx = uint8(r1 % c4);
            gid = data.getGidOfRarity(4 , idx);
            presells[1] -= 1;
        }else{
            idx = uint8(r1 % c3);
            gid = data.getGidOfRarity(3 , idx);
            presells[2] -= 1;
        }
        uint32 sid = randomSkill();
        uint64 id = asset.addPlayerGeneral(_owner, gid,sid,0);
        emit CommonLog(_owner,8,msg.value,gid,0,0,uint32(now));
        // random attr
        /* loop once and get for idx */
        initGeneralAttr(gid,id);
    }

    function initGeneralAttr(uint32 gid,uint64 _id) internal {
        MojoAssetInterface asset = MojoAssetInterface(assetContract);
        MojoDataInterface data  = MojoDataInterface(dataContract);
        uint8 idx_hp  = 22;
        uint8 idx_atk = 22;
        uint8 idx_lead= 22;
        uint8 idx_wit = 22;

        uint16 r_hp   = uint16(getRandom256() % 1000);
        uint16 r_atk  = uint16(getRandom256() % 1000);
        uint16 r_lead = uint16(getRandom256() % 1000);
        uint16 r_wit  = uint16(getRandom256() % 1000);

        uint32 total;
        for(uint8 i = 0; i < sections.length; i++ ){
            total += sections[i];
            if(idx_hp == 22 && r_hp <= total){
                idx_hp = i;
            }

            if(idx_atk == 22 && r_atk <= total){
                idx_atk = i;
            }

            if(idx_lead == 22 && r_lead <= total){
                idx_lead = i;
            }

            if(idx_wit == 22 && r_wit <= total){
                idx_wit = i;
            }
        }
        r_hp   = data.getGeneralAttr(gid,0);
        r_atk  = data.getGeneralAttr(gid,1);
        r_lead = data.getGeneralAttr(gid,2);
        r_wit  = data.getGeneralAttr(gid,3);
        asset.setPlayerGeneralLv(_id,1);
        asset.setPlayerGeneralAttr(_id,
            (r_hp * 2  + rantbl[idx_hp]) * 3 / 4,
            r_atk  * 5 + rantbl[idx_atk],
            r_lead * 5 + rantbl[idx_lead],
            r_wit  * 5 + rantbl[idx_wit]
            );
    }
}