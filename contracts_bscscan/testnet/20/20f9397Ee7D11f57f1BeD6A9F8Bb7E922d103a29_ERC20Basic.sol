// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "Ownable.sol";

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function addRTL(address _empaddr, uint256 amount) external returns (bool);
    function approveRTL(address _logid, uint8 _approveid) external returns (bool);

    //event Transfer(address indexed from, address indexed to, uint256 value);
    event SetEmp(address indexed empaddress, uint256 indexed id, address man1, address man2);
    event Transfer(address indexed _logaddr, address indexed _empid , uint256 balance);
    event AddRTL(address indexed _empaddr, uint256 balance);
    event ApproveRTL(address indexed _logaddr , uint8 statu);
}


contract ERC20Basic is IERC20,Ownable {

    string public constant name = "Test2";
    string public constant symbol = "T2";
    uint8 public constant decimals = 0;
    uint256 public waiting_tokens = 0;
    struct employee { 
       uint256 ID;
       uint256 balance;
       address manager1;
       address manager2;
    }
    
    struct RTL_log {
        address emp;
        uint256 balance;
        uint8 man1_ok;
        uint8 man2_ok;
    }
    
    mapping(address => RTL_log) logs;
    mapping(address => employee) emps;
    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor(uint256 total) public {
    totalSupply_ = total;
    emps[msg.sender].balance = totalSupply_;
    }

    function setEmployee (address _emp, uint256 _id,address _man1, address _man2) onlyOwner public {
        require((_id>1000 && _id<9999),"Invalid ID");
        emps[_emp].ID = _id;
        emps[_emp].manager1 = _man1;
        emps[_emp].manager2 = _man2;
        emit SetEmp(_emp,_id,_man1,_man2);
        
    }
    
    function setID (address _emp, uint256 _id) onlyOwner public {
        require((_id>1000 && _id<9999),"Invalid ID");
        emps[_emp].ID = _id;
    }
    
    function setMan1 (address _emp, address _man1) onlyOwner public {
        emps[_emp].manager1 = _man1;
    }
    
    function setMan2 (address _emp, address _man2) onlyOwner public {
        emps[_emp].manager2 = _man2;
    }
    
    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return emps[tokenOwner].balance;
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= emps[msg.sender].balance , "Not Enough RTL");
        require((receiver == owner() || msg.sender == owner()),"Only transfer to Kafein is avaliable");
        address _transfer_id = getUniqueId();
        logs[_transfer_id].balance = numTokens;
        emps[msg.sender].balance = emps[msg.sender].balance.sub(numTokens);
        logs[_transfer_id].emp = msg.sender;
        waiting_tokens = waiting_tokens.add(numTokens);
        
        //emps[receiver].balance =emps[receiver].balance.add(numTokens);
        emit Transfer(_transfer_id, msg.sender, numTokens);
        return true;
    }
    
    function addRTL(address _empaddr, uint256 numTokens) onlyOwner public override returns (bool) {
        require(numTokens > 0, "Must be bigger than zero");
        emps[_empaddr].balance = emps[_empaddr].balance.add(numTokens);
        totalSupply_ = totalSupply_.add(numTokens);
        //emps[receiver].balance =emps[receiver].balance.add(numTokens);
        emit AddRTL(_empaddr, numTokens);
        return true;
    }
    
    function approveRTL(address _logid, uint8 _approveid) public override returns (bool) {
        require(msg.sender == emps[logs[_logid].emp].manager1 || msg.sender == emps[logs[_logid].emp].manager2, "Approve user must be employee's manager.");
        require(_approveid < 3 , "1 - OK  or  2 - Reject");
        
        if (msg.sender == emps[logs[_logid].emp].manager1){
            logs[_logid].man1_ok = _approveid;
        }
        else if (msg.sender == emps[logs[_logid].emp].manager2){
            logs[_logid].man2_ok = _approveid;
        }
        
        if (logs[_logid].man1_ok == 1 && logs[_logid].man2_ok == 1){
            waiting_tokens = waiting_tokens.sub(logs[_logid].balance);
            totalSupply_ = totalSupply_.sub(logs[_logid].balance);
            emit ApproveRTL (_logid , 1);
        }
        
        else if (logs[_logid].man1_ok == 2 || logs[_logid].man2_ok == 2){
            waiting_tokens = waiting_tokens.sub(logs[_logid].balance);
            emps[logs[_logid].emp].balance = emps[logs[_logid].emp].balance.add(logs[_logid].balance);
            emit ApproveRTL (_logid , 2);
        }
        
        else {
            emit ApproveRTL (_logid , 0);
        }
        return true;
    }
    
    
    
    
    function logView(address addr) public view returns (RTL_log memory) 
    {
        return logs[addr];
    }
    
    function empView(address addr) public view returns (employee memory) 
    {
        return emps[addr];
    }
    
    
    
    function getUniqueId() public view returns (address) 
    {
        address addr = address(uint160(uint256(keccak256(abi.encodePacked(msg.sender,block.timestamp)))));
        return address(addr);
    }
    

   
}

library SafeMath {
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