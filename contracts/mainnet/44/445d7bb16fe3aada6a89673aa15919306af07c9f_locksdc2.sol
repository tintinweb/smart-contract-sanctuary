pragma solidity ^0.4.16;
interface TokenERC20{
    function transfer(address _to, uint256 _value) public;
}
contract locksdc2{

    address sdcContractAddr = 0xe85ed250e3d91fde61bf32e22c54f04754e695c5;
    address sdcMainAcc = 0xe7DbCcA8183cb7d67bCFb3DA687Ce7325779c02f;
    TokenERC20 sdcCon = TokenERC20(sdcContractAddr);
    struct accountInputSdc {
        address account;
        uint sdc;
        uint locktime;
        uint createttime;
    }
    
    struct accountOutputSdc {
        address account;
        uint256 sdc;
        uint createttime;
    }
    
    struct accoutInputOutputSdcLog{
        address account;
        uint256 sdc;
        uint locktime;
        bool isIn;
        uint createttime;
    }
    
    mapping(address=>accountInputSdc[]) public accountInputSdcs;
    mapping(address=>accountOutputSdc[]) public accountOutputSdcs;
    mapping(address=>accoutInputOutputSdcLog[]) public accoutInputOutputSdcLogs;
    mapping(address=>uint) public unlockSdc;
    
    event lockLogs(address indexed _controller,address indexed _user,uint256 _sdc,uint _locktime,bool _islock);
    
    function inSdcForAdmin(address _address,uint256 _sdc,uint _locktime) public returns (bool b)   {
        require(msg.sender == sdcMainAcc);
        accountInputSdcs[_address].push(accountInputSdc(_address,_sdc,_locktime,now));
        lockLogs(msg.sender,_address,_sdc,_locktime,true);
        accoutInputOutputSdcLogs[_address].push(accoutInputOutputSdcLog(_address,_sdc,_locktime,true,now));
        return true;
    }
    
    function outSdcForUser(uint256 _sdc) public returns(bool b){
        for(uint i=0;i<accountInputSdcs[msg.sender].length;i++){
            if(now >= accountInputSdcs[msg.sender][i].locktime){
                unlockSdc[msg.sender] = unlockSdc[msg.sender]+accountInputSdcs[msg.sender][i].sdc;
                accountInputSdcs[msg.sender][i] = accountInputSdc(msg.sender,0,999999999999,now);
            }
        }
        require(unlockSdc[msg.sender]>=_sdc);
        sdcCon.transfer(msg.sender,_sdc);   
        unlockSdc[msg.sender] = unlockSdc[msg.sender]-_sdc;
        lockLogs(msg.sender,msg.sender,_sdc,now,false);
        accountOutputSdcs[msg.sender].push(accountOutputSdc(msg.sender,_sdc,now));
        accoutInputOutputSdcLogs[msg.sender].push(accoutInputOutputSdcLog(msg.sender,_sdc,999999999999,false,now));
        return true;
    }

   function nowInSeconds() constant public returns (uint){
        return now;
    }
    
    function getAccountInputSdcslength() constant public returns(uint b){
        return accountInputSdcs[msg.sender].length;
    }
    function getAccountOutputSdcslength() constant public returns(uint b){
        return accountOutputSdcs[msg.sender].length;
    }
    function getLockSdc() constant public returns(uint b){
        uint tmpLockSdc = 0;
        for(uint i=0;i<accountInputSdcs[msg.sender].length;i++){
            if(now < accountInputSdcs[msg.sender][i].locktime){
                tmpLockSdc = tmpLockSdc + accountInputSdcs[msg.sender][i].sdc;
            }
        }
        return tmpLockSdc;
    }
    function getUnlockSdc() constant public returns(uint b){
        uint tmpUnlockSdc = unlockSdc[msg.sender];
        for(uint i=0;i<accountInputSdcs[msg.sender].length;i++){
            if(now >= accountInputSdcs[msg.sender][i].locktime){
                tmpUnlockSdc = tmpUnlockSdc + accountInputSdcs[msg.sender][i].sdc;
            }
        }
        return tmpUnlockSdc;
    }
    function insetMoney() public returns(bool b){
        for(uint i=0;i<accountInputSdcs[msg.sender].length;i++){
            if(now >= accountInputSdcs[msg.sender][i].locktime){
                unlockSdc[msg.sender] = unlockSdc[msg.sender]+accountInputSdcs[msg.sender][i].sdc;
                accountInputSdcs[msg.sender][i] = accountInputSdc(msg.sender,0,999999999999,now);
            }
        }
        return true;
    }
    
    function() payable { }
}