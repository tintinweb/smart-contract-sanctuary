pragma solidity ^0.4.23;

library SafeMath {
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);
        uint256 c = _a / _b;

        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenBurner {
    function kill() public {
        selfdestruct(address(this));
    }
}

contract BurnManager is Ownable {
    using SafeMath for uint256;

    ERC20 private _token;

    uint256 private _totalBurned;

    address[] private _burners;

    event Burn(address indexed from, address indexed to, uint256 amount);

    constructor(address token) public {
        _token = ERC20(token);
    }

    function token() public view returns (ERC20) {
        return _token;
    }

    function burners() public view returns (address[] memory) {
        return _burners;
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned;
    }

    function burn() external {
        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0);

        // No one in control of this new smart-contract
        TokenBurner burner = new TokenBurner();
        // Transferring the tokens from this contract to new TokenBurner smart-contract
        if (_token.transfer(address(burner), amount)) {
            // Killing the new TokenBurner smart-contract
            burner.kill();
            _burners.push(address(burner));
            _totalBurned = _totalBurned.add(amount);
            emit Burn(address(this), address(burner), amount);
        }
    }
}