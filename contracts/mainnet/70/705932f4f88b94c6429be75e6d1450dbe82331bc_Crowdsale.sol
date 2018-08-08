pragma solidity 0.4.21;


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
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


contract CryptoRoboticsToken {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function burn(uint256 value) public;
}


contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    /**
     * @param _wallet Vault address
     */
    function RefundVault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }

    /**
     * @param investor Investor address
     */
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
        wallet.transfer(address(this).balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    /**
     * @param investor Investor address
     */
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
}


contract Crowdsale is Ownable {
    using SafeMath for uint256;

    // The token being sold
    CryptoRoboticsToken public token;
    //MAKE APPROVAL TO Crowdsale
    address public reserve_fund = 0x7C88C296B9042946f821F5456bd00EA92a13B3BB;
    address preico;

    // Address where funds are collected
    address public wallet;

    // Amount of wei raised
    uint256 public weiRaised;

    uint256 public openingTime;
    uint256 public closingTime;

    bool public isFinalized = false;

    uint public currentStage = 0;

    uint256 public goal = 1000 ether;
    uint256 public cap  = 6840  ether;

    RefundVault public vault;



    //price in wei for stage
    uint[4] public stagePrices = [
    127500000000000 wei,     //0.000085 - ICO Stage 1
    135 szabo,     //0.000090 - ICO Stage 2
    142500000000000 wei,     //0.000095 - ICO Stage 3
    150 szabo     //0.0001 - ICO Stage 4
    ];

    //limit in wei for stage 612 + 1296 + 2052 + 2880
    uint[4] internal stageLimits = [
    612 ether,    //4800000 tokens 10% of ICO tokens (ICO token 40% of all (48 000 000) )
    1296 ether,    //9600000 tokens 20% of ICO tokens
    2052 ether,   //14400000 tokens 30% of ICO tokens
    2880 ether    //19200000 tokens 40% of ICO tokens
    ];

    mapping(address => bool) public referrals;
    mapping(address => uint) public reservedTokens;
    mapping(address => uint) public reservedRefsTokens;
    uint public amountReservedTokens;
    uint public amountReservedRefsTokens;

    event Finalized();
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokenReserved(address indexed beneficiary, uint256 value, uint256 amount, address referral);


    modifier onlyWhileOpen {
        require(now >= openingTime && now <= closingTime);
        _;
    }


    modifier onlyPreIco {
        require(msg.sender == preico);
        _;
    }


    function Crowdsale(CryptoRoboticsToken _token) public
    {
        require(_token != address(0));

        wallet = 0x3eb945fd746fbdf641f1063731d91a6fb381ea0f;
        token = _token;
        openingTime = 1526774400;
        closingTime = 1532044800;
        vault = new RefundVault(wallet);
    }


    function () external payable {
        buyTokens(msg.sender, address(0));
    }


    function buyTokens(address _beneficiary, address _ref) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);
        _getTokenAmount(weiAmount,true,_beneficiary,_ref);
    }


    function reserveTokens(address _ref) public payable {
        uint256 weiAmount = msg.value;
        _preValidateReserve(msg.sender, weiAmount, _ref);
        _getTokenAmount(weiAmount, false,msg.sender,_ref);
    }


    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view onlyWhileOpen {
        require(weiRaised.add(_weiAmount) <= cap);
        require(_weiAmount >= stagePrices[currentStage]);
        require(_beneficiary != address(0));

    }

    function _preValidateReserve(address _beneficiary, uint256 _weiAmount, address _ref) internal view {
        require(now < openingTime);
        require(referrals[_ref]);
        require(weiRaised.add(_weiAmount) <= cap);
        require(_weiAmount >= stagePrices[currentStage]);
        require(_beneficiary != address(0));
    }


    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }


    function _processPurchase(address _beneficiary, uint256 _tokenAmount, address _ref) internal {
        _tokenAmount = _tokenAmount * 1 ether;
        _deliverTokens(_beneficiary, _tokenAmount);
        if (referrals[_ref]) {
            uint _refTokens = valueFromPercent(_tokenAmount,10);
            token.transferFrom(reserve_fund, _ref, _refTokens);
        }
    }


    function _processReserve(address _beneficiary, uint256 _tokenAmount, address _ref) internal {
        _tokenAmount = _tokenAmount * 1 ether;
        _reserveTokens(_beneficiary, _tokenAmount);
        uint _refTokens = valueFromPercent(_tokenAmount,10);
        _reserveRefTokens(_ref, _refTokens);
    }


    function _reserveTokens(address _beneficiary, uint256 _tokenAmount) internal {
        reservedTokens[_beneficiary] = reservedTokens[_beneficiary].add(_tokenAmount);
        amountReservedTokens = amountReservedTokens.add(_tokenAmount);
    }


    function _reserveRefTokens(address _beneficiary, uint256 _tokenAmount) internal {
        reservedRefsTokens[_beneficiary] = reservedRefsTokens[_beneficiary].add(_tokenAmount);
        amountReservedRefsTokens = amountReservedRefsTokens.add(_tokenAmount);
    }


    function getReservedTokens() public {
        require(now >= openingTime);
        require(reservedTokens[msg.sender] > 0);
        amountReservedTokens = amountReservedTokens.sub(reservedTokens[msg.sender]);
        reservedTokens[msg.sender] = 0;
        token.transfer(msg.sender, reservedTokens[msg.sender]);
    }


    function getRefReservedTokens() public {
        require(now >= openingTime);
        require(reservedRefsTokens[msg.sender] > 0);
        amountReservedRefsTokens = amountReservedRefsTokens.sub(reservedRefsTokens[msg.sender]);
        reservedRefsTokens[msg.sender] = 0;
        token.transferFrom(reserve_fund, msg.sender, reservedRefsTokens[msg.sender]);
    }


    function valueFromPercent(uint _value, uint _percent) internal pure returns(uint amount)    {
        uint _amount = _value.mul(_percent).div(100);
        return (_amount);
    }


    function _getTokenAmount(uint256 _weiAmount, bool _buy, address _beneficiary, address _ref) internal {
        uint256 weiAmount = _weiAmount;
        uint _tokens = 0;
        uint _tokens_price = 0;
        uint _current_tokens = 0;

        for (uint p = currentStage; p < 4 && _weiAmount >= stagePrices[p]; p++) {
            if (stageLimits[p] > 0 ) {
                //если лимит больше чем _weiAmount, тогда считаем все из расчета что вписываемся в лимит
                //и выходим из цикла
                if (stageLimits[p] > _weiAmount) {
                    //количество токенов по текущему прайсу (останется остаток если прислали  больше чем на точное количество монет)
                    _current_tokens = _weiAmount.div(stagePrices[p]);
                    //цена всех монет, чтобы определить остаток неизрасходованных wei
                    _tokens_price = _current_tokens.mul(stagePrices[p]);
                    //получаем остаток
                    _weiAmount = _weiAmount.sub(_tokens_price);
                    //добавляем токены текущего стэйджа к общему количеству
                    _tokens = _tokens.add(_current_tokens);
                    //обновляем лимиты
                    stageLimits[p] = stageLimits[p].sub(_tokens_price);
                    break;
                } else { //лимит меньше чем количество wei
                    //получаем все оставшиеся токены в стейдже
                    _current_tokens = stageLimits[p].div(stagePrices[p]);
                    _weiAmount = _weiAmount.sub(stageLimits[p]);
                    _tokens = _tokens.add(_current_tokens);
                    stageLimits[p] = 0;
                    _updateStage();
                }

            }
        }

        weiAmount = weiAmount.sub(_weiAmount);
        weiRaised = weiRaised.add(weiAmount);

        if (_buy) {
            _processPurchase(_beneficiary, _tokens, _ref);
            emit TokenPurchase(msg.sender, _beneficiary, weiAmount, _tokens);
        } else {
            _processReserve(msg.sender, _tokens, _ref);
            emit TokenReserved(msg.sender, weiAmount, _tokens, _ref);
        }

        //отправляем обратно неизрасходованный остаток
        if (_weiAmount > 0) {
            msg.sender.transfer(_weiAmount);
        }

        // update state


        _forwardFunds(weiAmount);
    }


    function _updateStage() internal {
        if ((stageLimits[currentStage] == 0) && currentStage < 3) {
            currentStage++;
        }
    }


    function _forwardFunds(uint _weiAmount) internal {
        vault.deposit.value(_weiAmount)(msg.sender);
    }


    function hasClosed() public view returns (bool) {
        return now > closingTime;
    }


    function capReached() public view returns (bool) {
        return weiRaised >= cap;
    }


    function goalReached() public view returns (bool) {
        return weiRaised >= goal;
    }


    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasClosed() || capReached());

        finalization();
        emit Finalized();

        isFinalized = true;
    }


    function finalization() internal {
        if (goalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }

        uint token_balace = token.balanceOf(this);
        token_balace = token_balace.sub(amountReservedTokens);//
        token.burn(token_balace);
    }


    function addReferral(address _ref) external onlyOwner {
        referrals[_ref] = true;
    }


    function removeReferral(address _ref) external onlyOwner {
        referrals[_ref] = false;
    }


    function setPreIco(address _preico) onlyOwner public {
        preico = _preico;
    }


    function setTokenCountFromPreIco(uint _value) onlyPreIco public{
        _value = _value.div(1 ether);
        uint weis = _value.mul(stagePrices[3]);
        stageLimits[3] = stageLimits[3].add(weis);
        cap = cap.add(weis);

    }


    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

}