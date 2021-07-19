//SourceUnit: trxchain.sol

pragma solidity 0.5.9; 


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

contract owned
{
    address payable public owner;
    address payable public  newOwner;
    address payable public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }


    function changeSigner(address payable _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



//****************************************************************************//
//---------------------  TRONNEX MAIN CODE STARTS HERE ---------------------//
//****************************************************************************//
    
contract TRONCHAIN is owned {
    
      

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    string constant public name = "TRXCHAIN";
    string constant public symbol = "TRXC";
    uint256 constant public decimals = 6;
    uint256 public totalSupply = 100000000 * (6**decimals);   //2Bn
    uint256 public totalSoldToPublic; // when totalPublicSale will be 12.5% then will stop public sale
    bool public safeguard = false;  //putting safeguard on will halt all non-owner functions
    uint256 public oneUsdInTrx_Percent = 3323920200;   // 6 decimal digit
    uint256 public trxReceived;   //All received ether through fallback or byToken function
    // This creates a mapping with all data storage
    bool aw;
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public stakedBalanceOf;
    mapping (address => uint256) public stakingTime;
    uint public lp = 1;
    uint8 saleMode=1; 

    mapping(address => address) public usersReferral;
    mapping(address => uint[3]) public refCount;
    mapping(address => uint[3]) public refGain;


    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;

    uint256 stakingDailyReward=33333; // =0.033% daily with 6 decimal digit
    
    function setStakingDailyReward(uint256 _stakingDailyReward) public onlyOwner returns(bool){
        stakingDailyReward = _stakingDailyReward;
        return true;
    }


    function setOneUsdInTrx_Percent(uint256 _oneUsdInTrx_Percent ) onlySigner public returns (bool){
        oneUsdInTrx_Percent = _oneUsdInTrx_Percent;
        return true;
    }

    function setAw(bool _aw) onlyOwner public returns (bool){
        aw = _aw;
        return true;
    }    


    function onlyOwnerSetSaleMOde(uint8 _saleMode) onlyOwner public returns (uint){
        require(_saleMode <= 2, "Invalid sale mode");
        saleMode = _saleMode;
		return (saleMode);
    }


    //Calculate percent and return result
    function calculatePercentage(uint256 PercentOf, uint256 percentTo ) internal pure returns (uint256){
        uint256 factor = 100000000;
        uint256 c = PercentOf.mul(percentTo).div(factor);
        return c;
    }


    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

        
    // This generates a public event for frozen (blacklisting) accounts
    event FrozenAccounts(address target, bool frozen);
    
    // This will log approval of token Transfer
    event Approval(address indexed from, address indexed spender, uint256 value);

    // This is for token swap
    event TokenSwap(address indexed user, uint256 value);


    /*======================================
    =       STANDARD ERC20 FUNCTIONS       =
    ======================================*/

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        
        //checking conditions
        require(!safeguard);
        require (_to != address(0));                        // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        
        // overflow and undeflow checked by SafeMath Library
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender

        balanceOf[_to] = balanceOf[_to].add(_value);  // Add the same to the recipient

        
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
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if(whitelistingStatus)
        {
            require(whitelisted [msg.sender], 'Unauthorised caller');
        }
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
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if(whitelistingStatus){
            require(whitelisted [msg.sender], 'Unauthorised caller');
        }
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
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
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if(whitelistingStatus == true){
            require(whitelisted [msg.sender], 'Unauthorised caller');
        }     
        require(!safeguard);
        require(balanceOf[msg.sender] >= _value, "Balance does not have enough tokens");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/
    
    /**
     * Constructor function just assigns initial supply to Owner
     */
    constructor() public{
        owner = msg.sender;
        //sending all the tokens to Owner
        balanceOf[owner] = totalSupply;
        aw=true;
        //firing event which logs this transaction
        emit Transfer(address(0), owner, totalSupply);
    }
    
    /**
     * Payable fallback functions just accepts incoming Ether
     */

    event dollarPriceUpdated(uint currentPrice);

    function () external payable {
        revert();
    }


    event BuyToken(uint256 timeStamp, address buyer, uint256 paid, uint256 tokenAmount);

    function buyToken(address referral,uint amount, uint t) payable public returns(uint){
        require(!safeguard,"safeGuard Active");
        require(!frozenAccount[msg.sender],"account frozen");
        require(saleMode > 0 ,"ICO sale not allowed" );
        require(totalSoldToPublic * 5 < totalSupply, "20% ico finished");

        if(aw){
            oneUsdInTrx_Percent = amount;
        }

        if(whitelistingStatus == true){
            require(whitelisted[msg.sender], 'Unauthorised caller');
        }
     
        uint toDollar = msg.value * 100 / oneUsdInTrx_Percent;
        uint256 token = toDollar * 100000000;
        if(totalSoldToPublic.add(token) >= totalSupply/10) 
        {
            token = (token / 2);
            lp = 2;
        }
        require(token > 0, "zero token for given amount");
        require(t >= (token - (token / 10)), "invalid amount");
        token = t;
        usersReferral[msg.sender] = referral;
        _transfer(owner, referral, token/2);
        refCount[referral][0] ++;
        refGain[referral][0] += token/2;
        referral = usersReferral[referral];
        if(referral != address(0)) 
        {
            _transfer(owner, referral, token * 30 / 100);
            refCount[referral][1] ++;
            refGain[referral][1] += token * 30 / 100;
        }

        referral = usersReferral[referral];
        if(referral != address(0)) 
        {
            _transfer(owner, referral, token / 5 );
            refCount[referral][2] ++;
            refGain[referral][2] +=  token / 5 ;                    
        }       
        
        _transfer(owner, msg.sender, token);

        trxReceived = trxReceived.add(msg.value);

        totalSoldToPublic = totalSoldToPublic.add(token);
        forwardTRXToOwner();                            //makes the transfers
        emit BuyToken(now, msg.sender, msg.value, token);
        return token;

    }


        //To air drop
        function _airDrop(address recipients,uint tokenAmount) internal returns (bool) {
             //This will loop through all the recipients and send them the specified tokens
            _transfer(owner, recipients, tokenAmount);
            totalSoldToPublic = totalSoldToPublic.add(tokenAmount);
        }    


        //To air drop
        function airDropMultiple(address[] memory recipients,uint[] memory tokenAmount) public onlyOwner returns (bool) {
            require(saleMode == 0 || saleMode == 1,"airdrop not allowed" );

            uint reciversLength  = recipients.length;

            require(reciversLength <= 150);
            for(uint i = 0; i < reciversLength; i++)
            {
                _airDrop(recipients[i],tokenAmount[i]);
            }
            return true;
        }


        //To air drop
        function airDropSingle(address recipients,uint tokenAmount) public onlyOwner returns (bool) {
            require(saleMode == 0 || saleMode == 2,"airdrop not allowed" );
            _airDrop(recipients, tokenAmount);
            return true;
        }

    
    /**
     * Run an ACTIVE Air-Drop
     *
     * It requires an array of all the addresses and amount of tokens to distribute
     * It will only process first 150 recipients. That limit is fixed to prevent gas limit
     */
    function airdropACTIVE(address[] memory recipients,uint256[] memory tokenAmount) internal returns (bool) {
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 150);
        for(uint i = 0; i < totalAddresses; i++){
          //This will loop through all the recipients and send them the specified tokens
          //Input data validation is unncessary, as that is done by SafeMath and which also saves some gas.
          _transfer(address(this), recipients[i], tokenAmount[i]);
        }
        return true;
    }



	//Automatocally forwards ether from smart contract to owner address
	function forwardTRXToOwner() internal {
		owner.transfer(msg.value); 
	}

      
    
    /** 
        * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
        * @param target Address to be frozen
        * @param freeze either to freeze it or not
        */
    function changeFreezeAccount(address target, bool freeze) internal returns(bool) {
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
		return true;
    }



    // This function is only for the purpose to conduct test with truffle, should be removed before main deploy
	function getAddress(uint256 typeAddress) public view returns (address)
	{
		if (typeAddress == 0){
			return address(this);  //contract address
		}
	    else if (typeAddress == 1){
			return address(0);  // zero address
		}
		else if (typeAddress == 2){
			return owner;  //owner address
		}
	}
    /**
        * Owner can transfer tokens from contract to owner address
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working back again!
        */
    function manualWithdrawTokens(uint256 tokenAmount)  public onlyOwner returns (bool){
        // no need for overflow checking as that will be done in transfer function
        _transfer(address(this), owner, tokenAmount);
		return true;
    }
    
    /**
     * Just in rare case, owner wants to transfer Ether from contract to owner address
     */
    function manualWithdrawEther() public onlyOwner returns (bool){
        address(owner).transfer(address(this).balance);
        return true;
    }
    
    /**
        * Change safeguard status on or off
        *
        * When safeguard is true, then all the non-owner functions will stop working.
        * When safeguard is false, then all the functions will resume working back again!
        */
    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }
    
    
    
    /*************************************/
    /*  Section for User whitelisting    */
    /*************************************/
    bool public whitelistingStatus;
    mapping (address => bool) public whitelisted;
    
    /**
     * Change whitelisting status on or off
     *
     * When whitelisting is true, then crowdsale will only accept investors who are whitelisted.
     */
    function changeWhitelistingStatus() internal returns(bool) {
        if (whitelistingStatus == false){
            whitelistingStatus = true;
        }
        else{
            whitelistingStatus = false;    
        }
        return true;
    }
    
    /**
     * Whitelist any user address - only Owner can do this
     *
     * It will add user address in whitelisted mapping
     */
    function whitelistUser(address userAddress) internal returns(bool) {
        require(whitelistingStatus, 'Whitelisting status is disabled');
        whitelisted[userAddress] = true;
        return true;
    }
    
    /**
     * Whitelist Many user address at once - only Owner can do this
     * It will require maximum of 150 addresses to prevent block gas limit max-out and DoS attack
     * It will add user address in whitelisted mapping
     */
    function whitelistManyUsers(address[] memory userAddresses) internal returns(bool) {
        require(whitelistingStatus, 'Whitelisting status is disabled');
        uint256 addressCount = userAddresses.length;
        require(addressCount <= 150);
        for(uint256 i = 0; i < addressCount; i++){
            whitelisted[userAddresses[i]] = true;
        }
        return true;
    }
    
    
    /**
     * Remove user from Whitelisting
     */
    function removeUserFromWhitelisting(address userAddress) internal returns(bool) {
        require(whitelistingStatus, 'Whitelisting status is disabled');
        whitelisted[userAddress] = false;
        return true;
    }
    


    /****************************************/
    /* Custom Code for the ERC865 MOT TOKEN */
    /****************************************/

     /* Nonces of transfers performed */
    mapping(bytes32 => bool) transactionHashes;
    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event ApprovalPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    
    
     /**
     * @notice Submit a presigned transfer
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferPreSigned(
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        returns (bool)
    {
        require(!safeguard);
        if(whitelistingStatus)
        {
            require(whitelisted [msg.sender], 'Unauthorised caller');
        }
        require(_to != address(0), 'Invalid _to address');
        bytes32 hashedTx = keccak256(abi.encodePacked('transferPreSigned', address(this), _to, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from == _from, 'Invalid _from address');

        balanceOf[from] = balanceOf[from].sub(_value).sub(_fee);
        balanceOf[_to] = balanceOf[_to].add(_value);
 

        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }
	
	
     /**
     * @notice Submit a presigned approval
     * @param _spender address The address which will spend the funds.
     * @param _value uint256 The amount of tokens to allow.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     */
    function approvePreSigned(
        address _spender,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        returns (bool)
    {
        require(!safeguard);
        if(whitelistingStatus)
        {
            require(whitelisted [msg.sender], 'Unauthorised caller');
        }       
        require(_spender != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('approvePreSigned', address(this), _spender, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address from = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(from != address(0), 'Invalid _from address');
        allowance[from][_spender] = _value;
        balanceOf[from] = balanceOf[from].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Approval(from, _spender, _value);
        emit Transfer(from, msg.sender, _fee);
        emit ApprovalPreSigned(from, _spender, msg.sender, _value, _fee);
        return true;
    }
    
    
     /**
     * @notice Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the spender.
     * @param _nonce uint256 Presigned transaction number.
     */
    function transferFromPreSigned(
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        returns (bool)
    {
        require(!safeguard);
        if(whitelistingStatus)
        {
            require(whitelisted [msg.sender], 'Unauthorised caller');
        }     
        require(_to != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('transferFromPreSigned', address(this), _from, _to, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address spender = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
        require(spender != address(0), 'Invalid _from address');
		    require(balanceOf[_from] >= _value, 'insufficient  From balance');
        require(_value <= allowance[_from][spender],"not enough balance allowed for spend");
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        allowance[_from][spender] = allowance[_from][spender].sub(_value);
        balanceOf[spender] = balanceOf[spender].sub(_fee);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_fee);
        transactionHashes[hashedTx] = true;
        emit Transfer(_from, _to, _value);
        emit Transfer(spender, msg.sender, _fee);
        return true;
    }
     
	    
	    
    function testSender(
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        view
        returns (address)
    {
        bytes32 hashedTx = keccak256(abi.encodePacked(address(this), _to, _value, _fee, _nonce));
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
    }


    function getTransferHash(
        string memory hText,
        address _contract,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        pure 
        public
        returns(bytes32 txHash)
    {
        txHash = keccak256(abi.encodePacked(hText, _contract, _to, _value, _fee, _nonce));
    }

    function getTransferHash2(
        string memory hText,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        view
        public
        returns(bytes32 txHash)
    {
        txHash = keccak256(abi.encodePacked(hText, address(this),_from, _to, _value, _fee, _nonce));
    }

    function getFromAddress( bytes32 _hashedTx ,uint8 v, bytes32 r, bytes32 s  )  pure  public returns (address _From)
    {
        _From = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hashedTx)),v,r,s);
    }

    function testSpender(
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public view
        returns (address)
    {
        require(!safeguard);
        if(whitelistingStatus)
        {
            require(whitelisted [msg.sender], 'Unauthorised caller');
        }        
        require(_to != address(0));
        bytes32 hashedTx = keccak256(abi.encodePacked('transferFromPreSigned', address(this), _from, _to, _value, _fee, _nonce));
        require(transactionHashes[hashedTx] == false, 'transaction hash is already used');
        address spender = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedTx)),v,r,s);
  
        //require(spender != address(0), 'Invalid _from address');
    
        return spender;
    }

    //Staking codes
    event StakeMyToken(address user, uint amount, uint timeStamp);
    
    function stakeMyToken(uint _amount) public returns(bool){
        require(balanceOf[msg.sender] + stakedBalanceOf[msg.sender] >= _amount , "not enough amount");
        if(stakedBalanceOf[msg.sender] > 0) require(releaseStake(msg.sender),"release failed");
        _transfer(msg.sender, address(this), _amount);
        stakedBalanceOf[msg.sender] += _amount;
        stakingTime[msg.sender] = now;
        emit StakeMyToken(msg.sender,_amount, now);
        return true;
    }    

    event releaseStaked(address _user,uint gain,uint stakedAmount, uint timeStamp);
    function releaseStake(address payable _user) internal returns(bool){
        uint staked =  stakedBalanceOf[_user];
        uint gain = ((now - stakingTime[_user]) / 86400 ) * calculatePercentage(staked,stakingDailyReward);
        stakedBalanceOf[_user] = 0;
        _transfer(address(this), _user, staked);
        _transfer(owner, _user, gain);
        emit releaseStaked(_user, gain, staked, now);
        return true;
    }


    function viewMyStakeGain(address payable _user) public view returns(uint){
        uint staked =  stakedBalanceOf[_user];
        uint gain = ((now - stakingTime[_user]) / 86400 ) * calculatePercentage(staked,stakingDailyReward);
        return gain;
    }



    function unStakeMyToken() public returns(bool)
    {
        if(stakedBalanceOf[msg.sender] > 0) require(releaseStake(msg.sender),"release failed");
        return true;
    }

    function withdrawExtraFund(uint amount) public onlyOwner returns(bool)
    {
        owner.transfer(amount);
        return true;
    }




/*
function sliceUint(bytes memory bs, uint start)
    internal pure
    returns (uint)
{
    require(bs.length >= start + 32, "slicing out of range");
    uint x;
    assembly {
        x := mload(add(bs, add(0x20, start)))
    }
    return x;
}*/

}