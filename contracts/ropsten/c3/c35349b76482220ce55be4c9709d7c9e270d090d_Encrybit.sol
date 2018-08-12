pragma solidity 0.4.24;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 
// 
// ----------------------------------------------------------------------------

contract Encrybit is ERC20Interface, Owned {
    using SafeMath for uint;

    string public constant name = "Encrybit";
    string public constant symbol = "EBT";
    uint8 public constant decimals = 18;

    uint constant public _decimals18 = uint(10) ** decimals;

    uint constant public _totalSupply    = 470000000 * _decimals18;
    //uint constant public saleTokenSupply = 162000000 * _decimals18;
    uint constant public saleTokenSupply = 36000 * _decimals18;
    uint constant public teamTokenSupply = 308000000 * _decimals18;
    
    // Address where funds are collected
    address constant public wallet = 0x255ae182b2e823573FE0551FA8ece7F824Fd1E7F;


    constructor() public {
        balances[owner] = _totalSupply;
        whiteList[owner] = true;
        emit Transfer(address(0), owner, _totalSupply);
    }


// ----------------------------------------------------------------------------
// mappings for implementing ERC20 
// ERC20 standard functions
// ----------------------------------------------------------------------------
    // 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function _transfer(address _from, address _toAddress, uint _tokens) private {
        balances[_from] = balances[_from].sub(_tokens);
        balances[_toAddress] = balances[_toAddress].add(_tokens);
        emit Transfer(_from, _toAddress, _tokens);
    }
    
    function transfer(address _add, uint _tokens) public returns (bool success) {
        //checkTransfer(msg.sender, _tokens);
        
        require(_add != address(0));
        require(_tokens <= balances[msg.sender]);
        
        _transfer(msg.sender, _add, _tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address _toAddr, uint tokens) public returns (bool success) {
        //checkTransfer(from, tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        _transfer(from, _toAddr, tokens);
        return true;
    }


/////////////////////// Smart Contract //////////////////////////

    // Amount of ETH received during ICO
    uint public weiRaised;
    uint public ebtRaised;
    
    uint constant public softCapUSD = 20000000;
    uint constant public hardCapUSD = 53000000;

    // Minimum wei to buy token during ICO 0.01 eth
    uint internal minWeiBuy_ICO = _decimals18 / 100;
    
    // Minimum wei to buy token during presale 1 eth
    uint internal minWeiBuy_preICO =  _decimals18;
    
    // For 1eth we have 20 000 EBT
    uint256 mt = 20000;
    
    uint256 public remainTokenSupply = saleTokenSupply;
    
    // WhiteList
    mapping(address => bool) public whiteList;
    
    // Ether send 
    mapping(address => uint256) public ethSent;
    
    // receive Token 
    mapping(address => bool) public receivedToken;
    
    
    // All dates are stored as timestamps.
    uint constant public startPresale   = 1531692000; // 16.07.2018 00:00:00
    uint constant public endPresale     = 1543622399; // 30.11.2018 23:59:59
    uint constant public startCrowdsale = 1548979199; // 31.01.2019 23:59:59
    uint constant public endCrowdsale   = 1553903999; // 29.03.2019 23:59:59
    
    bool icoClosed = false;

    function _getTokenBonus() public pure returns(uint256) {
      //

      return 4000;  
    }
    
    function _getTokenAmount(uint256 _weiAmount)  internal pure returns (uint256) {
        uint256 token = _weiAmount * 20000  ;
        uint256  tokenBonus = _getTokenBonus() * _decimals18;
        return token.add(tokenBonus);
    }
    
/////////////////////// MODIFIERS ///////////////////////

    // In WhiteList
    modifier inwhiteList(address _adr){
        require(whiteList[_adr]);
        _;
    }

    // Ensure actions can only happen during Presale
    modifier duringPresale(){
        require(now <= endPresale);
        require(now >= startPresale);
        _;
    }
    
    // Ensure actions can only happen during CrowdSale
    modifier duringCrowdsale(){
        require(now <= endCrowdsale);
        require(now >= startCrowdsale);
        _;
    }

    // ico sill runing
    modifier icoNotClosed(){
        require(!icoClosed, "ICO is close, Thanks");
        _;
    }

    // token available
    modifier remainToken(){
        require(remainTokenSupply > 0);
        _;
    }
    
    // address not null
    modifier addressNotNull(address _addr){
        require(_addr != address(0));
        _;
    }

    // amount >0
    modifier amountNotNull(uint256 _unit){
        require(_unit != 0);
        _;
    }

    // amount >0
    modifier checkMinWei_preICo(uint256 _unit){
        require(_unit >= minWeiBuy_ICO);
        _;
    }
    
/////////////////////// Events ///////////////////////

    /**
     * Event for token withdrawal logging
     * @param receiver who receive the tokens
     * @param amount amount of tokens sent
     */
    event TokenDelivered(address indexed receiver, uint256 amount);

/////////////////////// Function checker ///////////////////////


    // Add early investor
    function addInvestor(address[] members) public onlyOwner {
        for(uint i = 0; i < members.length; i++) {
            whiteList[members[i]] = true;
        }
    }
    
    /// @notice doAirdrop is called when we launch airdrop.
    /// @notice airdrop tokens has their own supply.
    //uint dropped = 0;
    /*function doAirdrop(address[] members, uint[] tokens) public onlyOwner {
        require(members.length == tokens.length);
    
        for(uint i = 0; i < members.length; i++) {
            _freezeTransfer(members[i], tokens[i]);
            dropped = dropped.add(tokens[i]);
        }
        require(dropped <= bountySupply);
    }*/
    
    
    //inwhiteList(_addrTo)
    function purchaseToken(address _addrTo) payable public 
            
        addressNotNull(_addrTo)
        amountNotNull(msg.value)  { 
        
        require(now >= startPresale && now <= endCrowdsale);
        require(!icoClosed);
        
        uint _wei = msg.value;
        uint _ebtToken = _getTokenAmount(_wei);
        //uint256 weiToRefund = 0;
        
        /* If the user want par example 2000 token
           but its remain 100 token refund him
        
        if(remainTokenSupply > _ebtToken) {
            uint256 weiToPurchase = (remainTokenSupply.mul(_wei)).div(_ebtToken);
            assert( _wei >= weiToPurchase );
            weiToRefund = _wei.sub(weiToPurchase);
            _wei = weiToPurchase;
            icoClosed = true;
        }
         */
        updateCrowdfundState(_ebtToken, _addrTo, _wei);
        
        //if(weiToRefund>0) _addrTo.transfer(weiToRefund);
        _forwardFunds(); 
    }
    
    function updateCrowdfundState(uint256 _ebt, address _addr, uint256 _wei) internal {
        
        // Token raised
        ebtRaised = ebtRaised.add(_ebt);
        // Wei raised by address
        ethSent[_addr] = ethSent[_addr].add(_wei);
        // Total wei raised
        weiRaised = weiRaised.add(_wei);
        // Change balances
        balances[_addr] = balances[_addr].add(_ebt);
        // Set this address to false to not receive token before tokenDistribution
        receivedToken[_addr] = false;
        remainTokenSupply = remainTokenSupply.sub(_ebt);
    }
    
     /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    
    /**
     * @dev Deliver tokens to receiver_ after crowdsale ends.
     */
    function withdrawTokensFor(address receiver_) internal addressNotNull(receiver_) {
        
        
        uint256 amount = balances[receiver_];
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        
        balances[msg.sender] = balances[msg.sender].sub(balances[receiver_]);
        
        emit Transfer(msg.sender, receiver_, balances[receiver_]);
        receivedToken[receiver_] = true;
    }
    
    function tokenDistribution(address[] members) public onlyOwner {
    
        //require(icoClosed);
        for(uint i = 0; i < members.length; i++) {
            require(!receivedToken[members[i]]);
            withdrawTokensFor(members[i]);
        }
        
    }
    

    function () payable external {
        purchaseToken(msg.sender);
    }

    // Account 2 0x2F7F14890118f3908732DD3A71bEd7DB886CbA4b

}