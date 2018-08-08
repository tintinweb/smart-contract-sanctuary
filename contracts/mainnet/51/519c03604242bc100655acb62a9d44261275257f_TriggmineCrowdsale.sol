pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
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

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

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
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
        Transfer(burner, address(0), _value);
    }
}

/**
 * @title TriggmineToken
 */
contract TriggmineToken is StandardToken, BurnableToken, Ownable {

    string public constant name = "Triggmine Coin";

    string public constant symbol = "TRG";

    uint256 public constant decimals = 18;

    bool public released = false;
    event Release();

    address public holder;

    mapping(address => uint) public lockedAddresses;

    modifier isReleased () {
        require(released || msg.sender == holder || msg.sender == owner);
        require(lockedAddresses[msg.sender] <= now);
        _;
    }

    function TriggmineToken() public {
        owner = 0x7E83f1F82Ab7dDE49F620D2546BfFB0539058414;

        totalSupply_ = 620000000 * (10 ** decimals);
        balances[owner] = totalSupply_;
        Transfer(0x0, owner, totalSupply_);

        holder = owner;
    }

    function lockAddress(address _lockedAddress, uint256 _time) public onlyOwner returns (bool) {
        require(balances[_lockedAddress] == 0 && lockedAddresses[_lockedAddress] == 0 && _time > now);
        lockedAddresses[_lockedAddress] = _time;
        return true;
    }

    function release() onlyOwner public returns (bool) {
        require(!released);
        released = true;
        Release();

        return true;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function transfer(address _to, uint256 _value) public isReleased returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public isReleased returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public isReleased returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public isReleased returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public isReleased returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        address oldOwner = owner;
        super.transferOwnership(newOwner);

        if (oldOwner != holder) {
            allowed[holder][oldOwner] = 0;
            Approval(holder, oldOwner, 0);
        }

        if (owner != holder) {
            allowed[holder][owner] = balances[holder];
            Approval(holder, owner, balances[holder]);
        }
    }

}

