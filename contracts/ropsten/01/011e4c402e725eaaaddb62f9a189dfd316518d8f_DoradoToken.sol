/**
 * The tom token contract bases on the ERC20 standard token contracts from
 * open-zeppelin and is extended by functions to issue tokens as needed by the 
 * tom ICO.
 * authors: Julia Altenried, Yuri Kashnikov
 * */

pragma solidity 0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
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

contract DoradoToken is StandardToken, Owned {
    string public constant name = "DoradoToken";
    string public constant symbol = "DOR";
    uint8 public constant decimals = 15;

    /// Maximum tokens to be allocated on the sale (51% of the hard cap)
    uint256 public constant TOKENS_SALE_HARD_CAP = 510000000000000000000000; // 510000000 * 10**15

    /// Base exchange rate is set to 1 ETH = 6667 DOR.
    uint256 public constant BASE_RATE = 6667;

    /// seconds since 01.01.1970 to 07.02.2018 (16:00:00 o&#39;clock UTC)
    /// HOT sale start time
    uint64 private constant dateHOTSale = 1517961600 + 16 hours;

    /// HOT sale end time; Sale A start time 21.02.2018
    uint64 private constant dateSaleA = 1519171200 + 16 hours;

    /// Sale A end time; Sale B start time 07.03.2018
    uint64 private constant dateSaleB = 1520380800 + 16 hours;

    /// Sale B end time; Sale C start time 21.03.2018
    uint64 private constant dateSaleC = 1521590400 + 16 hours;

    /// Sale C end time; Sale D start time 04.04.2018
    uint64 private constant dateSaleD = 1522800000 + 16 hours;

    /// Sale D end time; Sale E start time 18.04.2018
    uint64 private constant dateSaleE = 1524009600 + 16 hours;

    /// Sale E end time;  Sale F start time 02.05.2018
    uint64 private constant dateSaleF = 1525219200 + 16 hours;

    /// Sale F end time; 16.05.2018 
    uint64 private constant date16May2018 = 1526428800 + 16 hours;
    
    /// token caps for each round
    uint256[7] private roundCaps = [
        70000000000000000000000, // HOT sale  70000000 * 10**15 
        140000000000000000000000, // Sale A   140000000 * 10**15
        210000000000000000000000, // Sale B   210000000 * 10**15
        285000000000000000000000, // Sale C   285000000 * 10**15
        360000000000000000000000, // Sale D   360000000 * 10**15
        435000000000000000000000, // Sale E   435000000 * 10**15
        510000000000000000000000  // Sale F   510000000 * 10**15
    ];
    uint8[7] private roundDiscountPercentages = [33, 30, 27, 22, 17, 12, 7];

    
    /// team tokens are locked until this date (01.01.2021) 00:00:00
    uint64 private constant dateTeamTokensLockedTill = 1609459200;
   

    /// no tokens can be ever issued when this is set to "true"
    bool public tokenSaleClosed = false;

    /// contract to be called to release the Dorado team tokens
    address public timelockContractAddress;

    modifier inProgress {
        require(totalSupply < TOKENS_SALE_HARD_CAP
            && !tokenSaleClosed && now >= dateHOTSale);
        _;
    }

    /// Allow the closing to happen only once
    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

    /// Require that the token sale has been closed
    modifier tradingOpen {
        require(tokenSaleClosed);
        _;
    }

    function DoradoToken() public {
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

    /// @dev Compute the amount of DOR token that can be purchased.
    /// @param ethAmount Amount of Ether in WEI to purchase DOR.
    /// @return Amount of DOR token to purchase
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256 tokens) {
        uint256 tokenBase = (ethAmount.mul(BASE_RATE)/10000000000000)*10000000000;//18 decimals to 15 decimals, set precision to 5 decimals
        uint8 roundNum = currentRoundIndex();
        tokens = tokenBase.mul(100)/(100 - (roundDiscountPercentages[roundNum]));
        while(tokens.add(totalSupply) > roundCaps[roundNum] && roundNum < 6){
           roundNum++;
           tokens = tokenBase.mul(100)/(100 - (roundDiscountPercentages[roundNum])); 
        }
    }

    /// @dev Determine the current sale round
    /// @return integer representing the index of the current sale round
    function currentRoundIndex() internal view returns (uint8 roundNum) {
        roundNum = currentRoundIndexByDate();

        /// round determined by conjunction of both time and total sold tokens
        while(roundNum < 6 && totalSupply > roundCaps[roundNum]) {
            roundNum++;
        }
    }

    /// @dev Determine the current sale tier.
    /// @return the index of the current sale tier by date.
    function currentRoundIndexByDate() internal view returns (uint8 roundNum) {
        require(now <= date16May2018); 
        if(now > dateSaleF) return 6;
        if(now > dateSaleE) return 5;
        if(now > dateSaleD) return 4;
        if(now > dateSaleC) return 3;
        if(now > dateSaleB) return 2;
        if(now > dateSaleA) return 1;
        else return 0;
    }

    /// @dev Closes the sale, issues the team tokens and burns the unsold
    function close() public onlyOwner beforeEnd {
        /// team tokens are equal to 15% of the sold tokens
        /// 8% foodout group tokens are added to the locked tokens
        uint256 lockedTokens = 230000000000000000000000;
        //partner tokens are available from the beginning
        uint256 partnerTokens = 260000000000000000000000;
        
        issueLockedTokens(lockedTokens);
        issuePartnerTokens(partnerTokens);
        
        /// increase token total supply
        totalSupply = totalSupply.add(lockedTokens+partnerTokens);
        
        /// burn the unallocated tokens - no more tokens can be issued after this line
        tokenSaleClosed = true;

        /// forward the raised funds to the contract creator
        owner.transfer(this.balance);
    }
    
    /**
     * issue the tokens for the team and the foodout group.
     * tokens are locked for 3 years.
     * @param lockedTokens the amount of tokens to the issued and locked
     * */
    function issueLockedTokens( uint lockedTokens) internal{
        /// team tokens are locked until this date (01.01.2021)
        TokenTimelock lockedTeamTokens = new TokenTimelock(this, owner, dateTeamTokensLockedTill);
        timelockContractAddress = address(lockedTeamTokens);
        balances[timelockContractAddress] = balances[timelockContractAddress].add(lockedTokens);
        /// fire event when tokens issued
        Transfer(address(0), timelockContractAddress, lockedTokens);
        
    }
    
    /**
     * issue the tokens for partners and advisors
     * @param partnerTokens the amount of tokens to be issued
     * */
    function issuePartnerTokens(uint partnerTokens) internal{
        balances[owner] = partnerTokens;
        Transfer(address(0), owner, partnerTokens);
    }

    /// Transfer limited by the tradingOpen modifier
    function transferFrom(address _from, address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /// Transfer limited by the tradingOpen modifier
    function transfer(address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transfer(_to, _value);
    }
}