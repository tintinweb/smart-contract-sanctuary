/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// File: contracts/order-book-v4.sol

pragma solidity ^0.5.7;

interface IERC20 {
    /* This is a slight change to the IERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract ERC20 is IERC20 {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    string public symbol;                 //An identifier: eg SBX

    /// total amount of tokens
    uint256 public totalSupply;
    
    //How many decimals to show.
    uint256 public decimals; // 256 to avoid overflow on crowdsale

    constructor(address _manager, uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol
    ) public {
        balances[_manager] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 _allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && _allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (_allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor() public {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

contract OrderBookDEX is ReentrancyGuard {

    address private master;

    uint256 commission;

    address token_reward;

    mapping(
        address => uint256
    ) private wei_rewards_rate_by_token;

    using SafeMath for uint256;

    // users balances: users_balances[wbtc][pedro] > 300000000 => 3 WBTC
    mapping(address => mapping(address => uint256)) private users_balances;

    // open orders
    struct OpenSellOrder { 
       uint256 opening;   // creation time
       address user;        // user that creates the order
       uint256 amount;      // amount to sell of the token to sell (1st token) with 1st token decimals
       uint256 price;       // price to sell with the decimals of the token to sell (1st token)
       uint8 order_type;    // 0: Market Sell, 1: Limit Sell, 2: Market Buy, 3: Limit Buy
    }

    mapping(
        address => mapping( // token to sell
            address =>      // token to get
                OpenSellOrder[]
        )
    ) private open_limit_sell_orders;

    mapping(
        address => mapping( // token to sell
            address =>      // token to get
                OpenSellOrder[]
        )
    ) private open_limit_sell_orders_aux;

    struct CloseSellOrder { 
       uint256 opening;     // creation time
       uint256 amount;      // amount to sell with the decimals of the token to sell (1st token)
       uint256 price;       // price to sell with the decimals of the token to sell (1st token)
       uint8 order_type;    // 0: Market Sell, 1: Limit Sell, 2: Market Buy, 3: Limit Buy
       uint256 closing;     // closing time
    }

    mapping(
        address => mapping(     // user
            address => mapping( // token to sell
                address =>      // token to get
                    CloseSellOrder[]
            )
        )
    ) private orders_archive;

    event policia(string txt, uint value);

    mapping(
        address => mapping(     // token_buy
            address => uint256 // token sell => price of 1 token buy in token sells
        )
    ) private prices;

    /*

    - stats24hr(token_to_buy, token_to_pay)

        Ejemplo: 
        stats24hr(“0x123...”, “0x345...”)
                ^ WBTC    ^ USDT

        Devuelve:

        {
            “last_price”: 33000000000, 
            “yesterday_price”: 29098536758, 

                Formula:
                (1 - yesterday / today) * 100

            “high”: 34869068445, 
            “low”: 28869068445, 
            “volume”: 12328869068445, 
        }

    */
    struct stats24hr { 
       uint256 yesterday_price;
       uint256 today_year;
       uint256 today_month;
       uint256 today_day;
       uint256 last_price;
       uint256 high;
       uint256 low;
       uint256 volume;
    }
    mapping(
        address => mapping(     // token_buy
            address => stats24hr // token sell => stats
        )
    ) public arrStats24hr;

    constructor(uint256 _commission) public {
        require(_commission<=100, "Commission cant be higher than 100");
        commission = _commission;
        master = msg.sender;
    }

    modifier onlyMaster() {
        require(msg.sender == master, "Not authorized");
        _;
    }

    function updateMaster(address _master) public onlyMaster {
        master = _master;
    }

    function updateCommission(uint256 _commission) public onlyMaster {
        require(_commission<=100, "Commission cant be higher than 100");
        commission = _commission;
    }

    function updateRewardToken(address token) public onlyMaster {
        token_reward = token;
    }

    function updateRewardRateByToken(address token, uint256 reward) public onlyMaster {
        wei_rewards_rate_by_token[token] = reward;
    }

    function updateStats24hr(address token2buy, address token2sell, uint256 price, uint256 amount) private {

        (uint256 year, uint256 month, uint256 day ) = timestampToDate();

        // si hoy no es hoy y si hoy existe
        if (
            arrStats24hr[token2buy][token2sell].today_year > 0 &&
            arrStats24hr[token2buy][token2sell].today_day != day
        ) {
            // actualiza la data de ayer con la de hoy
            arrStats24hr[token2buy][token2sell].yesterday_price = arrStats24hr[token2buy][token2sell].last_price;
        }

        // si hoy no existe agregarlo
        if (
            // inicializar el primer hoy
            (
                arrStats24hr[token2buy][token2sell].today_year == 0
            ) ||
            // actualizar el hoy
            (
                arrStats24hr[token2buy][token2sell].today_year > 0 &&
                arrStats24hr[token2buy][token2sell].today_day != day
            ) 
        ) {
            arrStats24hr[token2buy][token2sell].today_year = year;
            arrStats24hr[token2buy][token2sell].today_month = month;
            arrStats24hr[token2buy][token2sell].today_day = day;
            arrStats24hr[token2buy][token2sell].high = price;
            arrStats24hr[token2buy][token2sell].low = price;
            arrStats24hr[token2buy][token2sell].volume = 0;
        }

        // actualiza la data de hoy
        if (arrStats24hr[token2buy][token2sell].high < price) {
            arrStats24hr[token2buy][token2sell].high = price;
        }
        if (arrStats24hr[token2buy][token2sell].low > price) {
            arrStats24hr[token2buy][token2sell].low = price;
        }
        arrStats24hr[token2buy][token2sell].last_price = price;
        arrStats24hr[token2buy][token2sell].volume += amount;
    }

