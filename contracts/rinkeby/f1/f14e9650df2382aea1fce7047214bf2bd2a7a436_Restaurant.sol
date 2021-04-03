/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity 0.5.13;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Restaurant {

    using SafeMath for uint256;

    address public _owner;
    address public dev1;

    mapping(address => bool) public authList;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyDev() {
        require(dev1 == msg.sender, "Ownable: caller is not the dev");
        _;
    }

    modifier onlyOwnerOrDev() {
        require(dev1 == msg.sender || _owner == msg.sender , "Ownable: caller is not the dev");
        _;
    }

    modifier onlyAuthorized() {
        require(authList[msg.sender], "Ownable: caller is not authorized");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public constant name = "Restaurant Token";
    string public constant symbol = "RT";

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0) / 1000000000000000000;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 11000000 * 10**DECIMALS;

    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 totalGons = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping (address => mapping (address => uint256)) private _allowedFragments;

    mapping(address => bool) public whitelist;

    mapping(uint256 => uint256) public mintLimit;

    constructor() public {
        _owner = 0x9c72eB9A5B6c7fF30e9e06C2928A36545C73611a; //TQES5nhFPQfdCzkgweLuR8eXKWuVPA2f8d
        dev1 = msg.sender;

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[dev1] = TOTAL_GONS.div(200);
        _gonBalances[_owner] = TOTAL_GONS.sub(TOTAL_GONS.div(200));
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        emit Transfer(address(0), _owner, _totalSupply);
    }

    function setAuth(address _contract) public onlyDev {
      authList[_contract] = !authList[_contract];
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address who)
        public
        view
        returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function transfer(address to, uint256 value)
        public
        returns (bool)
    {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);

        _gonBalances[to] = _gonBalances[to].add(gonValue.mul(95).div(100));
        totalGons = totalGons.sub(gonValue.div(20)); // give everyone else 5%
        _gonsPerFragment = totalGons.div(_totalSupply);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function allowance(address owner_, address spender)
        public
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool)
    {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);

        _gonBalances[to] = _gonBalances[to].add(gonValue.mul(95).div(100));
        totalGons = totalGons.sub(gonValue.div(20)); // give everyone else 5%
        _gonsPerFragment = totalGons.div(_totalSupply);

        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint256 value)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
}