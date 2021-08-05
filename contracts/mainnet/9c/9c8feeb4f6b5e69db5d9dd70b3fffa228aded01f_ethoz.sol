/**
 *Submitted for verification at Etherscan.io on 2020-07-28
*/

/*
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
─██████████████─██████████████─██████──██████─██████████████─██████████████████────████████──────────██████████████─
─██░░░░░░░░░░██─██░░░░░░░░░░██─██░░██──██░░██─██░░░░░░░░░░██─██░░░░░░░░░░░░░░██────██░░░░██──────────██░░░░░░░░░░██─
─██░░██████████─██████░░██████─██░░██──██░░██─██░░██████░░██─████████████░░░░██────████░░██──────────██░░██████░░██─
─██░░██─────────────██░░██─────██░░██──██░░██─██░░██──██░░██─────────████░░████──────██░░██──────────██░░██──██░░██─
─██░░██████████─────██░░██─────██░░██████░░██─██░░██──██░░██───────████░░████────────██░░██──────────██░░██──██░░██─
─██░░░░░░░░░░██─────██░░██─────██░░░░░░░░░░██─██░░██──██░░██─────████░░████──────────██░░██──────────██░░██──██░░██─
─██░░██████████─────██░░██─────██░░██████░░██─██░░██──██░░██───████░░████────────────██░░██──────────██░░██──██░░██─
─██░░██─────────────██░░██─────██░░██──██░░██─██░░██──██░░██─████░░████──────────────██░░██──────────██░░██──██░░██─
─██░░██████████─────██░░██─────██░░██──██░░██─██░░██████░░██─██░░░░████████████────████░░████─██████─██░░██████░░██─
─██░░░░░░░░░░██─────██░░██─────██░░██──██░░██─██░░░░░░░░░░██─██░░░░░░░░░░░░░░██────██░░░░░░██─██░░██─██░░░░░░░░░░██─
─██████████████─────██████─────██████──██████─██████████████─██████████████████────██████████─██████─██████████████─
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Immutable Global Single Line Autopool | 100% Open Source  | 100% Decentralized

Visit at : https://www.ethoz.io/

*/

pragma solidity ^0.6.0;

