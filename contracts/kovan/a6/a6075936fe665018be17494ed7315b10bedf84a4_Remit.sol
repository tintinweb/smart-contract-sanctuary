/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT

contract Ownable {
    
    modifier onlyOwner() {
        require(msg.sender==owner,"only owner allowed");
        _;
    }
    
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    
    address payable owner;
    address payable newOwner;

    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner, "only new owner allowed");
         emit OwnershipTransferred(
            owner,
            newOwner
        );
        owner = newOwner;
        
    }
}

abstract contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) view public virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is Ownable,  ERC20 {
    string public symbol;
    string public name;
    uint8 public decimals;
    
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    
 
    uint256 public circulationSupply;
    uint256 public stakeFarmSupply;
    uint256 public teamAdvisorSupply;
    uint256 public devFundSupply;
    uint256 public marketingSupply;
    uint256 public resverdSupply;
    
    uint256 public teamCounter; 
    uint256 public devFundCounter;
    
    mapping(uint256 => uint256) public  stakeFarmSupplyUnlockTime;
    mapping(uint256 => uint256) public  stakeFarmUnlockSupply;
    
    mapping(uint256 => uint256) public  teamAdvisorSupplyUnlockTime;
    mapping(uint256 => uint256) public  teamAdvisorSupplyUnlockSupply;
    
    mapping(uint256 => uint256) public  devFundSupplyUnlockTime;
    mapping(uint256 => uint256) public  devFundSupplyUnlockSupply;
    
    mapping(uint256 => uint256) public  marketingSupplyUnlockTime;
    mapping(uint256 => uint256) public  marketingUnlockSupply;
    
    mapping(uint256 => uint256) public  resverdSupplyUnlockTime;
    mapping(uint256 => uint256) public  resverdUnlockSupply;
    
	
	uint256 constant public maxSupply = 5000000 ether;
	uint256 constant public supplyPerYear =  1000000 ether;
	uint256 constant public oneYear = 31536000;
	uint256 constant public teamAdvisorPeriod = 5256000;
	uint256 constant public devFundPeriod = 2628000;
	

    address public farmAddress;
    address public stakeAddress;

   
    function balanceOf(address _owner) view public virtual override returns (uint256 balance) {return balances[_owner];}
    
    
    function transfer(address _to, uint256 _amount) public virtual override returns (bool success) {
      require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
      balances[msg.sender]-=_amount;
      balances[_to]+=_amount;
      emit Transfer(msg.sender,_to,_amount);
      return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public virtual override returns (bool success) {
      require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
      balances[_from]-=_amount;
      allowed[_from][msg.sender]-=_amount;
      balances[_to]+=_amount;
      emit Transfer(_from, _to, _amount);
      return true;
    }
  
    function approve(address _spender, uint256 _amount) public virtual override returns (bool success) {
      allowed[msg.sender][_spender]=_amount;
      emit Approval(msg.sender, _spender, _amount);
      return true;
    }
    
    function allowance(address _owner, address _spender) view public virtual override returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function burn(uint256 _amount) public onlyOwner returns (bool success) {
      require(_amount <= totalSupply, "The burning value cannot be greater than the Total Supply!");
      address addressToBurn = 0x2323232323232323232323232323232323232323;
      uint256 feeToOwner = _amount * 3 / 100; // 3%
      transfer(addressToBurn, _amount - feeToOwner); // burn
      transfer(owner, feeToOwner); // transfer to owner address
      return true;
    }

    function mint(address _to, uint256 _amount) private returns (bool) {
      require((_amount + totalSupply) <= maxSupply, "The total supply cannot exceed 5.000.000");
      totalSupply = totalSupply + _amount;
      balances[_to] = balances[_to] + _amount;
      emit Transfer(address(0), _to, _amount);
      return true;
    }
    
    
    function mintCirculationSupply(address to,uint256 _amount) external onlyOwner returns(bool){
        require(circulationSupply >= _amount);    
        mint(to,_amount);
        circulationSupply -= _amount;
        return true;
    }
    
    function mintMarketingSupply(address to,uint256 _amount) external onlyOwner returns(bool){
        for(uint i = 1;i <= 4 ; i++){
            if(marketingSupplyUnlockTime[i] < now && marketingUnlockSupply[i] != 0){
                marketingSupply += marketingUnlockSupply[i];
                marketingUnlockSupply[i] = 0;
            }
            if(marketingSupplyUnlockTime[i] >  now)
              break;
        }
        require(marketingSupply >= _amount);    
        mint(to,_amount);
        marketingSupply -= _amount;
        return true;
    }
    
    
    function setFarmAddress(address _farm) external onlyOwner returns(bool){
        farmAddress = _farm;
        return true;
    }
    
    function setStakeAddress(address _stake) external onlyOwner returns(bool){
        stakeAddress = _stake;
        return true;
    }
    
    function mintStakeFarmSupply(address to,uint256 _amount) external returns(uint256){
        require(msg.sender == farmAddress || msg.sender == stakeAddress,"err farm or stake address only");
        for(uint i = 1;i <= 4 ; i++){
            if(stakeFarmSupplyUnlockTime[i] < now && stakeFarmUnlockSupply[i] != 0){
                stakeFarmSupply += stakeFarmUnlockSupply[i];
                stakeFarmUnlockSupply[i] = 0;
            }
            if(stakeFarmSupplyUnlockTime[i] >  now)
              break;
        }
        if(_amount > stakeFarmSupply){
            _amount = stakeFarmSupply;
        }    
        mint(to,_amount);
        stakeFarmSupply -= _amount;
        return _amount;
    }
    
    
    function mintReservedSupply(address to,uint256 _amount) external onlyOwner returns(bool){
        for(uint i = 1;i <= 4 ; i++){
            if(resverdSupplyUnlockTime[i] < now && resverdUnlockSupply[i] != 0){
                resverdSupply += resverdUnlockSupply[i];
                resverdUnlockSupply[i] = 0;
            }
            if(resverdSupplyUnlockTime[i] >  now)
              break;
        }
        require(resverdSupply >= _amount);    
        mint(to,_amount);
        resverdSupply -= _amount;
        return true;
    }
    
    // for loop dont take too much cost as it only loop to 25
    function mintDevFundSupply(address to,uint256 _amount) external onlyOwner returns(bool){
        for(uint i = 1;i <= devFundCounter ; i++){
            if(devFundSupplyUnlockTime[i] < now && devFundSupplyUnlockSupply[i] != 0){
                devFundSupply += devFundSupplyUnlockSupply[i];
                devFundSupplyUnlockSupply[i] = 0;
            }
            if(devFundSupplyUnlockTime[i] >  now)
              break;
        }
        require(devFundSupply >= _amount);    
        mint(to,_amount);
        devFundSupply -= _amount;
        return true;
    }
    
    function mintTeamAdvisorFundSupply(address to,uint256 _amount) external onlyOwner returns(bool){
        for(uint i = 1;i <= teamCounter ; i++){
            if(teamAdvisorSupplyUnlockTime[i] < now && teamAdvisorSupplyUnlockSupply[i] != 0){
                teamAdvisorSupply += teamAdvisorSupplyUnlockSupply[i];
                teamAdvisorSupplyUnlockSupply[i] = 0;
            }
            if(teamAdvisorSupplyUnlockTime[i] >  now)
              break;
        }
        require(teamAdvisorSupply >= _amount);    
        mint(to,_amount);
        teamAdvisorSupply -= _amount;
        return true;
    }

    
    
    function _initSupply() internal returns (bool){
        
        circulationSupply = 370000 ether;
        stakeFarmSupply =  350000 ether;
        marketingSupply = 50000 ether;
        resverdSupply = 10000 ether;
        
        uint256 currentTime = now;
        uint256 tempAdvisor = 100000 ether;
        uint256 tempDev = 120000 ether;
    
        for(uint j = 1;j <= 6 ; j++){
            teamCounter+=1;
            teamAdvisorSupplyUnlockTime[teamCounter] = currentTime+(teamAdvisorPeriod*j);
            teamAdvisorSupplyUnlockSupply[teamCounter] = tempAdvisor/6;
            
        }
        
        for(uint k = 1;k <= 5 ; k++){
            devFundCounter+= 1;
            devFundSupplyUnlockTime[devFundCounter] = currentTime+(devFundPeriod*k);
            devFundSupplyUnlockSupply[devFundCounter] = tempDev/5;
            
        }
        
        
        for(uint i = 1;i <= 4 ; i++){
            currentTime += oneYear;
            
            stakeFarmSupplyUnlockTime[i] = currentTime;
            stakeFarmUnlockSupply[i] = 720000 ether;
         
            marketingSupplyUnlockTime[i] = currentTime;
            marketingUnlockSupply[i] = 50000 ether;
            
            resverdSupplyUnlockTime[i] = currentTime;
            resverdUnlockSupply[i] = 10000 ether;
            
            
           for(uint j = 1;j <= 6 ; j++){
                teamCounter+=1;
                teamAdvisorSupplyUnlockTime[teamCounter] = currentTime+(teamAdvisorPeriod*j);
                teamAdvisorSupplyUnlockSupply[teamCounter] = tempAdvisor/6;
            
           }
        
            for(uint k = 1;k <= 5 ; k++){
                devFundCounter+= 1;
                devFundSupplyUnlockTime[devFundCounter] = currentTime+(devFundPeriod*k);
                devFundSupplyUnlockSupply[devFundCounter] = tempDev/5;
                
            }
             
        }
            
 
    }
   
}

contract Remit is Token{
    
    
    
    constructor() public{
      symbol = "REMIT";
      name = "Remit";
      decimals = 18;
      totalSupply = 0;  
      owner = msg.sender;
      balances[owner] = totalSupply;
      _initSupply();
      
    }
    
    

    receive () payable external {
      require(msg.value>0);
      owner.transfer(msg.value);
    }
}