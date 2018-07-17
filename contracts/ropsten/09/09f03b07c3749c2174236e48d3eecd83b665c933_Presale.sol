pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}




contract ERC20 {

    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract MultiOwnable {

    mapping (address => bool) public isOwner;
    address[] public ownerHistory;

    event OwnerAddedEvent(address indexed _newOwner);
    event OwnerRemovedEvent(address indexed _oldOwner);

    constructor () {
        // Add default owner
        address owner = msg.sender;
        ownerHistory.push(owner);
        isOwner[owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender]);
        _;
    }

    function ownerHistoryCount() public view returns (uint) {
        return ownerHistory.length;
    }

    /** Add extra owner. */
    function addOwner(address owner) onlyOwner public {
        require(owner != address(0));
        require(!isOwner[owner]);
        ownerHistory.push(owner);
        isOwner[owner] = true;
        emit OwnerAddedEvent(owner);
    }

    /** Remove extra owner. */
    function removeOwner(address owner) onlyOwner public {
        require(isOwner[owner]);
        isOwner[owner] = false;
        emit OwnerRemovedEvent(owner);
    }
}









contract Pausable is MultiOwnable {

    bool public paused;

    modifier ifNotPaused {
        require(!paused);
        _;
    }

    modifier ifPaused {
        require(paused);
        _;
    }

    // Called by the owner on emergency, triggers paused state
    function pause() external onlyOwner ifNotPaused {
        paused = true;
    }

    // Called by the owner on end of emergency, returns to normal state
    function resume() external onlyOwner ifPaused {
        paused = false;
    }
}








contract StandardToken is ERC20 {

    using SafeMath for uint;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}



contract CommonToken is StandardToken, MultiOwnable {

    string public constant name   = &#39;TMSY&#39;;
    string public constant symbol = &#39;TMSY&#39;;
    uint8 public constant decimals = 18;

    uint256 public saleLimit;   // 85% of tokens for sale.
    uint256 public teamTokens;  // 7% of tokens goes to the team and will be locked for 1 year.
    uint256 public presaleLimit;
    uint256 public bountryTokens;
    uint256 public advisorsTokens;
    uint256 public airdropTokens;

    // 7% of team tokens will be locked at this address for 1 year.
    address public teamWallet; // Team address.

    uint public unlockTeamTokensTime = now + 365 days;

    // The main account that holds all tokens at the beginning and during tokensale.
    address public seller; // Seller address (main holder of tokens)

    uint256 public tokensSold; // (e18) Number of tokens sold through all tiers or tokensales.
    uint256 public totalSales; // Total number of sales (including external sales) made through all tiers or tokensales.

    // Lock the transfer functions during tokensales to prevent price speculations.
    bool public locked = true;

    event SellEvent(address indexed _seller, address indexed _buyer, uint256 _value);
    event ChangeSellerEvent(address indexed _oldSeller, address indexed _newSeller);
    event Burn(address indexed _burner, uint256 _value);
    event Unlock();

    constructor (
        address _seller,
        address _teamWallet
    ) MultiOwnable() public {

        totalSupply    = 600000000 ether;
        saleLimit      = 420000000 ether;
        presaleLimit   =  18000000 ether;
        teamTokens     =  90000000 ether;
        bountryTokens  =  18000000 ether;
        advisorsTokens =  30000000 ether;
        airdropTokens  =   6000000 ether;

        seller = _seller;
        teamWallet = _teamWallet;

        uint sellerTokens = totalSupply - teamTokens - bountryTokens - advisorsTokens - airdropTokens;
        balances[seller] = sellerTokens;
        emit Transfer(0x0, seller, sellerTokens);

        balances[teamWallet] = teamTokens;
        emit Transfer(0x0, teamWallet, teamTokens);
    }

    modifier ifUnlocked(address _from) {
        require(!locked);

        // If requested a transfer from the team wallet:
        if (_from == teamWallet) {
            require(now >= unlockTeamTokensTime);
        }

        _;
    }

    /** Can be called once by super owner. */
    function unlock() onlyOwner public {
        require(locked);
        locked = false;
        emit Unlock();
    }

    /**
     * An address can become a new seller only in case it has no tokens.
     * This is required to prevent stealing of tokens  from newSeller via
     * 2 calls of this function.
     */
    function changeSeller(address newSeller) onlyOwner public returns (bool) {
        require(newSeller != address(0));
        require(seller != newSeller);

        // To prevent stealing of tokens from newSeller via 2 calls of changeSeller:
        require(balances[newSeller] == 0);

        address oldSeller = seller;
        uint256 unsoldTokens = balances[oldSeller];
        balances[oldSeller] = 0;
        balances[newSeller] = unsoldTokens;
        Transfer(oldSeller, newSeller, unsoldTokens);

        seller = newSeller;
        ChangeSellerEvent(oldSeller, newSeller);
        return true;
    }

    /**
     * User-friendly alternative to sell() function.
     */
    function sellNoDecimals(address _to, uint256 _value) public returns (bool) {
        return sell(_to, _value * 1e18);
    }

    function sell(address _to, uint256 _value)  public returns (bool) {
        // Check that we are not out of limit and still can sell tokens:
        //require(tokensSold.add(_value) <= saleLimit);
        //require(msg.sender == seller, &quot;User not authorized&quot;);

        require(_to != address(0));
        require(_value > 0);

        require(_value <= balances[seller]);


        balances[seller] = balances[seller].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(seller, _to, _value);

        totalSales++;
        tokensSold = tokensSold.add(_value);
        emit SellEvent(seller, _to, _value);
        return true;
    }

    /**
     * Until all tokens are sold, tokens can be transfered to/from owner&#39;s accounts.
     */
    function transfer(address _to, uint256 _value) ifUnlocked(msg.sender) public returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * Until all tokens are sold, tokens can be transfered to/from owner&#39;s accounts.
     */
    function transferFrom(address _from, address _to, uint256 _value) ifUnlocked(_from) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value) public returns (bool) {
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(msg.sender, 0x0, _value);
        emit Burn(msg.sender, _value);
        return true;
    }
}




