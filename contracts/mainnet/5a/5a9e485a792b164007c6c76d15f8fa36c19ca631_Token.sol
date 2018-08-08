pragma solidity ^0.4.20;

contract GenesisProtected {
    modifier addrNotNull(address _address) {
        require(_address != address(0));
        _;
    }
}


// ----------------------------------------------------------------------------
// The original code is taken from:
// https://github.com/OpenZeppelin/zeppelin-solidity:
//     master branch from zeppelin-solidity/contracts/ownership/Ownable.sol
// Changed function name: transferOwnership -> setOwner.
// Added inheritance from GenesisProtected (address != 0x0).
// setOwner refactored for emitting after owner replacing.
// ----------------------------------------------------------------------------

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is GenesisProtected {
    address public owner;

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
     * @dev Allows the current owner to transfer control of the contract to a _new.
     * @param a The address to transfer ownership to.
     */
    function setOwner(address a) external onlyOwner addrNotNull(a) {
        owner = a;
        emit OwnershipReplaced(msg.sender, a);
    }

    event OwnershipReplaced(
        address indexed previousOwner,
        address indexed newOwner
    );
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// The original code is taken from:
// https://theethereum.wiki/w/index.php/ERC20_Token_Standard
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner)
        public constant returns (uint balance);
    function allowance(address tokenOwner, address spender)
        public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens)
        public returns (bool success);
    function transferFrom(address from, address to, uint tokens)
        public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint tokens
    );
}

contract Enums {
    // Type for mapping uint (index) => name for baskets types described in WP
    enum BasketType {
        unknown, // 0 unknown
        team, // 1 Team
        foundation, // 2 Foundation
        arr, // 3 Advertisement, Referral program, Reward
        advisors, // 4 Advisors
        bounty, // 5 Bounty
        referral, // 6 Referral
        referrer // 7 Referrer
    }
}


contract WPTokensBaskets is Ownable, Enums {
    // This mapping holds all accounts ever used as baskets forever
    mapping (address => BasketType) internal types;

    // Baskets for tokens
    address public team;
    address public foundation;
    address public arr;
    address public advisors;
    address public bounty;

    // Public constructor
    function WPTokensBaskets(
        address _team,
        address _foundation,
        address _arr,
        address _advisors,
        address _bounty
    )
        public
    {
        setTeam(_team);
        setFoundation(_foundation);
        setARR(_arr);
        setAdvisors(_advisors);
        setBounty(_bounty);
    }

    // Fallback function - do not apply any ether to this contract.
    function () external payable {
        revert();
    }

    // Last resort to return ether.
    // See the last warning at
    // http://solidity.readthedocs.io/en/develop/contracts.html#fallback-function
    // for such cases.
    function transferEtherTo(address a) external onlyOwner addrNotNull(a) {
        a.transfer(address(this).balance);
    }

    function typeOf(address a) public view returns (BasketType) {
        return types[a];
    }

    // Return truth if given address is not registered as token basket.
    function isUnknown(address a) public view returns (bool) {
        return types[a] == BasketType.unknown;
    }

    function isTeam(address a) public view returns (bool) {
        return types[a] == BasketType.team;
    }

    function isFoundation(address a) public view returns (bool) {
        return types[a] == BasketType.foundation;
    }

    function setTeam(address a) public onlyOwner addrNotNull(a) {
        require(isUnknown(a));
        types[team = a] = BasketType.team;
    }

    function setFoundation(address a) public onlyOwner addrNotNull(a) {
        require(isUnknown(a));
        types[foundation = a] = BasketType.foundation;
    }

    function setARR(address a) public onlyOwner addrNotNull(a) {
        require(isUnknown(a));
        types[arr = a] = BasketType.arr;
    }

    function setAdvisors(address a) public onlyOwner addrNotNull(a) {
        require(isUnknown(a));
        types[advisors = a] = BasketType.advisors;
    }

    function setBounty(address a) public onlyOwner addrNotNull(a) {
        require(types[a] == BasketType.unknown);
        types[bounty = a] = BasketType.bounty;
    }
}

// ----------------------------------------------------------------------------
// The original code is taken from:
// https://github.com/OpenZeppelin/zeppelin-solidity:
//     master branch from zeppelin-solidity/contracts/math/SafeMath.sol
// ----------------------------------------------------------------------------

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0)
            return 0;
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
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is
     * greater than minuend).
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


