/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

pragma solidity 0.5.17;


contract Ownable {


  mapping (address=>bool) owners;

  event AddOwner(address newOwner,string name);
  event RemoveOwner(address owner);

   constructor() public {
    owners[msg.sender] = true;
  }


  modifier onlyOwners(){
    require(owners[msg.sender] == true );
    _;
  }

  function addOwner(address _newOwner,string memory newOwnerName) public onlyOwners{
    require(owners[_newOwner] == false);
    owners[_newOwner] = true;
    emit AddOwner(_newOwner,newOwnerName);
  }


  function removeOwner(address _owner) public onlyOwners{
    require(_owner != msg.sender);  // can't remove your self
    owners[_owner] = false;
    emit RemoveOwner(_owner);
  }

  function isOwner(address _owner) public view returns(bool){
    return owners[_owner];
  }

}

 contract ERC20 {

  	  function totalSupply() public view returns (uint256);
      function balanceOf(address tokenOwner) public view returns (uint256 balance);
      function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

      function transfer(address to, uint256 tokens) public returns (bool success);
       
      function approve(address spender, uint256 tokens) public returns (bool success);
      function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
      function decimals() public view returns(uint256);
      
      function createKYCData(bytes32 _KycData1, bytes32 _kycData2,address  _wallet) public returns(uint256);
	  function haveKYC(address _addr) public view returns(bool);
	  function getKYCData(address _wallet) public view returns(bytes32 _data1,bytes32 _data2);
	  
	       // For WSZO only
       function deposit(uint256 _amount) public;
       function withdraw(uint256 _amount) public;
       // SZO Only
       function intTransfer(address _from, address _to, uint256 _value) external  returns(bool);
	  
 }


contract POOLS{
    function getMaxDepositContract(address _addr) public view returns(uint256 _max);
    function getAllDepositIdx(address _addr) public view returns(uint256[] memory _idx);
    function getDepositDataIdx(uint256 idx) public view returns(uint256[] memory _data);
}

contract SZOCalcReward{
    function getReward(uint256 _time,uint256 _amount) public view returns(uint256);
}

