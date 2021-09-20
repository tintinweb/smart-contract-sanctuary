/**
 *Submitted for verification at Etherscan.io on 2021-09-20
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


interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
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
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) external returns (bytes4);
}

interface rarity is IERC721 {
    // function balanceOf(address owner) external view returns (uint);
    // function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    // function approve(address to, uint256 tokenId) external;
    // function getApproved(uint) external view returns (address);
    // function ownerOf(uint) external view returns (address);
    function level(uint) external view returns (uint);
    function adventurers_log(uint) external view returns (uint);
    function next_summoner() external view returns (uint);
    function class(uint) external view returns (uint);
    function summon(uint _class) external;
    function xp_required(uint curent_level)  external view  returns (uint);
    function xp(uint _summoner)  external view  returns (uint);

    //function spend_xp(uint _summoner, uint _xp) external;
    function adventure(uint _summoner) external ;
    function level_up(uint _summoner) external;
}

interface rarity_attributes {
    function character_created(uint) external view returns (bool);
    function ability_scores(uint) external view returns (uint32,uint32,uint32,uint32,uint32,uint32);
    function calculate_point_buy(uint _str, uint _dex, uint _const, uint _int, uint _wis, uint _cha) external view returns (uint);

    function point_buy(uint _summoner, uint32 _str, uint32 _dex, uint32 _const, uint32 _int, uint32 _wis, uint32 _cha) external;
}

interface rarity_skills {
    function is_valid_set(uint _summoner, uint8[36] memory _skills) external view returns (bool);
    function get_skills(uint _summoner) external view returns (uint8[36] memory);

    function set_skills(uint _summoner, uint8[36] memory _skills) external;
}

interface rarity_gold {
    function allowance(uint summoner,uint executer) external view returns (uint);
    function balanceOf(uint summoner) external view returns (uint);
    function claimable(uint summoner) external view returns (uint amount);

    function approve(uint from, uint spender, uint amount) external returns (bool);
    function claim(uint summoner) external;
    function transfer(uint from, uint to, uint amount) external returns (bool);
   // function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

interface rarity_crafting_materials_1 {
    function balanceOf(uint _summoner) external view returns (uint reward);

    function adventure(uint _summoner) external returns (uint reward);
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

// interface codex_base_random {
//     function d20(uint _summoner) external view returns (uint);
// }
interface rarity_crafting is IERC721 {
    //uint constant CRAFTING_SUMMMONER_ID=1758709;
    function next_item() external view returns (uint);
    function SUMMMONER_ID() external view returns (uint);
    function craft(uint _summoner, uint8 _base_type, uint8 _item_type, uint _crafting_materials) external;
    function simulate(uint _summoner, uint _base_type, uint _item_type, uint _crafting_materials) external view returns (bool crafted, int check, uint cost, uint dc);
}

//interface market_1{
//   function list(uint _id, uint _price) external;
//   function unlist(uint _id) external;
//   function myListLength(address user) external view returns (uint);
//   function myListsAt(address user,uint start,uint count) external view returns (uint[] memory rIds, uint[] memory rPrices);
//}

//V2和V1不同,rarity都是存在合约中的,所以不需要授权之类的
contract rarity_manager_v2 is IERC721Receiver {
    rarity public constant _rm = rarity(0x64A66c7FD681E94D4B54AAb08B3d4A5B2BBcC02D );
    rarity_attributes public constant _aattr = rarity_attributes( 0xf4537e2B4F2C1E5ee8a1fa57620D2808F716AB00);
    rarity_crafting_materials_1 public constant _materials_1 = rarity_crafting_materials_1(0x094208FB64554cE9258AD4C598ec327560790daD );
    rarity_gold public constant _gold = rarity_gold(0xBA57FfE606BABE2dA0832d38977887643cB050Ec );
    rarity_skills public constant _skills = rarity_skills( 0x926D5E3CfC2E6A9796Ac836BD18FB626637664B4);
    rarity_crafting public constant _crafting = rarity_crafting(0x672dF7ee4C09F5a596D797A707619DfC4719ae23);
    //codex_base_random constant _random = codex_base_random( 0x3764B6c7272C2a8D933A9962f38E8cc4065EB6Ef);
    address public constant _market_1_addr=address(0);
    
    // rarity public constant _rm = rarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb );
    // rarity_attributes public constant _aattr = rarity_attributes( 0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);
    // rarity_gold public constant _gold = rarity_gold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2 );
    // rarity_skills public constant _skills = rarity_skills(0x51C0B29A1d84611373BA301706c6B4b72283C80F);
    // rarity_crafting_materials_1 public constant _materials_1 = rarity_crafting_materials_1(0x2A0F1cB17680161cF255348dDFDeE94ea8Ca196A);
    // rarity_crafting public constant _crafting = rarity_crafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);
    // //codex_base_random constant _random = codex_base_random( 0x7426dBE5207C2b5DaC57d8e55F0959fcD99661D4);
    // address public constant _market_1_addr=address(0x4adEe474eA0A10E78376Ee5DFee7Be2A2A4CdDD0);
    
    address immutable _owner;

    uint public last_crafting_count;
    uint public last_crafter;
    int  public last_check;
    uint public last_cost;
    uint public last_dc;
    

    constructor(){
        _owner=msg.sender;
        
        //_rm.setApprovalForAll(address(_skills), true);
        //_rm.setApprovalForAll(address(_aattr), true);
        //_rm.setApprovalForAll(address(_gold), true);
        _rm.setApprovalForAll(address(_crafting), true);
        _rm.setApprovalForAll(address(_materials_1), true);

        //默认市场
        if( _market_1_addr!=address(0) ){
            _rm.setApprovalForAll(_market_1_addr, true);
            _crafting.setApprovalForAll(_market_1_addr, true);
        }
    }

    //代理合约内部的ERC721执行授权
    function setApprovalForAll(address _erc721_contact_addr,address operator, bool _approved) external{
        require(_owner==msg.sender);

        IERC721 _erc721=IERC721Enumerable(_erc721_contact_addr);
        _erc721.setApprovalForAll(operator, _approved);
    }

    function onERC721Received(address,address ,uint256 ,bytes calldata ) public virtual override  returns (bytes4){
        return this.onERC721Received.selector;
    }

    function _summoner_find(uint _summoner) internal view returns (int){
        uint _len = summoners.length;
        for (uint i = 0; i < _len; i++) {
            if(summoners[i]==_summoner) return int(i);
        }
        return -1;
    }


    //发送单个ERC20到某个地址
    function _erc721_transfer(address _erc721_contact_addr,uint[] memory _takenIds,address _to) internal {
        address _inner=address(this);
      
        IERC721 _erc721=IERC721(_erc721_contact_addr);
        if(_erc721_contact_addr==address(_rm) ){ //rarity受内部管理,除非不受控的才可以直接处理
            for(uint i=0;i<_takenIds.length;i++){
                if( _erc721.ownerOf(_takenIds[i])==_inner) continue;
                if( _summoner_find(_takenIds[i])>=0) continue;
                
                //不在受控列表中
                _erc721.transferFrom(_inner,_to,_takenIds[i]);
            }
        }else{
            for(uint i=0;i<_takenIds.length;i++){
                 if( _erc721.ownerOf(_takenIds[i])==_inner) continue;
                _erc721.transferFrom(_inner,_to,_takenIds[i]);
            }
        }
    }

    function erc721_transfer(address _erc721_contact_addr,uint[] memory _takenIds,address _to) external {
        require(_owner==msg.sender);
        require(_to!=address(0) && _to!=address(this));

        _erc721_transfer(_erc721_contact_addr,_takenIds,_to);
    }
    function erc721_widthdraw(address _erc721_contact_addr,uint[] memory _takenIds) external {
        require(_owner==msg.sender);
        _erc721_transfer(_erc721_contact_addr,_takenIds,_owner);
    }

    //可枚举的ERC721
    function erc721_widthdraw(address _erc721_contact_addr,uint _start,uint _count) external {
        require(_owner==msg.sender);
        require(_erc721_contact_addr!=address(_rm));

        address _inner=address(this);
        IERC721Enumerable _erc721=IERC721Enumerable(_erc721_contact_addr);
        uint _len = _erc721.balanceOf(_inner);
        if(_len>_start+_count){
            _len=_start+_count;
        }
        for(uint i= _start;i<_len;i++){
            uint _id=_erc721.tokenOfOwnerByIndex(_inner,_len-_start-1);
            _erc721.transferFrom(_inner,_owner,_id);
        }
    }
    
    function erc20_withdraw(address _ec20_contact_addr) external{
        require(_owner==msg.sender);
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


    uint[] summoners;        //合约内的召唤者索引
    uint8[36] preset_skills;    //技能点缓冲
    uint32[6] preset_attrs;     //属性点缓冲
    uint public last_gold_claimed;
    
    function get_preset_skills() external view returns (uint8[36] memory) {
        return preset_skills;
    }

    function update_preset_skills(uint8[36] memory _skill_data) external {
        require(_owner==msg.sender);
        preset_skills = _skill_data;
    }
    function get_preset_attrs() external view returns (uint32[6] memory) {
        return preset_attrs;
    }

    function update_preset_attrs(uint32[6] memory _preset_attrs) external {
        require(_owner==msg.sender);
        require(_aattr.calculate_point_buy(preset_attrs[0], preset_attrs[1], preset_attrs[2], preset_attrs[3], preset_attrs[4], preset_attrs[5]) == 32);
        preset_attrs = _preset_attrs;
    }


    function summoner_total() public view returns (uint) {
        return summoners.length;
    }

    struct summoner_info {
        uint32 id;
        uint8  class;
        uint8  level;
        uint32 xp;
        uint   gold;
        uint   materials_1;
    }


    function summoner_xp_list(uint _start,uint _count) public view returns ( summoner_info[] memory xps) {
        uint _eof = summoners.length;
        if(_eof>= (_start+_count) ){
            _eof=_start+_count;
        }
        if(_eof>_start){
            xps=new summoner_info[](_eof-_start);
            for (uint i = _start; i < _eof; i++) {
                uint _summoner=summoners[i];
                uint8 _level=uint8(_rm.level(_summoner));
                uint8 _class=uint8(_rm.class(_summoner));
                uint32 _xp=uint32(_rm.xp(_summoner)/1e18);
                uint32 _gold_val=uint32(_gold.balanceOf(_summoner)/1e18);
                uint32 _materials_1_val=uint32(_materials_1.balanceOf(_summoner));
                xps[i-_start]=summoner_info(uint32(_summoner),_class,_level,_xp,_gold_val,_materials_1_val);
            }
        }
    }


    function _summon_batch(uint _class,uint _count) internal{
        for (uint i = 0; i < _count; i++) {
            uint _summoner=_rm.next_summoner();
            _rm.summon(_class);
            _rm.adventure(_summoner); //首次冒险
            _gold.approve(_summoner,_crafting.SUMMMONER_ID(),1000000e18); //准备制造武器

            summoners.push(_summoner);
        }
    }

    //批量招募任意职业
    function summon_batch(uint _class,uint _count) external{
        require(_owner==msg.sender);
        if(_count==0) _count=10;
        _summon_batch(_class,_count);
    }

    //批量招募-制造者
    function summon_crafters(uint _count) external{
        require(_owner==msg.sender);
        if(_count==0) _count=10;
        _summon_batch(11,_count);

        preset_skills=[0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        preset_attrs=[8, 8, 8, 22, 8, 8];

        for (uint i = 0; i < _count; i++) {
            uint _summoner= summoners[summoners.length-i-1];
            _aattr.point_buy(_summoner, preset_attrs[0], preset_attrs[1], preset_attrs[2], preset_attrs[3], preset_attrs[4], preset_attrs[5]);
            _skills.set_skills(_summoner, preset_skills);
        }
    }


    function summoner_remove(uint _start,uint _count) internal{
        uint _move_start= _start+_count;
        uint _move_count=summoners.length-_move_start;
        for (uint _i = 0; _i<_move_count; _i++){
           summoners[_start+_i] = summoners[_move_start+_i];
        }
        uint _delete_count=summoners.length-(_start+_count);

        //删除尾部
        for (uint i = 0; i<_delete_count; i++){
            summoners.pop();
        }
    }

    function summoner_dispose(uint[] memory _takenIds) external{
        address _inner=address(this);
        for(uint i=0;i<_takenIds.length;i++){
            _rm.transferFrom(msg.sender,_inner,_takenIds[i]);
            summoners.push(_takenIds[i]);
        }
    }
    
    function _summoner_transfer(uint _start,uint _count,address _to) internal {
        address _inner=address(this);
        uint _eof=summoners.length;
        if(_eof>(_start+_count) ){
            _eof=_start+_count;
        }
        for(uint _i=_start;_i<_eof;_i++){
            _rm.transferFrom(_inner,_to,summoners[_i]);
        }
        summoner_remove(_start,_eof);
    }
    function summoner_withdraw(uint _start,uint count) external {
        require(_owner==msg.sender);
        _summoner_transfer(_start,count,_owner);
    }

    function summoner_transfer(uint _start,uint _count,address _to) external {
        require(_owner==msg.sender);
        _summoner_transfer(_start,_count,_to);
    }


    //批量授权
    function summoner_approve_batch(uint _start,uint _count,address _to) external {
        require(_owner==msg.sender);
        
        uint _len = summoners.length;
        if(_len>= (_start+_count) ){
            _len=_start+_count;
        }
        for (uint i = _start; i < _len; i++) {
            uint _tokenId=summoners[i];
            _rm.approve(_to, _tokenId); 
        }
    }
    function summoner_approve_one(uint _tokenId,address _to) external {
        require(_owner==msg.sender);
        _rm.approve(_to, _tokenId);
    }


    //先检查后制造,帮助提高成功率
    //可以用钱包中的summoner执行,但有三个前置条件:
    //1. summoner需要预先授权到本合约
    //2. 手动执行 _gold.approve(summoner, _crafting.SUMMMONER_ID=1758709, ...)
    //3. 手动执行 _rm.setApprovalForAll(_crafting, true)
    function crafting_one(uint _summoner, uint8 _base_type, uint8 _item_type) external{
        require(_owner==msg.sender);
        (bool _crafted,int _check,uint _cost,uint _dc)=_crafting.simulate(_summoner, _base_type, _item_type, 0) ;
        if(_crafted){
            uint _takenId=_crafting.next_item();
            _crafting.craft(_summoner, _base_type, _item_type, 0);
            (last_crafter,last_check,last_cost,last_dc)= (_summoner,_check,_cost,_dc);
            _crafting.transferFrom(address(this), _owner, _takenId); //直接发送到钱包
        }else{
            (last_crafter,last_check,last_cost,last_dc)=(0,0,0,0);
        }
    }

    function _find_crafter_ready(uint8 _base_type, uint8 _item_type,uint _start) internal view returns(uint _summonerId,int _next,int _check,uint _cost,uint _dc) {
        uint _len = summoners.length;

        for(uint _i=_start;_i<_len;_i++ ){
            uint _id=summoners[_i];
            bool _crafted;
            (_crafted,_check,_cost,_dc)= _crafting.simulate(_id, _base_type, _item_type, 0);
            if(_crafted){
                return (_id,int(_i+1),_check,_cost,_dc);
            }
        }

        return (0,-1,0,0,0);
    }

    function find_crafter_ready(uint8 _base_type, uint8 _item_type,uint _start) internal view returns(uint _summonerId,int _next,int _check,uint _cost,uint _dc) {
        return _find_crafter_ready(_base_type,_item_type,_start);
    }

    //批量制造装备
    function crafting_batch(uint8 _base_type, uint8 _item_type,uint _maxCount) external{
        require(_owner==msg.sender);
        if(_maxCount==0) _maxCount=2;  //默认一次尝试制作2件

        int _index=0;
        last_crafting_count=0;
        (last_crafter,last_check,last_cost,last_dc)= (0,0,0,0);
        for(uint i=0;i<_maxCount;i++){
            (uint _summoner,int _next,int _check,uint _cost,uint _dc)=_find_crafter_ready(_base_type,_item_type,uint(_index));
            if(_next<=_index) break;
            uint _takenId=_crafting.next_item();
            _crafting.craft(_summoner, _base_type, _item_type, 0);
            _crafting.transferFrom(address(this), _owner, _takenId); //直接发送到钱包
            
            (last_crafter,_index,last_check,last_cost,last_dc)= (_summoner,_next,_check,_cost,_dc);
            last_crafting_count++;
        }
    }


    //代理一次冒险
    function adventure_one(uint _summoner) external {
        require(_owner==msg.sender);
        _rm.adventure(_summoner);
    }
 
    //可冒险数量
    function adventure_count() external view returns (uint _count){
        _count=0;

        uint len = summoners.length;
        for (uint i = 0; i < len; i++) {
            uint _id=summoners[i];
            if(block.timestamp>_rm.adventurers_log(_id) ){
                _count++;
            }
        }
    }
    
    //冒险
    function adventure_all(uint _class, uint _maxCount) external {
        require(_owner==msg.sender);

        if(_maxCount==0) _maxCount=20;
        
        uint len = summoners.length;
        for (uint i = 0; i < len; i++) {
            uint _id=summoners[i];
            if(_class!=0 && _rm.class(_id)!=_class) continue; //跳过
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

        uint len = summoners.length;
        for (uint i = 0; i < len; i++) {
            uint _id=summoners[i];
            uint _level = _rm.level(_id);
            if( _rm.xp(_id)>= _rm.xp_required(_level) ){
                _count++;
            }
        }
    }

    //批量升级
    function level_up_all(uint _class_verify,uint _level_verify,uint _maxCount) external {
        require(_owner==msg.sender);
        if(_maxCount==0) _maxCount=20;

        uint len = summoners.length;
        for (uint i = 0; i < len; i++) {
            uint _id=summoners[i];
            if(_class_verify!=0 && _rm.class(_id)!=_class_verify) continue; //跳过
            uint _level=_rm.level(_id);
            if(_level_verify!=0 && _level!=_level_verify) continue; //跳过
            
            if( _rm.xp(_id)>= _rm.xp_required(_level) ){
                _rm.level_up(_id);
                _maxCount--;
                if(_maxCount==0) return;
            }
        }
    }

    function gold_approve_one(uint _from,uint _to,uint _val) external {
        require(_owner==msg.sender);
        _gold.approve(_from,_to,_val);
    }
    function gold_approve_batch(uint _to,uint _val, uint _start,uint _count) external {
        require(_owner==msg.sender);
        
        uint _len = summoners.length;
        if(_len>= (_start+_count) ){
            _len=_start+_count;
        }
        for (uint i = _start; i < _len; i++) {
            uint _from=summoners[i];
            _gold.approve(_from,_to,_val);
        }
    }



    //提取金币-单个
    function gold_claim_one(uint _summoner) external {
        require(_owner==msg.sender);
        _gold.claim(_summoner);
    }

    //批量提取金币
    function gold_claim_all(uint _class_verify,uint _level_verify,uint _maxCount) external {
        require(_owner==msg.sender);
        if(_maxCount==0) _maxCount=20;
        
        last_gold_claimed=0; //计数清零
        uint len = summoners.length;
        for (uint i = 0; i < len; i++) {
            uint _id=summoners[i];
            if(_class_verify!=0 && _rm.class(_id)!=_class_verify) continue; //跳过
            if(_level_verify!=0 && _rm.level(_id)!=_level_verify) continue; //跳过

            uint _gold_claimable=_gold.claimable(_id);
            if(_gold_claimable >0){
                _gold.claim(_id);
                last_gold_claimed+=_gold_claimable;
                _maxCount--;
                if(_maxCount==0) return;
            }
        }
    }

    //可提取金币的数量
    function gold_claim_count(uint _class) external view returns (uint _count){
        _count=0;

        uint len = summoners.length;
        for (uint i = 0; i < len; i++) {
            uint _id=summoners[i];
            if(_class!=0 && _rm.class(_id)!=_class) continue; //跳过
            if( _gold.claimable(_id)>0){
                _count++;
            }
        }
    }


    //分发金币
    function gold_tranfer_batch(uint _from,uint _start,uint _count,uint _val) external {
        require(_owner==msg.sender);
        
        uint _len = summoners.length;
        if(_len>= (_start+_count) ){
            _len=_start+_count;
        }
        for (uint i = _start; i < _len; i++) {
            uint _to=summoners[i];
            if( _to!=_from && _gold.balanceOf(_from)>= _val ){
                _gold.transfer(_from,_to,_val);
            }
        }
    }

    //汇总金币
    function gold_summary_batch(uint _to,uint _start,uint _count,uint _val) external {
        require(_owner==msg.sender);
        require(_rm.ownerOf(_to) == address(this) || _rm.ownerOf(_to) == _owner);
        
        uint _len = summoners.length;
        if(_len>= (_start+_count) ){
            _len=_start+_count;
        }
        for (uint i = _start; i<_len; i++) {
            uint _from=summoners[i];
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
        _total=0;
        uint _len = summoners.length;
        for (uint i = 0; i<_len; i++) {
            uint _from=summoners[i];
            _total+=_gold.balanceOf(_from);
        }
    }

    //需要加属性的数量
    function attr_uninit_count(uint _class) external view returns (uint _count){
        _count=0;

        uint len = summoners.length;
        for (uint i = 0; i < len; i++) {
            uint _id=summoners[i];
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
    function attr_init_all(uint _class,uint _maxCount) external{
        require(_owner==msg.sender);
        if(_maxCount==0) _maxCount=10;
        
        uint len = summoners.length;
        for (uint i = 0; i < len; i++) {
            uint _id=summoners[i];
            if(_class!=0 && _rm.class(_id)!=_class) continue; //跳过
            if( _aattr.character_created(_id) ) continue;
                
            _aattr.point_buy(_id,preset_attrs[0],preset_attrs[1],preset_attrs[2],preset_attrs[3],preset_attrs[4],preset_attrs[5]);
            _maxCount--;
            if(_maxCount==0) return;
        }
    }

    // //制造类加点
    // function attr_init_craft_all(uint _class,uint _maxCount) external{
    //     require(_owner==msg.sender);
    //     if(_maxCount==0) _maxCount=10;
        
    //     uint len = summoners.length;
    //     for (uint i = 0; i < len; i++) {
    //         uint _id=summoners[i];
    //         if(_class!=0 && _rm.class(_id)!=_class) continue; //跳过
    //         if( !_aattr.character_created(_id) ){
    //             _aattr.point_buy(_id, 8, 8,8, 22, 8, 8);
    //             _maxCount--;
    //             if(_maxCount==0) return;
    //         }
    //     }
    // }

    //人员数量汇总
    function summoner_count(uint _class) external view returns (uint _count){
        _count=0;
        uint len = summoners.length;
        for (uint i = 0; i < len; i++) {
            uint _id=summoners[i];
            if(_class!=0 && _rm.class(_id)!=_class) continue; //跳过
            _count++;
        }
    }


    //设置技能-单个
    function skills_set(uint _summoner) external {
        require(_owner==msg.sender);
        _skills.set_skills(_summoner, preset_skills);
    }

    //批量设置技能
    function skills_set_batch(uint _class,uint _start,uint _count) external {
        require(_owner==msg.sender);
        
        uint _len = summoners.length;
        if(_len>= (_start+_count) ){
            _len=_start+_count;
        }
        for (uint i = _start; i < _len; i++) {
            uint _tokenId=summoners[i];
            if(_class!=0 && _rm.class(_tokenId)!=_class) continue; //跳过
            _skills.set_skills(_tokenId,preset_skills); 
        }
    }
}