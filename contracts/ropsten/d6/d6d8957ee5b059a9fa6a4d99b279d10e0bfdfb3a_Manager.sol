pragma solidity ^0.4.24;

contract ERC20Interface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract Avatar20 {
    address     owner;
    uint256     index   = 1;

    constructor(address _owner) public {
        owner   = _owner;
    }

    event Asset(uint256 indexed, uint256 indexed, bytes);
    function asset(uint256 _cat, bytes _image) public {
        require(msg.sender==owner);
        emit Asset(_cat,index,_image);
        index++;
    }
}

contract Manager {
    address                     owner;
    
    constructor() public {
        owner = msg.sender;
    }

    struct data {
        uint8       status; // 1 = disable, 2 = enable;        
        address     owner;
        address     erc20;
        uint256     price;
    }

    mapping(address=>data)     stores;

    function create(address _erc20, uint256 _price, bytes _msgPack) public {
        address temp    = new Avatar20(msg.sender);
        stores[temp]    = data(2,msg.sender,_erc20,_price);
        emit Store(msg.sender,temp,_msgPack);
    }
    function toggle(address _store) public {
        require(stores[_store].status>0);
        require(msg.sender==owner);
        stores[_store].status    = stores[_store].status==1?2:1;
    }
    function about(address _store) constant public returns (uint8, address, address,uint256) {
        return (stores[_store].status,stores[_store].owner,stores[_store].erc20,stores[_store].price);
    }
    
    function price(address _store, uint256 _price) public {
        require(stores[_store].status>0);
        require(stores[_store].owner==msg.sender);
        stores[_store].price    = _price;
    }
    event Store(address indexed, address indexed, bytes);    
    function store(address _store, bytes _msgPack) public {
        require(stores[_store].status>0);
        require(stores[_store].owner==msg.sender);
        emit Store(msg.sender,_store,_msgPack);
    }
    event Script(address indexed, bytes);
    function script(address _store, bytes _script) public {
        emit Script(_store,_script);
    }

    event Avatar (address indexed, address indexed, bytes);
    function avatar(address _store, bytes _msgPack) payable public {
        require(stores[_store].status==2);
        require((stores[_store].erc20==address(0)?msg.value:ERC20Interface(stores[_store].erc20).allowance(msg.sender,this))==stores[_store].price);

        if(stores[_store].erc20!=address(0)&&stores[_store].price>0)
            ERC20Interface(stores[_store].erc20).transferFrom(msg.sender,stores[_store].owner,stores[_store].price);

        emit Avatar(msg.sender,_store,_msgPack);
    }
}