// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

interface OracleInterface{
    function getPrice(string memory _currencySymbol) external  view returns(int256);    
    function doesCurrencyExists (string memory _currencySymbol) external view returns(bool);
}

interface Token{
    function transferOwnership(address newOwner) external;
    function stop() external;
    function start() external;
    function close() external;
    function decimals() external view returns(uint256);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function mint( address to, uint256 value ) external returns (bool);
    function increaseApproval(address _spender, uint _addedValue) external returns (bool);
    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool);
    function burn(uint256 _value) external;
    function owner() external returns(address);
}

contract SCoinPublicSale is Ownable{

    using SafeMath for uint256;
    // Default active phase i.e 1st one
    uint256 public defaultActivePhase=1;
    uint public phaseTime=1 days;
    uint public phaseCount=16;
    uint public hardcap = 60000000000000000000000000000;
    uint public softcap=6000000000000000000000000000;
    uint public softcapTimestamp;
    // currentcap is just to store the cap till it reaches softcap
    uint public currentCap;
    uint[] tempArray;
    
    
    // Store number of tokens sold in each phase
    mapping(uint256=>uint256) public tokensSoldInEachPhase;
    
    // Decimal factor for token price 
    uint256 decimalFactorTokenPrice=10**3;
    uint256 decimalFactor;
    
    uint256 userPurchaseTokens;
    
    struct PhasesInfo{
        uint256 tokenSaleLimit;
        uint256 price;
    }
    mapping( uint256 => PhasesInfo ) public listOfPhases;
    mapping(uint=>uint) public phaseToEndTimes;
    
    
    address public tokenContractAddress= 0x1dfed394649BdCF973554Db52fE903f9e5e534a2;
    address public oracleWrapperAddress= 0x68E6d0ff31265a967603254a2254e5649675cD26;
    address public usdtContractAddress= 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address payable public adminAddress= 0x33dFAC456A6884B50872ac26C0C968DE6E442ffa;
    
    uint256 public  currentTimeStamp;
    event TokenSold(uint256 tokenPurchasedAmount, address indexed userAddress, uint256 timestamp, uint256 typeOf,uint256 ethAmount);

    constructor(){
        decimalFactor=10**Token(tokenContractAddress).decimals();
        currentTimeStamp=block.timestamp;
        listOfPhases[1]=PhasesInfo({tokenSaleLimit:60000000*decimalFactor,price:60}); // phase1 , i.e 100/10**3=0.1
        listOfPhases[2]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:150}); // phase2 
        listOfPhases[3]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:170}); // phase3 
        listOfPhases[4]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:180}); // phase4 
        listOfPhases[5]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:200}); // phase5 
        
        listOfPhases[6]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:230}); // phase6 10% of 2.5M
        listOfPhases[7]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:260}); // phase7 10% of left over
        listOfPhases[8]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:290}); // phase8 10% of  left over
        listOfPhases[9]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:320}); // phase9 10% of  left over
        listOfPhases[10]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:350}); // phase11 10% of  left over
        listOfPhases[11]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:390}); // phase12 10% of  left over
        listOfPhases[12]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:440}); // phase13 10% of  left over
        listOfPhases[13]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:480}); // phase14 10% of  left over
        listOfPhases[14]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:530}); // phase14 10% of  left over
        listOfPhases[15]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:580}); // phase14 10% of  left over
        listOfPhases[16]=PhasesInfo({tokenSaleLimit:20000000*decimalFactor,price:630}); // phase14 10% of  left over
        
        // set the phase end timestamp
        phaseToEndTimes[1]=currentTimeStamp+(20*phaseTime);
        
        for(uint i=2;i<=phaseCount;i++){
            uint lastPhaseEndTime= phaseToEndTimes[i-1];
            phaseToEndTimes[i]= lastPhaseEndTime+(10*phaseTime);
        }
        
    }

 
    // 1
    // Get active phase token price
    function activePhasePrice() internal returns (uint256 ) {
        
        Token tObj= Token(tokenContractAddress);
        uint256 currentPhaseAsPerDate  = activePhase();
        require(currentPhaseAsPerDate!=0,"ICO completed");
        if(currentPhaseAsPerDate == defaultActivePhase){
            if(soldTokenInfo(currentPhaseAsPerDate)==listOfPhases[currentPhaseAsPerDate].tokenSaleLimit){
                require(tObj.balanceOf(address(this))>0,"All tokens have been sold.");
                defaultActivePhase = defaultActivePhase.add(1);
                return listOfPhases[defaultActivePhase].price;
            }else{
                return (listOfPhases[defaultActivePhase].price);
            }
        }else if(currentPhaseAsPerDate>defaultActivePhase){
            uint256 carryOverTokens;
            for(uint256 i=defaultActivePhase;i<currentPhaseAsPerDate;i++){
                carryOverTokens+=listOfPhases[i].tokenSaleLimit.sub(soldTokenInfo(i));
            }
            listOfPhases[currentPhaseAsPerDate].tokenSaleLimit+=carryOverTokens;
            defaultActivePhase = currentPhaseAsPerDate;
            return listOfPhases[defaultActivePhase].price;
        }else{
            return listOfPhases[defaultActivePhase].price;
        }
    }
    
    // Get active phase as per current date timestamp
    function activePhase() public view returns (uint256){
        uint _currentTimeStamp=block.timestamp;
        for(uint i=1;i<=phaseCount;i++){
            if(_currentTimeStamp<=phaseToEndTimes[i]){
                return i;
            }
        }
        return 0;
    }
    
    // Get total number of tokens sold per phase
    function soldTokenInfo(uint256  _phase) public view returns (uint256){
        return tokensSoldInEachPhase[_phase];
    }
    
    // Buy tokens 
    function buyTokens(uint typeOf , uint256 _tokenAmount) public  payable {
        
        // if typeOf==1 , buy tokens using eth
        if(typeOf == 1){
            require(msg.value>0,'Eth amount cannot be zero.');
            OracleInterface oObj = OracleInterface(oracleWrapperAddress);
            uint256 currentEthPrice=uint256(oObj.getPrice('ETH')); // eth price in usd
            uint256 priceOfEthInDollar=(msg.value).mul(currentEthPrice); // price in dollar with 10**8
            uint256 currentTokenPrice = activePhasePrice(); // token current price in usd
            userPurchaseTokens=0;
            getPurchasedTokensAmount(priceOfEthInDollar,currentTokenPrice, defaultActivePhase,typeOf);
            
            // updating the softcap variable to reflect the amount of tokens sold
            if(currentCap<softcap){
                currentCap=currentCap.add(userPurchaseTokens.mul(currentTokenPrice));
                
                if(currentCap>=softcap){
                    softcapTimestamp=block.timestamp;
                }
            }
            // softcap= softcap.add(userPurchaseTokens.mul(currentTokenPrice));
           
            Token tObj= Token(tokenContractAddress);
            tObj.transfer(msg.sender,userPurchaseTokens);
            adminAddress.transfer(msg.value);
            
            
            emit TokenSold(userPurchaseTokens,msg.sender,block.timestamp,typeOf, msg.value);
            userPurchaseTokens=0;
            
        }else {
            // if typeof ==2 , buy tokens using usdt 
            require(_tokenAmount>0,'Token amount cannot be zero.');
             Token usdtContractObj = Token(usdtContractAddress);
             require(usdtContractObj.allowance(msg.sender,address(this))>=_tokenAmount,'USDT Tokens not approved.');
    
             OracleInterface oObj = OracleInterface(oracleWrapperAddress);
            uint256 currentUsdtPrice=uint256(oObj.getPrice('USDT')); // USDT price in usd
            uint256 priceOfUsdtInDollar=(_tokenAmount).mul(currentUsdtPrice); // price in dollar with 10**8
            uint256 currentTokenPrice = activePhasePrice(); // token current price in usd
            userPurchaseTokens=0;
            getPurchasedTokensAmount(priceOfUsdtInDollar,currentTokenPrice, defaultActivePhase,typeOf);
            
            // updating the softcap variable to reflect the amount of tokens sold
             if(currentCap<softcap){
                currentCap=currentCap.add(userPurchaseTokens.mul(currentTokenPrice));
                
                if(currentCap>=softcap){
                    softcapTimestamp=block.timestamp;
                }
            }  
          
            Token tObj= Token(tokenContractAddress);
            // send usdt to contract
            usdtContractObj.transferFrom(msg.sender,adminAddress,_tokenAmount);
            // contract sends scoin to user
            tObj.transfer(msg.sender,userPurchaseTokens);
            
            emit TokenSold(userPurchaseTokens,msg.sender,block.timestamp,typeOf,_tokenAmount);
            userPurchaseTokens=0;
        }
    }

    function getPurchasedTokensAmount(uint256 priceOfEthInDollar,uint256 currentTokenPrice, uint256 phase,uint typeOf) internal{
        uint256 noOfTokenAccordingToCurrentPhase;
        uint256 currentDecimalFactor;
       
        if(typeOf==1){
            currentDecimalFactor= 10**18;
        }else {
            Token usdtContractObj = Token(usdtContractAddress);
            currentDecimalFactor= 10**(usdtContractObj.decimals());
        }
        noOfTokenAccordingToCurrentPhase=(priceOfEthInDollar.mul(decimalFactorTokenPrice).mul(decimalFactor))
                                                    .div(currentTokenPrice
                                                    .mul(10**8)
                                                    .mul(currentDecimalFactor)); // no of tokens that can be purchased from current phase
        
        if(listOfPhases[phase].tokenSaleLimit.sub(soldTokenInfo(phase)) >=noOfTokenAccordingToCurrentPhase){
            userPurchaseTokens+=noOfTokenAccordingToCurrentPhase;
            tokensSoldInEachPhase[phase]+=noOfTokenAccordingToCurrentPhase;
        }else{
            uint256 noOfTokenLeftInCurrentPhase=listOfPhases[phase].tokenSaleLimit.sub(soldTokenInfo(phase));
            userPurchaseTokens+=noOfTokenLeftInCurrentPhase;
            tokensSoldInEachPhase[phase]+=noOfTokenLeftInCurrentPhase;
            uint256 priceOfCurrentLeftToken=(noOfTokenLeftInCurrentPhase.mul(currentTokenPrice)).div(10**3);
            uint256 dollarLeft=priceOfEthInDollar.sub(priceOfCurrentLeftToken.mul(10**8));
            if(dollarLeft>0){
                defaultActivePhase = phase.add(1);
                getPurchasedTokensAmount(dollarLeft,listOfPhases[defaultActivePhase].price,defaultActivePhase,typeOf);
            }
        }
    }
    
    function estimatedToken(uint256 amount,uint typeOf) public view returns(uint256){
        OracleInterface oObj = OracleInterface(oracleWrapperAddress);
        require(oObj.doesCurrencyExists(typeOf==1?"ETH":"USDT"),'Invalid currency.');
        uint256 currentCurrencyPrice=uint256(oObj.getPrice(typeOf==1?"ETH":"USDT")); // eth  OR USDT price in usd
        

        uint256 priceOfUsedCurrencyInDollar=(amount).mul(currentCurrencyPrice);
        uint256 currentTokenPrice=listOfPhases[defaultActivePhase].price;
        
        uint256 currentDecimalFactor;
        if(typeOf==1){
            currentDecimalFactor= 10**18;
        }else {
            Token usdtContractObj = Token(usdtContractAddress);
             currentDecimalFactor= 10**(usdtContractObj.decimals());

        }
        uint256 noOfTokenAccordingToCurrentPhase=(priceOfUsedCurrencyInDollar.mul(decimalFactorTokenPrice).mul(decimalFactor))
                                                    .div(currentTokenPrice
                                                        .mul(10**8)
                                                        .mul(currentDecimalFactor));
        return noOfTokenAccordingToCurrentPhase;
    }
    
    // function to send rewards after ico is finished
    function sendRewards() public onlyOwner returns (bool){
        require(activePhase()==0,'ICO not completed yet.');
        
        Token tObj= Token(tokenContractAddress);
            
        tObj.transfer(adminAddress,tObj.balanceOf(address(this)));
        return true;
        
    }
    
    function updateOracleWrapperAddress(address _oracleWrapperAddress) public onlyOwner{
        oracleWrapperAddress=_oracleWrapperAddress;
    }
    
    function adminContractAddress(address payable _adminAddress) public onlyOwner{
        adminAddress=_adminAddress;
    }
    
    function updateUsdtContractAddress(address _usdtAddress) public onlyOwner{
        require(_usdtAddress!=address(0),'Invalid address.');
        usdtContractAddress= _usdtAddress;
    }
}