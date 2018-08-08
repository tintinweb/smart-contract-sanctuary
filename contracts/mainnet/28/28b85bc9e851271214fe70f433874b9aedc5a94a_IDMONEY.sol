pragma solidity 0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    function totalSupply()public view returns(uint total_Supply);
    function balanceOf(address who)public view returns(uint256);
    function allowance(address owner, address spender)public view returns(uint);
    function transferFrom(address from, address to, uint value)public returns(bool ok);
    function approve(address spender, uint value)public returns(bool ok);
    function transfer(address to, uint value)public returns(bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract IDMONEY is ERC20
{
    using SafeMath for uint256;
        // Name of the token
        string public constant name = "IDMONEY";

    // Symbol of token
    string public constant symbol = "IDM";
    uint8 public constant decimals = 18;
    uint public _totalsupply = 35000000 * 10 ** 18; // 35 Million IDM Coins
    uint256 constant public _price_tokn = 0.00075 ether;
    uint256 no_of_tokens;
    uint256 bonus_token;
    uint256 total_token;
    uint256 tokensold;
    uint256 public total_token_sold;
    bool stopped = false;
 
    address public owner;
    address superAdmin = 0x1313d38e988526A43Ab79b69d4C94dD16f4c9936;
    address socialOne = 0x52d4bcF6F328492453fAfEfF9d6Eb73D26766Cff;
    address socialTwo = 0xbFe47a096486B564783f261B324e198ad84Fb8DE;
    address founderOne = 0x5AD7cdD7Cd67Fe7EB17768F04425cf35a91587c9;
    address founderTwo = 0xA90ab8B8Cfa553CC75F9d2C24aE7148E44Cd0ABa;
    address founderThree = 0xd2fdE07Ee7cB86AfBE59F4efb9fFC1528418CC0E;
    address storage1 = 0x5E948d1C6f7C76853E43DbF1F01dcea5263011C5;
    
    mapping(address => uint) balances;
    mapping(address => bool) public refund;              //checks the refund status
    mapping(address => bool) public whitelisted;         //checks the whitelist status of the address
    mapping(address => uint256) public deposited;        //checks the actual ether given by investor
    mapping(address => uint256) public tokensinvestor;   //checks number of tokens for investor
    mapping(address => mapping(address => uint)) allowed;

    uint constant public minimumInvestment = .1 ether; // .1 ether is minimum minimumInvestment
    uint bonus;
    uint c;
    uint256 lefttokens;

    enum Stages {
        NOTSTARTED,
        ICO,
        PAUSED,
        ENDED
    }
    Stages public stage;

     modifier atStage(Stages _stage) {
        require (stage == _stage);
            // Contract not in expected state
         _;
    }
    
     modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
     modifier onlySuperAdmin() {
        require (msg.sender == superAdmin);
        _;
    }

    function IDMONEY() public
    {
        owner = msg.sender;
        balances[superAdmin] = 2700000 * 10 ** 18;  // 2.7 million given to superAdmin
        balances[socialOne] = 3500000 * 10 ** 18;  // 3.5 million given to socialOne
        balances[socialTwo] = 3500000 * 10 ** 18;  // 3.5 million given to socialTwo
        balances[founderOne] = 2100000 * 10 ** 18; // 2.1 million given to FounderOne
        balances[founderTwo] = 2100000 * 10 ** 18; // 2.1 million given to FounderTwo
        balances[founderThree] = 2100000 * 10 ** 18; //2.1 million given to founderThree
        balances[storage1] = 9000000 * 10 ** 18; // 9 million given to storage1
        stage = Stages.NOTSTARTED;
       emit Transfer(0, superAdmin, balances[superAdmin]);
       emit Transfer(0, socialOne, balances[socialOne]);
       emit Transfer(0, socialTwo, balances[socialTwo]);
       emit Transfer(0, founderOne, balances[founderOne]);
       emit Transfer(0, founderTwo, balances[founderTwo]);
       emit Transfer(0, founderThree, balances[founderThree]);
       emit Transfer(0, storage1, balances[storage1]);
    }

    function () public payable atStage(Stages.ICO)
    {
        require(msg.value >= minimumInvestment);
        require(!stopped && msg.sender != owner);

        no_of_tokens = ((msg.value).div(_price_tokn)).mul(10 ** 18);
        tokensold = (tokensold).add(no_of_tokens);
        deposited[msg.sender] = deposited[msg.sender].add(msg.value);
        bonus = bonuscal();
        bonus_token = ((no_of_tokens).mul(bonus)).div(100);  // bonus
        total_token = no_of_tokens + bonus_token;
        total_token_sold = (total_token_sold).add(total_token);
        tokensinvestor[msg.sender] = tokensinvestor[msg.sender].add(total_token);


    }

    //calculation for the bonus for 1 million tokens
    function bonuscal() private returns(uint)
    {
       
        c = tokensold / 10 ** 23;
        if (c == 0) 
        {
           return  90;

        }
         return (90 - (c * 10));
    }

    function start_ICO() external onlyOwner atStage(Stages.NOTSTARTED)
    {
        stage = Stages.ICO;
        stopped = false;
        balances[address(this)] = 10000000 * 10 ** 18; // 10 million to smart contract initially
      emit Transfer(0, address(this), balances[address(this)]);
    }


    function enablerefund(address refundaddress) external onlyOwner
    {
        require(!whitelisted[refundaddress]);
        refund[refundaddress] = true;
    }

    //refund of the Non whitelisted
    function claimrefund(address investor) public
    {
        require(refund[investor]);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        tokensinvestor[investor] = 0;
        // Refunded(investor, depositedValue);
    }

    // called by the owner, pause ICO
    function PauseICO() external onlyOwner atStage(Stages.ICO) {
        stopped = true;
        stage = Stages.PAUSED;
    }

    // called by the owner , resumes ICO
    function releaseICO() external onlyOwner atStage(Stages.PAUSED)
    {
        stopped = false;
        stage = Stages.ICO;
    }


    function setWhiteListAddresses(address _investor) external onlyOwner{
        whitelisted[_investor] = true;
    }

    //Investor can claim his tokens within two weeks of ICO end using this function
    //It can be also used to claim on behalf of any investor
    function claimTokensICO(address receiver) public
    // isValidPayload
    {
        //   if (receiver == 0)
        //   receiver = msg.sender;
        require(whitelisted[receiver]);
        require(tokensinvestor[receiver] > 0);
        uint256 tokensclaim = tokensinvestor[receiver];
        balances[address(this)] = (balances[address(this)]).sub(tokensclaim);
        balances[receiver] = (balances[receiver]).add(tokensclaim);
        tokensinvestor[receiver] = 0;
      emit  Transfer(address(this), receiver, balances[receiver]);
    }

    function end_ICO() external onlySuperAdmin atStage(Stages.ICO)
    {
        stage = Stages.ENDED;
        lefttokens = balances[address(this)];
        balances[superAdmin]=(balances[superAdmin]).add(lefttokens);
        balances[address(this)] = 0;
       emit Transfer(address(this), superAdmin, lefttokens);

    }

    // what is the total supply of the ech tokens
    function totalSupply() public view returns(uint256 total_Supply) {
        total_Supply = _totalsupply;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner)public view returns(uint256 balance) {
        return balances[_owner];
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address _from, address _to, uint256 _amount)public returns(bool success) {
        require(_to != 0x0);
        require(_amount >= 0);
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
      emit  Transfer(_from, _to, _amount);
        return true;
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount)public returns(bool success) {
        require(_spender != 0x0);
        allowed[msg.sender][_spender] = _amount;
      emit  Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender)public view returns(uint256 remaining) {
        require(_owner != 0x0 && _spender != 0x0);
        return allowed[_owner][_spender];
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount)public returns(bool success) {
        require(_to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
      emit Transfer(msg.sender, _to, _amount);
        return true;
    }

 

    //In case the ownership needs to be transferred
    function transferOwnership(address newOwner)public onlySuperAdmin
    {
        require(newOwner != 0x0);
        owner = newOwner;
    }


    function drain() external onlyOwner {
         address myAddress = this;
        superAdmin.transfer(myAddress.balance);
    }

}