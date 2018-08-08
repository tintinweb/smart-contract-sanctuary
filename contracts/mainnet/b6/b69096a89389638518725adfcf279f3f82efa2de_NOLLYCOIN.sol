/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns(uint256);
    function transfer(address to, uint256 value) returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) constant returns(uint256);
    function transferFrom(address from, address to, uint256 value) returns(bool);
    function approve(address spender, uint256 value) returns(bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}


contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */

    function transfer(address _to, uint256 _value) returns (bool) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }else {
            return false;
        }
    }
    


    /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */

    function transferFrom(address _from, address _to, uint256 _value) returns(bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            uint256 _allowance = allowed[_from][msg.sender];
            allowed[_from][msg.sender] = _allowance.sub(_value);
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }


    /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */

    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns(bool) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifing the amount of tokens still avaible for the spender.
     */
    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }


}


contract NOLLYCOIN is BasicToken {

    using SafeMath for uint256;

    string public name = "Nolly Coin";                        //name of the token
    string public symbol = "NOLLY";                                // symbol of the token
    uint8 public decimals = 18;                                  // decimals
    uint256 public totalSupply = 500000000 * 10 ** 18;             // total supply of NOLLY Tokens  

    // variables
    uint256 public reservedForFounders;              // fund allocated to key founder 
    uint256 public bountiesAllocation;                  // fund allocated for bounty
    uint256 public affiliatesAllocation;                  // fund allocated to affiliates 
    uint256 public totalAllocatedTokens;                // variable to keep track of funds allocated
    uint256 public tokensAllocatedToCrowdFund;          // funds allocated to crowdfund



    // addresses
    // multi sign address of founders which hold 
    address public founderMultiSigAddress =    0x59b645EB51B1e47e45F14A56F271030182393Efd;
    address public bountiesAllocAddress = 0x6C2625A8b19c7Bfa88d1420120DE45A60dCD6e28;  //CHANGE THIS
    address public affiliatesAllocAddress = 0x0f0345699Afa5EE03d2B089A5aF73C405885B592;  //CHANGE THIS
    address public crowdFundAddress;                    // address of crowdfund contract   
    address public owner;                               // owner of the contract
    
    


    //events
    event ChangeFoundersWalletAddress(uint256  _blockTimeStamp, address indexed _foundersWalletAddress);

    //modifiers
    modifier onlyCrowdFundAddress() {
        require(msg.sender == crowdFundAddress);
        _;
    }

    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier onlyFounders() {
        require(msg.sender == founderMultiSigAddress);
        _;
    }



    // creation of the token contract 
    function NOLLYCOIN(address _crowdFundAddress) {
        owner = msg.sender;
        crowdFundAddress = _crowdFundAddress;


        // Token Distribution         
        reservedForFounders        = 97500000 * 10 ** 18;           // 97,500,000 [19.50%]
        tokensAllocatedToCrowdFund = 300000000 * 10 ** 18;      // 300,000,000NOLLY [50%]
        // tokensAllocatedToPreICO    = 50000000 * 10 ** 18;       // 50,000,000 [10%]
        affiliatesAllocation =       25000000 * 10 ** 18;               // 25, 000, 000[5.0 %]
        bountiesAllocation         = 27750000 * 10 ** 18;               // 27,750,000[5.5%] 
                                                


        // Assigned balances to respective stakeholders
        balances[founderMultiSigAddress] = reservedForFounders;
        balances[affiliatesAllocAddress] = affiliatesAllocation;
        balances[crowdFundAddress] = tokensAllocatedToCrowdFund;
        balances[bountiesAllocAddress] = bountiesAllocation;
        totalAllocatedTokens = balances[founderMultiSigAddress] + balances[affiliatesAllocAddress] + balances[bountiesAllocAddress];
    }


    // function to keep track of the total token allocation
    function changeTotalSupply(uint256 _amount) onlyCrowdFundAddress {
        totalAllocatedTokens += _amount;
    }

    // function to change founder multisig wallet address            
    function changeFounderMultiSigAddress(address _newFounderMultiSigAddress) onlyFounders nonZeroAddress(_newFounderMultiSigAddress) {
        founderMultiSigAddress = _newFounderMultiSigAddress;
        ChangeFoundersWalletAddress(now, founderMultiSigAddress);
    }


    // fallback function to restrict direct sending of ether
    function () {
        revert();
    }

}



