pragma solidity 0.4.24;

contract TESTToken {
    using SafeMath for uint256;

    //TODO change all state variables to private when going LIVE
    /*** State Variables ***/

    //TODO Set this to the opening rate of token per ETH here based on https://www.coinbase.com/charts
    //ex: $500 (per ETH) / $0.07 (opening price) = 7143 (works for wei as long as token decimals=18 because ETH=10^18 wei)
    uint256 public constant OPENING_RATE = 7143;

    //TODO use this as a constant when LIVE so that the source code signature includes it and is unique
    //TODO Set this to the Neureal multisig wallet that will take the ETH from the sale
    address private constant NEUREAL_ETH_WALLET = 0x3B2c9752B55eab06A66A6117E5D428835b03169d;

    //TODO use this as a constant when LIVE so that the source code signature includes it and is unique
    //TODO Set this to the address of the wallet that has authority to send the whitelisted Ethereum addresses
    address private constant WHITELIST_PROVIDER = 0xf9311383b518Ed6868126353704dD8139f7A30bE;

    //TODO change these values to the real values when going LIVE
    uint256 public constant MAX_SALE = 700 * 10**18; //Maximum token that can be purchased in the sale (70000000)
    uint256 public constant MIN_PURCHASE = 7 * 10**18; //Minumum token that can be purchased (150000)
    uint256 public constant MAX_ALLOCATION = 50 * 10**18; //Maximum token that can be allocated by the owner (5000000)
    uint256 public constant MAX_SUPPLY = MAX_SALE + MAX_ALLOCATION; //Maximum token that can be created
    //Maximum value of ETH (in Wei) in the contract that can be withdrawn immediately after its sold. The rest can only be withdrawn after the sale has ended.
    uint256 public constant MAX_WEI_WITHDRAWAL = (70 * 10**18) / OPENING_RATE; //(7000000)

    address public owner_;                  //Contract creator

    mapping(address => bool) public whitelist_;

    uint256 private totalSale_ = 0;         //Current total token sold
    function totalSale() external view returns (uint256) {
        return totalSale_;
    }
    uint256 private totalWei_ = 0;          //Current total Wei recieved from sale
    function totalWei() external view returns (uint256) {
        return totalWei_;
    }
    uint256 public weiWithdrawn_ = 0;       //Current total Wei withdrawn to NEUREAL_ETH_WALLET

    uint256 public totalRefunds_ = 0;       //Current Wei locked up in refunds
    mapping(address => uint256) public pendingRefunds_;

    uint256 public totalAllocated_ = 0;    //Current total token allocated

    enum Phase {
        BeforeSale,
        Sale,
        Finalized
    }
    Phase public phase_ = Phase.BeforeSale;


    /*** Events ***/
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event TokenPurchase(uint256 _totalTokenSold, uint256 _totalWei);
    event Refunded(address indexed _who, uint256 _weiValue);
    event SaleStarted();
    event Finalized();


    /*** ERC20 token standard ***/

    string public constant name = "Neureal TGE Test";
    string public constant symbol = "TEST";
    uint8 public constant decimals = 18;

    uint256 private totalSupply_ = 0;
    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }
    
    mapping(address => uint256) private balances_;
    function balanceOf(address _who) external view returns (uint256) {
        return balances_[_who];
    }
    
    function transfer(address _to, uint256 _value) external returns (bool) {
        // Non transferable, revert so people don&#39;t loose as much ether
        revert(); //uses some gas, around 23000, only like 3 instructions
        // require(false); //uses some gas, around 23000, medium number of instructions
        // assert(false); //uses full gas limit
        // revert("NOT SUPPORTED"); //uses some gas, around 23000, lots of instructions
        return false; //not needed?
    }


    /*** Non ERC20 Functions ***/

    /* Initializes contract */
    //TODO take parameters out when LIVE
    constructor() public {
        owner_ = msg.sender;
    }


    /** Purchase **/

    /* KYC/AML/accredited auth whitelisting */
    function whitelist(address _who) external {
        require(phase_ != Phase.Finalized);                //Only works before and during sale
        require(msg.sender == WHITELIST_PROVIDER);          //Only whitelist provider
        whitelist_[_who] = true;
        //DONT check blacklist (coinbase, exchange, etc) here, check in auth website
    }
    //TODO do we really need this?
    function whitelistMany(address[] _who) external {
        require(phase_ != Phase.Finalized);                //Only works before and during sale
        require(msg.sender == WHITELIST_PROVIDER);          //Only whitelist provider
        for (uint256 i = 0; i < _who.length; i++) {
            whitelist_[_who[i]] = true;
        }
    }
    //TODO do we really need this?
    function whitelistRemove(address _who) external {
        require(phase_ != Phase.Finalized);                //Only works before and during sale
        require(msg.sender == WHITELIST_PROVIDER);          //Only whitelist provider
        whitelist_[_who] = false;
    }

    /* Token purchase (called whenever someone tries to send ether to this contract) */
    function() external payable {
        require(phase_ == Phase.Sale);                     //Only sell during sale
        require(msg.value != 0);                            //Stop spamming, contract only calls, etc
        require(msg.sender != address(0));                  //Prevent transfer to 0x0 address
        require(msg.sender != address(this));               //Prevent calls from this.transfer(this)
        require(whitelist_[msg.sender]);                    //Only whitelisted
        // assert(address(this).balance >= msg.value);         //this.balance gets updated with msg.value before this function starts 
        
        uint256 tokens = msg.value.mul(OPENING_RATE);

        require(tokens >= MIN_PURCHASE);                    //must be above minimum

        uint256 newTotalSale = totalSale_.add(tokens);
        require(newTotalSale <= MAX_SALE);                  //Check if there is enough available in sale
        uint256 newTotalSupply = totalSupply_.add(tokens);
        require(newTotalSupply <= MAX_SUPPLY);               //Check if there is enough available (should not happen)

        balances_[msg.sender] = balances_[msg.sender].add(tokens);
        totalSupply_ = newTotalSupply;
        totalSale_ = newTotalSale;

        totalWei_ = totalWei_.add(msg.value);
        // NEUREAL_ETH_WALLET.transfer(msg.value);             //This is not safe, use withdraw and refund methods

        emit Transfer(address(0), msg.sender, tokens);
        emit TokenPurchase(totalSale_, totalWei_);
    }
    
    /* Withdrawl current available ETH in contract */
    function withdraw() external {
        require(msg.sender == owner_);                      //Only owner
        uint256 withdrawalValue = address(this).balance.sub(totalRefunds_);
        if (phase_ != Phase.Finalized) {
            uint256 newWeiWithdrawn = weiWithdrawn_.add(withdrawalValue);
            if (newWeiWithdrawn > MAX_WEI_WITHDRAWAL) {
                withdrawalValue = MAX_WEI_WITHDRAWAL.sub(weiWithdrawn_); //Withdraw up to the full amount left
                require(withdrawalValue != 0);              //Bail if already depleted
                newWeiWithdrawn = MAX_WEI_WITHDRAWAL;
            }
            weiWithdrawn_ = newWeiWithdrawn;
        }
        
        NEUREAL_ETH_WALLET.transfer(withdrawalValue);       //This works with our multisig (using 2300 gas stipend)
        // require(NEUREAL_ETH_WALLET.call.value(withdrawalValue)()); //alternative to be able to send more gas
    }


    /** Refund **/

    /* lock ETH for refund, burn all owned token */
    function refund(address _who) external payable {
        require(phase_ == Phase.Sale);             //Only refund during sale, afterwords can refund using NEUREAL TGE
        require(msg.sender == owner_);              //Only owner
        require(_who != address(0));                //Prevent refund to 0x0 address
        require(balances_[_who] != 0);              //Prevent if never purchased
        require(pendingRefunds_[_who] == 0);        //Prevent if already refunded
        
        uint256 tokenValue = balances_[_who];
        uint256 weiValue = tokenValue.div(OPENING_RATE);
        assert(weiValue != 0);                       //We don&#39;t allow transfers, but if we did this might happen from rounding

        require(address(this).balance >= weiValue);  //Must have enough wei in contract after payable to lock up
        totalRefunds_ = totalRefunds_.add(weiValue);
        pendingRefunds_[_who] = weiValue;

        totalSupply_ = totalSupply_.sub(tokenValue);
        totalSale_ = totalSale_.sub(tokenValue);
        balances_[_who] = 0;

        emit Transfer(_who, address(0), tokenValue);
    }
    /* send allocated refund, anyone can call anytime */
    function sendRefund(address _who) external {
        require(pendingRefunds_[_who] != 0);         //Limit reentrancy and execution if not needed

        uint256 weiValue = pendingRefunds_[_who];
        pendingRefunds_[_who] = 0;
        totalRefunds_ = totalRefunds_.sub(weiValue);
        emit Refunded(_who, weiValue);
        
        _who.transfer(weiValue);
        // require(_who.call.value(weiValue)()); //TODO I think I need to use this alternative to send more gas than 2300 to be able to refund to contracts
    }
    
    
    /** Allocate **/
    
    /* Owner allocation, create new token (under conditions) without costing ETH */
    function allocate(address _to, uint256 _value) external {
        require(phase_ != Phase.Finalized);        //Only works before and during sale
        require(msg.sender == owner_);              //Only owner
        require(_value != 0);                       //Allocate is not a transfer call from a wallet app, so this is ok
        require(_to != address(0));                 //Prevent transfer to 0x0 address
        require(_to != address(this));              //Prevent transfer to this contract address

        uint256 newTotalAllocated = totalAllocated_.add(_value);
        require(newTotalAllocated <= MAX_ALLOCATION); //Check if there is enough available to allocate
        uint256 newTotalSupply = totalSupply_.add(_value);
        require(newTotalSupply <= MAX_SUPPLY);    //Check if there is enough available (should not happen)
        
        balances_[_to] = balances_[_to].add(_value);
        totalSupply_ = newTotalSupply;
        totalAllocated_ = newTotalAllocated;

        emit Transfer(address(0), _to, _value);
    }
    
    
    /** Contract State **/

    /* state transition */
    function transition() external {
        require(phase_ != Phase.Finalized);        //Only works before and during sale
        require(msg.sender == owner_);              //Only owner
        
        if (phase_ == Phase.BeforeSale) {
            phase_ = Phase.Sale;
            emit SaleStarted();
        } else if (phase_ == Phase.Sale) {
            phase_ = Phase.Finalized;
            emit Finalized();
        }
    }

}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) return 0;
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


/*
0x0000000000000000000000000000000000000000
TEST
18
JSON Interface:
[  ]
*/