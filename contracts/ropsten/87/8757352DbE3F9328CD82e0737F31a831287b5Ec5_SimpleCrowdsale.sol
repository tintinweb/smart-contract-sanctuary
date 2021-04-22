// SPDX-License-Identifier: MIT;

pragma solidity >=0.7.0 <0.9.0;

import "./ReleasableSimpleCoin.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Destructible.sol";



contract SimpleCrowdsale is Ownable, Pausable, Destructible {
    uint256 public startTime;
    uint256 public endTime;
    uint256 public weiTokenPrice;
    uint256 public weiInvestmentObjective;
    
    mapping (address => uint256) public investmentAmountOf;
    
    uint256 public investmentReceived;
    uint256 public investmentRefunded;
    
    bool public isFinalized;
    bool public isRefundingAllowed;
    
    bool public investmentObjectiveMet;
    
    struct Tranche {
        uint256 weiHighLimit;
        uint256 weiTokenPrice;
    }
    
    mapping(uint256 => Tranche) public trancheStructure;
    
    uint256 public currentTrancheLevel; 


    
    ReleasableSimpleCoin public crowdsaleToken;
    
    constructor(uint256 _startTime, uint256 _endTime, uint256 _weiTokenPrice, uint256 _weiInvestmentObjective) payable {
        
        //This motherfucka gave me tough time. it broke my code, and remix did not correctly specify where the error was coming from
    // require(_startTime >= block.timestamp);
    require(_startTime >= 0);
    require(_endTime >= _startTime);
    require(_weiTokenPrice != 0);
    require(_weiInvestmentObjective != 0);
    
    trancheStructure[0] = Tranche(100 ether, 0.002 ether);
    trancheStructure[1] = Tranche(300 ether, 0.003 ether);
    trancheStructure[2] = Tranche(500 ether, 0.004 ether);
    trancheStructure[3] = Tranche(800 ether, 0.005 ether);
    
    currentTrancheLevel = 0;
    
    startTime = _startTime;
    endTime = _endTime;
    weiTokenPrice = _weiTokenPrice;
    weiInvestmentObjective = _weiInvestmentObjective;
    crowdsaleToken = new ReleasableSimpleCoin(0);
    isFinalized = false;
    
    }
    
    event LogInvestment(address indexed investor, uint256 value);
    event LogTokenAssignment(address indexed investor, uint256 numTokens);
    event Refund(address investor, uint256 value);
    
    
    function invest() public payable {
        require(isValidInvestment(msg.value));
        
        address investor = msg.sender;
        uint256 investment = msg.value;
        
        investmentAmountOf[investor] += investment;
        investmentReceived += investment;
        assignTokens(investor, investment);
        
        emit LogInvestment(investor, investment);
    }
    
    function isValidInvestment(uint256 _investment) internal pure returns (bool) {
        bool nonZeroInvestment = _investment != 0;
        
        //Use this for real deployment. I commented this out and used the one below in a test environment. My code will break if I don't
        // bool withinCrowdsalePeriod = block.timestamp >= startTime && block.timestamp <= endTime;
        bool withinCrowdsalePeriod = true;
        
        return nonZeroInvestment && withinCrowdsalePeriod;
    }
    
    function assignTokens(address _beneficiary, uint256 _investment) internal {
        uint256 _numberOfTokens = calculateNumberOfTokens(_investment);
        crowdsaleToken.mint(_beneficiary, _numberOfTokens);
    }
    
    function calculateNumberOfTokens(uint256 _investment) internal returns (uint256) {
        updateCurrentTrancheAndPrice(); 
        return _investment / weiTokenPrice;
    }
    
    function updateCurrentTrancheAndPrice() internal {
        uint256 i = currentTrancheLevel;
        while(trancheStructure[i].weiHighLimit < investmentReceived)
        ++i;
        currentTrancheLevel = i;
        weiTokenPrice = trancheStructure[currentTrancheLevel].weiTokenPrice; 
}

    
    function finalize() onlyOwner public {
        if (isFinalized) revert();
        
        bool isCrowdsaleComplete = block.timestamp > endTime;
        investmentObjectiveMet = investmentReceived >= weiInvestmentObjective;
        
        if (isCrowdsaleComplete) {
            if (investmentObjectiveMet) crowdsaleToken.release();
            else
                isRefundingAllowed = true;
                isFinalized = true;
        }
    }
    function refund() public {
        if (!isRefundingAllowed) revert();
        
        address investor = msg.sender;
        uint256  investment = investmentAmountOf[investor];
        
        if (investment == 0) revert();
        
        investmentAmountOf[investor] = 0;
        investmentRefunded += investment;
        
        emit Refund(msg.sender, investment);
        if (!payable(investor).send(investment)) revert();
    }
}



/**
 * StartTime: 1619092800
 * EndTime: 1619784000
 * TokenPrice: 20000000
 * InvestmentObjective: 1000
 */