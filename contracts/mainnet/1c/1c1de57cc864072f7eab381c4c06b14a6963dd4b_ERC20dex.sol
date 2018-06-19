contract ERC20 {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract ERC20dex {
    int constant SELL = 0;
    int constant BUY  = 1;
    
    byte constant COIN_DEAD         = 0;
    byte constant COIN_NON_APPROVED = 1;
    byte constant COIN_APPROVED     = 2;
    
    address owner = 0;
    address trader = 0;
    uint256 maker_fee = 0;
    uint256 taker_fee = 0;
    uint256 deploy_fee = 0;
    int stopped = 0;
    uint256 main_fee = 0;
    
    struct order_t {
        int buy_sell;
        address owner;
        uint256 amount;
        uint256 price;
        uint256 block;
    }
    
    struct coin_t {
        string ticker;
        string name;
        address base;
        uint8 digits;
        address requestor;
        uint256 minimum_trade;
        byte state;
        uint256 fee;
        uint256 price;
    }
    
    // List of registered coins
    coin_t[] shitcoins;
    
    // Minimum value of a trade
    uint256 minimum_trade;
    
    // Indexing for shitcoins array
    mapping(string => uint16) shitcoin_index;

    // Order book
    mapping(string => order_t[]) order_book;
    
    // Balances
    mapping(address => uint256) etx_balances;

    function ERC20dex() {
        owner = msg.sender;
        trader = msg.sender;
    }
    
    function set_owner(address new_owner) {
        require(msg.sender == owner);
        owner = new_owner;
    }
    function set_trader(address new_trader) {
        require(msg.sender == owner);
        trader = new_trader;
    }
    
    function require(bool condition) constant private {
        if (condition == false) {
            throw;
        }
    }

    function assert(bool condition) constant private {
        if (condition == false) {
            throw;
        }
    }
    
    function safe_mul(uint256 a, uint256 b) constant returns (uint256 c) {
        c = a * b;
        assert(a == 0 || c / a == b);
        
        return c;
    }
    
    function safe_add(uint256 a, uint256 b) constant returns (uint256 c) {
        require(a + b >= a);
        return a + b;
    }
    
    function safe_sub(uint256 a, uint256 b) constant returns (uint256 c) {
        require(a >= b);
        return a - b;
    }
    
    function stop() public {
        require(msg.sender == owner);
        stopped = 1;
    }

    function add_coin(string coin, string name, address base, uint8 digits) public {
        require(msg.sender == owner);
        require(shitcoin_index[coin] == 0);
        
        // Register a new coin
        shitcoins.push(coin_t(coin, name, base, digits, msg.sender, 0, COIN_APPROVED, 0, 0));
        shitcoin_index[coin] = uint16(shitcoins.length);
    }
    
    function createToken(string symbol, string name, address coin_address, uint8 decimals) public {
        // Check if sender included enough ETC for creation
        require(msg.value == deploy_fee);

        // Pass fee to the owner
        require(owner.send(msg.value));

        // Register a new coin, but do not approve it
        shitcoins.push(coin_t(symbol, name, coin_address, decimals, msg.sender, 0, COIN_NON_APPROVED, 0, 0));
        shitcoin_index[symbol] = uint16(shitcoins.length);
    }
    
    function approve_coin(string coin, bool approved) public {
        require(msg.sender == owner);
        if (approved) {
            shitcoins[shitcoin_index[coin] - 1].state = COIN_APPROVED;
        } else {
            shitcoins[shitcoin_index[coin] - 1].state = COIN_NON_APPROVED;
        }
    }
    
    function remove_coin(uint index) public {
        require(msg.sender == owner);
        require(index < shitcoins.length);
        
        string ticker = shitcoins[index].ticker;
        delete shitcoins[index];
        delete shitcoin_index[ticker];
        
        for (uint16 i = 0; i < uint16(shitcoins.length); i++) {
            shitcoin_index[shitcoins[i].ticker] = i + 1;
        }
    }
    
    function set_fee(uint256 the_maker_fee, uint256 the_taker_fee, uint256 the_deploy_fee) public {
        require(msg.sender == owner);
        
        maker_fee = the_maker_fee;
        taker_fee = the_taker_fee;
        deploy_fee = the_deploy_fee;
    }
    
    function set_minimum_trade(uint256 the_minimum_trade) public {
        require(msg.sender == owner);
        minimum_trade = the_minimum_trade;
    }
    
    function get_minimum_trade() constant returns (uint256) {
        return minimum_trade;
    }
    
    function set_coin_minimum_trade(string token, uint256 the_minimum_trade) public {
        require(msg.sender == owner);
        shitcoins[shitcoin_index[token] - 1].minimum_trade = the_minimum_trade;
    }

    function get_maker_fee() constant returns (uint256) {
        return maker_fee;
    }
    
    function get_taker_fee() constant returns (uint256) {
        return taker_fee;
    }
    
    function get_deploy_fee() constant returns (uint256) {
        return deploy_fee;
    }
    
    function get_coins_count() constant returns (uint256 length) {
        length = shitcoins.length;
    }
    
    function get_coin(uint index) constant returns (string, string, address, byte, uint8, address, uint256) {
        coin_t coin = shitcoins[index];
        return (coin.ticker, coin.name, coin.base, coin.state, coin.digits, coin.requestor, coin.minimum_trade);
    }
    
    function get_balance(address a, string token) constant returns (uint256 balance) {
        coin_t coin = shitcoins[shitcoin_index[token] - 1];
        
        if (coin.state != COIN_DEAD) {
            // Get ERC20 contract and check how many coins we can use for selling
            ERC20 shitcoin = ERC20(shitcoins[shitcoin_index[token] - 1].base);
            balance = shitcoin.allowance(a, this);
        }
    }
    
    function get_etc_balance(address a) constant returns (uint256 balance) {
        return etx_balances[a];
    }
    
    function get_order_book_length(string token) constant returns (uint256 length) {
        return order_book[token].length;
    }
    
    function get_order(string token, uint256 index) constant returns (int, address, uint256, uint256, uint256) {
        order_t order = order_book[token][index];
        return (order.buy_sell, order.owner, order.amount, order.price, order.block);
    }
    
    function get_price(string token) constant returns (uint256) {
        return shitcoins[shitcoin_index[token] - 1].price;
    }
    
    function total_amount(string token, uint256 amount, uint256 price) constant returns (uint256) {
        return safe_mul(amount, price) / 10**uint256(shitcoins[shitcoin_index[token] - 1].digits);
    }
    
    function sell(string token, uint256 amount, uint256 price) public {
        // Basic checks
        require(stopped == 0);
        require(total_amount(token, amount, price) >= minimum_trade);
        
        // Get coin
        coin_t coin = shitcoins[shitcoin_index[token] - 1];
        
        // Validate coin
        require(coin.state == COIN_APPROVED);
        require(amount >= coin.minimum_trade);
        
        // Check if we are allowed to secure coins for a deal
        ERC20 shitcoin = ERC20(coin.base);
        require(shitcoin.allowance(msg.sender, this) >= amount);
        
        // Secure tokens for a deal
        require(shitcoin.transferFrom(msg.sender, this, amount));

        // Register an order for further processing by matcher
        order_book[token].push(order_t(SELL, msg.sender, amount, price, block.number));
    }
    
    function buy(string token, uint256 amount, uint256 price) public {
        // Basic checks
        require(stopped == 0);
        require(total_amount(token, amount, price) == msg.value);
        require(msg.value >= minimum_trade);
        
        // Get coin
        coin_t coin = shitcoins[shitcoin_index[token] - 1];
        
        // Validate coin
        require(coin.state == COIN_APPROVED);
        require(amount >= coin.minimum_trade);

        // Credit ETX to the holder account
        etx_balances[msg.sender] += msg.value;

        // Register an order for further processing by matcher
        order_book[token].push(order_t(BUY, msg.sender, amount, price, block.number));
    }
    
    function trade(string token, uint maker, uint taker) public {
        // Basic checks
        require(msg.sender == trader);
        require(maker < order_book[token].length);
        require(taker < order_book[token].length);
        
        // Get coin
        coin_t coin = shitcoins[shitcoin_index[token] - 1];
        
        // Validate coin
        require(coin.state == COIN_APPROVED);

        order_t make = order_book[token][maker];
        order_t take = order_book[token][taker];
        uint256 makerFee = 0;
        uint256 takerFee = 0;
        uint256 send_to_maker = 0;
        uint256 send_to_taker = 0;
        ERC20 shitcoin = ERC20(coin.base);
        
        // Check how many coins go into the deal
        uint256 deal_amount = 0;
        if (take.amount < make.amount) {
            deal_amount = take.amount;
        } else {
            deal_amount = make.amount;
        }
        uint256 total_deal = total_amount(token, deal_amount, make.price);
        
        // If maker buys something
        if (make.buy_sell == BUY) {
            // Sanity check
            require(take.price <= make.price);
            
            // Calculate fees
            makerFee = safe_mul(deal_amount, maker_fee) / 10000;
            takerFee = safe_mul(total_deal, taker_fee) / 10000;
            
            // Update accessible fees
            coin.fee = coin.fee + makerFee;
            main_fee = main_fee + takerFee;
            
            send_to_maker = safe_sub(deal_amount, makerFee);
            send_to_taker = safe_sub(total_deal, takerFee);
                
            // Move shitcoin to maker
            require(shitcoin.transfer(make.owner, send_to_maker));
                
            // Deduct from avaialble ETC balance
            etx_balances[make.owner] = safe_sub(etx_balances[make.owner], total_deal);
                
            // Move funds to taker
            require(take.owner.send(send_to_taker));
                
        } else {
            // Sanity check
            require(take.price >= make.price);
            
            // Calculate fees
            makerFee = safe_mul(total_deal, maker_fee) / 10000;
            takerFee = safe_mul(deal_amount, taker_fee) / 10000;
            
            // Update accessible fees
            main_fee = main_fee + makerFee;
            coin.fee = coin.fee + takerFee;
            
            send_to_maker = safe_sub(total_deal, makerFee);
            send_to_taker = safe_sub(deal_amount, takerFee);
                
            // Move shitcoin to taker
            require(shitcoin.transfer(take.owner, send_to_taker));
                
            // Deduct from avaialble ETC balance
            etx_balances[take.owner] = safe_sub(etx_balances[take.owner], total_deal);
                
            // Move funds to maker
            require(make.owner.send(send_to_maker));
        }
        
        // Reduce order size
        make.amount = safe_sub(make.amount, deal_amount);
        take.amount = safe_sub(take.amount, deal_amount);
        
        // Update price
        coin.price = make.price;
    }
    
    function cancel(string token, uint256 index) public {
        // Coin checks
        coin_t coin = shitcoins[shitcoin_index[token] - 1];
        order_t order = order_book[token][index];

        require(coin.state == COIN_APPROVED);
        require((msg.sender == order.owner) || (msg.sender == owner));
        require(order.amount > 0);
        
        // Null the order
        order.amount = 0;

        // Return coins
        if (order.buy_sell == BUY) {
            // Return back ETC
            uint256 total_deal = total_amount(token, order.amount, order.price);
            etx_balances[msg.sender] = safe_sub(etx_balances[msg.sender], total_deal);
            require(order.owner.send(total_deal));
        } else {
            // Return shitcoins back 
            ERC20 shitcoin = ERC20(coin.base);
            shitcoin.transfer(order.owner, order.amount);
        }
    }
    
    function collect_fee(string token) public {
        require(msg.sender == owner);

        // Send shitcoins
        coin_t coin = shitcoins[shitcoin_index[token] - 1];
        if (coin.fee > 0) {
            ERC20 shitcoin = ERC20(coin.base);
            shitcoin.transfer(owner, coin.fee);
        }
    }
    
    function collect_main_fee() public {
        require(msg.sender == owner);

        // Send main currency
        require(owner.send(main_fee));
    }

}