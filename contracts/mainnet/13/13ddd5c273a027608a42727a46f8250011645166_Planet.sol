pragma solidity ^0.4.18;
library U256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
} 

contract Role {
    address public addrAdmin = msg.sender; 
    address public addrExecutor = msg.sender; 
  
    modifier _rA() {
        require(msg.sender == addrAdmin);
        _;
    } 

    modifier _rC() {
        require(msg.sender == addrAdmin || msg.sender == addrExecutor);
        _;
    }  

    function rSetA(address _newAdmin) public _rA {
        require(_newAdmin != address(0));  
        addrAdmin = _newAdmin; 
    }

    function rSetE(address _newExecutor) public _rA {
        require(_newExecutor != address(0));  
        addrExecutor = _newExecutor; 
    }   

    function myRole() constant public returns(uint8 _myRole) {
        _myRole = 0;
        if (msg.sender == addrAdmin) {
            _myRole = 1;
        } else if (msg.sender == addrExecutor) {
            _myRole = 2;
        }
    } 
} 

contract Fund is Role { 
    uint funds; 

    function fundChecking() constant public returns (uint) {
        return funds;
    } 
  
    function fundWithdraw(address addr, uint value) payable public _rA {
        require(value <= funds);
        addr.transfer(value); 
        funds -= value;
    }    

    function fundMark(uint value) internal { 
        funds += value;
    }    
}

contract Cryptoy is Fund {
    bool public isAlive = true;
    bool public isRunning = false;

    modifier gRunning(bool query) {
        require(query == isRunning);
        _;
    } 

    modifier gAlive(bool query) {
        require(query == isAlive);
        _;
    }  

    function gSetRunning(bool state) public _rC gRunning(!state) {
        isRunning = state; 
    }

    function gSetAlive(bool state) public _rC gAlive(!state) { 
        isAlive = state; 
    }

    function getSystemAvaliableState() constant public returns(uint8) {
        if (!isAlive) {
            return 1;
        }
        if (!isRunning) {
            return 2;
        } 
        return 0; 
    } 
}

interface INewPrice { 
    function getNewPrice(uint initial, uint origin) view public returns(uint);
    function isNewPrice() view public returns(bool);
}
contract Planet is Cryptoy {
    using U256 for uint256; 

    string public version = "1.0.0"; 
    uint16 public admin_proportion = 200; // 千分位

    INewPrice public priceCounter;

    event OnBuy(uint refund);

    struct Item { 
        address owner;
        uint8   round;
        uint    priceSell;
        uint    priceOrg;
        bytes   slogan;
    }
    Item[] public items; 
    
    function itemCount() view public returns(uint) {
        return items.length;
    }

    function aSetProportion(uint16 prop) _rC public returns(uint) {
        admin_proportion = prop;
        return admin_proportion;
    } 

    function setNewPriceFuncAddress(address addrFunc) public _rC {
        INewPrice counter = INewPrice(addrFunc); 
        require(counter.isNewPrice()); 
        priceCounter = counter;
    }

    function newPrice(uint priceOrg, uint priceSell) view public returns(uint) {
        return priceCounter.getNewPrice(priceOrg, priceSell);
    }

    function realbuy(Item storage item) internal returns(uint finalRefund) {
        uint total = item.priceSell; 
        uint fee = total.sub(item.priceOrg).mul(admin_proportion).div(1000);
        
        fundMark(fee);
        finalRefund = total.sub(fee); 

        item.owner.transfer(finalRefund); 
        item.owner = msg.sender;
        item.priceOrg = item.priceSell;
        item.priceSell = newPrice(item.priceOrg, item.priceSell);
        item.round = item.round + 1;
    }

    function createItem(uint amount, uint priceWei) _rC gAlive(true) public {    
        for (uint i = 0; i < amount; i ++) {
            items.push(Item({
                owner: msg.sender, 
                round: 0,
                priceOrg: 0, 
                priceSell: priceWei,
                slogan: ""
            }));
        } 
    }

    function buy(uint itemID) payable gAlive(true) gRunning(true) public {
        address addrBuyer = msg.sender;  
        require(itemID < items.length); 
        Item storage item = items[itemID];
        require(item.owner != addrBuyer);
        require(item.priceSell == msg.value);
        OnBuy(realbuy(item));
    }

    function setSlogan(uint itemID, bytes slogan) gAlive(true) gRunning(true) public {
        address addrBuyer = msg.sender; 
        require(itemID < items.length); 
        Item storage item = items[itemID];
        require(addrAdmin == addrBuyer || addrExecutor == addrBuyer || item.owner == addrBuyer);
        item.slogan = slogan;
    }
}