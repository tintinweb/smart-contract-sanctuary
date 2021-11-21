/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

pragma solidity 0.6.8;


contract Prosus_AMM {
    address payable public deployer;
    
    /*=================================
    =          MODIFICADORES          =
    =================================*/
    // sólo quienes tienen Prosus-BSC
    modifier conTokens() {
        require(myTokens() > 0);
        _;
    }
    
    // sólo quienes tienen ganancias
    modifier conGanancias() {
        require(myDividends(true) > 0);
        _;
    }
    
    /*==============================
    =           EVENTOS            =
    ==============================*/
    event onTokenPurchase(address indexed customerAddress, uint256 incomingBNB, uint256 tokensMinted, address indexed referredBy);
    event onTokenSell(address indexed customerAddress, uint256 tokensBurned, uint256 bnbEarned);
    event onReinvestment(address indexed customerAddress, uint256 bnbReinvested, uint256 tokensMinted);
    event onWithdraw(address indexed customerAddress, uint256 bnbWithdrawn);
    
    // BEP20
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Prosus-BSC"; // BSC = "Binance Smart Chain"
    string public symbol = "PROSUS";
    
    uint8 constant public decimals = 12;
    uint8 constant internal dividendFee_ = 10;
    
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether; // ether en BSC = BNB
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether; // ether en BSC = BNB
    uint256 constant internal magnitude = 2**64;
    
   /*================================
    =            DATASETS         	=
    ===============================*/
    // cantidad de acciones para cada dirección (número escalado)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    
    // otras métricas
    mapping(address => bool) internal activatedPlayer_;
    
    mapping(address => uint256) internal referralsOf_;
    mapping(address => uint256) internal referralEarningsOf_;
    
    uint256 internal players;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
    /*=======================================
    =            FUNCIONES PÜBLICAS         =
    =======================================*/

    constructor() public {
        deployer = msg.sender;
    }
     
    // Convierte todos los BNB entrantes en Prosus-BSC, para cada usuario. Y agrega un complemento para referidos (si corresponde).
    function buy(address _referredBy) public payable returns(uint256) {
        
        // Depositar BNB en el contrato; crear los tokens.
        purchaseTokens(msg.value, _referredBy);
        
		// Si los depósitos 'msgSender = 0' , significa que es el primer depósito.
        // Por esto, se agrega 1 al recuento total de jugadores y al contador de sus referidos.
        if (activatedPlayer_[msg.sender] == false) {
            activatedPlayer_[msg.sender] = true;
            players += 1;
            referralsOf_[_referredBy] += 1;
        }
    }
    
    // Función de respaldo para manejar BNB enviados directamente al contrato: "deployer" es el referido.
    receive() payable external {
        purchaseTokens(msg.value, deployer);
    }
    
    // Convertir todas las llamadas (de dividendos) en Prosus-BSC.
    function reinvest() conGanancias() public {
        // obtener dividendos
        uint256 _dividends = myDividends(false); // recuperar bono de referidos (ver el código a continuación)
        
        // pagar (virtualmente) dividendos
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

        // recuperar bono de referidos
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // ejecutar una orden de compra, usando el retiro de dividendos ("virtualmente").
        uint256 _tokens = purchaseTokens(_dividends, deployer);
        
        // disparar evento
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
    // Alias para vender y girar (retirar).
    function exit() public {
        // Obtener el recuento de tokens para la persona que lo solicita y venderlos todos.
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
        
		// ejecutar
        withdraw();
    }

    // Retira todas las ganancias de las personas que lo solicitan.
    function withdraw() conGanancias() public {
        // datos de configuración
        address payable _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // tomar bono de referidos (más adelante en el código)
        
        // actualizar el trazador de dividendos
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // agregar bono de referidos
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // ejecutar
        _customerAddress.transfer(_dividends);
        
        // disparar evento
        emit onWithdraw(_customerAddress, _dividends);
    }
    
    // liquidar Prosus-BSC (convertirlos a BNB)
    function sell(uint256 _amountOfTokens) conTokens() public {
        // datos de configuración
        address _customerAddress = msg.sender;
        // seguridad
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _bnb = tokensToBNB_(_tokens);
        uint256 _dividends = SafeMath.div(_bnb, dividendFee_);
        uint256 _taxedBNB = SafeMath.sub(_bnb, _dividends);
        
        // quemar los tokens vendidos
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        
        // actualizar el trazador de dividendos
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedBNB * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;       
        
        // evitar dividir por cero
        if (tokenSupply_ > 0) {
            // actualizar la cantidad de dividendos por cada token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        
        // disparar evento
        emit onTokenSell(_customerAddress, _tokens, _taxedBNB);
    }
    
    
    // Transferir Prosus-BSC a una dirección diferente. No se incluye la comisión.
     function transfer(address _toAddress, uint256 _amountOfTokens) conTokens() public returns(bool) {
        // No se puede enviar cantidad vacía.
        require(_toAddress != address(0));
        // configurar
        address _customerAddress = msg.sender;

        // asegurar que tengamos los tokens solicitados
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // retirar todos los dividendos pendientes primero
        if(myDividends(true) > 0) withdraw();

        // intercambiar tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

        // actualizar el trazador de dividendos
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);

        // dispara evento
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);

        // BEP20
        return true;
    }
    
    /*----------  AUXILIARES ("helpers") Y CÁLCULOS  ----------*/
    
    // Buscar amigos activos en el juego
    function playerStatus(address _player) public view returns (bool) {
        return activatedPlayer_[_player];
    }
    
    function myTotalReferrals() public view returns (uint) {
        return referralsOf_[msg.sender];
    }
    
    function myTotalReferralEarnings() public view returns (uint) {
        return referralEarningsOf_[msg.sender];
    }
    
    // ----------
    
    function totalReferralsOf(address _user) public view returns (uint) {
        return referralsOf_[_user];
    }
    
    function totalReferralEarningsOf(address _user) public view returns (uint) {
        return referralEarningsOf_[_user];
    }
    
    // ----------
    
    // Método para ver los BNB vigentes, almacenados en el contrato.
    function totalBNBBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    // Obtener cantidad total de Prosus-BSC ("suministro").
    function totalSupply() public view returns(uint256) {
        return tokenSupply_;
    }
    
    // Obtener cantidad de tokens que posee el usuario.
    function myTokens() public view returns(uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
    
    /**
	 * Recuperar los dividendos pertenecientes a la persona que lo solicita.
     * Si `_includeReferralBonus` es 1 (verdadero), el bono de referidos se incluirá en los cálculos.
     * La razón de esto es que, en la interfaz, debe aparecer los dividendos totales (global + referidos)
     * pero en los cálculos internos los queremos por separado.
     */ 
    function myDividends(bool _includeReferralBonus) public view returns(uint256) {
        address _customerAddress = msg.sender;
        return dividendsOf(_customerAddress,_includeReferralBonus);
    }
    
    // Recuperar el balance de los token, de una sola dirección.
    function balanceOf(address _customerAddress) view public returns(uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    // Recuperar el balance de los dividendos, de una sola dirección.
    function dividendsOf(address _customerAddress,bool _includeReferralBonus) view public returns(uint256) {
        uint256 regularDividends = (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
        if (_includeReferralBonus){
            return regularDividends + referralBalance_[_customerAddress];
        } else {
            return regularDividends;
        }
    }
    
    // Obtener el precio de compra de un solo token.
    function sellPrice() public view returns(uint256) {
        // se necesita un valor para calcular el suministro.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _bnb = tokensToBNB_(1e12);
            uint256 _dividends = SafeMath.div(_bnb, dividendFee_  );
            uint256 _taxedBNB = SafeMath.sub(_bnb, _dividends);
            return _taxedBNB;
        }
    }
    
    // Obtener el precio de venta de un solo token.
    function buyPrice() public view returns(uint256) {
        // se necesita un valor para calcular el suministro de tokens.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _bnb = tokensToBNB_(1e12);
            uint256 _dividends = SafeMath.div(_bnb, dividendFee_  );
            uint256 _taxedBNB = SafeMath.add(_bnb, _dividends);
            return _taxedBNB;
        }
    }
    
    // Función para que la interfaz recupere dinámicamente la escala de precios de las órdenes de compra.
    function calculateTokensReceived(uint256 _bnbToSpend) public view returns(uint256) {
        uint256 _dividends = SafeMath.div(_bnbToSpend, dividendFee_);
        uint256 _taxedBNB = SafeMath.sub(_bnbToSpend, _dividends);
        uint256 _amountOfTokens = bnbToTokens_(_taxedBNB);
        
        return _amountOfTokens;
    }
    
    // Función de la interfaz para recuperar dinámicamente la escala de precios de las órdenes de venta.
    function calculateBNBReceived(uint256 _tokensToSell) public view returns(uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _bnb = tokensToBNB_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_bnb, dividendFee_);
        uint256 _taxedBNB = SafeMath.sub(_bnb, _dividends);
        return _taxedBNB;
    }
    
    
    /*==========================================
    =            FUNCIONES INTERNAS            =
    ==========================================*/
    function purchaseTokens(uint256 _incomingBNB, address _referredBy) internal returns(uint256) {
        // datos de configuración
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingBNB, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedBNB = SafeMath.sub(_incomingBNB, _undividedDividends);
        uint256 _amountOfTokens = bnbToTokens_(_taxedBNB);
        uint256 _fee = _dividends * magnitude;
 
        // prevenir saturación
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
        if(
            // es una compra por referidos?
            _referredBy != 0x0000000000000000000000000000000000000000
        ){
            // redistribución de la riqueza
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
			// sin compras desde referidos
            // se agrega bono de referencia nuevamente al reparto global de dividendos.
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        
        // Para no entregar BNB infinito a los usuarios.
        if(tokenSupply_ > 0){
            
            // agregar tokens a una pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
 
            // tomar la cantidad de dividendos obtenidos a través de esta transacción y distribuirlos uniformemente a cada participante
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            
            // calcular la cantidad de tokens que recibe el usuario cuando compra
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
        
        } else {
            // agregar tokens a la pool
            tokenSupply_ = _amountOfTokens;
        }
        
        // actualizar el suministro en circulación y la dirección del libro mayor, para el usuario.
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
		// Le dice al contrato que el comprador no debe tener dividendos por los tokens antes de poseerlos.
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        
        referralEarningsOf_[_referredBy] += (_referralBonus);
        
        // disparar evento
        emit onTokenPurchase(_customerAddress, _incomingBNB, _amountOfTokens, _referredBy);
        
        return _amountOfTokens;
    }

    // Calcular el precio de Prosus-BSC en función de la cantidad de BNB entrantes.
	// Se realizan algunas conversiones para evitar errores decimales o [sub]desbordamientos en el código Solidity.
    function bnbToTokens_(uint256 _bnb) internal view returns(uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e12;
        uint256 _tokensReceived = 
         (
            (
                // seguridad: intentos de desbordamiento
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e12)*(_bnb * 1e12))
                            +
                            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(tokenSupply_)
        ;
  
        return _tokensReceived;
    }
    
    // Calcular el precio de venta de Prosus-BSC.
	// Se realizan algunas conversiones para evitar errores decimales o [sub]desbordamientos en el código Solidity.
     function tokensToBNB_(uint256 _tokens) internal view returns(uint256) {
        uint256 tokens_ = (_tokens + 1e12);
        uint256 _tokenSupply = (tokenSupply_ + 1e12);
        uint256 _etherReceived =
        (
            // seguridad: intentos de desbordamiento.
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e12))
                        )-tokenPriceIncremental_
                    )*(tokens_ - 1e12)
                ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e12))/2
            )
        /1e12);
        return _etherReceived;
    }
    
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}




/**
 * @title SafeMath
 * @dev Operaciones matemáticas para los mensajes de error en los controles de seguridad.
 */
library SafeMath {

    /**
    * @dev Multiplicar dos números, con desbordamiento.
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
    * @dev División entera de dos números, truncando el cociente.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity ya advierte automáticamente al dividir por cero.
        uint256 c = a / b;
        // assert(a == b * c + a % b); // En ningún caso esto se mantiene.
        return c;
    }

    /**
    * @dev Resta dos números, con desbordamiento si el sustraendo es mayor que el minuendo.
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Suma dos números, con desbordamiento.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}




 /*================================
 =            CRÉDITOS            =
 ================================*/
 // autor: Prosus Corp (research and technological development)
 // mantenimiento: YerkoBits
 // SPDX-License-Identifier: MIT
 // open-source: Prosus-BSC está basado en varios contratos de código abierto, principalmente Hourglass, StrongHands, Gauntlet.