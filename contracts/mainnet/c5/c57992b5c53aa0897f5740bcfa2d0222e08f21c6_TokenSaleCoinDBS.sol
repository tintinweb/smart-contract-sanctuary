// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

interface OracleInterface{
    function latestAnswer() external view returns (int256);
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
}

contract TokenSaleCoinDBS is Ownable{

    using SafeMath for uint256;
    // Default active phase i.e 1st one
    uint256 public defaultActivePhase=1;
    
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
    
    address public tokenContractAddress=0x0666BC06Fc0c4a1eFc27557E7effC7bd91a1E671;
    address public ethOracleAddress;
    address payable public adminAddress;
    uint256 currentTimeStamp;
    event TokenSold(uint256 tokenPurchasedAmount, address indexed userAddress, uint256 timestamp, uint256 ethAmount);
    
    constructor(){
        decimalFactor=10**Token(tokenContractAddress).decimals();
        currentTimeStamp=block.timestamp;
        listOfPhases[1]=PhasesInfo({tokenSaleLimit:500000*decimalFactor,price:100}); // phase1 , i.e 100/10**3=0.1
        listOfPhases[2]=PhasesInfo({tokenSaleLimit:500000*decimalFactor,price:125}); // phase2 
        listOfPhases[3]=PhasesInfo({tokenSaleLimit:500000*decimalFactor,price:150}); // phase3 
        listOfPhases[4]=PhasesInfo({tokenSaleLimit:500000*decimalFactor,price:175}); // phase4 
        listOfPhases[5]=PhasesInfo({tokenSaleLimit:500000*decimalFactor,price:200}); // phase5 
        
        listOfPhases[6]=PhasesInfo({tokenSaleLimit:250000*decimalFactor,price:220}); // phase6 10% of 2.5M
        listOfPhases[7]=PhasesInfo({tokenSaleLimit:225000*decimalFactor,price:242}); // phase7 10% of left over
        listOfPhases[8]=PhasesInfo({tokenSaleLimit:202500*decimalFactor,price:266}); // phase8 10% of  left over
        listOfPhases[9]=PhasesInfo({tokenSaleLimit:182250*decimalFactor,price:293}); // phase9 10% of  left over
        listOfPhases[10]=PhasesInfo({tokenSaleLimit:164025*decimalFactor,price:322}); // phase10 10% of  left over
        listOfPhases[11]=PhasesInfo({tokenSaleLimit:147622*decimalFactor,price:354}); // phase11 10% of  left over
        listOfPhases[12]=PhasesInfo({tokenSaleLimit:132860*decimalFactor,price:390}); // phase12 10% of  left over
        listOfPhases[13]=PhasesInfo({tokenSaleLimit:119574*decimalFactor,price:429}); // phase13 10% of  left over
        listOfPhases[14]=PhasesInfo({tokenSaleLimit:107616*decimalFactor,price:472}); // phase14 10% of  left over
        listOfPhases[15]=PhasesInfo({tokenSaleLimit:96855*decimalFactor,price:519}); // phase14 10% of  left over
        listOfPhases[16]=PhasesInfo({tokenSaleLimit:87169*decimalFactor,price:571}); // phase14 10% of  left over
        listOfPhases[17]=PhasesInfo({tokenSaleLimit:784529*decimalFactor,price:628}); // phase14 10% of  left over
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
        if(block.timestamp >= currentTimeStamp && block.timestamp <= 1612117799){ // phase 1
            return 1;
        }else if(block.timestamp >= 1612117800 && block.timestamp <= 1613413799){ // phase 2
            return 2;
        }else if(block.timestamp >= 1613413800 && block.timestamp <= 1614536999){ // phase 3
            return 3;
        }else if(block.timestamp >= 1614537000 && block.timestamp <= 1615832999){ // phase 4
            return 4;
        }else if(block.timestamp >= 1615833000 && block.timestamp <= 1617215399){ // phase 5
            return 5;
        }else if(block.timestamp >= 1617215400 && block.timestamp <= 1619807399){ // phase 6
            return 6;
        }else if(block.timestamp >= 1619807400 && block.timestamp <= 1622485799){ // phase 7
            return 7;
        }else if(block.timestamp >= 1622485800 && block.timestamp <= 1625077799){ // phase 8
            return 8;
        }else if(block.timestamp >= 1625077800 && block.timestamp <= 1627756199){ // phase 9
            return 9;
        }else if(block.timestamp >= 1627756200 && block.timestamp <= 1630434599){ // phase 10
            return 10;
        }else if(block.timestamp >= 1630434600 && block.timestamp <= 1633026599){ // phase 11
            return 11;
        }else if(block.timestamp >= 1633026600 && block.timestamp <= 1635704999){ // phase 12
            return 12;
        }else if(block.timestamp >= 1635705000 && block.timestamp <= 1638296999){ // phase 13
            return 13;
        }else if(block.timestamp >= 1638297000 && block.timestamp <= 1640975399){ // phase 14
            return 14;
        }else if(block.timestamp >= 1640975400 && block.timestamp <= 1643653799){ // phase 15
            return 15;
        }else if(block.timestamp >= 1643653800 && block.timestamp <= 1646072999){ // phase 16
            return 16;
        }else if(block.timestamp >= 1646073000 && block.timestamp <= 1648751399){ // phase 17
            return 17;
        }
        return 0;
    }
    
    // Get total number of tokens sold per phase
    function soldTokenInfo(uint256  _phase) public view returns (uint256){
        return tokensSoldInEachPhase[_phase];
    }
    
    // Buy tokens 
    function buyTokens() public  payable {
        
        OracleInterface oObj = OracleInterface(ethOracleAddress);
        uint256 currentEthPrice=uint256(oObj.latestAnswer()); // eth price in usd
        
        uint256 priceOfEthInDollar=(msg.value).mul(currentEthPrice); // price in dollar with 10**8
        
        uint256 currentTokenPrice = activePhasePrice(); // token current price in usd
        userPurchaseTokens=0;
        getPurchasedTokensAmount(priceOfEthInDollar,currentTokenPrice, defaultActivePhase);
        Token tObj= Token(tokenContractAddress);
        tObj.transfer(msg.sender,userPurchaseTokens);
        adminAddress.transfer(msg.value);
        emit TokenSold(userPurchaseTokens,msg.sender,block.timestamp, msg.value);
        userPurchaseTokens=0;
        
    }
    
    function getPurchasedTokensAmount(uint256 priceOfEthInDollar,uint256 currentTokenPrice, uint256 phase) internal{
        uint256 noOfTokenAccordingToCurrentPhase=(priceOfEthInDollar.mul(decimalFactorTokenPrice).mul(decimalFactor))
                                                    .div(currentTokenPrice
                                                    .mul(10**8)
                                                    .mul(decimalFactor)); // no of tokens that can be purchased from current phase
        
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
                getPurchasedTokensAmount(dollarLeft,listOfPhases[defaultActivePhase].price,defaultActivePhase);
            }
        }
    }
    
    function estimatedToken(uint256 amount) public view returns(uint256){
        OracleInterface oObj = OracleInterface(ethOracleAddress);
        uint256 currentEthPrice=uint256(oObj.latestAnswer()); // eth price in usd
        
        uint256 priceOfEthInDollar=(amount).mul(currentEthPrice);
        uint256 currentTokenPrice=listOfPhases[defaultActivePhase].price;
        uint256 noOfTokenAccordingToCurrentPhase=(priceOfEthInDollar.mul(decimalFactorTokenPrice).mul(decimalFactor))
                                                    .div(currentTokenPrice
                                                        .mul(10**8)
                                                        .mul(decimalFactor));
        return noOfTokenAccordingToCurrentPhase;
    }
    
    function burnTokens() public{
        if(activePhase()==0){
            Token tObj= Token(tokenContractAddress);
            tObj.burn(tObj.balanceOf(address(this)));
        }
    }
    
    function updateETHOracleContractAddress(address _ethOracleAddress) public onlyOwner{
        ethOracleAddress=_ethOracleAddress;
    }
    
    function adminContractAddress(address payable _adminAddress) public onlyOwner{
        adminAddress=_adminAddress;
    }
}
