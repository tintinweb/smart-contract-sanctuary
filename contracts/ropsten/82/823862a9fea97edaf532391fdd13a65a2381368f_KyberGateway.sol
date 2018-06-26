pragma solidity ^0.4.19;

// https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Token is ERC20{
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    event Transfer(address _from, address _to, uint256 _value);
    event Approval(address _owner, address _spender, uint256 _value);
}

contract KyberNetworkInterface {
  function trade(
      ERC20 src,
      uint srcAmount,
      ERC20 dest,
      address destAddress,
      uint maxDestAmount,
      uint minConversionRate,
      address walletId
  )
      public
      payable
      returns(uint);

  function getExpectedRate(
      ERC20 src,
      ERC20 dest,
      uint srcQty
  )
      public view
      returns (uint expectedRate, uint slippageRate);
  // maybe dont use this function
  function findBestRate(
      ERC20 src,
      ERC20 dest,
      uint srcQty
  )
      public view
      returns(uint, uint);
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _to Address of the new owner
    */
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0));
        owner = _to;
        return true;
    }
}

/**
    @dev Defines the interface of a standard RCN oracle.

    The oracle is an agent in the RCN network that supplies a convertion rate between RCN and any other currency,
    it&#39;s primarily used by the exchange but could be used by any other agent.
*/
contract Oracle is Ownable {
    uint256 public constant VERSION = 4;

    event NewSymbol(bytes32 _currency);

    mapping(bytes32 => bool) public supported;
    bytes32[] public currencies;

    /**
        @dev Returns the url where the oracle exposes a valid &quot;oracleData&quot; if needed
    */
    function url() public view returns (string);

    /**
        @dev Returns a valid convertion rate from the currency given to RCN

        @param symbol Symbol of the currency
        @param data Generic data field, could be used for off-chain signing
    */
    function getRate(bytes32 symbol, bytes data) public returns (uint256 rate, uint256 decimals);

    /**
        @dev Adds a currency to the oracle, once added it cannot be removed

        @param ticker Symbol of the currency

        @return if the creation was done successfully
    */
    function addCurrency(string ticker) public onlyOwner returns (bool) {
        bytes32 currency = encodeCurrency(ticker);
        emit NewSymbol(currency);
        supported[currency] = true;
        currencies.push(currency);
        return true;
    }

    /**
        @return the currency encoded as a bytes32
    */
    function encodeCurrency(string currency) public pure returns (bytes32 o) {
        require(bytes(currency).length <= 32);
        assembly {
            o := mload(add(currency, 32))
        }
    }

    /**
        @return the currency string from a encoded bytes32
    */
    function decodeCurrency(bytes32 b) public pure returns (string o) {
        uint256 ns = 256;
        while (true) { if (ns == 0 || (b<<ns-8) != 0) break; ns -= 8; }
        assembly {
            ns := div(ns, 8)
            o := mload(0x40)
            mstore(0x40, add(o, and(add(add(ns, 0x20), 0x1f), not(0x1f))))
            mstore(o, ns)
            mstore(add(o, 32), b)
        }
    }

}

contract Engine {
    uint256 public VERSION;
    string public VERSION_NAME;
    Token public rcn;

    enum Status { initial, lent, paid, destroyed }
    struct Approbation {
        bool approved;
        bytes data;
        bytes32 checksum;
    }

    function getTotalLoans() public view returns (uint256);
    function getOracle(uint index) public view returns (Oracle);
    function getBorrower(uint index) public view returns (address);
    function getCosigner(uint index) public view returns (address);
    function ownerOf(uint256) public view returns (address owner);
    function getCreator(uint index) public view returns (address);
    function getAmount(uint index) public view returns (uint256);
    function getPaid(uint index) public view returns (uint256);
    function getDueTime(uint index) public view returns (uint256);
    function getApprobation(uint index, address _address) public view returns (bool);
    function getStatus(uint index) public view returns (Status);
    function isApproved(uint index) public view returns (bool);
    function getPendingAmount(uint index) public returns (uint256);
    function getCurrency(uint index) public view returns (bytes32);
    function cosign(uint index, uint256 cost) external returns (bool);
    function approveLoan(uint index) public returns (bool);
    function transfer(address to, uint256 index) public returns (bool);
    function takeOwnership(uint256 index) public returns (bool);
    function withdrawal(uint index, address to, uint256 amount) public returns (bool);
    function lend(uint index, bytes oracleData, Cosigner cosigner, bytes cosignerData) public returns (bool);

    function convertRate(Oracle oracle, bytes32 currency, bytes data, uint256 amount) public returns (uint256);
    function pay(uint index, uint256 _amount, address _from, bytes oracleData) public returns (bool);
}

