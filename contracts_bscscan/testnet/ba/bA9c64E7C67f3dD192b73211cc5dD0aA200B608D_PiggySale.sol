pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

contract Owned {
    address public address_owner;
    constructor()  { 
        address_owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(
            msg.sender == address_owner,
            "Only owner can call this function."
        );
        _;
    }
    function transferOwnership(address _address_owner) public onlyOwner {
        address_owner = _address_owner;
    }
}

contract PiggySale is Owned, ReentrancyGuard {
    
    //address PIGI
    address public PIGI = 0x132087ee3e0D006d20Ed2E63669921ab13e4bD7b;
    //address BUSD
    address public BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    uint256 public min_amount;
    uint256 public price_current_BUSD;
    uint256 public price_current_BNB;
    uint256 public cap_sale_current;
    uint256 public time_start_current;
    uint256 public time_end_current;
    bool public is_sale_token = true;
    uint256 public price_next_BUSD;
    uint256 public price_next_BNB;
    uint256 public time_start_next;
    uint256 public time_end_next;
    uint256 public cap_sale_next;
    uint256 public total_buy_current;
    
    //Referral
    uint256 private buy_referral_bonus;

    event BuyPiggyEvent(uint256 price, uint256 amount);
    event NextPiggySale(uint256 priceBNB, uint256 priceBUSD, uint256 time_start, uint256 time_end, uint256 cap_sale);
    

    mapping (address => uint256) private referrals;
    mapping (uint256 => address) private referral_codes;
    mapping (address => address) private referral_parents;

    constructor(uint256 _min_amount, uint256 _price_BNB, uint256 _price_BUSD, uint256 time_start, uint256 time_end, uint256 cap_sale) {
        //Referral
        buy_referral_bonus = 15; //15%
        min_amount = _min_amount;
        price_current_BNB = _price_BNB;
        price_current_BUSD = _price_BUSD;
        time_start_current = time_start;
        time_end_current = time_end;
        cap_sale_current = cap_sale;
    }
    //set next sale info
    function addPrice(uint256 _price_BNB, uint256 _price_BUSD, uint256 time_start, uint256 time_end, uint256 _cap) public onlyOwner {
        require(time_end > time_start && time_start > time_end_current, "Invalid time");
        price_next_BNB = _price_BNB;
        price_next_BUSD = _price_BUSD;
        time_start_next = time_start;
        time_end_next = time_end;
        cap_sale_next = _cap;
        checkPrice();
        emit NextPiggySale(_price_BNB, _price_BUSD, time_start, time_end, _cap);
    }
    
    //Referral
    function setBonus(uint256 buy_bonus) public returns(uint256) {
        buy_referral_bonus = buy_bonus;
        return (buy_referral_bonus);
    }
    //close sale   
    function closeSale() public onlyOwner {
        is_sale_token = false;
    }
    
    function priceCurrent() public view returns(uint256 priceBNB, uint256 priceBUSD) {
        return (price_current_BNB, price_current_BUSD);
    }
    
    function isSale() public view returns(bool) {
        return ( block.timestamp >= time_start_current && block.timestamp <= time_end_current && is_sale_token != false);
    }
    
    function getSaleInfo() public view returns(bool is_sale, uint256 minamount, uint256 priceBNB, uint256 priceBUSD, uint256 buy_bonus, uint256 total_buy){
        bool is_sale_status = (block.timestamp <= time_end_current && is_sale_token != false);
        return (is_sale_status, min_amount, price_current_BNB, price_current_BUSD, buy_referral_bonus, total_buy_current);
    }
        
    function sendToken(address _token_address) payable public returns(bool) {
        IERC20 token = IERC20(_token_address);
        uint256 balance = token.balanceOf(address(this));
        return token.transfer(address_owner, balance);
    }
    
    function checkPrice() public {
        uint256 time_current = block.timestamp;
        if (price_next_BNB > 0 && price_next_BUSD > 0 && time_current >= time_start_next && time_current <= time_end_next)
        {
            price_current_BNB = price_next_BNB;
            price_current_BUSD = price_next_BUSD;
            time_start_current = time_start_next;
            time_end_current = time_end_next;
            price_next_BNB = 0;
            price_next_BUSD = 0;
        }
    }

    function checkCap() public {
        uint256 time_current = block.timestamp;
        if(time_current > time_end_current) {
            total_buy_current = 0;
        }
    }
    
    function buyPiggyBUSD(uint amount, address refferal) public nonReentrant returns(bool) {
        uint256 token_balance = IERC20(PIGI).balanceOf(address(address_owner));
        uint256 time_current = block.timestamp;
        require(amount >= min_amount, "You amount to small");
        checkPrice();
        checkCap();
        require(price_current_BUSD > 0, "Please set price of token");
        require(time_current >= time_start_current && time_current <= time_end_current && is_sale_token != false, "Token sale is finished or not opened");
        uint256 total_value = amount * price_current_BUSD;
        uint256 decimals = IERC20(PIGI).decimals();
        require(decimals >= 0, "Decimals is invalid");
        uint256 amount_buy = amount * (10 ** decimals);
        //check owner balance
        require(token_balance >= amount_buy, "Not enough tokens in the reserve");
        //check amount
        require(amount_buy > 0, "You amount token to small"); 
        require(total_buy_current + amount_buy <= cap_sale_current);
        IERC20(BUSD).transferFrom(msg.sender, address_owner, total_value);
        //send PIGGY Token for buyer 
        IERC20(PIGI).transferFrom(address_owner, msg.sender, amount_buy);
        //send for referral
        if (refferal != address(0))
        {
            IERC20(BUSD).transferFrom(address_owner, refferal, buy_referral_bonus * total_value / 100); 
        }
        payable(address_owner).transfer(address(this).balance);

        total_buy_current = total_buy_current + amount_buy;
        emit BuyPiggyEvent(token_balance, amount_buy);
        return true;
    }

    receive () external payable {}
}

