/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ERC20 {  
    function decimals() external view returns (uint8 decimals); 
    function totalSupply() external view returns (uint totalSupply);  
    function balanceOf(address _owner) external view returns (uint balance);  
    function transfer(address _to, uint _value) external returns (bool success);  
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);  
    function approve(address _spender, uint _value) external returns (bool success);  
    function allowance(address _owner, address _spender) external view returns (uint remaining);  
}

interface IERC721Receiver {
    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) external returns (bytes4);
}

interface ERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    
    
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}


interface rarity is ERC721 {
    // function balanceOf(address owner) external view returns (uint);
    // function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    // function approve(address to, uint256 tokenId) external;
    // function getApproved(uint) external view returns (address);
    // function ownerOf(uint) external view returns (address);
    function level(uint) external view returns (uint);
    

    function adventurers_log(uint) external view returns (uint);
    function class(uint) external view returns (uint);
    function summon(uint _class) external;
    function next_summoner() external view returns (uint);
    function spend_xp(uint _summoner, uint _xp) external;
    function adventure(uint _summoner) external ;
    function level_up(uint _summoner) external;
    
    function xp_required(uint curent_level)  external view  returns (uint);
    function xp(uint _summoner)  external view  returns (uint);
}

interface rarity_attributes {
    function point_buy(uint _summoner, uint32 _str, uint32 _dex, uint32 _const, uint32 _int, uint32 _wis, uint32 _cha) external;
    function character_created(uint) external view returns (bool);
    function ability_scores(uint) external view returns (uint32,uint32,uint32,uint32,uint32,uint32);
}

interface rarity_skills {
    function is_valid_set(uint _summoner, uint8[36] memory _skills) external view returns (bool);
    function set_skills(uint _summoner, uint8[36] memory _skills) external;
    function get_skills(uint _summoner) external view returns (uint8[36] memory);
}

