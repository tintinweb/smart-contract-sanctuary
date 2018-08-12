pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

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
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract BlockchainToken is StandardToken, Ownable {

    string public constant name = &#39;Blockchain Token 2.0&#39;;

    string public constant symbol = &#39;BCT&#39;;

    uint32 public constant decimals = 18;

    /**
     *  how many USD cents for 1 * 10^18 token
     */
    uint public price = 210;

    function setPrice(uint _price) onlyOwner public {
        price = _price;
    }

    uint256 public INITIAL_SUPPLY = 21000000 * 1 ether;

    /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 value);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(
        address _to,
        uint256 _amount
    )
        public
        hasMintPermission
        canMint
        returns (bool)
    {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _addr The address that will have _amount of tokens burned
     * @param _value The amount of token to be burned.
     */
    function burn(
        address _addr,
        uint256 _value
    )
        public onlyOwner
    {
        _burn(_addr, _value);
    }

    function _burn(
        address _who,
        uint256 _value
    )
        internal
    {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract WealthBuilderToken is MintableToken {

    string public name = &#39;Wealth Builder Token&#39;;

    string public symbol = &#39;WBT&#39;;

    uint32 public decimals = 18;

    /**
     *  how many {tokens*10^(-18)} get per 1wei
     */
    uint public rate = 10 ** 7;
    /**
     *  multiplicator for rate
     */
    uint public mrate = 10 ** 7;

    function setRate(uint _rate) onlyOwner public {
        rate = _rate;
    }

}

contract Data is Ownable {

    // node => its parent
    mapping (address => address) private parent;

    // node => its status
    mapping (address => uint8) public statuses;

    // node => sum of all his child deposits in USD cents
    mapping (address => uint) public referralDeposits;

    // client => balance in wei*10^(-6) available for withdrawal
    mapping(address => uint256) private balances;

    // investor => balance in wei*10^(-6) available for withdrawal
    mapping(address => uint256) private investorBalances;

    function parentOf(address _addr) public constant returns (address) {
        return parent[_addr];
    }

    function balanceOf(address _addr) public constant returns (uint256) {
        return balances[_addr] / 1000000;
    }

    function investorBalanceOf(address _addr) public constant returns (uint256) {
        return investorBalances[_addr] / 1000000;
    }

    /**
     * @dev The Data constructor to set up the first depositer
     */
    constructor() public {
        // DirectorOfRegion - 7
        statuses[msg.sender] = 7;
    }

    function addBalance(address _addr, uint256 amount) onlyOwner public {
        balances[_addr] += amount;
    }

    function subtrBalance(address _addr, uint256 amount) onlyOwner public {
        require(balances[_addr] >= amount);
        balances[_addr] -= amount;
    }

    function addInvestorBalance(address _addr, uint256 amount) onlyOwner public {
        investorBalances[_addr] += amount;
    }

    function subtrInvestorBalance(address _addr, uint256 amount) onlyOwner public {
        require(investorBalances[_addr] >= amount);
        investorBalances[_addr] -= amount;
    }

    function addReferralDeposit(address _addr, uint256 amount) onlyOwner public {
        referralDeposits[_addr] += amount;
    }

    function subtrReferralDeposit(address _addr, uint256 amount) onlyOwner public {
        referralDeposits[_addr] -= amount;
    }

    function setStatus(address _addr, uint8 _status) onlyOwner public {
        statuses[_addr] = _status;
    }

    function setParent(address _addr, address _parent) onlyOwner public {
        parent[_addr] = _parent;
    }

}

contract Declaration {

    // threshold in USD => status
    mapping (uint => uint8) statusThreshold;

    // status => (depositsNumber => percentage / 10)
    mapping (uint8 => mapping (uint16 => uint256)) feeDistribution;

    // status thresholds in USD
    uint[8] thresholds = [
    0, 5000, 35000, 150000, 500000, 2500000, 5000000, 10000000
    ];

    uint[5] referralFees = [50, 30, 20, 10, 5];
    uint[5] serviceFees = [25, 20, 15, 10, 5];


    /**
     * @dev The Declaration constructor to define some constants
     */
    constructor() public {
        setFeeDistributionsAndStatusThresholds();
    }


    /**
     * @dev Set up fee distribution & status thresholds
     */
    function setFeeDistributionsAndStatusThresholds() private {
        // Agent - 0
        setFeeDistributionAndStatusThreshold(0, [uint16(120), uint16(80), uint16(50), uint16(20), uint16(10)], thresholds[0]);
        // SilverAgent - 1
        setFeeDistributionAndStatusThreshold(1, [uint16(160), uint16(100), uint16(60), uint16(30), uint16(20)], thresholds[1]);
        // Manager - 2
        setFeeDistributionAndStatusThreshold(2, [uint16(200), uint16(120), uint16(80), uint16(40), uint16(25)], thresholds[2]);
        // ManagerOfGroup - 3
        setFeeDistributionAndStatusThreshold(3, [uint16(250), uint16(150), uint16(100), uint16(50), uint16(30)], thresholds[3]);
        // ManagerOfRegion - 4
        setFeeDistributionAndStatusThreshold(4, [300, 180, 120, 60, 35], thresholds[4]);
        // Director - 5
        setFeeDistributionAndStatusThreshold(5, [350, 210, 140, 70, 40], thresholds[5]);
        // DirectorOfGroup - 6
        setFeeDistributionAndStatusThreshold(6, [400, 240, 160, 80, 45], thresholds[6]);
        // DirectorOfRegion - 7
        setFeeDistributionAndStatusThreshold(7, [500, 300, 200, 100, 50], thresholds[7]);
    }


    /**
     * @dev Set up specific fee and status threshold
     * @param _st The status to set up for
     * @param _percentages Array of pecentages, which should go to member
     * @param _threshold The minimum amount of sum of children deposits to get
     *                   the status _st
     */
    function setFeeDistributionAndStatusThreshold(
        uint8 _st,
        uint16[5] _percentages,
        uint _threshold
    )
        private
    {
        statusThreshold[_threshold] = _st;
        for (uint8 i = 0; i < _percentages.length; i++) {
            feeDistribution[_st][i] = _percentages[i];
        }
    }

}

contract Referral is Declaration, Ownable {

    using SafeMath for uint;

    // reference to WBT token contract
    WealthBuilderToken private wbtToken;

    // reference to BCT2.0 token contract
    BlockchainToken private bctToken;

    // reference to data contract
    Data private data;

    /**
     *  how many USD cents get per ETH
     */
    uint public ethUsdRate;

    /**
     * @dev The Referral constructor to set up the first depositer,
     * reference to system wbt token, bct token, data and set ethUsdRate
     */
    constructor(
        uint _ethUsdRate,
        address _wbtToken,
        address _bctToken,
        address _data
    )
        public
    {
        ethUsdRate = _ethUsdRate;

        // instantiate wbtToken & data contracts
        wbtToken = WealthBuilderToken(_wbtToken);
        bctToken = BlockchainToken(_bctToken);
        data = Data(_data);
    }

    /**
     * @dev Callback function
     */
    function() payable public {
    }

    /**
     * @dev invest wbt token function
     * @param _client to transfer WBT token
     * @param _depositsCount num of the deposit
     */
    function invest(
        address _client,
        uint8 _depositsCount
    )
        payable public
    {
        uint amount = msg.value;

        // if less then 5 deposits
        if (_depositsCount < 5) {

            uint serviceFee;

            serviceFee = amount * serviceFees[_depositsCount];

            uint referralFee = amount * referralFees[_depositsCount];

            // distribute deposit fee among users above on the branch & update users&#39; statuses
            distribute(data.parentOf(_client), 0, _depositsCount, amount);

            // update balance & number of deposits of user
            uint active = (amount * 100).sub(referralFee).sub(serviceFee);

            wbtToken.mint(_client, active / 100 * wbtToken.rate() / wbtToken.mrate());

            // update owner`s balance
            data.addBalance(owner, serviceFee * 10000);
        } else {
            wbtToken.mint(_client, amount * wbtToken.rate() / wbtToken.mrate());
        }
    }

    /**
     * @dev invest bct token function
     * @param _client to transfer BCT token
     */
    function investBct(
        address _client
    )
        public payable
    {
        uint amount = msg.value;
        // distribute deposit fee among users above on the branch & update users&#39; statuses
        distribute(data.parentOf(_client), 0, 0, amount);

        bctToken.transfer(_client, amount * ethUsdRate / bctToken.price());
    }


    /**
     * @dev Recursively distribute deposit fee between parents
     * @param _node Parent address
     * @param _prevPercentage The percentage for previous parent
     * @param _depositsCount Count of depositer deposits
     * @param _amount The amount of deposit
     */
    function distribute(
        address _node,
        uint _prevPercentage,
        uint8 _depositsCount,
        uint _amount
    )
        private
    {
        address node = _node;
        uint prevPercentage = _prevPercentage;

        // distribute deposit fee among users above on the branch & update users&#39; statuses
        while(node != address(0)) {
            uint8 status = data.statuses(node);

            // count fee percentage of current node
            uint nodePercentage = feeDistribution[status][_depositsCount];
            uint percentage = nodePercentage.sub(prevPercentage);
            data.addBalance(node, _amount * percentage * 1000);

            //update refferals sum amount
            data.addReferralDeposit(node, _amount * ethUsdRate / 10**18);

            //update status
            updateStatus(node, status);

            node = data.parentOf(node);
            prevPercentage = nodePercentage;
        }
    }


    /**
     * @dev Update node status if children sum amount is enough
     * @param _node Node address
     * @param _status Node current status
     */
    function updateStatus(
        address _node,
        uint8 _status
    )
        private
    {
        uint refDep = data.referralDeposits(_node);

        for (uint i = thresholds.length - 1; i > _status; i--) {
            uint threshold = thresholds[i] * 100;

            if (refDep >= threshold) {
                data.setStatus(_node, statusThreshold[thresholds[i]]);
                break;
            }
        }
    }


    /**
     * @dev Set wbtToken exchange rate
     * @param _rate wbt/eth rate
     */
    function setRate(
        uint _rate
    )
        onlyOwner public
    {
        wbtToken.setRate(_rate);
    }


    /**
     * @dev Set bctToken price
     * @param _price bct/usd rate
     */
    function setPrice(
        uint _price
    )
        onlyOwner public
    {
        bctToken.setPrice(_price);
    }


    /**
     * @dev Set ETH exchange rate
     * @param _ethUsdRate eth/usd rate
     */
    function setEthUsdRate(
        uint _ethUsdRate
    )
        onlyOwner public
    {
        ethUsdRate = _ethUsdRate;
    }


    /**
     * @dev Add new child
     * @param _inviter parent
     * @param _invitee child
     */
    function invite(
        address _inviter,
        address _invitee
    )
        public onlyOwner
    {
        data.setParent(_invitee, _inviter);
        // Agent - 0
        data.setStatus(_invitee, 0);
    }


    /**
     * @dev Set _status for _addr
     * @param _addr address
     * @param _status ref. status
     */
    function setStatus(
        address _addr,
        uint8 _status
    )
        public onlyOwner
    {
        data.setStatus(_addr, _status);
    }


    /**
     * @dev Withdraw _amount for _addr
     * @param _addr withdrawal address
     * @param _amount withdrawal amount
     * @param investor is investor
     */
    function withdraw(
        address _addr,
        uint256 _amount,
        bool investor
    )
        public onlyOwner
    {
        uint amount = investor ? data.investorBalanceOf(_addr) : data.balanceOf(_addr);
        require(amount >= _amount && address(this).balance >= _amount);

        if (investor) {
            data.subtrInvestorBalance(_addr, _amount * 1000000);
        } else {
            data.subtrBalance(_addr, _amount * 1000000);
        }

        _addr.transfer(_amount);
    }


    /**
     * @dev Withdraw contract balance to _addr
     * @param _addr withdrawal address
     */
    function withdrawOwner(
        address _addr,
        uint256 _amount
    )
        public onlyOwner
    {
        require(address(this).balance >= _amount);
        _addr.transfer(_amount);
    }


    /**
     * @dev Withdraw corresponding amount of ETH to _addr and burn _value tokens
     * @param _addr buyer address
     * @param _amount amount of tokens to buy
     */
    function transferBctToken(
        address _addr,
        uint _amount
    )
        onlyOwner public
    {
        require(bctToken.balanceOf(this) >= _amount);
        bctToken.transfer(_addr, _amount);
    }


    /**
     * @dev Withdraw corresponding amount of ETH to _addr and burn _value tokens
     * @param _addr withdrawal address
     * @param _amount amount of tokens to sell
     */
    function withdrawWbtToken(
        address _addr,
        uint256 _amount
    )
        onlyOwner public
    {
        wbtToken.burn(_addr, _amount);
        uint256 etherValue = _amount * wbtToken.mrate() / wbtToken.rate();
        _addr.transfer(etherValue);
    }


    /**
     * @dev Transfer ownership of wbtToken contract to _addr
     * @param _addr address
     */
    function transferTokenOwnership(
        address _addr
    )
        onlyOwner public
    {
        wbtToken.transferOwnership(_addr);
    }


    /**
     * @dev Transfer ownership of data contract to _addr
     * @param _addr address
     */
    function transferDataOwnership(
        address _addr
    )
        onlyOwner public
    {
        data.transferOwnership(_addr);
    }

}