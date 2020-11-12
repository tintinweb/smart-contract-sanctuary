// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "./helpers.sol";

contract IAbacusOracle{
    uint public callFee;
    function getJobResponse(uint64 _jobId) public view returns(uint64[] memory _values){    }
    function scheduleFunc(address to ,uint callTime, bytes memory data , uint fee , uint gaslimit ,uint gasprice)public payable{}
}

contract EcoceliumInit is Initializable {

    address payable owner;
    address payable public MONEYMANAGER;
    address payable public DATAMANAGER;
    address payable public ECOCELIUM;
    address payable public ABACUS;
    string public WRAP_ECO_SYMBOL;
    string public ECO;
    string public ETH_SYMBOL;
    string public WRAP_ETH_SYMBOL;
    uint public swapFee;
    uint public rewardFee;
    uint public tradeFee;
    uint public CDSpercent;
    string [] rtokenlist;
    string [] wtokenlist;
    mapping (string => uint) public rcurrencyID;
    mapping (string => uint) public wcurrencyID;
    mapping (address => bool)  public isRegistrar;
    mapping (address => bool) public isUserLocked;
    mapping (string => uint ) public ownerFeeVault;
    mapping (string => uint) public slabRateDeposit;
    mapping (address => bool) public friendlyaddress;
    mapping (address => address) public SponsorAddress;
    mapping (address => uint) public usertreasuryearnings;
    
    event OrderCreated(
        address userAddress,
        uint duration,
        uint yield,
        uint amount,
        string token
        );
        
    event Swap(
        address userAddress,
        string from,
        string to,
        uint amount
        );
        
    event Borrowed(
        uint64 orderId,
        address borrower,
        uint amount,
        uint duration
        );
        
    event Deposit(
         address userAddress,
         string token,
         uint tokenAmount,
         uint collateralValue
         );
         
    event DuePaid(
        uint64 orderId,
        address borrower,
        uint amount
        );
        
    event WrapTokenCreated(
        address TokenAddress,
        string  TokenName,
        string  TokenSymbol,
        uint    Decimals
        );
        
    receive() payable external {     }    
        
    function initializeAddress(address payable _owner) public initializer {
        friendlyaddress[_owner] = true;
        owner = _owner;
    }
       
    function addRealCurrency(string memory rtoken) public{
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        if(rcurrencyID[rtoken] == 0) {
            rtokenlist.push(rtoken);
            rcurrencyID[rtoken] = rtokenlist.length; }
    }
    
    function addWrapCurrency (string memory wtoken) public{
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        if(wcurrencyID[wtoken] == 0) {
            wtokenlist.push(wtoken);
            wcurrencyID[wtoken] = wtokenlist.length; }
    }
    
    function setSlabRate(string memory WToken, uint rate) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        slabRateDeposit[WToken] = rate;
    }
    
    function setUserLocked(address userAddress, bool value) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        isUserLocked[userAddress] = value;
    }
    
    function setFriendlyAddress(address Address) public {
        (msg.sender == owner,"not owner");
        friendlyaddress[Address] = true;
    }
    
    function addRegistrar(address _registrar) public{
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        isRegistrar[_registrar] = true;
    }
    
    function setOwnerFeeVault(string memory add,uint value) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        ownerFeeVault[add] += value; 
    }
       
    function emitOrderCreated(address userAddress, uint _duration, uint _yield, uint newAmount,string  memory _tokenSymbol) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        emit OrderCreated(userAddress,_duration,_yield,newAmount,_tokenSymbol);        
    }
    
    function emitSwap(address msgSender, string memory from, string memory to,uint _amount) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        emit Swap(msgSender,from,to,_amount);
    }
    
    function emitBorrowed(uint64 _orderId, address msgSender, uint _amount,uint _duration) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        emit Borrowed(_orderId,msgSender,_amount,_duration);
    }
    
    function emitWrappedCreated(address tokenAddress,string memory name, string memory symbol,uint8 decimals) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        emit WrapTokenCreated(tokenAddress,name,symbol,decimals);   
    }
    
    function emitDeposit(address msgSender, string memory _tokenSymbol, uint amount, uint tokenUsdValue) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        emit Deposit(msgSender,_tokenSymbol,amount,tokenUsdValue);
    }
    
    function emitDuePaid(uint64 _orderId, address msgSender, uint due) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        emit DuePaid(_orderId,msgSender,due);
    }
    
    function setCONSTSYMBOLS(string[4] memory _symbolCONST) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        WRAP_ECO_SYMBOL = _symbolCONST[0];
        ECO = _symbolCONST[1];
        ETH_SYMBOL = _symbolCONST[2];
        WRAP_ETH_SYMBOL = _symbolCONST[3];
    }
    
    function updateFees(uint _swapFee,uint _tradeFee,uint _rewardFee) public{
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        (swapFee,tradeFee,rewardFee) = (_swapFee,_tradeFee,_rewardFee);
    }
    
    function setCSDpercent(uint percent) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        CDSpercent = percent;
    }
    
    function changeAbacusaddress(address payable Abacusaddress) public{
        require(msg.sender == owner,"not owner");
        ABACUS = Abacusaddress;
    } 
    
    function changeEcoceliumaddress(address payable Ecocelium) public{
        require(msg.sender == owner,"not owner");
        ECOCELIUM = Ecocelium;
    } 
    
    function changeDMaddress(address payable DMAddress) public{
        require(msg.sender == owner,"not owner");
        DATAMANAGER = DMAddress;
    }
    
     function changeMMaddress(address payable MMaddress) public{
        require(msg.sender == owner,"not owner");
        MONEYMANAGER = MMaddress;
    }
    
    function changeOwner(address payable _owner) public{
        require(msg.sender==owner);
        owner = _owner;
    }
    
    function setSponsor(address userAddress, address _sponsorAddress) external {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        SponsorAddress[userAddress] = _sponsorAddress;
    }
    
    function updateTreasuryEarnings(address userAddress, uint _amount) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        usertreasuryearnings[userAddress] = _amount;
    }
}


