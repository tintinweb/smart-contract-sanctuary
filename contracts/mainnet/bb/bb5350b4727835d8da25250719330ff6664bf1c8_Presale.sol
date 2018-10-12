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

    constructor() {
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
    uint256 public partnersTokens;
    uint256 public advisorsTokens;
    uint256 public reservaTokens;

    // 7% of team tokens will be locked at this address for 1 year.
    address public teamWallet; // Team address.
    address public partnersWallet; // bountry address.
    address public advisorsWallet; // Team address.
    address public reservaWallet;

    uint public unlockTeamTokensTime = now + 365 days;

    // The main account that holds all tokens at the beginning and during tokensale.
    address public seller; // Seller address (main holder of tokens)

    uint256 public tokensSold; // (e18) Number of tokens sold through all tiers or tokensales.
    uint256 public totalSales; // Total number of sales (including external sales) made through all tiers or tokensales.

    // Lock the transfer functions during tokensales to prevent price speculations.
    bool public locked = true;
    mapping (address => bool) public walletsNotLocked;

    event SellEvent(address indexed _seller, address indexed _buyer, uint256 _value);
    event ChangeSellerEvent(address indexed _oldSeller, address indexed _newSeller);
    event Burn(address indexed _burner, uint256 _value);
    event Unlock();

    constructor (
        address _seller,
        address _teamWallet,
        address _partnersWallet,
        address _advisorsWallet,
        address _reservaWallet
    ) MultiOwnable() public {

        totalSupply    = 600000000 ether;
        saleLimit      = 390000000 ether;
        teamTokens     = 120000000 ether;
        partnersTokens =  30000000 ether;
        reservaTokens  =  30000000 ether;
        advisorsTokens =  30000000 ether;

        seller         = _seller;
        teamWallet     = _teamWallet;
        partnersWallet = _partnersWallet;
        advisorsWallet = _advisorsWallet;
        reservaWallet  = _reservaWallet;

        uint sellerTokens = totalSupply - teamTokens - partnersTokens - advisorsTokens - reservaTokens;
        balances[seller] = sellerTokens;
        emit Transfer(0x0, seller, sellerTokens);

        balances[teamWallet] = teamTokens;
        emit Transfer(0x0, teamWallet, teamTokens);

        balances[partnersWallet] = partnersTokens;
        emit Transfer(0x0, partnersWallet, partnersTokens);

        balances[reservaWallet] = reservaTokens;
        emit Transfer(0x0, reservaWallet, reservaTokens);

        balances[advisorsWallet] = advisorsTokens;
        emit Transfer(0x0, advisorsWallet, advisorsTokens);
    }

    modifier ifUnlocked(address _from, address _to) {
        //TODO: lockup excepto para direcciones concretas... pago de servicio, conversion fase 2
        //TODO: Hacer funcion que a&#241;ada direcciones de excepcion
        //TODO: Para el team hacer las exceptions
        require(walletsNotLocked[_to]);

        require(!locked);

        // If requested a transfer from the team wallet:
        // TODO: fecha cada 6 meses 25% de desbloqueo
        /*if (_from == teamWallet) {
            require(now >= unlockTeamTokensTime);
        }*/
        // Advisors: 25% cada 3 meses

        // Reserva: 25% cada 6 meses

        // Partners: El bloqueo de todos... no pueden hacer nada

        _;
    }

    /** Can be called once by super owner. */
    function unlock() onlyOwner public {
        require(locked);
        locked = false;
        emit Unlock();
    }

    function walletLocked(address _wallet) onlyOwner public {
      walletsNotLocked[_wallet] = false;
    }

    function walletNotLocked(address _wallet) onlyOwner public {
      walletsNotLocked[_wallet] = true;
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
        emit Transfer(oldSeller, newSeller, unsoldTokens);

        seller = newSeller;
        emit ChangeSellerEvent(oldSeller, newSeller);
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
        // Cambiar a hardcap en usd
        //require(tokensSold.add(_value) <= saleLimit);
        require(msg.sender == seller, "User not authorized");

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
    function transfer(address _to, uint256 _value) ifUnlocked(msg.sender, _to) public returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * Until all tokens are sold, tokens can be transfered to/from owner&#39;s accounts.
     */
    function transferFrom(address _from, address _to, uint256 _value) ifUnlocked(_from, _to) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value) public returns (bool) {
        require(_value > 0, &#39;Value is zero&#39;);

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
    uint public refundDeadlineTime;

    // Balances of beneficiaries:
    uint public balance;
    uint public balanceComision;
    uint public balanceComisionHold;
    uint public balanceComisionDone;

    // Token contract reference.
    CommonToken public token;

    uint public minPaymentUSD = 250;

    uint public minCapWei;
    uint public maxCapWei;

    uint public minCapUSD;
    uint public maxCapUSD;

    uint public startTime;
    uint public endTime;

    // Stats for current tokensale:

    uint public totalTokensSold;  // Total amount of tokens sold during this tokensale.
    uint public totalWeiReceived; // Total amount of wei received during this tokensale.
    uint public totalUSDReceived; // Total amount of wei received during this tokensale.

    // This mapping stores info on how many ETH (wei) have been sent to this tokensale from specific address.
    mapping (address => uint256) public buyerToSentWei;
    mapping (address => uint256) public sponsorToComisionDone;
    mapping (address => uint256) public sponsorToComision;
    mapping (address => uint256) public sponsorToComisionHold;
    mapping (address => uint256) public sponsorToComisionFromInversor;
    mapping (address => bool) public kicInversor;
    mapping (address => bool) public validateKYC;
    mapping (address => bool) public comisionInTokens;

    address[] public sponsorToComisionList;

    // TODO: realizar opcion de que el inversor quiera cobrar en ETH o TMSY

    event ReceiveEthEvent(address indexed _buyer, uint256 _amountWei);
    event NewInverstEvent(address indexed _child, address indexed _sponsor);
    event ComisionEvent(address indexed _sponsor, address indexed _child, uint256 _value, uint256 _comision);
    event ComisionPayEvent(address indexed _sponsor, uint256 _value, uint256 _comision);
    event ComisionInversorInTokensEvent(address indexed _sponsor, bool status);
    event ChangeEndTimeEvent(address _sender, uint _date);
    event verifyKycEvent(address _sender, uint _date, bool _status);
    event payComisionSponsorTMSY(address _sponsor, uint _date, uint _value);
    event payComisionSponsorETH(address _sponsor, uint _date, uint _value);
    event withdrawEvent(address _sender, address _to, uint value, uint _date);
    // ratio USD-ETH
    uint public rateUSDETH;

    bool public isSoftCapComplete = false;

    // Array para almacenar los inversores
    mapping(address => bool) public inversors;
    address[] public inversorsList;

    // Array para almacenar los sponsors para hacer reparto de comisiones
    mapping(address => address) public inversorToSponsor;

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


        minCapUSD = 400000;
        maxCapUSD = 4000000;
    }

    function setRatio(uint _rate) onlyOwner public returns (bool) {
      rateUSDETH = _rate;
      return true;
    }

    //TODO: validateKYC
    //En el momento que validan el KYC se les entregan los tokens

    function burn(uint _value) onlyOwner public returns (bool) {
      return token.burn(_value);
    }

    function newInversor(address _newInversor, address _sponsor) onlyOwner public returns (bool) {
      inversors[_newInversor] = true;
      inversorsList.push(_newInversor);
      inversorToSponsor[_newInversor] = _sponsor;
      emit NewInverstEvent(_newInversor,_sponsor);
      return inversors[_newInversor];
    }
    function setComisionInvesorInTokens(address _inversor, bool _inTokens) onlyOwner public returns (bool) {
      comisionInTokens[_inversor] = _inTokens;
      emit ComisionInversorInTokensEvent(_inversor, _inTokens);
      return true;
    }
    function setComisionInTokens() public returns (bool) {
      comisionInTokens[msg.sender] = true;
      emit ComisionInversorInTokensEvent(msg.sender, true);
      return true;
    }
    function setComisionInETH() public returns (bool) {
      comisionInTokens[msg.sender] = false;
      emit ComisionInversorInTokensEvent(msg.sender, false);

      return true;
    }
    function inversorIsKyc(address who) public returns (bool) {
      return validateKYC[who];
    }
    function unVerifyKyc(address _inversor) onlyOwner public returns (bool) {
      require(!isSoftCapComplete);

      validateKYC[_inversor] = false;

      address sponsor = inversorToSponsor[_inversor];
      uint balanceHold = sponsorToComisionFromInversor[_inversor];

      //Actualizamos contadores globales
      balanceComision = balanceComision.sub(balanceHold);
      balanceComisionHold = balanceComisionHold.add(balanceHold);

      //Actualizamos contadores del sponsor
      sponsorToComision[sponsor] = sponsorToComision[sponsor].sub(balanceHold);
      sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].add(balanceHold);

      //Actualizamos contador comision por inversor
    //  sponsorToComisionFromInversor[_inversor] = sponsorToComisionFromInversor[_inversor].sub(balanceHold);
      emit verifyKycEvent(_inversor, now, false);
    }
    function verifyKyc(address _inversor) onlyOwner public returns (bool) {
      validateKYC[_inversor] = true;

      address sponsor = inversorToSponsor[_inversor];
      uint balanceHold = sponsorToComisionFromInversor[_inversor];

      //Actualizamos contadores globales
      balanceComision = balanceComision.add(balanceHold);
      balanceComisionHold = balanceComisionHold.sub(balanceHold);

      //Actualizamos contadores del sponsor
      sponsorToComision[sponsor] = sponsorToComision[sponsor].add(balanceHold);
      sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].sub(balanceHold);

      //Actualizamos contador comision por inversor
      //sponsorToComisionFromInversor[_inversor] = sponsorToComisionFromInversor[_inversor].sub(balanceHold);
      emit verifyKycEvent(_inversor, now, true);
      //Enviamos comisiones en caso de tener
      /*uint256 value = sponsorToComision[_inversor];
      sponsorToComision[_inversor] = sponsorToComision[_inversor].sub(value);
      _inversor.transfer(value);*/
      return true;
    }
    function buyerToSentWeiOf(address who) public view returns (uint256) {
      return buyerToSentWei[who];
    }
    function balanceOf(address who) public view returns (uint256) {
      return token.balanceOf(who);
    }
    function balanceOfComision(address who)  public view returns (uint256) {
      return sponsorToComision[who];
    }
    function balanceOfComisionHold(address who)  public view returns (uint256) {
      return sponsorToComisionHold[who];
    }
    function balanceOfComisionDone(address who)  public view returns (uint256) {
      return sponsorToComisionDone[who];
    }

    function isInversor(address who) public view returns (bool) {
      return inversors[who];
    }
    function payComisionSponsor(address _inversor) private {
      //comprobamos que el inversor quiera cobrar en tokens...
      //si es as&#237; le pagamos directo y a&#241;adimos los tokens a su cuenta
      if(comisionInTokens[_inversor]) {
        uint256 val = 0;
        uint256 valueHold = sponsorToComisionHold[_inversor];
        uint256 valueReady = sponsorToComision[_inversor];

        val = valueReady.add(valueHold);
        //comprobamos que tenga comisiones a cobrar
        if(val > 0) {
          require(balanceComision >= valueReady);
          require(balanceComisionHold >= valueHold);
         uint256 comisionTokens = weiToTokens(val);

          sponsorToComision[_inversor] = 0;
          sponsorToComisionHold[_inversor] = 0;

          balanceComision = balanceComision.sub(valueReady);
          balanceComisionDone = balanceComisionDone.add(val);
          balanceComisionHold = balanceComisionHold.sub(valueHold);

          balance = balance.add(val);

          token.sell(_inversor, comisionTokens);
          emit payComisionSponsorTMSY(_inversor, now, val); //TYPO TMSY
        }
      } else {
        uint256 value = sponsorToComision[_inversor];

        //comprobamos que tenga comisiones a cobrar
        if(value > 0) {
          require(balanceComision >= value);

          //Si lo quiere en ETH
          //comprobamos que hayamos alcanzado el softCap
          assert(isSoftCapComplete);

          //Comprobamos que el KYC est&#233; validado
          assert(validateKYC[_inversor]);

          sponsorToComision[_inversor] = sponsorToComision[_inversor].sub(value);
          balanceComision = balanceComision.sub(value);
          balanceComisionDone = balanceComisionDone.add(value);

          _inversor.transfer(value);
          emit payComisionSponsorETH(_inversor, now, value); //TYPO TMSY

        }

      }
    }
    function payComision() public {
      address _inversor = msg.sender;
      payComisionSponsor(_inversor);
    }
    //Enviamos las comisiones que se han congelado o por no tener kyc o por ser en softcap
    /*function sendHoldComisions() onlyOwner public returns (bool) {
      //repartimos todas las comisiones congeladas hasta ahora
      uint arrayLength = sponsorToComisionList.length;
      for (uint i=0; i<arrayLength; i++) {
        // do something
        address sponsor = sponsorToComisionList[i];

        if(validateKYC[sponsor]) {
          uint256 value = sponsorToComision[sponsor];
          sponsorToComision[sponsor] = sponsorToComision[sponsor].sub(value);
          sponsor.transfer(value);
        }
      }
      return true;
    }*/
    function isSoftCapCompleted() public view returns (bool) {
      return isSoftCapComplete;
    }
    function softCapCompleted() public {
      uint totalBalanceUSD = weiToUSD(balance.div(1e18));
      if(totalBalanceUSD >= minCapUSD) isSoftCapComplete = true;
    }

    function balanceComisionOf(address who) public view returns (uint256) {
      return sponsorToComision[who];
    }

    /** The fallback function corresponds to a donation in ETH. */
    function() public payable {
        //sellTokensForEth(msg.sender, msg.value);

        uint256 _amountWei = msg.value;
        address _buyer = msg.sender;
        uint valueUSD = weiToUSD(_amountWei);

        //require(startTime <= now && now <= endTime);
        require(inversors[_buyer] != false);
        require(valueUSD >= minPaymentUSD);
        //require(totalUSDReceived.add(valueUSD) <= maxCapUSD);

        uint tokensE18SinBono = weiToTokens(msg.value);
        uint tokensE18Bono = weiToTokensBono(msg.value);
        uint tokensE18 = tokensE18SinBono.add(tokensE18Bono);

        //Ejecutamos la transferencia de tokens y paramos si ha fallado
        require(token.sell(_buyer, tokensE18SinBono), "Falla la venta");
        if(tokensE18Bono > 0)
          assert(token.sell(_buyer, tokensE18Bono));

        //repartimos al sponsor su parte 10%
        uint256 _amountSponsor = (_amountWei * 10) / 100;
        uint256 _amountBeneficiary = (_amountWei * 90) / 100;

        totalTokensSold = totalTokensSold.add(tokensE18);
        totalWeiReceived = totalWeiReceived.add(_amountWei);
        buyerToSentWei[_buyer] = buyerToSentWei[_buyer].add(_amountWei);
        emit ReceiveEthEvent(_buyer, _amountWei);

        //por cada compra miramos cual es la cantidad actual de USD... si hemos llegado al softcap lo activamos
        if(!isSoftCapComplete) {
          uint256 totalBalanceUSD = weiToUSD(balance);
          if(totalBalanceUSD >= minCapUSD) {
            softCapCompleted();
          }
        }
        address sponsor = inversorToSponsor[_buyer];
        sponsorToComisionList.push(sponsor);

        if(validateKYC[_buyer]) {
          //A&#241;adimos el saldo al sponsor
          balanceComision = balanceComision.add(_amountSponsor);
          sponsorToComision[sponsor] = sponsorToComision[sponsor].add(_amountSponsor);

        } else {
          //A&#241;adimos el saldo al sponsor
          balanceComisionHold = balanceComisionHold.add(_amountSponsor);
          sponsorToComisionHold[sponsor] = sponsorToComisionHold[sponsor].add(_amountSponsor);
          sponsorToComisionFromInversor[_buyer] = sponsorToComisionFromInversor[_buyer].add(_amountSponsor);
        }


        payComisionSponsor(sponsor);

        // si hemos alcanzado el softcap repartimos comisiones
      /*  if(isSoftCapComplete) {
          // si el sponsor ha realizado inversi&#243;n se le da la comision en caso contratio se le asigna al beneficiario
          if(balanceOf(sponsor) > 0)
            if(validateKYC[sponsor])
              sponsor.transfer(_amountSponsor);
            else {
              sponsorToComisionList.push(sponsor);
              sponsorToComision[sponsor] = sponsorToComision[sponsor].add(_amountSponsor);
            }
          else
            _amountBeneficiary = _amountSponsor + _amountBeneficiary;
        } else { //en caso contrario no repartimos y lo almacenamos para enviarlo una vez alcanzado el softcap
          if(balanceOf(sponsor) > 0) {
            sponsorToComisionList.push(sponsor);
            sponsorToComision[sponsor] = sponsorToComision[sponsor].add(_amountSponsor);
          }
          else
            _amountBeneficiary = _amountSponsor + _amountBeneficiary;
        }*/

        balance = balance.add(_amountBeneficiary);
    }

    function weiToUSD(uint _amountWei) public view returns (uint256) {
      uint256 ethers = _amountWei;

      uint256 valueUSD = rateUSDETH.mul(ethers);

      return valueUSD;
    }

    function weiToTokensBono(uint _amountWei) public view returns (uint256) {
      uint bono = 0;

      uint256 valueUSD = weiToUSD(_amountWei);

      // Calculamos bono
      //Tablas de bonos
      if(valueUSD >= uint(500 * 1e18))   bono = 10;
      if(valueUSD >= uint(1000 * 1e18))  bono = 20;
      if(valueUSD >= uint(2500 * 1e18))  bono = 30;
      if(valueUSD >= uint(5000 * 1e18))  bono = 40;
      if(valueUSD >= uint(10000 * 1e18)) bono = 50;


      uint256 bonoUsd = valueUSD.mul(bono).div(100);
      uint256 tokens = bonoUsd.mul(tokensPerUSD());

      return tokens;
    }
    /** Calc how much tokens you can buy at current time. */
    function weiToTokens(uint _amountWei) public view returns (uint256) {

        uint256 valueUSD = weiToUSD(_amountWei);

        uint256 tokens = valueUSD.mul(tokensPerUSD());

        return tokens;
    }

    function tokensPerUSD() public pure returns (uint256) {
        return 65; // Default token price with no bonuses.
    }

    function canWithdraw() public view returns (bool);

    function withdraw(address _to, uint value) public returns (uint) {
        require(canWithdraw(), &#39;No es posible retirar&#39;);
        require(msg.sender == beneficiary, &#39;S&#243;lo puede solicitar el beneficiario los fondos&#39;);
        require(balance > 0, &#39;Sin fondos&#39;);
        require(balance >= value, &#39;No hay suficientes fondos&#39;);
        require(_to.call.value(value).gas(1)(), &#39;No se que es&#39;);

        balance = balance.sub(value);
        emit withdrawEvent(msg.sender, _to, value,now);
      return balance;
    }

    //Manage timelimit. For exception
    function changeEndTime(uint _date) onlyOwner public returns (bool) {
      //TODO; quitar comentarios para el lanzamiento
      require(endTime < _date);
      endTime = _date;
      refundDeadlineTime = endTime + 3 * 30 days;
      emit ChangeEndTimeEvent(msg.sender,_date);
      return true;
    }
}


contract Presale is CommonTokensale {

    // In case min (soft) cap is not reached, token buyers will be able to
    // refund their contributions during 3 months after presale is finished.

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
      refundDeadlineTime = _endTime + 3 * 30 days;
    }

    /**
     * During presale it will be possible to withdraw only in two cases:
     * min cap reached OR refund period expired.
     */
    function canWithdraw() public view returns (bool) {
        return isSoftCapComplete;
    }

    /**
     * It will be possible to refund only if min (soft) cap is not reached and
     * refund requested during 3 months after presale finished.
     */
    function canRefund() public view returns (bool) {
        return !isSoftCapComplete && endTime < now && now <= refundDeadlineTime;
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