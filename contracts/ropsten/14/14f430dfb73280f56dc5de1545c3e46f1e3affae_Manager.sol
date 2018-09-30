pragma solidity ^0.4.24;

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

contract _ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract _ApproveAndCallFallBack {
    function () public payable {revert();}  // Don&#39;t accept ETH
    function erc20() public constant returns (address);
    function spender() public constant returns (address);
    function receiveApproval(uint256[] _data) payable public;
    function receiveApproval(bytes _msgPack) payable public;
}

contract Wallet {
    address public                          owner;
    address public                          newOwner;
    mapping (address => uint256) private    allowed;

    event OWNER(address indexed _from, address indexed _to);
    constructor(address _owner) public {
        if(_owner==address(0))
            owner     = msg.sender;
        else
            owner     = _owner;
        emit OWNER(address(0),owner);
    }
    function () public payable {}

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // --------------------------------------------------------
    // owership transfer
    // --------------------------------------------------------
    function transferOwner(address _next) onlyOwner public {
        newOwner = _next;
    }
    function confirmTransferOwner() public {
        require(msg.sender == newOwner);
        emit OWNER(owner, newOwner);
        owner       = newOwner;
        newOwner   = address(0);
    }
    function undoTransferOwner() onlyOwner public {
        newOwner   = address(0);
    }
    function isOwnner(address _who) constant public returns (bool) {
        return owner==_who;
    }
    // --------------------------------------------------------

    // --------------------------------------------------------
    // register information
    // --------------------------------------------------------
    event INFO(bytes _msgPack);
    function info(bytes _msgPack) onlyOwner public {
        emit INFO(_msgPack);
    }
    // --------------------------------------------------------

    //-------------------------------------------------------
    // erc20 interface
    //-------------------------------------------------------
    function balanceOf(address _erc20) public constant returns (uint balance) {
        if(_erc20==address(0))
            return address(this).balance;
        return _ERC20Interface(_erc20).balanceOf(this);
    }
    function transfer(address _erc20, address _to, uint _tokens) onlyOwner public returns (bool success) {
        require(balanceOf(_erc20)>=_tokens);
        if(_erc20==address(0))
            _to.transfer(_tokens);
        else
            return _ERC20Interface(_erc20).transfer(_to,_tokens);
        return true;
    }
    function approve(address _erc20, address _spender, uint _tokens) onlyOwner public returns (bool success) {
        require(_erc20 != address(0));
        return _ERC20Interface(_erc20).approve(_spender,_tokens);
    }
    // todo
    // approve cancel

    //-------------------------------------------------------
    // pay interface
    //-------------------------------------------------------
    function pay(address _store, uint _tokens, uint256[] _options) onlyOwner public {
        address erc20   = _ApproveAndCallFallBack(_store).erc20();
        address spender = _ApproveAndCallFallBack(_store).spender();
        if(erc20 == address(0)) {
            transfer(erc20,spender,_tokens);
            _ApproveAndCallFallBack(_store).receiveApproval(_options);
        } else {
            _ERC20Interface(erc20).approve(spender,_tokens);
            _ApproveAndCallFallBack(_store).receiveApproval(_options);
        }
    }
    function pay(address _store, uint _tokens, bytes _msgPack) onlyOwner public {
        address erc20   = _ApproveAndCallFallBack(_store).erc20();
        address spender = _ApproveAndCallFallBack(_store).spender();
        if(erc20 == address(0)) {
            transfer(erc20,spender,_tokens);
            _ApproveAndCallFallBack(_store).receiveApproval(_msgPack);
        } else {
            _ERC20Interface(erc20).approve(spender,_tokens);
            _ApproveAndCallFallBack(_store).receiveApproval(_msgPack);
        }
    }
}

contract _Manager {
    function owner(address _contract) constant public returns (address);
}
contract _Base {
    address internal                manager;

    constructor(bytes _msgPack) public {
        manager     = msg.sender;
        emit INFO(_msgPack);
    }

    modifier onlyOwner() {
        require(msg.sender==_Manager(manager).owner(this));
        _;
    }

    // register information
    event INFO(bytes _msgPack);
    function info(bytes _msgPack) onlyOwner public {
        emit INFO(_msgPack);
    }
}

