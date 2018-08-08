pragma solidity 0.4.23;


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
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
        emit Transfer(msg.sender, _to, _value);
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
        emit Transfer(_from, _to, _value);
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
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
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
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

    constructor(ERC20Basic _token, address _beneficiary, uint64 _releaseTime) public {
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

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract ReferralDiscountToken is StandardToken, Owned {
    /// Store the referrers by the referred addresses
    mapping(address => address) referrerOf;
    address[] ownersIndex;

    // Emitted when an investor declares his referrer
    event Referral(address indexed referred, address indexed referrer);

    /// Compute the earned discount, topped at 60%
    function referralDiscountPercentage(address _owner) public view returns (uint256 percent) {
        uint256 total = 0;

        /// get one time discount for having been referred
        if(referrerOf[_owner] != address(0)) {
            total = total.add(10);
        }

        /// get a 10% discount for each one referred
        for(uint256 i = 0; i < ownersIndex.length; i++) {
            if(referrerOf[ownersIndex[i]] == _owner) {
                total = total.add(10);
                // if(total >= 60) break;
            }
        }

        return total;
    }

    // /**
    //  * Activate referral discounts by declaring one&#39;s own referrer
    //  * @param _referrer can&#39;t be self
    //  * @param _referrer must own tokens at the time of the call
    //  * You must own tokens at the time of the call
    //  */
    // function setReferrer(address _referrer) public returns (bool success) {
    //     require(_referrer != address(0));
    //     require(_referrer != address(msg.sender));
    //     require(balanceOf(msg.sender) > 0);
    //     require(balanceOf(_referrer) > 0);
    //     assert(referrerOf[msg.sender] == address(0));

    //     ownersIndex.push(msg.sender);
    //     referrerOf[msg.sender] = _referrer;

    //     Referral(msg.sender, _referrer);
    //     return true;
    // }

    /**
     * Activate referral discounts by declaring one&#39;s own referrer
     * @param _referrer the investor who brought another
     * @param _referred the investor who was brought by another
     * @dev _referrer and _referred must own tokens at the time of the call
     */
    function setReferrer(address _referred, address _referrer) onlyOwner public returns (bool success) {
        require(_referrer != address(0));
        require(_referrer != address(_referred));
        //        require(balanceOf(_referred) > 0);
        //        require(balanceOf(_referrer) > 0);
        require(referrerOf[_referred] == address(0));

        ownersIndex.push(_referred);
        referrerOf[_referred] = _referrer;

        emit Referral(_referred, _referrer);
        return true;
    }
}

contract NaorisToken is ReferralDiscountToken {
    string public constant name = "NaorisToken";
    string public constant symbol = "NAO";
    uint256 public constant decimals = 18;

    /// The owner of this address will manage the sale process.
    address public saleTeamAddress;

    /// The owner of this address will manage the referal and airdrop campaigns.
    address public referalAirdropsTokensAddress;

    /// The owner of this address is the Naoris Reserve fund.
    address public reserveFundAddress;

    /// The owner of this address is the Naoris Think Tank fund.
    address public thinkTankFundAddress;

    /// This address keeps the locked board bonus until 1st of May 2019
    address public lockedBoardBonusAddress;

    /// This is the address of the timelock contract for the locked Board Bonus tokens
    address public treasuryTimelockAddress;

    /// After this flag is changed to &#39;true&#39; no more tokens can be created
    bool public tokenSaleClosed = false;

    // seconds since 01.01.1970 to 1st of May 2019 (both 00:00:00 o&#39;clock UTC)
    uint64 date01May2019 = 1556668800;

    /// Maximum tokens to be allocated.
    uint256 public constant TOKENS_HARD_CAP = 400000000 * 10 ** decimals;

    /// Maximum tokens to be sold.
    uint256 public constant TOKENS_SALE_HARD_CAP = 300000000 * 10 ** decimals;

    /// Tokens to be allocated to the Referal tokens fund.
    uint256 public constant REFERRAL_TOKENS = 10000000 * 10 ** decimals;

    /// Tokens to be allocated to the Airdrop tokens fund.
    uint256 public constant AIRDROP_TOKENS = 10000000 * 10 ** decimals;

    /// Tokens to be allocated to the Think Tank fund.
    uint256 public constant THINK_TANK_FUND_TOKENS = 40000000 * 10 ** decimals;

    /// Tokens to be allocated to the Naoris Team fund.
    uint256 public constant NAORIS_TEAM_TOKENS = 20000000 * 10 ** decimals;

    /// Tokens to be allocated to the locked Board Bonus.
    uint256 public constant LOCKED_BOARD_BONUS_TOKENS = 20000000 * 10 ** decimals;

    /// Only the sale team or the owner are allowed to execute
    modifier onlyTeam {
        assert(msg.sender == saleTeamAddress || msg.sender == owner);
        _;
    }

    /// Only allowed to execute while the sale is not yet closed
    modifier beforeEnd {
        assert(!tokenSaleClosed);
        _;
    }

    constructor(address _saleTeamAddress, address _referalAirdropsTokensAddress, address _reserveFundAddress,
    address _thinkTankFundAddress, address _lockedBoardBonusAddress) public {
        require(_saleTeamAddress != address(0));
        require(_referalAirdropsTokensAddress != address(0));
        require(_reserveFundAddress != address(0));
        require(_thinkTankFundAddress != address(0));
        require(_lockedBoardBonusAddress != address(0));

        saleTeamAddress = _saleTeamAddress;
        referalAirdropsTokensAddress = _referalAirdropsTokensAddress;
        reserveFundAddress = _reserveFundAddress;
        thinkTankFundAddress = _thinkTankFundAddress;
        lockedBoardBonusAddress = _lockedBoardBonusAddress;
                
        /// The unsold sale tokens will be burnt when the sale is closed
        balances[saleTeamAddress] = TOKENS_SALE_HARD_CAP;
        totalSupply_ = TOKENS_SALE_HARD_CAP;
        emit Transfer(0x0, saleTeamAddress, TOKENS_SALE_HARD_CAP);

        /// The unspent referal/airdrop tokens will be sent back
        /// to the reserve fund when the sale is closed
        balances[referalAirdropsTokensAddress] = REFERRAL_TOKENS;
        totalSupply_ = totalSupply_.add(REFERRAL_TOKENS);
        emit Transfer(0x0, referalAirdropsTokensAddress, REFERRAL_TOKENS);

        balances[referalAirdropsTokensAddress] = balances[referalAirdropsTokensAddress].add(AIRDROP_TOKENS);
        totalSupply_ = totalSupply_.add(AIRDROP_TOKENS);
        emit Transfer(0x0, referalAirdropsTokensAddress, AIRDROP_TOKENS);
    }

    function close() public onlyTeam beforeEnd {
        /// burn the unsold sale tokens
        uint256 unsoldSaleTokens = balances[saleTeamAddress];
        if(unsoldSaleTokens > 0) {
            balances[saleTeamAddress] = 0;
            totalSupply_ = totalSupply_.sub(unsoldSaleTokens);
            emit Transfer(saleTeamAddress, 0x0, unsoldSaleTokens);
        }
        
        /// transfer the unspent referal/airdrop tokens to the Reserve fund
        uint256 unspentReferalAirdropTokens = balances[referalAirdropsTokensAddress];
        if(unspentReferalAirdropTokens > 0) {
            balances[referalAirdropsTokensAddress] = 0;
            balances[reserveFundAddress] = balances[reserveFundAddress].add(unspentReferalAirdropTokens);
            emit Transfer(referalAirdropsTokensAddress, reserveFundAddress, unspentReferalAirdropTokens);
        }
        
        /// 40% allocated to the Naoris Think Tank Fund
        balances[thinkTankFundAddress] = balances[thinkTankFundAddress].add(THINK_TANK_FUND_TOKENS);
        totalSupply_ = totalSupply_.add(THINK_TANK_FUND_TOKENS);
        emit Transfer(0x0, thinkTankFundAddress, THINK_TANK_FUND_TOKENS);

        /// 20% allocated to the Naoris Team and Advisors Fund
        balances[owner] = balances[owner].add(NAORIS_TEAM_TOKENS);
        totalSupply_ = totalSupply_.add(NAORIS_TEAM_TOKENS);
        emit Transfer(0x0, owner, NAORIS_TEAM_TOKENS);

        /// tokens of the Board Bonus locked until 1st of May 2019
        TokenTimelock lockedTreasuryTokens = new TokenTimelock(this, lockedBoardBonusAddress, date01May2019);
        treasuryTimelockAddress = address(lockedTreasuryTokens);
        balances[treasuryTimelockAddress] = balances[treasuryTimelockAddress].add(LOCKED_BOARD_BONUS_TOKENS);
        totalSupply_ = totalSupply_.add(LOCKED_BOARD_BONUS_TOKENS);
        emit Transfer(0x0, treasuryTimelockAddress, LOCKED_BOARD_BONUS_TOKENS);

        require(totalSupply_ <= TOKENS_HARD_CAP);

        tokenSaleClosed = true;
    }

    function tokenDiscountPercentage(address _owner) public view returns (uint256 percent) {
        if(balanceOf(_owner) >= 1000000 * 10**decimals) {
            return 50;
        } else if(balanceOf(_owner) >= 500000 * 10**decimals) {
            return 30;
        } else if(balanceOf(_owner) >= 250000 * 10**decimals) {
            return 25;
        } else if(balanceOf(_owner) >= 100000 * 10**decimals) {
            return 20;
        } else if(balanceOf(_owner) >= 50000 * 10**decimals) {
            return 15;
        } else if(balanceOf(_owner) >= 10000 * 10**decimals) {
            return 10;
        } else if(balanceOf(_owner) >= 1000 * 10**decimals) {
            return 5;
        } else {
            return 0;
        }
    }

    function getTotalDiscount(address _owner) public view returns (uint256 percent) {
        uint256 total = 0;

        total += tokenDiscountPercentage(_owner);
        total += referralDiscountPercentage(_owner);

        return (total > 60) ? 60 : total;
    }

    /// @dev Trading limited - requires the token sale to have closed
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(tokenSaleClosed) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }

    /// @dev Trading limited - requires the token sale to have closed
    function transfer(address _to, uint256 _value) public returns (bool) {
        if(tokenSaleClosed || msg.sender == referalAirdropsTokensAddress
                        || msg.sender == saleTeamAddress) {
            return super.transfer(_to, _value);
        }
        return false;
    }
}