    function timestampToDate() internal view returns (uint year, uint month, uint day) {

        uint256 __days = now / 86400;

        uint256 L = __days + 68569 + 2440588;
        uint256 N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        uint256 _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        uint256 _month = 80 * L / 2447;
        uint256 _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);

    }

    // Deposit, requires approval
    function deposit(ERC20 token, uint256 amount) public nonReentrant {
        token.transferFrom(msg.sender, address(this), amount);
        users_balances[address(token)][msg.sender] += amount;
    }

    // Withdraw
    function withdraw(ERC20 token, uint256 amount) public nonReentrant {
        token.transfer(msg.sender, amount);
        users_balances[address(token)][msg.sender] -= amount;
    }

    // User balances
    function balances(address[] memory tokens) public view
        returns (uint256[] memory) {
        
        uint256[] memory the_balances = new uint256[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {
            the_balances[i] = users_balances[tokens[i]][msg.sender];
        }

        return the_balances;
    }

    event Sell(address seller, address token2sell, address buyer, address token2pay, uint256 amount);

    function minusCommission(uint256 amount) private view returns (uint256) {
        return amount.sub(theCommission(amount));        
    }

    function theCommission(uint256 amount) private view returns (uint256) {
        return amount.mul(commission).div(100);
    }

    /*
        Si usuario compra 15 USDT (15000000 USDT) y la tasa es 2000 tokens weis por USD entonces el reward es:
            (15000000 /10**6) * 2000
            (tokens_spent / 10**decimals_tokens_spend) * rate
            (tokens_spent  * rate) / 10**decimals_tokens_spend
            (15000000  * 2000) / 10**6 = 30000 weis of tokens
    */
    function reward(address user, ERC20 token, uint256 amount) private {
        if (token_reward!=address(0)) {
            users_balances[token_reward][user] += getReward(token, amount);
        }
    }
    
    function getReward(ERC20 token, uint256 amount) private view returns (uint256) {
        return amount * wei_rewards_rate_by_token[address(token)] / 10 ** token.decimals();
    }

    /*
    Devuelve:
    {
        “fee”: 67000000, <--- 67 USDT (6 decimales)
        “rewards”: 6700000000000000000000, <--- 6700 SwapreX (18 decimales)
        “total”: 67000000000, <--- 67000 USDT (6 decimales)
    }
    */

    // order type = 1
    function getQuoteLimitSell(ERC20 token2sell, uint256 amount2sell, ERC20 token2get, uint256 sellPrice) public view
        returns (uint256 ret_fee, uint256 ret_rewards, uint256 ret_total) {

        uint256 how_much_to_spend;

        how_much_to_spend = amount2sell.mul(sellPrice).div(10**token2sell.decimals());

        uint trade_amount1;
        uint trade_amount2;
        
        for (uint i = 0; 
             i < open_limit_sell_orders[address(token2get)][address(token2sell)].length && how_much_to_spend>0; 
             i++
        ) {

            if (
                (
                    sellPrice > 0 && 
                    open_limit_sell_orders[address(token2get)][address(token2sell)][i].price <= (10**token2get.decimals() * 10**token2sell.decimals()) / sellPrice 
                )
            ) {

                if (how_much_to_spend <= open_limit_sell_orders[address(token2get)][address(token2sell)][i].amount) {
                    trade_amount1 = how_much_to_spend;
                } else {
                    trade_amount1 = open_limit_sell_orders[address(token2get)][address(token2sell)][i].amount;
                }

                if (trade_amount1 == 0) continue;

                trade_amount2 = (trade_amount1.mul(
                    open_limit_sell_orders[address(token2get)][address(token2sell)][i].price // price_sell
                )).div(10**token2get.decimals());

                if (users_balances[address(token2get)][
                        open_limit_sell_orders[address(token2get)][address(token2sell)][i].user
                    ] >= trade_amount1 && users_balances[address(token2sell)][msg.sender] >= trade_amount2) {

                    ret_rewards += getReward(ERC20(address(token2sell)), trade_amount2);
                    ret_total += trade_amount1;
                    ret_fee += theCommission(trade_amount1);

                    how_much_to_spend = how_much_to_spend.sub(trade_amount1);

                    amount2sell = amount2sell.sub(trade_amount2);

                }

            }

        }
        
        return (ret_fee, ret_rewards, ret_total);

    }

    function getQuoteLimitSell2(ERC20 token2sell, uint256 amount2sell, ERC20 token2get, uint256 sellPrice) public view
        returns (uint256 ret_fee, uint256 ret_rewards, uint256 ret_total) {

        uint256 how_much_to_spend;

        how_much_to_spend = amount2sell.mul(sellPrice).div(10**token2sell.decimals());

        uint trade_amount1;
        uint trade_amount2;
        
        for (uint i = 0; 
             i < open_limit_sell_orders[address(token2get)][address(token2sell)].length && how_much_to_spend>0; 
             i++
        ) {

            if (
                (
                    sellPrice > 0 && 
                    open_limit_sell_orders[address(token2get)][address(token2sell)][i].price <= (10**token2get.decimals() * 10**token2sell.decimals()) / sellPrice 
                )
            ) {

                if (how_much_to_spend <= open_limit_sell_orders[address(token2get)][address(token2sell)][i].amount) {
                    trade_amount1 = how_much_to_spend;
                } else {
                    trade_amount1 = open_limit_sell_orders[address(token2get)][address(token2sell)][i].amount;
                }

                if (trade_amount1 == 0) continue;

                trade_amount2 = (trade_amount1.mul(
                    open_limit_sell_orders[address(token2get)][address(token2sell)][i].price // price_sell
                )).div(10**token2get.decimals());

                if (users_balances[address(token2get)][
                        open_limit_sell_orders[address(token2get)][address(token2sell)][i].user
                    ] >= trade_amount1 && users_balances[address(token2sell)][msg.sender] >= trade_amount2) {

                    ret_rewards += getReward(ERC20(address(token2sell)), trade_amount2);
                    ret_total += trade_amount1;
                    ret_fee += theCommission(trade_amount1);

                    how_much_to_spend = how_much_to_spend.sub(trade_amount1);

                    amount2sell = amount2sell.sub(trade_amount2);

                }

            }

        }
        
        return (ret_fee, ret_rewards, ret_total);

    }

    function getQuoteLimitSell3(ERC20 token2sell, uint256 amount2sell, ERC20 token2get, uint256 sellPrice) public view
        returns (uint256 ret_fee, uint256 ret_rewards, uint256 ret_total) {

        uint256 how_much_to_spend;

        how_much_to_spend = amount2sell.mul(sellPrice).div(10**token2sell.decimals());

        uint trade_amount1;
        uint trade_amount2;
        
        for (uint i = 0; 
             i < open_limit_sell_orders[address(token2get)][address(token2sell)].length && how_much_to_spend>0; 
             i++
        ) {

            if (
                (
                    sellPrice > 0 && 
                    open_limit_sell_orders[address(token2get)][address(token2sell)][i].price <= (10**token2get.decimals() * 10**token2sell.decimals()) / sellPrice 
                )
            ) {

                if (how_much_to_spend <= open_limit_sell_orders[address(token2get)][address(token2sell)][i].amount) {
                    trade_amount1 = how_much_to_spend;
                } else {
                    trade_amount1 = open_limit_sell_orders[address(token2get)][address(token2sell)][i].amount;
                }

                if (trade_amount1 == 0) continue;

                trade_amount2 = (trade_amount1.mul(
                    open_limit_sell_orders[address(token2get)][address(token2sell)][i].price // price_sell
                )).div(10**token2get.decimals());

                if (users_balances[address(token2get)][
                        open_limit_sell_orders[address(token2get)][address(token2sell)][i].user
                    ] >= trade_amount1 && users_balances[address(token2sell)][msg.sender] >= trade_amount2) {

                    ret_rewards += getReward(ERC20(address(token2sell)), trade_amount2);
                    ret_total += trade_amount1;
                    ret_fee += theCommission(trade_amount1);

                    how_much_to_spend = how_much_to_spend.sub(trade_amount1);

                    amount2sell = amount2sell.sub(trade_amount2);

                }

            }

        }
        
        return (ret_fee, ret_rewards, ret_total);

    }

    function getQuoteLimitSell4(ERC20 token2sell, uint256 amount2sell, ERC20 token2get, uint256 sellPrice) public view
        returns (uint256 ret_fee, uint256 ret_rewards, uint256 ret_total) {

        uint256 how_much_to_spend;

        how_much_to_spend = amount2sell.mul(sellPrice).div(10**token2sell.decimals());

        uint trade_amount1;
        uint trade_amount2;
        
        for (uint i = 0; 
             i < open_limit_sell_orders[address(token2get)][address(token2sell)].length && how_much_to_spend>0; 
             i++
        ) {

            if (
                (
                    sellPrice > 0 && 
                    open_limit_sell_orders[address(token2get)][address(token2sell)][i].price <= (10**token2get.decimals() * 10**token2sell.decimals()) / sellPrice 
                )
            ) {

                if (how_much_to_spend <= open_limit_sell_orders[address(token2get)][address(token2sell)][i].amount) {
                    trade_amount1 = how_much_to_spend;
                } else {
                    trade_amount1 = open_limit_sell_orders[address(token2get)][address(token2sell)][i].amount;
                }

                if (trade_amount1 == 0) continue;

                trade_amount2 = (trade_amount1.mul(
                    open_limit_sell_orders[address(token2get)][address(token2sell)][i].price // price_sell
                )).div(10**token2get.decimals());

                if (users_balances[address(token2get)][
                        open_limit_sell_orders[address(token2get)][address(token2sell)][i].user
                    ] >= trade_amount1 && users_balances[address(token2sell)][msg.sender] >= trade_amount2) {

                    ret_rewards += getReward(ERC20(address(token2sell)), trade_amount2);
                    ret_total += trade_amount1;
                    ret_fee += theCommission(trade_amount1);

                    how_much_to_spend = how_much_to_spend.sub(trade_amount1);

                    amount2sell = amount2sell.sub(trade_amount2);

                }

            }

        }
        
        return (ret_fee, ret_rewards, ret_total);

    }



    /**
     *
     ********************************************************************************************************************************
     **********************************************************            **********************************************************
     ********************************************************** LIMIT SELL **********************************************************
     **********************************************************            **********************************************************
     ********************************************************************************************************************************
     *
     *******************************************************************************************************************************
     *
     *          CASO 1: D quiere vender 2 WBTC a 33500 USDT
     *
     *******************************************************************************************************************************
     */

    function limitSell(ERC20 token2sell, uint256 amount2sell, ERC20 token2get, uint256 sellPrice, uint8 theOrderType) public {

        emit policia("theOrderType", theOrderType);

        /*
        
        Si existen varias órdenes de compra de este par se ejecutarán primero las órdenes de compra con mayor precio que hagan match 
        con la orden de compra.

        Ejemplo si existen tres órdenes de compra de WBTC:

        La primera comprando 0.1 WBTC a 33600 USDT
        La segunda comprando 0.2 WBTC a 33600 USDT
        La tercera comprando 1 WBTC a 33500 USDT
        La cuarta comprando 1 WBTC a 33400 USDT 

        Supongamos que el usuario quiere vender 2 WBTC a 33500 USDT esto es:

        limitSell(wbtc, 200000000, usdt, 33500000000)

        ------------ market sell, el usuario quiere vender 2 WBTC a precio de mercado
        ------------         limitSell(wbtc, 200000000, usdt, 0)

        ------------------------- market buy el usuario quiere comprar 2 WBTC a precio de mercado pagando en USDT
        ------------------------- marketBuy(wbtc, 200000000, usdt)
        ------------------------- esto equivalente a decir que quiere vender USDT a cambio de WBTC, obteniendo maximo 2 WBTC a precio de mercado
        ------------------------- limitSell(usdt, 200000000, wbtc)
        ------------------------- aqui amount2sell es maximo a obtener de wbtc vendiendo usdt

        Entonces se venden 0.3 WBTC a 33600, 1 WBTC a 33500 y queda pendiente 0.7 WBTC para vender a 33500 USDT.

        Order Book:

        User    Sell amount     Sell price      Buy amount      Buy price
        A'                                      0.1 WBTC        33600 USDT
        A''                                     0.2 WBTC        33600 USDT
        B                                       1   WBTC        33500 USDT
        C                                       1   WBTC        33400 USDT
        D       2 WBTC          33500 USDT

        Luego de esto el Order Book queda:

        User    Sell amount     Sell price      Buy amount      Buy price
        C                                       1               33400 USDT
        D       0.7 WBTC        33500

        Esto traducido a sell orders queda:

        A'  quiere vender 3360 USDT  a cambio de WBTC por 1 / 33600 = 0,00002976 WBTC por dolar
        A'' quiere vender 6720 USDT  a cambio de WBTC por 1 / 33600 = 0,00002976 WBTC por dolar
        B   quiere vender 33500 USDT a cambio de WBTC por 1 / 33500 = 0,00002985 WBTC por dolar
        C   quiere vender 33400 USDT a cambio de WBTC por 1 / 33400 = 0,00002994 WBTC por dolar
        D   quiere vender 2 WBTC     a cambio de USDT por 33500 USDT

        Como el usuario D quiere vender 2 WBTC a cambio de USDT, tomamos el precio maximo que el usuario quiere pagar por los USDT en WBTC:

        1 / 33500 = 0,00002985 ==> 
        10**token2get.decimals() * 10**token2sell.decimals() / sellPrice
        1000000 * 100000000 / 33500000000 
        2985 ================================> price_buy

*/

        uint256 pow_decimals_get =  10**token2get.decimals();
        uint256 pow_decimals_sell = 10**token2sell.decimals();
        uint256 price_buy;
        // --------------- market sell; price_buy es 0
        if (sellPrice > 0) {
            price_buy = pow_decimals_get.mul(pow_decimals_sell).div(sellPrice);
        }

/*

        Ahora calculamos cuanto quiere gastar el usuario en total

        2 x 33500 = 67000 USDT

        Esto es:

        cuanto_quiere_gastar = amount2sell x sellPrice / 10**token2sell.decimals()

        cuanto_quiere_gastar = 200000000 x 33500000000 / 10**8 = 67000000000 ===> 67000 USDT

*/


        // ------------------------------   market buy, el amount2sell es el monto maximo a obtener de usdt
        //                                  entonces basicamente el how_much_to_spend es el amount2sell
        uint256 how_much_to_spend;

        if (theOrderType==2) {
            how_much_to_spend = amount2sell;
        } else {
            // --------------------- market sell: how much to spend is 0
            how_much_to_spend = amount2sell.mul(sellPrice).div(pow_decimals_sell);
        }

/*
        Ahora, se buscan todas las ordenes que quieren vender USDT a cambio de WBTC 
        para ello se hace un ciclo hasta que ya no existan ordenes a precio de venta menor o igual al precio deseado
        o hasta que se finalice la orden
*/

        address address_token2sell = address(token2sell);
        address address_token2get = address(token2get);

        address user;
        
        uint trade_amount1;
        uint trade_amount2;
        
        //uint price_sell;

        // emit policia("de entrada quiere vender BTC", amount2sell);
        // emit policia("gastando maximo $", how_much_to_spend);

        emit policia("going to loop", 0);

        // protege lo que el usuario quiere gastar, no gasta mas de eso
        // ----------------------- si es un market sell protege lo que quiere vender, amount2sell
        for (uint i = 0; 
             i < open_limit_sell_orders[address_token2get][address_token2sell].length && 
             (
                how_much_to_spend>0 ||
                (theOrderType==0 && amount2sell>0)
             ); 
             i++
        ) {

            emit policia("in the loop", 0);

            // emit policia("ronda", i);
            // emit policia("tiene para gastar", how_much_to_spend);
            // emit policia("esta comprando $ maximo a", price_buy);
            // emit policia("y este tipo los vende en", open_limit_sell_orders[address_token2get][address_token2sell][i].price);

            if (
                open_limit_sell_orders[address_token2get][address_token2sell][i].price <= price_buy ||
                (
                    theOrderType==0 ||  // -------------------------- market sell, si es market sell "compra" los dolares a cualquier precio
                    theOrderType==2     // -------------------------- market buy, si es market buy compra los $ a cualquier precio tambien
                )
            ) {

                emit policia("Si, Match!", 1);

                // price_sell = open_limit_sell_orders[address_token2get][address_token2sell][i].price;
                
                // emit policia("price_sell", price_sell);

//                El usuario D le compra al vendedor en curso lo mas que pueda a 2976
                
//                "lo mas que pueda" es:
    
//                    si lo que quiere gastar D es menor o igual que lo que vende A', entonces le compra todo lo que quiere gastar D
//                    si lo que quiere gastar D es mayor que lo que vende A', entonces le compra todo lo que vende A'
                    
//                en este caso 3360000000 USDT es todo lo que vende A' que es menor que los 67000000000 que quiere gastar, por lo tanto:
    
//                cantidad_de_la_operacion = 3360000000

//                ------------------- en el caso de market sell
//                                    tengo que verificar si el monto que el usuario A quiere comprar de BTC 
//                                    es menor que el monto que el usuario D quiere vender en wbtc (amount2sell), 
//                                    si es menor vende todo lo que D quiere vender (trade_amount1 = )
//                                    si es mayor vende a A todo lo que quiera comprar A (trade_amount1 = )


                // ---------------- market sell, esto lo vamos a resolver asi:
                //                  vamos a calcular el how_much_to_spend ($) en base al precio de venta de usdt de A
                //                  el asunto es que aqui el price esta en wbtc, para el calculo del how_much_to_spend necesitamos dolares
                //                  price: 2976
                //                  simplicando queda:
                //                  how_much_to_spend = amount2sell.div(open_limit_sell_orders[address_token2get][address_token2sell][i].price)
                //                  how_much_to_spend = 200000000.div(2976)
                //                  how_much_to_spend = 200000000.mul(2976).div(100000000) = 67204

                if (theOrderType==0) {
                    how_much_to_spend = amount2sell*pow_decimals_get;
                    how_much_to_spend = how_much_to_spend.div(open_limit_sell_orders[address_token2get][address_token2sell][i].price);
                }

                if (how_much_to_spend <= open_limit_sell_orders[address_token2get][address_token2sell][i].amount) {
                    trade_amount1 = how_much_to_spend;
                    // emit policia("D gasta todo lo que tiene", 0);
                } else {
                    trade_amount1 = open_limit_sell_orders[address_token2get][address_token2sell][i].amount;
                    // emit policia("D gasta lo mas que le vende A", 0);
                }

                emit policia("how_much_to_spend", how_much_to_spend);
                emit policia("trade_amount1 cuantos BTC compra", trade_amount1);

                if (trade_amount1 == 0) continue;

                //    se calcula cuanto tiene que pagarle D a A' en WBTC:

                //    cantidad_de_la_operacion * price_sell / 10**token2get.decimals()
                    
                //    esto es:

                //    3360000000 * 2976 / 10**6 = 9999360 ===> 0.09999360 WBTC


                trade_amount2 = (trade_amount1.mul(
                    open_limit_sell_orders[address_token2get][address_token2sell][i].price // price_sell
                )).div(pow_decimals_get);

                emit policia("trade_amount2 cuantos $ paga", trade_amount2);

                // si los usuarios pueden completar sus ordenes

                user = open_limit_sell_orders[address_token2get][address_token2sell][i].user;

                if (users_balances[address_token2get][user] >= trade_amount1 && users_balances[address_token2sell][msg.sender] >= trade_amount2) {

                    emit policia("Si!, pueden completar sus ordenes", 1);

                    // se le pagan los 3360 USDT al usuario D

                    // users_balances[address_token2get][msg.sender] += trade_amount1; // se le suman a D los USDT
                    // se le debe cobrar la comision a A en USDT

                    // se le suman a D los USDT, menos la comision
                    users_balances[address_token2get][msg.sender] = users_balances[address_token2get][msg.sender].add(minusCommission(trade_amount1));
                    // se le suman al admin la comision en USDT
                    users_balances[address_token2get][master] = users_balances[address_token2get][master].add(theCommission(trade_amount1));

                    // emit policia("D recibe $", trade_amount1);

                    // se le restan a A los USDT completos
                    users_balances[address_token2get][user] = users_balances[address_token2get][user].sub(trade_amount1); 
    
                    // se le debe pagar el reward a A, el reward se calcula en base a lo que gastó
                    reward(user, ERC20(address_token2get), trade_amount1);

                    // llamar a otro contrato?
                    // https://medium.com/talo-protocol/how-to-secure-sensitive-data-on-an-ethereum-smart-contract-77f21c2b49f5
                    // use a hash function and consider the msg.sender of this contract
                    // this will require to deploy both contracts
                    //  and then the admin can store the value of one contract in the other
                    //      https://ethereum.stackexchange.com/questions/93727/how-does-commit-reveal-solve-front-running/93740#93740
        
                    // se le pagan los 0.29998080 WBTC a A                    
                    // se le suman a A los WBTC, menos la comision
                    users_balances[address_token2sell][user] = users_balances[address_token2sell][user].add(minusCommission(trade_amount2));

                    // se le suman al master la comision en WBTC
                    users_balances[address_token2sell][master] = users_balances[address_token2sell][master].add(theCommission(trade_amount2));

                    // se le restan a D los WBTC completos
                    users_balances[address_token2sell][msg.sender] = users_balances[address_token2sell][msg.sender].sub(trade_amount2);

                    // se le debe pagar el reward a D, el reward se calcula en base a lo que gastó
                    reward(msg.sender, ERC20(address_token2sell), trade_amount2);

                    // emit policia("D paga los BTC", trade_amount2);


                    // se le debe cobrar la comision a D en WBTC

                    // TODO: se le debe pagar el reward a D

                    // llamar a otro contrato?
                    // https://medium.com/talo-protocol/how-to-secure-sensitive-data-on-an-ethereum-smart-contract-77f21c2b49f5
                    // use a hash function and consider the msg.sender of this contract
                    // this will require to deploy both contracts
                    //  and then the admin can store the value of one contract in the other
                    //      https://ethereum.stackexchange.com/questions/93727/how-does-commit-reveal-solve-front-running/93740#93740

                    // Ahora se archivan las ordenes de D en user_orders_archive                 
                    // user_orders_archive[D][wbtc][usdt][05/03/21, 9999360, 33600000000, 1, 06/03/21]

                    orders_archive[msg.sender][address_token2sell][address_token2get].push(
                        CloseSellOrder(
                            block.timestamp, 
                            trade_amount2, 
                            pow_decimals_get*pow_decimals_sell/open_limit_sell_orders[address_token2get][address_token2sell][i].price, // price_sell, 
                            1, 
                            block.timestamp)
                    );

                    // emit policia("trade_amount2 cerrando", trade_amount2);

//                    emit Sell(msg.sender, address_token2sell, user, address_token2get, trade_amount2);

//                    y a orders_archive se le suma al par de tokens, a la fecha y al precio el monto
//                    TODO: another contract?
//                    orders_archive[wbtc][usdt][ += 9999360, 33600000000, 06/03/21]

                    // se registra la orden de A cerrada en user_orders_archive 
        
//                    user_orders_archive[A][usdt][wbtc][05/03/21, 3360000000, 2976, 3, 06/03/21]

                    orders_archive[user][address_token2get][address_token2sell].push(
                        CloseSellOrder(
                            block.timestamp, 
                            trade_amount1, 
                            open_limit_sell_orders[address_token2get][address_token2sell][i].price, // price_sell,  // this transforms 2976 satoshis per dollar into 33600 USD per BTC with decimals in USDT decimals  
                            open_limit_sell_orders[address_token2get][address_token2sell][i].order_type,
                            block.timestamp
                        )
                    );

                    // actualiza el precio y las stats

                    prices[address_token2sell][address_token2get] = pow_decimals_get*pow_decimals_sell/open_limit_sell_orders[address_token2get][address_token2sell][i].price;

                    updateStats24hr(
                        address_token2sell, 
                        address_token2get, 
                        pow_decimals_get*pow_decimals_sell/open_limit_sell_orders[address_token2get][address_token2sell][i].price, 
                        trade_amount2
                    );

                    // emit policia("trade_amount1 cerrando", trade_amount1);

//                    emit Sell(user, address_token2get, msg.sender, address_token2sell, trade_amount1);

                    // si la orden de A queda en cero se borra del arbol de ordenes activas (este es el caso del ejemplo A')
                    if (trade_amount1 == open_limit_sell_orders[address_token2get][address_token2sell][i].amount) {

                        // aqui se debe eliminar la posicion i del arreglo: open_limit_sell_orders_detail[price_sell]
                        removeOpenLimitSellOrdersDetail(address_token2get, address_token2sell, i);

                        // ok, como se eliminó la posicion i del arreglo, hay que procesarla de nuevo
                        // la manera mas economica es resetear el indice aqui
                        i--;

                        // en este caso no se incrementa el indice i, porque se eliminó la posicion i del arreglo
                        // asi que se procesa de nuevo el mismo i

                    // si la orden de A no queda en cero se actualiza con el monto restante
                    } else {
                        if (how_much_to_spend < open_limit_sell_orders[address_token2get][address_token2sell][i].amount) {

                            //open_limit_sell_orders[address_token2get][address_token2sell][i].amount -= how_much_to_spend;
                            open_limit_sell_orders[address_token2get][address_token2sell][i].amount = open_limit_sell_orders[address_token2get][address_token2sell][i].amount.sub(how_much_to_spend);

                        }
                    }

                    // Ahora se actualiza el monto a gastar:
                    // cuanto_quiere_gastar -= 3360000000  =============> 67000 - 3360 = 63640 USDT

                    emit policia("theOrderType", theOrderType);
                    emit policia("how_much_to_spend", how_much_to_spend);
                    emit policia("trade_amount1", trade_amount1);
                    emit policia("amount2sell", amount2sell);
                    emit policia("trade_amount2", trade_amount2);

                    // how_much_to_spend -= trade_amount1;
                    how_much_to_spend = how_much_to_spend.sub(trade_amount1);

                    // amount2sell -= 9999360 // queda para vender 200000000 - 9999360 = 190000640 ~ 1.9 WBTC

                    // amount2sell in marketBuy is really how much to spend, so we don't care to substract here
                    if (theOrderType!=2) {
                        amount2sell = amount2sell.sub(trade_amount2);
                    }

                    // Ahora se itera y se toma el segundo A: A'' y se repite el paso anterior

                }

            }

        }

        // if it is a market order do not leave an opened order
        if ((theOrderType==1 || theOrderType==3) && amount2sell>0) {
            // se agrega la orden de venta al detalle

            pushInOrder(address_token2sell, address_token2get, amount2sell, sellPrice, theOrderType);

/*
            open_limit_sell_orders[address_token2sell][address_token2get].push(
                OpenSellOrder(block.timestamp, msg.sender, amount2sell, sellPrice, theOrderType)
            );
*/

        }

    }

    function pushInOrder(address add1, address add2, uint256 amount2sell, uint256 sellPrice, uint8 theOrderType) private {
        if (open_limit_sell_orders[add1][add2].length==0) {
            open_limit_sell_orders[add1][add2].push(
                OpenSellOrder(block.timestamp, msg.sender, amount2sell, sellPrice, theOrderType)
            );
        } else {
            open_limit_sell_orders_aux[add1][add2].length=0;
            for (uint256 index = 0; index < open_limit_sell_orders[add1][add2].length; index++) {
                if (theOrderType<10 && open_limit_sell_orders[add1][add2][index].price>=sellPrice) {
                    open_limit_sell_orders_aux[add1][add2].push(
                        OpenSellOrder(block.timestamp, msg.sender, amount2sell, sellPrice, theOrderType)
                    );
                    theOrderType=10;
                }
                open_limit_sell_orders_aux[add1][add2].push(
                    open_limit_sell_orders[add1][add2][index]
                );
            }
            // if not found add it at the end
            if (theOrderType<10) {
                open_limit_sell_orders_aux[add1][add2].push(
                    OpenSellOrder(block.timestamp, msg.sender, amount2sell, sellPrice, theOrderType)
                );
            }
            open_limit_sell_orders[add1][add2] = open_limit_sell_orders_aux[add1][add2];
        }
    }

    /**
     *
     * Limit Buy: A wants to buy 2 WBTC at 30.000 USDT 
     * equals to: Limit Sell: A wants to sell 60.000 USD at 0.00003333 WBTC
     * 
     * with decimals:
     * 
     * limitBuy(wbtc, 200000000, usdt, 30000000000)
     * equals to limitSell(usdt, 200000000*30000000000/10**8, wbtc, 10**6*10**8/30000000000)
     *           limitSell(usdt, 60000000000, wbtc, 3333)
     *
     */
    function limitBuy(ERC20 token2buy, uint256 amount2buy, ERC20 token2pay, uint256 buyPrice) public {
        limitSell(
            token2pay, 
            amount2buy*buyPrice/10**token2buy.decimals(), 
            token2buy, 
            10**token2buy.decimals()*10**token2pay.decimals()/buyPrice,
            3
        );
    }

    function marketSell(ERC20 token2sell, uint256 amount2sell, ERC20 token2get) public {
        limitSell(token2sell, amount2sell, token2get, 0, 0);
    }

    function marketBuy(ERC20 token2buy, uint256 amount2buy, ERC20 token2pay) public {
        emit policia("marketBuy", 1);
        limitSell(token2pay, amount2buy, token2buy, 0, 2);
        emit policia("marketBuy", 2);
    }

    function removeOpenLimitSellOrdersDetail(address add1, address add2, uint index) private {
        if (index >= open_limit_sell_orders[add1][add2].length) return;
        open_limit_sell_orders[add1][add2][index] = open_limit_sell_orders[add1][add2][
            open_limit_sell_orders[add1][add2].length-1
        ];
        open_limit_sell_orders[add1][add2].length--;
    }

    // TODO: if buy orders the stats has to return 1/price and amount in add2 coin

    function openOrders(address add1, address add2) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint8[] memory) {
        
        uint number_of_found_indexes = 0;

        uint256[] memory indexes = new uint256[](open_limit_sell_orders[add1][add2].length);

        // search indexes with matching users
        for (uint i = 0; i<open_limit_sell_orders[add1][add2].length; i++) {
            if (msg.sender==open_limit_sell_orders[add1][add2][i].user) {
                indexes[number_of_found_indexes] = i;
                number_of_found_indexes++;
            }
        }

        // create an array with just the needed size (indexes found)
        uint256[] memory openings    = new uint256[](number_of_found_indexes);
        uint256[] memory amounts     = new uint256[](number_of_found_indexes);
        uint256[] memory price_sells = new uint256[](number_of_found_indexes);
        uint8[]   memory order_types = new uint8[]  (number_of_found_indexes);

        // add values to arrays
        for (uint i = 0; i<number_of_found_indexes; i++) {
            openings[i]    = open_limit_sell_orders[add1][add2][indexes[i]].opening;
            amounts[i]     = open_limit_sell_orders[add1][add2][indexes[i]].amount;
            price_sells[i] = open_limit_sell_orders[add1][add2][indexes[i]].price;
            order_types[i] = open_limit_sell_orders[add1][add2][indexes[i]].order_type;
        }

        return (openings, amounts, price_sells, order_types);

    }

    function closedOrders(address add1, address add2) public view returns 
        (uint256[] memory, uint256[] memory, uint256[] memory, uint8[] memory, uint256[] memory) {
        
        uint256[] memory openings    = new uint256[](orders_archive[msg.sender][add1][add2].length);
        uint256[] memory amounts     = new uint256[](orders_archive[msg.sender][add1][add2].length);
        uint256[] memory price_sells = new uint256[](orders_archive[msg.sender][add1][add2].length);
        uint8[]   memory order_types = new uint8[]  (orders_archive[msg.sender][add1][add2].length);
        uint256[] memory closings    = new uint256[](orders_archive[msg.sender][add1][add2].length);

        for (uint i = 0; i<orders_archive[msg.sender][add1][add2].length; i++) {
            openings[i]    = orders_archive[msg.sender][add1][add2][i].opening;
            amounts[i]     = orders_archive[msg.sender][add1][add2][i].amount;
            price_sells[i] = orders_archive[msg.sender][add1][add2][i].price;
            order_types[i] = orders_archive[msg.sender][add1][add2][i].order_type;
            closings[i]    = orders_archive[msg.sender][add1][add2][i].closing;
        }

        return (openings, amounts, price_sells, order_types, closings);

    }


    function priceToken(address token_address, address[] memory token_array) public view returns (uint256[] memory) {

        /*
            Ejemplo:
            priceToken(wbtc, [usdt, dai, weth])

            Devuelve los precios de ese token en el momento, por ejemplo los precios de WBTC:

            [
                33000000000, <---- 33000.000000 USDT para comprar 1 WBTC
                330106408568574, <---- 33010.640856 DAI para comprar 1 WBTC
                23573380013301064085, <---- 23.57 WETH para comprar 1 WBTC
            ]
        */

        uint256[] memory amounts = new uint256[](token_array.length);

        for (uint i = 0; i<token_array.length; i++) {
            amounts[i] = prices[token_address][token_array[i]];
        }

        return amounts;

    }

}