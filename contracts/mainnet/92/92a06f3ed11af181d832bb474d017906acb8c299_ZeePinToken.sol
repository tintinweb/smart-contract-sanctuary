/**
 * Overflow aware uint math functions.
 *
 * Inspired by https://github.com/MakerDAO/maker-otc/blob/master/contracts/simple_market.sol
 */
pragma solidity ^0.4.11;

/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract ZeePinToken  {
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;


    string public name = "ZeePin Token";
    string public symbol = "ZPT";
    uint public decimals = 18;

    uint public startTime; //crowdsale start time (set in constructor)
    uint public endTime; //crowdsale end time (set in constructor)
    uint public startEarlyBird;  //crowdsale end time (set in constructor)
    uint public endEarlyBird;  //crowdsale end time (set in constructor)
    uint public startPeTime;  //pe start time (set in constructor)
    uint public endPeTime; //pe end time (set in constructor)
    uint public endFirstWeek;
    uint public endSecondWeek;
    uint public endThirdWeek;
    uint public endFourthWeek;
    uint public endFifthWeek;


    // Initial founder address (set in constructor)
    // All deposited ETH will be instantly forwarded to this address.
    address public founder = 0x0;

    // signer address (for clickwrap agreement)
    // see function() {} for comments
    address public signer = 0x0;

    // price is defined by time
    uint256 public pePrice = 6160;
    uint256 public earlyBirdPrice = 5720;
    uint256 public firstWeekTokenPrice = 4840;
    uint256 public secondWeekTokenPrice = 4752;
    uint256 public thirdWeekTokenPrice = 4620;
    uint256 public fourthWeekTokenPrice = 4532;
    uint256 public fifthWeekTokenPrice = 4400;

    uint256 public etherCap = 90909 * 10**decimals; //max amount raised during crowdsale, which represents 5,100,000,000 ZPTs
    uint256 public totalMintedToken = 1000000000;
    uint256 public etherLowLimit = 16500 * 10**decimals;
    uint256 public earlyBirdCap = 6119 * 10**decimals;
    uint256 public earlyBirdMinPerPerson = 5 * 10**decimals;
    uint256 public earlyBirdMaxPerPerson = 200 * 10**decimals;
    uint256 public peCap = 2700 * 10**decimals;
    uint256 public peMinPerPerson = 150 * 10**decimals;
    uint256 public peMaxPerPerson = 450 * 10**decimals;
    uint256 public regularMinPerPerson = 1 * 10**17;
    uint256 public regularMaxPerPerson = 200 * 10**decimals;

    uint public transferLockup = 15 days ; //transfers are locked for this time period after

    uint public founderLockup = 2 weeks; //founder allocation cannot be created until this time period after endTime
    

    uint256 public founderAllocation = 100 * 10**16; //100% of token supply allocated post-crowdsale for the founder/operation allocation


    bool public founderAllocated = false; //this will change to true when the founder fund is allocated

    uint256 public saleTokenSupply = 0; //this will keep track of the token supply created during the crowdsale
    uint256 public saleEtherRaised = 0; //this will keep track of the Ether raised during the crowdsale
    bool public halted = false; //the founder address can set this to true to halt the crowdsale due to emergency

    event Buy(uint256 eth, uint256 fbt);
    event AllocateFounderTokens(address indexed sender);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event print(bytes32 msg);

    //constructor
    function ZeePinToken(address founderInput, address signerInput, uint startTimeInput, uint endTimeInput, uint startEarlyBirdInput, uint endEarlyBirdInput, uint startPeInput, uint endPeInput) {
        founder = founderInput;
        signer = signerInput;
        startTime = startTimeInput;
        endTime = endTimeInput;
        startEarlyBird = startEarlyBirdInput;
        endEarlyBird = endEarlyBirdInput;
        startPeTime = startPeInput;
        endPeTime = endPeInput;
        
        endFirstWeek = startTime + 1 weeks;
        endSecondWeek = startTime + 2 weeks;
        endThirdWeek = startTime + 3 weeks;
        endFourthWeek = startTime + 4 weeks;
        endFifthWeek = startTime + 5 weeks;
    }

    //price based on current token supply
    function price() constant returns(uint256) {
        if (now <= endEarlyBird && now >= startEarlyBird) return earlyBirdPrice;
        if (now <= endFirstWeek) return firstWeekTokenPrice;
        if (now <= endSecondWeek) return secondWeekTokenPrice;
        if (now <= endThirdWeek) return thirdWeekTokenPrice;
        if (now <= endFourthWeek) return fourthWeekTokenPrice;
        if (now <= endFifthWeek) return fifthWeekTokenPrice;
        return fifthWeekTokenPrice;
    }

    // price() exposed for unit tests
    function testPrice(uint256 currentTime) constant returns(uint256) {
        if (currentTime < endEarlyBird && currentTime >= startEarlyBird) return earlyBirdPrice;
        if (currentTime < endFirstWeek && currentTime >= startTime) return firstWeekTokenPrice;
        if (currentTime < endSecondWeek && currentTime >= endFirstWeek) return secondWeekTokenPrice;
        if (currentTime < endThirdWeek && currentTime >= endSecondWeek) return thirdWeekTokenPrice;
        if (currentTime < endFourthWeek && currentTime >= endThirdWeek) return fourthWeekTokenPrice;
        if (currentTime < endFifthWeek && currentTime >= endFourthWeek) return fifthWeekTokenPrice;
        return fifthWeekTokenPrice;
    }


    // Buy entry point
    function buy( bytes32 hash) payable {
        print(hash);
        if (((now < startTime || now >= endTime) && (now < startEarlyBird || now >= endEarlyBird)) || halted) revert();
        if (now>=startEarlyBird && now<endEarlyBird) {
            if (msg.value < earlyBirdMinPerPerson || msg.value > earlyBirdMaxPerPerson || (saleEtherRaised + msg.value) > (peCap + earlyBirdCap)) {
                revert();
            }
        }
        if (now>=startTime && now<endTime) {
            if (msg.value < regularMinPerPerson || msg.value > regularMaxPerPerson || (saleEtherRaised + msg.value) > etherCap ) {
                revert();
            }
        }
        uint256 tokens = (msg.value * price());
        balances[msg.sender] = (balances[msg.sender] + tokens);
        totalSupply = (totalSupply + tokens);
        saleEtherRaised = (saleEtherRaised + msg.value);

        if (!founder.call.value(msg.value)()) revert(); //immediately send Ether to founder address

        Buy(msg.value, tokens);
    }

    /**
     * Set up founder address token balance.
     *
     * Security review
     *
     * - Integer math: ok - only called once with fixed parameters
     *
     * Applicable tests:
     *
     *
     */
    function allocateFounderTokens() {
        if (msg.sender!=founder) revert();
        if (now <= endTime + founderLockup) revert();
        if (founderAllocated) revert();
        balances[founder] = (balances[founder] + totalSupply * founderAllocation / (1 ether));
        totalSupply = (totalSupply + totalSupply * founderAllocation / (1 ether));
        founderAllocated = true;
        AllocateFounderTokens(msg.sender);
    }

    /**
     * Set up founder address token balance.
     *
     * Security review
     *
     * - Integer math: ok - only called once with fixed parameters
     *
     * Applicable tests:
     *
     *
     */
    function offlineSales(uint256 offlineNum, uint256 offlineEther) {
        if (msg.sender!=founder) revert();
        // if (now >= startEarlyBird && now <= endEarlyBird) revert(); //offline sales can be done only during early bird time 
        if (saleEtherRaised + offlineEther > etherCap) revert();
        totalSupply = (totalSupply + offlineNum);
        balances[founder] = (balances[founder] + offlineNum );
        saleEtherRaised = (saleEtherRaised + offlineEther);
    }

    /**
     * Emergency Stop ICO.
     *
     *  Applicable tests:
     *
     * - Test unhalting, buying, and succeeding
     */
    function halt() {
        if (msg.sender!=founder) revert();
        halted = true;
    }

    function unhalt() {
        if (msg.sender!=founder) revert();
        halted = false;
    }

    /**
     * Change founder address (where ICO ETH is being forwarded).
     *
     * Applicable tests:
     *
     * - Test founder change by hacker
     * - Test founder change
     * - Test founder token allocation twice
     */
    function changeFounder(address newFounder) {
        if (msg.sender!=founder) revert();
        founder = newFounder;
    }

    /**
     * ERC 20 Standard Token interface transfer function
     *
     * Prevent transfers until freeze period is over.
     *
     * Applicable tests:
     *
     * - Test restricted early transfer
     * - Test transfer after restricted period
     */
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (now <= endTime + transferLockup) revert();

        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        //if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }

    }
    /**
     * ERC 20 Standard Token interface transfer function
     *
     * Prevent transfers until freeze period is over.
     */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (msg.sender != founder) revert();

        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    /**
     * Do not allow direct deposits.
     *
     * All crowdsale depositors must have read the legal agreement.
     * This is confirmed by having them signing the terms of service on the website.
     * The give their crowdsale Ethereum source address on the website.
     * Website signs this address using crowdsale private key (different from founders key).
     * buy() takes this signature as input and rejects all deposits that do not have
     * signature you receive after reading terms of service.
     *
     */
    function() payable {
        buy(0x33);
    }

    // only owner can kill
    function kill() { 
        if (msg.sender == founder) suicide(founder); 
    }

}