/**
    @dev Defines the interface of a standard RCN cosigner.

    The cosigner is an agent that gives an insurance to the lender in the event of a defaulted loan, the confitions
    of the insurance and the cost of the given are defined by the cosigner.

    The lender will decide what cosigner to use, if any; the address of the cosigner and the valid data provided by the
    agent should be passed as params when the lender calls the &quot;lend&quot; method on the engine.

    When the default conditions defined by the cosigner aligns with the status of the loan, the lender of the engine
    should be able to call the &quot;claim&quot; method to receive the benefit; the cosigner can define aditional requirements to
    call this method, like the transfer of the ownership of the loan.
*/
contract Cosigner {
    uint256 public constant VERSION = 2;

    /**
        @return the url of the endpoint that exposes the insurance offers.
    */
    function url() public view returns (string);

    /**
        @dev Retrieves the cost of a given insurance, this amount should be exact.

        @return the cost of the cosign, in RCN wei
    */
    function cost(address engine, uint256 index, bytes data, bytes oracleData) public view returns (uint256);

    /**
        @dev The engine calls this method for confirmation of the conditions, if the cosigner accepts the liability of
        the insurance it must call the method &quot;cosign&quot; of the engine. If the cosigner does not call that method, or
        does not return true to this method, the operation fails.

        @return true if the cosigner accepts the liability
    */
    function requestCosign(Engine engine, uint256 index, bytes data, bytes oracleData) public returns (bool);

    /**
        @dev Claims the benefit of the insurance if the loan is defaulted, this method should be only calleable by the
        current lender of the loan.

        @return true if the claim was done correctly.
    */
    function claim(address engine, uint256 index, bytes oracleData) public returns (bool);
}

/* taking ideas from FirstBlood token */
contract RpSafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        require((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        require(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        require((x == 0)||(z/x == y));
        return z;
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }

    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }
}

