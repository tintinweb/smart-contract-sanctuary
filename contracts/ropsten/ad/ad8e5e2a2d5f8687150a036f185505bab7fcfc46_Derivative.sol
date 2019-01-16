pragma solidity ^0.5.1;

/**
 * @title Trading financial derivatives
 * @author Dodonix.io
 * @dev Factory to produce Derivatives
 * @notice Factory provides standardized derivatives
 */
contract Factory {

    address[] public derivatives;
    address owner;
    address oracleAddress = 0x0000000000000000000000000000000000000000;

    constructor()
        public
    {
        owner = msg.sender;
    }

    function createDerivative (bool long, uint8 leverage, uint256 dueDate, uint256 strikePrice, bytes16 underlying, uint256 minStake, uint256 takerDeadline)
        payable
        public
    {
        Derivative newDerivative = (new Derivative).value(msg.value)(long, leverage, dueDate, strikePrice, underlying, minStake, takerDeadline, oracleAddress);
        derivatives.push(address(newDerivative));
    }

    function getNumberOfDerivatives()
        public
        view
        returns (uint)
    {
        return derivatives.length;
    }

    function withdrawFees ()
        public
    {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }

    function setOracleAddress (address _oracleAddress)
        public
    {
        require(msg.sender == owner);
        oracleAddress = _oracleAddress;
    }
}


