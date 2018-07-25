pragma solidity ^0.4.24;

contract ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

//------------------------------------------------------------------------------
contract _Base {
    address internal    owner;
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    event PACK(address indexed, address indexed, address indexed);  // pack,creator,store
    event INFO(bytes _msgPack);
    function info(bytes _msgPack) onlyOwner public {
        emit INFO(_msgPack);
    }
}

//------------------------------------------------------------------------------
// Pack is group of items.
// Pack has information of pack and items.
//------------------------------------------------------------------------------
contract Pack is _Base {
    address internal    store;
    
    constructor (address _creator, bytes _msgPack) public {
        owner   = _creator;
        store   = msg.sender;
        emit INFO(_msgPack);
        emit PACK(this,owner,store);
    }
    
    modifier onlyStore() {
        require(msg.sender==store);
        _;
    }

    event ITEM(uint indexed _index, uint length, bytes _msgPack);
    function item(uint _index, uint _length, bytes _msgPack) onlyStore public {
        emit ITEM(_index,_length,_msgPack);
    }

    event BUY(address indexed, uint indexed, uint, uint);
    function buy(address _buy, uint _item, uint _creator, uint _shop) onlyStore public {
        emit BUY(_buy,_item,_creator,_shop);
    }
}
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// _Account is root of Creator and Store.
// for transfer erc20 and eth.
// and it has information of contract.
//------------------------------------------------------------------------------
contract _Account is _Base {
    address internal    manager;

    constructor () public {
        manager = msg.sender;
    }
    function ownerShip(address _owner) public {
        require(msg.sender==manager);
        owner   = _owner;
    }

    function () payable public {}

    function balanceOf(address _erc20) public constant returns (uint256) {
        return (_erc20==address(0)?address(this).balance:ERC20Interface(_erc20).balanceOf(this));
    }
    function transfer(address _to, address _erc20, uint256 _value) internal returns (bool success) {
        if(_erc20==address(0))
            _to.transfer(_value);
        else
            ERC20Interface(_erc20).transfer(_to,_value);
        return true;
    }
    function withdrawal(address _erc20, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf(_erc20)>=_value);
        return transfer(owner,_erc20,_value);
    }
}
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
contract Creator is _Account {
    constructor (address _owner,bytes _msgPack) public {
        owner   = _owner;
        emit INFO(_msgPack);
    }
    
    modifier isStore(address _store) {
        require(Manager(manager).storeOwner(_store)!=address(0));
        _;
    }

    function pack(address _store, bytes _msgPack) onlyOwner isStore(_store) public {
        emit PACK(Store(_store).pack(_msgPack),this,_store);
    }
    function packInfo(address _pack, bytes _msgPack) onlyOwner public {
        Pack(_pack).info(_msgPack);
    }
    function item(address _store, address _pack, uint _price, bool _weekly, bytes _msgPack) onlyOwner isStore(_store) public {
        Store(_store).item(_pack,_price,_weekly,_msgPack);
    }
    function itemPrice(address _store, address _pack, uint _item, uint _price) onlyOwner isStore(_store)  public {
        Store(_store).itemPrice(_pack,_item,_price);
    }
    function itemInfo(address _store, address _pack, uint _item, bytes _msgPack) onlyOwner isStore(_store) public {
        Store(_store).itemInfo(_pack,_item,_msgPack);
    }
}
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
contract Store is _Account, SafeMath {
    struct _item {
        uint                    price;
        bool                    weekly;
        uint                    income;

        uint                    count;
        uint                    pointUp;
        uint                    pointDn;

        mapping(address=>bool)  vote;
        mapping(address=>uint)  user;
    }
    struct _pack {
        address                 creator;
        _item[]                 items;
    }

    mapping(address=>_pack)     packs;

    uint        share;
    uint        shareStart;
    address     erc20;
    constructor (address _owner,bytes _msgPack,uint _share, uint _shareStart,address _erc20) public {
        owner       = _owner;
        share       = _share;
        shareStart  = _shareStart;
        erc20       = _erc20;
        emit INFO(_msgPack);
    }

    function status() constant public returns (uint,uint,address) {
        return (share,shareStart,erc20);
    }

    function pack(bytes _msgPack) public returns (address) {
        require(Manager(manager).creatorOwner(msg.sender)!=address(0));
        address temp        = new Pack(msg.sender,_msgPack);
        packs[temp].creator = msg.sender;
        emit PACK(temp,msg.sender,this);
        return temp;
    }
    
    function item(address _p, uint _price, bool _weekly, bytes _msgPack) public {
        require(packs[_p].creator==msg.sender);
        packs[_p].items.push(_item(_price,_weekly,0,0,0,0));
        Pack(_p).item(packs[_p].items.length-1,packs[_p].items.length,_msgPack);
    }
    function itemPrice(address _p, uint _i, uint _price) public {
        require(packs[_p].creator==msg.sender);
        require(packs[_p].items.length>_i);
        packs[_p].items[_i].price   = _price;
    }
    function itemInfo(address _p, uint _i, bytes _msgPack) public {
        require(packs[_p].creator==msg.sender);
        require(packs[_p].items.length>_i);
        Pack(_p).item(_i, packs[_p].items.length, _msgPack);
    }
    
    function itemCanVote(address _p, uint _i) constant public returns (bool) {
        return !packs[_p].items[_i].vote[msg.sender] && (packs[_p].items[_i].user[msg.sender] > 0);
    }
    function itemVoteUp(address _p, uint _i) public {
        require(packs[_p].items.length>_i);
        require(itemCanVote(_p,_i));
        packs[_p].items[_i].pointUp             = safeAdd(packs[_p].items[_i].pointUp,1);
        packs[_p].items[_i].vote[msg.sender]    = true;
    }
    function itemVoteDn(address _p, uint _i) public {
        require(packs[_p].items.length>_i);
        require(itemCanVote(_p,_i));
        packs[_p].items[_i].pointDn             = safeAdd(packs[_p].items[_i].pointUp,1);
        packs[_p].items[_i].vote[msg.sender]    = true;
    }
    function about(address _p, uint _i) constant public returns (uint,bool,uint,uint,uint,bool,bool) {
        require(packs[_p].items.length>_i);
        return (packs[_p].items[_i].price,packs[_p].items[_i].weekly,packs[_p].items[_i].count,packs[_p].items[_i].pointUp,packs[_p].items[_i].pointDn,canBuy(_p,_i),canUse(_p,_i));
    }

    function buy(address _p, uint _i) payable public {
        require(canBuy(_p,_i));
        require((erc20==address(0)?msg.value:ERC20Interface(erc20).allowance(msg.sender,this))==packs[_p].items[_i].price);
        
        if(erc20!=address(0))
            ERC20Interface(erc20).transferFrom(msg.sender,this,packs[_p].items[_i].price);

        packs[_p].items[_i].user[msg.sender]    = safeAdd(packs[_p].items[_i].user[msg.sender], 1 weeks) < now ? now : safeAdd(packs[_p].items[_i].user[msg.sender], 1 weeks);
        packs[_p].items[_i].income              = safeAdd(packs[_p].items[_i].income,packs[_p].items[_i].price);
        
        uint creator    = 0;
        
        if(packs[_p].items[_i].income>=shareStart)
            creator = safeDiv(safeMul(packs[_p].items[_i].price,share),100);
        
        if(packs[_p].items[_i].user[msg.sender]==0)
            packs[_p].items[_i].count   = safeAdd(packs[_p].items[_i].count,1);
        
        Pack(_p).buy(msg.sender,_i,creator,safeSub(packs[_p].items[_i].price,creator));
        
        if(creator>0)
            transfer(packs[_p].creator,erc20,creator);
    }
    function canBuy(address _p, uint _i) constant public returns(bool) {
        return  packs[_p].items.length>_i &&
                packs[_p].items[_i].price>0&&
                !(!packs[_p].items[_i].weekly&&packs[_p].items[_i].user[msg.sender]>0);
    }
    function canUse(address _p, uint _i) constant public returns(bool) {
        return  packs[_p].items.length>_i &&
                ( packs[_p].items[_i].price==0||
                 (packs[_p].items[_i].weekly&&safeAdd(packs[_p].items[_i].user[msg.sender], 1 weeks)>=now)||
                 (!packs[_p].items[_i].weekly&&packs[_p].items[_i].user[msg.sender]>0));
    }
}
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
contract Manager {
    mapping(address=>address) creators;
    event CREATOR(address indexed _creator, address indexed _owner, address indexed _from);
    function creator(bytes _msgPack) public returns (address) {
        address temp    = new Creator(msg.sender,_msgPack);
        creators[temp]  = msg.sender;
        emit CREATOR(temp,msg.sender,address(0));
        return temp;
    }
    function creatorOwner(address _creator) public constant returns (address){
        return creators[_creator];
    }
    function creatorOwnership(address _creator, address _owner) public {
        require(creators[_creator]==msg.sender&&address(0)!=_owner);
        creators[_creator]  = _owner;
        Creator(_creator).ownerShip(_owner);
        emit CREATOR(_creator,_owner,msg.sender);
    }
    
    mapping(address=>address) stores;
    event STORE(address indexed _store, address indexed _to, address indexed _from);
    event TOKEN(address indexed _store, address indexed _erc20);
    function store(bytes _msgPack,uint _share, uint _shareStart,address _erc20) public returns (address _shop) {
        address temp    = new Store(msg.sender,_msgPack,_share,_shareStart,_erc20);
        stores[temp]    = msg.sender;
        emit STORE(temp,msg.sender,address(0));
        emit TOKEN(temp,_erc20);
        return temp;
    }
    function storeOwner(address _store) public constant returns (address){
        return stores[_store];
    }
    function storeOwnership(address _store, address _owner) public {
        require(stores[_store]==msg.sender&&address(0)!=_owner);
        stores[_store]     = _owner;
        Store(_store).ownerShip(_owner);
        emit STORE(_store,_owner,msg.sender);
    }
}
//------------------------------------------------------------------------------