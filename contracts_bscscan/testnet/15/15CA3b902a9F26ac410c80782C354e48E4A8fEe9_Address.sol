/**
 *Submitted for verification at BscScan.com on 2021-12-25
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.2; 




library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}


library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        uint256 size;
        
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

   
contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()  {
        owner = payable(msg.sender);
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


}


 

    
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//
    
contract PlugToken is owned {
    


    // Public variables of the token
    using SafeMath for uint256;
    string constant private _name = "Plug Token";
    string constant private _symbol = "Plug";
    uint256 constant private _decimals = 18;
    uint256 private _totalSupply;         //800 million tokens
    uint256 constant public maxSupply = 50 * 10**9 * 10**uint256(_decimals);   //50 billion tokens
    uint256 constant public PERCENTS_DIVIDER = 10000;
    uint256 public _burnFee= 50;  //0.5 
    uint256 public _adminFee=50;  //0.5

    bool public safeguard;  //putting safeguard on will halt all non-owner functions


    // ----------------------------------------IDO GLOBAL DATA STORAGE ------------------------------------------
  
    // Public variables for IDO
    
   	uint256 public exchangeRate = 1500000;         // exchange rate  1 BNB = 1500000 tokens 
   	uint256 public idoBNBReceived;                  // how many BNB Received through IDO
   	uint256 public totalTokenSold;                  // how many tokens sold
	uint256 public minimumContribution = 10**16;    // Minimum amount to invest - 0.01 BNB (in 18 decimal format)
    
    uint256 public maximumTokenHold = 3* 10**6* 10**18;   // Maximum amount a wallet can hold 3 million for testing only
    //uint256 public maximumTokenHold = 10* 10**6* 10**18;  // for live this is max limit
    bool    public idoClosed;
    uint256 public idoAllotToken      = 15 * 10**9 * 10**18; // 15 billion for IDO
    address public _defiPlug_contract;
    address public tokenAddress ;
    
    // holders & its fee

    struct idoHolderInfo{
        bool joined;
        uint lastReceivedFee;
    }
    struct tokenHolderInfo{
        bool joined;
        uint lastReceivedFee;
    }
    mapping (address=>tokenHolderInfo) public tokenHolder;
    mapping(address=> idoHolderInfo) public idoHolder;

    uint public idoTaxFee=60; //1%;
    uint public taxFee = 40;//0.4

    uint public totalCollectedIDOFee;
    uint public totalHolderCollectedFee;

    uint public totalTokenHolder;
    uint public totalIdoHolder;

    uint public totalrefCount;
    uint public totalrefDistribution;



//------------------------------------------END---------------------------------------------------------


    // -------------------------TokenHolderAddresses-------------------
    address public  _devMarketingWallet=0x2f054d1a1C3fC2760cc08D4cb4f31873E9AFB201;
    address public  _lpWallet=0x5E8Bc8ECbc418Df7062ADf654127cE145bF2A6B3;
    address public  _teamWallet=0x999865d9Aa12a02042C3C53DE8cBf2a0BbB5261C;
    address public  _charityWallet=0x824B4ba2905E01E0e4A357042Ba06906Fd9e13A1;
    address public  _lockedWallet = 0x0d0c535c047c750c001F3A80309d0932F9991eA0;
    //--------------------------------------------------------------------
    
  
    
    uint256 public  _bountyBonusAllot = 10 * 10**9 * 10**18;   //  10 billion
    uint256 public  _totalBountyDistributed;                 // no of distribute token
    uint256 public  _lpAllot         = 10 * 10**9 * 10**18;  //  10 billion
    uint256 public  _devMarketingAllot = 5 *  10**9 * 10**18;   // 5 billion
    uint256 public  _teamAllot            = 25 * 10**8 * 10**18; //  2.5 billion
    uint256 public  _charityAllot         = 25 * 10**8 * 10**18; //  2.5 billion
    uint256 public  _lockedTokenAllot     = 5 *  10**9 * 10**18;   // 5 billion
    uint256 public  _lockedPeriod;
    bool    public  _lockedTokenClaimed;  
    



    // This creates a mapping with all data storage
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    mapping (address => bool) public frozenAccount;





    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
        
    // This generates a public event for frozen (blacklisting) accounts
    event FrozenAccounts(address target, bool frozen);
    
    // This will log approval of token Transfer
    event Approval(address indexed from, address indexed spender, uint256 value);



    /*======================================
    =       STANDARD ERC20 FUNCTIONS       =
    ======================================*/
    
    /**
     * Returns name of token 
     */
    function name() external pure returns(string memory){
        return _name;
    }
    
    /**
     * Returns symbol of token 
     */
    function symbol() external pure returns(string memory){
        return _symbol;
    }
    
    /**
     * Returns decimals of token 
     */
    function decimals() external pure returns(uint256){
        return _decimals;
    }
    
    /**
     * Returns totalSupply of token.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * Returns balance of token 
     */
    function balanceOf(address user) external view returns(uint256){
        return _balanceOf[user];
    }
    
    /**
     * Returns allowance of token 
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowance[owner][spender];
    }
    
    /**
     * Internal transfer, only can be called by this contract 
     */
    function _transfer(address _from, address _to, uint _value) internal {
        
        //checking conditions
        require(!safeguard);
        require (_to != address(0));                      // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        
        // overflow and undeflow checked by SafeMath Library
        _balanceOf[_from] = _balanceOf[_from].sub(_value);    // Subtract from the sender
        

        if(idoClosed==true){

            // system tax deduction

            // burn
            uint256  burnFee = _value.mul(_burnFee).div(PERCENTS_DIVIDER);
            _burn(burnFee);
            
            //_adminFee
            uint256 adminFee = _value.mul(_adminFee).div(PERCENTS_DIVIDER);
            
            _balanceOf[_devMarketingWallet]=_balanceOf[_devMarketingWallet].add(adminFee);    
            
            // holder tax deduction
             uint256  holderFee = _value.mul(taxFee).div(PERCENTS_DIVIDER);            

            // ido tax deduction
            uint256  idoFee = _value.mul(idoTaxFee).div(PERCENTS_DIVIDER);   

            _value=_value.sub(burnFee.add(adminFee).add(holderFee).add(idoFee));

            // add fee to pool
            totalHolderCollectedFee= totalHolderCollectedFee.add(holderFee);
            totalCollectedIDOFee= totalCollectedIDOFee.add(idoFee);

        }

        _balanceOf[_to] = _balanceOf[_to].add(_value);        // Add the same to the recipient
        
        // discountinue holder if he has not sufficient staking 

        if (_balanceOf[_from]<1000000*10**uint256(_decimals)){

            if(totalTokenHolder!=0 && tokenHolder[_from].joined==true){
                totalTokenHolder--;
                tokenHolder[_from].joined=false;
                if(totalIdoHolder!=0 && idoHolder[_from].joined==true){
                    totalIdoHolder--;
                    idoHolder[_from].joined=false;
                }
            }
        }else if (_balanceOf[_from]>=1000000*10**uint256(_decimals) && _balanceOf[_from]<1500000*10**uint256(_decimals)){
                if(totalIdoHolder!=0 && idoHolder[_from].joined==true){
                    totalIdoHolder--;
                    idoHolder[_from].joined=false;
                }

                if(tokenHolder[_from].joined==false){
                    totalTokenHolder++;
                    tokenHolder[_from].joined=true;
                }
        }else{

                if(tokenHolder[_from].joined==false){
                    totalTokenHolder++;
                    tokenHolder[_from].joined=true;
                }
        }        

    // for recipient

        if (_balanceOf[_to]<1000000*10**uint256(_decimals)){

            if(totalTokenHolder!=0 && tokenHolder[_to].joined==true){
                totalTokenHolder--;
                tokenHolder[_to].joined=false;
                if(totalIdoHolder!=0 && idoHolder[_to].joined==true){
                    totalIdoHolder--;
                    idoHolder[_to].joined=false;
                }
            }
        }else if (_balanceOf[_to]>=1000000*10**uint256(_decimals) && _balanceOf[_to]<1500000*10**uint256(_decimals)){
                if(totalIdoHolder!=0 && idoHolder[_to].joined==true){
                    totalIdoHolder--;
                    idoHolder[_to].joined=false;
                }

                if(tokenHolder[_to].joined==false){
                    totalTokenHolder++;
                    tokenHolder[_to].joined=true;
                }
        }else{

                if(tokenHolder[_to].joined==false){
                    totalTokenHolder++;
                    tokenHolder[_to].joined=true;
                }
        }  
        // emit Transfer event
        emit Transfer(_from, _to, _value);
    }

    /**
        * Transfer tokens
        *
        * Send `_value` tokens to `_to` from your account
        *
        * @param _to The address of the recipient
        * @param _value the amount to send
        */
    function transfer(address _to, uint256 _value) external returns (bool success) {
        //no need to check for input validations, as that is ruled by SafeMath
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        * Transfer tokens from other address
        *
        * Send `_value` tokens to `_to` in behalf of `_from`
        *
        * @param _from The address of the sender
        * @param _to The address of the recipient
        * @param _value the amount to send
        */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        //checking of allowance and token value is done by SafeMath
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
        * Set allowance for other address
        *
        * Allows `_spender` to spend no more than `_value` tokens in your behalf
        *
        * @param _spender The address authorized to spend
        * @param _value the max amount they can spend
        */
    function approve(address _spender, uint256 _value) external returns (bool success) {
        require(!safeguard);
        /* AUDITOR NOTE:
            Many dex and dapps pre-approve large amount of tokens to save gas for subsequent transaction. This is good use case.
            On flip-side, some malicious dapp, may pre-approve large amount and then drain all token balance from user.
            So following condition is kept in commented. It can be be kept that way or not based on client's consent.
        */
        //require(_balanceOf[msg.sender] >= _value, "Balance does not have enough tokens");
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to increase the allowance by.
     */
    function increase_allowance(address spender, uint256 value) external returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].add(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to decrease the allowance by.
     */
    function decrease_allowance(address spender, uint256 value) external returns (bool) {
        require(spender != address(0));
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].sub(value);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }


    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/
    
    constructor() {
        //sending  the tokens to lpwallet
        mintToken(_lpWallet,_lpAllot);
        //sending the token to devMarketing
        mintToken(_devMarketingWallet,_devMarketingAllot);
        // sending the token to teamwallet
        mintToken(_teamWallet,_teamAllot);
        // sending the token to charity wallet 
        mintToken(_charityWallet,_charityAllot);
        
        _lockedPeriod= block.timestamp+157784760; // 5 years
        
    }
    
    
    receive () external payable {
      
    }

    /**
        * Destroy tokens
        *
        * Remove `_value` tokens from the system irreversibly
        *
        * @param _value the amount of money to burn
        */
    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);
        //checking of enough token balance is done by SafeMath
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);  // Subtract from the sender
        _totalSupply = _totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    function _burn(uint256 _value) internal returns (bool success) {
        require(!safeguard);
        //checking of enough token balance is done by SafeMath
        _balanceOf[address(0)] = _balanceOf[address(0)].add(_value);  // Subtract from the sender
        _totalSupply = _totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    /**
        * Destroy tokens from other account
        *
        * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
        *
        * @param _from the address of the sender
        * @param _value the amount of money to burn
        */
    function burnFrom(address _from, uint256 _value) external returns (bool success) {
        require(!safeguard);
        //checking of allowance and token value is done by SafeMath
        _balanceOf[_from] = _balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value); // Subtract from the sender's allowance
        _totalSupply = _totalSupply.sub(_value);                                   // Update totalSupply
        emit  Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }
        
    
    /** 
        * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
        * @param target Address to be frozen
        * @param freeze either to freeze it or not
        */
    function freezeAccount(address target, bool freeze) onlyOwner external {
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }
    
    /** 
        * @notice Create `mintedAmount` tokens and send it to `target`
        * @param target Address to receive the tokens
        * @param mintedAmount the amount of tokens it will receive
        */
    function mintToken(address target, uint256 mintedAmount) internal  {
        require(_totalSupply.add(mintedAmount) <= maxSupply, "Cannot Mint more than maximum supply");
        _balanceOf[target] = _balanceOf[target].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
    }

        
    function mint(address _receiver, uint256 _amount) external  onlyMinter {
   
        if (_totalBountyDistributed >= _bountyBonusAllot) {
        return;
        }
        mintToken(_receiver, _amount);
        _totalBountyDistributed+=_amount;
    }
    
    //Just in rare case, owner wants to transfer Ether from contract to owner address

    
    /**
        * Change safeguard status on or off
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working back again!
        */
    function changeSafeguardStatus() onlyOwner external{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }
    

    
    /*************************************/
    /*    Section for IDO      */
    /*************************************/
    

    function openLockedToken() public onlyOwner returns(bool){
        
        require(_lockedTokenClaimed==false,"Token already Claimed");
        require(_lockedPeriod<=block.timestamp,"Please wait until locked period over");
        // _mint(msg.sender,_lockedTokenAllot);
        mintToken(_lockedWallet,_lockedTokenAllot);
        _lockedTokenClaimed=true;
        return true;
    }

    event buyTokenEvent (address sender,uint amount, uint tokenPaid);
    event refTokenBonusEvent (address referral, uint tokenPaid);
    function buyToken(address ref) payable public returns(uint)
    {
		
		//checking conditions
		require(idoClosed==false,"IDO is Closed Now.");
       
        require(msg.value >= minimumContribution, "less then minimum contribution");
       
        
        
        //calculating tokens to issue
        uint256 tokenTotal = msg.value * exchangeRate;
        require(totalTokenSold.add(tokenTotal)<=idoAllotToken,"all tokens already sold");
        require(_balanceOf[msg.sender].add(tokenTotal)<=maximumTokenHold,"wallet reach maximum holdings");
        //updating state variables
        idoBNBReceived += msg.value;
        totalTokenSold += tokenTotal;

        if (ref!=address(0)){

            totalrefCount++;
            uint refBonus = tokenTotal*10/100; // 10% of user purchase 
            mintToken(ref,refBonus);
            totalrefDistribution+=refBonus;
           emit  refTokenBonusEvent(ref,refBonus);
        }

        //sending tokens. This contract must hold enough tokens.

        mintToken(msg.sender,tokenTotal);
        
        if(idoHolder[msg.sender].joined==false){
            if(_balanceOf[msg.sender]>=1500000*10**uint256(_decimals)){
                idoHolder[msg.sender].joined=true;
                totalIdoHolder++;
            }
            
        }

        if(tokenHolder[msg.sender].joined==false){

            if(_balanceOf[msg.sender]>=1000000*10**uint256(_decimals)){
                tokenHolder[msg.sender].joined=true;
                totalTokenHolder++;
            }

        }
        
        //send ether to owner
        forwardBNBToOwner();
        
        //logging event
        emit buyTokenEvent(msg.sender,msg.value, tokenTotal);
        
        return tokenTotal;

    }


	//Automatocally forwards ether from smart contract to owner address
	function forwardBNBToOwner() internal {
		payable(owner).transfer(msg.value); 
	}
	
	
	// exchange rate => 1 BNB = how many tokens
    function setExchangeRate(uint256 _exchangeRatePercent) onlyOwner public returns (bool)
    {
        exchangeRate = _exchangeRatePercent;
        return true;
    }

    function setIdoClosed() onlyOwner public returns (bool)
    {
        idoClosed = true;

        return true;
    }

    function setMinimumContribution(uint256 _minimumContribution) onlyOwner public returns (bool)
    {
        minimumContribution = _minimumContribution;
        return true;
    }
    
    
    function setMaximumContribution(uint256 _maximumContribution) onlyOwner public returns (bool)
    {
        maximumTokenHold = _maximumContribution;
        return true;
    }
    
	function transferAllTokensToBounty() public onlyOwner returns(string memory){
        // no need for overflow checking as that will be done in transfer function
        require(idoClosed==true,"ido is running");
        require(totalTokenSold<idoAllotToken,"token sold");
        uint256 remainToken = idoAllotToken.sub(totalTokenSold);
        // _mint(msg.sender,tokenAmount);
        //mintToken(owner,tokenAmount);
        _bountyBonusAllot = _bountyBonusAllot.add(remainToken);
        return "Tokens withdrawn to Bounty wallet";
    }

    function manualWithdrawBNB() public onlyOwner returns(string memory){
        payable(owner).transfer(address(this).balance);
        return "BNB withdrawn to owner wallet";
    }

    function getTokenReward(address _wallet) public view returns(uint rewards){
    
        if(totalTokenHolder>0 && tokenHolder[_wallet].joined==true){

            uint reward = totalHolderCollectedFee.div(totalTokenHolder);

            if(tokenHolder[_wallet].lastReceivedFee<reward){

                return reward.sub(tokenHolder[_wallet].lastReceivedFee);
            }
            
        }

        return 0;
    
    }

    function getIdoReward(address _wallet) public view returns(uint rewards){
    
        if(totalIdoHolder>0 && idoHolder[_wallet].joined==true){

            uint reward = totalCollectedIDOFee.div(totalIdoHolder);

            if(idoHolder[_wallet].lastReceivedFee<reward){

                return reward.sub(idoHolder[_wallet].lastReceivedFee);
            }
            
        }

        return 0;
    
    }


     function claimTokenReward() public  returns(bool success){
    
         require(totalTokenHolder>0,"No Holder is eligible  for claim");
         require(tokenHolder[msg.sender].joined==true ,"You are not eligible for claim");
         require(totalHolderCollectedFee>0,"Fee pool is empty");
        if(totalTokenHolder>0 && tokenHolder[msg.sender].joined==true){

            uint reward = totalHolderCollectedFee.div(totalTokenHolder);

            if(tokenHolder[msg.sender].lastReceivedFee<reward){

                uint rewardFee= reward.sub(tokenHolder[msg.sender].lastReceivedFee);
                require(rewardFee>0,"you dont have sufficent balance ");
                _balanceOf[msg.sender]= _balanceOf[msg.sender].add(rewardFee);
                tokenHolder[msg.sender].lastReceivedFee=rewardFee;
                emit Transfer(address(0), msg.sender, rewardFee);
                return true;

            }
            
        }

        return false;
    
    }

    function claimIdoReward() public  returns(bool success){

        require(totalIdoHolder>0,"No Holder is eligible  for claim");
         require(idoHolder[msg.sender].joined==true ,"You are not eligible for claim");
         require(totalCollectedIDOFee>0,"Fee pool is empty");
    
        if(totalIdoHolder>0 && idoHolder[msg.sender].joined==true){

            uint reward = totalCollectedIDOFee.div(totalIdoHolder);

            if(idoHolder[msg.sender].lastReceivedFee<reward){

                uint rewardFee= reward.sub(idoHolder[msg.sender].lastReceivedFee);
                require(rewardFee>0,"you dont have sufficent balance ");
                _balanceOf[msg.sender]=_balanceOf[msg.sender].add(rewardFee);
                idoHolder[msg.sender].lastReceivedFee=rewardFee;
                 emit Transfer(address(0), msg.sender, rewardFee);
                return true;
            }
            
        }

        return false;
    
    }



    function addMinter(address _minter) public onlyOwner {
        require(_minter != address(0), "Minter already added");

        _defiPlug_contract=_minter;
    }

    modifier onlyMinter() {
        require(_defiPlug_contract == msg.sender && Address.isContract(msg.sender), "Caller could be only minter contract");
        _;
    }
    
    

}