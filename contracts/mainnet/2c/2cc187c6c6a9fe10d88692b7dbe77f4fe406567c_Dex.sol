pragma solidity ^0.4.18;
pragma experimental ABIEncoderV2;

// ----------------------------------------------------------------------------------------------
// Sample fixed supply token contract
// Enjoy. (c) BokkyPooBah 2017. The MIT Licence.
// ----------------------------------------------------------------------------------------------

import './FixedSupplyToken.sol';

contract TokenSale {
    
    uint256 fee = 0.01 ether;
    
    uint256 symbolNameIndex;
    
    uint256 historyIndex;
    
    
    //it will divide on 1000
    uint256 siteShareRatio = 1;
    
    address manager;
    
    enum State {Waiting , Selling , Ended , Checkedout}

    mapping (uint256 => uint) tokenBalanceForAddress;

    mapping (address => uint256) refAccount;

    mapping (address => mapping(uint256 => uint)) balanceEthForAddress;
    
    mapping (uint256 => Token) tokens;

    struct Token {
        address tokenContract;
        address owner;
        string symbolName;
        string symbol;
        string link;
        uint256 amount;
        uint256 leftover;
        uint256 priceInWie;
        uint256 deadline;
        uint decimals;
        State state;
        uint256 referral;
    }
    
    mapping (uint256 => History) histories;
    
    struct History{
        address owner;
        string title;
        uint256 amount;
        uint256 decimals;
        uint256 time;
        string symbol;
    }
    
    event TokenAdded(address erc20TokenAddress);
    event TokenDeposited(address erc20TokenAddress , uint256 amount);
    event DexCheckouted(address erc20TokenAddress , uint256 amount);
    event RefCheckouted(address ownerAddress , uint256 amount);
    event TokenBuyed(address erc20TokenAddress , uint256 amount , address buyer);


    function TokenSale() public{
        manager = msg.sender;
    }

    ///////////////////////
    // TOKEN MANAGEMENT //
    //////////////////////

    function addToken(address erc20TokenAddress , string symbolName , string symbol , string link , uint256 priceInWie , uint decimals , uint256 referral) public payable {
        require(!hasToken(erc20TokenAddress) , 'Token Is Already Added');
        require(msg.value == fee , 'Add Token Fee Is Invalid');
        require(referral >= 0 && referral <= 100);
        
        manager.transfer(msg.value);
        
        symbolNameIndex++;
        tokens[symbolNameIndex].symbolName = symbolName;
        tokens[symbolNameIndex].tokenContract = erc20TokenAddress;
        tokens[symbolNameIndex].symbol = symbol;
        tokens[symbolNameIndex].link = link;
        tokens[symbolNameIndex].amount = 0;
        tokens[symbolNameIndex].deadline = now;
        tokens[symbolNameIndex].leftover = 0;
        tokens[symbolNameIndex].state = State.Waiting;
        tokens[symbolNameIndex].priceInWie = priceInWie;
        tokens[symbolNameIndex].decimals = decimals;
        tokens[symbolNameIndex].referral = referral;
        tokens[symbolNameIndex].owner = msg.sender;
        
        setHistory(msg.sender , fee , 'Fee For Add Token' , 'ETH' , 18);
        setHistory(manager , fee , '(Manager) Fee For Add Token' , 'ETH' , 18);
        
        TokenAdded(erc20TokenAddress);

    }

    function hasToken(address erc20TokenAddress) public constant returns (bool) {
        uint256 index = getSymbolIndexByAddress(erc20TokenAddress);
        if (index == 0) {
            return false;
        }
        return true;
    }

    function getSymbolIndexByAddress(address erc20TokenAddress) internal returns (uint256) {
        for (uint256 i = 1; i <= symbolNameIndex; i++) {
            if (tokens[i].tokenContract == erc20TokenAddress) {
                return i;
            }
        }
        return 0;
    }
    
    function getSymbolIndexByAddressOrThrow(address erc20TokenAddress) returns (uint256) {
        uint256 index = getSymbolIndexByAddress(erc20TokenAddress);
        require(index > 0);
        return index;
    }
    
    function getAllDex() public view returns(address[] memory , string[] memory , uint256[] memory , uint[] memory , uint256[] memory , string[] memory){
        
        address[] memory tokenAdderss = new address[](symbolNameIndex+1);
        string[] memory tokenName = new string[](symbolNameIndex+1);
        string[] memory tokenLink = new string[](symbolNameIndex+1);
        uint256[] memory tokenPrice = new uint256[](symbolNameIndex+1);
        uint[] memory decimal = new uint256[](symbolNameIndex+1);
        uint256[] memory leftover = new uint256[](symbolNameIndex+1);



        for (uint256 i = 0; i <= symbolNameIndex; i++) {
            if(checkDeadLine(tokens[i]) && tokens[i].leftover != 0){
                tokenAdderss[i] = tokens[i].tokenContract;
                tokenName[i] = tokens[i].symbol;
                tokenLink[i] = tokens[i].link;
                tokenPrice[i] = tokens[i].priceInWie;
                decimal[i] = tokens[i].decimals;
                leftover[i] = tokens[i].leftover;
            }
        }
        return (tokenAdderss , tokenName , tokenPrice , decimal , leftover , tokenLink);
    }

    ////////////////////////////////
    // DEPOSIT / WITHDRAWAL TOKEN //
    ////////////////////////////////
    
    function depositToken(address erc20TokenAddress, uint256 amountTokens , uint256 deadline) public payable {
        uint256 symbolNameIndex = getSymbolIndexByAddressOrThrow(erc20TokenAddress);
        require(tokens[symbolNameIndex].tokenContract != address(0) , 'Token is Invalid');
        require(tokens[symbolNameIndex].state == State.Waiting , 'Token Cannot be deposited');
        require(tokens[symbolNameIndex].owner == msg.sender , 'You are not owner of this coin');

        ERC20Interface token = ERC20Interface(tokens[symbolNameIndex].tokenContract);
        
        require(token.transferFrom(msg.sender, address(this), amountTokens) == true);
        
        tokens[symbolNameIndex].amount = amountTokens;
        tokens[symbolNameIndex].leftover = amountTokens;
        
        require(tokenBalanceForAddress[symbolNameIndex] + amountTokens >= tokenBalanceForAddress[symbolNameIndex]);
        tokenBalanceForAddress[symbolNameIndex] += amountTokens;
        tokens[symbolNameIndex].state = State.Selling;
        tokens[symbolNameIndex].deadline = deadline;
        
        Token tokenRes = tokens[symbolNameIndex];
        
        setHistory(msg.sender , amountTokens , 'Deposit Token' , tokenRes.symbol , tokenRes.decimals);
        
        TokenDeposited(erc20TokenAddress , amountTokens);
        
    }

    function checkoutDex(address erc20TokenAddress) public payable {
        
        uint256 symbolNameIndex = getSymbolIndexByAddressOrThrow(erc20TokenAddress);
        
        ERC20Interface token = ERC20Interface(tokens[symbolNameIndex].tokenContract);

        uint256 _amountTokens = tokens[symbolNameIndex].leftover;
        
        require(tokens[symbolNameIndex].tokenContract != address(0), 'Token is Invalid');
        require(tokens[symbolNameIndex].owner == msg.sender , 'You are not owner of this coin');
        require(!checkDeadLine(tokens[symbolNameIndex]) || tokens[symbolNameIndex].leftover == 0 , 'Token Cannot be withdrawn');


        require(tokenBalanceForAddress[symbolNameIndex] - _amountTokens >= 0 , "overflow error");
        require(tokenBalanceForAddress[symbolNameIndex] - _amountTokens <= tokenBalanceForAddress[symbolNameIndex] , "Insufficient amount of token");
        
        tokenBalanceForAddress[symbolNameIndex] -= _amountTokens;
        tokens[symbolNameIndex].leftover = 0;
        tokens[symbolNameIndex].state = State.Checkedout;
        
        if(_amountTokens > 0){
            require(token.transfer(msg.sender, _amountTokens) == true , "transfer failed"); 
            setHistory(msg.sender , _amountTokens , 'Check Out Token' , tokens[symbolNameIndex].symbol , tokens[symbolNameIndex].decimals);
        }

        uint256 _siteShare = balanceEthForAddress[msg.sender][symbolNameIndex] * siteShareRatio / 1000;
        uint256 _ownerShare = balanceEthForAddress[msg.sender][symbolNameIndex] - _siteShare;
        
        setHistory(msg.sender , _ownerShare , 'Check Out ETH' , 'ETH' , 18 );
        setHistory(manager , _siteShare , '(Manager) Site Share For Deposite Token' , 'ETH' , 18);

        
        msg.sender.transfer(_ownerShare);
        
        DexCheckouted(erc20TokenAddress , _ownerShare);

    }

    function getBalance(address erc20TokenAddress) public constant returns (uint256) {
        uint256 symbolNameIndex = getSymbolIndexByAddressOrThrow(erc20TokenAddress);
        return tokenBalanceForAddress[symbolNameIndex];
    }
    
    function checkoutRef(uint256 amount) public payable {
        
        amount = amount;
        
        require(refAccount[msg.sender] >= amount , 'Insufficient amount of ETH');

        refAccount[msg.sender] -= amount;
        
        setHistory(msg.sender , amount , 'Check Out Referral' , 'ETH' , 18 );

        msg.sender.transfer(amount);
        
        RefCheckouted(msg.sender , amount);
    }
    
    function getRefBalance(address _ownerAddress) view returns(uint256){
        return refAccount[_ownerAddress];
    }

    
    ///////////////
    // Buy Token //
    ///////////////
    
    function buyToken(address erc20TokenAddress , address refAddress , uint256 _amount) payable returns(bool){
        
        uint256 symbolNameIndex = getSymbolIndexByAddressOrThrow(erc20TokenAddress);
        Token token = tokens[symbolNameIndex];

        require(token.state == State.Selling , 'You Can not Buy This Token');
        require((_amount * token.priceInWie) / (10 ** token.decimals)  == msg.value , "Incorrect Eth Amount");
        require(checkDeadLine(token) , 'Deadline Passed');
        require(token.leftover >= _amount , 'Insufficient Token Amount');
        
        if(erc20TokenAddress != refAddress){
            uint256 ref = msg.value * token.referral / 100;
            balanceEthForAddress[token.owner][symbolNameIndex] += msg.value - ref;
            refAccount[refAddress] += ref;
        }else{
            balanceEthForAddress[token.owner][symbolNameIndex] += msg.value;
        }    
        
        ERC20Interface ERC20token = ERC20Interface(tokens[symbolNameIndex].tokenContract);
        
        
        ERC20token.approve(address(this) , _amount);

        require(ERC20token.transferFrom(address(this) , msg.sender , _amount) == true , 'Insufficient Token Amount');
        
        setHistory(msg.sender , _amount , 'Buy Token' , token.symbol , token.decimals);

        
        token.leftover -= _amount;
        tokenBalanceForAddress[symbolNameIndex] -= _amount;
        
        if(token.leftover == 0){
            token.state = State.Ended;
        }
        
        TokenBuyed(erc20TokenAddress , _amount , msg.sender);
        
        return true;
    }
    
    function leftover(address erc20TokenAddress , uint256 _amount) public view returns(uint256){
        uint256 symbolNameIndex = getSymbolIndexByAddressOrThrow(erc20TokenAddress);
        return tokens[symbolNameIndex].leftover;
    }
    
    function checkDeadLine(Token token) internal returns(bool){
        return (now < token.deadline); 
    }
    
    function getOwnerTokens(address owner) public view returns(address[] memory , string[] memory , uint256[] memory , uint256[] memory , uint256[] memory , uint256[] memory , uint[] memory ){
        
        address[] memory tokenAdderss = new address[](symbolNameIndex+1);
        string[] memory tokenName = new string[](symbolNameIndex+1);
        uint256[] memory tokenAmount = new uint256[](symbolNameIndex+1);
        uint256[] memory tokenLeftover = new uint256[](symbolNameIndex+1);
        uint256[] memory tokenPrice = new uint256[](symbolNameIndex+1);
        uint256[] memory tokenDeadline = new uint256[](symbolNameIndex+1);
        uint[] memory status = new uint[](symbolNameIndex+1);


        for (uint256 i = 0; i <= symbolNameIndex; i++) {
            if (tokens[i].owner == owner) {
                tokenAdderss[i] = tokens[i].tokenContract;
                tokenName[i] = tokens[i].symbol;
                tokenAmount[i] = tokens[i].amount;
                tokenLeftover[i] = tokens[i].leftover;
                tokenPrice[i] = tokens[i].priceInWie;
                tokenDeadline[i] = tokens[i].deadline;

                if(tokens[i].state == State.Waiting)
                    status[i] = 1;
                else{    
                    if(tokens[i].state == State.Selling)
                        status[i] = 2;
                    if(!checkDeadLine(tokens[i]) || tokens[i].leftover == 0)
                        status[i] = 3;
                    if(tokens[i].state == State.Checkedout)
                        status[i] = 4;
                }
            }
        }
        return (tokenAdderss , tokenName , tokenLeftover , tokenAmount , tokenPrice , tokenDeadline , status);
    }
    
    function getDecimal(address erc20TokenAddress) public view returns(uint256){
        uint256 symbolNameIndex = getSymbolIndexByAddressOrThrow(erc20TokenAddress);
        return tokens[symbolNameIndex].decimals;
    }
    
    function getOwnerTokenDetails(address erc20TokenAddress) public view returns(Token){
        uint256 symbolNameIndex = getSymbolIndexByAddressOrThrow(erc20TokenAddress);
        Token token = tokens[symbolNameIndex];
        require(token.owner == msg.sender);
        
        return token;
    }
    
    function setHistory(address _owner , uint256 _amount , string _name , string _symbol , uint256 _decimals) public {
        histories[historyIndex].amount = _amount;
        histories[historyIndex].title = _name;
        histories[historyIndex].owner = _owner;
        histories[historyIndex].symbol = _symbol;
        histories[historyIndex].time = now;
        histories[historyIndex].decimals = _decimals;
        
        historyIndex++;
    }
    
    function getHistory(address _owner) public view returns(string[] , string[] , uint256[] , uint256[] , uint256[]){
        
        string[] memory title = new string[](historyIndex+1);
        string[] memory symbol = new string[](historyIndex+1);
        uint256[] memory time = new uint256[](historyIndex+1);
        uint256[] memory amount = new uint256[](historyIndex+1);
        uint256[] memory decimals = new uint256[](historyIndex+1);



        for (uint256 i = 0; i <= historyIndex; i++) {
            if (histories[i].owner == _owner) {
                title[i] = histories[i].title;
                symbol[i] = histories[i].symbol;
                time[i] = histories[i].time;
                amount[i] = histories[i].amount;
                decimals[i] = histories[i].decimals;
            }
        }
        return (title , symbol , time , amount , decimals);
    }
}