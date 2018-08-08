pragma solidity 0.4.18;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

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

// File: zeppelin-solidity/contracts/token/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/StandardToken.sol

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
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

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

// File: zeppelin-solidity/contracts/token/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

// File: contracts/OAKToken.sol

contract OAKToken is MintableToken {
    string public name = "Acorn Collective Token";
    string public symbol = "OAK";
    uint256 public decimals = 18;

    mapping(address => bool) public kycRequired;

    // overriding MintableToken#mint to add kyc logic
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        kycRequired[_to] = true;
        return super.mint(_to, _amount);
    }

    // overriding MintableToken#transfer to add kyc logic
    function transfer(address _to, uint _value) public returns (bool) {
        require(!kycRequired[msg.sender]);

        return super.transfer(_to, _value);
    }

    // overriding MintableToken#transferFrom to add kyc logic
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!kycRequired[_from]);

        return super.transferFrom(_from, _to, _value);
    }

    function kycVerify(address participant) onlyOwner public {
        kycRequired[participant] = false;
        KycVerified(participant);
    }
    event KycVerified(address indexed participant);
}

// File: contracts/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    OAKToken public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));

        token = createTokenContract();
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific mintable token.
    event CrowdSaleTokenContractCreation();
    // creates the token to be sold.
    function createTokenContract() internal returns (OAKToken) {
        OAKToken newToken = new OAKToken();
        CrowdSaleTokenContractCreation();
        return newToken;
    }


    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }


}

// File: contracts/FinalizableCrowdsale.sol

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract&#39;s finalization function.
     */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super.finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    function finalization() internal {
    }
}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

// File: contracts/OAKTokenCrowdsale.sol

contract OAKTokenCrowdsale is FinalizableCrowdsale, Pausable {

    uint256 public restrictedPercent;
    address public restricted;
    uint256 public soldTokens;
    uint256 public hardCap;
    uint256 public vipRate;

    uint256 public totalTokenSupply;

    mapping(address => bool) public vip;

    //TokenTimelock logic
    uint256 public Y1_lockedTokenReleaseTime;
    uint256 public Y1_lockedTokenAmount;

    uint256 public Y2_lockedTokenReleaseTime;
    uint256 public Y2_lockedTokenAmount;


    // constructor
    function OAKTokenCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public
    Crowdsale(_startTime, _endTime, _rate, _wallet) {

        // total token supply for sales
        totalTokenSupply = 75000000 * 10 ** 18;

        // hardCap for pre-sale
        hardCap = 7000000 * 10 ** 18;

        vipRate = _rate;
        soldTokens = 0;

        restrictedPercent = 20;
        restricted = msg.sender;
    }

    // update hardCap for sale
    function setHardCap(uint256 _hardCap) public onlyOwner {
        require(!isFinalized);
        require(_hardCap >= 0 && _hardCap <= totalTokenSupply);

        hardCap = _hardCap;
    }

    // update address where funds are collected
    function setWalletAddress(address _wallet) public onlyOwner {
        require(!isFinalized);

        wallet = _wallet;
    }

    // update token units a buyer gets per wei
    function setRate(uint256 _rate) public onlyOwner {
        require(!isFinalized);
        require(_rate > 0);

        rate = _rate;
    }

    // update token units a vip buyer gets per wei
    function setVipRate(uint256 _vipRate) public onlyOwner {
        require(!isFinalized);
        require(_vipRate > 0);

        vipRate = _vipRate;
    }

    // add VIP buyer address
    function setVipAddress(address _address) public onlyOwner {
        vip[_address] = true;
    }

    // remove VIP buyer address
    function unsetVipAddress(address _address) public onlyOwner {
        vip[_address] = false;
    }

    // update startTime, endTime for post-sales
    function setSalePeriod(uint256 _startTime, uint256 _endTime) public onlyOwner {
        require(!isFinalized);
        require(_startTime > 0);
        require(_endTime > _startTime);

        startTime = _startTime;
        endTime = _endTime;
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // overriding Crowdsale#buyTokens to add pausable sales and vip logic
    function buyTokens(address beneficiary) public whenNotPaused payable {
        require(beneficiary != address(0));
        require(!isFinalized);

        uint256 weiAmount = msg.value;
        uint tokens;

        if(vip[msg.sender] == true){
            tokens = weiAmount.mul(vipRate);
        }else{
            tokens = weiAmount.mul(rate);
        }
        require(validPurchase(tokens));
        soldTokens = soldTokens.add(tokens);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    // overriding Crowdsale#validPurchase to add capped sale logic
    // @return true if the transaction can buy tokens
    function validPurchase(uint256 tokens) internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool withinCap = soldTokens.add(tokens) <= hardCap;
        bool withinTotalSupply = soldTokens.add(tokens) <= totalTokenSupply;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase && withinCap && withinTotalSupply;
    }

    // overriding FinalizableCrowdsale#finalization to add 20% of sold token for owner
    function finalization() internal {
        // mint locked token to Crowdsale contract
        uint256 restrictedTokens = soldTokens.div(100).mul(restrictedPercent);
        token.mint(this, restrictedTokens);
        token.kycVerify(this);

        Y1_lockedTokenReleaseTime = now + 1 years;
        Y1_lockedTokenAmount = restrictedTokens.div(2);

        Y2_lockedTokenReleaseTime = now + 2 years;
        Y2_lockedTokenAmount = restrictedTokens.div(2);

        // stop minting new tokens
        token.finishMinting();

        // transfer the contract ownership to OAKTokenCrowdsale.owner
        token.transferOwnership(owner);

    }

    // release the 1st year locked token
    function Y1_release() onlyOwner public {
        require(Y1_lockedTokenAmount > 0);
        require(now > Y1_lockedTokenReleaseTime);

        // transfer the locked token to restricted
        token.transfer(restricted, Y1_lockedTokenAmount);

        Y1_lockedTokenAmount = 0;
    }

    // release the 2nd year locked token
    function Y2_release() onlyOwner public {
        require(Y1_lockedTokenAmount == 0);
        require(Y2_lockedTokenAmount > 0);
        require(now > Y2_lockedTokenReleaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        // transfer the locked token to restricted
        token.transfer(restricted, amount);

        Y2_lockedTokenAmount = 0;
    }

    function kycVerify(address participant) onlyOwner public {
        token.kycVerify(participant);
    }

    function addPrecommitment(address participant, uint balance) onlyOwner public {
        require(!isFinalized);
        require(balance > 0);
        // Check if the total token supply will be exceeded
        require(soldTokens.add(balance) <= totalTokenSupply);

        soldTokens = soldTokens.add(balance);
        token.mint(participant, balance);
    }

}