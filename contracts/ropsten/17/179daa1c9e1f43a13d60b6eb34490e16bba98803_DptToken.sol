pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract DptToken {
    
    using SafeMath for uint256;

    // Token basic information
    string  public name     = &quot;Deliverers Power Token&quot;;
    string  public symbol   = &quot;DPT&quot;;
    uint256 public decimals = 18;

    // Mapping of balance and allowance
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    bool    public stopped      = false;
    uint256 public totalSupply  = 5000000000 * (10 ** uint256(decimals));
    
    address owner;
    address walletTeam;
    address walletAdvisor;
    address walletBounty;
    address walletGft;
    
    uint256 fundTeam;
    uint256 fundAdvisor;
    uint256 fundBounty;
    uint256 fundGft;
    
    uint256 public fundRaised   = 0;
    uint256 public tokenSold    = 0;
    uint256 tokenPerEth         = 6000;

    struct icoData {
        uint256 icoStage;
        uint256 icoStartDate;
        uint256 icoEndDate;
        uint256 icoFund;
        uint256 icoBonus;
        uint256 icoSold;
    }

    icoData ico;

    // only owner modifier
    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    // is ico running modifier
    modifier isRunning {
        assert (!stopped);
        _;
    }
    
    // is ico stopped modifier
    modifier isStopped {
        assert (stopped);
        _;
    }

    constructor() public {
        owner               = 0x8055258a3d5a03e233bfc82660c4c3a65a296365;
        balanceOf[owner]    = totalSupply;
        emit Transfer(0x0, owner, totalSupply);
    }
    
    // Set wallet and amount for team
    function setTeamFundWallet(address _address, uint256 _value) public isOwner isRunning returns (bool) {
        require(walletTeam == address(0));
        require(_value > 0);
        transfer(_address, _value * (10 ** uint256(decimals)));
        walletTeam = _address;
        fundTeam = _value * (10 ** uint256(decimals));
        return true;
    }
        
    // Set wallet and amount for advisor
    function setAdvisorFundWallet(address _address, uint256 _value) public isOwner isRunning returns (bool) {
        require(walletAdvisor == address(0));
        require(_value > 0);
        transfer(_address, _value * (10 ** uint256(decimals)));
        walletAdvisor = _address;
        fundAdvisor = _value * (10 ** uint256(decimals));
        return true;
    }
    
    // Set wallet and amount for bounty
    function setBountyFundWallet(address _address, uint256 _value) public isOwner isRunning returns (bool) {
        require(walletBounty == address(0));
        require(_value > 0);
        transfer(_address, _value * (10 ** uint256(decimals)));
        walletBounty = _address;
        fundBounty = _value * (10 ** uint256(decimals));
        return true;
    }
    
    // Set wallet and fund for gft
    function setGftFundWallet(address _address, uint256 _value) public isOwner isRunning returns (bool) {
        require(walletGft == address(0));
        require(_value > 0);
        transfer(_address, _value * (10 ** uint256(decimals)));
        walletGft = _address;
        fundGft = _value * (10 ** uint256(decimals));
        return true;
    }
    
    // function to send amount from team wallet
    function sendFromTeamWallet(address _to, uint256 _value) public isOwner isRunning returns(bool) {
        _transfer(walletTeam, _to, _value * (10 ** uint256(decimals)));
    }
    
    // function to send amount from advisor wallet
    function sendFromAdvisorWallet(address _to, uint256 _value) public isOwner isRunning {
        _transfer(walletAdvisor, _to, _value * (10 ** uint256(decimals)));
    }
    
    // function to send amount from bounty wallet
    function sendFromBountyWallet(address _to, uint256 _value) public isOwner isRunning {
        _transfer(walletBounty, _to, _value * (10 ** uint256(decimals)));
    }
    
    // function to send amount from gft wallet
    function sendFromGftWallet(address _to, uint256 _value) public isOwner isRunning {
        _transfer(walletGft, _to, _value * (10 ** uint256(decimals)));
    }

    // internal function transfer from different wallets
    function _transfer(address _wallet, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(balanceOf[_wallet] >= _value);
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        
        balanceOf[_wallet]  = balanceOf[_wallet].sub(_value);
        balanceOf[_to]      = balanceOf[_to].add(_value);
        
        emit Transfer(_wallet, _to, _value);
    }

    // transfer to address with amount of token
    function transfer(address _to, uint256 _value) public isRunning returns (bool success) {
        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // transfer amount from one to another address
    function transferFrom(address _from, address _to, uint256 _value) public isRunning returns (bool success) {
        require(_from != address(0) && _to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    // approve for transfer from account
    function approve(address _spender, uint256 _value) public isRunning returns (bool success) {
        require(_spender != address(0));
        require(_value <= balanceOf[msg.sender]);
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // stop ico
    function stop() public isOwner isRunning {
        stopped = true;
    }

    // start ico
    function start() public isOwner isStopped {
        stopped = false;
    }

    // set ico stage with the stage, start, end, fund, bonus
    function setStage(uint256 _stage, uint256 _startDate, uint256 _endDate, uint256 _fund, uint256 _bonus) public isOwner returns(bool) {
        
        require(balanceOf[msg.sender] >= _fund);
        require(now < _startDate);
        require(_startDate < _endDate);
        
        ico.icoStage        = _stage;
        ico.icoStartDate    = _startDate;
        ico.icoEndDate      = _endDate;
        ico.icoFund         = _fund * (10 ** uint256(decimals));
        ico.icoBonus        = _bonus;
        ico.icoSold         = 0;
        
        return true;
    }

    // send token only owner can call
    function sendToken(address _to, uint _amount) public isOwner isRunning returns(bool) {

        // check for conditions
        require(msg.sender != address(0));
        require(_amount > 0);
        require(now >= ico.icoStartDate && now <= ico.icoEndDate);

        // calculate token and bonus
        uint tokens = _amount * (10 ** uint256(decimals));
        uint bonus  = ( tokens.mul(ico.icoBonus) ).div(100);
        uint total  = tokens;

        require(ico.icoFund >= tokens);
        
        transfer(_to, tokens);

        // update ico amounts sold and fund
        ico.icoFund      = ico.icoFund.sub(tokens);
        ico.icoSold      = ico.icoSold.add(tokens);

        fundRaised  = fundRaised.add((tokens.div(tokenPerEth)));

        if( balanceOf[walletBounty] >= bonus ) {
            sendFromBountyWallet(_to, bonus);
            total = total.add(bonus);
        }

        tokenSold   = tokenSold.add(total);

        return true;
    }

    // function for get all allocated wallet balance data
    function getWalletsData() public view isOwner returns(uint256[5]) {
        return [balanceOf[owner], balanceOf[walletTeam], balanceOf[walletAdvisor], balanceOf[walletBounty], balanceOf[walletGft]];
    }
    
    // function for get all allocated stage of ico data
    function getStageData() public view isOwner returns(uint256[6]) {
        return [ico.icoStage, ico.icoStartDate, ico.icoEndDate, ico.icoFund, ico.icoBonus, ico.icoSold];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}