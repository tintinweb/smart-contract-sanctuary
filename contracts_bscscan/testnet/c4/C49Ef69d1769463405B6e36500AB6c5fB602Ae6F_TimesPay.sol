/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

pragma solidity >=0.5.0 <0.8.6;
// pragma experimental ABIEncoderV2;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract TimesPay {

    using SafeMath for uint256;
    
    address payable public owner;
    
    uint public defaultFee = 5;
    uint public feeDecimal = 10**3;
    
    struct Token {
        address tokenAddress;
        bool available;
        uint index;
    }

    struct Manager {
        address managerAddress;
        string permission;
        bool available;
        uint index;
    }

    struct Member {
        address payable memberAddress;
        // uint256 index;
        // string brandkey;
        uint256 fee;
        // uint256 userCount;
        // uint256 totalRecived;
        // uint256 totalPayout;
        // uint256 totalFee;
        uint256 timestamp;
        bool banned;
        uint32 orderCount;
    }

    struct Wallet {
        address tokenAddress;
        uint256 totalRecived;
        uint256 totalPayout;
        uint256 totalWithdraw;
        uint256 balance;
        uint256 totalFee;
        uint256 timestamp;
    }

    struct Order {
        string clientId;
        uint32 index;
        address charger;
        address tokenAddress;
        address payer;
        uint256 amount;
        uint256 fee;
        uint256 orderListIndex;
        uint256 paidAt;
        uint256 timestamp;
    }

    struct User {
        address payable userAddress;
        uint256 timestamp;
        uint32 orderCount;
    }
    
    
    mapping (address => Token) token;
    mapping (address => Manager) manager;
    mapping (address => Member) member;
    mapping (address => mapping (uint => Order)) order;
    mapping (string => Order) orderList;
    mapping (address => mapping(address => Wallet)) wallet;
    mapping (address => User) user;
    
    address[] TokenList;
    address[] ManagerList;
    string[] internal OrderIdList;

    constructor() public {
        owner = msg.sender;
    }

    // auth
    modifier onlyOwner() {
        require(msg.sender == owner, "Permission denied.");
        _;
    }

    modifier ownerOrManager() {
        require(msg.sender == owner || manager[msg.sender].available, "Permission denied");
        _;
    }
    
    // permission manage todo : add permission check
    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function isManager(address managerAddr) public view returns(bool) {
        Manager memory m = manager[managerAddr];
        return (m.available);
    }

    function getManagerList() ownerOrManager public view returns(address[] memory){
        return (ManagerList);
    }

    function getManager(address managerAddr) ownerOrManager public view returns(address managerAddress, bool available, string memory permission, uint index) {
        Manager memory m = manager[managerAddr];
        return (m.managerAddress, m.available, m.permission, m.index);
    }

    function setManager(address managerAddr, string memory _permission) ownerOrManager public returns(address managerAddress, bool available, string memory permission, uint index) {
        Manager memory m = manager[managerAddr];
        if(m.available) {
            manager[managerAddr].permission = _permission;
            return (m.managerAddress, m.available, m.permission, m.index);
        } else {
            manager[managerAddr].managerAddress = managerAddr;
            manager[managerAddr].available = true;
            manager[managerAddr].permission = _permission;
            manager[managerAddr].index = ManagerList.length;
            ManagerList.push(managerAddr);
            return (manager[managerAddr].managerAddress, manager[managerAddr].available, manager[managerAddr].permission, manager[managerAddr].index);
        }
    }

    function deleteManager(address managerAddr) ownerOrManager public returns(address[] memory){
        Manager memory m = manager[managerAddr];
        if(m.available) {
            for(uint i = m.index; i<ManagerList.length; i++) {
                ManagerList[i] = ManagerList[i+1];
            }
            ManagerList.pop();
            delete manager[managerAddr];
        }
        return (ManagerList);
    }
    
    // pool balance manage
    
    function poolMainBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function poolTokenBalance(address tokenAddr) public view returns (uint) {
        return ERC20(tokenAddr).balanceOf(address(this));
    }

    function withdrawPool(address[] memory assetList) public onlyOwner { //
        for(uint i=0;i<assetList.length;i++){
            if(poolTokenBalance(assetList[i]) > 0) {
                ERC20(assetList[i]).transfer(msg.sender, poolTokenBalance(assetList[i]));
            }
        }
        require(msg.sender.send(address(this).balance));
    }

    // token list manage
    function getTokenList() public view returns (address[] memory){
        return (TokenList);
    }

    function addToken(address tokenAddr) ownerOrManager public returns (address[] memory){
        Token memory t = token[tokenAddr];
        if(t.available) {
            return (TokenList);
        } else {
            token[tokenAddr].tokenAddress = tokenAddr;
            token[tokenAddr].available = true;
            token[tokenAddr].index = TokenList.length;
            TokenList.push(tokenAddr);
            return (TokenList);
        }
    }

    function deleteToken(address tokenAddr) ownerOrManager public returns (address[] memory){
        Token memory t = token[tokenAddr];
        if(!t.available) {
            return (TokenList);
        } else {
            for(uint256 i = t.index - 1 ;i < TokenList.length; i++) {
                TokenList[i] = TokenList[i+1];
            }
            TokenList.pop();
            delete token[tokenAddr];
            return (TokenList);
        }
    }


    // manage member method
    function setMemberFee(address addr, uint newFee) ownerOrManager public returns (address memberAddress, uint fee) {
        require(member[addr].timestamp > 0, "Member not registed");
        member[addr].fee = newFee;
        return (member[addr].memberAddress, member[addr].fee);
    }

    function bannedMember(address addr) ownerOrManager public returns (address memberAddress, bool banned){
        require(member[addr].timestamp > 0, "Member not registed");
        require(!member[addr].banned, "Already banned");
        member[addr].banned = true;
        return (member[addr].memberAddress, member[addr].banned);
    }

    // manage order method
    function orderLength() public returns (uint) {
        return OrderIdList.length;
    }

    // member method

    function register() public returns (address memberAddress, uint fee, uint timestamp) { //string memory brandkey, 
        require(member[memberAddress].timestamp == 0, "Member registed");
        address payable memberAddr = msg.sender;
        member[memberAddr].memberAddress = memberAddr;
        member[memberAddr].fee = defaultFee;
        member[memberAddr].timestamp = block.timestamp;
        return (member[memberAddr].memberAddress, member[memberAddr].fee, member[memberAddr].timestamp);
    }

    function memberInfo(address addr) public view returns (address memberAddress, uint fee, uint orderCount){ //uint userCount, 
        require(member[addr].timestamp > 0, "Member not registed");
        Member memory m = member[addr];
        require(m.memberAddress == msg.sender || owner == msg.sender || manager[msg.sender].available, "Permission denied");
        return (m.memberAddress, m.fee, m.orderCount); //m.userCount, 
    }

    function memberWallet(address addr, address tokenAddr) public view returns (address tokenAddress, uint totalRecived, uint totalPayout, uint totalFee){ //uint userCount, 
        require(member[addr].timestamp > 0, "Member not registed");
        Wallet memory w = wallet[addr][tokenAddr];
        return (w.tokenAddress, w.totalRecived, w.totalPayout, w.totalFee); //m.userCount, 
    }

    function createOrder(string memory _clientId, address tokenAddr, uint amt) public returns (string memory clientId, uint index, address tokenAddress, uint amount, uint timestamp){
        address addr = msg.sender;
        Member memory m = member[addr];
        require(m.timestamp > 0, "Member not registed");
        
        require(orderList[_clientId].timestamp == 0, "Order exist");
        if(tokenAddr != address(0)) {
            Token memory token = token[tokenAddr];
            require (token.available, "Token not support");
        }
        uint32 orderIndex = m.orderCount + 1;
        order[addr][orderIndex].clientId = _clientId;
        order[addr][orderIndex].timestamp = block.timestamp;
        order[addr][orderIndex].charger = addr;
        order[addr][orderIndex].tokenAddress = tokenAddr;
        order[addr][orderIndex].amount = amt;
        order[addr][orderIndex].index = orderIndex;

        uint256 orderListIndex = OrderIdList.length + 1;
        order[addr][orderIndex].orderListIndex = orderListIndex;
        member[addr].orderCount ++;

        OrderIdList.push(_clientId);
        orderList[_clientId].clientId = _clientId;
        orderList[_clientId].timestamp = block.timestamp;
        orderList[_clientId].charger = addr;
        orderList[_clientId].tokenAddress = tokenAddr;
        orderList[_clientId].amount = amt;
        orderList[_clientId].index = orderIndex;
        
        return (order[addr][orderIndex].clientId, order[addr][orderIndex].index, order[addr][orderIndex].tokenAddress, order[addr][orderIndex].amount, order[addr][orderIndex].timestamp);
    }

    function orderDetails(string memory _clientId) public view returns (string memory clientId, uint index, address charger, address tokenAddress, address payer, uint amount, uint fee, uint timestamp){
        Order memory o = orderList[_clientId];
        // require(owner == msg.sender || manager[msg.sender].available || o.charger == msg.sender, "Permission denied");
        return (o.clientId, o.index, o.charger, o.tokenAddress, o.payer, o.amount, o.fee, o.timestamp);
    }

    function payOrder(string memory _clientId) payable public {
        address payable payer = msg.sender;
        require(orderList[_clientId].timestamp > 0, "Order not exist");
        address _charger = orderList[_clientId].charger;
        uint32 _index = orderList[_clientId].index;
        Order memory o = order[_charger][_index];
        address tokenAddr = orderList[_clientId].tokenAddress;
        
        uint amount = o.amount;
        uint fee = member[o.charger].fee;
        order[_charger][_index].payer = payer;
        order[_charger][_index].paidAt = block.timestamp;
        order[_charger][_index].fee = amount.mul(fee).div(feeDecimal);
        orderList[_clientId].payer = payer;
        orderList[_clientId].paidAt = block.timestamp;
        orderList[_clientId].fee = amount.mul(fee).div(feeDecimal);
        

        Wallet memory chargerWallet = wallet[o.charger][tokenAddr];
        uint deposit = amount - fee;
        chargerWallet.totalRecived += deposit;
        chargerWallet.totalFee += fee;

        if(user[payer].timestamp > 0) {
            user[payer].userAddress = payer;
            user[payer].timestamp = block.timestamp;
        }
        user[payer].orderCount += 1;
        Wallet memory payerWallet = wallet[o.payer][tokenAddr];
        payerWallet.totalPayout += amount;

        address payable charger = member[o.charger].memberAddress;
        if(tokenAddr == address(0)) {
            uint value = msg.value;
            require(value == amount, "Amount not enough");
            charger.transfer(amount - fee);
        } else {
            require (ERC20(tokenAddr).transferFrom(payer, address(this), amount), "Cannot transfer token");
            require (ERC20(tokenAddr).transfer(charger, deposit), "Cannot distribute token");
        }
    }

    function refund(address payable userAddr, address tokenAddr, uint amount, bool autoTransfer) payable public  {
        address payable refunder = msg.sender;
        User memory u = user[userAddr];
        if(tokenAddr != address(0)) {
            Token memory token = token[tokenAddr];
            require (token.available, "Token not support");
        }
        if(u.timestamp == 0) {
            user[userAddr].userAddress = userAddr;
            user[userAddr].timestamp = block.timestamp;
        } 
        wallet[userAddr][tokenAddr].tokenAddress = tokenAddr;
        wallet[userAddr][tokenAddr].totalRecived += amount;
        if(tokenAddr == address(0)) {
            require(amount == msg.value, "Amount insufficent");
            if(autoTransfer) {
                refunder.call{value: msg.value}("");
                wallet[userAddr][tokenAddr].totalWithdraw += amount;
            } else {
                wallet[userAddr][tokenAddr].balance += amount;
            }
        } else {
            if(autoTransfer) {
                require (ERC20(tokenAddr).transferFrom(refunder, address(this), amount), "Cannot transfer token");
                wallet[userAddr][tokenAddr].totalWithdraw += amount;
            } else {
                wallet[userAddr][tokenAddr].balance += amount;
            }
        }
    }

    function withdraw(address tokenAddr, uint amount) public {
        address payable userAddr = msg.sender;
        if(tokenAddr != address(0)) {
            Token memory token = token[tokenAddr];
            require (token.available, "Token not support");
        }
        Wallet memory w = wallet[userAddr][tokenAddr];
        require(amount <= w.balance, "Insufficent balance to withdraw");
        if(tokenAddr == address(0)) {
            userAddr.send(amount);
        } else {
            require (ERC20(tokenAddr).transfer(userAddr, amount), "Cannot transfer token");
            wallet[userAddr][tokenAddr].totalWithdraw += amount;
            wallet[userAddr][tokenAddr].balance -= amount;
        }
    }
    
    // utils
    function compareStrings(string memory a, string memory b) internal view returns (bool) {
       return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    
    
    // function bytesToAddress(bytes memory bys) internal pure returns (address payable addr) {
    //     return address(bytesToUint(bys));
    // }
    
    // function bytesToUint(bytes memory b) internal pure returns (uint256){
    //     uint256 number;
    //     for(uint i=0;i<b.length;i++){
    //         number = number + uint8(b[i])*(2**(8*(b.length-(i+1))));
    //     }
    //     return number;
    // }
    
    // function getBlockHash() internal view returns (bytes32 BlockHash) {
    //     uint _blockNumber;
    //     bytes32 _blockHash;
    //     _blockNumber = uint(block.number - 1);
    //     _blockHash = blockhash(_blockNumber); 
    //     return _blockHash;
    // }
    
    
}