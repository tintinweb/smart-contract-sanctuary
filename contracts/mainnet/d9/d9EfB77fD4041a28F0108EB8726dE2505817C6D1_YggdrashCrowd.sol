pragma solidity ^0.4.11;
/**
    ERC20 Interface
    @author DongOk Peter Ryu - <<span class="__cf_email__" data-cfemail="5b343f32351b223c3c3f293a2833753234">[email&#160;protected]</span>>
*/
contract ERC20 {
    function totalSupply() public constant returns (uint supply);
    function balanceOf( address who ) public constant returns (uint value);
    function allowance( address owner, address spender ) public constant returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}
/**
    YGGDRASH SmartContract
    @author Peter Ryu - <<span class="__cf_email__" data-cfemail="93fcf7fafdd3eaf4f4f7e1f2e0fbbdfafc">[email&#160;protected]</span>>
*/
contract YggdrashCrowd {
    using SafeMath for uint;
    ERC20 public yeedToken;
    Stages stage;
    address public wallet;
    address public owner;
    address public tokenOwner;
    uint public totalAmount;    // Contruibute Token amount
    uint public priceFactor; // ratio
    uint public startBlock;
    uint public totalReceived;
    uint public endTime;

    uint public maxValue; // max ETH
    uint public minValue;

    uint public maxGasPrice; // Max gasPrice

    // collect log
    event FundTransfer (address sender, uint amount);

    struct ContributeAddress {
        bool exists; // set to true
        address account; // sending account
        uint amount; // sending amount
        uint balance; // token value
        bytes data; // sending data
    }

    mapping(address => ContributeAddress) public _contributeInfo;
    mapping(bytes => ContributeAddress) _contruibuteData;

    /*
        Check is owner address
    */
    modifier isOwner() {
        // Only owner is allowed to proceed
        require (msg.sender == owner);
        _;
    }

    /**
        Check Valid Payload
    */
    modifier isValidPayload() {
        // check Max
        if(maxValue != 0){
            require(msg.value < maxValue + 1);
        }
        // Check Min
        if(minValue != 0){
            require(msg.value > minValue - 1);
        }
        require(wallet != msg.sender);
        // check data value
        require(msg.data.length != 0);
        _;

    }

    /*
        Check exists Contribute list
    */
    modifier isExists() {
        require(_contruibuteData[msg.data].exists == false);
        require(_contributeInfo[msg.sender].amount == 0);
        _;
    }

    /*
     *  Modifiers Stage
     */
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }


    /*
     *  Enums Stage Status
     */
    enum Stages {
    Deployed,
    SetUp,
    Started,
    Ended
    }


    /// init
    /// @param _token token address
    /// @param _tokenOwner token owner wallet address
    /// @param _wallet Send ETH wallet
    /// @param _amount token total value
    /// @param _priceFactor token and ETH ratio
    /// @param _maxValue maximum ETH balance
    /// @param _minValue minimum ETH balance

    function YggdrashCrowd(address _token, address _tokenOwner, address _wallet, uint _amount, uint _priceFactor, uint _maxValue, uint _minValue)
    public
    {
        require (_tokenOwner != 0 && _wallet != 0 && _amount != 0 && _priceFactor != 0);
        tokenOwner = _tokenOwner;
        owner = msg.sender;
        wallet = _wallet;
        totalAmount = _amount;
        priceFactor = _priceFactor;
        maxValue = _maxValue;
        minValue = _minValue;
        stage = Stages.Deployed;

        if(_token != 0){ // setup token
            yeedToken = ERC20(_token);
            stage = Stages.SetUp;
        }
        // Max Gas Price is unlimited
        maxGasPrice = 0;
    }

    // setupToken
    function setupToken(address _token)
    public
    isOwner
    {
        require(_token != 0);
        yeedToken = ERC20(_token);
        stage = Stages.SetUp;
    }

    /// @dev Start Contruibute
    function startContruibute()
    public
    isOwner
    atStage(Stages.SetUp)
    {
        stage = Stages.Started;
        startBlock = block.number;
    }


    /**
        Contributer send to ETH
        Payload Check
        Exist Check
        GasPrice Check
        Stage Check
    */
    function()
    public
    isValidPayload
    isExists
    atStage(Stages.Started)
    payable
    {
        uint amount = msg.value;
        uint maxAmount = totalAmount.div(priceFactor);
        // refund
        if (amount > maxAmount){
            uint refund = amount.sub(maxAmount);
            assert(msg.sender.send(refund));
            amount = maxAmount;
        }
        //  NO MORE GAS WAR!!!
        if(maxGasPrice != 0){
            assert(tx.gasprice < maxGasPrice + 1);
        }
        totalReceived = totalReceived.add(amount);
        // calculate token
        uint token = amount.mul(priceFactor);
        totalAmount = totalAmount.sub(token);

        // give token to sender
        yeedToken.transferFrom(tokenOwner, msg.sender, token);
        FundTransfer(msg.sender, token);

        // Set Contribute Account
        ContributeAddress crowdData = _contributeInfo[msg.sender];
        crowdData.exists = true;
        crowdData.account = msg.sender;
        crowdData.data = msg.data;
        crowdData.amount = amount;
        crowdData.balance = token;
        // add contruibuteData
        _contruibuteData[msg.data] = crowdData;
        _contributeInfo[msg.sender] = crowdData;
        // send to wallet
        wallet.transfer(amount);

        // token sold out
        if (amount == maxAmount)
            finalizeContruibute();
    }

    /// @dev Changes auction totalAmount and start price factor before auction is started.
    /// @param _totalAmount Updated auction totalAmount.
    /// @param _priceFactor Updated start price factor.
    /// @param _maxValue Maximum balance of ETH
    /// @param _minValue Minimum balance of ETH
    function changeSettings(uint _totalAmount, uint _priceFactor, uint _maxValue, uint _minValue, uint _maxGasPrice)
    public
    isOwner
    {
        require(_totalAmount != 0 && _priceFactor != 0);
        totalAmount = _totalAmount;
        priceFactor = _priceFactor;
        maxValue = _maxValue;
        minValue = _minValue;
        maxGasPrice = _maxGasPrice;
    }
    /**
        Set Max Gas Price by Admin
    */
    function setMaxGasPrice(uint _maxGasPrice)
    public
    isOwner
    {
        maxGasPrice = _maxGasPrice;
    }


    // token balance
    // @param src sender wallet address
    function balanceOf(address src) public constant returns (uint256)
    {
        return _contributeInfo[src].balance;
    }

    // amount ETH value
    // @param src sender wallet address
    function amountOf(address src) public constant returns(uint256)
    {
        return _contributeInfo[src].amount;
    }

    // contruibute data
    // @param src Yggdrash uuid
    function contruibuteData(bytes src) public constant returns(address)
    {
        return _contruibuteData[src].account;
    }

    // Check contruibute is open
    function isContruibuteOpen() public constant returns (bool)
    {
        return stage == Stages.Started;
    }

    // Smartcontract halt
    function halt()
    public
    isOwner
    {
        finalizeContruibute();
    }

    // END of this Contruibute
    function finalizeContruibute()
    private
    {
        stage = Stages.Ended;
        // remain token send to owner
        totalAmount = 0;
        endTime = now;
    }
}