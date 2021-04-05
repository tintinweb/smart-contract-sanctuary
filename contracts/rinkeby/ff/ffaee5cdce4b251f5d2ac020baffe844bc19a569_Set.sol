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