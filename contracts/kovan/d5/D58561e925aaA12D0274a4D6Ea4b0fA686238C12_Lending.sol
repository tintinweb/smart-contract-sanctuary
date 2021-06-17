/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity ^0.4.19;
pragma experimental ABIEncoderV2;

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
  
  function percent(uint numerator, uint denominator) internal pure returns(uint quotient) {
         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (10);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator)) / 10;
        return ( _quotient);
  }
}
contract ERC20_Interface {
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}


contract Ownable {
  address public owner;
  address public waitNewOwner;
    
  event transferOwner(address newOwner);
 
  function Ownable() public{
      owner = msg.sender;
  }
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   * and safe new contract new owner will be accept owner
   */
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      waitNewOwner = newOwner;
    }
  }
  /**
   * this function accept when transfer to new owner and new owner will be accept owner for safe contract free owner
   */
   
  function acceptOwnership() public {
      if(waitNewOwner == msg.sender) {
          owner = msg.sender;
          transferOwner(msg.sender);
      }else{
          revert();
      }
  }

}
contract LenderOwner is Ownable {
      address[] public ownerLender;
      address[] public reserveLender;
      event transferLenderOwner(address newLenderOwner);
    
    
      /**
       * @dev Throws if called by any account other than the owner.
       */
      modifier onlyLenderOwner() {
        for(uint256 i=0;i<ownerLender.length;i++){
            if(msg.sender == ownerLender[i]){
                _; 
            } 
        }
      }
    
      
    
      /**
       * @dev Allows the current owner to transfer control of the contract to a newOwner.
       * @param newOwner The address to transfer ownership to.
       * and safe new contract new owner will be accept owner
       */
      function updateLenderContract(address newOwner, uint256 number) onlyOwner public {
        if (newOwner != address(0)) {
          ownerLender[number] = newOwner;
           transferLenderOwner(newOwner);
        }
      }       
      function addLenderContract(address lenderAddress) onlyOwner public {
          if(lenderAddress != (address(0))){
            ownerLender.push(lenderAddress);  
          }
      }
      
      function removeLenderContract(address _address) onlyOwner public returns (address[]) {
        
          for(uint256 i=0;i<ownerLender.length;i++){
             reserveLender.push(ownerLender[i]);
          }
          for(uint256 v=0;v<reserveLender.length;v++){
             if(ownerLender[v] != _address){
                 ownerLender[v] = reserveLender[v];
             }
          }
          ownerLender.length--;
          delete reserveLender;
          return reserveLender;
         
      }
      function checkAdmin(address checker) onlyLenderOwner public returns (bool){
          return true;
      }
      function totalLender() public view returns (uint256) {
          return ownerLender.length;
      }
      
      function listLenderContract() public view returns (address[]) {
          return ownerLender;
      }
}
contract LockERC20 is LenderOwner {
   
    enum statusWithdraw {
        INACTIVE,
        ACTIVE
    }
    
    enum statusLockTransfer {
        ACTIVE,
        INACTIVE
    }
    struct lockToken  {
        address token;
        uint256 expire;
        uint256 block;
        uint256 start;
        uint256 amount;
        uint256 amountUnlock;
        statusLockTransfer isTransfer;
        statusWithdraw isWithdraw;
    }
    
    struct timeLock {
        address token;
        uint256 expire;
        uint256 block;
        uint256 start;
        uint256 amount;
        statusWithdraw isWithdraw;
    }
    using SafeMath for uint;
    // mapping (address => mapping (address => uint256)) public tokens;

    mapping (address => mapping(address => lockToken)) public tokens;
    mapping (address => mapping(address => timeLock)) public timelockhold;
    mapping (address => uint256) public balanceToken;
    mapping (address => uint256) public activeLock;
    mapping (address => mapping(address => uint256)) public pendingWithdraw;
    
    uint256 public isExpire = 1 days;

    event DepositToken(address contractAddress, address sender, uint256 amount, uint256 expire);
    event WithdrawTL(address contractAddress, address sender, uint256 amount);
    event WithdrawToken(address contractAddress, address sender, uint256 amount, uint256 amountexists);
    event AdminWT(address contractAddress, address sender, uint256 amount, string message);
    event RequestWithdraw(address contractAddress, address sender);
    function setExpire(uint256 expire) onlyOwner public{
        isExpire = expire;
    }
    function depositTimeLock(address likeAddr, address holder, uint amount, uint256 lockto) public returns (bool){
        if(amount > ERC20_Interface(likeAddr).allowance(msg.sender, address(this))) {  
          revert();  
        }  
        ERC20_Interface(likeAddr).transferFrom(msg.sender, address(this), amount);

        timeLock memory hl = timelockhold[likeAddr][holder];
        hl.token = likeAddr;
        hl.expire = now.add(lockto);
        hl.block = block.number;
        hl.start = now;
        hl.amount = hl.amount.add(amount);
        hl.isWithdraw = statusWithdraw.INACTIVE;
        timelockhold[likeAddr][holder] = hl;

        balanceToken[likeAddr] = balanceToken[likeAddr].add(amount);
        activeLock[likeAddr] = activeLock[likeAddr].add(amount);
        DepositToken(likeAddr, msg.sender, amount, lockto);
        return true;
        
    }
    function withdrawTimeLock(address likeAddr, uint amount) public  returns (bool){
        timeLock memory holderLock = timelockhold[likeAddr][msg.sender];
        require(now > holderLock.expire);
        require(amount <= holderLock.amount);

        holderLock.amount = holderLock.amount.sub(amount);
        timelockhold[likeAddr][msg.sender] = holderLock;      
        balanceToken[likeAddr]= balanceToken[likeAddr].sub(amount);
        activeLock[likeAddr] = activeLock[likeAddr].sub(amount);
        ERC20_Interface(likeAddr).transfer(msg.sender, amount);
        WithdrawTL(likeAddr, msg.sender, amount);
        return true;
        
    }
    
    function depositToken(address likeAddr, uint amount, uint256 expire) public returns (bool){
        if(amount > ERC20_Interface(likeAddr).allowance(msg.sender, address(this))) {  
          revert();  
        }  
        ERC20_Interface(likeAddr).transferFrom(msg.sender, address(this), amount);
        
        lockToken memory tokenData = tokens[likeAddr][msg.sender];
          //เช็คว่าปลดล็อคไว้หรือ
        //check pendingWithdraw
        if(pendingWithdraw[likeAddr][msg.sender] > 0){
            activeLock[likeAddr] = activeLock[likeAddr].add(pendingWithdraw[likeAddr][msg.sender]);
            pendingWithdraw[likeAddr][msg.sender] = 0;
            tokenData.amountUnlock = 0;
        }
        tokenData.token = likeAddr;
        tokenData.expire = now.add(expire);
        tokenData.block = block.number;
        tokenData.start = now;
        tokenData.amount = tokenData.amount.add(amount);
        tokenData.isWithdraw = statusWithdraw.INACTIVE;
        tokens[likeAddr][msg.sender] = tokenData;
        balanceToken[likeAddr] = balanceToken[likeAddr].add(amount);
        activeLock[likeAddr] = activeLock[likeAddr].add(amount);
 
        DepositToken(likeAddr, msg.sender, amount, expire);
        return true;
        
    }
    function depositTokenByAdmin(address likeAddr, address recev, uint amount, uint256 expire) public returns (bool){
        if(amount > ERC20_Interface(likeAddr).allowance(msg.sender, address(this))) {  
          revert();  
        }  
        ERC20_Interface(likeAddr).transferFrom(msg.sender, address(this), amount);
        
        lockToken memory tokenData = tokens[likeAddr][recev];
          //เช็คว่าปลดล็อคไว้หรือ
        //check pendingWithdraw
        if(pendingWithdraw[likeAddr][msg.sender] > 0){
            activeLock[likeAddr] = activeLock[likeAddr].add(pendingWithdraw[likeAddr][msg.sender]);
            pendingWithdraw[likeAddr][msg.sender] = 0;
            tokenData.amountUnlock = 0;
        }
        tokenData.token = likeAddr;
        tokenData.expire = now.add(expire);
        tokenData.block = block.number;
        tokenData.start = now;
        tokenData.amount = tokenData.amount.add(amount);
        tokenData.isWithdraw = statusWithdraw.INACTIVE;
        tokens[likeAddr][recev] = tokenData;
        balanceToken[likeAddr] = balanceToken[likeAddr].add(amount);
        activeLock[likeAddr] = activeLock[likeAddr].add(amount);

        DepositToken(likeAddr, recev, amount, expire);
        return true;
        
    }
    function requestWithdraw(address likeAddr, uint256 amount) public returns (bool){
        lockToken memory tokenData = tokens[likeAddr][msg.sender];
        require(tokenData.isWithdraw == statusWithdraw.INACTIVE);
        require(tokenData.isTransfer == statusLockTransfer.ACTIVE);
        require(tokenData.amount >= amount);
        tokenData.isWithdraw = statusWithdraw.ACTIVE;
        tokenData.expire = now.add(isExpire);
        tokenData.amountUnlock = amount;
        tokens[likeAddr][msg.sender] = tokenData;
        //pending withdraw
        pendingWithdraw[likeAddr][msg.sender] = amount;
        
        activeLock[likeAddr] = activeLock[likeAddr].sub(amount);
        RequestWithdraw(likeAddr, msg.sender);
        return true;
    }
    function withdrawToken(address likeAddr) public  returns (bool){
        lockToken memory tokenData = tokens[likeAddr][msg.sender];
        require(now > tokenData.expire);
        require(tokenData.amountUnlock <= tokenData.amount);
        require(tokenData.isWithdraw == statusWithdraw.ACTIVE);
        require(tokenData.isTransfer == statusLockTransfer.ACTIVE);
        
        balanceToken[likeAddr]= balanceToken[likeAddr].sub(tokenData.amountUnlock);
        ERC20_Interface(likeAddr).transfer(msg.sender, tokenData.amountUnlock);
        tokenData.amount = tokenData.amount.sub(tokenData.amountUnlock);
        uint256 amount = tokenData.amountUnlock;
        tokenData.amountUnlock = 0;
        tokenData.isWithdraw = statusWithdraw.INACTIVE;
        tokens[likeAddr][msg.sender] = tokenData;      
      
        //pending withdraw clear
        pendingWithdraw[likeAddr][msg.sender] = 0;
    
        
        WithdrawToken(likeAddr, msg.sender, amount, tokenData.amount);
        return true;
        
    }
    function getTransfer(address likeAddr, address _sender) public view returns (statusLockTransfer) {
        return tokens[likeAddr][_sender].isTransfer;
    }
    function getLock(address likeAddr, address _sender) public view returns (uint256){
          return tokens[likeAddr][_sender].amount;
    }
    function getWithdraw(address likeAddr, address _sender) public view returns (statusWithdraw) {
        return tokens[likeAddr][_sender].isWithdraw;
    }
    function getAmount(address likeAddr, address _sender) public view returns (uint256) {
        return tokens[likeAddr][_sender].amount.add(timelockhold[likeAddr][_sender].amount).sub(pendingWithdraw[likeAddr][_sender]);
    }
    function getDepositTime(address likeAddr, address _sender) public view returns (uint256) {
        return tokens[likeAddr][_sender].start;
    }
    function adminWithdraw(address likeAddr, uint amount, string  message) onlyOwner public {
        // require(amount <= balanceToken[likeAddr]);
        ERC20_Interface(likeAddr).transfer(msg.sender, amount);    
        AdminWT(likeAddr, msg.sender, amount, message);
    }
    function getActiveLock(address likeAddr) public view returns (uint256) {
        return activeLock[likeAddr];
    }
    


}