contract Token is Ownable, ERC20Interface, Enums {
    using SafeMath for uint;

    // Token full name
    string private constant NAME = "EnvisionX EXCHAIN Token";
    // Token symbol name
    string private constant SYMBOL = "EXT";
    // Token max fraction, in decimal signs after the point
    uint8 private constant DECIMALS = 18;

    // Tokens max supply, in EXTwei
    uint public constant MAX_SUPPLY = 3000000000 * (10**uint(DECIMALS));

    // Tokens balances map
    mapping(address => uint) internal balances;

    // Maps with allowed amounts fot TransferFrom
    mapping (address => mapping (address => uint)) internal allowed;

    // Total amount of issued tokens, in EXTwei
    uint internal _totalSupply;

    // Map with Ether founds amount by address (using when refunds)
    mapping(address => uint) internal etherFunds;
    uint internal _earnedFunds;
    // Map with refunded addreses (Black List)
    mapping(address => bool) internal refunded;

    // Address of sale agent (a contract) which can mint new tokens
    address public mintAgent;

    // Token transfer allowed only when token minting is finished
    bool public isMintingFinished = false;
    // When minting was finished
    uint public mintingStopDate;

    // Total amount of tokens minted to team basket, in EXTwei.
    // This will not include tokens, transferred to team basket
    // after minting is finished.
    uint public teamTotal;
    // Amount of tokens spent by team in first 96 weeks since
    // minting finish date. Used to calculate team spend
    // restrictions according to ICO White Paper.
    uint public spentByTeam;

    // Address of WPTokensBaskets contract
    WPTokensBaskets public wpTokensBaskets;

    // Constructor
    function Token(WPTokensBaskets baskets) public {
        wpTokensBaskets = baskets;
        mintAgent = owner;
    }

    // Fallback function - do not apply any ether to this contract.
    function () external payable {
        revert();
    }

    // Last resort to return ether.
    // See the last warning at
    // http://solidity.readthedocs.io/en/develop/contracts.html#fallback-function
    // for such cases.
    function transferEtherTo(address a) external onlyOwner addrNotNull(a) {
        a.transfer(address(this).balance);
    }

    /**
    ----------------------------------------------------------------------
    ERC20 Interface implementation
    */

    // Return token full name
    function name() public pure returns (string) {
        return NAME;
    }

    // Return token symbol name
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

    // Return amount of decimals after point
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    // Return total amount of issued tokens, in EXTwei
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    // Return account balance in tokens (in EXTwei)
    function balanceOf(address _address) public constant returns (uint) {
        return balances[_address];
    }

    // Transfer tokens to another account
    function transfer(address to, uint value)
        public
        addrNotNull(to)
        returns (bool)
    {
        if (balances[msg.sender] < value)
            return false;
        if (isFrozen(wpTokensBaskets.typeOf(msg.sender), value))
            return false;
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        saveTeamSpent(msg.sender, value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    // Transfer tokens from one account to another,
    // using permissions defined with approve() method.
    function transferFrom(address from, address to, uint value)
        public
        addrNotNull(to)
        returns (bool)
    {
        if (balances[from] < value)
            return false;
        if (allowance(from, msg.sender) < value)
            return false;
        if (isFrozen(wpTokensBaskets.typeOf(from), value))
            return false;
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        saveTeamSpent(from, value);
        emit Transfer(from, to, value);
        return true;
    }

    // Allow to transfer given amount of tokens (in EXTwei)
    // to account which is not owner.
    function approve(address spender, uint value) public returns (bool) {
        if (msg.sender == spender)
            return false;
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // Return amount of tokens (in EXTwei) which allowed to
    // be transferred by non-owner spender
    function allowance(address _owner, address spender)
        public
        constant
        returns (uint)
    {
        return allowed[_owner][spender];
    }

    /**
    ----------------------------------------------------------------------
    Other methods
    */

    // Return account funds in ether (in wei)
    function etherFundsOf(address _address) public constant returns (uint) {
        return etherFunds[_address];
    }

    // Return total amount of funded ether, in wei
    function earnedFunds() public constant returns (uint) {
        return _earnedFunds;
    }

    // Return true if given address have been refunded
    function isRefunded(address _address) public view returns (bool) {
        return refunded[_address];
    }

    // Set new address of sale agent contract.
    // Will be called for each sale stage: PrivateSale, PreSale, MainSale.
    function setMintAgent(address a) public onlyOwner addrNotNull(a) {
        emit MintAgentReplaced(mintAgent, a);
        mintAgent = a;
    }

    // Interface for sale agent contract - mint new tokens
    function mint(address to, uint256 extAmount, uint256 etherAmount) public {
        require(!isMintingFinished);
        require(msg.sender == mintAgent);
        require(!refunded[to]);
        _totalSupply = _totalSupply.add(extAmount);
        require(_totalSupply <= MAX_SUPPLY);
        balances[to] = balances[to].add(extAmount);
        if (wpTokensBaskets.isUnknown(to)) {
            _earnedFunds = _earnedFunds.add(etherAmount);
            etherFunds[to] = etherFunds[to].add(etherAmount);
        } else if (wpTokensBaskets.isTeam(to)) {
            teamTotal = teamTotal.add(extAmount);
        }
        emit Mint(to, extAmount);
        emit Transfer(msg.sender, to, extAmount);
    }

    // Destroy minted tokens and refund ether spent by investor.
    // Used in AML (Anti Money Laundering) workflow.
    // Will be called only by humans because there is no way
    // to withdraw crowdfunded ether from Beneficiary account
    // from context of this account.
    // Important note: all tokens minted to team, foundation etc.
    // will NOT be burned, because they in general are spent
    // during the sale and its too expensive to track all these
    // transactions.
    function burnTokensAndRefund(address _address)
        external
        payable
        addrNotNull(_address)
        onlyOwner()
    {
        require(msg.value > 0 && msg.value == etherFunds[_address]);
        _totalSupply = _totalSupply.sub(balances[_address]);
        balances[_address] = 0;
        _earnedFunds = _earnedFunds.sub(msg.value);
        etherFunds[_address] = 0;
        refunded[_address] = true;
        _address.transfer(msg.value);
    }

    // Stop tokens minting forever.
    function finishMinting() external onlyOwner {
        require(!isMintingFinished);
        isMintingFinished = true;
        mintingStopDate = now;
        emit MintingFinished();
    }

    /**
    ----------------------------------------------------------------------
    Tokens freeze logic, according to ICO White Paper
    */

    // Return truth if given _value amount of tokens (in EXTwei)
    // cannot be transferred from account due to spend restrictions
    // defined in ICO White Paper.
    // !!!Caveat of current implementaion!!!
    // Say,
    //  1. There was 100 tokens minted to the team basket;
    //  2. Minting was finished and 24 weeks elapsed, and now
    //    team can spend up to 25 tokens till next 24 weeks;
    //  3. Someone transfers another 100 tokens to the team basket;
    //  4. ...
    // Problem is, actually, you can&#39;t spend any of these extra 100
    // tokens until 96 weeks will elapse since minting finish date.
    // That&#39;s because after next 24 weeks will be unlocked only
    // 25 tokens more (25% of *minted* tokens) and so on.
    // So, DO NOT send tokens to the team basket until 96 weeks elapse!
    function isFrozen(
        BasketType _basketType,
        uint _value
    )
        public view returns (bool)
    {
        if (!isMintingFinished) {
            // Allow spend only after minting is finished
            return true;
        }
        if (_basketType == BasketType.foundation) {
            // Allow to spend foundation tokens only after
            // 48 weeks after minting is finished
            return now < mintingStopDate + 48 weeks;
        }
        if (_basketType == BasketType.team) {
            // Team allowed to spend tokens:
            //  25%  - after minting finished date + 24 weeks;
            //  50%  - after minting finished date + 48 weeks;
            //  75%  - after minting finished date + 72 weeks;
            //  100% - after minting finished date + 96 weeks.
            if (mintingStopDate + 96 weeks <= now) {
                return false;
            }
            if (now < mintingStopDate + 24 weeks)
                return true;
            // Calculate fraction as percents multipled to 10^10.
            // Without this owner will be able to spend fractions
            // less than 1% per transaction.
            uint fractionSpent =
                spentByTeam.add(_value).mul(1000000000000).div(teamTotal);
            if (now < mintingStopDate + 48 weeks) {
                return 250000000000 < fractionSpent;
            }
            if (now < mintingStopDate + 72 weeks) {
                return 500000000000 < fractionSpent;
            }
            // from 72 to 96 weeks elapsed
            return 750000000000 < fractionSpent;
        }
        // No restrictions for other token holders
        return false;
    }

    // Save amount of spent tokens by team till 96 weeks after minting
    // finish date. This is vital because without the check we&#39;ll eventually
    // overflow the uint256.
    function saveTeamSpent(address _owner, uint _value) internal {
        if (wpTokensBaskets.isTeam(_owner)) {
            if (now < mintingStopDate + 96 weeks)
                spentByTeam = spentByTeam.add(_value);
        }
    }

    /**
    ----------------------------------------------------------------------
    Events
    */

    // Emitted when mint agent (address of a sale contract)
    // replaced with new one
    event MintAgentReplaced(
        address indexed previousMintAgent,
        address indexed newMintAgent
    );

    // Emitted when new tokens were created and funded to account
    event Mint(address indexed to, uint256 amount);

    // Emitted when tokens minting is finished.
    event MintingFinished();
}