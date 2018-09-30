pragma solidity ^0.4.7;
contract MobaBase {
    address public owner = 0x0;
    bool public isLock = false;
    constructor ()  public  {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner,"only owner can call this function");
        _;
    }
    
    modifier notLock {
        require(isLock == false,"contract current is lock status");
        _;
    }
    
    modifier msgSendFilter() {
        address addr = msg.sender;
        uint size;
        assembly { size := extcodesize(addr) }
        require(size <= 0,"address must is not contract");
        require(msg.sender == tx.origin, "msg.sender must equipt tx.origin");
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function updateLock(bool b) onlyOwner public {
        
        require(isLock != b," updateLock new status == old status");
        isLock = b;
    }
}

contract BRMobaInviteData is MobaBase {
   
    address owner = 0x0;
    uint256 price = 10 finney;
    mapping(bytes32 => address) public m_nameToAddr;
    mapping(address => bytes32) public m_addrToName;
    
    function createInviteName(bytes32 name) 
    notLock 
    msgSendFilter
    public payable {
        require(msg.value == price);
        require(checkUp(msg.sender,name),"current name has been used or current address has been one name"); 
        m_nameToAddr[name] = msg.sender;
        m_addrToName[msg.sender] = name;
    }
    
    function checkUp(address addr,bytes32 name) public view returns (bool) {
        if(m_nameToAddr[name] == address(0) && m_addrToName[addr] == 0) {
            return true;
        }
        return false;
    }
    
    function GetAddressByName(bytes32 name) public view returns (address){
        return m_nameToAddr[name];
    }
}

contract BRPerSellData is MobaBase {
    
    struct PerSell {
      bool isOver;
      uint16 id;
      uint256 price;
    }
    
    constructor ()  public  {
        owner = msg.sender;
        addPerSell(0,0  finney,true);
        addPerSell(1,10 finney,false);
        addPerSell(2,10 finney,false);
        addPerSell(3,10 finney,false);
    }
    
    PerSell[]  mPerSellList;
    mapping (uint16 => uint16) public mIdToIndex;
 

    
    modifier noPerSellId(uint16 id) {
        uint16 index = mIdToIndex[id];
        if(index < mPerSellList.length ) {
            PerSell storage curPerSell = mPerSellList[index];
            require(curPerSell.id == 0,"current PerSell.Id isnot exist");
        }
        _;  
    }
    modifier hasPerSellId(uint16 id) {
        PerSell storage curPerSell = mPerSellList[mIdToIndex[id]];
        require(curPerSell.id > 0,"current PerSell.Id isnot exist");
        _;
    }
    
    function addPerSell(uint16 id,uint256 price,bool isOver) 
    onlyOwner 
    msgSendFilter 
    noPerSellId(id)
    public {
        mPerSellList.push( PerSell(isOver,id,price));
        uint16 index   = uint16(mPerSellList.length-1);
        mIdToIndex[id] = index;
        require(mPerSellList[index].id == id);
    }
    
    function updatePerSell(uint16 id,uint256 price,bool isOver) 
    onlyOwner 
    msgSendFilter 
    hasPerSellId(id)
    public {
         PerSell storage curPerSell = mPerSellList[mIdToIndex[id]];
         curPerSell.price  = price;
         curPerSell.isOver = isOver;
    }
    
    function PerSellOver(uint16[] array) 
    onlyOwner 
    msgSendFilter 
    public {
        for(uint16 i = 0 ; i < array.length;i++) {
            uint16 id = array[i];
            PerSell storage curPerSell = mPerSellList[mIdToIndex[id]];
            if(curPerSell.isOver == false) {
                curPerSell.isOver = true;
            }
        }
    } 
    
    function OverAllPerSell() 
    onlyOwner 
    msgSendFilter 
    public {
        for(uint16 i = 0 ; i < mPerSellList.length;i++) {
            PerSell storage curPerSell = mPerSellList[i];
            if(curPerSell.isOver == false) {
                curPerSell.isOver = true;
            }
        }
    }

    
    function GetPerSellInfo(uint16 id) public view returns (uint16,uint256 price,bool isOver) {
        
        PerSell storage curPerSell = mPerSellList[mIdToIndex[id]];
        return (curPerSell.id,curPerSell.price,curPerSell.isOver);
    }
    
}


//////////////////////////////////////购买//////////////////////////////////////
contract IBRInviteData {
    function GetAddressByName(bytes32 name) public view returns (address);
}
contract IBRPerSellData {
   function GetPerSellInfo(uint16 id) public view returns (uint16,uint256 price,bool isOver);
}

contract BRPerSellControl is MobaBase {
    
    IBRInviteData mInviteAddr;
    IBRPerSellData mPerSellData;
    mapping (address => uint16[]) public mBuyList;

    event updateIntefaceEvent();
    event transferToOwnerEvent(uint256 price);
    event buyPerSellEvent(uint16 perSellId,bytes32 name,uint256 price);
    constructor(address inviteData, address perSellData) public {
        mInviteAddr  = IBRInviteData(inviteData);
        mPerSellData = IBRPerSellData(perSellData);
    }
    
    function updateInteface(address inviteData, address perSellData) 
    onlyOwner 
    msgSendFilter 
    public {
        mInviteAddr  = IBRInviteData(inviteData);
        mPerSellData = IBRPerSellData(perSellData);
        emit updateIntefaceEvent();
    }
    
    function transferToOwner()    
    onlyOwner 
    msgSendFilter 
    public {
        uint256 totalBalace = address(this).balance;
        owner.transfer(totalBalace);
        emit transferToOwnerEvent(totalBalace);
    }
    
   function GetPerSellInfo(uint16 id) public view returns (uint16 pesellId,uint256 price,bool isOver) {
        return mPerSellData.GetPerSellInfo(id);
    }
    
    function buyPerSell(uint16 perSellId,bytes32 name) 
    notLock
    msgSendFilter 
    payable public {
        uint16 id; uint256 price; bool isOver;
        (id,price,isOver) = mPerSellData.GetPerSellInfo(perSellId);
        require(id == perSellId && id > 0,"perSell.Id is error"  );
        require(msg.value == price,"msg.value is error");
        require(isOver == false,"persell is over status");
        
        address inviteAddr = mInviteAddr.GetAddressByName(name);
        if(inviteAddr != address(0)) {
           uint giveToEth   = msg.value * 10 / 100;
           inviteAddr.transfer(giveToEth);
        }
        mBuyList[msg.sender].push(id);
        emit buyPerSellEvent(perSellId,name,price);
    }
    

}