interface rarity_gold {
    function approve(uint from, uint spender, uint amount) external returns (bool);
    function allowance(uint summoner,uint executer) external view returns (uint);
    function balanceOf(uint summoner) external view returns (uint);
    function claimable(uint summoner) external view returns (uint amount);
    function claim(uint summoner) external;
    function transfer(uint from, uint to, uint amount) external returns (bool);
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

interface rarity_crafting_materials_1 {
    function adventure(uint _summoner) external returns (uint reward);
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

// interface codex_base_random {
//     function d20(uint _summoner) external view returns (uint);
// }
interface rarity_crafting is ERC721 {
    //uint constant CRAFTING_SUMMMONER_ID=1758709;
    //function SUMMMONER_ID() external view returns (uint);
    function craft(uint _summoner, uint8 _base_type, uint8 _item_type, uint _crafting_materials) external;
    function simulate(uint _summoner, uint _base_type, uint _item_type, uint _crafting_materials) external view returns (bool crafted, int check, uint cost, uint dc);
}

//V2和V1不同,rarity都是存在合约中的,所以不需要授权之类的
contract crafting_batch_v2_ropsten is IERC721Receiver {
    rarity _rm = rarity(0x64A66c7FD681E94D4B54AAb08B3d4A5B2BBcC02D );
    rarity_attributes _aattr = rarity_attributes( 0xf4537e2B4F2C1E5ee8a1fa57620D2808F716AB00);
    rarity_crafting_materials_1 _materials_1 = rarity_crafting_materials_1(0x094208FB64554cE9258AD4C598ec327560790daD );
    rarity_gold _gold = rarity_gold(0xBA57FfE606BABE2dA0832d38977887643cB050Ec );
    rarity_skills _skills = rarity_skills( 0x926D5E3CfC2E6A9796Ac836BD18FB626637664B4);

    //codex_base_random constant _random = codex_base_random( 0x3764B6c7272C2a8D933A9962f38E8cc4065EB6Ef);
    rarity_crafting  _crafting = rarity_crafting(0x672dF7ee4C09F5a596D797A707619DfC4719ae23);
    
    function set_rarity(address addr) external {
        require(_owner==msg.sender);
        _rm=rarity(addr);
    }
    
    function set_crafting(address addr) external {
        require(_owner==msg.sender);
        _crafting=rarity_crafting(addr);
    }

    function set_attributes(address addr) external {
        require(_owner==msg.sender);
        _aattr=rarity_attributes(addr);
    }
    
    function set_materials_1(address addr) external {
        require(_owner==msg.sender);
        _materials_1=rarity_crafting_materials_1(addr);
    }
    
    function set_gold(address addr) external {
        require(_owner==msg.sender);
        _gold=rarity_gold(addr);
    }
    
    function set_skills(address addr) external {
        require(_owner==msg.sender);
        _skills=rarity_skills(addr);
    }
    
    
    function getAddress(uint8 index) external view returns (address){
        if(index==0 ){
            return address(_rm);
        }else if(index==1){
            return address(_aattr);
        }else if(index==2){
            return address(_gold); 
        }else if(index==3){
            return address(_skills);
        }else if(index==4 ){
            return address(_materials_1);
        }else if(index==5){
            return address(_crafting);
        }else if(index==255){
            return _owner;
        }else{
            return address(0);
        }
    }
    
    address immutable _owner;

    bool public last_crafted;
    int  public last_check;
    uint public last_cost;
    uint public last_dc;
    

    constructor(){
        _owner=payable(msg.sender);
    }
    
    function onERC721Received(address,address ,uint256 ,bytes calldata ) public virtual override  returns (bytes4){
        return this.onERC721Received.selector;
    }


    function transfer_erc721(address _erc721_contact_addr,address _to,uint _max) external {
        require(_owner==msg.sender);
        address _inner=address(this);
        if(_to==address(0)){
            _to=_owner;
        }
        
        ERC721 _erc721=ERC721(_erc721_contact_addr);
        
        uint _len = _erc721.balanceOf(_inner);
        if(_len>_max) _len=_max;
        while(_len>0){
            uint _id=_erc721.tokenOfOwnerByIndex(_inner,0);
            _erc721.transferFrom(_inner,_to,_id);
            _len--;
        }
    }
    
    function withdraw_erc20(address _ec20_contact_addr) external{
        address _inner=address(this);
        
        if(_ec20_contact_addr==address(0)){
            if(_inner.balance>0){
                payable(_owner).transfer(_inner.balance);
            }
        }else{
            ERC20 _erc20=ERC20(_ec20_contact_addr);
            if(_erc20.balanceOf(_inner) >0){
                _erc20.transfer(_owner,_erc20.balanceOf(_inner));
            }
        }
    }
        

    //先检查后制造,帮助提高成功率
    function craft_one(uint _summoner, uint8 _base_type, uint8 _item_type) external{
        require(_owner==msg.sender);
        (last_crafted,last_check,last_cost,last_dc)=_crafting.simulate(_summoner, _base_type, _item_type, 0) ;
        if(last_crafted){
            _crafting.craft(_summoner, _base_type, _item_type, 0);
            //_crafting.approve(_owner,_crafting.tokenByIndex(_crafting.totalSupply()-1));
        }
    }



    function find_summon_ready(uint8 _base_type, uint8 _item_type,uint _start) internal returns(uint _summonerId,uint _next) {
        address _inner=address(this);
        uint _len = _rm.balanceOf(_inner);

        for(uint _i=_start;_i<_len;_i++ ){
            uint _id=_rm.tokenOfOwnerByIndex(_inner,_i);
            (last_crafted,last_check,last_cost,last_dc)= _crafting.simulate(_id, _base_type, _item_type, 0);
            if(last_crafted ){
                return (_id,_i+1);
            }
        }

        return (0,0);
    }

    //批量制造装备
    function craft_batch(uint8 _base_type, uint8 _item_type,uint _maxCount) external{
        require(_owner==msg.sender);
        if(_maxCount==0) _maxCount=10;  //默认一次尝试制作10次

        uint _next=0;
        uint _summoner=0;
        
        for(uint _i=0;_i<_maxCount;_i++){          
            (_summoner,_next)=find_summon_ready(_base_type,_item_type,_next);
            if(_next==0) break;
            _crafting.craft(_summoner, _base_type, _item_type, 0);
        }
    }

    function adventure_one(uint _summoner) external {
        require(_owner==msg.sender);
        _rm.adventure(_summoner);
    }
 
    //可冒险数量
    function adventure_count() external view returns (uint _count){
        _count=0;

        address _inner=address(this);
        uint len = _rm.balanceOf(_inner);
        for (uint i = 0; i < len; i++) {
            uint _id=_rm.tokenOfOwnerByIndex(_inner,i);
            if(block.timestamp>_rm.adventurers_log(_id) ){
                _count++;
            }
        }
    }
    
    //冒险
    function adventure_all(uint _maxCount) external {
        require(_owner==msg.sender);

        if(_maxCount==0) _maxCount=20; //默认一次搞20个
        
        address _inner=address(this);
        uint len = _rm.balanceOf(_inner);
        for (uint i = 0; i < len; i++) {
            uint _id=_rm.tokenOfOwnerByIndex(_inner,i);
            if(block.timestamp>_rm.adventurers_log(_id) ){
                _rm.adventure(_id);
                _maxCount--;
                if(_maxCount==0) return;
            }
        }
    }

    function level_up_one(uint _summoner) external {
        require(_owner==msg.sender);
        _rm.level_up(_summoner);
    }


    //可升级数量
    function level_up_count() external view returns (uint _count){
        _count=0;

        address _inner=address(this);
        uint len = _rm.balanceOf(_inner);
        for (uint i = 0; i < len; i++) {
            uint _id=_rm.tokenOfOwnerByIndex(_inner,i);
            uint _level = _rm.level(_id);
            if( _rm.xp(_id)>= _rm.xp_required(_level) ){
                _count++;
            }
        }
    }
    //批量升级
    function level_up_all(uint _maxCount) external {
        require(_owner==msg.sender);
        if(_maxCount==0) _maxCount=20; //默认一次搞20个

        address _inner=address(this);
        uint len = _rm.balanceOf(_inner);
        for (uint i = 0; i < len; i++) {
            uint _id=_rm.tokenOfOwnerByIndex(_inner,i);
            uint _level = _rm.level(_id);
            if( _rm.xp(_id)>= _rm.xp_required(_level) ){
                _rm.level_up(_id);
                _maxCount--;
                if(_maxCount==0) return;
            }
        }
    }

    //提取金币-单个
    function gold_claim_one(uint _summoner) external {
        require(_owner==msg.sender);
        _gold.claim(_summoner);
    } 

    //批量提取金币
    function gold_claim_all(uint _maxCount) external {
        require(_owner==msg.sender);
        if(_maxCount==0) _maxCount=20; //默认一次搞20个
        
        address _inner=address(this);
        uint len = _rm.balanceOf(_inner);
        for (uint i = 0; i < len; i++) {
            uint _id=_rm.tokenOfOwnerByIndex(_inner,i);
            if( _gold.claimable(_id)>0){
                _gold.claim(_id);
                _maxCount--;
                if(_maxCount==0) return;
            }
        }
    }

    //可提取金币的数量
    function gold_claim_count() external view returns (uint _count){
        _count=0;

        address _inner=address(this);
        uint len = _rm.balanceOf(_inner);
        for (uint i = 0; i < len; i++) {
            uint _id=_rm.tokenOfOwnerByIndex(_inner,i);
            if( _gold.claimable(_id)>0){
                _count++;
            }
        }
    }


    //分发金币
    function gold_tranfer_all(uint _from,uint _start,uint _count,uint _val) external {
        require(_owner==msg.sender);
        
        address _inner=address(this);
        uint _len = _rm.balanceOf(_inner);
        if(_len>= (_start+_count) ){
            _len=_start+_count;
        }
        for (uint i = _start; i < _len; i++) {
            uint _to=_rm.tokenOfOwnerByIndex(_inner,i);
            if( _to!=_from && _gold.balanceOf(_from)>= _val ){
                _gold.transfer(_from,_to,_val);
            }
        }
    }

    //汇总金币
    function gold_summary_all(uint _to,uint _start,uint _count,uint _val) external {
        require(_owner==msg.sender);
        require(_rm.ownerOf(_to) == msg.sender);
        
        address _inner=address(this);
        uint _len = _rm.balanceOf(_inner);
        if(_len>= (_start+_count) ){
            _len=_start+_count;
        }
        for (uint i = _start; i<_len; i++) {
            uint _from=_rm.tokenOfOwnerByIndex(_inner,i);
            if(_from!=_to){
                if(_val>_gold.balanceOf(_from)){
                    _val=_gold.balanceOf(_from);
                }
                _gold.transfer(_from,_to, _val);
            }
        }
    }

    //所有金币数量
    function gold_total() external view returns (uint _total) {
        address _inner=address(this);
        
        _total=0;
        uint _len = _rm.balanceOf(_inner);
        for (uint i = _len; i<_len; i++) {
            uint _from=_rm.tokenOfOwnerByIndex(_inner,i);
            _total+=_gold.balanceOf(_from);
        }
    }

    //需要加属性的数量
    function attr_uninit_count(uint _class) external view returns (uint _count){
        _count=0;

        address _inner=address(this);
        uint len = _rm.balanceOf(_inner);
        for (uint i = 0; i < len; i++) {
            uint _id=_rm.tokenOfOwnerByIndex(_inner,i);
            if(_class!=0 && _rm.class(_id)!=_class) continue; //跳过
            if( _aattr.character_created(_id) ) continue;
             _count++;
        }
    }

    //属性点-单个
    function attr_init_one(uint _summoner, uint32 _str, uint32 _dex, uint32 _const, uint32 _int, uint32 _wis, uint32 _cha) external{
        require(_owner==msg.sender);
        _aattr.point_buy(_summoner, _str, _dex, _const, _int, _wis, _cha);
    }

    //属性点-批量
    function attr_init_all(uint _class,uint _maxCount, uint32 _str, uint32 _dex, uint32 _const, uint32 _int, uint32 _wis, uint32 _cha) external{
        require(_owner==msg.sender);
        if(_maxCount==0) _maxCount=20; //默认一次搞20个
        
        address _inner=address(this);
        uint len = _rm.balanceOf(_inner);
        for (uint i = 0; i < len; i++) {
            uint _id=_rm.tokenOfOwnerByIndex(_inner,i);
            if(_class!=0 && _rm.class(_id)!=_class) continue; //跳过
            if( _aattr.character_created(_id) ) continue;
                
            _aattr.point_buy(_id, _str, _dex, _const, _int, _wis, _cha);
            _maxCount--;
            if(_maxCount==0) return;
        }
    }

    //制造类加点
    function attr_init_craft_all(uint _class,uint _maxCount) external{
        require(_owner==msg.sender);
        if(_maxCount==0) _maxCount=20; //默认一次搞20个
        
        address _inner=address(this);
        uint len = _rm.balanceOf(_inner);
        for (uint i = 0; i < len; i++) {
            uint _id=_rm.tokenOfOwnerByIndex(_inner,i);
            if(_class!=0 && _rm.class(_id)!=_class) continue; //跳过
            if( !_aattr.character_created(_id) ){
                _aattr.point_buy(_id, 8, 8,8, 22, 8, 8);
                _maxCount--;
                if(_maxCount==0) return;
            }
        }
    }

    //人员数量汇总
    function summoner_count(uint _class) external view returns (uint _count){
        _count=0;
        address _inner=address(this);
        uint len = _rm.balanceOf(_inner);
        for (uint i = 0; i < len; i++) {
            uint _id=_rm.tokenOfOwnerByIndex(_inner,i);
            if(_class!=0 && _rm.class(_id)!=_class) continue; //跳过
            _count++;
        }
    }

    //批量招募
    function summon_batch(uint _class,uint _count) external{
        require(_owner==msg.sender);
        for (uint i = 0; i < _count; i++) {
            uint _summoner=_rm.next_summoner();
            _rm.summon(_class);
            _rm.approve(_owner,_summoner); 
            _rm.adventure(_summoner); //首次冒险
        }
    }

    function summon_craft_batch(uint _class,uint _count) external{
        require(_owner==msg.sender);
        preset_skills=[0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        for (uint i = 0; i < _count; i++) {
            uint _summoner=_rm.next_summoner();
            _rm.summon(_class);
            _rm.approve(_owner,_summoner); 
            _rm.adventure(_summoner); //首次冒险
            _aattr.point_buy(_summoner, 8, 8, 8, 22, 8, 8);
            _skills.set_skills(_summoner, preset_skills);
        }
    }
    
    //批量授权
    function summoner_approve_batch(address _to, uint _start,uint _count) external {
        require(_owner==msg.sender);
        
        address _inner=address(this);
        uint _len = _rm.balanceOf(_inner);
        if(_len>= (_start+_count) ){
            _len=_start+_count;
        }
        for (uint i = _start; i < _len; i++) {
            uint _tokenId=_rm.tokenOfOwnerByIndex(_inner,i);
            _rm.approve(_to, _tokenId); 
        }
    }
    function summoner_approve_one(address _to,uint _tokenId ) external {
        require(_owner==msg.sender);
        _rm.approve(_to, _tokenId);
    }


    //技能点
    uint8[36] public preset_skills=[0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];

    function update_preset_skills(uint8[36] memory _skill_data) external {
        require(_owner==msg.sender);
        preset_skills = _skill_data;
    }
    //设置技能-单个
    function skills_set(uint _summoner) external {
        require(_owner==msg.sender);
        _skills.set_skills(_summoner, preset_skills);
    }

    //批量设置技能
    function skills_set_batch(uint _class,uint _start,uint _count) external {
        require(_owner==msg.sender);
        
        address _inner=address(this);
        uint _len = _rm.balanceOf(_inner);
        if(_len>= (_start+_count) ){
            _len=_start+_count;
        }
        for (uint i = _start; i < _len; i++) {
            uint _tokenId=_rm.tokenOfOwnerByIndex(_inner,i);
            if(_class!=0 && _rm.class(_tokenId)!=_class) continue; //跳过
            _skills.set_skills(_tokenId,preset_skills); 
        }
    }

}