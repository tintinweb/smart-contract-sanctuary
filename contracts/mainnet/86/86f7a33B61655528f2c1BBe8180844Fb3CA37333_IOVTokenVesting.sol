pragma solidity ^0.4.23;

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

contract IOVTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    uint256  public  airdropBSupply = 5*10**6*10**8; // airdrop total supply = 500W
    uint256  public  currentAirdropAmount = 0;
    uint256  airdropNum  =  10*10**8;                // 10IOV each time for airdrop
    mapping (address => bool) touched;               //records whether an address has received an airdrop;

    constructor(uint supply) public {
        _balances[msg.sender] = sub(supply, airdropBSupply);
        _supply = supply;
        emit Transfer(0x0, msg.sender, _balances[msg.sender]);
    }

    function totalSupply() public view returns (uint) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint) {
        return getBalance(src);
    }
    function allowance(address src, address guy) public view returns (uint) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(_balances[src] >= wad);

        if (src != msg.sender) {
            require(_approvals[src][msg.sender] >= wad);
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }

    //
    function getBalance(address src) internal constant returns(uint) {
        if( currentAirdropAmount < airdropBSupply && !touched[src]) {
            return add(_balances[src], airdropNum);
        } else {
            return _balances[src];
        }
    }
}

contract ContractLock is DSStop {

    uint  public  unlockTime;         // Start time for token transferring
    mapping (address => bool) public isAdmin;  // Admin accounts

    event LogAddAdmin(address whoAdded, address newAdmin);
    event LogRemoveAdmin(address whoRemoved, address admin);

    constructor(uint _unlockTime) public {
        unlockTime = _unlockTime;
        isAdmin[msg.sender] = true;
        emit LogAddAdmin(msg.sender, msg.sender);
    }

    function addAdmin(address admin) public auth returns (bool) {
        if(isAdmin[admin] == false) {
            isAdmin[admin] = true;
            emit LogAddAdmin(msg.sender, admin);
        }
        return true;
    }

    function removeAdmin(address admin) public auth returns (bool) {
        if(isAdmin[admin] == true) {
            isAdmin[admin] = false;
            emit LogRemoveAdmin(msg.sender, admin);
        }
        return true;
    }

    function setOwner(address owner_)
        public
        auth
    {
        removeAdmin(owner);
        owner = owner_;
        addAdmin(owner);
        emit LogSetOwner(owner);

    }


    modifier onlyAdmin {
        require (isAdmin[msg.sender]);
        _;
    }


    modifier isUnlocked {
        require( now > unlockTime || isAdmin[msg.sender]);
        _;
    }

    function setUnlockTime(uint unlockTime_) public auth {
        unlockTime = unlockTime_;
    }

}