contract CommonTokensale is MultiOwnable, Pausable {

    using SafeMath for uint;

    address public beneficiary;

    // Balances of beneficiaries:
    uint public balance;

    // Token contract reference.
    CommonToken public token;

    uint public minPaymentWei = 0.1 ether;

    uint public minCapWei;
    uint public maxCapWei;

    uint public startTime;
    uint public endTime;

    // Stats for current tokensale:

    uint public totalTokensSold;  // Total amount of tokens sold during this tokensale.
    uint public totalWeiReceived; // Total amount of wei received during this tokensale.

    // This mapping stores info on how many ETH (wei) have been sent to this tokensale from specific address.
    mapping (address => uint256) public buyerToSentWei;
    mapping (address => uint256) public sponsorToComision;

    event ReceiveEthEvent(address indexed _buyer, uint256 _amountWei);

    // Array para almacenar los inversores
    mapping(address => bool) inversors;

    // Array para almacenar los sponsors para hacer reparto de comisiones
    mapping(address => address) inversorToSponsor;

    constructor (
        address _token,
        address _beneficiary,
        uint _startTime,
        uint _endTime
    ) MultiOwnable() public {

        require(_token != address(0));
        token = CommonToken(_token);

        beneficiary = _beneficiary;

        startTime = _startTime;
        endTime   = _endTime;
    }

    function newInversor(address _newInversor, address _sponsor) onlyOwner public returns (bool) {
      inversors[_newInversor] = true;
      inversorToSponsor[_newInversor] = _sponsor;
      return true;
    }

    function balanceOf(address who)  public view returns (uint256) {
      return token.balanceOf(who);
    }


    /** The fallback function corresponds to a donation in ETH. */
    function() public payable {
        //sellTokensForEth(msg.sender, msg.value);

        uint256 _amountWei = msg.value;
        address _buyer = msg.sender;


        //require(startTime <= now && now <= endTime);
        require(inversors[_buyer] != false);
        require(_amountWei >= minPaymentWei);
        require(totalWeiReceived.add(_amountWei) <= maxCapWei);


        uint tokensE18 = weiToTokens(_amountWei);
        //TODO: Revisar seguridad... Pueden comprar directamente en el token?
        require(token.sell(_buyer, tokensE18));

        //repartimos al sponsor su parte 10%
        uint256 _amountSponsor = (_amountWei * 10) / 100;
        uint256 _amountBeneficiary = (_amountWei * 90) / 100;

        totalTokensSold = totalTokensSold.add(tokensE18);
        totalWeiReceived = totalWeiReceived.add(_amountWei);
        buyerToSentWei[_buyer] = buyerToSentWei[_buyer].add(_amountWei);
        emit ReceiveEthEvent(_buyer, _amountWei);

        // si hemos alcanzado el softcap repartimos comisiones
        if(totalTokensSold >= minCapWei) {
          if(inversorToSponsor[_buyer] > 0)
            inversorToSponsor[_buyer].transfer(_amountSponsor);
          else
            _amountBeneficiary = _amountSponsor + _amountBeneficiary;
        } else { //en caso contrario no repartimos y lo almacenamos para enviarlo una vez alcanzado el softcap
          if(inversorToSponsor[_buyer] > 0)
            sponsorToComision[inversorToSponsor[_buyer]] = sponsorToComision[inversorToSponsor[_buyer]].add(_amountSponsor);
          else
            _amountBeneficiary = _amountSponsor + _amountBeneficiary;
        }

        balance = balance.add(_amountBeneficiary);
    }

    function sellTokensForEth(
        address _buyer,
        uint256 _amountWei
    ) ifNotPaused internal {

        //require(startTime <= now && now <= endTime);
        //require(_amountWei >= minPaymentWei);
        //require(totalWeiReceived.add(_amountWei) <= maxCapWei);

        uint tokensE18 = weiToTokens(_amountWei);
        // Transfer tokens to buyer.
        //require(token.sell(_buyer, tokensE18));

        // Update total stats:
        totalTokensSold = totalTokensSold.add(tokensE18);
        totalWeiReceived = totalWeiReceived.add(_amountWei);
        buyerToSentWei[_buyer] = buyerToSentWei[_buyer].add(_amountWei);
        emit ReceiveEthEvent(_buyer, _amountWei);

        // Split received amount between balances of three beneficiaries.
        balance = balance.add(_amountWei);
    }

    /** Calc how much tokens you can buy at current time. */
    function weiToTokens(uint _amountWei) public view returns (uint) {
        return _amountWei.mul(tokensPerWei(_amountWei));
    }

    function tokensPerWei(uint _amountWei) public view returns (uint256) {
        uint expectedTotal = totalWeiReceived.add(_amountWei);

        // Presale pricing rules:
        if (expectedTotal <  400 ether) return 49057;
        if (expectedTotal <  800 ether) return 41510;
        if (expectedTotal <  1800 ether) return 35972;

        // Public sale pricing rules:
        if (expectedTotal <  3000 ether) return 33727;
        if (expectedTotal <  5000 ether) return 31743;
        if (expectedTotal <  7000 ether) return 29980;
        if (expectedTotal < 10000 ether) return 28402;
        if (expectedTotal < 14000 ether) return 26982;

        return 26982; // Default token price with no bonuses.
    }

    function canWithdraw() public view returns (bool);

    function withdraw(address _to, uint value) public returns (uint) {
        require(canWithdraw());
        require(msg.sender == beneficiary);
        require(balance > 0);
        require(balance >= value);
        require(_to.call.value(value).gas(1)());

        balance = balance.sub(value);
        return balance;
    }
}


