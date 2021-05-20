/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED


contract PGN {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public basicAmount;
    uint256 public basicTime;
	address payable public owner;
	
    mapping (address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor() {
    }

    address ZERO = 0x0000000000000000000000000000000000000000;
    function transfer(address _to, uint256 _value)
    public {
        if (_to == ZERO)
            revert();
		if (_value <= 0)
		    revert();
        if (balanceOf[msg.sender] < _value)
            revert();
        if (balanceOf[_to] + _value < balanceOf[_to])
            revert();
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value; 
        emit Transfer(msg.sender, _to, _value);
    }
       
    function transferFrom(address _from, address _to, uint256 _value)
    public returns(bool success) {
        if(_to == ZERO)
            revert();
		if(_value <= 0)
		    revert();
        if(balanceOf[_from] < _value)
            revert();
        if(balanceOf[_to] + _value < balanceOf[_to])
            revert();
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function random()
	internal view returns(uint256) {
	    uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
        block.number
        )));
        return (seed - ((seed / 1000) * 1000));
	}
}


contract Library is PGN {
    
    struct Board {
        mapping(address => mapping(uint256 => Goods)) board;
    }
    
    struct User {
        string id;
        address payable wallet;
        uint256 count;
        uint256 posRec;
        uint256 tradeRec;
        uint256 stdRec;
        uint256 credits;
        string encodeMsg;
    }
    
    struct isUserAllow {
        bool isBuyerAllow;
        bool isSellerAllow;
        bool isDealFlag;
    }
    
    struct userAddr {
        address payable buyerAddr;
        address payable sellerAddr;
    }
    
    struct ipfsHash {
        string picture;
        string moreMsg;
    }
    
    struct Goods {
        string name;
        uint256 price;
        userAddr addr;
        string message;
        uint256 time;
        isUserAllow isAllow;
        ipfsHash hash;
    }
    
    constructor() {
    }
    
	function findUser(User[] storage user, address _addr) 
	internal view returns(uint256){
	    uint256 i;
	    for(i = 0; i < user.length; i++) {
            if(user[i].wallet == _addr) {
                break;
            }
        }
        return i;
	}
	
    function insert(Board storage self, User[] storage user, address payable _addr,
    string memory _name, uint256 _price, address payable _buyerAddr, address payable _sellerAddr, string memory _message, uint256 _time, string memory _picture, string memory _moreMsg)
    internal {
        uint256 i = findUser(user, _addr);

        self.board[user[i].wallet][user[i].count] = Goods(_name, _price, userAddr(_buyerAddr, _sellerAddr), _message, _time, isUserAllow(false, false, false), ipfsHash(_picture, _moreMsg));
        user[i].count += 1;
    }
    
    function remove(Board storage self, User[] storage user, address payable _addr, uint256 count)
    internal {
        uint256 i = findUser(user, _addr);
        self.board[user[i].wallet][count] = self.board[user[i].wallet][user[i].count-1];
        delete self.board[user[i].wallet][user[i].count-1];
        user[i].count -= 1;
    }
    
    function check(User[] storage user)
    internal view returns(bool) {
        bool flag = false;
        for(uint256 i = 0; i < user.length; i++) {
            if(user[i].wallet == msg.sender) {
                flag = true;
                break;
            }
        }
        return flag;
    }
    
    function register(User[] storage user, address payable _addr, string memory id)
    internal {
        User memory temp;
        temp.id = id;
        temp.wallet = _addr;
        temp.count = 0;
        temp.posRec = 5;
        temp.tradeRec = 10;
        temp.stdRec = 50;
        temp.credits = 0;
        user.push(temp);
    }
    
    function write(User[] storage user, string memory _enMsg)
    internal {
        uint256 i = findUser(user, msg.sender);
        user[i].encodeMsg = _enMsg;
    }
    
    function read(User[] storage user, address _addr)
    internal view returns(string memory) {
        uint256 i = findUser(user, _addr);
        string memory _enMsg;
        _enMsg = user[i].encodeMsg;
        return _enMsg;
    }
    
    function finding(Board storage self, User[] storage user, string memory _name, uint256 num)
    internal view returns(address payable, uint256, uint256, string memory, uint256) {
        Goods[100] memory searchBoard;
        uint256[100] memory _count;
        uint256 k = 0;
        bool flag = true;
        for(uint256 i = 0; i < user.length && flag; i++) {
            for(uint256 j = 0; j < user[i].count && flag; j++) {
                if(keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(self.board[user[i].wallet][j].name))) {
                    searchBoard[k].price = self.board[user[i].wallet][j].price;
                    searchBoard[k].addr.sellerAddr = user[i].wallet;
                    searchBoard[k].message = self.board[user[i].wallet][j].message;
                    searchBoard[k].time = self.board[user[i].wallet][j].time;
                    _count[k] = j;
                    k++;
                }
                if(k > num) {
                    flag = false;
                }
            }
        }
        return(searchBoard[num].addr.sellerAddr, _count[num], searchBoard[num].price, searchBoard[num].message, searchBoard[num].time);
    }
    
    function findID(User[] storage user, address _addr)
    internal view returns(string memory) {
        uint256 i = findUser(user, _addr);
        return user[i].id;
    }
    
    function findAddr(User[] storage user, string memory _id)
    internal view returns(address payable) {
        uint256 i;
        for(i = 0; i < user.length; i++) {
            if(keccak256(abi.encodePacked(user[i].id)) == keccak256(abi.encodePacked(_id)))
                break;
        }
        return user[i].wallet;
    }
    
    function findCount(User[] storage user, address _addr)
    internal view returns(uint256) {
        uint256 i = findUser(user, _addr);
        return user[i].count;
    }
    
    function search(Board storage self, User[] storage user, address payable _addr, string memory _name) 
    internal view returns(uint256) {
        uint256 i = findUser(user, _addr);
        uint256 j;
        for(j = 0; j < user[i].count; j++) {
            if(keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(self.board[_addr][j].name)))
                break;
        }
        return j;
    }
    
    function viewBoard(Board storage self, address _addr, uint256 _count)
    internal view returns(string memory, uint256, userAddr memory, string memory, uint256, ipfsHash memory) {
        userAddr memory _userAddr = userAddr(self.board[_addr][_count].addr.buyerAddr, self.board[_addr][_count].addr.sellerAddr);
        ipfsHash memory _ipfsHash = ipfsHash(self.board[_addr][_count].hash.picture, self.board[_addr][_count].hash.moreMsg);
        return(self.board[_addr][_count].name, self.board[_addr][_count].price, _userAddr, self.board[_addr][_count].message, self.board[_addr][_count].time, _ipfsHash);
    }
    
    function removeArray(Goods[] storage array, string memory _name)
    internal {
        uint256 i;
        for(i = 0; i < array.length; i++) {
            if(keccak256(abi.encodePacked(array[i].name)) == keccak256(abi.encodePacked(_name)))
                break;
        }
        for(uint256 j = i; j < array.length-1; j++) {
            array[j] = array[j+1];
        }
        delete array[array.length-1];
        array.pop();
    }
    
    function addCredits(User[] storage user, address payable _addr, uint256 _value)
    internal {
        uint256 i = findUser(user, _addr);
        user[i].credits += _value;
    }
    
    function subCredits(User[] storage user, address payable _addr, uint256 _value)
    internal {
        uint256 i = findUser(user, _addr);
        user[i].credits -= _value;
    }
    
    function pay(Board storage self, User[] storage user, address payable _addr, uint256 _count, uint256 n, address payable _owner)
    internal {
        uint256 _price;
        address payable _payAddr;
        uint256 i = 0;
        uint8 m;
        _price = self.board[_addr][_count].price;
        if(n == 1) {
            _payAddr = _addr;
            m = 3;
        }
        else {
            _payAddr = self.board[_addr][_count].addr.sellerAddr;
            m = 1;
        }

        if(self.board[_addr][_count].isAllow.isBuyerAllow) {
            _payAddr.transfer(_price * n);
        }
        else if(self.board[_addr][_count].isAllow.isSellerAllow) {
            _payAddr.transfer(_price * m);
        }
        else {
            for(i = 0; i < user.length; i++) {
                if(user[i].wallet == _payAddr)
                    break;
            }
            uint256 _score = (user[i].posRec * 100)/user[i].tradeRec;
            if(_score >= user[i].stdRec) {
                _payAddr.transfer(_price * 2);
                if(_score < 90) {
                    user[i].stdRec += 10;
                }
            }
            else {
                _owner.transfer(_price * 2);
            }
        }
    }
    
    function feedback(User[] storage user, address payable _addr, uint256 _credits, uint256 _price, bool _allow)
    internal {
        uint256 i = findUser(user, _addr);
        uint256 _rec = _price;
        if(_credits > _price) {
            _rec *= 1000;
        }
        user[i].tradeRec += _rec;
        if(_allow) {
            user[i].posRec += _rec;
        }
    }
    
    function checkRec(User[] storage user, address _addr) 
    internal view returns(uint256, uint256, uint256) {
        uint256 i = findUser(user, _addr);
        return(user[i].posRec, user[i].tradeRec, user[i].stdRec);
    }
    
    function checkCredits(User[] storage user, address _addr)
    internal view returns(uint256) {
        uint256 i = findUser(user, _addr);
        return user[i].credits;
    }
    
}


