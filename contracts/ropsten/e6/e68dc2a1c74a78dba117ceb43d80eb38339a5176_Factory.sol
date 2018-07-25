pragma solidity ^0.4.24;

/**
 * @title Trading financial derivatives
 * @author Dodonix.io
 * @dev Factory to produce Derivatives
 * @notice Factory provides standardized derivatives
 */
contract Factory {

    address[] public derivatives;
    address owner;


    event NewDerivative(
        address maker,
        bool long,
        uint8 leverage,
        uint256 indexed terminationDate,
        uint256 strikePrice,
        bytes16 underlying,
        uint256 minStake
    );


    constructor()
        public
    {
        owner = msg.sender;
    }


    /**
     * @notice Will create a new derivative in which &#39;msg.sender&#39; is &#39;long&#39; and which expires at &#39;terminationDate&#39;
     * @param leverage Will multiply percentage change of underlying value at terminationDate compared to &#39;strikePrice&#39;
     */
    function createDerivative (bool long, uint8 leverage, uint256 dueDate, uint256 strikePrice, bytes16 underlying, uint256 minStake, uint256 takerDeadline)
        payable
        public
    {
        Derivative newDerivative = (new Derivative).value(msg.value)(long, leverage, dueDate, strikePrice, underlying, minStake, takerDeadline);
        derivatives.push(newDerivative);
    }

    /// Should be removed:
    function createStandardDerivative ()
        payable
        public
    {
        Derivative newDerivative = (new Derivative).value(msg.value)(true, 2, now+70, 100, 0x00, msg.value/5, now + 65);
        derivatives.push(newDerivative);
    }

    function getNumberOfDerivatives()
        public
        view
        returns (uint)
    {
        return derivatives.length;
    }

    function withdraw ()
        public
    {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
}


contract Derivative {

    /** --- variables --- **/

    address factory;

    // The derivative&#39;s attributes
    uint8 public leverage;
    uint256 public dueDate;
    uint256 public strikePrice;
    uint256 public minStake;
    bytes16 public underlying;
    bool public makerLong;

    // Stakes
    mapping(address => uint256) public stakes;
    uint256 public totalStakeTaker;

    // Sell & buy derivatives
    mapping(address => uint256) public sellPrices;

    // The maker&#39;s attributes
    address private maker;

    // The taker&#39;s attributes
    uint8 public noOfTakers;
    uint256 public takerDeadline;

    // Agreed termination variables
    mapping(address => bool) public hasSubmittedPrice;
    uint8 public noOfSubmittedPrices;
    uint256 public previousSubmittedPrice;

    // Oracle termination variables
    address public oracleAddress = 0x0;
    uint256 public oracleFee = 100000;
    bool public oracleRequest;

    // Termination variables
    uint256 public priceAtTermination;
    bool public isTerminated;


    /** --- modifiers --- **/

    modifier hasMaker(bool yes) {
        require((maker != 0) ==  yes);
        _;
    }

    modifier hasTaker(bool yes) {
        require((noOfTakers != 0) == yes);
        _;
    }

    modifier derivativeIsTerminated(bool yes) {
        require(isTerminated == yes);
        _;
    }

    modifier onlyBy(address who) {
        require(who == msg.sender);
        _;
    }

    modifier onlyByParticipants() {
        require(stakes[msg.sender]!=0);
        _;
    }
    
    modifier takerDeadlineNotExceeded() {
        require(takerDeadline > now);
        _;
    }


    /** --- contructor --- **/

    /**
      * @dev Contructor for all &#39;Derivative&#39;s
      */
    constructor(bool _long,uint8 _leverage,uint256 _dueDate, uint256 _strikePrice, bytes16 _underlying, uint256 _minStake, uint256 _takerDeadline)
        payable
        public
    {
        factory = msg.sender;
        make(_long,_leverage,_dueDate,_strikePrice,_underlying,_minStake,_takerDeadline);
    }


    /** --- functions --- **/

    // -----------------
    // maker&#39;s functions
    // -----------------

    /**
      * @notice Intialization of &#39;Derivative&#39;
      */
    function make (bool _long, uint8 _leverage,uint256 _dueDate, uint256 _strikePrice, bytes16 _underlying, uint256 _minStake, uint256 _takerDeadline)
        payable
        public
        hasMaker(false)
        //derivativeIsTerminated(false)
    {
        // Set maker&#39;s attributes:
        maker = tx.origin;
        makerLong = _long;
        stakes[maker] = msg.value;

        // Set derivative&#39;s attributes:
        strikePrice = _strikePrice;
        dueDate = _dueDate;
        leverage = _leverage;
        underlying = _underlying;
        minStake = _minStake;
        takerDeadline = _takerDeadline;
    }


    /* Functions which can be executed before a taker has entered derivative */

    /**
     * @notice Change the strikePrice
     * @param newStrikePrice will set the new strikePrice
     */
    function changeStrikePrice(uint256 newStrikePrice)
        public
        onlyBy(maker)
        hasTaker(false)
        derivativeIsTerminated(false)
    {
        strikePrice = newStrikePrice;
    }

    /**
     * @notice Change the dueDate
     * @param newDueDate will set the new dueDate
     */
    function changeDueDate(uint256 newDueDate)
        public
        onlyBy(maker)
        hasTaker(false)
        derivativeIsTerminated(false)
    {
        dueDate = newDueDate;
    }
    
    /**
     * @notice Change the dueDate
     * @param newTakerDeadline will set the new dueDate
     */
    function changeTakerDeadline(uint256 newTakerDeadline)
        public
        onlyBy(maker)
        derivativeIsTerminated(false)
    {
        takerDeadline = newTakerDeadline;
    }
    
    /**
     * @notice Maker can reduce stake down to totalStakeTaker
     * @param amount Can be withdrawn from maker&#39;s stake
     */
    function reduceStake(uint256 amount)
        public
        onlyBy(maker)
    {
        uint256 remainder = sub(stakes[maker],amount);
        require(remainder > totalStakeTaker);
        stakes[maker] = remainder;
        maker.transfer(amount);
    }

    // -----------------
    // taker&#39;s functions
    // -----------------

    /**
     * @notice  Send &#39;msg.value&#39; which fulfills
     *          &#39;totalStakeTaker&#39; (after adding msg.value to existing total stakes)
     *            < &#39;stakes[maker]&#39;
     *          and
     *          &#39;msg.value&#39; >= &#39;minStake&#39;
     *          to take derivative
     * @dev &#39;msg.value&#39; has to be equal to stakes[maker]
     */
    function take ()
        payable
        public
        hasMaker(true)
        derivativeIsTerminated(false)
        takerDeadlineNotExceeded()
    {
        totalStakeTaker += msg.value;
        require(totalStakeTaker <= stakes[maker] && msg.value >= minStake);
        if (stakes[msg.sender] == 0)
        {
            noOfTakers += 1;
        }
        stakes[msg.sender] += msg.value; // allows multiple takes
    }


    // --------------------
    // sell & buy functions
    // --------------------

    function sellPosition (uint256 sellPrice)
        public
    {
        sellPrices[msg.sender] = sellPrice;
    }

    function buyPosition (address sellerAddress)
        public
        payable
    {
        require (sellPrices[sellerAddress] != 0);
        require (msg.value == sellPrices[sellerAddress]);
        stakes[msg.sender] = stakes[sellerAddress];
        stakes[sellerAddress] = 0;
        sellerAddress.transfer(msg.value);
    }


    // -----------
    // termination
    // -----------

    /**
     * @notice If participants are willing to agree on the same price, they can commit the closing price of the underying at termination date
     * @param submittedPrice Will be compared with other summited prices. Be careful: Can only be submitted once!
     */
    function agreedTermination (uint256 submittedPrice)
        public
        onlyByParticipants()
    {
        // Participant should not have summitted price yet:
        require(!hasSubmittedPrice[msg.sender]);
        if (noOfSubmittedPrices != 0 && previousSubmittedPrice != submittedPrice)
        {
            sendPriceRequestToOracle(underlying, bytes16(dueDate));
            return;
        }
        if (noOfSubmittedPrices == noOfTakers)
        {
            terminate(submittedPrice);
        }
        else
        {
            previousSubmittedPrice = submittedPrice;
            hasSubmittedPrice[msg.sender] = true;
            noOfSubmittedPrices++;
        }
    }


    /**
     * @notice Terminates active derivative and distributes win
     * @param price Is value of underlying at &#39;terminationDate&#39; which will be compared to &#39;strikePrice&#39;
     */

    /**
     * @param price Is the closing price of the underlying at the due date which will be used to calculate the win or loss of all participants
     */
    function terminate (uint256 price)
        private
        derivativeIsTerminated(false)
    {
        // Set calucation parameters:
        priceAtTermination = price;
        isTerminated = true;
    }


    // --------
    // withdraw
    // --------

    /**
     * @notice Withdraw your remaining money
     * @dev Is following Checks-Effects-Interaction pattern
     */
    function withdraw ()
        public
        derivativeIsTerminated(true)
    {
        uint256 surplus;
        uint256 stakeMemory;
        // Calculate withdraw amount:
        if (msg.sender == maker)
        {
            stakeMemory = stakes[msg.sender];
            stakes[msg.sender] = 0;
            maker = 0;
            // Long wins:
            if (priceAtTermination > strikePrice)
            {
                surplus = sub(mul(priceAtTermination,mul(totalStakeTaker,leverage))/strikePrice , mul(totalStakeTaker,leverage));
                if (surplus > totalStakeTaker)
                    surplus = totalStakeTaker;
                if (makerLong)
                {
                    msg.sender.transfer(add(stakeMemory,surplus));
                }
                else
                {
                    msg.sender.transfer(sub(stakeMemory,surplus));
                }
            }
            // Short wins:
            else
            {
                surplus = sub(mul(totalStakeTaker,leverage) , mul(priceAtTermination,mul(totalStakeTaker,leverage))/strikePrice);
                if (surplus > totalStakeTaker)
                    surplus = totalStakeTaker;
                if (makerLong)
                {
                    msg.sender.transfer(sub(stakeMemory,surplus));
                }
                else
                {
                    msg.sender.transfer(add(stakeMemory,surplus));
                }
            }
            return;
        }
        if (msg.sender != maker && stakes[msg.sender] != 0)
        // msg.sender is a taker:
        {
            // Remove taker from takers list:
            stakeMemory = stakes[msg.sender];
            stakes[msg.sender] = 0;
            // Long wins:
            if (priceAtTermination > strikePrice)
            {
                surplus = sub(mul(priceAtTermination,mul(stakeMemory,leverage))/strikePrice , mul(stakeMemory,leverage));
                if (surplus > stakeMemory)
                    surplus = stakeMemory;
                if (!makerLong)
                {
                    msg.sender.transfer(add(stakeMemory,surplus));
                }
                else
                {
                    msg.sender.transfer(sub(stakeMemory,surplus));
                }
            }
            // Short wins:
            else
            {
                surplus = sub(mul(stakeMemory,leverage) , mul(priceAtTermination,mul(stakeMemory,leverage))/strikePrice);
                if (surplus > stakeMemory)
                    surplus = stakeMemory;
                if (!makerLong)
                {
                    msg.sender.transfer(sub(stakeMemory,surplus));
                }
                else
                {
                    msg.sender.transfer(add(stakeMemory,surplus));
                }
            }
        }
    }


    // ----
    // Math functions:
    // ----

    // TODO: Could be outsourced
    function sub (uint256 _a, uint256 _b)
        internal
        pure
        returns (uint256)
    {
        if (_b > _a) return 0;
        return _a - _b;
    }

    // TODO: Could be outsourced
    function mul (uint256 _a, uint256 _b)
        internal
        pure
        returns (uint256)
    {
        if (_a == 0) return 0;
        uint256 c = _a * _b;
        if(c / _a != _b) return 0;
        return c;
    }

    // TODO: Could be outsourced
    function add(uint256 _a, uint256 _b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = _a + _b;
        assert(c >= _a);
        return c;
    }


    // ---
    // Additional functions:
    // ---

    function getNow ()
        public
        view
        returns(uint256)
    {
        return(now);
    }

    function balanceOfDerivative()
        public
        view
        returns (uint256)
    {
        return (address(this).balance);
    }

    function getStatus()
        public
        view
        returns(uint8,uint256,uint256,bytes16,uint256,address,bool)
    {
        return(
            leverage,
            dueDate,
            strikePrice,
            underlying,
            minStake,
            maker,
            makerLong
        );
    }


    // ---
    // Oracle functions:
    // ---

    function sendPriceRequestToOracle (bytes16 _nameOfAsset, bytes16 _date)
        public
        payable
    {
        Oracle o = Oracle(oracleAddress);
        o.receivePriceRequest.value(msg.value)(_nameOfAsset, _date, this.receivePriceFromOracle);
        oracleRequest = true;
    }

    //callback function to be called by oracle contract
    function receivePriceFromOracle (uint256 _price)
        public
    {
        terminate(_price);
    }

}


/**
 * @title Oracle Contract
 * @author Dodon Oracle Services
 * @dev Contract to save price values
 * @notice Contract provides oracle values
 */

contract Oracle {

  function receivePriceRequest(bytes16 _nameOfAsset, bytes16 _date, function(uint256) external _callback)
    public
    payable
  {

  }

}