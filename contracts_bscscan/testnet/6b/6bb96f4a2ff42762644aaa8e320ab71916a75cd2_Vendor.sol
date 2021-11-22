/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
contract Owner {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    
}
    constructor() {
        owner = msg.sender; 
        emit OwnerSet(address(0), owner);
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}
 contract Test01 is Owner {
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
   
    string public name = "Test01";
    string public symbol = "TST01";
    uint  public  decimals = 18;
     
    uint internal fee;
    address internal safeBox;
    address internal incinerator = 0x3A0D79acB2D3882262D88D13B11A11E4d3b2fDF4;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event DestroyTokens(uint256 amountTokens);
    
    uint public totalSupply = 500_000_000 * 10 ** 18;
   
   constructor() {   
       
    
   } 
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "Saldo insuficiente (balance too low)");
        uint theFee = (value * fee / 100);
        balances[to] += value - theFee ;
        balances[safeBox] += theFee;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, "Saldo insuficiente (balance too low)");
        require(allowance[from][msg.sender] >= value, "Sem permissao (allowance too low)");
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function setNewFee(uint newFee) public isOwner {
        fee = newFee;
    }
    
    function setNewSafeBox(address newSafeBox) public isOwner {
        safeBox = newSafeBox;
    }
    
     function burnFrom(address from, uint256 amountToBurn) public isOwner returns(uint256) {
        require(balances[from] >= amountToBurn);
               balances[from] -=  amountToBurn;
               balances[incinerator] += amountToBurn;
               uint256 amountBurned = amountToBurn;
            return amountBurned;   
     }
     
    function destroyTokens(uint256 amountTokens) public isOwner returns(bool sucess) {
            require(balanceOf(msg.sender) >= amountTokens, "Saldo insuficiente (balance too low)");
            totalSupply -= amountTokens;        
    	    balances[msg.sender] -= amountTokens;
    	emit DestroyTokens(amountTokens);
    	return true;
    }
}

contract Vendor is Test01{

  // token price for ETH WEI 10^18
  uint256 public  buyPrice  =  2500000000;
  uint256 public  sellPrice =  2400000000;
  uint256 public tokensAvailable   = totalSupply;   // Number of tokens available for sell.
  uint256 public distributedTokens = 0;                 // Number of tokens distributed.
  uint256 public solvency          = balances[msg.sender];    
  uint256 public  marketing =  0;
  address public walletMarketing;
        // Event that log buy operation

    event LogDeposit(address sender, uint amount);
    event LogWithdrawal(address receiver, uint amount);
    event Buy(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event Sell(address seller, uint256 amountOfTokens, uint256 amountOfETH);


   
    constructor() {
        totalSupply = totalSupply;
        balances[msg.sender] = totalSupply;
     
 
  }
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);
        balances[_to] += _value;
        balances[_from] -= _value;
    emit Transfer(_from, _to, _value); 
    
    }
     
    function _updateDistributedTokens(uint256 _distributedTokens) internal {
        distributedTokens = _distributedTokens;
        
    }
    
     function _updateSolvency(uint256 _solvency) internal {
        solvency = _solvency;
        
    }
    
    function _updateMarketing(uint256 _increment, bool add) internal{
        if (add){
            // Increase the profit value
              marketing = marketing + _increment;
        }else{
            // Decrease the profit value
            if(_increment >marketing ) {
                marketing = 0;
            }else{
                 marketing = marketing - _increment;
            }
        }

    }
   
    function buy() public payable returns(uint256 tokenAmount) {
       uint256 amountToBuy = msg.value / buyPrice;
        uint256 marketing_in_transaction = msg.value - (amountToBuy * sellPrice);
        require(marketing_in_transaction > 0 );
    
       _transfer(address(this), msg.sender, amountToBuy);
       distributedTokens = distributedTokens + amountToBuy;
       _updateSolvency(address(this).balance - marketing_in_transaction);
       _updateMarketing(marketing_in_transaction, true);             
       _transfer(address(this), walletMarketing, marketing_in_transaction);
       emit Buy(msg.sender, msg.value, amountToBuy);
       return tokenAmount;
    }

    function sell(uint256 amountToSell) public {
        require(amountToSell > 0, "Specify an amount of token greater than zero");
        require(address(this).balance >= amountToSell * sellPrice);
          
         _transfer(msg.sender, address(this), amountToSell);
         distributedTokens = distributedTokens - amountToSell;
         _updateSolvency( (address(this).balance - (amountToSell * sellPrice)) );
         _transfer(address(this), msg.sender, (amountToSell * sellPrice));
       
    }
    
    function setWalletMarketing(address newWalletMarketing) public isOwner {
        walletMarketing = newWalletMarketing;
    }
  
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public isOwner {
        sellPrice = newSellPrice; // Updates the buying price.
        buyPrice = newBuyPrice;   // Updates the selling price.

    }
   
    function withdraw(uint amountInWeis) public  isOwner {
       emit LogWithdrawal(msg.sender, amountInWeis);
         uint256 ownerBalance = address(this).balance;
        _updateSolvency(address(this).balance -amountInWeis);
        _updateMarketing(amountInWeis, true);
        
       require(ownerBalance > 0, "Owner has not balance to withdraw");

     (bool sent,) = msg.sender.call{value: address(this).balance}("");
     require(sent, "Failed to send user balance back to the owner");

  }   
    function deposit() public payable returns(bool sucess) {
       address(this).balance + msg.value; 
       _updateSolvency(address(this).balance);
       _updateMarketing(msg.value, false);
       emit LogDeposit(msg.sender, msg.value);
        return true;
   }  

}