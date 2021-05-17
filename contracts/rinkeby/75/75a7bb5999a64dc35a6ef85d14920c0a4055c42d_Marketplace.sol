/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity 0.8.0;
//SPDX-License-Identifier: UNLICENSED


contract Marketplace {
    
    struct Board {
        mapping(address => mapping(uint256 => Goods)) board;
    }
    
    struct User {
        string id;
        address payable wallet;
        uint256 count;
        uint256 PosRec;
        uint256 TradeRec;
        uint256 StdRec;
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
    
    function insert(Board storage self, User[] storage user, address payable _addr,
    string memory _name, uint256 _price, address payable _buyerAddr, address payable _sellerAddr, string memory _message, uint256 _time, string memory _picture, string memory _moreMsg)
    internal {
        uint256 i;
        for(i = 0; i < user.length; i++) {
            if(user[i].wallet == _addr) {
                break;
            }
        }
        self.board[user[i].wallet][user[i].count] = Goods(_name, _price, userAddr(_buyerAddr, _sellerAddr), _message, _time, isUserAllow(false, false, false), ipfsHash(_picture, _moreMsg));
        user[i].count += 1;
    }
    
    function remove(Board storage self, User[] storage user, address payable _addr, uint256 count)
    internal {
        uint256 i;
        for(i = 0; i < user.length; i++) {
            if(user[i].wallet == _addr) {
                break;
            }
        }
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
        temp.PosRec = 5;
        temp.TradeRec = 10;
        temp.StdRec = 50;
        user.push(temp);
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
        uint256 i;
        for(i = 0; i < user.length; i++) {
            if(user[i].wallet == _addr)
                break;
        }
        return(user[i].id);
    }
    
    function findAddr(User[] storage user, string memory _id)
    internal view returns(address payable) {
        uint256 i;
        for(i = 0; i < user.length; i++) {
            if(keccak256(abi.encodePacked(user[i].id)) == keccak256(abi.encodePacked(_id)))
                break;
        }
        return(user[i].wallet);
    }
    
    function findCount(User[] storage user, address _addr)
    internal view returns(uint256) {
        uint256 i;
        for(i = 0; i < user.length; i++) {
            if(user[i].wallet == _addr)
                break;
        }
        return(user[i].count);
    }
    
    function search(Board storage self, User[] storage user, address payable _addr, string memory _name) 
    internal view returns(uint256) {
        uint256 i;
        uint256 j;
        for(i = 0; i < user.length; i++) {
            if(user[i].wallet == _addr)
                break;
        }
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
            uint256 _score = (user[i].PosRec * 100)/user[i].TradeRec;
            if(_score >= user[i].StdRec) {
                _payAddr.transfer(_price * 2);
                if(_score < 90) {
                    user[i].StdRec += 10;
                }
            }
            else {
                _owner.transfer(_price * 2);
            }
        }
    }
    
    function feedback(User[] storage user, address payable _addr, uint256 _price, bool _allow)
    internal {
        uint256 i = 0;
        for(i = 0; i < user.length; i++) {
            if(user[i].wallet == _addr)
                break;
        }
        user[i].TradeRec += _price;
        if(_allow) {
            user[i].PosRec += _price;
        }
    }
    
    function checkRec(User[] storage user, address _addr) 
    internal view returns(uint256, uint256, uint256) {
        uint256 i = 0;
        for(i = 0; i < user.length; i++) {
            if(user[i].wallet == _addr)
                break;
        }
        return(user[i].PosRec, user[i].TradeRec, user[i].StdRec);
    }
    
    address payable internal owner;
    uint256 public totalGoods;
    Board PublicBoard;
    Board SellerBoard;
    Board BuyerBoard;
    Goods[] MarketBoard;
    User[] internal Pseller;
    User[] internal seller;
    User[] internal buyer;
    
    constructor() {
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
        require(check(seller) && check(buyer) && check(Pseller));
        _;
    }
    
    function SignUp(string memory _id)
    public {
        require(!(check(seller) || check(buyer) || check(Pseller)));
        register(Pseller, payable(msg.sender), _id);
        register(seller, payable(msg.sender), _id);
        register(buyer, payable(msg.sender), _id);
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
    }
    
    function FindingGoods(string memory _name, uint256 _num)
    public view returns(address payable, uint256, uint256, string memory, uint256) {
        return(finding(PublicBoard, Pseller, _name, _num));
    }
    
    function FindUserID(address payable _addr)
    public view returns(string memory) {
        return(findID(seller, _addr));
    }
    
    function FindUserAddr(string memory _id)
    public view returns(address) {
        return(findAddr(seller, _id));
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
            return(findCount(buyer, _addr));
        }
        else if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("seller"))) {
            return(findCount(seller, _addr));
        }
        else{
            revert();
        }
    }
    
    function Buy(address payable _sellerAddr, string memory _name, uint256 _count) checker()
    public payable {
        require(msg.value == PublicBoard.board[_sellerAddr][_count].price * 2);
        insert(SellerBoard, seller, _sellerAddr, _name, PublicBoard.board[_sellerAddr][_count].price, payable(msg.sender), _sellerAddr, PublicBoard.board[_sellerAddr][_count].message, block.timestamp+(PublicBoard.board[_sellerAddr][_count].time * 1 days), PublicBoard.board[_sellerAddr][_count].hash.picture, PublicBoard.board[_sellerAddr][_count].hash.moreMsg);
        insert(BuyerBoard, buyer, payable(msg.sender), _name, PublicBoard.board[_sellerAddr][_count].price, payable(msg.sender), _sellerAddr, PublicBoard.board[_sellerAddr][_count].message, block.timestamp+(PublicBoard.board[_sellerAddr][_count].time * 1 days), PublicBoard.board[_sellerAddr][_count].hash.picture, PublicBoard.board[_sellerAddr][_count].hash.moreMsg);
        remove(PublicBoard, Pseller, _sellerAddr, _count);
        removeArray(MarketBoard, _name);
        totalGoods--;
    }
    
    function Deal(string memory _name, uint256 _count) checker()
    public payable {
        Goods storage _g = BuyerBoard.board[msg.sender][_count];
        require(keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name)));
        BuyerBoard.board[msg.sender][_count].isAllow.isBuyerAllow = true;
        SellerBoard.board[_g.addr.sellerAddr][search(SellerBoard, seller, _g.addr.sellerAddr, _name)].isAllow.isBuyerAllow = true;
        feedback(buyer, _g.addr.buyerAddr, _g.price, _g.isAllow.isBuyerAllow);
        feedback(seller, _g.addr.sellerAddr, _g.price, _g.isAllow.isBuyerAllow);
        pay(BuyerBoard, buyer, payable(msg.sender), _count, 1, owner);
        pay(BuyerBoard, seller, payable(msg.sender), _count, 3, owner);
        remove(SellerBoard, seller, _g.addr.sellerAddr, search(SellerBoard, seller, _g.addr.sellerAddr, _name));
        remove(BuyerBoard, buyer, _g.addr.buyerAddr, _count);
    }
    
    function NotDeal(string memory _name, uint256 _count) checker()
    public payable {
        Goods storage _g = BuyerBoard.board[msg.sender][_count];
        require(keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name)) && _g.isAllow.isDealFlag == false);
        feedback(seller, _g.addr.sellerAddr, _g.price, _g.isAllow.isBuyerAllow);
        BuyerBoard.board[msg.sender][_count].isAllow.isDealFlag = true;
        SellerBoard.board[_g.addr.sellerAddr][search(SellerBoard, seller, _g.addr.sellerAddr, _name)].isAllow.isDealFlag = true;
    }
    
    function ForceDeal(string memory _name, uint256 _count) checker()
    public payable {
        Goods storage _g = BuyerBoard.board[msg.sender][_count];
        require((keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name))) && ((_g.isAllow.isDealFlag == true) && (block.timestamp >= (_g.time + (10 days)))));
        _g.isAllow.isSellerAllow = true;
        SellerBoard.board[_g.addr.sellerAddr][search(SellerBoard, seller, _g.addr.sellerAddr, _name)].isAllow.isSellerAllow = true;
        feedback(buyer, _g.addr.buyerAddr, _g.price, _g.isAllow.isSellerAllow);
        feedback(seller, _g.addr.sellerAddr, _g.price, _g.isAllow.isBuyerAllow);
        pay(BuyerBoard, buyer, payable(msg.sender), _count, 1, owner);
        pay(BuyerBoard, seller, payable(msg.sender), _count, 3, owner);
        remove(SellerBoard, seller, _g.addr.sellerAddr, search(SellerBoard, seller, _g.addr.sellerAddr, _name));
        remove(BuyerBoard, buyer, _g.addr.buyerAddr, _count);
    }
    
    function PosFeedback(string memory _name, uint256 _count) checker()
    public payable {
        Goods storage _g = SellerBoard.board[msg.sender][_count];
        require((keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name))) && ((_g.isAllow.isDealFlag == true) || (block.timestamp >= (_g.time + (7 days)))));
        if(_g.isAllow.isDealFlag == false && block.timestamp >= (_g.time + (7 days))) {
            BuyerBoard.board[_g.addr.buyerAddr][search(BuyerBoard, buyer, _g.addr.buyerAddr, _name)].isAllow.isBuyerAllow = true;
            _g.isAllow.isBuyerAllow = true;
        }
        BuyerBoard.board[_g.addr.buyerAddr][search(BuyerBoard, buyer, _g.addr.buyerAddr, _name)].isAllow.isSellerAllow = true;
        _g.isAllow.isSellerAllow = true;
        pay(BuyerBoard, buyer, _g.addr.buyerAddr, _count, 1, owner);
        pay(BuyerBoard, seller, _g.addr.buyerAddr, _count, 3, owner);
        feedback(buyer, _g.addr.buyerAddr, _g.price, _g.isAllow.isSellerAllow);
        remove(BuyerBoard, buyer, _g.addr.buyerAddr, search(BuyerBoard, buyer, _g.addr.buyerAddr, _name));
        remove(SellerBoard, seller, _g.addr.sellerAddr,  _count);
    }
    
    function NegFeedback(string memory _name,  uint256 _count) checker()
    public payable {
        Goods storage _g = SellerBoard.board[msg.sender][_count];
        require((keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name))) && ((_g.isAllow.isDealFlag == true) || (block.timestamp >= (_g.time + (7 days)))));
        if(_g.isAllow.isDealFlag == false && block.timestamp >= (_g.time + (7 days))) {
            BuyerBoard.board[_g.addr.buyerAddr][search(BuyerBoard, buyer, _g.addr.buyerAddr, _name)].isAllow.isBuyerAllow = true;
            _g.isAllow.isBuyerAllow = true;
        }
        pay(BuyerBoard, buyer, _g.addr.buyerAddr, _count, 1, owner);
        pay(BuyerBoard, seller, _g.addr.buyerAddr, _count, 3, owner);
        feedback(buyer, _g.addr.buyerAddr, _g.price, _g.isAllow.isSellerAllow);
        remove(BuyerBoard, buyer, _g.addr.buyerAddr, search(BuyerBoard, buyer, _g.addr.buyerAddr, _name));
        remove(SellerBoard, seller, _g.addr.sellerAddr,  _count);
    }
    
    function CheckUserRec(address addr, string memory _user)
    public view returns(uint256, uint256, uint256) {
        if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("buyer"))) {
            return(checkRec(buyer, addr));
        }
        else if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("seller"))) {
            return(checkRec(seller, addr));
        }
        else {
            revert();
        }
    }
}