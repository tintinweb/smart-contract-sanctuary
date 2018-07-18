pragma solidity ^0.4.24;
// Developed by Phenom.Team <info@phenom.team>

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

contract ERC20 {
    uint public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    function balanceOf(address _owner) view returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    function transferFrom(address _from, address _to, uint _value) returns (bool);
    function approve(address _spender, uint _value) returns (bool);
    function allowance(address _owner, address _spender) view returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

contract Ownable {
    address public owner;

    constructor() public {
        owner = tx.origin;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, &#39;ownership is required&#39;);
        _;
    }
}

contract BaseTokenVesting is Ownable() {
    using SafeMath for uint;

    address public beneficiary;
    ERC20 public token;

    bool public vestingHasStarted;
    uint public start;
    uint public cliff;
    uint public vestingPeriod;

    uint public released;

    event Released(uint _amount);

    constructor(
		address _benificiary,
		uint _cliff,
		uint _vestingPeriod,
		address _token
	) internal 
	{
        require(_benificiary != address(0), &#39;can not send to zero-address&#39;);

        beneficiary = _benificiary;
        cliff = _cliff;
        vestingPeriod = _vestingPeriod;
        token = ERC20(_token);
    }

    function startVesting() public onlyOwner {
        vestingHasStarted = true;
        start = now;
        cliff = cliff.add(start);
    }

    function sendTokens(address _to, uint _amount) public onlyOwner {
        require(vestingHasStarted == false, &#39;send tokens only if vesting has not been started&#39;);
        require(token.transfer(_to, _amount), &#39;token.transfer has failed&#39;);
    }

    function release() public;

    function releasableAmount() public view returns (uint _amount);

    function vestedAmount() public view returns (uint _amount);
}

contract TokenVestingWithConstantPercent is BaseTokenVesting {

    uint public periodPercent;

    constructor(
        address _benificiary,
        uint _cliff,
        uint _vestingPeriod,
        address _tokenAddress,
        uint _periodPercent
    ) 
        BaseTokenVesting(_benificiary, _cliff, _vestingPeriod, _tokenAddress)
        public 
    {
        periodPercent = _periodPercent;
    }

    function release() public {
        require(vestingHasStarted, &#39;vesting has not started&#39;);
        uint unreleased = releasableAmount();

        require(unreleased > 0, &#39;released amount has to be greter than zero&#39;);
        require(token.transfer(beneficiary, unreleased), &#39;revert on transfer failure&#39;);
        released = released.add(unreleased);
        emit Released(unreleased);
    }


    function releasableAmount() public view returns (uint _amount) {
        _amount = vestedAmount().sub(released);
    }

    function vestedAmount() public view returns (uint _amount) {
        uint currentBalance = token.balanceOf(this);
        uint totalBalance = currentBalance.add(released);

        if (now < cliff || !vestingHasStarted) {
            _amount = 0;
        }
        else if (now.sub(cliff).div(vestingPeriod).mul(periodPercent) > 100) {
            _amount = totalBalance;
        }
        else {
            _amount = totalBalance.mul(now.sub(cliff).div(vestingPeriod).mul(periodPercent)).div(100);
        }
    }

    

}

contract TokenVestingWithFloatingPercent is BaseTokenVesting {
	
    uint[] public periodPercents;

    constructor(
        address _benificiary,
        uint _cliff,
        uint _vestingPeriod,
        address _tokenAddress,
        uint[] _periodPercents
    ) 
        BaseTokenVesting(_benificiary, _cliff, _vestingPeriod, _tokenAddress)
        public 
    {
        uint sum = 0;
        for (uint i = 0; i < _periodPercents.length; i++) {
            sum = sum.add(_periodPercents[i]);
        }
        require(sum == 100, &#39;percentage sum must be equal to 100&#39;);

        periodPercents = _periodPercents;
    }

    function release() public {
        require(vestingHasStarted, &#39;vesting has not started&#39;);
        uint unreleased = releasableAmount();

        require(unreleased > 0, &#39;released amount has to be greter than zero&#39;);
        require(token.transfer(beneficiary, unreleased), &#39;revert on transfer failure&#39;);
        released = released.add(unreleased);
        emit Released(unreleased);	
    }

    function releasableAmount() public view returns (uint _amount) {
        _amount = vestedAmount().sub(released);
    }

    function vestedAmount() public view returns (uint _amount) {
        uint currentBalance = token.balanceOf(this);
        uint totalBalance = currentBalance.add(released);

        if (now < cliff || !vestingHasStarted) {
            _amount = 0;
        }
        else {
            uint _periodPercentsIndex = now.sub(cliff).div(vestingPeriod);
            if (_periodPercentsIndex > periodPercents.length.sub(1)) {
                _amount = totalBalance;
            }
            else {
                if (_periodPercentsIndex >= 1) {
                    uint totalPercent = 0;
                    for (uint i = 0; i < _periodPercentsIndex - 1; i++) {
                        totalPercent = totalPercent + periodPercents[i];
                    }
                    _amount = totalBalance.mul(totalPercent).div(100);
                }
            }
        }
    }

}

contract TokenVestingFactory is Ownable() {
    event VestingContractCreated(address indexed _creator, address indexed _contract);

    mapping(address => address) public investorToVesting;

    function createVestingContractWithConstantPercent(
        address _benificiary,
        uint _cliff,
        uint _vestingPeriod,
        address _tokenAddress,
        uint _periodPercent
	)
	public
    onlyOwner
	returns (address vestingContract)
	{		
        vestingContract = new TokenVestingWithConstantPercent(
			_benificiary,
			_cliff,
			_vestingPeriod,
			_tokenAddress,
			_periodPercent
        );
        investorToVesting[_benificiary] = vestingContract;
        emit VestingContractCreated(tx.origin, vestingContract);
    }

    function createVestingContractWithFloatingPercent(
        address _benificiary,
        uint _cliff,
        uint _vestingPeriod,
        address _tokenAddress,
        uint[] _periodPercents	
	)
	public
    onlyOwner
	returns (address vestingContract) 
	{
        vestingContract = new TokenVestingWithFloatingPercent(
            _benificiary, 
            _cliff,
            _vestingPeriod,
            _tokenAddress,
            _periodPercents
        );
        investorToVesting[_benificiary] = vestingContract;
        emit VestingContractCreated(tx.origin, vestingContract);
    }
}