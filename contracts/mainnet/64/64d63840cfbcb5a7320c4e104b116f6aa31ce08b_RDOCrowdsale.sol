pragma solidity ^0.4.18;

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
    
     function percent(uint256 a,uint256 b) internal  pure returns (uint256){
      return mul(div(a,uint256(100)),b);
    }
  
    function power(uint256 a,uint256 b) internal pure returns (uint256){
      return mul(a,10**b);
    }
}


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

contract RDOToken is StandardToken {
    string public name = "RDO";
    string public symbol = "RDO";
    uint256 public decimals = 8;
    address owner;
    address crowdsale;
    
    event Burn(address indexed burner, uint256 value);

    function RDOToken() public {
        owner=msg.sender;
        uint256 initialTotalSupply=1000000000;
        totalSupply=initialTotalSupply.power(decimals);
        balances[msg.sender]=totalSupply;
        
        crowdsale=new RDOCrowdsale(this,msg.sender);
        allocate(crowdsale,75); 
        allocate(0x523f6034c79915cE9AacD06867721D444c45a6a5,12); 
        allocate(0x50d0a8eDe1548E87E5f8103b89626bC9C76fe2f8,7); 
        allocate(0xD8889ff86b9454559979Aa20bb3b41527AE4b74b,3); 
        allocate(0x5F900841910baaC70e8b736632600c409Af05bf8,3); 
        
    }

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
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }


    function allocate(address _address,uint256 percent) private{
        uint256 bal=totalSupply.percent(percent);
        transfer(_address,bal);
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    
    function stopCrowdfunding() onlyOwner public {
        if(crowdsale!=0x0){
            RDOCrowdsale(crowdsale).stopCrowdsale();
            crowdsale=0x0;
        }
    }
    
    function getCrowdsaleAddress() constant public returns(address){
        return crowdsale;
    }
}

/**
 * @title RPOCrowdsale
 * @dev RPOCrowdsale is a contract for managing a token crowdsale for RPO project.
 * Crowdsale have 9 phases with start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate and bonuses. Collected funds are forwarded to a wallet
 * as they arrive.
 */
contract RDOCrowdsale {
    using SafeMath for uint256;

    // The token being sold
    RDOToken public token;

    // External wallet where funds get forwarded
    address public wallet;

    // Crowdsale administrator
    address public owners;

    
    // price per 1 RDO
    uint256 public price=0.55 finney;

    // Phases list, see schedule in constructor
    mapping (uint => Phase) phases;

    // The total number of phases (0...9)
    uint public totalPhases = 9;

    // Description for each phase
    struct Phase {
        uint256 startTime;
        uint256 endTime;
        uint256 bonusPercent;
    }

    // Bonus based on value
    BonusValue[] bonusValue;

    struct BonusValue{
        uint256 minimum;
        uint256 maximum;
        uint256 bonus;
    }
    
    // Minimum Deposit in eth
    uint256 public constant minContribution = 100 finney;


    // Amount of raised Ethers (in wei).
    uint256 public weiRaised;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param bonusPercent free tokens percantage for the phase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 bonusPercent, uint256 amount);

    // event for wallet update
    event WalletSet(address indexed wallet);

    function RDOCrowdsale(address _tokenAddress, address _wallet) public {
        require(_tokenAddress != address(0));
        token = RDOToken(_tokenAddress);
        wallet = _wallet;
        owners=msg.sender;
        
        /*
        ICO SCHEDULE
        Bonus        
        40%     1 round
        30%     2 round
        25%     3 round
        20%     4 round
        15%     5 round
        10%     6 round
        7%      7 round
        5%      8 round
        3%      9 round
        */
        
        fillPhase(0,40,25 days);
        fillPhase(1,30,15 days);
        fillPhase(2,25,15 days);
        fillPhase(3,20,15 days);
        fillPhase(4,15,15 days);
        fillPhase(5,10,15 days);
        fillPhase(6,7,15 days);
        fillPhase(7,5,15 days);
        fillPhase(8,3,15 days);
        
        // Fill bonus based on value
        bonusValue.push(BonusValue({
            minimum:5 ether,
            maximum:25 ether,
            bonus:5
        }));
        bonusValue.push(BonusValue({
            minimum:26 ether,
            maximum:100 ether,
            bonus:8
        }));
        bonusValue.push(BonusValue({
            minimum:101 ether,
            maximum:100000 ether,
            bonus:10
        }));
    }
    
    function fillPhase(uint8 index,uint256 bonus,uint256 delay) private{
        phases[index].bonusPercent=bonus;
        if(index==0){
            phases[index].startTime = now;
        }
        else{
            phases[index].startTime = phases[index-1].endTime;
        }
        phases[index].endTime = phases[index].startTime+delay;
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(msg.value != 0);

        uint256 currentBonusPercent = getBonusPercent(now);
        uint256 weiAmount = msg.value;
        uint256 volumeBonus=getVolumeBonus(weiAmount);
        
        require(weiAmount>=minContribution);

        // calculate token amount to be created
        uint256 tokens = calculateTokenAmount(weiAmount, currentBonusPercent,volumeBonus);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.transfer(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, currentBonusPercent, tokens);

        forwardFunds();
    }

    function getVolumeBonus(uint256 _wei) private view returns(uint256){
        for(uint256 i=0;i<bonusValue.length;++i){
            if(_wei>bonusValue[i].minimum && _wei<bonusValue[i].maximum){
                return bonusValue[i].bonus;
            }
        }
        return 0;
    }
    
    // If phase exists return corresponding bonus for the given date
    // else return 0 (percent)
    function getBonusPercent(uint256 datetime) private view returns (uint256) {
        for (uint i = 0; i < totalPhases; i++) {
            if (datetime >= phases[i].startTime && datetime <= phases[i].endTime) {
                return phases[i].bonusPercent;
            }
        }
        return 0;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owners==msg.sender);
        _;
    }

    // calculates how much tokens will beneficiary get
    // for given amount of wei
    function calculateTokenAmount(uint256 _weiDeposit, uint256 _bonusTokensPercent,uint256 _volumeBonus) private view returns (uint256) {
        uint256 mainTokens = _weiDeposit.div(price);
        uint256 bonusTokens = mainTokens.percent(_bonusTokensPercent);
        uint256 volumeBonus=mainTokens.percent(_volumeBonus);
        return mainTokens.add(bonusTokens).add(volumeBonus);
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function stopCrowdsale() public {
        token.burn(token.balanceOf(this));
        selfdestruct(wallet);
    }
    
    function getCurrentBonus() public constant returns(uint256){
        return getBonusPercent(now);
    }
    
    function calculateEstimateToken(uint256 _wei) public constant returns(uint256){
        uint256 timeBonus=getCurrentBonus();
        uint256 volumeBonus=getVolumeBonus(_wei);
        return calculateTokenAmount(_wei,timeBonus,volumeBonus);
    }
}