contract Derivative {

    address factory;

    // The derivative&#39;s attributes
    uint8 public leverage;
    uint256 public dueDate;
    uint256 public strikePrice;
    bytes16 public underlying;
    bool public makerLong;

    // Stakes
    mapping(address => uint256) public stakes;
    uint256 public totalStakeAllTakers;

    // The maker&#39;s attributes
    address payable public maker;

    // The taker&#39;s attributes
    uint8 public numberOfTakers;
    uint256 public takerDeadline;
    uint256 public minTakerStake;

    // Gas costs:
    mapping(address => uint256) public gasCostBalance;
    uint256 public totalGasUsed;
    uint256 public gasUsageOfMaker = 1000000;
    uint256 public gasPrice;

    // Agreed termination variables
    mapping(address => bool) public hasSubmittedPrice;
    uint8 public numberOfSubmittedPrices;
    uint256 public previousSubmittedPrice;

    // Oracle termination variables
    address public oracle = 0x0000000000000000000000000000000000000000;
    uint256 public oracleFee = 1000000000;

    // Termination variables
    uint256 public priceAtTermination;
    bool public isTerminated;


    modifier hasTaker(bool yes) {
        require((numberOfTakers != 0) == yes);
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

    modifier notByMaker(){
        require(msg.sender != maker);
        _;
    }

    modifier takerDeadlineNotExceeded() {
        require(takerDeadline > now);
        _;
    }


    constructor(
        bool _long,
        uint8 _leverage,
        uint256 _dueDate,
        uint256 _strikePrice,
        bytes16 _underlying,
        uint256 _minTakerStake,
        uint256 _takerDeadline,
        address _oracle
    )
        payable
        public
    {
        factory = msg.sender;
        oracle = _oracle;

        // Set maker&#39;s attributes:
        maker = tx.origin;
        makerLong = _long;
        stakes[maker] = msg.value;

        // Set derivative&#39;s attributes:
        strikePrice = _strikePrice;
        dueDate = _dueDate;
        leverage = _leverage;
        underlying = _underlying;
        minTakerStake = _minTakerStake;
        takerDeadline = _takerDeadline;
    }

    function changeStrikePrice(uint256 newStrikePrice)
        public
        onlyBy(maker)
        hasTaker(false)
    {
        strikePrice = newStrikePrice;
    }

    /**
     * @notice Can used multiple times by smae taker
     **/
    function take ()
        payable
        public
        derivativeIsTerminated(false)
        takerDeadlineNotExceeded()
        notByMaker()
    {
        uint256 gasAtBeginning = gasleft();
        totalStakeAllTakers += msg.value;
        require(totalStakeAllTakers <= stakes[maker] && msg.value >= minTakerStake);
        if (stakes[msg.sender] == 0)
        {
            numberOfTakers += 1;
        }
        stakes[msg.sender] += msg.value;
        gasCostBalance[msg.sender] = gasAtBeginning - gasleft();
        totalGasUsed += gasAtBeginning - gasleft();
    }

    /**
     * @notice If participants are willing to agree on the same price, they can commit the closing price of the underying at termination date
     * @notice This fails if price does not agree with previousSubmittedPrice --> directly sends request to Oracle
     * @param submittedPrice will be compared with other summited prices. Be careful: Can only be submitted once!
     */
    function agreedTermination (uint256 submittedPrice)
        public
        onlyByParticipants()
    {
        uint256 gasAtBeginning = gasleft();
        require(!hasSubmittedPrice[msg.sender]);
        if (numberOfSubmittedPrices == 0)
        {
            previousSubmittedPrice = submittedPrice;
            hasSubmittedPrice[msg.sender] = true;
            numberOfSubmittedPrices = 1;
            gasCostBalance[msg.sender] = gasAtBeginning - gasleft();
            totalGasUsed += gasAtBeginning - gasleft();
            return;
        }
        if (previousSubmittedPrice != submittedPrice)
        {
            sendPriceRequestToOracle(underlying, dueDate);
            gasCostBalance[msg.sender] = gasAtBeginning - gasleft();
            totalGasUsed += gasAtBeginning - gasleft();
            return;
        }
        if (numberOfSubmittedPrices == numberOfTakers - 1)
        {
            terminate(submittedPrice);
        }
        else
        {
            previousSubmittedPrice = submittedPrice;
            hasSubmittedPrice[msg.sender] = true;
            numberOfSubmittedPrices++;
        }
        gasCostBalance[msg.sender] = gasAtBeginning - gasleft();
        totalGasUsed += gasAtBeginning - gasleft();
    }

    function terminate (uint256 price)
        private
        derivativeIsTerminated(false)
    {
        // Set calucation parameters:
        priceAtTermination = price;
        isTerminated = true;
    }

    /**
     * @dev Is following Checks-Effects-Interaction pattern
     */
    function withdraw ()
        public
        derivativeIsTerminated(true)
    {
        uint256 surplus;
        uint256 stakeMemory;
        if (msg.sender == maker)
        {
            stakeMemory = stakes[msg.sender];
            stakes[msg.sender] = 0;
            maker = 0x0000000000000000000000000000000000000000;
            uint256 effectiveTotalStakeAllTakers =
                sub(
                    totalStakeAllTakers,
                    mul(
                        gasPrice,
                        add(totalGasUsed,gasUsageOfMaker)
                    )
                );
            // Long wins:
            if (priceAtTermination > strikePrice)
            {
                surplus =
                    sub(
                        mul(
                            priceAtTermination,
                            mul(effectiveTotalStakeAllTakers,leverage)
                        )/strikePrice ,
                        mul(effectiveTotalStakeAllTakers,leverage)
                    );
                if (surplus > effectiveTotalStakeAllTakers)
                    surplus = effectiveTotalStakeAllTakers;
                if (makerLong)
                {
                    msg.sender.transfer(add(add(stakeMemory,surplus),gasUsageOfMaker));
                }
                else
                {
                    msg.sender.transfer(add(sub(stakeMemory,surplus),gasUsageOfMaker));
                }
            }
            // Short wins:
            else
            {
                surplus =
                    sub(
                        mul(totalStakeAllTakers,leverage),
                        mul(
                            priceAtTermination,
                            mul(totalStakeAllTakers,leverage)
                        )/strikePrice
                    );
                if (surplus > totalStakeAllTakers)
                    surplus = totalStakeAllTakers;
                if (makerLong)
                {
                    msg.sender.transfer(add(sub(stakeMemory,surplus),gasUsageOfMaker));
                }
                else
                {
                    msg.sender.transfer(add(add(stakeMemory,surplus),gasUsageOfMaker));
                }
            }
            return;
        }
        if (stakes[msg.sender] != 0)
        // msg.sender is a taker:
        {
            stakeMemory = add(
                stakes[msg.sender],
                mul(
                    gasPrice,
                    sub(
                        gasCostBalance[msg.sender],
                        mul(
                            stakes[msg.sender]/totalStakeAllTakers,
                            add(totalGasUsed,gasUsageOfMaker)
                        )
                    )
                )
            );
            stakes[msg.sender] = 0;
            // Long wins:
            if (priceAtTermination > strikePrice)
            {
                surplus =
                    sub(
                        mul(
                            priceAtTermination,
                            mul(stakeMemory,leverage)
                        )/strikePrice,
                        mul(stakeMemory,leverage)
                    );
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
                surplus =
                    sub(
                        mul(stakeMemory,leverage),
                        mul(
                            priceAtTermination,
                            mul(stakeMemory,leverage)
                        )/strikePrice
                    );
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
        require(c / _a != _b);
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
            minTakerStake,
            maker,
            makerLong
        );
    }


    // ---
    // Oracle functions:
    // ---

    function sendPriceRequestToOracle (bytes16 _nameOfAsset, uint256 _date)
        public
        payable
    {
        Oracle o = Oracle(oracle);
        o.receivePriceRequest.value(oracleFee)(_nameOfAsset, _date, this.receivePriceFromOracle);
    }

    //callback function to be called by oracle contract
    function receivePriceFromOracle (uint256 _price)
        public
        onlyBy(oracle)
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

  function receivePriceRequest(bytes16 _nameOfAsset, uint256 _date, function(uint256) external _callback)
    public
    payable
  {

  }

}