/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

//SPDX-License-Identifier: UNLICENSED

/**
 *Paralism.com EPARA Token V1 on Ethereum
*/
pragma solidity ^0.7.0;

/**
 * Math operations with safety checks
 */
library SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'add() overflow!');
    }

    function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'sub() underflow!');
    }
}

contract EPARA {
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => TokensWithLock) public lock;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    event Approval(address indexed approver, address indexed _spender, uint256 _value);
    event TransferWithLock(address indexed from, address indexed to, uint256 value, uint256 lockedTime ,uint256 initlockDays);
    event ReturnLockedTokens(address indexed from, address indexed to, uint256 value); 
    event UpdateLockTime(address indexed sender, address indexed addr, uint256 lockdays);
    event AllowUpdateLock(address indexed sender, bool allow);
    
    struct TokensWithLock {
        uint256 lockValue;
        uint256 lockTime;
        address sender;
        bool allowLockTimeUpdate;  
    }
 
    /* Initializes contract with initial supply tokens */
    constructor(){
        totalSupply = 21000*10000*(10**9); //210M                       
        name = "Paralism-EPARA";                                  
        symbol = "EPARA";                              
        decimals = 9;                            
		
        balanceOf[0xC7f12C99830982A1CaDeF01E7deA1B7C17e0ab5B] = totalSupply/10;         //21M
        balanceOf[0x804ce455A39348E7CFb4Bdd5365636F55907420b] = totalSupply/10;         //21M
        balanceOf[0x33Ce92bd42c8034CBC16fF02B2d805388026604e] = totalSupply/10;         //21M
        balanceOf[0x784B96AdaFb1274bA26F583e16E2613715E14348] = totalSupply/10;         //21M
        balanceOf[0xD848e7F2E0c46c383DE0dc8469933ffda611aBA3] = totalSupply/10;         //21M
        balanceOf[0x9BC07857cdFad1C6Bc36B5848A17858d75D5A143] = totalSupply/10;         //21M
        balanceOf[0x5A6d86c56BBDca6B3D87E94B51b93C7187A9f2dA] = totalSupply/10;         //21M
        balanceOf[0x9229bA5B93B867A7326Ff80514C8869F2e7148ae] = totalSupply/10;         //21M
        balanceOf[0x4EA30C087Ec411C17D335721F49fC8ff18A6C44D] = totalSupply/10;         //21M
        balanceOf[0x266465cf2935646Bb2f5ebE6FE96F6C28A62C1f7] = totalSupply/10;         //21M
    }

    /* Send Tokens */
    function transfer(address _to, uint256 _value) public returns (bool success){
        if (_to == address(0)) revert("transfert to address 0"); 
        if (balanceOf[msg.sender] < _value.safeAdd(getLockValue(msg.sender))) revert("insufficient balance or lock detected"); 
        
        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);
        balanceOf[_to] = balanceOf[_to].safeAdd(_value);  
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /* Athorize another address to spend some tokens on your behalf */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
       
    /* An athorized address attempts to get the approved amount of tokens */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_to == address(0)) revert("transfert to address 0");                              
        if (_value > allowance[_from][msg.sender]) revert("transfer more than allowance");    
        if (balanceOf[_from] < _value.safeAdd(getLockValue(_from))) revert("insufficient balance or lock detected");
    
        allowance[_from][msg.sender] = allowance[_from][msg.sender].safeSub(_value);
        balanceOf[_from] = balanceOf[_from].safeSub(_value);                           
        balanceOf[_to] = balanceOf[_to].safeAdd(_value);                             

        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        if (balanceOf[msg.sender] < _value.safeAdd(getLockValue(msg.sender))) revert("insufficient balance or lock detected");

        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);                      
        totalSupply = totalSupply.safeSub(_value);                                
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) public returns (bool success) {
        if (balanceOf[msg.sender] < _value.safeAdd(getLockValue(msg.sender))) revert("insufficient balance or lock detected"); 

        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);                      
        freezeOf[msg.sender] = freezeOf[msg.sender].safeAdd(_value);                                
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) public returns (bool success) {
        if (freezeOf[msg.sender] < _value) revert("insufficient balance.");           

        freezeOf[msg.sender] = freezeOf[msg.sender].safeSub(_value);                      
		balanceOf[msg.sender] = balanceOf[msg.sender].safeAdd(_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
    
    function transferWithLock(address _to, uint256 _value, uint256 _initLockdays) public returns (bool success) {
        require(address(0) != _to,"transfer to address 0");
 		require(0 < _value,"transfer value should > 0"); 

        if (balanceOf[msg.sender] < _value.safeAdd(getLockValue(msg.sender))) revert("insufficient balance or lock detected");
		
        if (0 < getLockValue(_to)) {
			require (msg.sender == lock[_to].sender,"others lock detected") ;
			require (_initLockdays == 0,"Lock detected, init fail") ;
		}
		
        if (0 == getLockValue(_to)) {
			lock[_to].lockTime = block.timestamp.safeAdd(_initLockdays * 1 days);           //init expriation day.
			lock[_to].sender= msg.sender;                                                   //init sender
		}
		
        lock[_to].lockValue = lock[_to].lockValue.safeAdd(_value);                          //add lock value
		balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_value);                      //subtract from the sender
		balanceOf[_to] = balanceOf[_to].safeAdd(_value);                                    //add to the recipient

        lock[_to].allowLockTimeUpdate = false;                                              //disable senderUpdate until receiver allowed
        emit TransferWithLock(msg.sender, _to, _value, lock[_to].lockTime , _initLockdays); 
        return true;
    }
    
    function transferMoreWithLock(address _to, uint256 _value) public returns (bool success) {
	    if(0 == getLockValue(_to)) revert("NO lock detected");
        return transferWithLock(_to,_value,0);
    }

    /*get locked balance*/
    function getLockValue(address addr) public returns (uint256 amount){
        if (lock[addr].lockTime <= block.timestamp) {
		    lock[addr].lockValue = 0; //expired
	    } 
	    return lock[addr].lockValue;
    }
    
    /*get locked timestamp*/
    function getLockTime(address addr) public view returns (uint256 time){
		return lock[addr].lockTime;
    }
    
    /*get lock remaining seconds*/
    function getLockRemainSeconds(address addr) public view returns (uint256 sec){
        lock[addr].lockTime > block.timestamp ? sec = lock[addr].lockTime - block.timestamp : sec = 0;
    }
 
    /*only with receiver permission, locked amount sender can update lock time */ 
    function updateLockTime(address addr, uint256 _days)public returns (bool success) {
        require(getLockValue(addr) > 0,"NO lock detected");
        require(msg.sender == lock[addr].sender, "others lock detected");  
        require(true == lock[addr].allowLockTimeUpdate,"allowUpdateLockTime is false");

        lock[addr].lockTime = block.timestamp.safeAdd(_days * 1 days);    
        lock[addr].allowLockTimeUpdate = false;
        emit UpdateLockTime(msg.sender, addr, _days);
        return true;
    }

    /*receiver switch on or off to enable lock amount sender update lock time or not*/   
    function allowUpdateLockTime(bool allow) public returns (bool success){
        lock[msg.sender].allowLockTimeUpdate = allow;
        emit AllowUpdateLock(msg.sender, allow);
        return true;
    }
  
    /*receiver can return locked amount to the sender*/
    function returnLockedTokens(uint256 _value) public returns (bool success){
        address _returnTo = lock[msg.sender].sender;
        address _returnFrom = msg.sender;
        
        uint256 lockValue = getLockValue(_returnFrom);
        require(0 < lockValue, "NO lock detected");
        require(_value <= lockValue,"insufficient lock value");

        balanceOf[_returnFrom] = balanceOf[_returnFrom].safeSub(_value); 
        balanceOf[_returnTo] = balanceOf[_returnTo].safeAdd(_value);
        
        lock[_returnFrom].lockValue = lock[_returnFrom].lockValue.safeSub(_value);   //reduce locked amount
        
        emit ReturnLockedTokens(_returnFrom, _returnTo, _value);
        return true;
    }
    
    /*Transfer tokens to multiple addresses*/
    function transferForMultiAddresses(address[] memory _addresses, uint256[] memory _amounts) public returns (bool) {
       require(_addresses.length == _amounts.length,"arrays length mismatch");
       for (uint i = 0; i < _addresses.length; i++) {
           require(_addresses[i] != address(0),"transfer to address 0");
           if (balanceOf[msg.sender] < _amounts[i].safeAdd(getLockValue(msg.sender))) revert("insufficient balance or lock detected"); 
        
           balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(_amounts[i]);
           balanceOf[_addresses[i]] = balanceOf[_addresses[i]].safeAdd(_amounts[i]);
           emit Transfer(msg.sender, _addresses[i], _amounts[i]);
        }
        return true;
    }
}