contract SZORewardPools is Ownable{
    
    uint256 public version = 3;
    mapping (address => uint256) public lastTimeClaim;
    mapping (address => uint256) public poolsRewardIdx;
    mapping (address => bool) public poolsRewardActive;
    
    address[] public pools; 
    
    ERC20 szoToken;
    ERC20 wszoToken;
    
 
    bool  public  pauseReward;
    address public newPools;

    SZOCalcReward public calReward;
    SZOCalcReward public SPReward;
    
    
    constructor() public{
        szoToken = ERC20(0x6086b52Cab4522b4B0E8aF9C3b2c5b8994C36ba6); 
        wszoToken = ERC20(0x5538Ac3ce36e73bB851921f2a804b4657b5307bf);

        setPoolRewardAddr(0xE29659A35260B87264eBf1155dD03B7DE17d9B26); // DAI
        setPoolRewardAddr(0x1C69D1829A5970d85bCe8dD4A4f7f568DB492c81); // USDT
        setPoolRewardAddr(0x93347FFA6020a3904790220E84f38594F35bac7D); // USDC
        
        calReward = SZOCalcReward(0xCd02b50a0BEA9DE3f7dd2D898820842D2eC33D59); // call reward
        SPReward = SZOCalcReward(0xdAD2b958A445d9e57dD86ff2dc57Ed0DEEf10671);  // 2x Reward
        
        szoToken.approve(0x5538Ac3ce36e73bB851921f2a804b4657b5307bf,30000000 ether);
        

    }
    
    function setRewardCal(address _addr) public onlyOwners{
        calReward = SZOCalcReward(_addr);
    }
    
    function setSPRewardCal(address _addr) public onlyOwners{
        SPReward = SZOCalcReward(_addr);
    }
    
    function addWSZO(uint256 _amount) public onlyOwners{
         wszoToken.deposit(_amount);
    }
    
    function removeWSZO(uint256 _amount) public onlyOwners{
        wszoToken.withdraw(_amount);
    }
    
    function setPauseReward() public onlyOwners{
        pauseReward = true;
    }
    
    function moveToNewRewardPools(address _newAddr) public onlyOwners{
        require(pauseReward == true,"Please Pause before move to new pools");
        
        bytes32 _data1;
        bytes32 _data2;
        
        (_data1,_data2) = szoToken.getKYCData(address(this));
        
        if(szoToken.haveKYC(_newAddr)  == false){
          szoToken.createKYCData(_data1,_data2,_newAddr);    
        }
        
        uint256 amount = szoToken.balanceOf(address(this));
        newPools = _newAddr;
        szoToken.transfer(_newAddr,amount);
        amount = wszoToken.balanceOf(address(this));
        wszoToken.transfer(_newAddr,amount);
        
    }
    
    
    function setPoolRewardAddr(address _addr)public onlyOwners{
            if(poolsRewardIdx[_addr] == 0){
                uint256 idx = pools.push(_addr);
                poolsRewardIdx[_addr] = idx;
                poolsRewardActive[_addr] = true;
            }    
    }
    
    function setActivePools(address _addr,bool _act) public onlyOwners{
        poolsRewardActive[_addr] =  _act;
    }

    
    function getReward(address _contract,address _wallet) public view returns(uint256){
        if(poolsRewardActive[_contract] == false) return 0;
        
        POOLS  pool = POOLS(_contract);
        uint256 maxIdx = pool.getMaxDepositContract(_wallet);
        uint256[] memory idxs = new uint256[](maxIdx);
        idxs = pool.getAllDepositIdx(_wallet);
        uint256 totalReward;
        uint256 lastClaim = lastTimeClaim[_wallet];
        uint256[] memory _data = new uint256[](2);
        uint256 _reward;
        
        for(uint256 i=0;i<maxIdx;i++){
            _data = pool.getDepositDataIdx(idxs[i]-1);
            if(_data[0] > 0){
                if(_data[1] > lastClaim){
                    _reward =  calReward.getReward(now - _data[1],_data[0]); 
                }
                else
                {
                    _reward =  calReward.getReward(now - lastClaim,_data[0]); 
                }
                totalReward += _reward;
            }
        }
        
        return totalReward;
    }
    
    
    function getRewardSP(address _contract,address _wallet) public view returns(uint256){
        if(poolsRewardActive[_contract] == false) return 0;
        
        POOLS  pool = POOLS(_contract);
        uint256 maxIdx = pool.getMaxDepositContract(_wallet);
        uint256[] memory idxs = new uint256[](maxIdx);
        idxs = pool.getAllDepositIdx(_wallet);
        uint256 totalReward;
        uint256[] memory _data = new uint256[](2);
        uint256 _reward;
        
        uint256 lastClaim = lastTimeClaim[_wallet];
        
        
        for(uint256 i=0;i<maxIdx;i++){
            _data = pool.getDepositDataIdx(idxs[i]-1);
            if(_data[0] > 0){
                if(_data[1] > lastClaim )
                    _reward =  SPReward.getReward(_data[1],_data[0]); 
                else
                    _reward =  SPReward.getReward(lastClaim,_data[0]); 
                totalReward += _reward;
            }
        }
        
        return totalReward;
    }
    
    function summarySZOReward(address _addr) public view returns(uint256 sumBalance,uint256[] memory _pool,uint256[] memory _poolSP){
         _pool = new uint256[](pools.length);
         _poolSP = new uint256[](pools.length);
         
         for(uint256 i=0;i<pools.length;i++){
                _pool[i] = getReward(pools[i],_addr);
                _poolSP[i] = getRewardSP(pools[i],_addr);
                 sumBalance += _pool[i] + _poolSP[i];
             }
    }
     

    function claimWSZOReward(address _wallet) public returns(uint256 _claim){
        require(msg.sender == _wallet || owners[msg.sender] == true,"No permission to claim reward");
        require(pauseReward == false,"REWARD PAUSE TO CLAIM");
        
        (_claim,,) = summarySZOReward(_wallet);
        lastTimeClaim[_wallet] = now;
        if(_claim > wszoToken.balanceOf(address(this))) _claim = wszoToken.balanceOf(address(this));
        
        wszoToken.transfer(_wallet,_claim);
    }
    
    function claimReward(address _wallet) public  returns(uint256 _claim){
        require(msg.sender == _wallet || owners[msg.sender] == true,"No permission to claim reward");
        require(pauseReward == false,"REWARD PAUSE TO CLAIM");
        
        (_claim,,) = summarySZOReward(_wallet);
        lastTimeClaim[_wallet] = now;

        if(_claim > szoToken.balanceOf(address(this))) _claim = szoToken.balanceOf(address(this));

        szoToken.transfer(_wallet,_claim);
       
        return _claim;
    }
}