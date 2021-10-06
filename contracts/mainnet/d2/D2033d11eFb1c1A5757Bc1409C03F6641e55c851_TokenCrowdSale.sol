/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

abstract contract ERC20 {
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address) virtual public view returns (uint256);
    function transfer(address, uint256) virtual public returns (bool);
    function transferFrom(address, address, uint256) virtual public returns (bool);
    function approve(address, uint256) virtual public returns (bool);
    function allowance(address, address) virtual public view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // allow transfer of ownership to another address in case shit hits the fan.
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

abstract contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;


    function transfer(address _to, uint256 _value) virtual override public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
    
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) virtual override public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) override public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) override public returns (bool success) {
        // Added to prevent potential race attack.
        // forces caller of this function to ensure address allowance is already 0
        // ref: https://github.com/ethereum/EIPs/issues/738
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    /**
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

//token contract
contract Token is Owned, StandardToken {
    using SafeMath for uint;
    event Burn(address indexed burner, uint256 value);

    /* Public variables of the token */
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 private _totalSupply;
    address public distributionAddress;
    bool public isTransferable = false;


    constructor() {
        name = "Twistcode Token";
        decimals = 18;
        symbol = "TCDT";
        _totalSupply = 1500000000 * 10 ** uint256(decimals);
        owner = msg.sender;

        //transfer all to handler address
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    function transfer(address _to, uint256 _value) override public returns (bool) {
        require(isTransferable);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool) {
        require(isTransferable);
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * Get totalSupply of tokens - Minus any from address 0 if that was used as a burnt method
     * Suggested way is still to use the burnSent function
     */
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * unlocks tokens, only allowed once
     */
    function enableTransfers() public onlyOwner {
        isTransferable = true;
    }

    /**
     * Callable by anyone
     * Accepts an input of the number of tokens to be burnt held by the sender.
     */
    function burnSent(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(burner, _value);
    }

    
    /**
    * Allow distribution helper to help with distributeToken function
    * Here we should update the distributionAddress with the crowdsale contract address upon deployment
    * Allows for added flexibility in terms of scheduling, token allocation, etc.
    */
    function setDistributionAddress(address _setAddress) public onlyOwner {
        distributionAddress = _setAddress;
    }

    /**
     * Called by owner to transfer tokens - Managing manual distribution.
     * Also allow distribution contract to call for this function
     */
    function distributeTokens(address _to, uint256 _value) public {
        require(distributionAddress == msg.sender || owner == msg.sender);
        super.transfer(_to, _value);
    }
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract OwnedBySaleOwner {
    address payable public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // allow transfer of ownership to another address in case shit hits the fan.
    function transferOwnership(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract TokenCrowdSale is OwnedBySaleOwner  {
    // all values dealt with in wei, unless explicitly specified.
    // Note: Contract to be loaded with the allocated tokens prior to pre/public sales

    // ====     start and end dates     ==== //
    uint256 public startDate;               // Start date - to be determined
    uint256 public endDate;                 // End date - to be determined

    // ==== address of Token ==== //
    Token public token;

    // ==== funds will be transferred to these addresses ==== //
    address payable public TwistcodeAddress = payable(0xe23a95fF8531dDF0Eab22DF35F131fBc7F074ed7);

    // ==== hardcap of Sale ==== //
    bool public isHalted;               // is the crowdsale halted
    
    // ==== AggregatorV3Interface so that we rely on oracle for eth price instead of hardcoding ==== //
    AggregatorV3Interface public oracle;

    // ==== bonus ==== //
    uint8 public bonusCollected;
    uint8 public maxBonusCollected;
    uint256 public bonusToGive;
    uint256 public bonusThreshold;
    mapping (address => bool) public bonusCollectionList;
    mapping (address => uint256) public bonusCollectionAmount;

    using SafeMath for uint256;

    constructor(address _Token,
                uint256 _startDate, uint256 _endDate, 
                address _oracle) {
        token = Token(_Token);             // initialising reference to ERC20
        startDate = _startDate;                  // Sale start date in UNIX time
        endDate = _endDate;                      // Sale end date in UNIX time
        owner = payable(msg.sender);                      // Set contract ownership
        oracle = AggregatorV3Interface(_oracle); // Set Oracle for Eth Price

        bonusCollected = 0; // how many have collected their bonus?
        maxBonusCollected = 30; // only 30 can get bonus
        bonusToGive = 10000 * 10 ** 18; // how much bonus to give
        bonusThreshold = 100000 * 10 ** 18; // how much of a threshold.
    }

    receive() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        // crowdsale checks
        require(isCrowdSaleOngoing(), "Crowdsale ended");
        
        // Get ethPrice from an oracle
        uint256 ethPrice = uint256(getLatestPrice()); // int256 unlikely to break uint256, judging that price would be astronomical.

        // get amount sent
        uint256 payAmt = msg.value;

        //send tokens
        uint256 toSend = calculateBonuses(payAmt, ethPrice);
        // if bonus is given, increment bonus that is collection count. 
        if(toSend > payAmt.mul(ethPrice * 10)) {
            bonusCollectionList[msg.sender] = true;
            bonusCollected++;
        }
        // tally into amount for sender.
        bonusCollectionAmount[msg.sender] = bonusCollectionAmount[msg.sender].add(toSend);

        token.distributeTokens(msg.sender, toSend);

        // send ethers to respective parties
        TwistcodeAddress.transfer(payAmt);
    }
    
    function getLatestPrice() public view returns (int) {
        (
            ,
            int256 answer, // we shall note that the latest price is times 8 decimal places. which we want to get rid of.
            ,
            ,
        ) = oracle.latestRoundData();
        return answer / (10 ** 8); // if eth goes below 1 dollar we will have more than the crowdsale to worry about.
    }

    function calculateBonuses(uint256 amount, uint256 ethPrice) public view returns (uint256 total) {
        // 0.1$ per token. at 100,000 threshhold (including previous collection). award 10,000 tokens. first 30 only. no duplicate address allowed.
        if(bonusCollected < maxBonusCollected && amount.mul(ethPrice * 10).add(bonusCollectionAmount[msg.sender]) >= bonusThreshold && !bonusCollectionList[msg.sender]){
            return amount.mul(ethPrice * 10).add(bonusToGive);
        } else {
            return amount.mul(ethPrice * 10);
        }
    }

    /**
     * Halts token sales - Only callable by owner
     */
    function haltTokenSales(bool _status) public onlyOwner {
        isHalted = _status;
    }

    /**
     * Internal check to see if crowdsale is still ongoing.
     * Defaults to return false unless within crowdsale timeframe.
     */
    function isCrowdSaleOngoing() internal view returns (bool ongoing) {
        require(!isHalted, "Sales halted.");
        require(block.timestamp >= startDate && block.timestamp <= endDate, "Sales ended.");
        return true;
    }

    /**
     * Withdraws token from smart contract.
     */
    function withdrawTokens(uint256 amount) public onlyOwner {
        token.distributeTokens(owner, amount);
    }
    
    /**
     * If somehow the chainlink oracle goes down... lets hope there is a saving grace somewhere.
     */
    function changeOracle(address newOracle) public onlyOwner {
        oracle = AggregatorV3Interface(newOracle);
    }

    /**
     * If someone sends some ERC20 tokens, we could withdraw and return them
     * Full credits to KyberNetwork.
     */
    function emergencyERC20Drain(ERC20 _token, uint256 amount) public onlyOwner {
        _token.transfer(owner, amount);
    }

    function emergencyETHDrain() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}