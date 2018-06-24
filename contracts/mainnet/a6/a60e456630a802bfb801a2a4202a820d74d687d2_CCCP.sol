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

contract CCCP {
    using SafeMath for uint256;
    address[] users;
    mapping(address => bool) usersExist;
    mapping(address => address) users2users;
    mapping(address => uint256) balances;
    mapping(address => uint256) balancesTotal;
    uint256 nextUserId = 0;
    uint256 cyles = 100;
    
    event Register(address indexed user, address indexed parentUser);
    event BalanceUp(address indexed user, uint256 amount);
    event ReferalBonus(address indexed user, uint256 amount);
    event GetMyMoney(address user, uint256 amount);
    
    function () payable public {
        msg.sender.transfer(msg.value);
    }

    function register(address parentUser) payable public{
        require(msg.value == 20 finney);
        require(msg.sender != address(0));
        require(parentUser != address(0));
        require(!usersExist[msg.sender]);
        _register(msg.sender, msg.value, parentUser);
    }
    
    function _register(address user, uint256 amount, address parentUser) internal {
        if (users.length > 0) {
            require(parentUser!=user);
            require(usersExist[parentUser]);
        }
        users.push(user);
        usersExist[user]=true;
        users2users[user]=parentUser;
        emit Register(user, parentUser);
        
        uint256 referalBonus = amount.div(2);
        
        balances[parentUser] = balances[parentUser].add(referalBonus.div(2));
        balancesTotal[parentUser] = balancesTotal[parentUser].add(referalBonus.div(2));
        emit ReferalBonus(parentUser, referalBonus.div(2));
        
        balances[users2users[parentUser]] = balances[users2users[parentUser]].add(referalBonus.div(2));
        balancesTotal[users2users[parentUser]] = balancesTotal[users2users[parentUser]].add(referalBonus.div(2));
        emit ReferalBonus(users2users[parentUser], referalBonus.div(2));
        
        uint256 length = users.length;
        uint256 existLastIndex = length.sub(1);
        
        for (uint i = 1; i <= cyles; i++) {
            nextUserId = nextUserId.add(1);
            if(nextUserId > existLastIndex){
                nextUserId = 0;
            }
            balances[users[nextUserId]] = balances[users[nextUserId]].add(referalBonus.div(cyles));
            balancesTotal[users[nextUserId]] = balancesTotal[users[nextUserId]].add(referalBonus.div(cyles));
            emit BalanceUp(users[nextUserId], referalBonus.div(cyles));
        }
    }
    
    function getMyMoney() public {
        require(balances[msg.sender]>0);
        msg.sender.transfer(balances[msg.sender]);
        emit GetMyMoney(msg.sender, balances[msg.sender]);
        balances[msg.sender]=0;
    }
    
    function balanceOf(address who) public constant returns (uint256 balance) {
        return balances[who];
    }
    
    function balanceTotalOf(address who) public constant returns (uint256 balanceTotal) {
        return balancesTotal[who];
    }
    
    function getNextUserId() public constant returns (uint256 nextUserId) {
        return nextUserId;
    }
    
    function getUserAddressById(uint256 id) public constant returns (address userAddress) {
        return users[id];
    }
}