contract IOVToken is IOVTokenBase(10*10**9*10**8), ContractLock(1527782400) {

    string  public  symbol;
    uint256  public  decimals = 8; // standard token precision. override to customize

    constructor(string symbol_) public {
        symbol = symbol_;
    }

    function approve(address guy) public stoppable returns (bool) {
        return super.approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        return super.approve(guy, wad);
    }

    function transferFrom(address src, address dst, uint wad) public stoppable isUnlocked returns (bool)
    {
        require(_balances[src] >= wad);

        if(!touched[src] && currentAirdropAmount < airdropBSupply) {
            _balances[src] = add( _balances[src], airdropNum );
            touched[src] = true;
            currentAirdropAmount = add(currentAirdropAmount, airdropNum);
        }

        if (src != msg.sender && _approvals[src][msg.sender] != uint(-1)) {
            require(_approvals[src][msg.sender] >= wad);
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function push(address dst, uint wad) public {
        transferFrom(msg.sender, dst, wad);
    }
    function pull(address src, uint wad) public {
        transferFrom(src, msg.sender, wad);
    }
    function move(address src, address dst, uint wad) public {
        transferFrom(src, dst, wad);
    }

    // Optional token name
    string   public  name = "CarLive Chain";

    function setName(string name_) public auth {
        name = name_;
    }

    //
}


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract IOVTokenVesting is DSAuth, DSMath {

  event LogNewAllocation(address indexed _recipient, uint256 _totalAllocated);
  event LogIOVClaimed(address indexed _recipient, uint256 _amountClaimed);
  event LogDisable(address indexed _recipient, bool _disable);

  event LogAddVestingAdmin(address whoAdded, address indexed newAdmin);
  event LogRemoveVestingAdmin(address whoRemoved, address indexed admin);

  //Allocation with vesting information
  struct Allocation {
    uint256  start;          // Start time of vesting contract
    uint256  cliff;          // cliff time in which tokens will begin to vest
    uint256  periods;        // Periods for vesting
    uint256  totalAllocated; // Total tokens allocated
    uint256  amountClaimed;  // Total tokens claimed
    bool     disable;        // allocation disabled or not.
  }

  IOVToken  public  IOV;
  mapping (address => Allocation) public beneficiaries;
  mapping (address => bool) public isVestingAdmin;  // community Admin accounts

  // constructor function
  constructor(IOVToken iov) public {
    assert(address(IOV) == address(0));
    IOV = iov;
  }

  // Contract admin related functions
  function addVestingAdmin(address admin) public auth returns (bool) {
      if(isVestingAdmin[admin] == false) {
          isVestingAdmin[admin] = true;
          emit LogAddVestingAdmin(msg.sender, admin);
      }
      return true;
  }

  function removeVestingAdmin(address admin) public auth returns (bool) {
      if(isVestingAdmin[admin] == true) {
          isVestingAdmin[admin] = false;
          emit LogRemoveVestingAdmin(msg.sender, admin);
      }
      return true;
  }

  modifier onlyVestingAdmin {
      require ( msg.sender == owner || isVestingAdmin[msg.sender] );
      _;
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

  function totalUnClaimed() public view returns (uint256) {
    return IOV.balanceOf(this);
  }

  /**
  * @dev Allow the owner of the contract to assign a new allocation
  * @param _recipient The recipient of the allocation
  * @param _totalAllocated The total amount of IOV allocated to the receipient (after vesting)
  * @param _start Start time of vesting contract
  * @param _cliff cliff time in which tokens will begin to vest
  * @param _period Periods for vesting
  */
  function setAllocation(address _recipient, uint256 _totalAllocated, uint256 _start, uint256 _cliff, uint256 _period) public onlyVestingAdmin {
    require(_recipient != address(0));
    require(beneficiaries[_recipient].totalAllocated == 0 && _totalAllocated > 0);
    require(_start > 0 && _start < 32503680000);
    require(_cliff >= _start);
    require(_period > 0);

    beneficiaries[_recipient] = Allocation(_start, _cliff, _period, _totalAllocated, 0, false);
    emit LogNewAllocation(_recipient, _totalAllocated);
  }

  function setDisable(address _recipient, bool disable) public onlyVestingAdmin {
    require(beneficiaries[_recipient].totalAllocated > 0);
    beneficiaries[_recipient].disable = disable;
    emit LogDisable(_recipient, disable);
  }

  /**
   * @notice Transfer a recipients available allocation to their address.
   * @param _recipient The address to withdraw tokens for
   */
  function transferTokens(address _recipient) public {
    require(beneficiaries[_recipient].amountClaimed < beneficiaries[_recipient].totalAllocated);
    require( now >= beneficiaries[_recipient].cliff );
    require(!beneficiaries[_recipient].disable);

    uint256 unreleased = releasableAmount(_recipient);
    require( unreleased > 0);

    IOV.transfer(_recipient, unreleased);

    beneficiaries[_recipient].amountClaimed = vestedAmount(_recipient);

    emit LogIOVClaimed(_recipient, unreleased);
  }


  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param _recipient The address which is being vested
   */
  function releasableAmount(address _recipient) public view returns (uint256) {
    require( vestedAmount(_recipient) >= beneficiaries[_recipient].amountClaimed );
    require( vestedAmount(_recipient) <= beneficiaries[_recipient].totalAllocated );
    return sub( vestedAmount(_recipient), beneficiaries[_recipient].amountClaimed );
  }

  // /**
  //  * @dev Calculates the amount that has already vested.
  //  * @param _recipient The address which is being vested
  //  */
  // function vestedAmount(address _recipient) public view returns (uint256) {
  //   if( block.timestamp < add(beneficiaries[_recipient].start, beneficiaries[_recipient].cliff) ) {
  //     return 0;
  //   } else if( block.timestamp >= add( beneficiaries[_recipient].start, beneficiaries[_recipient].duration) ) {
  //     return beneficiaries[_recipient].totalAllocated;
  //   } else {
  //     return div( mul(beneficiaries[_recipient].totalAllocated, sub(block.timestamp, beneficiaries[_recipient].start)), beneficiaries[_recipient].duration );
  //   }
  // }

    /**
   * @dev Calculates the amount that has already vested.
   * @param _recipient The address which is being vested
   */
  function vestedAmount(address _recipient) public view returns (uint256) {
    if( block.timestamp < beneficiaries[_recipient].cliff ) {
      return 0;
    }else if( block.timestamp >= add( beneficiaries[_recipient].cliff, (30 days)*beneficiaries[_recipient].periods ) ) {
      return beneficiaries[_recipient].totalAllocated;
    }else {
      for(uint i = 0; i < beneficiaries[_recipient].periods; i++) {
        if( block.timestamp >= add( beneficiaries[_recipient].cliff, (30 days)*i ) && block.timestamp < add( beneficiaries[_recipient].cliff, (30 days)*(i+1) ) ) {
          return div( mul(i, beneficiaries[_recipient].totalAllocated), beneficiaries[_recipient].periods );
        }
      }
    }
  }
}