contract KyberGateway is RpSafeMath {
    ERC20 constant internal ETH = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint constant internal MAX_UINT = 2**256 - 1;

    /**
        @notice Performs the a trade on kyber network and pay an amount on loan in nanoLoanEngine

        @param _network kyverNetwork market
        @param _engine the engine of RCN
        @param _index Index of the loan
        @param _amount Amount of pay in loan currency
        @param _oracleData Data required by the oracle to return the rate, the content of this field must be provided
            by the url exposed in the url() method of the oracle.
        @param _minChangeRCN minimum repurchase change amount
        @param _minConversionRate min rate. Lower rate typically results in better success rate when the market is volatile

        @return true if the trade and pay was done successfully
    */
    function pay(
        KyberNetworkInterface _network,
        Engine _engine,
        uint _index,
        uint _amount,
        bytes _oracleData,
        uint _minChangeRCN,
        uint _minConversionRate
    ) public payable returns (bool) {
        require(msg.value > 0, &quot;msg.value its 0&quot;);

        Token rcn = _engine.rcn();
        uint initialBalance = rcn.balanceOf(this);

        uint boughtRCN = _network.trade.value(msg.value)(ETH, msg.value, rcn, this, MAX_UINT, _minConversionRate, 0);
        require(rcn.balanceOf(this) - initialBalance == boughtRCN, &quot;Kyber return wrong rcn amount&quot;);

        uint requiredRcn = _engine.convertRate(_engine.getOracle(_index), _engine.getCurrency(_index), _oracleData, _amount);
        require(boughtRCN >= requiredRcn, &quot;insufficient rcn found&quot;);

        rcn.approve(address(_engine), requiredRcn);
        require(_engine.pay(_index, _amount, msg.sender, _oracleData), &quot;pay engine fail&quot;);
        rcn.approve(address(_engine), 0);

        require(rebuyAndReturn(_network, rcn, _minChangeRCN, safeSubtract(boughtRCN, requiredRcn)), &quot;rebuy fail&quot;);
        require(rcn.balanceOf(this) == initialBalance, &quot;Wrong final balance of rcn&quot;);

        return true;
    }

    /**
        @notice Performs the a trade on kyber network and lend a loan in nanoLoanEngine

        @param _network kyverNetwork market
        @param _engine the engine of RCN
        @param _index Index of the loan
        @param _cosigner Address of the cosigner, 0x0 for lending without cosigner.
        @param _cosignerData Data required by the cosigner to process the request.
        @param _oracleData Data required by the oracle to return the rate, the content of this field must be provided
            by the url exposed in the url() method of the oracle.
        @param _minChangeRCN minimum repurchase change amount
        @param _minConversionRate min rate. Lower rate typically results in better success rate when the market is volatile

        @return true if the trade and lend was done successfully
    */
    function lend(
        KyberNetworkInterface _network,
        Engine _engine,
        uint _index,
        Cosigner _cosigner,
        bytes _cosignerData,
        bytes _oracleData,
        uint _minChangeRCN,
        uint _minConversionRate
    ) public payable returns (bool) {
        require(msg.value > 0, &quot;msg.value its 0&quot;);

        Token rcn = _engine.rcn();
        uint initialBalance = rcn.balanceOf(this);

        uint boughtRCN = _network.trade.value(msg.value)(ETH, msg.value, rcn, this, MAX_UINT, _minConversionRate, this);
        require(rcn.balanceOf(this) - initialBalance == boughtRCN, &quot;Kyber return wrong rcn amount&quot;);

        uint requiredRcn = getRequiredRcnLend(_engine, _index, _cosignerData, _oracleData);
        require(boughtRCN >= requiredRcn, &quot;insufficient rcn found&quot;);

        rcn.approve(address(_engine), requiredRcn);
        require(_engine.lend(_index, _oracleData, _cosigner, _cosignerData), &quot;fail engine lend&quot;);
        rcn.approve(address(_engine), 0);

        require(_engine.transfer(msg.sender, _index), &quot;fail rcn transfer&quot;);
        require(rebuyAndReturn(_network, rcn, _minChangeRCN, safeSubtract(boughtRCN, requiredRcn)), &quot;rebuy fail&quot;);
        require(rcn.balanceOf(this) == initialBalance, &quot;Wrong final balance of rcn&quot;);

        return true;
    }
    /**
        @notice rebuy ETH and transfer to the sender or transfer the change on RCN to the sender

        @param _network kyverNetwork market
        @param _rcn RCN token
        @param _minChangeRCN minimum repurchase change amount
        @param _change amount of change on RCN of the previous trade

        @return true if the trade was done successfully or if the transfer of RCN was done successfully
    */
    function rebuyAndReturn(
        KyberNetworkInterface _network,
        Token _rcn,
        uint _minChangeRCN,
        uint _change
    ) internal returns (bool) {
        if (_change != 0) {
            if(_minChangeRCN < _change){
                uint prevBalanceUser = msg.sender.balance;
                _rcn.approve(address(_network), _change);
                _change = _network.trade.value(0)(_rcn, _change, ETH, msg.sender, MAX_UINT, 0, this);
                _rcn.approve(address(_network), 0);
                require(msg.sender.balance - prevBalanceUser == _change, &quot;Kyber return wrong rcn amount&quot;);
            }else{
                require(_rcn.transfer(msg.sender, _change), &quot;Transfer rcn fail&quot;);
            }
        }
        return true;
    }
    /**
        @notice get the require amount of RCN to performs a lend

        @param _engine the engine of RCN
        @param _index Index of the loan
        @param _oracleData Data required by the oracle to return the rate, the content of this field must be provided
            by the url exposed in the url() method of the oracle.
        @param _cosignerData Data required by the cosigner to process the request.

        @return require amount of RCN
    */
    function getRequiredRcnLend(
        Engine _engine,
        uint _index,
        bytes _cosignerData,
        bytes _oracleData
    ) internal returns(uint required){
        Cosigner cosigner = Cosigner(_engine.getCosigner(_index));

        if (cosigner != address(0)) {
            required += cosigner.cost(_engine, _index, _oracleData, _cosignerData);
        }
        required += _engine.convertRate(_engine.getOracle(_index), _engine.getCurrency(_index), _oracleData, _engine.getAmount(_index));
    }
}