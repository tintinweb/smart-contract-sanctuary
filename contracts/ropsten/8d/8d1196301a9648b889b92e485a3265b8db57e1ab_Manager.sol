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


contract Badge is _Base {
    constructor(bytes _msgPack) _Base(_msgPack) public {}
    // register asset
    event ASSET(uint8 indexed _index, string _title, bytes _img);
    function asset(uint8 _index, string _title, bytes _image) onlyOwner public {
        require(_index>0);
        emit ASSET(_index,_title,_image);
    }
}

contract Avatar is _Base, _ApproveAndCallFallBack, SafeMath {
    constructor(bytes _msgPack) _Base(_msgPack) public {}
    // register asset
    uint256                         index;
    event ASSET(uint256 indexed _category, uint256 indexed _index, bytes _img);
    function asset(uint256 _category, bytes _image) onlyOwner public {
        emit ASSET(_category,index,_image);
        index   = safeAdd(index,1);
    }
    event SETTING(bytes _msgPack);
    function setting(bytes _msgPack) onlyOwner public {
        emit SETTING(_msgPack);
    }
    
    // _ApproveAndCallFallBack
    function erc20() public constant returns (address) {
        bool    _copyright;
        address _erc20;
        (_copyright,_erc20) = Manager(manager).currency();
        require(_copyright);
        return _erc20;
    }
    function spender() public constant returns (address) {
        return manager;
    }
    function receiveApproval(uint256[] _data) payable public {
        revert();
    }
    function receiveApproval(bytes _msgPack) payable public {
        Manager(manager).receiveApproval(msg.sender,_msgPack);
    }
}

