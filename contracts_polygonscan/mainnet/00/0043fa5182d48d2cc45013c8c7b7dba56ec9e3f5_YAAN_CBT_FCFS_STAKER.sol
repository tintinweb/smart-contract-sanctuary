/**
 *Submitted for verification at polygonscan.com on 2021-12-16
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;


interface AggregatorV3Interface {

  function decimals() external view returns (uint);
  function description() external view returns (string memory);
  function version() external view returns (uint);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );

}

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0); // Mainnet MATIC/USD
       
    }


    function getThePrice() public view returns (uint) {
        (
            uint roundID, 
            uint price,
            uint startedAt,
            uint timeStamp,
            uint answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}


interface BEP20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}



interface STAKE {
    function userStakeStastus(address) external view returns (bool);
}

contract StakingDetails {
    
    STAKE public stakeGetter;
    
    constructor() {
        stakeGetter = STAKE(0x1843EC59C04ffbf349e21aBd317F6EC874DCAc9F); // live stake contract address
    }
    
    function stakeStatus(address addr) public view returns(bool){
        return stakeGetter.userStakeStastus(addr);
    }
}
contract YAAN_CBT_FCFS_STAKER {
    
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint public priceOfMATIC = priceConsumerV3.getThePrice();
    
    
    address public owner;
    uint public minLimit;
    uint public maxLimit;
    uint public maxCollectionLimit;
    uint public totalDeposit;
    uint public time;
	uint public buyPrice;
	uint public buyPriceDecimal;
	address public claimTokenAddr = 0xeA8f52e3BdD7446aB33f1088ba7a04BE0DC1118C; 

    struct Deposit {
        uint[] amounts;
        uint[] times;
    }
    
    struct Claim {
        uint[] claimAmounts;
        uint[] claimTimes;
    }
    
    StakingDetails stakeDetails = new StakingDetails();

    mapping(address => Deposit) private dep;
    mapping(address => Claim) claim;
    mapping(address => bool) public manualApprovalArr;
    
    event OwnershipTransferred(address to);
    event Received(address, uint);
    
    constructor() {
        owner = msg.sender;
        minLimit = 10 * 10**18;
        maxLimit = 1000 * 10**18;
        maxCollectionLimit = 400000 * 10**18;
        buyPrice = 1;
        buyPriceDecimal = 10;
        time = 1639764000; // Friday, December 17, 2021 11:30:00 PM GMT+05:30
    }
    
   function updateLiveMaticPrice() external {
      priceOfMATIC = priceConsumerV3.getThePrice();
      
    } 
    
    function deposit() external payable {

        bool userStakeStatus = stakeDetails.stakeStatus(msg.sender);
        require(userStakeStatus == true || manualApprovalArr[msg.sender]==true,"Not staked");

        uint amount  = msg.value;
        
        require(amount >= minLimit && amount <= maxLimit, "Min Max Limit Found");
        require(totalDeposit < maxCollectionLimit , "Max Deposit Limit Reached");
        address sender = msg.sender;
        dep[sender].amounts.push(amount);
        dep[sender].times.push(block.timestamp);
        totalDeposit += amount;
        uint tokens = (amount * priceOfMATIC / (100000000/buyPriceDecimal)) / buyPrice;
        uint claimAmountFirst = tokens * 30 / 100;
        uint claimAmountSecond = tokens * 30 / 100;
        uint claimAmountThird = tokens * 40 / 100;
        
        claim[sender].claimAmounts.push(claimAmountFirst);
        claim[sender].claimAmounts.push(claimAmountSecond);
        claim[sender].claimAmounts.push(claimAmountThird);
        
        claim[sender].claimTimes.push(1639764000); // Friday, December 17, 2021 11:30:00 PM GMT+05:30
        claim[sender].claimTimes.push(1642064400); // Thursday, January 13, 2022 2:30:00 PM GMT+05:30
        claim[sender].claimTimes.push(1644397200); // Wednesday, February 9, 2022 2:30:00 PM GMT+05:30
       
    }
    
    // Set buy price 
    // Upto _price_decimal decimals
    function setBuyPrice(uint _price,uint _price_decimal) external {
        require(msg.sender == owner, "Only owner");
        buyPrice = _price;
        buyPriceDecimal = _price_decimal;
    }

    function updateManualApprovalArr(address setAddress,bool setStatus) external {
        require(msg.sender == owner, "Only owner");
        manualApprovalArr[setAddress] = setStatus;
    }
    
    function updateManualApprovalArrMultiple(address[] memory setAddress,bool[] memory setStatus) external {
        require(msg.sender == owner, "Only owner");
        require(setAddress.length==setStatus.length,"Length should be same");
        for(uint i=0; i < setAddress.length; i++){
            manualApprovalArr[setAddress[i]] = setStatus[i];
        }
    }   


    
    // Update claims for addresses with multiple entries
    function updateClaims(address addr, uint[] memory _amounts, uint[] memory _times) external {
        Claim storage clm = claim[addr];
        require(msg.sender == owner, "Permission error");
        require(_amounts.length == _times.length, "Array length error");
        uint len = _amounts.length;
        for(uint i = 0; i < len; i++){
            clm.claimAmounts.push(_amounts[i]);
            clm.claimTimes.push(_times[i]);
        }
        
    }
    
    // Update claims for multiple addresses with multiple entries
    function updateMultipleClaims(address[] memory multipleAddr, uint[][] memory _multipleAmounts, uint[][] memory _multipleTimes) external {
        require(msg.sender == owner, "Permission error");
        require(multipleAddr.length == _multipleAmounts.length, "Array length error");
        require(_multipleAmounts.length == _multipleTimes.length, "Array length error");
        
        uint addrLength = multipleAddr.length;
        for(uint i = 0; i < addrLength; i++){
            require(_multipleAmounts[i].length == _multipleTimes[i].length, "Array length error");
            address addr = multipleAddr[i];
            Claim storage clm = claim[addr];
            
            uint len = _multipleAmounts[i].length;
            for(uint j = 0; j < len; j++){
                clm.claimAmounts.push(_multipleAmounts[i][j]);
                clm.claimTimes.push(_multipleTimes[i][j]);
            }
           
        }
    }    
    
   // add same claim to multiple addresses
    function updateClaimWithSameEntryForMultiAddress(address[] memory addr, uint[] memory amt, uint[] memory at) external {
        require(msg.sender == owner, "Permission error");
        require(amt.length == at.length, "Array length error");
        
        for(uint i = 0; i <  addr.length; i++){
            address singleAddr = addr[i];
            for(uint j = 0; j < amt.length; j++){
                claim[singleAddr].claimAmounts.push(amt[j]);
                claim[singleAddr].claimTimes.push(at[j]);
            }
           
        }
    }

    // remove and update all chaims for single address
    function removeAndUpdateClaims(address addr, uint[] memory _amounts, uint[] memory _times) external {
        delete claim[addr];
        Claim storage clm = claim[addr];
        require(msg.sender == owner, "Permission error");
        require(_amounts.length == _times.length, "Array length error");
        uint len = _amounts.length;
        for(uint i = 0; i < len; i++){
            clm.claimAmounts.push(_amounts[i]);
            clm.claimTimes.push(_times[i]);
        }
        
    }
    
    // Update entry for user at particular index 
    function indexValueUpdate(address addr, uint index, uint amount, uint _time) external {
        require(msg.sender == owner, "Permission error");
        claim[addr].claimAmounts[index] = amount;
        claim[addr].claimTimes[index] = _time;
    }




    
    // Transfer ownership 
    // Only owner can do that
    function ownershipTransfer(address to) external {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Zero address error");
        owner = to;
        emit OwnershipTransferred(to);
    }
    
    // Owner token withdraw 
    function ownerTokenWithdraw(address tokenAddr, uint amount) external {
        require(msg.sender == owner, "Only owner");
        BEP20 _token = BEP20(tokenAddr);
        require(amount != 0, "Zero withdrawal");
        _token.transfer(msg.sender, amount);
    }
    
    // Owner MATIC withdrawal
    function ownerMaticWithdraw(uint amount) external {
        require(msg.sender == owner, "Only owner");
        require(amount != 0, "Zero withdrawal");
        address payable to = payable(msg.sender);
        to.transfer(amount);
    }
    
    // update max limit
    function updateMaxLimit(uint maxLimitAmt) external {
        require(msg.sender == owner, "Only owner");
        maxLimit = maxLimitAmt * 10**18;
       
    }
    
    // update min limit
    function updateMinLimit(uint minLimitAmt) external{
        require(msg.sender == owner, "Only owner");
        minLimit = minLimitAmt * 10**18;
        
    }
    
    // update max Collection limit
    function updateMaxCollectionLimit(uint maxCollectionLimitAmt) external {
        require(msg.sender == owner, "Only owner");
        maxCollectionLimit = maxCollectionLimitAmt * 10**18;
        
    }
    
    /// Set claim token address
    function setClaimTokenAddress(address addr) external {
        require(msg.sender == owner, "Only owner");
        claimTokenAddr = addr;
        
    }
    
  
    
    function viewDeposits(address addr) public view returns(uint[] memory amt, uint[] memory at) {
        uint len = dep[addr].amounts.length;
        amt = new uint[](len);
        at = new uint[](len);
        for(uint i = 0; i < len; i++){
            amt[i] = dep[addr].amounts[i];
            at[i] = dep[addr].times[i];
        }
        return (amt,at);
    }
    
     // Set first claim time 
    function setFirstClaimTime(uint _time) external {
        require(msg.sender == owner, "Only owner");
        time = _time;
    }

    function claimTokens(uint index) public returns (bool) {
        require(claimTokenAddr != address(0), "Claim token address not set");
        BEP20 token = BEP20(claimTokenAddr);
        Claim storage _claim = claim[msg.sender];
        uint amount = _claim.claimAmounts[index];
        require(block.timestamp > _claim.claimTimes[index], "Claim time not reached");
        require(_claim.claimAmounts[index] != 0, "Already claimed");
        token.transfer(msg.sender, amount);
        delete _claim.claimAmounts[index];
        return true;
    }    
    
    
    /// Show Buyer Details
    function claimDetails(address addr) public view returns(uint[] memory amounts, uint[] memory times){
        uint len = claim[addr].claimAmounts.length;
        amounts = new uint[](len);
        times = new uint[](len);
        for(uint i = 0; i < len; i++){
            amounts[i] = claim[addr].claimAmounts[i];
            times[i] = claim[addr].claimTimes[i];
        }
        return (amounts, times);
    }
    
    
    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}