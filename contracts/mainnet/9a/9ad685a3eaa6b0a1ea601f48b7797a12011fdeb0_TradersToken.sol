pragma solidity ^0.4.25;

/*TradersToken
www.Crypterx.com Development
www.icomastery.eu consulted
Symbol: TRDS
Version: 1.1
*/

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}


contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It&#39;s O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ERC20 is ERC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}

contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    constructor(uint supply) public {
        _balances[msg.sender] = supply;
        _supply = supply;
    }

 /**
  * @dev Total number of tokens in existence
  */
    function totalSupply() public view returns (uint) {
        return _supply;
    }

 /**
  * @dev Gets the balance of the specified address.
  * @param src The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */

    function balanceOf(address src) public view returns (uint) {
        return _balances[src];
    }

 /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param src address The address which owns the funds.
   * @param guy address The address which will spend the funds.
   */
    function allowance(address src, address guy) public view returns (uint) {
        return _approvals[src][guy];
    }

  /**
   * @dev Transfer token for a specified address
   * @param dst The address to transfer to.
   * @param wad The amount to be transferred.
   */

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

 /**
   * @dev Transfer tokens from one address to another
   * @param src address The address which you want to send tokens from
   * @param dst address The address which you want to transfer to
   * @param wad uint256 the amount of tokens to be transferred
   */

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        if (src != msg.sender) {
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }


 /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param guy The address which will spend the funds.
   * @param wad The amount of tokens to be spent.
   */

    function approve(address guy, uint wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }

 /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param src The address which will spend the funds.
   * @param wad The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address src,
    uint256 wad
  )
    public
    returns (bool)
  {
    require(src != address(0));

    _approvals[src][msg.sender] = add(_approvals[src][msg.sender], wad);
    emit Approval(msg.sender, src, _approvals[msg.sender][src]);
    return true;
  }

 /**
   * @dev Decrese the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param src The address which will spend the funds.
   * @param wad The amount of tokens to increase the allowance by.
   */
  function decreaseAllowance(
    address src,
    uint256 wad
  )
    public
    returns (bool)
  {
    require(src != address(0));
    _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
    emit Approval(msg.sender, src, _approvals[msg.sender][src]);
    return true;
  }

}

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

contract DSStop is DSNote, DSAuth {

    bool public stopped;

    modifier stoppable {
        require(!stopped);
        _;
    }
    function stop() public auth note {
        stopped = true;
    }
    function start() public auth note {
        stopped = false;
    }

}


contract TradersToken is DSTokenBase , DSStop {

    string  public  symbol="TRDS";
    string  public  name="Traders Token";
    uint256  public  decimals = 3; // Standard Token Precision
    uint256 public initialSupply=500000000000000;
    address public burnAdmin;
    constructor() public
    DSTokenBase(initialSupply)
    {
        burnAdmin=msg.sender;
    }

    event Burn(address indexed guy, uint wad);

 /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyAdmin() {
    require(isAdmin());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isAdmin() public view returns(bool) {
    return msg.sender == burnAdmin;
}

/**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyAdmin {
    burnAdmin = address(0);
  }

    function approve(address guy) public stoppable returns (bool) {
        return super.approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        return super.approve(guy, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        stoppable
        returns (bool)
    {
        if (src != msg.sender && _approvals[src][msg.sender] != uint(-1)) {
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }



    /**
   * @dev Burns a specific amount of tokens from the target address
   * @param guy address The address which you want to send tokens from
   * @param wad uint256 The amount of token to be burned
   */
    function burnfromAdmin(address guy, uint wad) public onlyAdmin {
        require(guy != address(0));


        _balances[guy] = sub(_balances[guy], wad);
        _supply = sub(_supply, wad);

        emit Burn(guy, wad);
        emit Transfer(guy, address(0), wad);
    }


}