contract EcoMoneyManager is Initializable {
    

    
    
    EcoceliumInit Init;
    address public owner;
    address [] public TokenAddresses;
    address [] public wTokenAddresses;
    mapping (string => address) rTokens;
    mapping (string => string) public wtormap;
    mapping (string => string)  public rTokensTowToken;
    mapping (string => TokenConfig)  wTokens;
    mapping (address => uint) public ecoWithdrawls;
    mapping (string => uint) public WGains;
    mapping (string => uint) public WLoss;
    
    receive() payable external {     }
    
    struct TokenConfig{
        address tokenAddress;
        uint64 fetchId;
    }
    
    function initialize(address _owner, address payable _Init) public initializer{
        owner = _owner;
        Init = EcoceliumInit(_Init);
    }
    
    function updateAdminAddress(address adminAddress) public {
        require(msg.sender == owner);
        for(uint i = 0;i<wTokenAddresses.length;i++){
            wERC20(wTokenAddresses[i]).changeAdmin(adminAddress);
        }
    }
    
    function addTokenWithAddress(address tokenAddress) public {
        require(msg.sender == owner);
        ERC20Basic token = ERC20Basic(tokenAddress);
        require(getrTokenAddress(token.symbol())== address(0),"token exist");
        rTokens[token.symbol()] = tokenAddress;  
        TokenAddresses.push(tokenAddress);
    } 

    function createWrapToken(string memory name,string memory symbol,uint64 _fetchId, uint8 decimal, string memory wrapOf) public  returns(address TokenAddress){
        require(msg.sender == owner);
        wERC20  token = new wERC20(name,symbol,decimal, address(this), address(this));        
        rTokensTowToken[wrapOf] = symbol;
        TokenAddresses.push(address(token));
        wTokenAddresses.push(address(token));
        wTokens[symbol] = TokenConfig({
                                        tokenAddress:address(token),
                                        fetchId : _fetchId
                                    });
        Init.emitWrappedCreated(address(token),name,symbol,token.decimals());                 
        return address(token);
    } 
    
    function changeOwner(address _owner) public{
        require(owner == msg.sender);
        owner =_owner;
    }   
    
    function updatertoken (string memory WToken, string memory RToken) public {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        wtormap[WToken] = RToken;
    }
    
    function getwTokenAddress(string memory symbol) public view returns(address){
        return wTokens[symbol].tokenAddress;
    }
    
    function getFetchId(string memory symbol ) public view returns(uint64){
        if( wTokens[symbol].tokenAddress == address(0))   {
            symbol = rTokensTowToken[symbol];
        }
        return wTokens[symbol].fetchId;
    }
    
    function getrTokenAddress(string memory symbol) public view returns(address){
        return rTokens[symbol];
    }
    
    function getTokenAddresses() public view returns(address[] memory){
        return TokenAddresses;
    }
    
    function getWrapped(string memory symbol) public view returns(string memory){
        return rTokensTowToken[symbol];
    }
    
    function getTokenID(string memory symbol) public view returns(uint){
        for(uint i=0; i< TokenAddresses.length; i++) {
            if(TokenAddresses[i] == wTokens[symbol].tokenAddress) {
                return i;
            }
        }
    }
    
    function releaseWrappedToken (address _userAddress, uint amount, string memory WToken) public {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        wERC20(getwTokenAddress(WToken)).release(_userAddress,amount);
    }
    
    function mintWrappedToken (address _userAddress, uint amount, string memory WToken) public {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        wERC20(getwTokenAddress(WToken)).mint(_userAddress,amount);
    }
    
    function lockWrappedToken (address _userAddress, uint amount, string memory WToken) public {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        wERC20(getwTokenAddress(WToken)).lock(_userAddress,amount);
    }
    
    function burnWrappedFrom(address userAddress, uint amount, string memory WToken) public {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        wERC20(getwTokenAddress(WToken)).burnFrom(userAddress,amount);
    }
     
    function mintECO(address userAddress, uint amount) public {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        wERC20(getwTokenAddress(Init.WRAP_ECO_SYMBOL())).mint(userAddress,amount);
    }
    
    function lockECO(address userAddress, uint amount) public {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        wERC20(getwTokenAddress(Init.WRAP_ECO_SYMBOL())).lock(userAddress,amount);
    }
    
    function releaseECO(address userAddress, uint amount) public {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        wERC20(getwTokenAddress(Init.WRAP_ECO_SYMBOL())).release(userAddress,amount);
    }
    
    function burnECOFrom(address userAddress, uint amount) public {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        wERC20(getwTokenAddress(Init.WRAP_ECO_SYMBOL())).burnFrom(userAddress,amount);
    }
    
    function DepositManager(string memory _rtoken, uint amount, address userAddress) public payable {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        if(Init.rcurrencyID(_rtoken) == Init.rcurrencyID(Init.ETH_SYMBOL()))
        {   require(msg.value >= amount,"Invalid Amount");  }
        else {ERC20Basic rtoken = ERC20Basic(getrTokenAddress(_rtoken));
        require(rtoken.allowance(userAddress, address(this)) >= amount,"set allowance");
        rtoken.transferFrom(userAddress,address(this),amount);}
    }
    
    function WithdrawManager(string memory _rtoken, uint amount, address payable userAddress) public {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        if(Init.rcurrencyID(_rtoken) == Init.rcurrencyID(Init.ETH_SYMBOL()))
        {   userAddress.transfer(amount);        }
        else {
        ERC20Basic rtoken = ERC20Basic(getrTokenAddress(_rtoken));
        rtoken.transfer(userAddress,amount);}
    }
    
    function redeemEcoEarning(address payable userAddress, uint amount) public {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        ecoWithdrawls[userAddress] = ecoWithdrawls[userAddress] + amount;
        WithdrawManager(Init.ECO(), amount, userAddress);
    }

    function adjustEcoEarning(address userAddress, uint amount) public {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        ecoWithdrawls[userAddress] = ecoWithdrawls[userAddress] - amount;
    }
    
    function updateFetchID (string memory wtoken, uint64 _fetchID) external {
        require(owner == msg.sender);
        wTokens[wtoken].fetchId = _fetchID;
    }
    
    function w2wswap (address msgSender, string memory token1, uint token1amount, uint token2amount, string memory token2) external {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        releaseWrappedToken(msgSender, token1amount, token1);
        burnWrappedFrom(msgSender,token1amount,token1);
        WGains[token1]=token1amount;
        mintWrappedToken(msgSender,token2amount, token2);
        lockWrappedToken(msgSender, token2amount, token2);
        WLoss[token2]=token2amount;
    }
    
    function updateWrapAddress (string memory wtoken, address wAddress) external {
        require(owner == msg.sender);
        wTokens[wtoken].tokenAddress = wAddress;
    }
    
    function updatewtoken (string memory RToken, string memory WToken) public {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        rTokensTowToken[RToken] = WToken;
    }
}
