pragma solidity  ^0.4.21;


contract DSMath {
    uint constant DENOMINATOR = 10000;
    uint constant DECIMALS = 18;
    uint constant WAD = 10**DECIMALS;

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
	
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
	
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
}


contract Token is DSMath {
    string  public symbol;
    uint256 public decimals;
    string  public name;
    address public owner;

    uint256 internal _supply;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) private _approvals;

    event LogSetOwner(address indexed owner_);
    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner_, address indexed spender, uint value);

    modifier auth {
        require(isAuthorized(msg.sender));
        _;
    }

    function Token() internal {
        owner = msg.sender;
    }

    function totalSupply() public constant returns (uint256) {
        return _supply;
    }

    function balanceOf(address src) public constant returns (uint256) {
        return _balances[src];
    }

    function allowance(address src, address guy) public constant returns (uint256) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) public returns (bool) {
        require(_balances[msg.sender] >= wad);

        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(msg.sender, dst, wad);

        return true;
    }

    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        require(_balances[src] >= wad);
        require(_approvals[src][msg.sender] >= wad);

        _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function mint(uint wad)
    public
    auth
    {
        _balances[msg.sender] = add(_balances[msg.sender], wad);
        _supply = add(_supply, wad);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function isAuthorized(address src) internal constant returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else {
            return false;
        }
    }
}


// Universal Token
contract UniversalToken is Token {
    uint public xactionFeeNumerator;
    uint public xactionFeeShare;

    function UniversalToken( 
        uint initialSupply,
        uint feeMult,
        uint feeShare ) public
        condition(initialSupply > 1000)
        condition(feeMult > 0)
    {
        symbol = "PMT";
        name = "Universal Evangelist Token - by Pure Money Tech";
        decimals = DECIMALS;
		_supply = mul(initialSupply, WAD);
		owner = msg.sender;
        xactionFeeNumerator = feeMult;
        xactionFeeShare = feeShare;
		_balances[owner] = _supply;
    }

    function modifyTransFee(uint _xactionFeeMult) public
        auth
        condition(_xactionFeeMult >= 0)
        condition(DENOMINATOR > 4 * _xactionFeeMult)
    {
        xactionFeeNumerator = _xactionFeeMult;
    }

    function modifyFeeShare(uint _share) public
        auth
        condition(_share >= 0)
        condition(DENOMINATOR > 3 * _share)
    {
        xactionFeeShare = _share;
    }
}