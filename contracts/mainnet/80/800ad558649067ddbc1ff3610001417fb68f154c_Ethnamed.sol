pragma solidity ^0.4.21;

contract Issuer {
    
    address internal issuer = 0x692202c797ca194be918114780db7796e9397c13;
    
    function changeIssuer(address _to) public {
        
        require(msg.sender == issuer); 
        
        issuer = _to;
    }
}

contract ERC20Interface {
    
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    
}

library StringHelper {

    function stringToUint(string s) pure internal returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }
    
}

library SafeMath {
    
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
}

contract ERC20 is Issuer, ERC20Interface {

    using SafeMath for uint;

    bool public locked = true;
    
    string public constant name = "Ethnamed";
    string public constant symbol = "NAME";
    uint8 public constant decimals = 18;
    uint internal tokenPrice;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    struct Contributor {
        mapping(address => uint) allowed;
        uint balance;
    }
    
    mapping(address => Contributor) contributors;
    
    function ERC20() public {
        tokenPrice = 10**uint(decimals);
        Contributor storage contributor = contributors[issuer];
        contributor.balance = totalSupply();
        emit Transfer(address(0), issuer, totalSupply());
    }
    
    function unlock() public {
        require(msg.sender == issuer);
        locked = false;
    }
    
    function totalSupply() public view returns (uint) {
        return 1000000 * tokenPrice;
    }
    
    function balanceOf(address _tokenOwner) public view returns (uint) {
        Contributor storage contributor = contributors[_tokenOwner];
        return contributor.balance;
    }
    
    function transfer(address _to, uint _tokens) public returns (bool) {
        require(!locked || msg.sender == issuer);
        Contributor storage sender = contributors[msg.sender];
        Contributor storage recepient = contributors[_to];
        sender.balance = sender.balance.sub(_tokens);
        recepient.balance = recepient.balance.add(_tokens);
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }
    
    function allowance(address _tokenOwner, address _spender) public view returns (uint) {
        Contributor storage owner = contributors[_tokenOwner];
        return owner.allowed[_spender];
    }
    
    function transferFrom(address _from, address _to, uint _tokens) public returns (bool) {
        
        Contributor storage owner = contributors[_from];
        
        require(owner.allowed[msg.sender] >= _tokens);
        
        Contributor storage receiver = contributors[_to];
        
        owner.balance = owner.balance.sub(_tokens);
        owner.allowed[msg.sender] = owner.allowed[msg.sender].sub(_tokens);
        
        receiver.balance = receiver.balance.add(_tokens);
        
        emit Transfer(_from, _to, _tokens);
        
        return true;
    }
    
    function approve(address _spender, uint _tokens) public returns (bool) {
        
        require(!locked);
        
        Contributor storage owner = contributors[msg.sender];
        owner.allowed[_spender] = _tokens;
        
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }
    
}

contract DEXified is ERC20 {

    using SafeMath for uint;

    //use struct Contributor from ERC20
    //use bool locked from ERC20
    
    struct Sales {
        address[] items;
        mapping(address => uint) lookup;
    }
    
    struct Offer {
        uint256 tokens;
        uint256 price;
    }
    
    mapping(address => Offer) exchange;
    
    uint256 public market = 0;
    
    //Credits to https://github.com/k06a
    Sales internal sales;
    
    function sellers(uint index) public view returns (address) {
        return sales.items[index];
    }
    
    function getOffer(address _owner) public view returns (uint256[2]) {
        Offer storage offer = exchange[_owner];
        return ([offer.price , offer.tokens]);
    }
    
    function addSeller(address item) private {
        if (sales.lookup[item] > 0) {
            return;
        }
        sales.lookup[item] = sales.items.push(item);
    }

    function removeSeller(address item) private {
        uint index = sales.lookup[item];
        if (index == 0) {
            return;
        }
        if (index < sales.items.length) {
            address lastItem = sales.items[sales.items.length - 1];
            sales.items[index - 1] = lastItem;
            sales.lookup[lastItem] = index;
        }
        sales.items.length -= 1;
        delete sales.lookup[item];
    }
    
    
    function setOffer(address _owner, uint256 _price, uint256 _value) internal {
        exchange[_owner].price = _price;
        market =  market.sub(exchange[_owner].tokens);
        exchange[_owner].tokens = _value;
        market =  market.add(_value);
        if (_value == 0) {
            removeSeller(_owner);
        }
        else {
            addSeller(_owner);
        }
    }
    

    function offerToSell(uint256 _price, uint256 _value) public {
        require(!locked);
        setOffer(msg.sender, _price, _value);
    }
    
    function executeOffer(address _owner) public payable {
        require(!locked);
        Offer storage offer = exchange[_owner];
        require(offer.tokens > 0);
        require(msg.value == offer.price);
        _owner.transfer(msg.value);
        
        Contributor storage owner_c  = contributors[_owner];
        Contributor storage sender_c = contributors[msg.sender];
        
        require(owner_c.balance >= offer.tokens);
        owner_c.balance = owner_c.balance.sub(offer.tokens);
        sender_c.balance =  sender_c.balance.add(offer.tokens);
        emit Transfer(_owner, msg.sender, offer.tokens);
        setOffer(_owner, 0, 0);
    }
    
}

