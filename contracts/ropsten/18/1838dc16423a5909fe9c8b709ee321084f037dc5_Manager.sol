pragma solidity ^0.4.24;

contract ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract Avatar20 {
    address     owner;
    address     manager;
    uint256     index   = 1;

    constructor(address _owner) public {
        owner   = _owner;
        manager = msg.sender;
    }
    
    function ownerShip(address _owner) public {
        require(msg.sender==manager);
        owner   = _owner;
    }

    event ASSET(uint256 indexed _category, uint256 indexed index, bytes);
    function asset(uint256 _category, bytes _image) public {
        require(msg.sender==owner);
        emit ASSET(_category,index,_image);
        index++;
    }
}

contract Manager {
    address     owner;

    constructor() public {
        owner = msg.sender;
    }

    struct _data {
        uint8       status; // 1 = disable, 2 = enable;
        address     owner;
        address     erc20;
        uint256     price;
    }

    mapping(address=>_data)     stores;

    modifier onlyStoreOwner(address _store) {
        require(stores[_store].status>0&&stores[_store].owner==msg.sender);
        _;
    }

    event TOKEN(address indexed _store, address indexed _erc20);    
    function create(address _erc20, uint256 _price, bytes _msgPack) public {
        address temp    = new Avatar20(msg.sender);
        stores[temp]    = _data(2,msg.sender,_erc20,_price);
        emit TOKEN(temp,_erc20);
        emit STORE(temp,_msgPack);
        emit OWNER(temp,msg.sender,address(0));        
    }
    function toggle(address _store) public {
        require(stores[_store].status>0);
        require(msg.sender==owner);
        stores[_store].status    = stores[_store].status==1?2:1;
    }
    function about(address _store) constant public returns (uint8, address, address,uint256) {
        return (stores[_store].status,stores[_store].owner,stores[_store].erc20,stores[_store].price);
    }

    function price(address _store, uint256 _price) onlyStoreOwner(_store) public {
        stores[_store].price    = _price;
    }
    event OWNER(address indexed _store, address indexed _to, address indexed _from);
    function ownerShip(address _store, address _owner) public {
        require(stores[_store].status==2);
        require(stores[_store].owner==msg.sender);
        require(address(0)!=_owner);
        stores[_store].owner=_owner;
        Avatar20(_store).ownerShip(_owner);
        emit OWNER(_store,_owner,msg.sender);
    }
    event STORE(address indexed _store, bytes _msgPack);
    function store(address _store, bytes _msgPack) onlyStoreOwner(_store) public {
        emit STORE(_store,_msgPack);
    }
    event SCRIPT(address indexed _store, bytes _script);
    function custom(address _store, bytes _script) onlyStoreOwner(_store) public {
        emit SCRIPT(_store,_script);
    }
    function script(bytes _script) public {
        require(msg.sender==owner);
        emit SCRIPT(address(0),_script);
    }

    event AVATAR (address indexed _user, address indexed _store, bytes _msgPack);
    function avatar(address _store, bytes _msgPack) payable public {
        require(stores[_store].status==2);
        require((stores[_store].erc20==address(0)?msg.value:ERC20Interface(stores[_store].erc20).allowance(msg.sender,this))==stores[_store].price);

        if(stores[_store].erc20!=address(0)&&stores[_store].price>0)
            ERC20Interface(stores[_store].erc20).transferFrom(msg.sender,stores[_store].owner,stores[_store].price);

        emit AVATAR(msg.sender,_store,_msgPack);
    }
}