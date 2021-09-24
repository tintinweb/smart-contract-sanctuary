/**
 *Submitted for verification at Etherscan.io on 2021-09-24
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


// interface codex_base_random {
//     function d20(uint _summoner) external view returns (uint);
// }
interface rarity_crafting is IERC721Enumerable {
    function items(uint) external view returns (uint8, uint8, uint32, uint);
    //uint constant CRAFTING_SUMMMONER_ID=1758709;
    function next_item() external view returns (uint);
    function SUMMMONER_ID() external view returns (uint);
    function get_item_cost(uint _base_type, uint _item_type)  external view returns (uint cost);

    function craft(uint _summoner, uint8 _base_type, uint8 _item_type, uint _crafting_materials) external;
    function simulate(uint _summoner, uint _base_type, uint _item_type, uint _crafting_materials) external view returns (bool crafted, int check, uint cost, uint dc);
}

interface rarity_starter_pack is IERC721Enumerable{
    function sell_summoners(uint[] calldata summoners) external returns (uint proceeds);
    function sell_items(uint[] memory items) external returns (uint proceeds);
    function sell_all_items_between_ids(uint min_id, uint max_id) external returns (uint proceeds);

    function get_sellable_items_between_ids(address seller, uint min_id, uint max_id) external view returns (uint[] memory sellable);
    function get_needed_summoners() external view returns (uint[11] memory needed_summoners);

    //function filter_needed_summoners(uint[] calldata summoners) external view returns (uint[] memory needed_summoners) ;
}

//V2和V1不同,rarity都是存在合约中的,所以不需要授权之类的
contract rarity_starter_proxy is IERC721Receiver {
    // ropsten 测试网配置
    rarity public constant _rm = rarity(0x64A66c7FD681E94D4B54AAb08B3d4A5B2BBcC02D );
    rarity_attributes public constant _aattr = rarity_attributes( 0xf4537e2B4F2C1E5ee8a1fa57620D2808F716AB00);
    rarity_gold public constant _gold = rarity_gold(0xBA57FfE606BABE2dA0832d38977887643cB050Ec );
    rarity_crafting public constant _crafting = rarity_crafting(0x672dF7ee4C09F5a596D797A707619DfC4719ae23);
    rarity_starter_pack constant _starter_pack  = rarity_starter_pack(0x6F22ff8EDe99628914F8A58176E02798d9912391);
    

    //Fantom主网配置
    // rarity constant _rm = rarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb );
    // rarity_attributes constant _aattr = rarity_attributes( 0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);
    // rarity_gold constant _gold = rarity_gold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2 );
    // rarity_crafting constant _crafting = rarity_crafting(0xf41270836dF4Db1D28F7fd0935270e3A603e78cC);
    // rarity_starter_pack constant _starter_pack  = rarity_starter_pack(0xb3b96DF217e88Ee51513C0aBc036c3d0fC885EAA);

    address immutable _owner;


    uint[] private summoners;    //等待出售的英雄
    
    //所有本地址中的物品都是等待出售的物品


    constructor(){
        _owner=msg.sender;

        _rm.setApprovalForAll(address(_starter_pack), true);
        _crafting.setApprovalForAll(address(_starter_pack), true);
    }

    //代理合约内部的ERC721执行授权
    function setApprovalForAll(address _erc721_contact_addr,address operator, bool _approved) external{
        require(_owner==msg.sender);

        IERC721 _erc721=IERC721Enumerable(_erc721_contact_addr);
        _erc721.setApprovalForAll(operator, _approved);
    }

    receive() external payable {

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
    function erc721_withdraw_batch(address _erc721_contact_addr,uint[] memory _takenIds) external {
        require(_owner==msg.sender);
        _erc721_transfer(_erc721_contact_addr,_takenIds,_owner);
    }

    //可枚举的ERC721
    function _erc721_withdraw(address _erc721_contact_addr,uint _start,uint _count) internal {
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
    
    function erc721_widthdraw(address _erc721_contact_addr,uint _start,uint _count) external {
        require(_owner==msg.sender);
        _erc721_withdraw(_erc721_contact_addr,_start,_count);
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

    function withdraw() external{
        require(_owner==msg.sender);
        address _inner=address(this);
        
        if(_inner.balance>0){
            payable(_owner).transfer(_inner.balance);
        }
    }
    
    function summoner_total(int) external view returns (uint) {
        return summoners.length;
    }

    function summoner_statistics(uint) external view returns (uint48[11] memory) {
        uint48[11] memory _statistics=[1000000000000,2000000000000,3000000000000,4000000000000,5000000000000,
                                 6000000000000, 7000000000000,8000000000000,9000000000000,10000000000000,1100000000000];
        for (uint i = 0; i < summoners.length; i++) {
            uint _index=_rm.class(summoners[i])-1;
            _statistics[_index]++;
        }
        return _statistics;
    }

    function crafting_statistics(uint) external view returns (uint32[6] memory) {
        uint32[6] memory  _statistics=[203000000,208000000,215000000,327000000,338000000,344000000];

        uint _len=_crafting.balanceOf(address(this));

        for (uint i = 0; i < _len; i++) {
            uint _itemId=_crafting.tokenOfOwnerByIndex(address(this), i);
            (uint8 _base_type, uint8 _item_type,,) =_crafting.items(_itemId);
            if(_base_type==2){
                if(_item_type==3){
                    _statistics[0]++;
                }else  if(_item_type==8){
                    _statistics[1]++;
                }else  if(_item_type==15){
                    _statistics[2]++;
                }
            }else if(_base_type==3){
                if(_item_type==27){
                    _statistics[3]++;
                }else  if(_item_type==38){
                    _statistics[4]++;
                }else  if(_item_type==44){
                    _statistics[5]++;
                }
            }
                uint _index=_rm.class(summoners[i])-1;
                _statistics[_index]++;
        }
        return _statistics;
    }


    function summoners_list(uint mode) external view returns (uint[] memory){
        if(mode==0){
            return summoners;
        }else{
            uint[] memory _items=new uint[](summoners.length);
            for (uint i = 0; i < summoners.length; i++) {
                _items[i]=summoners[i]+ (_rm.class(summoners[i])*100+_rm.level(summoners[i]))*1000000000000;  //职业(XX)+等级(XX)+ 12位数字是ID
            }
            return _items;
        }
    }

    //显示可出售英雄
    function summoners_list_sellable(uint) external view returns (uint[] memory){
        uint[11] memory _needed_summoners=_starter_pack.get_needed_summoners();
        
        uint[] memory _summoners=new uint[](summoners.length);
        for(uint i=0;i< summoners.length;i++){
            uint _summoner=summoners[i];
            if(_summoner==0) continue;

            uint _classIndex=_rm.class(summoners[i])-1;
            if( _needed_summoners[_classIndex]>0){
                _needed_summoners[_classIndex]--;
                _summoners[i]=_summoner;
            }
        }
        return _summoners;
    }


    //保存到内部列表
    function _summoner_save(uint _summoner) internal{
        for(uint i=0;i<summoners.length;i++){
            if(summoners[i]==0){
                summoners[i]=_summoner;
                return;
            }
        }
        summoners.push(_summoner);
    }

    //存入英雌
    function summoner_dispose(uint[] memory _takenIds) external{
        require(_owner==msg.sender);
        address _inner=address(this);
        for(uint i=0;i<_takenIds.length;i++){
            uint _summoner=_takenIds[i];

            //只有符合条件的英雄才可以进入
            if(_aattr.character_created(_summoner) ) continue;

            //自动升级
            if(_rm.level(_summoner)==1 && _rm.xp(_summoner)>=1000e18){
            //    _rm.level_up(_summoner);               
            }
            if( _rm.level(_summoner)!=2 ) continue;
            uint _claim_gold=_gold.claimable(_summoner);
            uint _balance_gold=_gold.balanceOf(_summoner);
            if( (_claim_gold+_balance_gold ) < 1000e18) continue;
                
            //_rm.transferFrom(msg.sender,_inner,_takenIds[i]);
            _summoner_save(_takenIds[i]);
            //如有必要,提取黄金
            //if(_balance_gold< 1000e18){
            //    _gold.claim(_summoner);
            //}
            
        }
    }
    
    
    function _summoner_remove(uint _start,uint _count) internal{
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

    function _summoner_transfer(uint _start,uint _count,address _to) internal {
        address _inner=address(this);
        uint _eof=summoners.length;
        if(_eof>(_start+_count) ){
            _eof=_start+_count;
        }
        for(uint _i=_start;_i<_eof;_i++){
            if(summoners[_i]!=0){
                _rm.transferFrom(_inner,_to,summoners[_i]);
            }
        }
        _summoner_remove(_start,_count);
    }
    function summoner_withdraw(uint _start,uint _count) external {
        require(_owner==msg.sender);
        _summoner_transfer(_start,_count,_owner);
    }

   
    function _adjust_summoners() internal{
        //整理summoners
        uint _eof=0;
        for(uint i=0;i<summoners.length;i++){
            if(summoners[i]!=0){
                _eof++;
            }
        }
        
        uint[] memory _summoners=new uint[](_eof);
        uint j=0;
        for(uint i=0;i<summoners.length;i++){
            if(summoners[i]!=0){
                _summoners[j++]=_summoners[i];
            }
        }
        summoners=_summoners;
    }

    //出售英雄
    function _sell_summoners_all() internal{
        uint[11] memory _needed_summoners=_starter_pack.get_needed_summoners();
        
        uint[] memory _summoners=new uint[](summoners.length);
        uint _eof=0;
        for(uint i=0;i<summoners.length;i++){
            uint _summoner=summoners[i];
            if(_summoner==0) continue;

            uint _classIndex=_rm.class(summoners[i])-1;
            if( _needed_summoners[_classIndex]>0){
                _needed_summoners[_classIndex]--;
                _summoners[_eof++]=_summoner;
                summoners[i]=0; //清空英雄id, 但暂时不删除这个元素
            }
        }
        
      
        if(_eof>0){
            //压缩_summoners
            uint[] memory _summoners_compack=new uint[](_eof);
            for(uint i=0;i<_eof;i++){
                _summoners_compack[i]=_summoners[i];
            }
            _starter_pack.sell_summoners(_summoners_compack);
                    
           //整理summoners
            _adjust_summoners();
        }

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

    function crafting_total(int) public view returns (uint) {
        return _crafting.balanceOf(address(this));
    }
    
    function crafting_list_all(uint mode) external view returns (uint[] memory){
        uint _count = _crafting.balanceOf(address(this));
        uint[] memory _items=new uint[](_count);
        if(mode==0){
            for (uint i = 0; i < _count; i++) {
                _items[i]= _crafting.tokenOfOwnerByIndex(address(this), i);
            }
        }else { //带属性
            for (uint i = 0; i < _count; i++) {
                uint _crafting_id = _crafting.tokenOfOwnerByIndex(address(this), i);
                (uint _base_type,uint _item_type,,)=_crafting.items(_crafting_id);
                 _items[i]= _crafting_id+ (_base_type*100 + _item_type)*1000000000000;  //大类(XX)+小类(XX)+ 12位数字是ID
            }
        }
        return _items;
    }

    //显示可出售物品
    function crafting_list_sellable(uint)  external view returns (uint[] memory){
        return _starter_pack.get_sellable_items_between_ids(address(this), 0,100000000);
    }

    function crafting_dispose(uint[] memory _takenIds) external{
        require(_owner==msg.sender);
        address _inner=address(this);
        for(uint i=0;i<_takenIds.length;i++){
            bool _ok=false;
            (uint8 _base_type, uint8 _item_type,,) = _crafting.items(_takenIds[i]);
            if (_base_type == 2) {
                if (_item_type == 3) {
                    _ok=true;
                } else if (_item_type == 8) {
                    _ok=true;
                } else if (_item_type == 15) {
                    _ok=true;
                }
            } else if (_base_type == 3) {
                if (_item_type == 38) {
                    _ok=true;
                } else if (_item_type == 44) {
                    _ok=true;
                } else if (_item_type == 27) {
                    _ok=true;
                }
            }
            if(_ok){
                _crafting.transferFrom(msg.sender,_inner,_takenIds[i]);
            }
        }
    }
    function crafting_withdraw(uint _start,uint _count) external {
        require(_owner==msg.sender);
        _erc721_withdraw(address(_crafting),_start,_count);
    }

    
    function _sell_crafting_all() internal{
        uint[] memory _craftings= _starter_pack.get_sellable_items_between_ids(address(this), 0,100000000);
        if(_craftings.length>0){
            _starter_pack.sell_items(_craftings);
        }
    }

    //出售物品
    function sell_crafting(uint[] memory _craftings)  external {
        require(_owner==msg.sender);
        _starter_pack.sell_items(_craftings);
    }

    //一次性出售所有
    function sell_all() external{
        require(_owner==msg.sender);
        _sell_summoners_all();
        _sell_crafting_all();
    }
}