contract Ethnamed is DEXified {

    using SafeMath for uint;
    using StringHelper for string;
    
    struct Name {
        string record;
        address owner;
        uint expires;
        uint balance;
    }
    
    function withdraw(address _to) public {

        require(msg.sender == issuer); 
        
        _to.transfer(address(this).balance);
    }
    
    mapping (string => Name) internal registry;
    
    mapping (bytes32 => string) internal lookup;
    
    function resolve(string _name) public view returns (string) {
        return registry[_name].record;
    }
    
    function whois(bytes32 _hash) public view returns (string) {
        return lookup[_hash];
    }
    
    function transferOwnership(string _name, address _to) public {
        
        require(registry[_name].owner == msg.sender);
        
        registry[_name].owner = _to;
    }

    function removeName(string _name) internal {
        Name storage item = registry[_name];
        
        bytes32 hash = keccak256(item.record);
        
        delete registry[_name];
        
        delete lookup[hash];
    }

    function removeExpiredName(string _name) public {
        
        require(registry[_name].expires < now);
        
        removeName(_name);
    }
    
    function removeNameByOwner(string _name) public {
        
        Name storage item = registry[_name];
        
        require(item.owner == msg.sender);
        
        removeName(_name);
    }
    

    function sendTo(string _name) public payable {
        
        if (registry[_name].owner == address(0)) {
            registry[_name].balance = registry[_name].balance.add(msg.value);
        }
        else {
            registry[_name].owner.transfer(msg.value);
        }
    
    }
    
    
    
    function setupCore(string _name, string _record, address _owner, uint _life) internal {
        
        Name storage item = registry[_name];
        
        require(item.owner == msg.sender || item.owner == 0x0);
        item.record = _record;
        item.owner = _owner;
        if (item.balance > 0) {
            item.owner.transfer(item.balance);
            item.balance = 0;
        }
        item.expires = now + _life;
        bytes32 hash = keccak256(_record);
        lookup[hash] = _name;
        
    }

    function setupViaAuthority(
        string _length,
        string _name,
        string _record,
        string _blockExpiry,
        address _owner,
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s,
        uint _life
    ) internal {
        
        require(_blockExpiry.stringToUint() >= block.number);
        
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n", _length, _name, "r=", _record, "e=", _blockExpiry), _v, _r, _s) == issuer);
        
        setupCore(_name, _record, _owner, _life);
        
    }

    function setOrUpdateRecord2(
        string _length,
        string _name,
        string _record,
        string _blockExpiry,
        address _owner,
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s
    ) public {
        
        Contributor storage contributor = contributors[msg.sender];
        
        require(contributor.balance >= tokenPrice);
        
        contributor.balance = contributor.balance.sub(tokenPrice);
        
        uint life = 48 weeks;
     
        setupViaAuthority(_length, _name, _record, _blockExpiry, _owner, _v, _r, _s, life);   
    }

    function setOrUpdateRecord(
        string _length,
        string _name,
        string _record,
        string _blockExpiry,
        address _owner,
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s
    ) public payable {
        
        uint life = msg.value == 0.01  ether ?  48 weeks : 
                    msg.value == 0.008 ether ?  24 weeks :
                    msg.value == 0.006 ether ?  12 weeks :
                    msg.value == 0.002 ether ?  4  weeks :
                    0;
                       
        require(life > 0);
        
        setupViaAuthority(_length, _name, _record, _blockExpiry, _owner, _v, _r, _s, life);
    }
}