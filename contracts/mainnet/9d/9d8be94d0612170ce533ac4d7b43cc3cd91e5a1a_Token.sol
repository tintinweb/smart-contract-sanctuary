pragma solidity ^0.4.24;  
////////////////////////////////////////////////////////////////////////////////
library     SafeMath
{
    //--------------------------------------------------------------------------
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0)     return 0;
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    //--------------------------------------------------------------------------
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a/b;
    }
    //--------------------------------------------------------------------------
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }
    //--------------------------------------------------------------------------
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
////////////////////////////////////////////////////////////////////////////////
library     StringLib       // (minimal version)
{
    function same(string strA, string strB) internal pure returns(bool)
    {
        return keccak256(abi.encodePacked(strA))==keccak256(abi.encodePacked(strB));        // using abi.encodePacked since solidity v0.4.23
    }
}
////////////////////////////////////////////////////////////////////////////////
contract    ERC20 
{
    using SafeMath  for uint256;
    using StringLib for string;

    //----- VARIABLES

    address public              owner;          // Owner of this contract
    address public              admin;          // The one who is allowed to do changes 

    mapping(address => uint256)                         balances;       // Maintain balance in a mapping
    mapping(address => mapping (address => uint256))    allowances;     // Allowances index-1 = Owner account   index-2 = spender account

    //------ TOKEN SPECIFICATION

    string  public  constant    name       = "BqtX Token";
    string  public  constant    symbol     = "BQTX";
    uint256 public  constant    decimals   = 18;      // Handle the coin as FIAT (2 decimals). ETH Handles 18 decimal places
    uint256 public  constant    initSupply = 800000000 * 10**decimals;        // 10**18 max
    uint256 public  constant    supplyReserveVal = 600000000 * 10**decimals;          // if quantity => the ##MACRO## addrs "* 10**decimals" 

    //-----

    uint256 public              totalSupply;
    uint256 public              icoSalesSupply   = 0;                   // Needed when burning tokens
    uint256 public              icoReserveSupply = 0;
    uint256 public              softCap = 10000000   * 10**decimals;
    uint256 public              hardCap = 500000000   * 10**decimals;

    //---------------------------------------------------- smartcontract control

    uint256 public              icoDeadLine = 1544313600;     // 2018-12-09 00:00 (GMT+0)

    bool    public              isIcoPaused            = false; 
    bool    public              isStoppingIcoOnHardCap = false;

    //--------------------------------------------------------------------------

    modifier duringIcoOnlyTheOwner()  // if not during the ico : everyone is allowed at anytime
    { 
        require( now>icoDeadLine || msg.sender==owner );
        _;
    }

    modifier icoFinished()          { require(now > icoDeadLine);           _; }
    modifier icoNotFinished()       { require(now <= icoDeadLine);          _; }
    modifier icoNotPaused()         { require(isIcoPaused==false);          _; }
    modifier icoPaused()            { require(isIcoPaused==true);           _; }
    modifier onlyOwner()            { require(msg.sender==owner);           _; }
    modifier onlyAdmin()            { require(msg.sender==admin);           _; }

    //----- EVENTS

    event Transfer(address indexed fromAddr, address indexed toAddr,   uint256 amount);
    event Approval(address indexed _owner,   address indexed _spender, uint256 amount);

            //---- extra EVENTS

    event onAdminUserChanged(   address oldAdmin,       address newAdmin);
    event onOwnershipTransfered(address oldOwner,       address newOwner);
    event onAdminUserChange(    address oldAdmin,       address newAdmin);
    event onIcoDeadlineChanged( uint256 oldIcoDeadLine, uint256 newIcoDeadline);
    event onHardcapChanged(     uint256 hardCap,        uint256 newHardCap);
    event icoIsNowPaused(       uint8 newPauseStatus);
    event icoHasRestarted(      uint8 newPauseStatus);

    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    constructor()   public 
    {
        owner       = msg.sender;
        admin       = owner;

        isIcoPaused = false;
        //-----

        balances[owner] = initSupply;   // send the tokens to the owner
        totalSupply     = initSupply;
        icoSalesSupply  = totalSupply;   

        //----- Handling if there is a special maximum amount of tokens to spend during the ICO or not

        icoSalesSupply   = totalSupply.sub(supplyReserveVal);
        icoReserveSupply = totalSupply.sub(icoSalesSupply);
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //----- ERC20 FUNCTIONS
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function balanceOf(address walletAddress) public constant returns (uint256 balance) 
    {
        return balances[walletAddress];
    }
    //--------------------------------------------------------------------------
    function transfer(address toAddr, uint256 amountInWei)  public   duringIcoOnlyTheOwner   returns (bool)     // don&#39;t icoNotPaused here. It&#39;s a logic issue. 
    {
        require(toAddr!=0x0 && toAddr!=msg.sender && amountInWei>0);     // Prevent transfer to 0x0 address and to self, amount must be >0

        uint256 availableTokens = balances[msg.sender];

        //----- Checking Token reserve first : if during ICO    

        if (msg.sender==owner && now <= icoDeadLine)                    // ICO Reserve Supply checking: Don&#39;t touch the RESERVE of tokens when owner is selling
        {
            assert(amountInWei<=availableTokens);

            uint256 balanceAfterTransfer = availableTokens.sub(amountInWei);      

            assert(balanceAfterTransfer >= icoReserveSupply);           // We try to sell more than allowed during an ICO
        }

        //-----

        balances[msg.sender] = balances[msg.sender].sub(amountInWei);
        balances[toAddr]     = balances[toAddr].add(amountInWei);

        emit Transfer(msg.sender, toAddr, amountInWei);

        return true;
    }
    //--------------------------------------------------------------------------
    function allowance(address walletAddress, address spender) public constant returns (uint remaining)
    {
        return allowances[walletAddress][spender];
    }
    //--------------------------------------------------------------------------
    function transferFrom(address fromAddr, address toAddr, uint256 amountInWei)  public  returns (bool) 
    {
        if (amountInWei <= 0)                                   return false;
        if (allowances[fromAddr][msg.sender] < amountInWei)     return false;
        if (balances[fromAddr] < amountInWei)                   return false;

        balances[fromAddr]               = balances[fromAddr].sub(amountInWei);
        balances[toAddr]                 = balances[toAddr].add(amountInWei);
        allowances[fromAddr][msg.sender] = allowances[fromAddr][msg.sender].sub(amountInWei);

        emit Transfer(fromAddr, toAddr, amountInWei);
        return true;
    }
    //--------------------------------------------------------------------------
    function approve(address spender, uint256 amountInWei) public returns (bool) 
    {
        require((amountInWei == 0) || (allowances[msg.sender][spender] == 0));
        allowances[msg.sender][spender] = amountInWei;
        emit Approval(msg.sender, spender, amountInWei);

        return true;
    }
    //--------------------------------------------------------------------------
    function() public                       
    {
        assert(true == false);      // If Ether is sent to this address, don&#39;t handle it -> send it back.
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function transferOwnership(address newOwner) public onlyOwner               // @param newOwner The address to transfer ownership to.
    {
        require(newOwner != address(0));

        emit onOwnershipTransfered(owner, newOwner);
        owner = newOwner;
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function    changeAdminUser(address newAdminAddress) public onlyOwner
    {
        require(newAdminAddress!=0x0);

        emit onAdminUserChange(admin, newAdminAddress);
        admin = newAdminAddress;
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function    changeIcoDeadLine(uint256 newIcoDeadline) public onlyAdmin
    {
        require(newIcoDeadline!=0);

        emit onIcoDeadlineChanged(icoDeadLine, newIcoDeadline);
        icoDeadLine = newIcoDeadline;
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function    changeHardCap(uint256 newHardCap) public onlyAdmin
    {
        require(newHardCap!=0);

        emit onHardcapChanged(hardCap, newHardCap);
        hardCap = newHardCap;
    }
    //--------------------------------------------------------------------------
    function    isHardcapReached()  public view returns(bool)
    {
        return (isStoppingIcoOnHardCap && initSupply-balances[owner] > hardCap);
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function    pauseICO()  public onlyAdmin
    {
        isIcoPaused = true;
        emit icoIsNowPaused(1);
    }
    //--------------------------------------------------------------------------
    function    unpauseICO()  public onlyAdmin
    {
        isIcoPaused = false;
        emit icoHasRestarted(0);
    }
    //--------------------------------------------------------------------------
    function    isPausedICO() public view     returns(bool)
    {
        return (isIcoPaused) ? true : false;
    }
    /*--------------------------------------------------------------------------
    //
    // When ICO is closed, send the remaining (unsold) tokens to address 0x0
    // So no one will be able to use it anymore... 
    // Anyone can check address 0x0, so to proove unsold tokens belong to no one anymore
    //
    //--------------------------------------------------------------------------*/
    function destroyRemainingTokens() public onlyAdmin icoFinished icoNotPaused  returns(uint)
    {
        require(msg.sender==owner && now>icoDeadLine);

        address   toAddr = 0x0000000000000000000000000000000000000000;

        uint256   amountToBurn = balances[owner];

        if (amountToBurn > icoReserveSupply)
        {
            amountToBurn = amountToBurn.sub(icoReserveSupply);
        }

        balances[owner]  = balances[owner].sub(amountToBurn);
        balances[toAddr] = balances[toAddr].add(amountToBurn);

        emit Transfer(msg.sender, toAddr, amountToBurn);
        //Transfer(msg.sender, toAddr, amountToBurn);

        return 1;
    }        

    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------

}
////////////////////////////////////////////////////////////////////////////////
contract    Token  is  ERC20
{
    using SafeMath  for uint256;
    using StringLib for string;

    //-------------------------------------------------------------------------- Constructor
    constructor()   public 
    {
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
}