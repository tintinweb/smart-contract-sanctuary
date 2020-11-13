pragma solidity ^0.5.16;

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
    bool private _paused;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Paused(address account);
    event Unpaused(address account);

    constructor() internal {
        _paused = false;
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    modifier whenPaused() {
        require(_paused);
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenTimelock is Ownable {
    using SafeMath for uint256;

    ERC20 private _token;

    address private _beneficiary;

    uint256 private _requestTime;

    uint256 private _releaseDelay;

    bool private _releaseRequested;

    event ReleaseRequested(address account);

    constructor(
        address token,
        address beneficiary,
        uint256 releaseTime,
        uint256 releaseDelay
    ) public {
        require(releaseTime > block.timestamp);
        require(releaseDelay >= 864000 && releaseDelay <= 3888000); // Min = 10 days, Max = 45 days
        require(beneficiary != address(0));
        _token = ERC20(token);
        _beneficiary = beneficiary;
        _requestTime = releaseTime - releaseDelay;
        _releaseDelay = releaseDelay;
        _releaseRequested = false;
    }

    function token() public view returns (ERC20) {
        return _token;
    }

    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    function releaseTime() public view returns (uint256) {
        return _requestTime + _releaseDelay;
    }

    function releaseDelay() public view returns (uint256) {
        return _releaseDelay;
    }

    function releaseRequested() public view returns (bool) {
        return _releaseRequested;
    }

    function tokenBalance() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    function release() public whenNotPaused {
        require(block.timestamp >= _requestTime);

        if (!_releaseRequested) {
            _releaseRequested = true;
            emit ReleaseRequested(msg.sender);
        } else {
            require(block.timestamp >= (_requestTime + _releaseDelay));

            uint256 amount = _token.balanceOf(address(this));
            require(amount > 0);
            _token.transfer(_beneficiary, amount);
        }
    }
}