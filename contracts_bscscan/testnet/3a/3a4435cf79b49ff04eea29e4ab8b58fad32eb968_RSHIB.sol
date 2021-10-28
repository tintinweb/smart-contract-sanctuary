/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.6; 

contract Owned {
    
    /// Modifier for owner only function call
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    address public owner;
   
    /// Function to transfer ownership 
    /// Only owner can call this function
    function changeOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
}

contract ERC20 is Owned {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
  
    bool public change;
    uint public percent;
    
    uint public marketingPercent = 3;
    uint public liquidityPoolPercent = 4;
    uint public holderDistributorPercent = 2;
    
    address public marketingAddress;
    address public liquidityPoolAddress;
    address public holdersDistributorAddress;
    address[] public tokenHoldersArr;
    
   
    mapping (address=>bool) public tokenHoldersMap;
    mapping (address=>uint256) internal balances;
    mapping (address=>mapping (address=>uint256)) internal allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    /// Returns the token balance of the address which is passed in parameter
    function balanceOf(address _owner) view public  returns (uint256 balance) {return balances[_owner];}
    
    /**
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address _to, uint256 _amount) public returns (bool) {
        
        require(_to != address(0), "Transfer to zero address");
        require (balances[msg.sender]>=_amount && _amount>0 && balances[_to]+_amount>balances[_to], "Insufficient amount or allowance error");
        if(change == true){
            
            balances[msg.sender]-=_amount;
            
            //marketingPercents
            uint marketingAmt = _amount * marketingPercent / 100;
            balances[marketingAddress] += marketingAmt;
            emit Transfer(msg.sender,marketingAddress,marketingAmt);
            
             //liquidityPoolPercents
            uint liquidityPoolAmt = _amount * liquidityPoolPercent / 100;
            balances[liquidityPoolAddress] += liquidityPoolAmt;
            emit Transfer(msg.sender,liquidityPoolAddress,liquidityPoolAmt);
            
             //holderDistributor
            uint holderDistributorAmt = _amount * holderDistributorPercent / 100;
            balances[holdersDistributorAddress] += holderDistributorAmt;
            emit Transfer(msg.sender,holdersDistributorAddress,holderDistributorAmt);
            
            // user Amount
            uint remainingAmt = _amount - (marketingAmt+liquidityPoolAmt+holderDistributorAmt);
            balances[_to] += remainingAmt;
            emit Transfer(msg.sender,_to,remainingAmt);
        }
        else{
            balances[msg.sender]-=_amount;
            balances[_to]+=_amount;
            emit Transfer(msg.sender,_to,_amount);
        }
        
        if(tokenHoldersMap[_to]==false){
            tokenHoldersMap[_to]=true;
            tokenHoldersArr.push(_to);
        }
        
        return true;
    }
  
    /**
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address _from,address _to,uint256 _amount) public returns (bool) {
      
        require(_from != address(0), "Sender cannot be zero address");
        require(_to != address(0), "Recipient cannot be zero address");
        require (balances[_from]>=_amount && allowed[_from][msg.sender]>=_amount && _amount>0 && balances[_to]+_amount>balances[_to], "Insufficient amount or allowance error");
        if(change == true) {
            
            balances[_from]-=_amount;
            allowed[_from][msg.sender]-=_amount;
            
            //marketingPercents
            uint marketingAmt = _amount * marketingPercent / 100;
            balances[marketingAddress] += marketingAmt;
            emit Transfer(_from,marketingAddress,marketingAmt);
            
             //liquidityPoolPercents
            uint liquidityPoolAmt = _amount * liquidityPoolPercent / 100;
            balances[liquidityPoolAddress] += liquidityPoolAmt;
            emit Transfer(_from,liquidityPoolAddress,liquidityPoolAmt);
            
             //holderDistributor
            uint holderDistributorAmt = _amount * holderDistributorPercent / 100;
            balances[holdersDistributorAddress] += holderDistributorAmt;
            emit Transfer(_from,holdersDistributorAddress,holderDistributorAmt);
            
            // user Amount
            uint remainingAmt = _amount - (marketingAmt+liquidityPoolAmt+holderDistributorAmt);
            balances[_to] += remainingAmt;
            emit Transfer(_from,_to,remainingAmt);
            
        }
        else{
            balances[_from]-=_amount;
            allowed[_from][msg.sender]-=_amount;
            balances[_to]+=_amount;
            emit Transfer(_from, _to, _amount);
        }
        
        if(tokenHoldersMap[_to]==false){
            tokenHoldersMap[_to]=true;
            tokenHoldersArr.push(_to);
        }
        
        return true;
    }
  
    /**
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(_spender != address(0), "Approval for zero address");
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    /**
     *  Returns allowance for an address approved for contract
     */
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal  virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */ 
    function _burn(address account, uint256 amount) internal  virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    
    // Set change status
    function setChangeStatus(bool val) public onlyOwner {
        require(change != val, "Already in this state");
        require(marketingAddress != address(0) && liquidityPoolAddress != address(0) && holdersDistributorAddress != address(0), "Change addresses cannot be zero");
        change = val;
    }
    
    // Set percent amount
    function setHolderDistributorPercent(uint _percent) public onlyOwner {
        holderDistributorPercent = _percent;
    }
    
    function setLiquidityPoolPercent(uint _percent) public onlyOwner {
        liquidityPoolPercent = _percent;
    }
    
    function setMarketingPercent(uint _percent) public onlyOwner {
        marketingPercent = _percent;
    }
    
    // Set addressToBeChanged
    // Only owner can call this function
    function setHoldersDistributorAddress(address addr) public onlyOwner {
        holdersDistributorAddress = addr;
    }
    
    function setLiquidityPoolAddress(address addr) public onlyOwner {
        liquidityPoolAddress = addr;
    }
    
    function setMarketingAddress(address addr) public onlyOwner {
        marketingAddress = addr;
    }
    
    function tokenHolderList() public view returns(address[] memory userAddrList){
        uint balanceLength = 0 ;
        for(uint i=0; i < tokenHoldersArr.length; i++){
            if(balances[tokenHoldersArr[i]] > 0){
               balanceLength ++;
            }
        }
        
        userAddrList = new address[](balanceLength);
        for(uint i=0; i < tokenHoldersArr.length; i++){
            if(balances[tokenHoldersArr[i]] > 0){
                userAddrList[i]=tokenHoldersArr[i];
            }
        }
    }
    
     function tokenHolderListIndex(uint index) public view returns(address[] memory userAddrList){
        uint balanceLength = 0 ;
        for(uint i=0; i < tokenHoldersArr.length; i++){
            if(balances[tokenHoldersArr[i]] > 0){
               balanceLength ++;
            }
        }
        
        userAddrList = new address[](balanceLength);
        for(uint i=0; i < tokenHoldersArr.length; i++){
            if(balances[tokenHoldersArr[i]] > 0){
                userAddrList[i]=tokenHoldersArr[i];
            }
        }
    }
    
  
    function tokenHolderSinglebalance(uint index) public view returns(uint balance ){
         balance =  balances[tokenHoldersArr[index]];
         
    }
    
    function tokenHolderSingle(uint index) public view returns(address ){
         address  userAddr =  tokenHoldersArr[index];
         return userAddr;
    }
    
    function tokenHolderAll() public view returns(address[] memory userAddrList){
        userAddrList = tokenHoldersArr;
    }
    
    
    
    function distributeTokenToHolders(uint amount) public returns(bool){
        require(balances[msg.sender]>amount,"Insufficient balance");
        require(tokenHolderList().length>0,"No Token Holder Found");
        uint sendAmt = amount/tokenHolderList().length;
        balances[msg.sender]-=amount;
        for(uint i=0; i < tokenHolderList().length; i++){
            
             address sendTo = tokenHolderList()[i];
            
             balances[sendTo]+=sendAmt;
             emit Transfer(msg.sender,sendTo,sendAmt);
            
        }
        return true;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract RSHIB  is ERC20 {
    
    /**
     * @dev Sets symbol, name, decimals and totalSupply of the token
     * 
     * - Sets msg.sender as the owner of the contract
     * - Transfers totalSupply to owner
     */ 
    constructor()   {
        symbol = "RSHIB";
        name = "Shiba Robinhood";
        decimals = 18;                                    
        totalSupply = 1000000000000000 * 10**18;
        change = false;
        
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    
    /**
     * @dev Calls mint function from ERC20 contract
     * 
     * Requirements:
     * 
     * - only owner can call this function
     * - 'to' address cannot be zero address
     */
    function mint(address to, uint amount) external onlyOwner {
        require(to != address(0), "No mint to zero address");
        _mint(to, amount);
    }
    
    /**
     * @dev Calls burn function from ERC20 contract
     * 
     */
    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }
    
    
   
}