/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

pragma solidity 0.8.0;
//SPDX-License-Identifier: UNLICENSED

library Set {
    struct Board {
        mapping(address => mapping(uint256 => Goods)) board;
    }
    
    struct User {
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
        bool buyerAllow;
        bool sellerAllow;
        bool flag;
    }
    
    function insert(Board storage self, User[] storage user, address payable _addr,
    string memory _name, uint256 _price, address payable _buyer_addr, address payable _seller_addr) internal {
        uint256 i;
        for(i = 0; i < user.length; i++) {
            if(user[i].wallet == _addr) {
                break;
            }
        }
        self.board[user[i].wallet][user[i].count] = Goods(_name, _price, _buyer_addr, _seller_addr, false, false, false);
        user[i].count += 1;
    }
    
    function remove(Board storage self, User[] storage user, address payable _addr, uint256 count) internal {
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
    
    function check(User[] storage user) internal view returns(bool) {
        bool flag = false;
        for(uint256 i = 0; i < user.length; i++) {
            if(user[i].wallet == msg.sender) {
                flag = true;
                break;
            }
        }
        return flag;
    }
    
    function register(User[] storage user, address payable _addr) internal {
        Set.User memory temp;
        temp.wallet = _addr;
        temp.count = 0;
        temp.PosRec = 5;
        temp.TradeRec = 10;
        temp.StdRec = 50;
        user.push(temp);
    }
    
    function finding(Board storage self, User[] storage user, string memory _name, uint256 num)
    public view returns(address payable, uint256, uint256) {
        Goods[100] memory searchBoard;
        uint256[100] memory _count;
        uint256 k = 0;
        bool flag = true;
        for(uint256 i = 0; i < user.length && flag; i++) {
            for(uint256 j = 0; j < user[i].count && flag; j++) {
                if(keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(self.board[user[i].wallet][j].name))) {
                    searchBoard[k] = Goods(_name, self.board[user[i].wallet][j].price, user[i].wallet, user[i].wallet, false, false, false);
                    _count[k] = j;
                    k++;
                }
                if(k > num) {
                    flag = false;
                }
            }
        }
        return (searchBoard[num].seller_addr, _count[num], searchBoard[num].price);
    }
    
    function search(Board storage self, User[] storage user, address payable _addr, string memory _name) 
    public view returns(uint256) {
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
    public view returns(string memory, uint256, address payable) {
        string memory _name;
        uint256 _price;
        address payable _sellerAddr;
        _name = self.board[_addr][_count].name;
        _price = self.board[_addr][_count].price;
        _sellerAddr = self.board[_addr][_count].seller_addr;
        return(_name, _price, _sellerAddr);
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
    public view returns(bool, bool) {
        return (self.board[_addr][_count].buyerAllow, self.board[_addr][_count].sellerAllow);
    }
    
    function pay(Board storage self, User[] storage user, address payable _addr, uint256 _count, uint256 n) internal {
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
    
    function checkRec(User[] storage user, address _addr) public view returns(uint256, uint256, uint256) {
        uint256 i = 0;
        while(user[i].wallet != _addr) {
            i++;
        }
        return(user[i].PosRec, user[i].TradeRec, user[i].StdRec);
    }
}


contract Marketplace {
    using Set for Set.Board;
    using Set for Set.User[];
    address internal owner;
    Set.Board PublicBoard;
    Set.Board SellerBoard;
    Set.Board BuyerBoard;
    Set.User[] internal Pseller;
    Set.User[] internal seller;
    Set.User[] internal buyer;
    constructor() {
        owner = msg.sender;
    }
    
    fallback() external payable {
        revert("invalid function");
    }
    receive() external payable {
        revert("invalid data");
    }
    
    modifier checker() {
        require(seller.check() && buyer.check());
        _;
    }
    
    function SignUp() public {
        Pseller.register(payable(msg.sender));
        seller.register(payable(msg.sender));
        buyer.register(payable(msg.sender));
    }
    
    function Sell(string memory _name, uint256 _price, string memory _unit) checker() public payable {
        if(keccak256(abi.encodePacked(_unit)) == keccak256(abi.encodePacked("ether"))) {
            _price *= 1 ether;
        }
        else if(keccak256(abi.encodePacked(_unit)) != keccak256(abi.encodePacked("wei"))) {
            revert("invalid unit");
        }
        require(msg.value == _price * 2);
        PublicBoard.insert(Pseller, payable(msg.sender), _name, _price, payable(msg.sender), payable(msg.sender));
    }
    
    function FindingGoods(string memory _name, uint256 _num) public view returns(address payable, uint256, uint256) {
        return (PublicBoard.finding(Pseller, _name, _num));
    }
    
    function ViewPublicBoard(address _addr, uint256 _count) public view returns(string memory, uint256, address payable) {
        return(PublicBoard.viewBoard(_addr, _count));
    }
    
    function ViewSellerBoard(uint256 _count) checker()
    public view returns(string memory, uint256, address payable) {
        return(SellerBoard.viewBoard(msg.sender, _count));
    }
    
    function ViewBuyerBoard(uint256 _count) checker()
    public view returns(string memory, uint256, address payable) {
        return(BuyerBoard.viewBoard(msg.sender, _count));
    }
    
    function Buy(address payable SellerAddr, string memory _name, uint256 _count) checker() public payable {
        uint256 GoodsPrice = PublicBoard.board[SellerAddr][_count].price;
        require(msg.value == GoodsPrice * 2);
        SellerBoard.insert(seller, SellerAddr, _name, GoodsPrice, payable(msg.sender), SellerAddr);
        BuyerBoard.insert(buyer, payable(msg.sender), _name, GoodsPrice, payable(msg.sender), SellerAddr);
        PublicBoard.remove(Pseller, SellerAddr, _count);
    }
    
    function Deal(string memory _name, uint256 _count) checker() public payable {
        Set.Goods storage _g = BuyerBoard.board[msg.sender][_count];
        require(keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name)));
        SellerBoard.userAllow(_g.seller_addr, SellerBoard.search(seller, _g.seller_addr, _name));
        BuyerBoard.userAllow(payable(msg.sender), _count);
        (_g.buyerAllow, _g.sellerAllow) = BuyerBoard.checkAllow(payable(msg.sender), _count);
        buyer.feedback(_g.buyer_addr, _g.price, _g.buyerAllow);
        seller.feedback(_g.seller_addr, _g.price, _g.buyerAllow);
        BuyerBoard.pay(buyer, payable(msg.sender), _count, 1);
        BuyerBoard.pay(seller, payable(msg.sender), _count, 3);
        SellerBoard.remove(seller, _g.seller_addr, SellerBoard.search(seller, _g.seller_addr, _name));
        BuyerBoard.remove(buyer, _g.buyer_addr, _count);
    }
    
    function NotDeal(string memory _name, uint256 _count) checker() public payable {
        Set.Goods storage _g = BuyerBoard.board[msg.sender][_count];
        require(keccak256(abi.encodePacked(_g.name)) == keccak256(abi.encodePacked(_name)));
        (_g.buyerAllow, _g.sellerAllow) = BuyerBoard.checkAllow(payable(msg.sender), _count);
        seller.feedback(_g.seller_addr, _g.price, _g.buyerAllow);
        BuyerBoard.board[msg.sender][_count].flag = true;
        SellerBoard.board[_g.seller_addr][SellerBoard.search(seller, _g.seller_addr, _name)].flag = true;
    }
    
    function PosFeedback(string memory _name, uint256 _count) checker() public payable {
        Set.Goods storage _g = SellerBoard.board[msg.sender][_count];
        require(SellerBoard.board[msg.sender][_count].flag == true);
        BuyerBoard.userAllow(_g.buyer_addr, BuyerBoard.search(buyer, _g.buyer_addr, _name));
        SellerBoard.userAllow(payable(msg.sender), _count);
        (_g.buyerAllow, _g.sellerAllow) = BuyerBoard.checkAllow(_g.buyer_addr, _count);
        BuyerBoard.pay(buyer, _g.buyer_addr, _count, 1);
        BuyerBoard.pay(seller, _g.buyer_addr, _count, 3);
        buyer.feedback(_g.buyer_addr, _g.price, _g.sellerAllow);
        BuyerBoard.remove(buyer, _g.buyer_addr, BuyerBoard.search(buyer, _g.buyer_addr, _name));
        SellerBoard.remove(seller, _g.seller_addr,  _count);
    }
    
    function NegFeedback(string memory _name,  uint256 _count) checker() public payable {
        Set.Goods storage _g = SellerBoard.board[msg.sender][_count];
        require(SellerBoard.board[msg.sender][_count].flag == true);
        (_g.buyerAllow, _g.sellerAllow) = BuyerBoard.checkAllow(_g.buyer_addr, _count);
        BuyerBoard.pay(buyer, _g.buyer_addr, _count, 1);
        BuyerBoard.pay(seller, _g.buyer_addr, _count, 3);
        buyer.feedback(_g.buyer_addr, _g.price, _g.sellerAllow);
        BuyerBoard.remove(buyer, _g.buyer_addr, BuyerBoard.search(buyer, _g.buyer_addr, _name));
        SellerBoard.remove(seller, _g.seller_addr,  _count);
    }
    
    function CheckMyRec(string memory _user) public view returns(uint256, uint256, uint256) {
        if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("buyer"))) {
            return(buyer.checkRec(msg.sender));
        }
        else if(keccak256(abi.encodePacked(_user)) == keccak256(abi.encodePacked("seller"))) {
            return(seller.checkRec(msg.sender));
        }
        else {
            revert("invalid user");
        }
    }
}