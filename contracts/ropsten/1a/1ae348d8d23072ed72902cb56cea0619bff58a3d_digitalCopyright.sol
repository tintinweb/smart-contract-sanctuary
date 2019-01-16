pragma solidity ^0.4.24;

/**
 * @title IP digital copyright.
 */
//==============================================================================
//     _    _  _ _|_ _  .
//    (/_\/(/_| | | _\  .
//==============================================================================
contract digitalCopyright {
    using SafeMath for *;
    // fill out your address
    address constant private IpOwner = 0x89428305344Fe5De0801EDF41C5632C1e0FA231C;
    address constant private IpBuyer = 0x4A1061Afb0aF7d9f6c2D545Ada068dA68052c060;
    ERC20Interface constant private IERC20 = ERC20Interface(0x6102796465266ef3E499c24c50b3Ac603a87dc1A);
//==============================================================================
//     _ _  _  |`. _     _ _ |_ | _  _  .
//    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (default settings)
//=================_|===========================================================
    string constant public name = "IP Digital Copyright";
    string constant public symbol = "IPDC";
//==============================================================================
//     _| _ _|_ _    _ _ _|_    _   .
//    (_|(_| | (_|  _\(/_ | |_||_)  .  (data used to store info that changes)
//=============================|================================================
    uint256 public buyCount_;
//****************
// LICENSE DATA 
//****************
    mapping (uint256 => Elastos.DIDs) public nIDxDIDs_; // (number => DID) returns did by buying index
//****************
// FEE DATA 
//****************
    IPDCdatasets.distributeFee public fees_; // define each stakeholder&#39;s fee;
//==============================================================================
//     _ _  _  __|_ _    __|_ _  _  .
//    (_(_)| |_\ | | |_|(_ | (_)|   .  (initial data setup upon contract deploy)
//==============================================================================
    constructor ()
        public
    {
        buyCount_ = 0;
        fees_ = IPDCdatasets.distributeFee(2, 8); // 90% to IP copyright buyer, 2% return to user, 8% give to IP owner
    }
//==============================================================================
//     _ _  _  _|. |`. _  _ _  .
//    | | |(_)(_||~|~|(/_| _\  .  (these are safety checks)
//==============================================================================
    /**
     * @dev prevents contracts from interacting with fomo3dx 
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
//==============================================================================
//     _    |_ |. _   |`    _  __|_. _  _  _  .
//    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  (use these to interact with contract)
//====|=========================================================================
     /**
     * @dev buy copyright with paramaters
     */
    function buyCopyright
        (
        uint256 _rate,
        string _txid,
        string _key
        )
        public
        payable
        isHuman()
    {
        IpOwner.transfer(msg.value);
        uint256 _assets = ((msg.value).div(_rate)).mul(100);
        mortgage(_assets);
        updateDID(_txid, _key);
    }

    /**
     * @dev mortgage token amount to contract
     */
    function mortgage (uint256 _assets)
        private
    {
        IERC20.transferFrom(IpOwner, address(this), _assets);
    }

    /**
     * @dev update address and key to search DID
     */
    function updateDID (string _txid, string _key)
        private
    {
        buyCount_++;
        nIDxDIDs_[buyCount_].txid = _txid;
        nIDxDIDs_[buyCount_].key = _key;
    }

    /**
     * @dev customer buy goods and distribute
     */
    function buyGoods ()
        public
    {
        distribute(msg.sender);
    }

    /**
     * @dev distribute token amount to each stakeholder
     */
    function distribute (address _user)
        private
    {
        uint256 _balance = IERC20.balanceOf(address(this));
        if (_balance > 0)
        {
            uint256 _ownValue = (_balance.mul(fees_.owner)).div(100);
            uint256 _retrValue = (_balance.mul(fees_.retr)).div(100);
            _balance = _balance.sub(_ownValue.add(_retrValue));
            // distribute to each stakeholder
            IERC20.transferFrom(address(this), IpOwner, _ownValue);
            IERC20.transferFrom(address(this), IpBuyer, _balance);
            IERC20.transferFrom(address(this), _user, _retrValue);
        }
    }
}

//==============================================================================
//  . _ _|_ _  _ |` _  _ _  _  .
//  || | | (/_| ~|~(_|(_(/__\  .
//==============================================================================
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20Interface {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

//==============================================================================
//   __|_ _    __|_ _  .
//  _\ | | |_|(_ | _\  .
//==============================================================================
/**
 * @dev the implementation of elastos DID searching
 */
library Elastos {
    struct DIDs {
        string txid;
        string key;
    }
}

/**
 * @dev datasets of IP digital right
 */
library IPDCdatasets {
    struct distributeFee {
        uint256 retr; // distribute 2% fee to buyer  
        uint256 owner; // distribute 8% fee to ip right owner
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}