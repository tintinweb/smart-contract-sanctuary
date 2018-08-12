pragma solidity 0.4.24;

contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Exchange {
    function fillOrder(address[5], uint[6], uint, bool, uint8, bytes32, bytes32) public returns (uint);
}

contract WETH9 {
    function deposit() public payable;
    function withdraw(uint) public;
    function approve(address, uint) public returns (bool);
}

contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint256) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint256) {
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint256) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract HydroSwap is SafeMath {

    Exchange exchange;
    address tokenProxy;
    WETH9 etherToken;

    uint256 constant MAX_UINT = 2 ** 256 - 1;

    event LogSwapSuccess(bytes32 indexed id);

    constructor(
        Exchange _exchange,
        address _tokenProxy,
        WETH9 _etherToken)
        public
    {
        exchange = _exchange;
        tokenProxy = _tokenProxy;
        etherToken = _etherToken;
    }

    function initialize()
        external
    {
        etherToken.approve(tokenProxy, MAX_UINT);
    }

    function fillOrder(
        bytes32 id,
        address[5] orderAddresses,
        uint[6] orderValues,
        uint8 v,
        bytes32 r,
        bytes32 s)
        external
        payable
        returns (uint256 takerTokenFilledAmount)
    {
        etherToken.deposit.value(msg.value)();
        require(
            Exchange(exchange).fillOrder(
                orderAddresses,
                orderValues,
                msg.value,
                true,
                v,
                r,
                s
            ) == msg.value,
            "FILL_ORDER_ERROR"
        );

        // makerTokenAmount * takerTokenFillAmount / takerTokenAmount
        uint256 makerTokenFilledAmount = getPartialAmount(orderValues[0], orderValues[1], msg.value);

        transferToken(orderAddresses[2], msg.sender, makerTokenFilledAmount);

        emit LogSwapSuccess(id);
        return msg.value;
    }

    function getPartialAmount(uint256 numerator, uint256 denominator, uint256 target)
        internal
        pure
        returns (uint256)
    {
        return safeDiv(safeMul(numerator, target), denominator);
    }

    function transferToken(address token, address account, uint amount)
        internal
    {
        require(ERC20(token).transfer(account, amount), "TOKEN_TRANSFER_ERROR");
    }
}