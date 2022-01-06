/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// File: Users/chenfei/tool/bridge/tec/width_tool/timelineunlockcontract/contracts/test/TToken.sol


pragma solidity 0.6.12;

// Test Token
// Public mint and burn functions!

contract TToken {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 internal _totalSupply;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowance;

    event Approval(address indexed src, address indexed dst, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    // Math
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a);
    }

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function _move(
        address src,
        address dst,
        uint256 amt
    ) internal {
        require(_balance[src] >= amt, "3ERR_INSUFFICIENT_BAL");
        _balance[src] = sub(_balance[src], amt);
        _balance[dst] = add(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint256 amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint256 amt) internal {
        _move(from, address(this), amt);
    }

    function _mint(address dst, uint256 amt) internal {
        _balance[dst] = add(_balance[dst], amt);
        _totalSupply = add(_totalSupply, amt);
        emit Transfer(address(0), dst, amt);
    }

    function allowance(address src, address dst)
        external
        view
        returns (uint256)
    {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view returns (uint256) {
        return _balance[whom];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function approve(address dst, uint256 amt) external returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function mint(address dst, uint256 amt) public returns (bool) {
        _mint(dst, amt);
        return true;
    }

    function burn(uint256 amt) public returns (bool) {
        require(_balance[address(this)] >= amt, "4ERR_INSUFFICIENT_BAL");
        _balance[address(this)] = sub(_balance[address(this)], amt);
        _totalSupply = sub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
        return true;
    }

    function transfer(address dst, uint256 amt) external returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool) {
        require(
            msg.sender == src || amt <= _allowance[src][msg.sender],
            "ERR_BTOKEN_BAD_CALLER"
        );
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint256(-1)) {
            _allowance[src][msg.sender] = sub(_allowance[src][msg.sender], amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
}