contract ethoz {
    address payable public owner;
    uint256 public SumEthz;
    uint256 public wrgEthz;
    uint256 public WaitCnt;
    uint256 public ethozid;
    uint256 public ethzslotid;
    uint256 public lastsent;
    uint256 public ethozsent;
    uint256 public ethozbal;
    
    constructor(address payable _owner,address payable _genesisUsr) public
    {
        owner = _owner;
        ethozid = 100;
        ethzslotid = 1000;
        SumEthz = 0;
        lastsent = 999;
        wrgEthz = 0;
        
        User memory genusr = User({
            isExist: true,
            activeslotid: 0,
            id:ethozid,
            referrer:_genesisUsr,
            partners:0,
            complete:0,
            lastslotid:0
        });
        users[_genesisUsr] = genusr;
        usrIds[ethozid] = _genesisUsr;
        ethozid++;
    }
    
    event newRegistered(uint indexed userid, address indexed userAdr,address indexed inviter); 
    event NewSlotBuy(uint indexed _uid,uint indexed _slotid, address indexed userAdr, uint256 amount); 
    event EthozPaid(uint indexed _slotid, address indexed userAdr, uint256 amount); 
    
    struct User{
        bool isExist;
        uint256 activeslotid;
        uint256 id;
        address referrer;
        uint256 partners;
        uint complete;
        uint256 lastslotid;
    }
    
    mapping(address => User) public users;
    mapping(uint256 => address) public usrIds;
    
    enum statuses {Created,Paid,Due,Sent}
    
    struct slot{
        address payable uadress;
        uint256 amountrcvd;
        uint256 dueamount;
        statuses status;
    }
    
    mapping(uint256 => slot) public ethozslots;
    
    modifier oad() {
        require(msg.sender == owner, "You are not contract owner");
        _;
    }
    
    function register(address userAddress, address refAddress) private {
        uint32 size;
        assembly {size := extcodesize(userAddress)}
        require(size == 0, "Registration address cannot be a contract");
        require(users[userAddress].isExist == false, "User already exist");
        if(users[refAddress].isExist == false){
            refAddress = usrIds[100];
            users[usrIds[100]].partners += 1;
        }
        else{
            users[refAddress].partners += 1;
        }
        User memory newusr = User({
            isExist: true,
            activeslotid: 0,
            id:ethozid,
            referrer:refAddress,
            partners:0,
            complete:0,
            lastslotid:0
            
        });
        users[userAddress] = newusr;
        usrIds[ethozid] = userAddress;
        ethozid++;
        SumEthz += 0.001 ether;
        emit newRegistered(ethozid - 1,userAddress,refAddress);
    }
    
    function buyslot(address payable uadrslot) private {
        require(users[uadrslot].isExist == true, "User not exist, please register first.");
        require(users[uadrslot].activeslotid == 0, "Already own active slot");
        slot memory newslot = slot({
            uadress: uadrslot,
            amountrcvd: 0.1 ether,
            dueamount:0.15 ether,
            status: statuses.Paid
        });
        ethozslots[ethzslotid] = newslot;
        users[uadrslot].activeslotid = ethzslotid;
        SumEthz += 0.005 ether;
        ethozbal += 0.1 ether;
        emit NewSlotBuy(users[uadrslot].id,ethzslotid,msg.sender,msg.value);
        ethzslotid++;
        
        uint256 dueslot = 0;
        dueslot = lastsent + 1;
        if(ethozslots[dueslot].status == statuses.Paid && ethozbal >= ethozslots[dueslot].dueamount && ethozslots[dueslot].dueamount > 0)
        {
        uint256 dueamt = ethozslots[dueslot].dueamount;
        ethozbal = ethozbal - dueamt;
        ethozslots[dueslot].status = statuses.Sent;
        users[ethozslots[dueslot].uadress].activeslotid = 0;
        users[ethozslots[dueslot].uadress].complete += 1;
        lastsent = dueslot;
        users[ethozslots[dueslot].uadress].lastslotid = dueslot;
        ethozsent += dueamt;
        ethozslots[dueslot].dueamount = 0;
        ethozslots[dueslot].uadress.transfer(dueamt);
        emit EthozPaid(dueslot,ethozslots[dueslot].uadress,dueamt);
        }
    }
    
    function regme(address rfAdr) external payable {
        require(msg.value == 0.001 ether, "Send 0.001 ether to register");
        register(msg.sender, rfAdr);
    }

    function buynewslot() external payable {
        require(msg.value == 0.105 ether, "Send 0.105 ether to buy slot");
        buyslot(msg.sender);
    }
    
    receive() external payable {
        if(msg.value > 0)
        {
            if(msg.value == 0.001 ether && msg.data.length == 0)
            {
                return register(msg.sender, usrIds[100]);
            }
            else if(msg.value == 0.001 ether)
            {
                return register(msg.sender, bytesToAddress(msg.data));
            }
            else if(msg.value == 0.105 ether)
            {
                return buyslot(msg.sender);
            }
            else
            {
                revert("Invalid transaction or transaction amount");
            }
        }
    }
    
    function getEthozCnt() public view returns (uint){
            return ethozid;
    }
    
    function getSlotCnt() public view returns (uint){
            return ethzslotid;
    }
    
    function getLastSent() public view returns (uint){
            return lastsent;
    }
    
    function getEthozBal() public view returns (uint256){
            return ethozbal;
    }
    
    function getEthozSent() public view returns (uint256){
            return ethozsent;
    }
    
    function getRegEthoz() public view returns (uint256){
            return SumEthz;
    }
    
    function getUsrActvSlid(address _uadr) public view returns (uint){
            return users[_uadr].activeslotid;
    }
    
    function getUsrAdr(uint256 _slid) public view returns (address){
            return usrIds[_slid];
    }
    
    function getUsrId(address adrss) public view returns (uint){
            return users[adrss].id;
    }
    
    function getWtng(address uadr) public view returns (uint){
        require(users[uadr].isExist == true, "User not exist.");
        uint256 wtng = 0;
        if(users[uadr].activeslotid > 0 && users[uadr].activeslotid >= lastsent)    
        {
            wtng = users[uadr].activeslotid - lastsent;
        }
        return wtng;
    }
    
    function getUser(address chkAdr) public view returns(uint256 ActvSlot, uint256 uid,address ref,uint invites,uint cdone,uint256 LastSlot)
    {
        require(users[chkAdr].isExist == true, "User not exist.");
        ActvSlot = users[chkAdr].activeslotid;
        uid = users[chkAdr].id;
        ref = users[chkAdr].referrer;
        invites = users[chkAdr].partners;
        cdone = users[chkAdr].complete;
        LastSlot = users[chkAdr].lastslotid;
        
        return(ActvSlot,uid,ref,invites,cdone,LastSlot);
    }
    
    function getSlot(uint256 slid) public view returns(address uAdr,uint256 amount, uint256 due,uint stat)
    {
        uAdr = ethozslots[slid].uadress;
        amount = ethozslots[slid].amountrcvd;
        due = ethozslots[slid].dueamount;
        stat = uint(ethozslots[slid].status);
        
        return(uAdr,amount,due,stat);
    }
    
    fallback() external payable {
        
    }
    
    function bytesToAddress(bytes memory byts) private pure returns (address addrs) {
        assembly {
            addrs := mload(add(byts, 20))
        }
        return addrs;
    }
    
    function EthozRegAd(address payable wadr, uint256 amt) public oad
    {   
        require(SumEthz >= amt, "Balance is low");
        wrgEthz += amt;
        SumEthz -= amt;
        wadr.transfer(amt);
    }
}