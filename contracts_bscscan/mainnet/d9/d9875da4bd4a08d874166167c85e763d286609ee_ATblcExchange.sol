/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;
/*


████████╗██████╗░██╗░░░░░░█████╗░      ███████╗██╗░░██╗░█████╗░██╗░░██╗░█████╗░███╗░░██╗░██████╗░███████╗
╚══██╔══╝██╔══██╗██║░░░░░██╔══██╗      ██╔════╝╚██╗██╔╝██╔══██╗██║░░██║██╔══██╗████╗░██║██╔════╝░██╔════╝
░░░██║░░░██████╦╝██║░░░░░██║░░╚═╝      █████╗░░░╚███╔╝░██║░░╚═╝███████║███████║██╔██╗██║██║░░██╗░█████╗░░
░░░██║░░░██╔══██╗██║░░░░░██║░░██╗      ██╔══╝░░░██╔██╗░██║░░██╗██╔══██║██╔══██║██║╚████║██║░░╚██╗██╔══╝░░
░░░██║░░░██████╦╝███████╗╚█████╔╝      ███████╗██╔╝╚██╗╚█████╔╝██║░░██║██║░░██║██║░╚███║╚██████╔╝███████╗
░░░╚═╝░░░╚═════╝░╚══════╝░╚════╝░      ╚══════╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝░╚═════╝░╚══════╝
*/