contract Creator is _Base {
    constructor(bytes _msgPack) _Base(_msgPack) public {}
    function about() constant public returns(address,bool) {
        return (Manager(manager).owner(this),Manager(manager).copyright(this));
    }
    
    function () public payable {}
    //-------------------------------------------------------
    // erc20 interface
    //-------------------------------------------------------
    function balanceOf(address _erc20) public constant returns (uint balance) {
        if(_erc20==address(0))
            return address(this).balance;
        return _ERC20Interface(_erc20).balanceOf(this);
    }
    function transfer(address _erc20, address _to, uint _tokens) onlyOwner public returns (bool success) {
        require(balanceOf(_erc20)>=_tokens);
        if(_erc20==address(0))
            _to.transfer(_tokens);
        else
            return _ERC20Interface(_erc20).transfer(_to,_tokens);
        return true;
    }
    function approve(address _erc20, address _spender, uint _tokens) onlyOwner public returns (bool success) {
        require(_erc20 != address(0)); 
        return _ERC20Interface(_erc20).approve(_spender,_tokens);
    }

    //-------------------------------------------------------
    // avatar
    //-------------------------------------------------------
    function avatar(address _store, uint _tokens, bytes _msgPack) onlyOwner public {
        address erc20   = _ApproveAndCallFallBack(_store).erc20();
        address spender = _ApproveAndCallFallBack(_store).spender();
        if(erc20 == address(0)) {
            transfer(erc20,spender,_tokens);
            _ApproveAndCallFallBack(_store).receiveApproval(_msgPack);
        } else {
            _ERC20Interface(erc20).approve(spender,_tokens);
            _ApproveAndCallFallBack(_store).receiveApproval(_msgPack);
        }
    }
}

contract Pack is _Base, _ApproveAndCallFallBack, SafeMath {
    struct _item {
        uint256                     price;
        bool                        weekly;
        uint256                     income;

        uint256                     pointUp;
        uint256                     pointDn;

        mapping(address=>bool)      vote;
        mapping(address=>uint256)   user;
    }

    _item[]                 items;
    uint256                 _income;

    constructor(bytes _msgPack) _Base(_msgPack) public {}

    modifier safeRange(uint256 _index) {
        require(items.length>_index);
        _;
    }

    // vote up & down
    function canVote(uint256 _index) constant public returns (bool) {
        return !items[_index].vote[msg.sender] && (items[_index].user[msg.sender] > 0);
    }
    function voteUp(uint256 _index) safeRange(_index) public {
        require(canVote(_index));
        items[_index].pointUp             = safeAdd(items[_index].pointUp,1);
        items[_index].vote[msg.sender]    = true;
    }
    function voteDn(uint256 _index) safeRange(_index) public {
        require(canVote(_index));
        items[_index].pointDn             = safeAdd(items[_index].pointUp,1);
        items[_index].vote[msg.sender]    = true;
    }

    // about pack
    function price(uint256 _index) safeRange(_index) constant public returns (uint256) {
        return items[_index].price;
    }
    function length() constant public returns (uint256) {
        return items.length;
    }
    function income() constant public returns (uint256) {
        return _income;
    }
    // about item
    function about() constant public returns (address,bool) {
        return (Manager(manager).owner(this),Manager(manager).copyright(this));
    }
    function aboutItem(uint256 _index) safeRange(_index) constant public returns (uint256,bool,uint256,uint256,uint256,bool,bool) {
        return (price(_index),items[_index].weekly,items[_index].pointUp,items[_index].pointDn,length(),canBuy(_index),canUse(_index));
    }

    // add item
    event ITEM(uint indexed _index, bytes _msgPack);
    function item(uint256 _price, bool _weekly, bytes _msgPack) onlyOwner public {
        emit ITEM(items.length,_msgPack);
        items.push(_item(_price,_weekly,0,0,0));
    }
    // info item
    function editInfo(uint256 _index, bytes _msgPack) onlyOwner safeRange(_index) public {
        emit ITEM(_index,_msgPack);
    }
    // price item
    function editPrice(uint256 _index, uint _price) onlyOwner safeRange(_index) public {
        items[_index].price   = _price;
    }

    // copyright
    function copyright(address _who) constant private returns (bool) {
        return Manager(manager).copyright(_who);
    }

    // can buy
    function canBuy(uint256 _index) safeRange(_index) constant public returns (bool) {
        return (copyright(this)&&
                copyright(Manager(manager).owner(this))&&
                copyright(Manager(manager).packStore(this))&&
                items[_index].price>0&&
                !(!items[_index].weekly&&items[_index].user[msg.sender]>0));
    }

    // can use
    function canUse(uint256 _index) safeRange(_index) constant public returns (bool) {
        return  (copyright(this)&&
                 items[_index].price==0||
                 items[_index].weekly&&safeAdd(items[_index].user[msg.sender], 1 weeks)>=now)||
                 (!items[_index].weekly&&items[_index].user[msg.sender]>0);
    }
    // buy
    event BUY(address indexed _store, address indexed _user, uint indexed _index, uint256, uint256);
    function buy(uint256 _index, address _user, uint256 _creator, uint256 _Store) safeRange(_index) public {
        require(Manager(manager).packStore(this)==msg.sender);
        items[_index].user[_user]   = safeAdd(items[_index].user[_user], 1 weeks) < now ? now : safeAdd(items[_index].user[_user], 1 weeks);
        items[_index].income        = safeAdd(items[_index].income,items[_index].price);
        _income                     = safeAdd(_income,items[_index].price);
        emit BUY(msg.sender,_user,_index,_creator,_Store);
    }
    
    // _ApproveAndCallFallBack
    function erc20() public constant returns (address) {
        bool    _copyright;
        address _erc20;
        (_copyright,_erc20) = Store(Manager(manager).packStore(this)).currency();
        require(_copyright);
        return _erc20;
    }
    function spender() public constant returns (address) {
        return Manager(manager).packStore(this);
    }
    function receiveApproval(uint256[] _data) payable public {
        require(_data.length==1);
        Store(Manager(manager).packStore(this)).receiveApproval(msg.sender,_data[0]);
    }
    function receiveApproval(bytes _msgPack) payable public {
        revert();
    }
}