contract Lending is LockERC20 {
    
    event TransferWithdrawFund(address contractAddress, address sender, uint256 amount);
    event TransferDepositFund(address contractAddress, address sender, uint256 amount);
    event LiquidateCollateral(address likeAddr, address borrower, uint256 fullcollateral, uint256 collateral, address liquidator, uint256 dept);
    mapping (address => uint256) public balanceLending;
    
    function adminClearBlacklist(address likeAddr, address borrower) onlyOwner public returns (bool){
           lockToken memory tokenData = tokens[likeAddr][borrower];
           tokenData.isTransfer = statusLockTransfer.ACTIVE;
           tokens[likeAddr][borrower] = tokenData;
           return true;
    } 
    function transferWithdrawFund(address likeAddr, address borrower, uint amount) onlyLenderOwner public returns (bool) {
        //decrease balance of borrower
        lockToken memory tokenData = tokens[likeAddr][borrower];
        tokenData.amount = tokenData.amount.sub(amount);
        tokenData.isTransfer = statusLockTransfer.INACTIVE;
        tokens[likeAddr][borrower] = tokenData;
        
        balanceToken[likeAddr] = balanceToken[likeAddr].sub(amount);
        balanceLending[likeAddr] = balanceLending[likeAddr].add(amount);
        ERC20_Interface(likeAddr).transfer(borrower, amount);
        TransferWithdrawFund(likeAddr, borrower, amount);
        return true;
    }
    
    function transferDepositFund(address likeAddr, address borrower, uint amount, uint canTransfer) onlyLenderOwner public returns (bool) {
        //increase balance of borrower
        lockToken memory tokenData = tokens[likeAddr][borrower];
        tokenData.amount = tokenData.amount.add(amount);
        if(canTransfer == 1){
            tokenData.isTransfer = statusLockTransfer.ACTIVE;
        }
        tokens[likeAddr][borrower] = tokenData;
             
        balanceToken[likeAddr] = balanceToken[likeAddr].add(amount);
        balanceLending[likeAddr] = balanceLending[likeAddr].sub(amount);
        ERC20_Interface(likeAddr).transferFrom(borrower, address(this), amount);
        TransferWithdrawFund(likeAddr, borrower, amount);
        return true;
    }
    
    function liquidateCollateral(address likeAddr, address borrower, uint256 collateral, uint256 liquidate, address liquidator, uint256 dept)  onlyLenderOwner public returns (bool) {
     
        lockToken memory tokenData = tokens[likeAddr][borrower];
         
             balanceToken[likeAddr] = balanceToken[likeAddr].sub(liquidate);
             tokenData.amount = tokenData.amount.sub(liquidate);
             activeLock[likeAddr] = activeLock[likeAddr].sub(liquidate.add(dept));
             balanceLending[likeAddr] = balanceLending[likeAddr].sub(dept);
             ERC20_Interface(likeAddr).transfer(liquidator, liquidate);  
 
        tokenData.isTransfer = statusLockTransfer.ACTIVE;
        tokens[likeAddr][borrower] = tokenData;     
         
        LiquidateCollateral(likeAddr, borrower, collateral ,liquidate, liquidator, dept);
         
        return true;   
    }

}