contract TriggmineCrowdsale is Ownable {
    using SafeMath for uint256;

    uint256 public constant SALES_START = 1529938800; // Monday, June 25, 2018 3:00:00 PM
    uint256 public constant SALES_END = 1538319600; // Sunday, September 30, 2018 3:00:00 PM

    address public constant ASSET_MANAGER_WALLET = 0x7E83f1F82Ab7dDE49F620D2546BfFB0539058414;
    address public constant ESCROW_WALLET = 0x2e9F22E2D559d9a5ce234AB722bc6e818FA5D079;

    address public constant TOKEN_ADDRESS = 0x98F319D4dc58315796Ec8F06274fe2d4a5A69721; // Triggmine coin ERC20 contract address
    uint256 public constant TOKEN_CENTS = 1000000000000000000; // 1 TRG is 1^18
    uint256 public constant TOKEN_PRICE = 0.0001 ether;

    uint256 public constant USD_HARD_CAP = 15000000;
    uint256 public constant MIN_INVESTMENT = 25000;

    uint public constant BONUS_50_100 = 10;
    uint public constant BONUS_100_250 = 15;
    uint public constant BONUS_250_500 = 20;
    uint public constant BONUS_500 = 25;

    mapping(address => uint256) public investments;
    uint256 public investedUSD;
    uint256 public investedETH;
    uint256 public investedBTC;
    uint256 public tokensPurchased;

    uint256 public rate_ETHUSD;
    uint256 public rate_BTCUSD;

    address public whitelistSupplier;
    mapping(address => bool) public whitelist;

    event ContributedETH(address indexed receiver, uint contribution, uint contributionUSD, uint reward);
    event ContributedBTC(address indexed receiver, uint contribution, uint contributionUSD, uint reward);
    event WhitelistUpdated(address indexed participant, bool isWhitelisted);

    constructor() public {
        whitelistSupplier = msg.sender;
        owner = ASSET_MANAGER_WALLET;
    }

    modifier onlyWhitelistSupplier() {
        require(msg.sender == whitelistSupplier || msg.sender == owner);
        _;
    }

    function contribute() public payable returns(bool) {
        return contributeETH(msg.sender);
    }

    function contributeETH(address _participant) public payable returns(bool) {
        require(now >= SALES_START && now < SALES_END);
        require(whitelist[_participant]);

        uint256 usdAmount = (msg.value * rate_ETHUSD) / 10**18;
        investedUSD = investedUSD.add(usdAmount);
        require(investedUSD <= USD_HARD_CAP);
        investments[msg.sender] = investments[msg.sender].add(usdAmount);
        require(investments[msg.sender] >= MIN_INVESTMENT);

        uint bonusPercents = getBonusPercents(usdAmount);
        uint totalTokens = getTotalTokens(msg.value, bonusPercents);

        tokensPurchased = tokensPurchased.add(totalTokens);
        require(TriggmineToken(TOKEN_ADDRESS).transferFrom(ASSET_MANAGER_WALLET, _participant, totalTokens));
        investedETH = investedETH.add(msg.value);
        ESCROW_WALLET.transfer(msg.value);

        emit ContributedETH(_participant, msg.value, usdAmount, totalTokens);
        return true;
    }

    function contributeBTC(address _participant, uint256 _btcAmount) public onlyWhitelistSupplier returns(bool) {
        require(now >= SALES_START && now < SALES_END);
        require(whitelist[_participant]);

        uint256 usdAmount = (_btcAmount * rate_BTCUSD) / 10**8; // BTC amount should be provided in satoshi
        investedUSD = investedUSD.add(usdAmount);
        require(investedUSD <= USD_HARD_CAP);
        investments[_participant] = investments[_participant].add(usdAmount);
        require(investments[_participant] >= MIN_INVESTMENT);

        uint bonusPercents = getBonusPercents(usdAmount);

        uint256 ethAmount = (_btcAmount * rate_BTCUSD * 10**10) / rate_ETHUSD;
        uint totalTokens = getTotalTokens(ethAmount, bonusPercents);

        tokensPurchased = tokensPurchased.add(totalTokens);
        require(TriggmineToken(TOKEN_ADDRESS).transferFrom(ASSET_MANAGER_WALLET, _participant, totalTokens));
        investedBTC = investedBTC.add(_btcAmount);

        emit ContributedBTC(_participant, _btcAmount, usdAmount, totalTokens);
        return true;
    }

    function setRate_ETHUSD(uint256 _rate) public onlyWhitelistSupplier {
        rate_ETHUSD = _rate;
    }

    function setRate_BTCUSD(uint256 _rate) public onlyWhitelistSupplier {
        rate_BTCUSD = _rate;
    }

    function getBonusPercents(uint256 usdAmount) private pure returns(uint256) {
        if (usdAmount >= 500000) {
            return BONUS_500;
        }

        if (usdAmount >= 250000) {
            return BONUS_250_500;
        }

        if (usdAmount >= 100000) {
            return BONUS_100_250;
        }

        if (usdAmount >= 50000) {
            return BONUS_50_100;
        }

        return 0;
    }

    function getTotalTokens(uint256 ethAmount, uint256 bonusPercents) private pure returns(uint256) {
        // If there is some division reminder, we just collect it too.
        uint256 tokensAmount = (ethAmount * TOKEN_CENTS) / TOKEN_PRICE;
        require(tokensAmount > 0);
        uint256 bonusTokens = (tokensAmount * bonusPercents) / 100;
        uint256 totalTokens = tokensAmount.add(bonusTokens);

        return totalTokens;
    }

    function () public payable {
        contribute();
    }

    function addToWhitelist(address _participant) onlyWhitelistSupplier public returns(bool) {
        if (whitelist[_participant]) {
            return true;
        }
        whitelist[_participant] = true;
        emit WhitelistUpdated(_participant, true);

        return true;
    }

    function removeFromWhitelist(address _participant) onlyWhitelistSupplier public returns(bool) {
        if (!whitelist[_participant]) {
            return true;
        }
        whitelist[_participant] = false;
        emit WhitelistUpdated(_participant, false);

        return true;
    }

    function getTokenOwner() public view returns (address) {
        return TriggmineToken(TOKEN_ADDRESS).getOwner();
    }

    function restoreTokenOwnership() public onlyOwner {
        TriggmineToken(TOKEN_ADDRESS).transferOwnership(ASSET_MANAGER_WALLET);
    }

}