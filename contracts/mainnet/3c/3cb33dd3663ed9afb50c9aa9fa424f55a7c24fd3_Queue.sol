pragma solidity ^0.4.11;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract Queue {
    using SafeMath for uint256;
    address[] users;
    mapping(address => bool) usersExist;
    mapping(address => address) users2users;
    mapping(address => uint256) collectBalances;
    mapping(address => uint256) balances;
    mapping(address => uint256) balancesTotal;
    uint256 nextForwardUserId = 0;
    uint256 nextBackUserId = 0;
    uint256 cyles = 50;
    uint256 interes = 10 finney;
    uint256 reminder=0;
    uint256 price = 20 finney;
    uint256 referalBonus = 5 finney;
    uint256 queueInteres = 100 szabo;
    address to;
    uint256 collect = 30 finney;
    
    event QueueStart(address indexed user, address indexed parentUser, uint256 indexed timeshtamp);
    event BalanceUp(address indexed user, uint256 amount, uint256 indexed timeshtamp);
    event GetMyMoney(address indexed user, uint256 amount, uint256 indexed timeshtamp);
    
    function () payable public {
        msg.sender.transfer(msg.value);
    }
    
    function startQueue(address parentUser) payable public {
        require(msg.value == price);
        require(msg.sender != address(0));
        require(parentUser != address(0));
        require(!usersExist[msg.sender]);
        _queue(msg.sender, parentUser);
    }
    
    function serchIndexByAddress(address a) public view returns (uint256 index) {
        for(index=0; index<users.length; index++) {
            if(a == users[index]){
                return index;
            }
        }
    }
    
    function _removeIndex(uint256 indexToRemove) internal {
        if (indexToRemove >= users.length) return;

        for (uint i = indexToRemove; i<users.length-1; i++){
            users[i] = users[i+1];
        }
        delete users[users.length-1];
        users.length--;
    }
    
    function _queue(address user, address parentUser) internal {
        if (user != address(0x9a965e5e9c3A0F062C80a7f3d1B0972201b2F19f) ) {
            require(parentUser!=user);
            require(usersExist[parentUser]);
        }
        users.push(user);
        usersExist[user]=true;
        users2users[user]=parentUser;
        emit QueueStart(user, parentUser, now);
        
        if (collectBalances[parentUser].add(referalBonus) >= collect){
            reminder = collectBalances[parentUser].add(referalBonus) - collect;
            balancesTotal[parentUser] = balancesTotal[parentUser].add(interes);
            balances[parentUser] = balances[parentUser].add(interes);
            emit BalanceUp(parentUser, interes, now);
            collectBalances[parentUser] = reminder;
            to = parentUser;
            _removeIndex(serchIndexByAddress(parentUser));
            _queue(to, users2users[to]);
        }else{
            collectBalances[parentUser] = collectBalances[parentUser].add(referalBonus);
        }
        
        if (collectBalances[users2users[parentUser]].add(referalBonus) >= collect){
            reminder = collectBalances[users2users[parentUser]].add(referalBonus) - collect;
            balancesTotal[users2users[parentUser]] = balancesTotal[users2users[parentUser]].add(interes);
            balances[users2users[parentUser]] = balances[users2users[parentUser]].add(interes);
            emit BalanceUp(users2users[parentUser], interes, now);
            collectBalances[users2users[parentUser]] = reminder;
            to = users2users[parentUser];
            _removeIndex(serchIndexByAddress(users2users[parentUser]));
            _queue(to, users2users[to]);
        }else{
            collectBalances[users2users[parentUser]] = collectBalances[users2users[parentUser]].add(referalBonus);
        }
        
        uint256 length = users.length;
        uint256 existLastIndex = length.sub(1);
        uint256 firstHalfEnd = 0;
        uint256 secondHalfStart = 0;
        
        if (length == 1 ){
            collectBalances[users[0]] = collectBalances[users[0]].add(queueInteres.mul(cyles.mul(2)));
        }else{
            if (length % 2 != 0) {
                firstHalfEnd  = length.div(2);
                secondHalfStart  = length.div(2);
            }else{
                firstHalfEnd  = length.div(2).sub(1);
                secondHalfStart  = length.div(2);
            }
            
            for (uint i = 1; i <= cyles; i++) {
                if(collectBalances[users[nextForwardUserId]].add(queueInteres) >= collect){
                    reminder = collectBalances[users[nextForwardUserId]].add(queueInteres) - collect;
                    balancesTotal[users[nextForwardUserId]] = balancesTotal[users[nextForwardUserId]].add(interes);
                    balances[users[nextForwardUserId]] = balances[users[nextForwardUserId]].add(interes);
                    collectBalances[users[nextForwardUserId]] = reminder;
                    emit BalanceUp(users[nextForwardUserId], interes, now);
                    to = users[nextForwardUserId];
                    _removeIndex(serchIndexByAddress(users[nextForwardUserId]));
                    _queue(to, users2users[to]);
                    if (nextForwardUserId == 0){
                        nextForwardUserId = firstHalfEnd;
                    }else{
                        nextForwardUserId = nextForwardUserId.sub(1);
                    }
                }else{
                    collectBalances[users[nextForwardUserId]] = collectBalances[users[nextForwardUserId]].add(queueInteres);
                }
                if(collectBalances[users[nextBackUserId]].add(queueInteres) == collect){
                    reminder = collectBalances[users[nextBackUserId]].add(queueInteres) - collect;
                    balancesTotal[users[nextBackUserId]] = balancesTotal[users[nextBackUserId]].add(interes);
                    balances[users[nextBackUserId]] = balances[users[nextBackUserId]].add(interes);
                    collectBalances[users[nextBackUserId]] = reminder;
                    emit BalanceUp(users[nextBackUserId], interes, now);
                    to = users[nextBackUserId];
                    _removeIndex(serchIndexByAddress(users[nextBackUserId]));
                    _queue(to, users2users[to]);
                    if (nextBackUserId == existLastIndex){
                        nextBackUserId = secondHalfStart;
                    }else{
                        nextBackUserId = nextBackUserId.add(1);
                    }
                }else{
                    collectBalances[users[nextBackUserId]] = collectBalances[users[nextBackUserId]].add(queueInteres);
                }
            }
        }
    }
    
    function getMyMoney() public {
        require(balances[msg.sender]>0);
        msg.sender.transfer(balances[msg.sender]);
        emit GetMyMoney(msg.sender, balances[msg.sender], now);
        balances[msg.sender]=0;
    }
    
    function balanceOf(address who) public view returns (uint256 balance) {
        return balances[who];
    }
    
    function balanceTotalOf(address who) public view returns (uint256 balanceTotal) {
        return balancesTotal[who];
    }
    
    function getNextForwardUserId() public view returns (uint256) {
        return nextForwardUserId;
    }
    
    function getNextBackUserId() public view returns (uint256) {
        return nextBackUserId;
    }
    
    function getLastIndex() public view returns (uint256) {
        uint256 length = users.length;
        return length.sub(1);
    }
    
    function getUserAddressById(uint256 id) public view returns (address userAddress) {
        return users[id];
    }
    
    function checkExistAddress(address user) public view returns (bool) {
        return usersExist[user];
    }
    
    function getParentUser(address user) public view returns (address) {
        return users2users[user];
    }
}