contract Store is _Base, SafeMath {
    struct _info {
        uint8                       share;
        uint256                     shareStart;

        bool                        canMove;
        mapping(uint256=>uint256)   incomes;
    }

    address                     erc20;
    mapping(address=>_info)     packs;

    uint256                     totalSupply;
    mapping(address=>uint256)   coupons;

    modifier onlyManager() {
        require(msg.sender==manager);
        _;
    }

    constructor(bytes _msgPack,address _erc20) _Base(_msgPack) public {
        erc20       = _erc20;
    }

    // about
    function currency() constant public returns (bool,address) {
        return (Manager(manager).copyright(this), erc20);
    }
    function about() constant public returns (address,bool,address,uint256,uint256) {
        return (Manager(manager).owner(this),Manager(manager).copyright(this),erc20,coupons[msg.sender],totalSupply);
    }

    // coupon
    event COUPON(address indexed _to, uint256 _count);
    function coupon(address _to, uint256 _count) onlyOwner public {
        coupons[_to]    = safeAdd(coupons[_to],_count);
        totalSupply     = safeAdd(totalSupply,_count);
        emit COUPON(_to,_count);
    }

    // pack
    function add(address _pack, uint8 share, uint256 shareStart) onlyManager public {
        packs[_pack]    = _info(share,shareStart,false);
    }
    function remove(address _pack) onlyManager public {
        delete packs[_pack];
    }
    function approveMove(address _pack, bool _allow) onlyOwner public {
        packs[_pack].canMove = _allow;
    }
    function canMove(address _pack) constant public returns (bool) {
        return packs[_pack].canMove;
    }

    // buy
    function balanceOf(address _erc20, address _tokenOwner) private constant returns (uint balance) {
        if(_erc20==address(0))
            return address(this).balance;
        return _ERC20Interface(_erc20).balanceOf(_tokenOwner);
    }
    function min(uint256 _a, uint256 _b) private pure returns (uint256) {
        if(_a>_b)
            return _b;
        return _a;
    }
    function buy(address _user, address _contract, uint256 _price, uint256 _value, uint256 _index) private {
        if(_value==0) {
            coupons[_user]  = safeSub(coupons[_user],1);
            totalSupply     = safeSub(totalSupply,1);
            Pack(_contract).buy(_index,_user,0,0);
        } else {
            if(erc20!=address(0))
                _ERC20Interface(erc20).transferFrom(_user,this,_price);

            uint256 creator = 0;

            if(packs[_contract].incomes[_index]>=packs[_contract].shareStart)
                creator = safeDiv(safeMul(_price,packs[_contract].share),100);

            uint256 store   = safeSub(_price,creator);

            packs[_contract].incomes[_index]   = safeAdd(packs[_contract].incomes[_index],store);
            Pack(_contract).buy(_index,_user,creator,store);

            if(creator>0) {
                if(erc20==address(0))   Manager(manager).owner(_contract).transfer(creator);
                else                    _ERC20Interface(erc20).transfer(Manager(manager).owner(_contract),creator);
            }
            if(store>0) {
                if(erc20==address(0))   Manager(manager).owner(this).transfer(store);
                else                    _ERC20Interface(erc20).transfer(Manager(manager).owner(this),store);
            }
        }        
    }
    function receiveApproval(address _user, uint256 _index) payable public {
        require(Manager(manager).packStore(msg.sender)==address(this));
        uint256 _price  = Pack(msg.sender).price(_index);
        uint256 _value  = min(erc20==address(0) ? msg.value : _ERC20Interface(erc20).allowance(_user,this),balanceOf(erc20,_user));
        require((_value>0&&_value>=_price)||(_value==0&&coupons[_user]>0));
        require(Pack(msg.sender).canBuy(_index)&&Manager(manager).copyright(this));
        
        buy(_user, msg.sender, _price, _value, _index);
    }
    function buy(address _contract, uint256 _index) payable public {
        require(Manager(manager).packStore(_contract)==address(this));
        uint256 _price  = Pack(_contract).price(_index);
        uint256 _value  = min(erc20==address(0) ? msg.value : _ERC20Interface(erc20).allowance(msg.sender,this),balanceOf(erc20,msg.sender));
        require((_value>0&&_value>=_price)||(_value==0&&coupons[msg.sender]>0));
        require(Pack(_contract).canBuy(_index)&&Manager(manager).copyright(this));
        
        buy(msg.sender, _contract, _price, _value, _index);
    }
}

