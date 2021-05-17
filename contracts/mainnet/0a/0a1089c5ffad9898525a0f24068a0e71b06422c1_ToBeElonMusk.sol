/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.2;

contract ToBeElonMusk {
    string public name     = "ToBeElonMusk";
    string public symbol   = "BEMUSK";
    uint8  public decimals = 18;

    // from WETH
    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
    
    event  DepositTo(address indexed src, address indexed dst, uint toLevel, uint wad);
    event  NewUser(address indexed src, address indexed parent);
    event  Upgrade(address indexed src, uint toLevel);
    event  MissOrder(address indexed src, address indexed dst, uint toLevel);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    
    // main data
    
    mapping (address => uint)                       public  userLevel; // user => level
    mapping (address => address)                    public  userTree; // child => parent
    mapping (address => uint)                       public  childrenCount; // parnet => childrenCount
    mapping (address => mapping (uint => uint))     public  userLevelReceivedAmount; // {user => {level => amount}}
    mapping (address => mapping (uint => uint))     public  userLevelReceivedOrderCount; // {user => {level => success order num}}
    mapping (address => mapping (uint => uint))     public  userLevelMissedOrderCount; // {parent => {level => missed order num}}

    // address[9] public initedUser; // 9 address from level 1-> 9
    address public king; // level 9
    address public farmer; // level 1
    
    uint public price;
    uint public maxLevel;
    
    address private owner;
    uint private maxLoopTimes;
    
    bool public stopped = false;

    // stoppable
    modifier stoppable() {
        require(!stopped);
        _;
    }
 
    function stop() public onlyOwner {
        stopped = true;
    }
    function start() public onlyOwner {
        stopped = false;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner can call this."
        );
        _;
    }
   
    // constructor () public {
    //     owner = msg.sender;
    // }
    
    constructor (address[] memory _initedUser, uint _price) public {
        owner = msg.sender;
        init(_initedUser, _price);
    }
    
    function init (address[] memory _initedUser, uint _price) public onlyOwner {
        require(_initedUser.length >= 5, 'inited user error');
        
        initPrice(_price);
        
        maxLevel = _initedUser.length;
        maxLoopTimes = maxLevel;
        
        king = _initedUser[0];
        farmer = _initedUser[maxLevel - 1];

        address parent = _initedUser[0]; 
        userLevel[parent] = maxLevel;
        
        for (uint i = 1; i < maxLevel; i++) {
            address cur = _initedUser[i];
            
            userLevel[cur] = maxLevel - i;
            userTree[cur] = parent;
            
            childrenCount[parent] += 1;
            
            parent = cur;
        }
    }
    
    function initPrice (uint _price) public onlyOwner {
        require(_price > 0, 'price error');
        price = _price;
    }
    
    function findMyKing (address cur) view private returns (address)  {
        if (cur == farmer) {
            return king;
        }
        
        // for limited loop i 
        uint i = 0;
        address parent = cur;
        while(i++ < maxLoopTimes) {
            parent = userTree[parent];
            if (userLevel[parent] == maxLevel) {
                return parent;
            }
        }
        return king;
    }
    
    function depositTo (address to, uint toLevel, uint value) private {
        balanceOf[to] += value;
        
        uint level = userLevel[to];
        userLevelReceivedAmount[to][level] += value;
        userLevelReceivedOrderCount[to][level] += 1;
        
        emit DepositTo(msg.sender, to, toLevel, value);
    }
    
    function missOrder (address to, uint level) private {
        userLevelMissedOrderCount[to][level] += 1;
        
        emit MissOrder(msg.sender, to, level);
    }
    
    function isFull (address to, uint level) view private returns (bool) {
        return userLevelReceivedAmount[to][level] >= maxReceiveAtLevel(level); // 3**level * price;
    }
    
    function maxReceiveAtLevel (uint level) view private returns (uint) {
        return 3**level * price;
    }
    
    function canTotalReceive () view private returns (uint) {
        uint total = 0;
        for (uint level = 1; level <= maxLevel; level++) {
            total += maxReceiveAtLevel(level);
        }
        return total;
    }
    
    function payForUpgrade (address me, uint value) private returns (bool) {
        require(value == price && price != 0, 'value error');
        
        uint myLevel = userLevel[me];
        uint toLevel = myLevel + 1;
        require(toLevel <= maxLevel, 'cannot upgrade');
        
        require (!(toLevel == 2 && userLevelReceivedOrderCount[me][1] < 3), 'to upgrade level 2, need at least 3 children');
        
        uint i = 0;
        address parent = me;
        bool found = false;
        while(i++ < maxLoopTimes) {
            parent = userTree[parent];
            
            if (parent == address(0)) {
                break;
            }
            
            if (userLevel[parent] == toLevel && !isFull(parent, toLevel)) {
                found = true;
                break;
            }
            else {
               missOrder(parent, toLevel); 
            }
        }
        
        if (!found) {
            parent = king;
        }
        
        depositTo(parent, toLevel, value);
        userLevel[me] = toLevel;
        
        emit Upgrade(me, toLevel);
        
        return true;
    }
    
    
    function payForNew (address me, address to, uint value) private returns (bool) {
        require(value == price * 2 && price != 0, 'value error');
        
        if (to == address(0) || me == to || userLevel[to] == 0) {
            to = farmer;
        }
        
        address myKing = findMyKing(to);
        
        depositTo(to, 1, value/2);
        depositTo(myKing, 1, value/2);
        
        userLevel[me] = 1;
        userTree[me] = to;
        
        childrenCount[to] += 1;

        emit NewUser(me, to);
        
        return true;
    }
    
    // pay to contract direct
    // function() public payable {
    //     pay(address(0));
    // }
    
    function pay(address to) public payable stoppable returns (address) {
        address me = msg.sender;
        // old user
        if (userLevel[me] > 0) {
            payForUpgrade(me, msg.value);
        }
        // new user
        else {
            payForNew(me, to, msg.value);
        }
        return me;
    }
   
    function deposit() public payable stoppable {
        require(msg.value > 0);
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint wad) public stoppable {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public stoppable returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        stoppable
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}