contract NOLLYCOINCrowdFund {

    using SafeMath for uint256;

    NOLLYCOIN public token;                                    // Token contract reference

    //variables
    uint256 public preSaleStartTime = 1514874072; //1519898430;             // 01-MARCH-18 00:10:00 UTC //CHANGE THIS    
    uint256 public preSaleEndTime = 1522490430;               // 31-MARCH-18 00:10:00 UTC           //CHANGE THIS
    uint256 public crowdfundStartDate = 1522576830;           // 1-APRIL-18 00:10:00 UTC      //CHANGE THIS
    uint256 public crowdfundEndDate = 1525155672;             // 31-MARCH-17 00:10:00 UTC      //CHANGE THIS
    uint256 public totalWeiRaised;                            // Counter to track the amount raised //CHANGE THIS
    uint256 public exchangeRateForETH = 32000;                  // No. of NOLLY Tokens in 1 ETH  // CHANGE THIS 
    uint256 public exchangeRateForBTC = 60000;                 // No. of NOLLY Tokens in 1 BTC  //CHANGE THIS
    uint256 internal tokenSoldInPresale = 0;
    uint256 internal tokenSoldInCrowdsale = 0;
    uint256 internal minAmount = 1 * 10 ** 17;                // Equivalent to 0.1 ETH

    bool internal isTokenDeployed = false;                    // Flag to track the token deployment -- only can be set once


    // addresses
    // Founders multisig address
    address public founderMultiSigAddress = 0x59b645EB51B1e47e45F14A56F271030182393Efd;   //CHANGE THIS                          
    // Owner of the contract
    address public owner;

    enum State { PreSale, Crowdfund, Finish }

    //events
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event CrowdFundClosed(uint256 _blockTimeStamp);
    event ChangeFoundersWalletAddress(uint256 _blockTimeStamp, address indexed _foundersWalletAddress);

    //Modifiers
    modifier tokenIsDeployed() {
        require(isTokenDeployed == true);
        _;
    }
    modifier nonZeroEth() {
        require(msg.value > 0);
        _;
    }

    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier onlyFounders() {
        require(msg.sender == founderMultiSigAddress);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPublic() {
        require(msg.sender != founderMultiSigAddress);
        _;
    }

    modifier inState(State state) {
        require(getState() == state);
        _;
    }

    // Constructor to initialize the local variables 
    function NOLLYCOINCrowdFund() {
        owner = msg.sender;
    }

    // Function to change the founders multisig address 
    function setFounderMultiSigAddress(address _newFounderAddress) onlyFounders  nonZeroAddress(_newFounderAddress) {
        founderMultiSigAddress = _newFounderAddress;
        ChangeFoundersWalletAddress(now, founderMultiSigAddress);
    }

    // Attach the token contract, can only be done once     
    function setTokenAddress(address _tokenAddress) external onlyOwner nonZeroAddress(_tokenAddress) {
        require(isTokenDeployed == false);
        token = NOLLYCOIN(_tokenAddress);
        isTokenDeployed = true;
    }

    // function call after crowdFundEndTime.
    // It transfers the remaining tokens to remainingTokenHolder address
    function endCrowdfund() onlyFounders inState(State.Finish) returns(bool) {
        require(now > crowdfundEndDate);
        uint256 remainingToken = token.balanceOf(this);  // remaining tokens

        if (remainingToken != 0)
            token.transfer(founderMultiSigAddress, remainingToken);
        CrowdFundClosed(now);
        return true;
    }

    // Buy token function call only in duration of crowdfund active 
    function buyTokens(address beneficiary) 
    nonZeroEth 
    tokenIsDeployed 
    onlyPublic 
    nonZeroAddress(beneficiary) 
    payable 
    returns(bool) 
    {
        require(msg.value >= minAmount);

        if (getState() == State.PreSale) {
            if (buyPreSaleTokens(beneficiary)) {
                return true;
            }
            return false;
        } else {
            require(now >= crowdfundStartDate && now <= crowdfundEndDate);
            fundTransfer(msg.value);

            uint256 amount = getNoOfTokens(exchangeRateForETH, msg.value);

            if (token.transfer(beneficiary, amount)) {
                tokenSoldInCrowdsale = tokenSoldInCrowdsale.add(amount);
                token.changeTotalSupply(amount);
                totalWeiRaised = totalWeiRaised.add(msg.value);
                TokenPurchase(beneficiary, msg.value, amount);
                return true;
            }
            return false;
        }

    }

    // function to buy the tokens at presale 
    function buyPreSaleTokens(address beneficiary) internal returns(bool) {

        uint256 amount = getTokensForPreSale(exchangeRateForETH, msg.value);
        fundTransfer(msg.value);

        if (token.transfer(beneficiary, amount)) {
            tokenSoldInPresale = tokenSoldInPresale.add(amount);
            token.changeTotalSupply(amount);
            totalWeiRaised = totalWeiRaised.add(msg.value);
            TokenPurchase(beneficiary, msg.value, amount);
            return true;
        }
        return false;
    }

    // function to calculate the total no of tokens with bonus multiplication
    function getNoOfTokens(uint256 _exchangeRate, uint256 _amount) internal constant returns(uint256) {
        uint256 noOfToken = _amount.mul(_exchangeRate);
        uint256 noOfTokenWithBonus = ((100 + getCurrentBonusRate()) * noOfToken).div(100);
        return noOfTokenWithBonus;
    }

    function getTokensForPreSale(uint256 _exchangeRate, uint256 _amount) internal constant returns(uint256) {
        uint256 noOfToken = _amount.mul(_exchangeRate);
        uint256 noOfTokenWithBonus = ((100 + getCurrentBonusRate()) * noOfToken).div(100);
        if (noOfTokenWithBonus + tokenSoldInPresale > (50000000 * 10 ** 18)) { //change this to reflect current max
            revert();
        }
        return noOfTokenWithBonus;
    }

    // function to transfer the funds to founders account
    function fundTransfer(uint256 weiAmount) internal {
        founderMultiSigAddress.transfer(weiAmount);
    }


    // Get functions 

    // function to get the current state of the crowdsale
    function getState() public constant returns(State) {
       if (now >= preSaleStartTime && now <= preSaleEndTime) {
            return State.PreSale;
        }
        if (now >= crowdfundStartDate && now <= crowdfundEndDate) {
            return State.Crowdfund;
        } 
        return State.Finish;
    }


    // function provide the current bonus rate
    function getCurrentBonusRate() internal returns(uint8) {

        if (getState() == State.PreSale) {
            return 30; //presale bonus rate is 33%
        }
        if (getState() == State.Crowdfund) {
            

        //  week 1: 8th of April 1523197901
            if (now > crowdfundStartDate && now <= 1523197901) { 
                return 25;
            }

        //  week 2: 15th of April 1523802701
            if (now > 1523197901 && now <= 1523802701) { 
                return 20;
            }


        // week 3: 
            if (now > 1523802701 && now <= 1524565102 ) {
                return 15;

            } else {

                return 10;

            }
        }
    }


    // provides the bonus % 
    function currentBonus() public constant returns(uint8) {
        return getCurrentBonusRate();
    }

    // GET functions
    function getContractTimestamp() public constant returns(
        uint256 _presaleStartDate,
        uint256 _presaleEndDate,
        uint256 _crowdsaleStartDate,
        uint256 _crowdsaleEndDate)
    {
        return (preSaleStartTime, preSaleEndTime, crowdfundStartDate, crowdfundEndDate);
    }

    function getExchangeRate() public constant returns(uint256 _exchangeRateForETH, uint256 _exchangeRateForBTC) {
        return (exchangeRateForETH, exchangeRateForBTC);
    }

    function getNoOfSoldToken() public constant returns(uint256 _tokenSoldInPresale, uint256 _tokenSoldInCrowdsale) {
        return (tokenSoldInPresale, tokenSoldInCrowdsale);
    }

    function getWeiRaised() public constant returns(uint256 _totalWeiRaised) {
        return totalWeiRaised;
    }

    // Crowdfund entry
    // send ether to the contract address
    // With at least 200 000 gas
    function() public payable {
        buyTokens(msg.sender);
    }
}