contract ATblcExchange {
      modifier onlyTblcAdmin(){
        address tblcHolderAddress = msg.sender;
        require(administrators[tblcHolderAddress]);
        _;
    }
    modifier onlyTblcHolders() {
        require(myTokens() > 0);
        _;
    }
    modifier onlyPrelaunchContract(){
        address preLaunchSwapAddress = msg.sender;
        require(msg.sender==address(0x4F692058946AB3eDF645088955d7CFb1Fc78130c));
        _;
    }
    
  
    /*==============================
    =            EVENTS            =
    ==============================*/
    event Approval(
        address indexed tokenOwner, 
        address indexed spender,
        uint tokens
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    event Withdraw(
        address indexed customerAddress,
        uint256 bnbWithdrawn
    );
    event RewardWithdraw(
        address indexed customerAddress,
        uint256 tokens
    );
    event Buy(
        address indexed buyer,
        uint256 tokensBought
    );
    event Sell(
        address indexed seller,
        uint256 tokensSold
    );
    event Stake(
        address indexed staker,
        uint256 tokenStaked
    );
    event Unstake(
        address indexed staker,
        uint256 tokenRestored
    );

       
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public  name = "Tblc Exchange";
    string public symbol = "TBLC";
    uint8 public decimals = 5;
    uint256 public totalSupply_ = 310000000000;
    uint256 constant internal STARTING_TBLC_PRICE = 2500000000;
    uint256 constant internal TOKEN_PRICE_INCREMENTAL = 1;
    uint256 internal buyPercent = 1000; //comes multiplied by 1000 from outside
    uint256 internal sellPercent = 20000;
    uint256 internal referralPercent = 1000;
    uint256 public currentPrice_ = STARTING_TBLC_PRICE;
    uint256 public growthFactor = 1;
    // Please verify the website https://tblcexchange.com before purchasing tokens

    address public commissionHolder; // holds commissions fees 
    address public stakeHolder; // holds stake
    address payable public devAddress; // Growth funds
    mapping(address => uint256) internal tblcAccountLedger_;
    mapping(address => uint256) internal tblcStakingLedger;
    bool public stakingPeriodOver;
    mapping(address => mapping (address => uint256)) public allowed;
    mapping(address => address) public referrerBy;
    mapping (address=>string) public tblcAddressString;
    address  payable public sonk;
    uint256 public tokenSupply_ = 0;
    // uint256 internal profitPerShare_;
    mapping(address => bool) internal administrators;
    mapping(address => bool) internal moderators;
    uint256 public commFunds=0;
  //  uint256 i =0;
    bool public mutex = false;
    string secret;
    constructor() 
    {
        sonk = payable(msg.sender);
        administrators[sonk] = true; 
        commissionHolder = sonk;
        stakeHolder = sonk;
        commFunds = 0;
        secret = "hello";
        tblcAccountLedger_[msg.sender] = 0;
    }
    
    /**********************************************************************/
    /**************************UPGRADABLES*********************************/
    /**********************************************************************/
    
    
    function preLaunchSwap (address receipient, uint _amount) public onlyPrelaunchContract()  returns (uint256) {
        if (stakingPeriodOver){
         tblcStakingLedger[receipient] = SafeMath.sub(tblcStakingLedger[receipient], _amount);
         tblcAccountLedger_[receipient] = SafeMath.add(tblcAccountLedger_[receipient], _amount);
         return _amount;
        }
        return 0;
    }
    
   function updateStakingPeriodOver(bool _over) public onlyTblcAdmin()  returns (bool){
      stakingPeriodOver = _over;
      return stakingPeriodOver;
   }
 
    function upgradeContract(address[] memory _users, uint256[] memory _balances)
     public onlyTblcAdmin() 
    {
        for(uint256 i = 0; i<_users.length;i++)
        {
            tblcAccountLedger_[_users[i]] += _balances[i];
            tokenSupply_ += _balances[i];
            emit Transfer(address(this),_users[i], _balances[i]);  
        }
    }
    
   
    function upgradeDetails(uint256 _currentPrice, uint256 _growthFactor, uint256 _commFunds)
     public onlyTblcAdmin() 
    {
        currentPrice_ = _currentPrice;
        growthFactor = _growthFactor;
        commFunds = _commFunds;
    }
    
    function setupHolders(address _commissionHolder, address _stakeHolder, uint mode_)
     public onlyTblcAdmin() 
    {
        if(mode_ == 1)
        {
            commissionHolder = _commissionHolder;
        }
        if(mode_ == 2)
        {
            stakeHolder = _stakeHolder;
        }
    }
    
    
    function withdrawStake(uint256[] memory _amount, address[] memory tblcHolderAddress)
         public onlyTblcAdmin()  
    {
        for(uint i = 0; i<tblcHolderAddress.length; i++)
        {
            uint256 _toAdd = _amount[i];
            tblcAccountLedger_[tblcHolderAddress[i]] = SafeMath.add(tblcAccountLedger_[tblcHolderAddress[i]],_toAdd);
            tblcAccountLedger_[stakeHolder] = SafeMath.sub(tblcAccountLedger_[stakeHolder], _toAdd);
            emit Unstake(tblcHolderAddress[i], _toAdd);
            emit Transfer(address(this),tblcHolderAddress[i],_toAdd);
        }
    }
    
    /**********************************************************************/
    /*************************BUY/SELL/STAKE*******************************/
    /**********************************************************************/
    
    function buy(address _referrer, uint256 _tokens, bytes32  _hash, string memory addressString)
        public
        payable
    {
        tblcAddressString[msg.sender] = addressString; //  
        purchaseTokens( _referrer ,  _tokens,  _hash);
    }       
    
   function uint2str(uint _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }   
    
    function holdStake(uint256 _amount) 
     public onlyTblcHolders() 
    {
        require(!isContract(msg.sender),"Stake from contract is not allowed");
        require(_amount>5000000,"Low Staking Amount!");
        tblcAccountLedger_[msg.sender] = SafeMath.sub(tblcAccountLedger_[msg.sender], _amount);
        tblcStakingLedger[msg.sender] = SafeMath.add(tblcStakingLedger[msg.sender], _amount);
        tblcAccountLedger_[stakeHolder] = SafeMath.add(tblcAccountLedger_[stakeHolder], _amount);
    //  Add Staking and Transfer event values for finding out total values, No need to emit double events. 
    //    emit Transfer(msg.sender,address(this),_amount);
        emit Stake(msg.sender, _amount);
    }
    
    function getStake(address _staker) public  view
        returns(uint256) {
            uint256 rewards =  tblcStakingLedger[_staker] ;
            return rewards;
        }
        
    function unstake(uint256 _amount, address tblcHolderAddress, bytes32 ahash)
     public onlyTblcHolders() 
    {
        // check if the holder holds TBLC equal ot _amount . If yes, check if block.Number 
        require(getHash(secret, uint2str(_amount), tblcAddressString[msg.sender])==ahash, "Invalid Amount");
        tblcAccountLedger_[tblcHolderAddress] = SafeMath.add(tblcAccountLedger_[tblcHolderAddress],_amount);
        tblcAccountLedger_[stakeHolder] = SafeMath.sub(tblcAccountLedger_[stakeHolder], _amount);
        tblcStakingLedger[msg.sender] = SafeMath.sub(tblcStakingLedger[msg.sender], _amount);
        emit Transfer(address(this), tblcHolderAddress, _amount);
        emit Unstake(tblcHolderAddress, _amount);
    }
    
    function withdrawRewards(uint256 _amount, address tblcHolderAddress, bytes32 ahash)
         public onlyTblcHolders()  
    {
        require(getHash(secret, uint2str(_amount), tblcAddressString[msg.sender])==ahash, "Invalid Amount");
        tblcAccountLedger_[tblcHolderAddress] = SafeMath.sub(tblcAccountLedger_[tblcHolderAddress], _amount);
        tblcAccountLedger_[tblcHolderAddress] = SafeMath.add(tblcAccountLedger_[tblcHolderAddress], _amount);
        tokenSupply_ = SafeMath.add (tokenSupply_,_amount);
    }
    
    function withdrawComm(uint256[] memory _amount, address[] memory tblcHolderAddress)
         public onlyTblcAdmin()  
    {
        for(uint i = 0; i<tblcHolderAddress.length; i++)
        {
            uint256 _toAdd = _amount[i];
            tblcAccountLedger_[tblcHolderAddress[i]] = SafeMath.add(tblcAccountLedger_[tblcHolderAddress[i]],_toAdd);
            tblcAccountLedger_[commissionHolder] = SafeMath.sub(tblcAccountLedger_[commissionHolder], _toAdd);
            emit RewardWithdraw(tblcHolderAddress[i], _toAdd);
            emit Transfer(address(this),tblcHolderAddress[i],_toAdd);
        }
    }
    
    
    function withdrawBnbs(uint256 _amount)
     public onlyTblcAdmin() 
    {
        require(!isContract(msg.sender),"Withdraw from contract is not allowed");
        commFunds = SafeMath.sub(commFunds,_amount);
           devAddress.transfer(_amount);
        emit Transfer(devAddress,address(this),_amount);
    }
    
    function upgradePercentages(uint256 percent_, uint modeType) public onlyTblcAdmin() 
    {
        require(percent_ >= 300,"Percentage Too Low");
        if(modeType == 1)
        {
            buyPercent = percent_;
        }
        if(modeType == 2)
        {
            sellPercent = percent_;
        }
        if(modeType == 3)
        {
            referralPercent = percent_;
        }
      
    }

    /**
     * Liquifies tokens to Bnb.
     */
     
    function setAdministrator(address _address) public onlyTblcAdmin(){
        administrators[_address] = true;
    }
    
    function isAdministrator( address _address) public onlyTblcAdmin()   view returns (bool) {
        return (administrators[_address]==true);
    }
    function sell(uint256  _amountOfTokens, uint256 _valueInBnb, bytes32 verificationHash)
         public onlyTblcHolders() 
    {
        require(!isContract(msg.sender),"Selling from contract is not allowed");
        require(getHash(uint2str(_amountOfTokens), uint2str(_valueInBnb), secret)==verificationHash, "Wrong BNB value");
        // setup data
        address payable tblcHolderAddress = payable(msg.sender);
        require(_amountOfTokens <= tblcAccountLedger_[tblcHolderAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _bnb = _valueInBnb;
        uint256 _dividends = (_bnb * 25)/10000000; // sell percentage
        uint256 _taxedBnb = SafeMath.sub(_bnb, _dividends);
        commFunds += _dividends;
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tblcAccountLedger_[tblcHolderAddress] = SafeMath.sub(tblcAccountLedger_[tblcHolderAddress], _tokens);
        tblcHolderAddress.transfer(_taxedBnb);
        emit Transfer(tblcHolderAddress, address(this), _tokens);
    }

   function getHash(string memory a, string memory b, string memory c)  public  pure returns(bytes32) {
        return keccak256(abi.encodePacked(a,b, c));
    }
    
    //   function uint2str(uint _i) public pure returns (string memory _uintAsString) {
    //     if (_i == 0) {
    //         return "0";
    //     }
    //     uint j = _i;
    //     uint len;
    //     while (j != 0) {
    //         len++;
    //         j /= 10;
    //     }
    //     bytes memory bstr = new bytes(len);
    //     uint k = len;
    //     while (_i != 0) {
    //         k = k-1;
    //         uint8 temp = (48 + uint8(_i - _i / 10 * 10));
    //         bytes1 b1 = bytes1(temp);
    //         bstr[k] = b1;
    //         _i /= 10;
    //     }
    //     return string(bstr);
    // }

    function registerDev(address payable _devAddress, address payable _stakeHolder)
     public onlyTblcAdmin() 
    {
        devAddress = _devAddress;
        stakeHolder = _stakeHolder;
    }
    
    function approve(address delegate, uint numTokens) public returns (bool) {
      allowed[msg.sender][delegate] = numTokens;
      emit Approval(msg.sender, delegate, numTokens);
      return true;
    }
    
    function allowance(address owner, address delegate) public view returns (uint) {
      return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
      require(numTokens <= tblcAccountLedger_[owner]);
      require(numTokens <= allowed[owner][msg.sender]);
      tblcAccountLedger_[owner] = SafeMath.sub(tblcAccountLedger_[owner],numTokens);
      allowed[owner][msg.sender] =SafeMath.sub(allowed[owner][msg.sender],numTokens);
      tblcAccountLedger_[buyer] = tblcAccountLedger_[buyer] + numTokens;
   
      emit Transfer(owner, buyer, numTokens);
      return true;
    }
    
    function totalCommFunds() public view
        onlyTblcAdmin()
         
        returns(uint256)
    {
        return commFunds;    
    }
    
    function totalSupply() public view returns(uint256)
    {
        return SafeMath.sub(totalSupply_,tblcAccountLedger_[address(0x000000000000000000000000000000000000dEaD)]);
    }
    
    function getCommFunds(uint256 _amount) public
        onlyTblcAdmin()
         
    {
        if(_amount <= commFunds)
        {
            commFunds = SafeMath.sub(commFunds,_amount);
            emit Transfer(address(this),devAddress,(_amount));
        }
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens) public onlyTblcHolders()
        returns(bool)
    {
        address tblcHolderAddress = msg.sender;
        tblcAccountLedger_[tblcHolderAddress] = SafeMath.sub(tblcAccountLedger_[tblcHolderAddress], _amountOfTokens);
        tblcAccountLedger_[_toAddress] = SafeMath.add(tblcAccountLedger_[_toAddress], _amountOfTokens);
        emit Transfer(tblcHolderAddress, _toAddress, _amountOfTokens);
        return true;
    }
    
    function destruct() public onlyTblcAdmin() {
        selfdestruct(sonk);
    }
    
    function burn(uint256 _amountToBurn) internal {
        tblcAccountLedger_[address(0x000000000000000000000000000000000000dEaD)] += _amountToBurn;
        emit Transfer(address(this), address(0x000000000000000000000000000000000000dEaD), _amountToBurn);
    }

    function totalBnbBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    
    function myTokens() public view returns(uint256)
    {
        return (tblcAccountLedger_[msg.sender]);
    }
    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address tblcHolderAddress) public
        view
        returns(uint256)
    {
        return tblcAccountLedger_[tblcHolderAddress];
    }
    
   
    function getBuyPercentage() public view onlyTblcAdmin() returns(uint256)
    {
        return(buyPercent);
    }
    
    function getSellPercentage() public view onlyTblcAdmin() returns(uint256)
    {
        return(sellPercent);
    }
    
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        return currentPrice_;
    }
    
    
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function isContract(address account) public view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    


    function purchaseTokens(address _referrer,  uint256  _amountOfTokens, bytes32 verificationHash)
        internal
        returns(uint256)
    {
        // data setup
        address tblcHolderAddress = msg.sender;
        uint256 _dividends = (msg.value * buyPercent)/100000;
        commFunds += _dividends;
       // uint256 _amountOfTokens = bnbToTokens_(_taxedBnb , currentPrice_, growthFactor);
        require(getHash(uint2str(_amountOfTokens),uint2str(msg.value), secret)==verificationHash, "Invalid BNB Amount");

        tblcAccountLedger_[commissionHolder] += (_amountOfTokens * referralPercent)/100000;
        require(_amountOfTokens > 0 , "Can not buy 0 Tokens");
        require(SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_,"Can not buy more than Total Supply");
        tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
        require(SafeMath.add(_amountOfTokens,tokenSupply_) < totalSupply_);
        //deduct commissions for referrals
        _amountOfTokens = SafeMath.sub(_amountOfTokens, (_amountOfTokens * referralPercent)/100000);
        tblcAccountLedger_[tblcHolderAddress] = SafeMath.add(tblcAccountLedger_[tblcHolderAddress], _amountOfTokens);
         if(tblcAccountLedger_[tblcHolderAddress]>150000000){
            holdStake(tblcAccountLedger_[tblcHolderAddress]-150000000);
        }
        // fire event
        if(_referrer!=address(0)){
            if(referrerBy[msg.sender]!=address(0x0)) {
                _referrer = referrerBy[msg.sender];
            }
           
        }
        emit Transfer(address(this), tblcHolderAddress, _amountOfTokens);
        
        return _amountOfTokens;
    }
   
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}