contract Manager {
    enum CLASS   {NONE,CREATOR,STORE,PACK}
    struct _info {
        CLASS       class;
        address     owner;
        bool        copyright;
    }
    address                     master;
    mapping(address=>_info)     infos;

    constructor() public {
        master = msg.sender;
    }

    modifier onlyMaster() {
        require(msg.sender==master);
        _;
    }
    modifier onlyOwner(address _contract) {
        require(msg.sender==infos[_contract].owner);
        _;
    }

    function newMaster(address _next) onlyMaster public {
        require(_next!=address(0)&&_next!=address(this)&&_next!=master&&infos[_next].class==CLASS.NONE);
        master = _next;
    }

    function owner(address _who) constant public returns (address) {
        return infos[_who].owner;
    }
    function copyright(address _who) constant public returns (bool) {
        return infos[_who].copyright;
    }

    // about
    function about(address _who) constant public returns(CLASS,bool,address,address) {
        return (infos[_who].class,infos[_who].copyright,infos[_who].owner,packs[_who]);
    }

    // change copyright
    function enable(address _contract, bool _enable) onlyMaster public {
        infos[_contract].copyright  = _enable;
    }
    // change Owner
    function newOwner(address _contract, address _next) onlyOwner(_contract) public {
        require(infos[_contract].class!=CLASS.NONE&&_next!=address(0)&&_next!=address(this)&&_next!=master&&infos[_next].class==CLASS.NONE);
        if(infos[_contract].class==CLASS.CREATOR)       emit CREATOR(_contract,_next,infos[_contract].owner);
        else if(infos[_contract].class==CLASS.STORE)    emit STORE(_contract,_next,infos[_contract].owner);
        else if(infos[_contract].class==CLASS.PACK)     emit PACK(_contract,_next,infos[_contract].owner);
        infos[_contract].owner  = _next;
    }

    // create creator
    event CREATOR(address indexed _contract, address indexed _to, address indexed _from);
    function creator(bytes _msgPack) public {
        address temp    = new Creator(_msgPack);
        infos[temp]     = _info(CLASS.CREATOR,msg.sender,true);
        emit CREATOR(temp,msg.sender,address(0));
    }

    // create store
    event STORE(address indexed _contract, address indexed _to, address indexed _from);
    function store(bytes _msgPack, address _erc20) public {
        address temp    = new Store(_msgPack,_erc20);
        infos[temp]     = _info(CLASS.STORE,msg.sender,true);
        emit STORE(temp,msg.sender,address(0));
    }

    // create pack
    mapping(address=>address)   packs;
    event PACK(address indexed _contract, address indexed _to, address indexed _from);
    event PACK2(address indexed _pack, address indexed _to, address indexed _from);
    function pack(bytes _msgPack, address _creator, address _store, uint8 _share, uint256 _shareStart) public {
        require(infos[_creator].class==CLASS.CREATOR&&infos[_store].class==CLASS.STORE&&infos[_store].owner==msg.sender&&_share<101);
        address temp    = new Pack(_msgPack);
        infos[temp]     = _info(CLASS.PACK,_creator,true);
        packs[temp]     = _store;
        Store(_store).add(temp,_share,_shareStart);
        emit PACK(temp,_creator,address(0));
        emit PACK2(temp,_store,address(0));
    }
    function move(address _pack, address _next, uint8 _share, uint256 _shareStart) public {
        require(packs[_pack]!=address(0)&&infos[_pack].owner==msg.sender&&infos[_next].class==CLASS.STORE);
        require(Store(packs[_pack]).canMove(_pack));
        Store(packs[_pack]).remove(_pack);
        Store(_next).add(_pack,_share,_shareStart);
        emit PACK2(_pack,_next,packs[_pack]);
        packs[_pack]    = _next;
    }
    function packStore(address _pack) constant public returns(address) {
        return packs[_pack];
    }
}