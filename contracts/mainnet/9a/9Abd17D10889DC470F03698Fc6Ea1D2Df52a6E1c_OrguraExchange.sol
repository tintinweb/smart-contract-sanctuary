/**
 * The OGXNext "Orgura Exchange" token contract bases on the ERC20 standard token contracts 
 * OGX Coin ICO. (Orgura group)
 * authors: Roongrote Suranart
 * */

pragma solidity ^0.4.20;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}


/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

    // ERC20 basic token contract being held
    ERC20Basic public token;

    // beneficiary of tokens after they are released
    address public beneficiary;

    // timestamp when token release is enabled
    uint64 public releaseTime;

    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint64 _releaseTime) public {
        require(_releaseTime > uint64(block.timestamp));
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        require(uint64(block.timestamp) >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


contract Owned {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Owned() public {
        owner = msg.sender;
    }
    
    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract OrguraExchange is StandardToken, Owned {
    string public constant name = "Orgura Exchange";
    string public constant symbol = "OGX";
    uint8 public constant decimals = 18;

    /// Maximum tokens to be allocated.
    uint256 public constant HARD_CAP = 800000000 * 10**uint256(decimals);  /* Initial supply is 800,000,000 OGX */

    /// Maximum tokens to be allocated on the sale (50% of the hard cap)
    uint256 public constant TOKENS_SALE_HARD_CAP = 400000000 * 10**uint256(decimals);

    /// Base exchange rate is set to 1 ETH = 7,169 OGX.
    uint256 public constant BASE_RATE = 7169;


    /// seconds since 01.01.1970 to 19.04.2018 (0:00:00 o&#39;clock UTC)
    /// HOT sale start time
    uint64 private constant dateSeedSale = 1523145600 + 0 hours; // 8 April 2018 00:00:00 o&#39;clock UTC

    /// Seed sale end time; Sale PreSale start time 20.04.2018
    uint64 private constant datePreSale = 1524182400 + 0 hours; // 20 April 2018 0:00:00 o&#39;clock UTC

    /// Sale PreSale end time; Sale Round 1 start time 1.05.2018
    uint64 private constant dateSaleR1 = 1525132800 + 0 hours; // 1 May 2018 0:00:00 o&#39;clock UTC

    /// Sale Round 1 end time; Sale Round 2 start time 15.05.2018
    uint64 private constant dateSaleR2 = 1526342400 + 0 hours; // 15 May 2018 0:00:00 o&#39;clock UTC

    /// Sale Round 2 end time; Sale Round 3 start time 31.05.2018
    uint64 private constant dateSaleR3 = 1527724800 + 0 hours; // 31 May 2018 0:00:00 o&#39;clock UTC

    /// Sale Round 3  end time; 14.06.2018 0:00:00 o&#39;clock UTC
    uint64 private constant date14June2018 = 1528934400 + 0 hours;

    /// Token trading opening time (14.07.2018)
    uint64 private constant date14July2018 = 1531526400;
    
    /// token caps for each round
    uint256[5] private roundCaps = [
        50000000* 10**uint256(decimals), // Sale Seed 50M  
        50000000* 10**uint256(decimals), // Sale Presale 50M
        100000000* 10**uint256(decimals), // Sale Round 1 100M
        100000000* 10**uint256(decimals), // Sale Round 2 100M
        100000000* 10**uint256(decimals) // Sale Round 3 100M
    ];
    uint8[5] private roundDiscountPercentages = [90, 75, 50, 30, 15];


    /// Date Locked until
    uint64[4] private dateTokensLockedTills = [
        1536883200, // locked until this date (14 Sep 2018) 00:00:00 o&#39;clock UTC
        1544745600, // locked until this date (14 Dec 2018) 00:00:00 o&#39;clock UTC
        1557792000, // locked until this date (14 May 2019) 00:00:00 o&#39;clock UTC
        1581638400 // locked until this date (14 Feb 2020) 00:00:00 o&#39;clock UTC
    ];

    //Locked Unil percentages
    uint8[4] private lockedTillPercentages = [20, 20, 30, 30];

    /// team tokens are locked until this date (27 APR 2019) 00:00:00
    uint64 private constant dateTeamTokensLockedTill = 1556323200;

    /// no tokens can be ever issued when this is set to "true"
    bool public tokenSaleClosed = false;

    /// contract to be called to release the Penthamon team tokens
    address public timelockContractAddress;

    modifier inProgress {
        require(totalSupply < TOKENS_SALE_HARD_CAP
            && !tokenSaleClosed && now >= dateSeedSale);
        _;
    }

    /// Allow the closing to happen only once
    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

    /// Require that the token sale has been closed
    modifier tradingOpen {
        //Begin ad token sale closed
        //require(tokenSaleClosed);
        //_; 

        //Begin at date trading open setting
        require(uint64(block.timestamp) > date14July2018);
        _;
    }

    function OrguraExchange() public {
    }

    /// @dev This default function allows token to be purchased by directly
    /// sending ether to this smart contract.
    function () public payable {
        purchaseTokens(msg.sender);
    }

    /// @dev Issue token based on Ether received.
    /// @param _beneficiary Address that newly issued token will be sent to.
    function purchaseTokens(address _beneficiary) public payable inProgress {
        // only accept a minimum amount of ETH?
        require(msg.value >= 0.01 ether);

        uint256 tokens = computeTokenAmount(msg.value);
        
        // roll back if hard cap reached
        require(totalSupply.add(tokens) <= TOKENS_SALE_HARD_CAP);
        
        doIssueTokens(_beneficiary, tokens);

        /// forward the raised funds to the contract creator
        owner.transfer(this.balance);
    }

    /// @dev Batch issue tokens on the presale
    /// @param _addresses addresses that the presale tokens will be sent to.
    /// @param _addresses the amounts of tokens, with decimals expanded (full).
    function issueTokensMulti(address[] _addresses, uint256[] _tokens) public onlyOwner beforeEnd {
        require(_addresses.length == _tokens.length);
        require(_addresses.length <= 100);

        for (uint256 i = 0; i < _tokens.length; i = i.add(1)) {
            doIssueTokens(_addresses[i], _tokens[i]);
        }
    }


    /// @dev Issue tokens for a single buyer on the presale
    /// @param _beneficiary addresses that the presale tokens will be sent to.
    /// @param _tokens the amount of tokens, with decimals expanded (full).
    function issueTokens(address _beneficiary, uint256 _tokens) public onlyOwner beforeEnd {
        doIssueTokens(_beneficiary, _tokens);
    }

    /// @dev issue tokens for a single buyer
    /// @param _beneficiary addresses that the tokens will be sent to.
    /// @param _tokens the amount of tokens, with decimals expanded (full).
    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
        require(_beneficiary != address(0));

        // increase token total supply
        totalSupply = totalSupply.add(_tokens);
        // update the beneficiary balance to number of tokens sent
        balances[_beneficiary] = balances[_beneficiary].add(_tokens);

        // event is fired when tokens issued
        Transfer(address(0), _beneficiary, _tokens);
    }

    /// @dev Returns the current price.
    function price() public view returns (uint256 tokens) {
        return computeTokenAmount(1 ether);
    }

    /// @dev Compute the amount of OGX token that can be purchased.
    /// @param ethAmount Amount of Ether in WEI to purchase OGX.
    /// @return Amount of LKC token to purchase
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256 tokens) {
        uint256 tokenBase = ethAmount.mul(BASE_RATE);
        uint8 roundNum = currentRoundIndex();
        tokens = tokenBase.mul(100)/(100 - (roundDiscountPercentages[roundNum]));
        while(tokens.add(totalSupply) > roundCaps[roundNum] && roundNum < 4){
           roundNum++;
           tokens = tokenBase.mul(100)/(100 - (roundDiscountPercentages[roundNum])); 
        }
    }

    /// @dev Determine the current sale round
    /// @return integer representing the index of the current sale round
    function currentRoundIndex() internal view returns (uint8 roundNum) {
        roundNum = currentRoundIndexByDate();

        /// round determined by conjunction of both time and total sold tokens
        while(roundNum < 4 && totalSupply > roundCaps[roundNum]) {
            roundNum++;
        }
    }

    /// @dev Determine the current sale tier.
    /// @return the index of the current sale tier by date.
    function currentRoundIndexByDate() internal view returns (uint8 roundNum) {
        require(now <= date14June2018); 
        if(now > dateSaleR3) return 4;
        if(now > dateSaleR2) return 3;
        if(now > dateSaleR1) return 2;
        if(now > datePreSale) return 1;
        else return 0;
    }

     /// @dev Closes the sale, issues the team tokens and burns the unsold
    function close() public onlyOwner beforeEnd {

      /// Company team advisor and group tokens are equal to 37.5%
        uint256 amount_lockedTokens = 300000000; // No decimals
        
        uint256 lockedTokens = amount_lockedTokens* 10**uint256(decimals); // 300M Reserve for Founder and team are added to the locked tokens 
        
        //resevred tokens are available from the beginning 25%
        uint256 reservedTokens =  100000000* 10**uint256(decimals); // 100M Reserve for parner
        
        //Sum tokens of locked and Reserved tokens 
        uint256 sumlockedAndReservedTokens = lockedTokens + reservedTokens;

        //Init fegment
        uint256 fagmentSale = 0* 10**uint256(decimals); // 0 fegment Sale

        /// check for rounding errors when cap is reached
        if(totalSupply.add(sumlockedAndReservedTokens) > HARD_CAP) {

            sumlockedAndReservedTokens = HARD_CAP.sub(totalSupply);

        }

        //issueLockedTokens(lockedTokens);
        
        //-----------------------------------------------
        // Locked until Loop calculat

        uint256 _total_lockedTokens =0;

        for (uint256 i = 0; i < lockedTillPercentages.length; i = i.add(1)) 
        {
            _total_lockedTokens =0;
            _total_lockedTokens = amount_lockedTokens.mul(lockedTillPercentages[i])* 10**uint256(decimals)/100;
            //Locked  add % of Token amount locked
            issueLockedTokensCustom( _total_lockedTokens, dateTokensLockedTills[i] );

        }
        //---------------------------------------------------


        issueReservedTokens(reservedTokens);
        
        
        /// increase token total supply
        totalSupply = totalSupply.add(sumlockedAndReservedTokens);
        
        /// burn the unallocated tokens - no more tokens can be issued after this line
        tokenSaleClosed = true;

        /// forward the raised funds to the contract creator
        owner.transfer(this.balance);
    }

    /**
     * issue the tokens for the team and the foodout group.
     * tokens are locked for 1 years.
     * @param lockedTokens the amount of tokens to the issued and locked
     * */
    function issueLockedTokens( uint lockedTokens) internal{
        /// team tokens are locked until this date (01.01.2019)
        TokenTimelock lockedTeamTokens = new TokenTimelock(this, owner, dateTeamTokensLockedTill);
        timelockContractAddress = address(lockedTeamTokens);
        balances[timelockContractAddress] = balances[timelockContractAddress].add(lockedTokens);
        /// fire event when tokens issued
        Transfer(address(0), timelockContractAddress, lockedTokens);
        
    }

    function issueLockedTokensCustom( uint lockedTokens , uint64 _dateTokensLockedTill) internal{
        /// team tokens are locked until this date (01.01.2019)
        TokenTimelock lockedTeamTokens = new TokenTimelock(this, owner, _dateTokensLockedTill);
        timelockContractAddress = address(lockedTeamTokens);
        balances[timelockContractAddress] = balances[timelockContractAddress].add(lockedTokens);
        /// fire event when tokens issued
        Transfer(address(0), timelockContractAddress, lockedTokens);
        
    }

    /**
     * issue the tokens for Reserved 
     * @param reservedTokens & bounty Tokens the amount of tokens to be issued
     * */
    function issueReservedTokens(uint reservedTokens) internal{
        balances[owner] = reservedTokens;
        Transfer(address(0), owner, reservedTokens);
    }

    // Transfer limited by the tradingOpen modifier (time is 14 July 2018 or later)
    function transferFrom(address _from, address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /// Transfer limited by the tradingOpen modifier (time is 14 July 2018 or later)
    function transfer(address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transfer(_to, _value);
    }

}