contract Manager is SafeMath {
    struct _owner {
        bool                            isBadge;
        address                         owner;
    }
    struct _badge {
        address                         owner;
        address                         updater;
        mapping(address=>uint256[4])    status;
    }
    struct _store {
        address                         owner;
        bool                            copyright;
        address                         erc20;
        uint256                         price;

        uint256                         totalSupply;
        uint8                           stamp;
        mapping(address=>uint256[2])    coupons;
    }

    address                     _master;

    mapping(address=>_badge)    badges;
    mapping(address=>_store)    stores;
    mapping(address=>_owner)    owners;

    constructor() public {_master = msg.sender;}

    // modifiers
    modifier onlyMaster() {
        require(msg.sender==_master);
        _;
    }
    modifier onlyOwner(address _contract) {
        require(owner(_contract)==msg.sender);
        _;
    }
    modifier onlyUpdater(address _contract) {
        require (updater(_contract)==msg.sender);
        _;
    }
    modifier onlyStore(address _contract) {
        require(stores[_contract].copyright);
        _;
    }

    // master
    function master(address _next) onlyMaster public {
        require(_next!=address(0)&&_next!=address(this)&&_next!=_master);
        _master = _next;
    }
    // change copyright
    function enable(address _contract, bool _enable) onlyMaster onlyStore(_contract) public {
        stores[_contract].copyright  = _enable;
    }

    // change Owner
    event STORE(address indexed _contract, address indexed _to, address indexed _from);
    event BADGE(address indexed _contract, address indexed _to, address indexed _from);
    function owner(address _contract) constant public returns (address) {
        return owners[_contract].owner;
    }
    function newOwner(address _contract, address _next) onlyOwner(_contract) public {
        if(owners[_contract].isBadge) {
            emit BADGE(_contract,_next,stores[_contract].owner);
            badges[_contract].owner = _next;
        } else {
            emit STORE(_contract,_next,stores[_contract].owner);
            stores[_contract].owner = _next;
        }
        owners[_contract].owner = _next;
    }

    // create Wallet
    mapping(address=>bool)  wallets;
    function wallet() public {
        //Wallet
        address temp    = new Wallet(msg.sender);
        wallets[temp]   = true;
    }
    function isWallet(address _wallet) constant public returns (bool) {
        return wallets[_wallet];
    }

    // create badge
    function badge(bytes _msgPack) public {
        address temp    = new Badge(_msgPack);
        owners[temp]    = _owner(true,msg.sender);
        badges[temp]    = _badge(msg.sender,msg.sender);
        emit BADGE(temp,msg.sender,address(0));
    }
    function updater(address _contract) constant public returns (address) {
        return badges[_contract].updater;
    }
    function newUpdater(address _contract, address _next) onlyOwner(_contract) public {
        badges[_contract].updater   = _next;
    }
    // update user status
    function rank(address _contract, address _user, uint256 _rank) onlyUpdater(_contract)  public {
        badges[_contract].status[_user][0]   = _rank;
    }
    function level(address _contract, address _user, uint256 _level) onlyUpdater(_contract)  public {
        badges[_contract].status[_user][1]   = _level;
    }
    function exp(address _contract, address _user, uint256 _exp) onlyUpdater(_contract)  public {
        badges[_contract].status[_user][2]   = _exp;
    }
    function badge(address _contract, address _user, uint8 _newBadge) onlyUpdater(_contract)  public {
        require(_newBadge>0);
        badges[_contract].status[_user][3]   |= (1<<uint256(_newBadge-1));
    }
    // get user status
    function status(address _contract, address _user) constant public returns (address,address,uint256[4]) {
        return (badges[_contract].owner,badges[_contract].updater,badges[_contract].status[_user]);
    }

    // create Shop
    event TOKEN(address indexed _contract, address indexed _erc20);
    function store(bytes _msgPack, address _erc20, uint256 _price, uint8 _stamp) public {
        address temp    = new Avatar(_msgPack);
        owners[temp]    = _owner(false,msg.sender);
        stores[temp]    = _store(msg.sender,true,_erc20,_price,0,_stamp);
        emit STORE(temp,msg.sender,address(0));
        emit TOKEN(temp,_erc20);
    }
    // change price
    function price(address _contract, uint256 _price, uint8 _stamp) onlyOwner(_contract) onlyStore(_contract) public {
        stores[_contract].price   = _price;
        stores[_contract].stamp   = _stamp;
    }
    function currency() constant public returns (bool,address) {
        return (stores[msg.sender].copyright,
                stores[msg.sender].erc20);
    }
    function about(address _contract) constant public returns (address, bool, address, uint256, uint256, uint256, uint256[2]) {
        return (stores[_contract].owner,
                stores[_contract].copyright,
                stores[_contract].erc20,
                stores[_contract].price,
                stores[_contract].stamp,
                stores[_contract].totalSupply,
                stores[_contract].coupons[msg.sender]);
    }

    // coupon
    event COUPON(address _contract, address indexed _to, address indexed _from, uint256 _count);
    function coupon(address _contract, address _to, uint256 _count) onlyOwner(_contract) onlyStore(_contract) public {
        mint(_contract,_to,_count);
    }
    function give(address _contract, address _to, uint256 _count) public {
        require(stores[_contract].coupons[msg.sender][1]>=_count);
        stores[_contract].coupons[msg.sender][1]= safeSub(stores[_contract].coupons[msg.sender][1],_count);
        stores[_contract].coupons[_to][1]       = safeAdd(stores[_contract].coupons[_to][1],_count);
        emit COUPON(_contract,_to,address(msg.sender),_count);
    }
    function mint(address _contract, address _to, uint256 _count) private {
        stores[_contract].coupons[_to][1]       = safeAdd(stores[_contract].coupons[_to][1],_count);
        stores[_contract].totalSupply           = safeAdd(stores[_contract].totalSupply,_count);
        emit COUPON(_contract,_to,address(0),_count);
    }
    function burn(address _contract, address _from, uint256 _count) private {
        stores[_contract].coupons[_from][1]     = safeSub(stores[_contract].coupons[_from][1],_count);
        stores[_contract].totalSupply           = safeSub(stores[_contract].totalSupply,_count);
        emit COUPON(_contract,address(0),_from,_count);
    }

    // register Avatar
    event AVATAR (address indexed _user, address indexed _contract, bytes _msgPack);
    function balanceOf(address _erc20, address _tokenOwner) private constant returns (uint balance) {
        if(_erc20==address(0))
            return address(this).balance;
        return _ERC20Interface(_erc20).balanceOf(_tokenOwner);
    }
    function min(uint _a, uint _b) private pure returns (uint256) {
        if(_a>_b)
            return _b;
        return _a;
    }
    function avatar(address _user, address _contract, uint256 _price, uint256 _value, bytes _msgPack) private {
        if(_price>0) {
            if(_value==0&&(stores[_contract].coupons[_user][1]>0))
                burn(_contract, _user, 1);
            else {
                stores[_contract].coupons[_user][0]    = safeAdd(stores[_contract].coupons[_user][0],1);
                if(stores[_contract].stamp>0&&(stores[_contract].coupons[_user][0]%stores[_contract].stamp)==0)
                    mint(_contract,_user,1);
                if(stores[_contract].erc20==address(0))
                    stores[_contract].owner.transfer(_value);
                else
                    _ERC20Interface(stores[_contract].erc20).transferFrom(_user,stores[_contract].owner,_value);
            }
        }
        emit AVATAR(_user,_contract,_msgPack);
    }
    function receiveApproval(address _user, bytes _msgPack) onlyStore(msg.sender) payable public {
        uint256 _price  = stores[msg.sender].price;
        uint256 _value  = min(stores[msg.sender].erc20==address(0)?msg.value:_ERC20Interface(stores[msg.sender].erc20).allowance(_user,this),balanceOf(stores[msg.sender].erc20,_user));
        require(_price==0||(_value>0&&_value>=_price)||(_value==0&&stores[msg.sender].coupons[_user][1]>0));

        avatar(_user, msg.sender, _price, _value, _msgPack);
    }
    function avatar(address _contract, bytes _msgPack) onlyStore(_contract) payable public {
        uint256 _price  = stores[_contract].price;
        uint256 _value  = min(stores[_contract].erc20==address(0)?msg.value:_ERC20Interface(stores[_contract].erc20).allowance(msg.sender,this),balanceOf(stores[_contract].erc20,msg.sender));
        require(_price==0||(_value>0&&_value>=_price)||(_value==0&&stores[_contract].coupons[msg.sender][1]>0));

        avatar(msg.sender, _contract, _price, _value, _msgPack);
    }
}