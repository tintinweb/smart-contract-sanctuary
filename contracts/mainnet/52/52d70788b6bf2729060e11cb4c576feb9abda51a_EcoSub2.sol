/*SPDX-License-Identifier: MIT


███████╗░█████╗░░█████╗░░█████╗░███████╗██╗░░░░░██╗██╗░░░██╗███╗░░░███╗
██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██║░░░░░██║██║░░░██║████╗░████║
█████╗░░██║░░╚═╝██║░░██║██║░░╚═╝█████╗░░██║░░░░░██║██║░░░██║██╔████╔██║
██╔══╝░░██║░░██╗██║░░██║██║░░██╗██╔══╝░░██║░░░░░██║██║░░░██║██║╚██╔╝██║
███████╗╚█████╔╝╚█████╔╝╚█████╔╝███████╗███████╗██║╚██████╔╝██║░╚═╝░██║
╚══════╝░╚════╝░░╚════╝░░╚════╝░╚══════╝╚══════╝╚═╝░╚═════╝░╚═╝░░░░░╚═╝

Brought to you by Kryptual Team */

pragma solidity ^0.6.0;
import "./helpers.sol";

contract IAbacusOracle{
    uint public callFee;
    function getJobResponse(uint64 _jobId) public view returns(uint64[] memory _values){    }
    function scheduleFunc(address to ,uint callTime, bytes memory data , uint fee , uint gaslimit ,uint gasprice)public payable{}
}


contract EcoceliumTokenManager is Initializable{
    
    address public owner;
    address public EcoceliumAddress;
    address [] public TokenAddresses;
    mapping (string => address) rTokens;    
    mapping (string => string)  rTokensTowToken;
    mapping (string => TokenConfig)  wTokens;
    
    struct TokenConfig{
        address tokenAddress;
        uint64 fetchId;
    }
    
    function initialize(address _owner) public initializer{
        owner = _owner;
    }
    event WrapTokenCreated(
        address TokenAddress,
        string  TokenName,
        string  TokenSymbol,
        uint    Decimals
        );
        
    function updateEcoceliumAddress(address ecoAddress) public {
        require(msg.sender == owner);
        EcoceliumAddress = ecoAddress;
        for(uint i = 0;i<TokenAddresses.length;i++){
            wERC20(TokenAddresses[i]).changeAdmin(ecoAddress);
            
        }
    }
    
    function addToken(address tokenAddress) public {
        require(msg.sender == owner);
        
        ERC20Basic token = ERC20Basic(tokenAddress);
        require(getrTokenAddress(token.symbol())== address(0),"token exist");
        rTokens[token.symbol()] = tokenAddress;  
        TokenAddresses.push(tokenAddress);
    } 

    function createWrapToken(string memory name,string memory symbol,uint64 _fetchId,string memory wrapOf) public  returns(address TokenAddress){
        require(msg.sender == owner);
        require(EcoceliumAddress != address(0),"update Ecocelium Address");
        ERC20Basic rToken = ERC20Basic(getrTokenAddress(wrapOf));
        require(getrTokenAddress(wrapOf) != address(0),"counterpart not supported");

        wERC20  token = new wERC20(name,symbol,uint8(rToken.decimals()),EcoceliumAddress,address(this));        
        // token.initialize(name,symbol,uint8(rToken.decimals()),EcoceliumAddress,address(this));
        rTokensTowToken[wrapOf] = symbol;
        TokenAddresses.push(address(token));
        wTokens[symbol] = TokenConfig({
                                        tokenAddress:address(token),
                                        fetchId : _fetchId
                                    });
        emit WrapTokenCreated(address(token),name,symbol,token.decimals());                            
        return address(token);
    } 
    function changeOwner(address _owner) public{
        require(owner == msg.sender);
        owner =_owner;
    }    
    function getwTokenAddress(string memory symbol) public view returns(address){
        return wTokens[symbol].tokenAddress;
    }
    
    function getFetchId(string memory symbol ) public view returns(uint64){
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

    
}



contract EcoceliumSub1 is Initializable {

    address public owner;
    EcoceliumTokenManager ETM;
    string public WRAP_ECO_SYMBOL;
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
        
    function initializeAddress(address _owner) public initializer {
        owner = _owner;
	friendlyaddress[_owner] = true;
    }
       
    function addCurrency(string memory rtoken) public{
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        if(rcurrencyID[rtoken] != 0) {
            rtokenlist.push(rtoken);
            rcurrencyID[rtoken] = rtokenlist.length+1;
            wtokenlist.push(ETM.getWrapped(rtoken));
            wcurrencyID[ETM.getWrapped(rtoken)] = wtokenlist.length+1;
        }
    }
    
    function changeOwner(address _owner) public{
        (msg.sender == owner,"not owner");
        owner = _owner;
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
    
    function emitDeposit(address msgSender, string memory _tokenSymbol, uint amount, uint tokenUsdValue) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        emit Deposit(msgSender,_tokenSymbol,amount,tokenUsdValue);
    }
    
    function emitDuePaid(uint64 _orderId, address msgSender, uint due) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        emit DuePaid(_orderId,msgSender,due);
    }
    
    function setWRAP_ECO_SYMBOL(string memory _symbol) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        WRAP_ECO_SYMBOL = _symbol;
    }
    
    function updateFees(uint _swapFee,uint _tradeFee,uint _rewardFee) public{
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        (swapFee,tradeFee,rewardFee) = (_swapFee,_tradeFee,_rewardFee);
    }
    
    function setCSDpercent(uint percent) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        CDSpercent = percent;
    }
    
    function unlockDeposit(address _userAddress, uint amount, string memory WToken) public {
        require(friendlyaddress[msg.sender],"Not Friendly Address");
        wERC20 wtoken = wERC20(ETM.getwTokenAddress(WToken));
        wtoken.release(_userAddress,amount);
    }
        
}

