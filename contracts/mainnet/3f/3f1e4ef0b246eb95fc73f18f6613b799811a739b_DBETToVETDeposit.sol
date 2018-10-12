pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// Intermediate deposit contract for DBET V1 and V2 tokens.
// Token holders send tokens to this contract to in-turn receive DBET tokens on VET.
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract DBETToVETDeposit {

    using SafeMath for uint256;

    // DBET team address
    address public dbetTeam;
    // DBET V1 token contract
    ERC20 public dbetV1;
    // DBET V2 token contract
    ERC20 public dbetV2;

    // Emergency withdrawals incase something goes wrong
    bool public emergencyWithdrawalsEnabled;
    // If deposits are finalized, emergency withdrawals will cease to work
    bool public finalizedDeposits;
    // Number of deposits made
    uint256 public depositIndex;

    // Mapping of tokens deposited by addresses
    // isV2 => (address => amount)
    mapping(bool => mapping(address => uint256)) public depositedTokens;

    event LogTokenDeposit(
        bool isV2,
        address _address,
        address VETAddress,
        uint256 amount,
        uint256 index
    );
    event LogEmergencyWithdraw(
        bool isV2,
        address _address,
        uint256 amount
    );

    constructor(address v1, address v2) public {
        dbetTeam = msg.sender;
        dbetV1 = ERC20(v1);
        dbetV2 = ERC20(v2);
    }

    modifier isDbetTeam() {
        require(msg.sender == dbetTeam);
        _;
    }

    modifier areWithdrawalsEnabled() {
        require(emergencyWithdrawalsEnabled && !finalizedDeposits);
        _;
    }

    // Returns the appropriate token contract
    function getToken(bool isV2) internal returns (ERC20) {
        if (isV2)
            return dbetV2;
        else
            return dbetV1;
    }

    // Deposit V1/V2 tokens into the contract
    function depositTokens(
        bool isV2,
        uint256 amount,
        address VETAddress
    )
    public {
        require(amount > 0);
        require(VETAddress != 0);
        require(getToken(isV2).balanceOf(msg.sender) >= amount);
        require(getToken(isV2).allowance(msg.sender, address(this)) >= amount);

        depositedTokens[isV2][msg.sender] = depositedTokens[isV2][msg.sender].add(amount);

        require(getToken(isV2).transferFrom(msg.sender, address(this), amount));

        emit LogTokenDeposit(
            isV2,
            msg.sender,
            VETAddress,
            amount,
            depositIndex++
        );
    }

    function enableEmergencyWithdrawals () public
    isDbetTeam {
        emergencyWithdrawalsEnabled = true;
    }

    function finalizeDeposits () public
    isDbetTeam {
        finalizedDeposits = true;
    }

    // Withdraw deposited tokens if emergency withdrawals have been enabled
    function emergencyWithdraw(bool isV2) public
    areWithdrawalsEnabled {
        require(depositedTokens[isV2][msg.sender] > 0);

        uint256 amount = depositedTokens[isV2][msg.sender];

        depositedTokens[isV2][msg.sender] = 0;

        require(getToken(isV2).transfer(msg.sender, amount));

        emit LogEmergencyWithdraw(isV2, msg.sender, amount);
    }

}