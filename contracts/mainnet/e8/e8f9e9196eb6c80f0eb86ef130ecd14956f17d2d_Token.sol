pragma solidity ^0.4.18;        // v0.4.18 was the latest possible version. 0.4.19 and above were not allowed

////////////////////////////////////////////////////////////////////////////////
library SafeMath 
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
        uint256 c = a / b;
        return c;
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
library StringLib 
{
    function concat(string strA, string strB) internal pure returns (string)
    {
        uint            i;
        uint            g;
        uint            finalLen;
        bytes memory    dataStrA;
        bytes memory    dataStrB;
        bytes memory    buffer;

        dataStrA  = bytes(strA);
        dataStrB  = bytes(strB);

        finalLen  = dataStrA.length + dataStrB.length;
        buffer    = new bytes(finalLen);

        for (g=i=0; i<dataStrA.length; i++)   buffer[g++] = dataStrA[i];
        for (i=0;   i<dataStrB.length; i++)   buffer[g++] = dataStrB[i];

        return string(buffer);
    }
    //--------------------------------------------------------------------------
    function same(string strA, string strB) internal pure returns(bool)
    {
        return keccak256(strA)==keccak256(strB);
    }
    //-------------------------------------------------------------------------
    function uintToAscii(uint number) internal pure returns(byte) 
    {
             if (number < 10)         return byte(48 + number);
        else if (number < 16)         return byte(87 + number);

        revert();
    }
    //-------------------------------------------------------------------------
    function asciiToUint(byte char) internal pure returns (uint) 
    {
        uint asciiNum = uint(char);

             if (asciiNum > 47 && asciiNum < 58)    return asciiNum - 48;
        else if (asciiNum > 96 && asciiNum < 103)   return asciiNum - 87;

        revert();
    }
    //-------------------------------------------------------------------------
    function bytes32ToString (bytes32 data) internal pure returns (string) 
    {
        bytes memory bytesString = new bytes(64);

        for (uint j=0; j < 32; j++) 
        {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));

            bytesString[j*2+0] = uintToAscii(uint(char) / 16);
            bytesString[j*2+1] = uintToAscii(uint(char) % 16);
        }
        return string(bytesString);
    }
    //-------------------------------------------------------------------------
    function stringToBytes32(string str) internal pure returns (bytes32) 
    {
        bytes memory bString = bytes(str);
        uint uintString;

        if (bString.length != 64) { revert(); }

        for (uint i = 0; i < 64; i++) 
        {
            uintString = uintString*16 + uint(asciiToUint(bString[i]));
        }
        return bytes32(uintString);
    }
}
////////////////////////////////////////////////////////////////////////////////
contract ERC20 
{
    function balanceOf(   address _owner)                               public constant returns (uint256 balance);
    function transfer(    address toAddr,  uint256 amount)              public returns (bool success);
    function allowance(   address owner,   address spender)             public constant returns (uint256);
    function approve(     address spender, uint256 value)               public returns (bool);

    event Transfer(address indexed fromAddr, address indexed toAddr,   uint256 amount);
    event Approval(address indexed _owner,   address indexed _spender, uint256 amount);

    uint256 public totalSupply;
}
////////////////////////////////////////////////////////////////////////////////
contract Ownable 
{
    address public owner;

    //-------------------------------------------------------------------------- @dev The Ownable constructor sets the original `owner` of the contract to the sender account
    function Ownable() public 
    {
        owner = msg.sender;
    }
    //-------------------------------------------------------------------------- @dev Throws if called by any account other than the owner.
    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }
}
////////////////////////////////////////////////////////////////////////////////
contract Lockable is Ownable 
{
    uint256 internal constant lockedUntil = 1530604800;     // 2018-07-03 08:00 (GMT+0)

    address internal allowedSender;     // the address that can make transactions when the transaction is locked 

    //-------------------------------------------------------------------------- @dev Allow access only when is unlocked. This function is good when you make crowdsale to avoid token expose in exchanges
    modifier unlocked() 
    {
        require((now > lockedUntil) || (allowedSender == msg.sender));
        _;
    }
    //-------------------------------------------------------------------------- @dev Allows the current owner to transfer control of the contract to a newOwner.
    function transferOwnership(address newOwner) public onlyOwner               // @param newOwner The address to transfer ownership to.
    {
        require(newOwner != address(0));
        owner = newOwner;

        allowedSender = newOwner;
    }
}
////////////////////////////////////////////////////////////////////////////////
contract Token is ERC20, Lockable 
{
    using SafeMath for uint256;

    address public                                      owner;          // Owner of this contract
    mapping(address => uint256)                         balances;       // Maintain balance in a mapping
    mapping(address => mapping (address => uint256))    allowances;     // Allowances index-1 = Owner account   index-2 = spender account

    //------ TOKEN SPECIFICATION

    string public constant      name     = "TESTGVINE1";
    string public constant      symbol   = "TESTGVINE1";

    uint256 public constant     decimals = 18;      // Handle the coin as FIAT (2 decimals). ETH Handles 18 decimal places

    uint256 public constant     initSupply = 825000000 * 10**decimals;        // 10**18 max

    string private constant     supplyReserveMode="percent";        // "quantity" or "percent"
    uint256 public constant     supplyReserveVal = 58;          // if quantity => (val * 10**decimals)   if percent => val;

    uint256 public              icoSalesSupply   = 0;                   // Needed when burning tokens
    uint256 public              icoReserveSupply = 0;

    //-------------------------------------------------------------------------- Functions with this modifier can only be executed by the owner
    modifier onlyOwner() 
    {
        if (msg.sender != allowedSender) 
        {
            assert(true==false);
        }
        _;
    }
    //-------------------------------------------------------------------------- Functions with this modifier can only be executed by the owner
    modifier onlyOwnerDuringIco() 
    {
        if (msg.sender!=allowedSender || now > lockedUntil) 
        {
            assert(true==false);
        }
        _;
    }
    //-------------------------------------------------------------------------- Constructor
    function Token() public 
    {
        owner           = msg.sender;
        totalSupply     = initSupply;
        balances[owner] = initSupply;   // send the tokens to the owner

        //-----

        allowedSender = owner;          // In this contract, only the contract owner can send token while ICO is active.

        //----- Handling if there is a special maximum amount of tokens to spend during the ICO or not

        icoSalesSupply = totalSupply;   

        if (StringLib.same(supplyReserveMode, "quantity"))
        {
            icoSalesSupply = totalSupply.sub(supplyReserveVal);
        }
        else if (StringLib.same(supplyReserveMode, "percent"))
        {
            icoSalesSupply = totalSupply.mul(supplyReserveVal).div(100);
        }

        icoReserveSupply = totalSupply.sub(icoSalesSupply);
    }
    //--------------------------------------------------------------------------
    function transfer(address toAddr, uint256 amount)  public   unlocked returns (bool success) 
    {
        require(toAddr!=0x0 && toAddr!=msg.sender && amount>0);     // Prevent transfer to 0x0 address and to self, amount must be >0

        uint256 availableTokens      = balances[msg.sender];

        if (msg.sender==allowedSender)                              // Special handling on contract owner 
        {
            if (now <= lockedUntil)                                 // The ICO is now running
            {
                uint256 balanceAfterTransfer = availableTokens.sub(amount);      

                assert(balanceAfterTransfer >= icoReserveSupply);          // don&#39;t sell more than allowed during ICO
            }
        }

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[toAddr]     = balances[toAddr].add(amount);

        emit Transfer(msg.sender, toAddr, amount);
        //Transfer(msg.sender, toAddr, amount);

        return true;
    }
    //--------------------------------------------------------------------------
    function balanceOf(address _owner)  public   constant returns (uint256 balance) 
    {
        return balances[_owner];
    }
    //--------------------------------------------------------------------------
    function approve(address _spender, uint256 amount)  public   returns (bool) 
    {
        require((amount == 0) || (allowances[msg.sender][_spender] == 0));

        allowances[msg.sender][_spender] = amount;

        emit Approval(msg.sender, _spender, amount);
        //Approval(msg.sender, _spender, amount);

        return true;
    }
    //--------------------------------------------------------------------------
    function allowance(address _owner, address _spender)  public   constant returns (uint remaining)
    {
        return allowances[_owner][_spender];    // Return the allowance for _spender approved by _owner
    }
    //--------------------------------------------------------------------------
    function() public                       
    {
        assert(true == false);      // If Ether is sent to this address, don&#39;t handle it -> send it back.
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------


    //--------------------------------------------------------------------------
    //
    // When ICO is closed, send the relaining (unsold) tokens to address 0x0
    // So no one will be able to use it anymore... 
    // Anyone can check address 0x0, so to proove unsold tokens belong to no one anymore
    //
    //--------------------------------------------------------------------------
    function destroyRemainingTokens() public unlocked /*view*/ returns(uint)
    {
        require(msg.sender==allowedSender && now>lockedUntil);

        address   toAddr = 0x0000000000000000000000000000000000000000;

        uint256   amountToBurn = balances[allowedSender];

        if (amountToBurn > icoReserveSupply)
        {
            amountToBurn = amountToBurn.sub(icoReserveSupply);
        }

        balances[owner]  = balances[allowedSender].sub(amountToBurn);
        balances[toAddr] = balances[toAddr].add(amountToBurn);

        //emit Transfer(msg.sender, toAddr, amount);
        Transfer(msg.sender, toAddr, amountToBurn);

        return 1;
    }        
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
}