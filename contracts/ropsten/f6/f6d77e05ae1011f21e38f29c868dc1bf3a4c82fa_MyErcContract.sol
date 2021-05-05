/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.5.0;

contract ERC20Interface {
    //این تابع تعداد کل توکن های موجود در شبکه را مشخص می کند
    function totalSupply() public view returns (uint);
    
    //این تابع تعداد توکن های یک آدرس خاص (در اینجا تعداد توکن هایی که صاحب قرارداد هوشمند در حساب خود دارد) را نشان میدهد 
    function balanceOf(address tokenOwner) public view returns (uint balance);
    
    //این تابع حداقل توکن مورد نیاز برای انجام تراکنش مشخص می کند. اگر کاربر حداقل توکن لازم را نداشت، تراکنش اتومات کنسل می شود
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    
    //این تابع به صاحب قرارداد امکان ارسال توکن به آدرس های دیگر را میدهد
    function transfer(address to, uint tokens) public returns (bool success);
    
    //این تابع اعتبارسنجی تراکنش را براساس مقدار کل توکن ها و مانده حساب کاربران برای جلوگیری از جعل و کلاهبرداری انجام میدهد
    function approve(address spender, uint tokens) public returns (bool success);
    
    //این تابع به شما امکان اتومات کن پرداخت ها و واریز به یک حساب خاص را میدهد
    function transferFrom(address from, address to, uint tokens) public returns (bool success);


    //این رویدادها هنگامی که قرارداد هوشمند به کاربر حق برداشت توکن ها از یک حساب و بعد از آن انتقال توکن ها را میدهد صادر یا فراخوانی می شود
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b; require(a == 0 || c / a == b); }
    function safeDiv(uint a, uint b) public pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }
}

contract MyErcContract is ERC20Interface, SafeMath {
    //متغیرها
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    
    // متغیر balancesاز نوع ارایه است و هر خانه از آن شامل یک آدرس 256 بیتی است. 
// این  مسیردهی مانده  حساب مالک را نگه میدارد. یک ارایه ی انجمنی کلید مقدار است.ادرس ها مقادری از نوع عدد صحیح 256 بیتی 
    mapping(address => uint) balances;
    
    //متغیر allowed از نوع آرایه است و هر خانه از آن مقدارش آدرس است
//شامل تمام حساب های مصوب برای برداشت از یک حساب معین به همراه مبلغ برداشت به ازای هریک است
    mapping(address => mapping(address => uint)) allowed;
//...............................................................


    constructor() public {
        name = "izakxyz"; // token name ex: Bitcoin
        symbol = "IZX"; // token symbol ex: BTC
        decimals = 18; // token decimals (ETH=18,USDT=6,BTC=8)
        _totalSupply = 1000000000000000; // total supply including decimals

//msg یک متغیر عمومی است که توسط خود اتریوم اعلام و عمومی شده است که شامل داده های مهم جهت اجرای قرارداد است
//msg.sender شامل یک حساب اتریوم است که عملکرد قرارداد فعلی را انجام می دهد
//فقط حساب توسعه دهنده می تواند وارد تابع سازنده بشود با شروع قرارداد این تابع توکن های موجود را به حساب مالک قرارداد اختصاص می دهد
//مقدار حساب صاحب قرارداد میشه تمام توکن های موجود 
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

//کل توکن های ایجاد شده را برمیگرداند 
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
//مانده ی حساب مالک را برمیگرداند 
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    //توکن ها را به یک حساب دیگر انتقال دهید. این توکن ها از مانده ی حساب مالک به کاربر دیگر انتقال داده می شود
    //این مالک انتقال دهنده همون msg.sender است. یعنی فقط صاحبان توکن می توانند انها را به دیگران انتقال دهند. 
    //راه solid برای اثبات یک گزاره requireاست

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        //از مبلغ مجاز برداشت نماینده هم کم می کند. به نماینده ای با اجازه ی برداشت مشخص امکان میدهد تامبلغ را به چندین برداشت جداگانه تقسیم کند 
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}