contract Marketplace is Library {
    
    uint256 public totalGoods;
    Board PublicBoard;
    Board SellerBoard;
    Board BuyerBoard;
    Goods[] MarketBoard;
    User[] internal Pseller;
    User[] internal Seller;
    User[] internal Buyer;
    
    event sellEvent(address indexed from, Goods _goods);
    event buyEvent(address indexed from, address indexed to, Goods _goods);
    event dealEvent(address indexed from, address indexed to, Goods _goods);
    event noDealEvent(address indexed from, address indexed to, Goods _goods);
    event forceDealEvent(address indexed from, address indexed to, Goods _goods);
    event PosEvent(address indexed from, address indexed to, Goods _goods);
    event NegEvent(address indexed from, address indexed to, Goods _goods);
    
    constructor(uint256 initialSupply, uint256 initialAmount, uint256 initialTime, string memory tokenName, uint8 decimalUnits, string memory tokenSymbol) {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        basicAmount = initialAmount;
        basicTime = block.timestamp + initialTime;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        owner = payable(msg.sender);
        totalGoods = 0;
    }
    
    fallback() external payable {
        revert();
    }
    receive() external payable {
        revert();
    }
    
    modifier checker() {
        require(check(Seller) && check(Buyer) && check(Pseller));
        _;
    }
    
    function FindingGoods(string memory _name, uint256 _num)
    public view returns(address payable, uint256, uint256, string memory, uint256) {
        return(finding(PublicBoard, Pseller, _name, _num));
    }
    
    function FindUserID(address payable _addr)
    public view returns(string memory) {
        return(findID(Seller, _addr));
    }
    
    function FindUserAddr(string memory _id)
    public view returns(address) {
        return(findAddr(Seller, _id));
    }
    
    function ViewMarketBoard(uint256 _index)
    public view returns(string memory, uint256, address payable, string memory, uint256, string memory, string memory) {
        return(MarketBoard[_index].name, MarketBoard[_index].price, MarketBoard[_index].addr.sellerAddr, MarketBoard[_index].message, MarketBoard[_index].time, MarketBoard[_index].hash.picture, MarketBoard[_index].hash.moreMsg);
    }
    
    function ViewPublicBoard(address _addr, uint256 _count)
    public view returns(string memory, uint256, userAddr memory, string memory, uint256, ipfsHash memory) {
        return(viewBoard(PublicBoard, _addr, _count));
    }
    
    function ViewSellerBoard(address _addr, uint256 _count)
    public view returns(string memory, uint256, userAddr memory, string memory, uint256, ipfsHash memory) {
        return(viewBoard(SellerBoard, _addr, _count));
    }
    
    function ViewBuyerBoard(address _addr, uint256 _count)
    public view returns(string memory, uint256, userAddr memory, string memory, uint256, ipfsHash memory) {
        return(viewBoard(BuyerBoard, _addr, _count));
    }
    
    function ViewCount(string memory _user, address _addr)
    public view returns(uint256) {
        if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("Pseller"))) {
            return(findCount(Pseller, _addr));
        }
        else if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("buyer"))) {
            return(findCount(Buyer, _addr));
        }
        else if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("seller"))) {
            return(findCount(Seller, _addr));
        }
        else {
            revert();
        }
    }
    
    function SignUp(string memory _id)
    public {
        require(!(check(Seller) || check(Buyer) || check(Pseller)));
        register(Pseller, payable(msg.sender), _id);
        register(Seller, payable(msg.sender), _id);
        register(Buyer, payable(msg.sender), _id);
    }
    
    function Mining() 
	public {
		if((block.timestamp >= basicTime) && (block.timestamp <= (basicTime+60))) {
		    uint256 giveAmount = ((balanceOf[address(this)]*basicAmount/totalSupply))+1;
		    transferFrom(address(this), msg.sender, giveAmount);
		}
		else if(block.timestamp > (basicTime+60)) {
		    basicTime = block.timestamp + random();
		}
		else {
		    revert();
		}
	}
	
    function BuyCredits(uint256 _value) checker()
    public {
        transferFrom(msg.sender, address(this), _value);
        addCredits(Buyer, payable(msg.sender), (_value * 1 ether)/10);
        addCredits(Seller, payable(msg.sender), (_value * 1 ether)/10);
    }
    
    function WriteMsg(string memory _user, string memory _enMsg) checker()
    public {
        if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("buyer"))) {
            write(Buyer, _enMsg);
        }
        else if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("seller"))) {
            write(Seller, _enMsg);
        }
        else {
            revert();
        }
    }
    
    function ReadMsg(string memory _user, address _addr) checker()
    public view returns(string memory) {
        if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("buyer"))) {
            return(read(Buyer, _addr));
        }
        else if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("seller"))) {
            return(read(Seller, _addr));
        }
        else {
            revert();
        }
    }
	
    function Sell(string memory _name, uint256 _price, string memory _unit, string memory _message, uint256 _time, string memory _picture, string memory _moreMsg) checker()
    public payable {
        if(keccak256(abi.encodePacked(_unit)) == keccak256(abi.encodePacked("ether"))) {
            _price *= 1 ether;
        }
        else if(keccak256(abi.encodePacked(_unit)) == keccak256(abi.encodePacked("gwei"))) {
            _price *= 1000000000;
        }
        else {
             revert();
        }
        require(msg.value == _price * 2);
        insert(PublicBoard, Pseller, payable(msg.sender), _name, _price, payable(msg.sender), payable(msg.sender), _message, _time, _picture, _moreMsg);
        MarketBoard.push(Goods(_name, _price, userAddr(payable(msg.sender), payable(msg.sender)), _message, _time, isUserAllow(false, false, false), ipfsHash(_picture, _moreMsg)));
        totalGoods++;
        
        emit sellEvent(msg.sender, Goods(_name, _price, userAddr(payable(msg.sender), payable(msg.sender)), _message, _time, isUserAllow(false, false, false), ipfsHash(_picture, _moreMsg)));
    }
    
    function Buy(address payable _sellerAddr, string memory _name, uint256 _count) checker()
    public payable {
        require(msg.value == PublicBoard.board[_sellerAddr][_count].price * 2);
        insert(SellerBoard, Seller, _sellerAddr, _name, PublicBoard.board[_sellerAddr][_count].price, payable(msg.sender), _sellerAddr, PublicBoard.board[_sellerAddr][_count].message, block.timestamp+(PublicBoard.board[_sellerAddr][_count].time * 1 days), PublicBoard.board[_sellerAddr][_count].hash.picture, PublicBoard.board[_sellerAddr][_count].hash.moreMsg);
        insert(BuyerBoard, Buyer, payable(msg.sender), _name, PublicBoard.board[_sellerAddr][_count].price, payable(msg.sender), _sellerAddr, PublicBoard.board[_sellerAddr][_count].message, block.timestamp+(PublicBoard.board[_sellerAddr][_count].time * 1 days), PublicBoard.board[_sellerAddr][_count].hash.picture, PublicBoard.board[_sellerAddr][_count].hash.moreMsg);
        
        emit buyEvent(msg.sender, _sellerAddr, PublicBoard.board[_sellerAddr][_count]);
        remove(PublicBoard, Pseller, _sellerAddr, _count);
        removeArray(MarketBoard, _name);
        totalGoods--;
    }
    
    function Deal(string memory _name, uint256 _count) checker()
    public payable {
        Goods storage _g = BuyerBoard.board[msg.sender][_count];
        require(keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name)));
        BuyerBoard.board[msg.sender][_count].isAllow.isBuyerAllow = true;
        SellerBoard.board[_g.addr.sellerAddr][search(SellerBoard, Seller, _g.addr.sellerAddr, _name)].isAllow.isBuyerAllow = true;
        feedback(Buyer, _g.addr.buyerAddr, checkCredits(Seller, _g.addr.sellerAddr), _g.price, _g.isAllow.isBuyerAllow);
        if(checkCredits(Seller, _g.addr.sellerAddr) > 0)
            subCredits(Seller, _g.addr.sellerAddr, _g.price);
        feedback(Seller, _g.addr.sellerAddr, checkCredits(Buyer, _g.addr.buyerAddr), _g.price, _g.isAllow.isBuyerAllow);
        if(checkCredits(Buyer, _g.addr.buyerAddr) > 0)
            subCredits(Buyer, _g.addr.buyerAddr, _g.price);
        pay(BuyerBoard, Buyer, payable(msg.sender), _count, 1, owner);
        pay(BuyerBoard, Seller, payable(msg.sender), _count, 3, owner);
        
        emit dealEvent(msg.sender, _g.addr.sellerAddr, _g);
        remove(SellerBoard, Seller, _g.addr.sellerAddr, search(SellerBoard, Seller, _g.addr.sellerAddr, _name));
        remove(BuyerBoard, Buyer, _g.addr.buyerAddr, _count);
    }
    
    function NoDeal(string memory _name, uint256 _count) checker()
    public payable {
        Goods storage _g = BuyerBoard.board[msg.sender][_count];
        require(keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name)) && _g.isAllow.isDealFlag == false);
        feedback(Seller, _g.addr.sellerAddr,  checkCredits(Buyer, _g.addr.buyerAddr), _g.price, _g.isAllow.isBuyerAllow);
        if(checkCredits(Buyer, _g.addr.buyerAddr) > 0)
            subCredits(Buyer, _g.addr.buyerAddr, _g.price);
        BuyerBoard.board[msg.sender][_count].isAllow.isDealFlag = true;
        SellerBoard.board[_g.addr.sellerAddr][search(SellerBoard, Seller, _g.addr.sellerAddr, _name)].isAllow.isDealFlag = true;
        
        emit noDealEvent(msg.sender, _g.addr.sellerAddr, _g);
    }
    
    function ForceDeal(string memory _name, uint256 _count) checker()
    public payable {
        Goods storage _g = BuyerBoard.board[msg.sender][_count];
        require((keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name))) && ((_g.isAllow.isDealFlag == true) && (block.timestamp >= (_g.time + (10 days)))));
        _g.isAllow.isSellerAllow = true;
        SellerBoard.board[_g.addr.sellerAddr][search(SellerBoard, Seller, _g.addr.sellerAddr, _name)].isAllow.isSellerAllow = true;
        feedback(Buyer, _g.addr.buyerAddr, checkCredits(Seller, _g.addr.sellerAddr), _g.price, _g.isAllow.isSellerAllow);
        if(checkCredits(Seller, _g.addr.sellerAddr) > 0)
            subCredits(Seller, _g.addr.sellerAddr, _g.price);
        feedback(Seller, _g.addr.sellerAddr, checkCredits(Buyer, _g.addr.buyerAddr), _g.price, _g.isAllow.isBuyerAllow);
        if(checkCredits(Buyer, _g.addr.buyerAddr) > 0)
            subCredits(Buyer, _g.addr.buyerAddr, _g.price);
        pay(BuyerBoard, Buyer, payable(msg.sender), _count, 1, owner);
        pay(BuyerBoard, Seller, payable(msg.sender), _count, 3, owner);
        
        emit forceDealEvent(msg.sender, _g.addr.sellerAddr, _g);
        remove(SellerBoard, Seller, _g.addr.sellerAddr, search(SellerBoard, Seller, _g.addr.sellerAddr, _name));
        remove(BuyerBoard, Buyer, _g.addr.buyerAddr, _count);
    }
    
    function PosFeedback(string memory _name, uint256 _count) checker()
    public payable {
        Goods storage _g = SellerBoard.board[msg.sender][_count];
        require((keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name))) && ((_g.isAllow.isDealFlag == true) || (block.timestamp >= (_g.time + (7 days)))));
        if(_g.isAllow.isDealFlag == false && block.timestamp >= (_g.time + (7 days))) {
            BuyerBoard.board[_g.addr.buyerAddr][search(BuyerBoard, Buyer, _g.addr.buyerAddr, _name)].isAllow.isBuyerAllow = true;
            _g.isAllow.isBuyerAllow = true;
        }
        BuyerBoard.board[_g.addr.buyerAddr][search(BuyerBoard, Buyer, _g.addr.buyerAddr, _name)].isAllow.isSellerAllow = true;
        _g.isAllow.isSellerAllow = true;
        pay(BuyerBoard, Buyer, _g.addr.buyerAddr, _count, 1, owner);
        pay(BuyerBoard, Seller, _g.addr.buyerAddr, _count, 3, owner);
        feedback(Buyer, _g.addr.buyerAddr, checkCredits(Seller, _g.addr.sellerAddr), _g.price, _g.isAllow.isSellerAllow);
        if(checkCredits(Seller, _g.addr.sellerAddr) > 0)
            subCredits(Seller, _g.addr.sellerAddr, _g.price);
        
        emit PosEvent(msg.sender, _g.addr.buyerAddr, _g);
        remove(BuyerBoard, Buyer, _g.addr.buyerAddr, search(BuyerBoard, Buyer, _g.addr.buyerAddr, _name));
        remove(SellerBoard, Seller, _g.addr.sellerAddr,  _count);
    }
    
    function NegFeedback(string memory _name,  uint256 _count) checker()
    public payable {
        Goods storage _g = SellerBoard.board[msg.sender][_count];
        require((keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name))) && ((_g.isAllow.isDealFlag == true) || (block.timestamp >= (_g.time + (7 days)))));
        if(_g.isAllow.isDealFlag == false && block.timestamp >= (_g.time + (7 days))) {
            BuyerBoard.board[_g.addr.buyerAddr][search(BuyerBoard, Buyer, _g.addr.buyerAddr, _name)].isAllow.isBuyerAllow = true;
            _g.isAllow.isBuyerAllow = true;
        }
        pay(BuyerBoard, Buyer, _g.addr.buyerAddr, _count, 1, owner);
        pay(BuyerBoard, Seller, _g.addr.buyerAddr, _count, 3, owner);
        feedback(Buyer, _g.addr.buyerAddr, checkCredits(Seller, _g.addr.sellerAddr), _g.price, _g.isAllow.isSellerAllow);
        if(checkCredits(Seller, _g.addr.sellerAddr) > 0)
            subCredits(Seller, _g.addr.sellerAddr, _g.price);
            
        emit NegEvent(msg.sender, _g.addr.buyerAddr, _g);
        remove(BuyerBoard, Buyer, _g.addr.buyerAddr, search(BuyerBoard, Buyer, _g.addr.buyerAddr, _name));
        remove(SellerBoard, Seller, _g.addr.sellerAddr,  _count);
    }
    
    function CheckUserRec(address addr, string memory _user)
    public view returns(uint256, uint256, uint256) {
        if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("buyer"))) {
            return(checkRec(Buyer, addr));
        }
        else if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("seller"))) {
            return(checkRec(Seller, addr));
        }
        else {
            revert();
        }
    }
    
    function ChechUserCredits(address _addr, string memory _user)
    public view returns(uint256) {
        if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("buyer"))) {
            uint256 i = findUser(Buyer, _addr);
            return(Buyer[i].credits);
        }
        else if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("seller"))) {
            uint256 i = findUser(Seller, _addr);
            return(Seller[i].credits);
        }
        else {
            revert();
        }
    }
}