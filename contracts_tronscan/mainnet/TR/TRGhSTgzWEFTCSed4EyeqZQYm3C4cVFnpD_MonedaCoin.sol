//SourceUnit: MonedaCoin.sol

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// -----------------------------------------

import "./Ownable.sol";

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function transfer(address to, uint256 tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


contract MonedaCoin is ERC20Interface , Ownable{
    string public name = "Moneda";
    string public symbol = "MCAM";
    uint256 public decimals = 9; 
    uint256 public override totalSupply;
    uint256 private _decimal = decimals; 
    
    address public founder;
    address public liquidityWallet;
    address public rewardWallet;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint)) allowed;
    
    mapping(address => uint256) private _firstSell;
    mapping(address => uint256) private _totSells;
    
    mapping(address => uint256) private _firstbuy;
    mapping(address => uint256) private _totbuy;
    
    mapping(address => bool) private _isBadActor;
  
    mapping (address => bool) private _isExcludedFromFee;
    
    address[] private _addressList;
    mapping (address => bool) private _isExistsinAddressList;
    
    mapping(address => bool) public _isReward1;
    mapping(address => uint256) public _reward1Time;    ///////1000 above or equal 
    
    mapping(address => bool) public _isReward2;
    mapping(address => uint256) public _reward2Time;  ///////5000 above or equal 
    
    mapping(address => bool) public _isReward3;
    mapping(address => uint256) public _reward3Time;  ///////10000 above or equal 
   
    
    uint256 public maxSellAmountPerDay = 500 * 10**_decimal;
    uint256 public maxSellAmountPerTxn = 500 * 10**_decimal;
    
    uint256 public maxBuyAmountPerDay = 5000 * 10**_decimal;
    uint256 public maxBuyAmountPerTxn = 500 * 10**_decimal;
    
    uint256 public totalBurnAmount;
    
    address[] private _coreTeam;
    mapping(address => bool) private _isCoreTeam;
    
    constructor(){
        totalSupply = 6000000 * 10**_decimal;
        totalBurnAmount =3000000 * 10**_decimal;
        founder = msg.sender;
        rewardWallet=founder;
        liquidityWallet =founder;
        balances[founder] = totalSupply;
        _isExcludedFromFee[founder] = true;
        _isExcludedFromFee[address(this)] = true;
        
        _addressList.push(founder);
        _isExistsinAddressList[founder] = true;
        
        emit Transfer(address(0), founder, totalSupply);
    }
    
    function balanceOf(address tokenOwner) public view override returns (uint256 balance){
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint256 amount) public override returns(bool success){
        
        require(to !=msg.sender, "transfer from same address");
        require(to != address(0), "transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Low balance" );
        require(!_isBadActor[msg.sender] && !_isBadActor[to], "Bots are not allowed");
        _transfer(msg.sender,to,amount);
        return true;
    }
    
    function _transfer( address from, address to, uint256 amount ) private {
        bool isBuy =false;
        bool isSell =false;
        uint256 transferAmount=amount;
        uint256 rewardAmount=0;
        
        
        if(!_isExistsinAddressList[to])
        { 
             _addressList.push(to);
             _isExistsinAddressList[to] = true;
        }
        
        if(!_isExistsinAddressList[from])
        { 
             _addressList.push(from);
             _isExistsinAddressList[from] = true;
        }
        
       
        if(balances[to]+amount>=10000 * 10**_decimal && balances[to]<10000 * 10**_decimal )
        {
            if(balances[to]<1000 * 10**_decimal )
            {
                 _reward1Time[to] =block.timestamp;
                 _reward2Time[to] =block.timestamp;
            }
            if(balances[to]<5000 * 10**_decimal  && balances[to]>=1000 * 10**_decimal )
            {
                 _reward2Time[to] =block.timestamp;
            }
           _reward3Time[to] = block.timestamp;
           
            _isReward1[to] = false;
            _isReward2[to] = false;
            _isReward3[to] = true;
            
        }
        else if(balances[to]+amount>=5000 * 10**_decimal && balances[to]<5000 * 10**_decimal)
        {
            if(balances[to]<1000 * 10**_decimal )
            {
                 _reward1Time[to] =block.timestamp;
            }
            _reward2Time[to] =block.timestamp;
            _reward3Time[to] = block.timestamp;
            _isReward1[to] = false;
            _isReward2[to] = true;
            _isReward3[to] = false;
        }
        else if(balances[to]+amount>=1000 * 10**_decimal && balances[to]<1000 * 10**_decimal)
        {
          _reward1Time[to] =block.timestamp;
          _reward2Time[to] =block.timestamp; 
          _reward3Time[to] =block.timestamp;
          _isReward1[to] = true;
          _isReward2[to] = false;
          _isReward3[to] = false;
        }
        else if(balances[to]+amount<1000 * 10**_decimal)
        {
           _reward1Time[to] =block.timestamp;
           _reward2Time[to] =block.timestamp; 
           _reward3Time[to] =block.timestamp;
           _isReward1[to] = false;
           _isReward2[to] = false;
           _isReward3[to] = false;
        }
        
        if(balances[from]-amount<1000 * 10**_decimal)
        {
           _reward1Time[from] =block.timestamp;
           _reward2Time[from] =block.timestamp; 
           _reward3Time[from] =block.timestamp;
           _isReward1[from] = false;
           _isReward2[from] = false;
           _isReward3[from] = false;
        }
        else if (balances[from]-amount<5000 * 10**_decimal && balances[from]-amount>=1000 * 10**_decimal)
        {
           _reward2Time[from] =block.timestamp; 
           _reward3Time[from] =block.timestamp;
           _isReward1[from] = true;
           _isReward2[from] = false;
           _isReward3[from] = false;
        }
        else if (balances[from]-amount<10000 * 10**_decimal && balances[from]-amount>=5000 * 10**_decimal)
        {
           _reward3Time[from] =block.timestamp;
           _isReward1[from] = false;
           _isReward2[from] = true;
           _isReward3[from] = false;
        }
        
        if (from==liquidityWallet && !_isExcludedFromFee[to])
        {
           require(amount <= maxBuyAmountPerTxn, "You can't buy more than maxbuy per transaction");
           if(block.timestamp < _firstbuy[to]+24 * 1 hours){
                require(_totbuy[to]+amount <= maxBuyAmountPerDay, "You can't buy more than maxBuyPerDay");
                _totbuy[to] += amount;
            }
            else{
                 require(amount <= maxBuyAmountPerDay, "You can't buy more than maxBuyPerDay");
                _firstbuy[to] = block.timestamp;
                _totbuy[to] = amount;
            }
            isBuy = true; 
        }
        
        if (to==liquidityWallet && !_isExcludedFromFee[from])
        {
            require(amount <= maxSellAmountPerTxn, "You can't sell more than maxSell per transaction");
            if(block.timestamp < _firstSell[from]+24 * 1 hours){
                require(_totSells[from]+amount <= maxSellAmountPerDay, "You can't sell more than maxSellPerDay");
                _totSells[from] += amount;
            }
            else{
                require(amount <= maxSellAmountPerDay, "You can't sell more than maxSellPerDay");
                _firstSell[from] = block.timestamp;
                _totSells[from] = amount;
            }
            isSell = true;
        }
        
        if(isBuy)
        {
           transferAmount =amount*98/100;
           rewardAmount = amount*2/100;
           balances[rewardWallet] += rewardAmount; 
           balances[to] += transferAmount;
           balances[from] -= amount;
            _burn(founder,amount*25/1000, true);
           emit Transfer(from, to, transferAmount);
           emit Transfer(from, rewardWallet, rewardAmount);
           
        }else if(isSell)
        {
           rewardAmount = amount*2/100;
           require(balances[from] >= amount+rewardAmount, "Low balance" );
           balances[rewardWallet] += rewardAmount; 
           balances[to] += transferAmount;
           balances[from] -= transferAmount+rewardAmount;
            _burn(founder,amount*25/1000, true);
           emit Transfer(from, to, transferAmount);
           emit Transfer(from, rewardWallet, rewardAmount);
           
        }else
        {
            if (_isExcludedFromFee[to] || _isExcludedFromFee[from])
            {
               balances[to] += transferAmount;
               balances[from] -= transferAmount;
               emit Transfer(from, to, transferAmount);
            }
            else
            {
               transferAmount =amount*98/100;
               rewardAmount = amount*2/100;
               balances[rewardWallet] += rewardAmount; 
               balances[to] += transferAmount;
               balances[from] -= amount;
                _burn(founder,amount*25/1000, true);
               emit Transfer(from, to, transferAmount);
               emit Transfer(from, rewardWallet, rewardAmount);
            }
        }
        
    }
    
    function allowance(address tokenOwner, address spender) view public override returns(uint256){
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint256 tokens) public override returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success){
         require(allowed[from][to] >= tokens);
         require(balances[from] >= tokens);
         _transfer(from,to,tokens);
         allowed[from][to] -= tokens;
         return true;
     }
     
    function _burn(address account, uint256 value, bool isTrrxnburn) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        if (isTrrxnburn)
        {
            if (totalBurnAmount>value)
            {
                totalSupply -= value;
                balances[account] -= value;
                totalBurnAmount-= value;
                emit Transfer(account, address(0), value);
            }
        }else
        {
            totalSupply -= value;
            balances[account] -= value;
            emit Transfer(account, address(0), value);
        }
    }
     
    function setMaxSellAmountPerDay(uint256 amount) external onlyOwner{
        maxSellAmountPerDay = amount * 10**_decimal;
    } 
   
    function setmaxSellAmountPerTxn(uint256 amount) external onlyOwner{
        maxSellAmountPerTxn = amount * 10**_decimal;
    } 
    
    function setMaxBuyAmountPerDay(uint256 amount) external onlyOwner{
        maxBuyAmountPerDay = amount * 10**_decimal;
    } 
    
    function setMaxBuyAmountPerTxn(uint256 amount) external onlyOwner{
        maxBuyAmountPerTxn = amount * 10**_decimal;
    } 
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
   // To be used for snipe-bots and bad actors communicated on with the community.
    function badActorDefenseMechanism(address account, bool isBadActor) external onlyOwner{
        _isBadActor[account] = isBadActor;
    }
    
    function checkBadActor(address account) public view returns(bool){
        return _isBadActor[account];
    }
    
    function setLiquidityWallet(address payable _address) external onlyOwner returns (bool){
        liquidityWallet = _address;
        _isExcludedFromFee[liquidityWallet] = true;
        return true;
    }
    
    function setRewardWallet(address payable _address) external onlyOwner returns (bool){
        rewardWallet = _address;
        _isExcludedFromFee[rewardWallet] = true;
        return true;
    }
    
    function addInCoreTeam(address account) public onlyOwner() {
        require(!_isCoreTeam[account], "Account is already added");
        _isCoreTeam[account] = true;
        _coreTeam.push(account);
    }
    
    function removeFromCoreTeam(address account) external onlyOwner() {
        require(_isCoreTeam[account], "Account is already removed");
        for (uint256 i = 0; i < _coreTeam.length; i++) {
            if (_coreTeam[i] == account) {
                _coreTeam[i] = _coreTeam[_coreTeam.length - 1];
                _isCoreTeam[account] = false;
                _coreTeam.pop();
                break;
            }
        }
    }
    
    function getCoreTeam()public onlyOwner view returns(address[] memory){
         return _coreTeam;
    }
    
    function getAddressList()public onlyOwner view returns(address[] memory){
         return _addressList;
    }
    
    function getTimeStamp()public onlyOwner view returns(uint256){
         return block.timestamp;
    }
    
    function isReward1Address(address account)public onlyOwner view returns(bool)    {
       if((block.timestamp >= _reward1Time[account] + 24 * 15 hours) &&  _isReward1[account] && !_isBadActor[account] && rewardWallet!=account)
       {
           return true;
       }
       return false;
    }
    
    function isReward2Address(address account)public onlyOwner view returns(bool)    {
         if((block.timestamp >= _reward2Time[account] + 24 * 15 hours) &&  _isReward2[account] && !_isBadActor[account] && rewardWallet!=account)
         {
             return true;
         }
         return false;
    }
    
    function isReward3Address(address account)public onlyOwner view returns(bool)  {
        if((block.timestamp >= _reward3Time[account] + 24 * 15 hours) &&  _isReward3[account] && !_isBadActor[account] && rewardWallet!=account)
        {
            return true;
        }
        return false;
    }
    
    function sendReward()public onlyOwner {
       
       uint256 reward1count = 0;
       uint256 reward2count = 0;
       uint256 reward3count = 0;
       
       uint256 reward1start = 0;
       uint256 reward2start = 0;
       uint256 reward3start = 0;
       
       
       for (uint256 i = 0; i < _addressList.length; i++) 
       {
           if(isReward3Address(_addressList[i]))
           {
              reward3count++;
           }
           else if(isReward2Address(_addressList[i]))
           {
               reward2count++;
           }
           else  if(isReward1Address(_addressList[i]))
           {
               reward1count++;
           }
       }
       
       uint256 totalRewardAmount  =  balances[rewardWallet];
       uint256 perReward1amount = 0;
       uint256 perReward2amount = 0;
       uint256 perReward3amount = 0;
       uint256 perRewardCoreAmount  = (totalRewardAmount*25/100)/_coreTeam.length;
       
       if (reward1count>0)
       {
           perReward1amount = (totalRewardAmount*20/100)/reward1count;
       }
       
       if (reward2count>0)
       {
           perReward2amount = (totalRewardAmount*25/100)/reward2count;
       }
       
       if (reward3count>0)
       {
           perReward3amount = (totalRewardAmount*30/100)/reward3count;
       }
       
       for (uint256 i = 0; i < _addressList.length; i++) 
       {
           if(isReward3Address(_addressList[i]) && reward3count>reward3start)
           {
              reward3start++;
              balances[rewardWallet] -= perReward3amount;
              balances[_addressList[i]] += perReward3amount;
              emit Transfer(rewardWallet, _addressList[i], perReward3amount);
             
           }
           else if(isReward2Address(_addressList[i]) && reward2count>reward2start)
           {
               reward2start++;
               balances[rewardWallet] -= perReward2amount;
               balances[_addressList[i]] += perReward2amount;
               emit Transfer(rewardWallet, _addressList[i], perReward2amount);
           }
           else  if(isReward1Address(_addressList[i]) && reward1count>reward1start)
           {
              balances[rewardWallet] -= perReward1amount;
              balances[_addressList[i]] += perReward1amount;
              emit Transfer(rewardWallet, _addressList[i], perReward1amount);
              reward1start++;
           }
       }
       
       for (uint256 i = 0; i < _coreTeam.length; i++) 
       {
            balances[rewardWallet] -= perRewardCoreAmount;
            balances[_coreTeam[i]] += perRewardCoreAmount;
            emit Transfer(rewardWallet, _coreTeam[i], perRewardCoreAmount);
       }
    }  
    
}


//SourceUnit: Ownable.sol

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

abstract contract Ownable  {
    address private _owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _setOwner(msg.sender);
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }


    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}