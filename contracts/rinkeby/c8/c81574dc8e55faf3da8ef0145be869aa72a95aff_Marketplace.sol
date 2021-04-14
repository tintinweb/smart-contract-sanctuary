/**
 *Submitted for verification at Etherscan.io on 2021-04-14
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
    
    struct Goods {
        string name;
        uint256 price;
        address payable buyer_addr;
        address payable seller_addr;
        string message;
        bool buyerAllow;
        bool sellerAllow;
        bool flag;
    }
    
    function insert(Board storage self, User[] storage user, address payable _addr,
    string memory _name, uint256 _price, address payable _buyer_addr, address payable _seller_addr, string memory _message)
    internal {
        uint256 i;
        for(i = 0; i < user.length; i++) {
            if(user[i].wallet == _addr) {
                break;
            }
        }
        self.board[user[i].wallet][user[i].count] = Goods(_name, _price, _buyer_addr, _seller_addr, _message, false, false, false);
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
    internal view returns(address payable, uint256, uint256, string memory) {
        Goods[100] memory searchBoard;
        uint256[100] memory _count;
        uint256 k = 0;
        bool flag = true;
        for(uint256 i = 0; i < user.length && flag; i++) {
            for(uint256 j = 0; j < user[i].count && flag; j++) {
                if(keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(self.board[user[i].wallet][j].name))) {
                    searchBoard[k].price = self.board[user[i].wallet][j].price;
                    searchBoard[k].seller_addr = user[i].wallet;
                    searchBoard[k].message = self.board[user[i].wallet][j].message;
                    _count[k] = j;
                    k++;
                }
                if(k > num) {
                    flag = false;
                }
            }
        }
        return(searchBoard[num].seller_addr, _count[num], searchBoard[num].price, searchBoard[num].message);
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
            if(user[i].wallet == _addr) {
                break;
            }
        }
        for(j = 0; j < user[i].count; j++) {
            if(keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(self.board[_addr][j].name))) {
                break;
            }
        }
        return j;
    }
    
    function viewBoard(Board storage self, address _addr, uint256 _count)
    internal view returns(string memory, uint256, address payable, string memory) {
        return(self.board[_addr][_count].name, self.board[_addr][_count].price, self.board[_addr][_count].seller_addr, self.board[_addr][_count].message);
    }
    
    function removeArray(Goods[] storage array, string memory _name)
    internal {
        uint256 i;
        for(i = 0; i < array.length; i++){
            if(keccak256(abi.encodePacked(array[i].name)) == keccak256(abi.encodePacked(_name))) {
                break;
            }
        }
        for(uint256 j = i; j < array.length-1; j++) {
            array[j] = array[j+1];
        }
        delete array[array.length-1];
    }

    function userAllow(Board storage self, address payable _addr, uint256 _count)
    internal {
        if(msg.sender == self.board[_addr][_count].seller_addr) {
            self.board[_addr][_count].sellerAllow = true;
        }
        else {
            self.board[msg.sender][_count].buyerAllow = true;
        }
    }
    
    function checkAllow(Board storage self, address payable _addr, uint256 _count)
    internal view returns(bool, bool) {
        return(self.board[_addr][_count].buyerAllow, self.board[_addr][_count].sellerAllow);
    }
    
    function pay(Board storage self, User[] storage user, address payable _addr, uint256 _count, uint256 n, address payable _owner)
    internal {
        uint256 _price;
        address payable _payAddr;
        uint256 i = 0;
        uint256 m;
        _price = self.board[_addr][_count].price;
        if(n == 1) {
            _payAddr = _addr;
            m = 3;
        }
        else {
            _payAddr = self.board[_addr][_count].seller_addr;
            m = 1;
        }
        
        if(self.board[_addr][_count].buyerAllow) {
            _payAddr.transfer(_price * n);
        }
        else if(self.board[_addr][_count].sellerAllow) {
            _payAddr.transfer(_price * m);
        }
        else {
            while(user[i].wallet != _payAddr) {
                i++;
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
        while(user[i].wallet != _addr) {
            i++;
        }
        user[i].TradeRec += _price;
        if(_allow) {
            user[i].PosRec += _price;
        }
    }
    
    function checkRec(User[] storage user, address _addr) 
    internal view returns(uint256, uint256, uint256) {
        uint256 i = 0;
        while(user[i].wallet != _addr) {
            i++;
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
        revert("invalid function");
    }
    receive() external payable {
        revert("invalid data");
    }
    
    modifier checker() {
        require(check(seller) && check(buyer) && check(Pseller));
        _;
    }
    
    function SignUp(string memory _id)
    public {
        register(Pseller, payable(msg.sender), _id);
        register(seller, payable(msg.sender), _id);
        register(buyer, payable(msg.sender), _id);
    }
    
    function Sell(string memory _name, uint256 _price, string memory _unit, string memory _message) checker()
    public payable {
        if(keccak256(abi.encodePacked(_unit)) == keccak256(abi.encodePacked("ether"))) {
            _price *= 1 ether;
        }
        else if(keccak256(abi.encodePacked(_unit)) == keccak256(abi.encodePacked("gwei"))) {
            _price *= 1000000000;
        }
        else {
             revert("invalid unit");
        }
        require(msg.value == _price * 2);
        insert(PublicBoard, Pseller, payable(msg.sender), _name, _price, payable(msg.sender), payable(msg.sender), _message);
        MarketBoard.push(Goods(_name, _price, payable(msg.sender), payable(msg.sender), _message, false, false, false));
        totalGoods++;
    }
    
    function FindingGoods(string memory _name, uint256 _num)
    public view returns(address payable, uint256, uint256, string memory) {
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
    
    function FindUserRec(address payable _addr)
    public view returns(uint256) {
        uint256 _PosRec;
        uint256 _TradeRec;
        uint256 _StdRec;
        (_PosRec, _TradeRec, _StdRec) = checkRec(seller, _addr);
        return((_PosRec*100)/_TradeRec);
    }
    
    function ViewMarketBoard(uint256 _index)
    public view returns(string memory, uint256, address payable, string memory) {
        return(MarketBoard[_index].name, MarketBoard[_index].price, MarketBoard[_index].seller_addr, MarketBoard[_index].message);
    }
    
    function ViewPublicBoard(address _addr, uint256 _count)
    public view returns(string memory, uint256, address payable, string memory) {
        return(viewBoard(PublicBoard, _addr, _count));
    }
    
    function ViewSellerBoard(uint256 _count) checker()
    public view returns(string memory, uint256, address payable, string memory) {
        return(viewBoard(SellerBoard, msg.sender, _count));
    }
    
    function ViewBuyerBoard(uint256 _count) checker()
    public view returns(string memory, uint256, address payable, string memory) {
        return(viewBoard(BuyerBoard, msg.sender, _count));
    }
    
    function ViewCount(string memory _user, address _addr) checker()
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
            revert("invalid user");
        }
    }
    
    function Buy(address payable SellerAddr, string memory _name, uint256 _count) checker()
    public payable {
        require(msg.value == PublicBoard.board[SellerAddr][_count].price * 2);
        insert(SellerBoard, seller, SellerAddr, _name, PublicBoard.board[SellerAddr][_count].price, payable(msg.sender), SellerAddr, PublicBoard.board[SellerAddr][_count].message);
        insert(BuyerBoard, buyer, payable(msg.sender), _name, PublicBoard.board[SellerAddr][_count].price, payable(msg.sender), SellerAddr, PublicBoard.board[SellerAddr][_count].message);
        remove(PublicBoard, Pseller, SellerAddr, _count);
        removeArray(MarketBoard, _name);
        totalGoods--;
    }
    
    function Deal(string memory _name, uint256 _count) checker()
    public payable {
        Goods storage _g = BuyerBoard.board[msg.sender][_count];
        require(keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name)));
        userAllow(SellerBoard, _g.seller_addr, search(SellerBoard, seller, _g.seller_addr, _name));
        userAllow(BuyerBoard, payable(msg.sender), _count);
        (_g.buyerAllow, _g.sellerAllow) = checkAllow(BuyerBoard, payable(msg.sender), _count);
        feedback(buyer, _g.buyer_addr, _g.price, _g.buyerAllow);
        feedback(seller, _g.seller_addr, _g.price, _g.buyerAllow);
        pay(BuyerBoard, buyer, payable(msg.sender), _count, 1, owner);
        pay(BuyerBoard, seller, payable(msg.sender), _count, 3, owner);
        remove(SellerBoard, seller, _g.seller_addr, search(SellerBoard, seller, _g.seller_addr, _name));
        remove(BuyerBoard, buyer, _g.buyer_addr, _count);
    }
    
    function NotDeal(string memory _name, uint256 _count) checker()
    public payable {
        Goods storage _g = BuyerBoard.board[msg.sender][_count];
        require(keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name)));
        (_g.buyerAllow, _g.sellerAllow) = checkAllow(BuyerBoard, payable(msg.sender), _count);
        feedback(seller, _g.seller_addr, _g.price, _g.buyerAllow);
        BuyerBoard.board[msg.sender][_count].flag = true;
        SellerBoard.board[_g.seller_addr][search(SellerBoard, seller, _g.seller_addr, _name)].flag = true;
    }
    
    function PosFeedback(string memory _name, uint256 _count) checker()
    public payable {
        Goods storage _g = SellerBoard.board[msg.sender][_count];
        require(SellerBoard.board[msg.sender][_count].flag == true);
        userAllow(BuyerBoard, _g.buyer_addr, search(BuyerBoard, buyer, _g.buyer_addr, _name));
        userAllow(SellerBoard, payable(msg.sender), _count);
        (_g.buyerAllow, _g.sellerAllow) = checkAllow(BuyerBoard, _g.buyer_addr, _count);
        pay(BuyerBoard, buyer, _g.buyer_addr, _count, 1, owner);
        pay(BuyerBoard, seller, _g.buyer_addr, _count, 3, owner);
        feedback(buyer, _g.buyer_addr, _g.price, _g.sellerAllow);
        remove(BuyerBoard, buyer, _g.buyer_addr, search(BuyerBoard, buyer, _g.buyer_addr, _name));
        remove(SellerBoard, seller, _g.seller_addr,  _count);
    }
    
    function NegFeedback(string memory _name,  uint256 _count) checker()
    public payable {
        Goods storage _g = SellerBoard.board[msg.sender][_count];
        require(SellerBoard.board[msg.sender][_count].flag == true);
        (_g.buyerAllow, _g.sellerAllow) = checkAllow(BuyerBoard, _g.buyer_addr, _count);
        pay(BuyerBoard, buyer, _g.buyer_addr, _count, 1, owner);
        pay(BuyerBoard, seller, _g.buyer_addr, _count, 3, owner);
        feedback(buyer, _g.buyer_addr, _g.price, _g.sellerAllow);
        remove(BuyerBoard, buyer, _g.buyer_addr, search(BuyerBoard, buyer, _g.buyer_addr, _name));
        remove(SellerBoard, seller, _g.seller_addr,  _count);
    }
    
    function CheckMyRec(string memory _user)
    public view returns(uint256, uint256, uint256) {
        if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("buyer"))) {
            return(checkRec(buyer, msg.sender));
        }
        else if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("seller"))) {
            return(checkRec(seller, msg.sender));
        }
        else {
            revert("invalid user");
        }
    }
}