/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

pragma solidity ^0.4.24;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
    function safeAdd(uint256 a, uint256 b) external pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) external pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) external pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) external pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract Lock is ReentrancyGuard {
    using SafeMath for uint256;
    struct LockInfo {
        uint256 startedDate;
        uint256 endDate;
        uint256 amount;
        address tokenAddress;
        address managerAddress;
    }

    uint256 public poolCount = 0;
    LockInfo public pool;

    modifier onlyManager() {
        require(msg.sender == pool.managerAddress);
        _;
    }

    function lockTokens(
        uint256 _endDate,
        uint256 _amount,
        address _tokenAddress
    ) external nonReentrant {
        require(now < _endDate, "endDate should be bigger than now");
        require(_amount != 0, "amount cannot 0");
        require(
            _tokenAddress != address(0),
            "Token adress cannot be address(0)"
        );
        require(
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Transaction failed"
        );
        require(poolCount == 0, "Pool count must be 0");
        pool = LockInfo(now, _endDate, _amount, _tokenAddress, msg.sender);
        poolCount = poolCount.safeAdd(1);
    }

    function getPoolData()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            address
        )
    {
        return (
            pool.startedDate,
            pool.endDate,
            pool.amount,
            pool.tokenAddress,
            pool.managerAddress
        );
    }

    function getTokens() external onlyManager nonReentrant {
        require(now > pool.endDate);
        IERC20(pool.tokenAddress).transfer(msg.sender, pool.amount);
    }
}