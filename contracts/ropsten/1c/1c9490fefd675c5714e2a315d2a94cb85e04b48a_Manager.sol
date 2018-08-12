pragma solidity ^0.4.24;

contract ERC20Interface {
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

contract User {
    address internal                        updater;
    mapping(address=>uint256[2]) internal   status;

    modifier onlyUpdater() {
        require (msg.sender==updater);
        _;
    }

    // updater
    function setUpdater(address _updater) public;
    // update ranks. (how to update ranks??)
    function rank(address _user, uint256 _rank) onlyUpdater public {
        status[_user][0]   = _rank;
    }
    // update badge (how to add badges??)
    function badge(address _user, uint256 _badge) onlyUpdater public {
        status[_user][1]   |=_badge;
    }
    // about user
    function user() constant public returns (uint256[2]) {
        return (status[msg.sender]);
    }
}

contract Avatar is User, SafeMath {
    address                         manager;
    
    constructor(bytes _msgPack) public {
        manager     = msg.sender;
        emit INFO(_msgPack);
    }
    
    function setUpdater(address _updater) onlyOwner public {
        updater = _updater;
    }
    
    // modifiers
    modifier onlyOwner() {
        require(msg.sender==Manager(manager).owner(this));
        _;
    }

    // register information
    event INFO(bytes _msgPack);
    function info(bytes _msgPack) onlyOwner public {
        emit INFO(_msgPack);
    }

    // register asset
    uint256                         index;
    event ASSET(uint256 indexed _category, uint256 indexed _index, bytes _img);
    function asset(uint256 _category, bytes _image) onlyOwner public {
        emit ASSET(_category,index,_image);
        index   = safeAdd(index,1);
    }
    event BADGE(uint8 indexed _index, string _title, bytes _img);
    function badge(uint8 _index, string _title, bytes _image) onlyOwner public {
        require(_index>0);
        emit BADGE(_index,_title,_image);
    }
}

contract Manager is SafeMath {
    struct _avatar {
        address                         owner;
        address                         root;
        
        bool                            copyright;
        
        address                         erc20;
        uint256                         price;
        uint256                         fee;
        
        uint256                         totalSupply;
        uint8                           stamp;
        mapping(address=>uint256[2])    coupons;
    }
    address                     _master;
    mapping(address=>_avatar)   avatars;

    constructor() public {
        _master = msg.sender;
    }

    // modifiers
    modifier onlyMaster() {
        require(msg.sender==_master);
        _;
    }
    modifier onlyOwner(address _contract) {
        require(avatars[_contract].owner==msg.sender);
        _;
    }
    modifier onlyRoot(address _contract) {
        require(avatars[_contract].root==address(0));
        _;
    }
    
    // master
    function master(address _next) onlyMaster public {
        require(_next!=address(0)&&_next!=address(this)&&_next!=_master);
        _master = _next;
    }

    // change copyright
    function enable(address _contract, bool _enable) onlyMaster onlyRoot(_contract) public {
        avatars[_contract].copyright  = _enable;
    }
    // register Script
    event SCRIPT(address indexed _contract, bytes _script);
    function custom(address _contract, bytes _script) onlyRoot(_contract) public {
        emit SCRIPT(_contract,_script);
    }
    function script(bytes _script) onlyMaster public {
        emit SCRIPT(address(0),_script);
    }
    
    // create Shop
    event TOKEN(address indexed _contract, address indexed _erc20);
    function store(address _root, address _erc20, uint256 _price, uint8 _fee, uint8 _stamp, bytes _msgPack) public {
        require(_root==address(0)||(copyright(_root)&&avatars[_root].root==address(0)));
        require(_fee<101);
        address temp            = new Avatar(_msgPack);
        address erc20           = _root==address(0)?_erc20:avatars[_root].erc20;
        uint256 price           = _root==address(0)?_price:0;
        uint256 fee             = _root==address(0)?(_fee>0?safeDiv(safeMul(_price,_fee),100):0):0;
        uint8 stamp             = _root==address(0)?_stamp:0;
        avatars[temp]           = _avatar(msg.sender,_root,true,erc20,price,fee,0,stamp);
        emit OWNER(temp,msg.sender,address(0));
        emit TOKEN(temp,_erc20);
    }
    function owner(address _contract) constant public returns (address) {
        return avatars[_contract].owner;
    }
    function root(address _contract) constant public returns (address) {
        return avatars[_contract].root;
    }
    function copyright(address _contract) constant public returns (bool) {
        return avatars[_contract].root==address(0)?avatars[_contract].copyright:avatars[avatars[_contract].root].copyright;
    }
    function about(address _contract) constant public returns (bool, address, uint256, uint256, uint8, uint256) {
        address _root = avatars[_contract].root;
        return (copyright(_contract),
                _root==address(0)?avatars[_contract].erc20:avatars[_root].erc20,
                _root==address(0)?avatars[_contract].price:avatars[_root].price,
                _root==address(0)?avatars[_contract].fee:avatars[_root].fee,
                _root==address(0)?avatars[_contract].stamp:avatars[_root].stamp,
                _root==address(0)?avatars[_contract].totalSupply:avatars[_root].totalSupply);
    }
    function user(address _contract) constant public returns (uint256[2]) {
        return avatars[_contract].coupons[msg.sender];
    }
    // change price
    /*
    function price(address _contract, uint256 _price, uint8 _fee) onlyOwner(_contract) onlyRoot(_contract) public {
        require(_fee<101);
        avatars[_contract].price    = _price;
        avatars[_contract].fee      = _fee>0?safeDiv(safeMul(_price,_fee),100):0;
        // todo : is it need governance?
    }
    */
    // change Owner
    event OWNER(address indexed _contract, address indexed _to, address indexed _from);
    function owner(address _contract, address _next) onlyOwner(_contract) public {
        emit OWNER(_contract,_next,avatars[_contract].owner);
        avatars[_contract].owner  = _next;
    }
    // coupon
    event COUPON(address _contract, address indexed _to, address indexed _from, uint256 _count);
    function coupon(address _contract, address _to, uint256 _count) onlyOwner(_contract) onlyRoot(_contract) public {
        mint(_contract,_to,_count);
    }
    function give(address _contract, address _to, uint256 _count) public {
        require(avatars[_contract].coupons[msg.sender][1]>=_count);
        avatars[_contract].coupons[msg.sender][1]  = safeSub(avatars[_contract].coupons[msg.sender][1],_count);
        avatars[_contract].coupons[_to][1]         = safeAdd(avatars[_contract].coupons[_to][1],_count);
        emit COUPON(_contract,_to,address(msg.sender),_count);
    }
    function mint(address _contract, address _to, uint256 _count) private {
        avatars[_contract].coupons[_to][1]      = safeAdd(avatars[_contract].coupons[_to][1],_count);
        avatars[_contract].totalSupply          = safeAdd(avatars[_contract].totalSupply,_count);
        emit COUPON(_contract,_to,address(0),_count);
    }
    function burn(address _contract, address _from, uint256 _count) private {
        avatars[_contract].coupons[_from][1]    = safeSub(avatars[_contract].coupons[_from][1],_count);
        avatars[_contract].totalSupply          = safeSub(avatars[_contract].totalSupply,_count);
        emit COUPON(_contract,address(0),_from,_count);
    }
    // change alliance
    function alliance(address _contract, address _root)  onlyOwner(_contract) onlyRoot(_root) public {
        require(avatars[_contract].root!=address(0));
        avatars[_contract].root = _root;
    }

    // register Avatar
    event AVATAR (address indexed _user, address indexed _contract, bytes _msgPack);
    function avatar(address _contract, bytes _msgPack) payable public {
        require(copyright(_contract));
        address _root   = avatars[_contract].root==address(0)?_contract:avatars[_contract].root;
        uint256 _price  = avatars[_root].price;
        uint256 _value  = avatars[_root].erc20==address(0)?msg.value:ERC20Interface(avatars[_root].erc20).allowance(msg.sender,this);
        require(_price==0||(_value==0&&avatars[_root].coupons[msg.sender][1]>0)||(_value>0&&_value==_price));

        if(_price>0) {
            if(_value==0&&(avatars[_root].coupons[msg.sender][1]>0))
                burn(_root, msg.sender, 1);
            else {
                avatars[_root].coupons[msg.sender][0]   = safeAdd(avatars[_root].coupons[msg.sender][0],1);
                if(avatars[_root].stamp>0&&(avatars[_root].coupons[msg.sender][0]%avatars[_root].stamp)==0)
                    mint(_root,msg.sender,1);
                
                if(_contract==_root)
                    transfer(avatars[_root].erc20,msg.sender,avatars[_root].owner,_price);
                else {
                    transfer(avatars[_root].erc20,msg.sender,avatars[_root].owner,avatars[_root].fee);
                    transfer(avatars[_root].erc20,msg.sender,avatars[_contract].owner,safeSub(_price,avatars[_root].fee));
                }
            }
        }
        emit AVATAR(msg.sender,_root,_msgPack);
    }
    function transfer(address _erc20, address _from, address _to, uint256 _value) private {
        if(_erc20==address(0))  _to.transfer(_value);
        else                    ERC20Interface(_erc20).transferFrom(_from,_to,_value);
    }
}