pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
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
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
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
 * @title ICO Rocket Fuel contract for LastMile service.
 */
contract IcoRocketFuel is Ownable {

    using SafeMath for uint256;

    // Crowdsale states
    enum States {Active, Refunding, Closed}

    struct Crowdsale {
        address owner;        // Crowdsale proposer
        address refundWallet; // Tokens for sale will refund to this wallet
        uint256 cap;          // Hard cap
        uint256 goal;         // Soft cap
        uint256 raised;       // wei raised
        uint256 rate;         // Sell rate. Set to 10 means 1 Wei = 10 token units
        uint256 minInvest;    // Minimum investment in Wei
        uint256 closingTime;  // Crowdsale closing time
        bool earlyClosure;    // Whether allow early closure
        uint8 commission;     // Commission percentage. Set to 10 means 10%
        States state;         // Crowdsale current state
    }

    // When crowdsale is closed, commissions will transfer to this wallet.
    address public commissionWallet;    

    // Use crowdsales[token] to get corresponding crowdsale.
    // The token is an ERC20 token address.
    mapping(address => Crowdsale) public crowdsales;

    // Use deposits[buyer][token] to get deposited Wei for buying the token.
    // The buyer is the buyer address.
    // The token is an ERC20 token address.
    mapping (address => mapping(address => uint256)) public deposits;

    modifier onlyCrowdsaleOwner(address _token) {
        require(
            msg.sender == crowdsales[_token].owner,
            "Failed to call function due to permission denied."
        );
        _;
    }

    modifier inState(address _token, States _state) {
        require(
            crowdsales[_token].state == _state,
            "Failed to call function due to crowdsale is not in right state."
        );
        _;
    }

    modifier nonZeroAddress(address _token) {
        require(
            _token != address(0),
            "Failed to call function due to address is 0x0."
        );
        _;
    }

    event CommissionWalletUpdated(
        address indexed _previoudWallet, // Previous commission wallet address
        address indexed _newWallet       // New commission wallet address
    );

    event CrowdsaleCreated(
        address indexed _owner, // Crowdsale proposer
        address indexed _token, // ERC20 token for crowdsale
        address _refundWallet,  // Tokens for sale will refund to this wallet
        uint256 _cap,           // Hard cap
        uint256 _goal,          // Soft cap
        uint256 _rate,          // Sell rate. Set to 10 means 1 Wei = 10 token units
        uint256 closingTime,    // Crowdsale closing time
        bool earlyClosure,      // Whether allow early closure
        uint8 _commission       // Commission percentage. Set to 10 means 10%
    );

    event TokenBought(
        address indexed _buyer, // Buyer address
        address indexed _token, // Bought ERC20 token address
        uint256 _value          // Spent wei amount
    );

    event CrowdsaleClosed(
        address indexed _setter, // Address who closed crowdsale
        address indexed _token   // Token address
    );

    event SurplusTokensRefunded(
        address _token,       // ERC20 token for crowdsale
        address _beneficiary, // Surplus tokens will refund to this wallet
        uint256 _surplus      // Surplus token units
    );

    event CommissionPaid(
        address indexed _payer,       // Commission payer        
        address indexed _token,       // Paid from this crowdsale
        address indexed _beneficiary, // Commission paid to this wallet
        uint256 _value                // Paid commission in Wei amount
    );

    event RefundsEnabled(
        address indexed _setter, // Address who enabled refunds
        address indexed _token   // Token address
    );

    event CrowdsaleTokensRefunded(
        address indexed _token,        // ERC20 token for crowdsale
        address indexed _refundWallet, // Token will refund to this wallet
        uint256 _value                 // Refuned amount
    );

    event RaisedWeiClaimed(
        address indexed _beneficiary, // Who claimed refunds
        address indexed _token,       // Refund from this crowdsale
        uint256 _value                // Raised Wei amount
    );

    event TokenClaimed(
        address indexed _beneficiary, // Who claimed refunds
        address indexed _token,       // Refund from this crowdsale
        uint256 _value                // Refund Wei amount 
    );

    event CrowdsalePaused(
        address indexed _owner, // Current contract owner
        address indexed _token  // Paused crowdsale
    );

    event WeiRefunded(
        address indexed _beneficiary, // Who claimed refunds
        address indexed _token,       // Refund from this crowdsale
        uint256 _value                // Refund Wei amount 
    );

    // Note no default constructor is required, but 
    // remember to set commission wallet before operating.

    /**
     * Set crowdsale commission wallet.
     *
     * @param _newWallet New commission wallet
     */
    function setCommissionWallet(
        address _newWallet
    )
        external
        onlyOwner
        nonZeroAddress(_newWallet)
    {
        emit CommissionWalletUpdated(commissionWallet, _newWallet);
        commissionWallet = _newWallet;
    }

    /**
     * Create a crowdsale.
     *
     * @param _token Deployed ERC20 token address
     * @param _refundWallet Tokens for sale will refund to this wallet
     * @param _cap Crowdsale cap
     * @param _goal Crowdsale goal
     * @param _rate Token sell rate. Set to 10 means 1 Wei = 10 token units
     * @param _minInvest Minimum investment in Wei
     * @param _closingTime Crowdsale closing time
     * @param _earlyClosure True: allow early closure; False: not allow
     * @param _commission Commission percentage. Set to 10 means 10%
     */
    function createCrowdsale(
        address _token,
        address _refundWallet,
        uint256 _cap,
        uint256 _goal,
        uint256 _rate,
        uint256 _minInvest,
        uint256 _closingTime,
        bool _earlyClosure,
        uint8 _commission
    )
        external
        nonZeroAddress(_token)
        nonZeroAddress(_refundWallet)
    {
        require(
            crowdsales[_token].owner == address(0),
            "Failed to create crowdsale due to the crowdsale is existed."
        );

        require(
            _goal <= _cap,
            "Failed to create crowdsale due to goal is larger than cap."
        );

        require(
            _minInvest > 0,
            "Failed to create crowdsale due to minimum investment is 0."
        );

        require(
            _commission <= 100,
            "Failed to create crowdsale due to commission is larger than 100."
        );

        // Leverage SafeMath to help potential overflow of maximum token untis.
        _cap.mul(_rate);

        crowdsales[_token] = Crowdsale({
            owner: msg.sender,
            refundWallet: _refundWallet,
            cap: _cap,
            goal: _goal,
            raised: 0,
            rate: _rate,
            minInvest: _minInvest,
            closingTime: _closingTime,
            earlyClosure: _earlyClosure,
            state: States.Active,
            commission: _commission
        });

        emit CrowdsaleCreated(
            msg.sender, 
            _token,
            _refundWallet,
            _cap, 
            _goal, 
            _rate,
            _closingTime,
            _earlyClosure,
            _commission
        );
    }

    /**
     * Buy token with Wei.
     *
     * The Wei will be deposited until crowdsale is finalized.
     * If crowdsale is success, raised Wei will be transfered to the token.
     * If crowdsale is fail, buyer can refund the Wei.
     *
     * Note The minimum investment is 1 ETH.
     * Note the big finger issue is expected to be handled by frontends.
     *
     * @param _token Deployed ERC20 token address
     */
    function buyToken(
        address _token
    )
        external
        inState(_token, States.Active)
        nonZeroAddress(_token)
        payable
    {
        require(
            msg.value >= crowdsales[_token].minInvest,
            "Failed to buy token due to less than minimum investment."
        );

        require(
            crowdsales[_token].raised.add(msg.value) <= (
                crowdsales[_token].cap
            ),
            "Failed to buy token due to exceed cap."
        );

        require(
            // solium-disable-next-line security/no-block-members
            block.timestamp < crowdsales[_token].closingTime,
            "Failed to buy token due to crowdsale is closed."
        );

        deposits[msg.sender][_token] = (
            deposits[msg.sender][_token].add(msg.value)
        );
        crowdsales[_token].raised = crowdsales[_token].raised.add(msg.value);
        emit TokenBought(msg.sender, _token, msg.value);        
    }

    /**
     * Check whether crowdsale goal was reached or not.
     *
     * Goal reached condition:
     * 1. total raised wei >= goal (soft cap); and
     * 2. Right amout of token is prepared for this contract.
     *
     * @param _token Deployed ERC20 token
     * @return Whether crowdsale goal was reached or not
     */
    function _goalReached(
        ERC20 _token
    )
        private
        nonZeroAddress(_token)
        view
        returns(bool) 
    {
        return (crowdsales[_token].raised >= crowdsales[_token].goal) && (
            _token.balanceOf(address(this)) >= 
            crowdsales[_token].raised.mul(crowdsales[_token].rate)
        );
    }

    /**
     * Refund surplus tokens to refund wallet.
     *
     * @param _token Deployed ERC20 token
     * @param _beneficiary Surplus tokens will refund to this wallet
     */
    function _refundSurplusTokens(
        ERC20 _token,
        address _beneficiary
    )
        private
        nonZeroAddress(_token)
        inState(_token, States.Closed)
    {
        uint256 _balance = _token.balanceOf(address(this));
        uint256 _surplus = _balance.sub(
            crowdsales[_token].raised.mul(crowdsales[_token].rate));
        emit SurplusTokensRefunded(_token, _beneficiary, _surplus);

        if (_surplus > 0) {
            // Refund surplus tokens to refund wallet.
            _token.transfer(_beneficiary, _surplus);
        }
    }

    /**
     * Pay commission by raised Wei amount of crowdsale.
     *
     * @param _token Deployed ERC20 token address
     */
    function _payCommission(
        address _token
    )
        private
        nonZeroAddress(_token)
        inState(_token, States.Closed)
        onlyCrowdsaleOwner(_token)
    {
        // Calculate commission, update rest raised Wei, and pay commission.
        uint256 _commission = crowdsales[_token].raised
            .mul(uint256(crowdsales[_token].commission))
            .div(100);
        crowdsales[_token].raised = crowdsales[_token].raised.sub(_commission);
        emit CommissionPaid(msg.sender, _token, commissionWallet, _commission);
        commissionWallet.transfer(_commission);
    }

    /**
     * Refund crowdsale tokens to refund wallet.
     *
     * @param _token Deployed ERC20 token
     * @param _beneficiary Crowdsale tokens will refund to this wallet
     */
    function _refundCrowdsaleTokens(
        ERC20 _token,
        address _beneficiary
    )
        private
        nonZeroAddress(_token)
        inState(_token, States.Refunding)
    {
        // Set raised Wei to 0 to prevent unknown issues 
        // which might take Wei away. 
        // Theoretically, this step is unnecessary due to there is no available
        // function for crowdsale owner to claim raised Wei.
        crowdsales[_token].raised = 0;

        uint256 _value = _token.balanceOf(address(this));
        emit CrowdsaleTokensRefunded(_token, _beneficiary, _value);

        if (_value > 0) {         
            // Refund all tokens for crowdsale to refund wallet.
            _token.transfer(_beneficiary, _token.balanceOf(address(this)));
        }
    }

    /**
     * Enable refunds of crowdsale.
     *
     * @param _token Deployed ERC20 token address
     */
    function _enableRefunds(
        address _token
    )
        private
        nonZeroAddress(_token)
        inState(_token, States.Active)      
    {
        // Set state to Refunding while preventing reentry.
        crowdsales[_token].state = States.Refunding;
        emit RefundsEnabled(msg.sender, _token);
    }

    /**
     * Finalize a crowdsale.
     *
     * Once a crowdsale is finalized, its state could be
     * either Closed (success) or Refunding (fail).
     *
     * @param _token Deployed ERC20 token address
     */
    function finalize(
        address _token
    )
        external
        nonZeroAddress(_token)
        inState(_token, States.Active)        
        onlyCrowdsaleOwner(_token)
    {
        require(                    
            crowdsales[_token].earlyClosure || (
            // solium-disable-next-line security/no-block-members
            block.timestamp >= crowdsales[_token].closingTime),                   
            "Failed to finalize due to crowdsale is opening."
        );

        if (_goalReached(ERC20(_token))) {
            // Set state to Closed whiling preventing reentry.
            crowdsales[_token].state = States.Closed;
            emit CrowdsaleClosed(msg.sender, _token);
            _refundSurplusTokens(
                ERC20(_token), 
                crowdsales[_token].refundWallet
            );
            _payCommission(_token);                        
        } else {
            _enableRefunds(_token);
            _refundCrowdsaleTokens(
                ERC20(_token), 
                crowdsales[_token].refundWallet
            );
        }
    }

    /**
     * Pause crowdsale, which will set the crowdsale state to Refunding.
     *
     * Note only pause crowdsales which are suspicious/scams.
     *
     * @param _token Deployed ERC20 token address
     */
    function pauseCrowdsale(
        address _token
    )  
        external      
        nonZeroAddress(_token)
        onlyOwner
        inState(_token, States.Active)
    {
        emit CrowdsalePaused(msg.sender, _token);
        _enableRefunds(_token);
        _refundCrowdsaleTokens(ERC20(_token), crowdsales[_token].refundWallet);
    }

    /**
     * Claim crowdsale raised Wei.
     *
     * @param _token Deployed ERC20 token address
     */
    function claimRaisedWei(
        address _token,
        address _beneficiary
    )
        external
        nonZeroAddress(_token)
        nonZeroAddress(_beneficiary)
        inState(_token, States.Closed)
        onlyCrowdsaleOwner(_token)        
    {
        require(
            crowdsales[_token].raised > 0,
            "Failed to claim raised Wei due to raised Wei is 0."
        );

        uint256 _raisedWei = crowdsales[_token].raised;
        crowdsales[_token].raised = 0;
        emit RaisedWeiClaimed(msg.sender, _token, _raisedWei);
        _beneficiary.transfer(_raisedWei);
    }

    /**
     * Claim token, which will transfer bought token amount to buyer.
     *
     * @param _token Deployed ERC20 token address
     */
    function claimToken(
        address _token
    )
        external 
        nonZeroAddress(_token)
        inState(_token, States.Closed)
    {
        require(
            deposits[msg.sender][_token] > 0,
            "Failed to claim token due to deposit is 0."
        );

        // Calculate token unit amount to be transferred. 
        uint256 _value = (
            deposits[msg.sender][_token].mul(crowdsales[_token].rate)
        );
        deposits[msg.sender][_token] = 0;
        emit TokenClaimed(msg.sender, _token, _value);
        ERC20(_token).transfer(msg.sender, _value);
    }

    /**
     * Claim refund, which will transfer refunded Wei amount back to buyer.
     *
     * @param _token Deployed ERC20 token address
     */
    function claimRefund(
        address _token
    )
        public
        nonZeroAddress(_token)
        inState(_token, States.Refunding)
    {
        require(
            deposits[msg.sender][_token] > 0,
            "Failed to claim refund due to deposit is 0."
        );

        uint256 _value = deposits[msg.sender][_token];
        deposits[msg.sender][_token] = 0;
        emit WeiRefunded(msg.sender, _token, _value);
        msg.sender.transfer(_value);
    }
}