contract Presale is CommonTokensale {

    // In case min (soft) cap is not reached, token buyers will be able to
    // refund their contributions during 3 months after presale is finished.
    uint public refundDeadlineTime;

    // Total amount of wei refunded if min (soft) cap is not reached.
    uint public totalWeiRefunded;

    event RefundEthEvent(address indexed _buyer, uint256 _amountWei);

    constructor(
        address _token,
        address _beneficiary,
        uint _startTime,
        uint _endTime
    ) CommonTokensale(
        _token,
        _beneficiary,
        _startTime,
        _endTime
    ) public {
        minCapWei = 400 ether;
        maxCapWei = 800 ether;
        refundDeadlineTime = _endTime + 3 * 30 days;
    }

    /**
     * During presale it will be possible to withdraw only in two cases:
     * min cap reached OR refund period expired.
     */
    function canWithdraw() public view returns (bool) {
        return totalWeiReceived >= minCapWei || now > refundDeadlineTime;
    }
    
    /**
     * It will be possible to refund only if min (soft) cap is not reached and
     * refund requested during 3 months after presale finished.
     */
    function canRefund() public view returns (bool) {
        return totalWeiReceived < minCapWei && endTime < now && now <= refundDeadlineTime;
    }

    function refund() public {
        require(canRefund());

        address buyer = msg.sender;
        uint amount = buyerToSentWei[buyer];
        require(amount > 0);

        // Redistribute left balance between three beneficiaries.
        uint newBal = balance.sub(amount);
        balance = newBal;

        emit RefundEthEvent(buyer, amount);
        buyerToSentWei[buyer] = 0;
        totalWeiRefunded = totalWeiRefunded.add(amount);
        buyer.transfer(amount);
    }
}