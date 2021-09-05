/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

// File @openzeppelin/contracts/token/ERC20/[email protected]

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) return a;
        return b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) return a;
        return b;
    }
}

abstract contract OrderManager {

    function createOrder(address _tokenContract, address _sender, uint256 _price, uint256 _token, uint256 _usdt, uint8 _type) public virtual returns (uint256 _orderId);

    function insertOrder(address _tokenContract, uint256 _orderId, address _sender) public virtual returns (bool _flag);

    function removeOrder(address _tokenContract, uint256 _orderId, address _sender) public virtual returns (bool _flag);

    function handleMatchOrder(address _tokenContract, uint256 _orderId) public virtual;
}

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract TDEX {

    struct Token {
        string symbol;
        string name;
        address tokenContract;
        uint decimals;
    }

    Token USDT = Token({
        symbol:"USDT",
        name:"USD Tether",
        tokenContract:0xa8557Ea8D2A59dE104B4aE5274F05A1a3ee862D3,
        decimals:6
    });

    Token ETH = Token({
        symbol:"HT",
        name:"HT",
        tokenContract:0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
        decimals:18
    });

    struct TokenMap
    {
        mapping(address => Token) data;
        address[] keys;
        uint size;
    }

    address addressZero = 0x0000000000000000000000000000000000000000;

    // 交易对
    TokenMap tokenMap;

    OrderManager orderManager;

    constructor(OrderManager _orderManager) {
        orderManager = _orderManager;
    }

    function insertToken(address _tokenContract) public returns (bool replaced)
    {
        // 假装拿到了token
        string memory _symbol = "TT";
        string memory _name = "TokenEco Token";
        uint _decimals = 4;

        if (tokenMap.data[_tokenContract].decimals > 0)
            return false;
        else
        {
            tokenMap.data[_tokenContract] = Token({
                name: _name,
                symbol:_symbol,
                tokenContract:_tokenContract,
                decimals:_decimals

            });

            tokenMap.size++;
            {
                bool added = false;
                for (uint i=0; i<tokenMap.keys.length;i++)
                {
                    if (tokenMap.keys[i] == addressZero)
                    {
                        tokenMap.keys[i] = _tokenContract;
                        added = true;
                    }
                }
                if (added == false)
                {
                    tokenMap.keys.push(_tokenContract);
                }
            }

            return true;
        }
     }

    function removeToken(address _tokenContract) public returns (bool replaced)
    {

        if (tokenMap.data[_tokenContract].decimals == 0)
            return false;
        else
        {
            delete tokenMap.data[_tokenContract];
            tokenMap.size--;

            for (uint i=0; i<tokenMap.keys.length; i++)
            {
                if (tokenMap.keys[i] == _tokenContract)
                {
                    tokenMap.keys[i] = addressZero;
                }
            }

            return true;
        }
     }

    function getToken(address _tokenContract) public view returns (string memory symbol, string memory name, address tokenContract, uint decimals)
    {
        Token memory token = tokenMap.data[_tokenContract];

        symbol = token.symbol;
        name = token.name;
        tokenContract = token.tokenContract;
        decimals = token.decimals;
    }

    /**********************************************************/

    function sendBuyOrder(address _tokenContract, uint256 _price, uint256 _usdt_amount) public
    {
        Token memory token = tokenMap.data[_tokenContract];
        require(token.decimals > 0, "This contract address is not supported");

        require(_usdt_amount <= 100000 * 10 ** USDT.decimals, "Maximum single transaction amount 100000 USDT");
        require(_price*_usdt_amount > 0, "Error");

        uint256 orderId = orderManager.createOrder(_tokenContract, msg.sender, _price, 0, _usdt_amount, 0);
        if (orderId > 0)
        {
            IERC20(USDT.tokenContract).transferFrom(
                msg.sender,
                address(this),
                _usdt_amount
            );
            orderManager.handleMatchOrder(_tokenContract, orderId);
            orderManager.insertOrder(_tokenContract, orderId, msg.sender);
        }
    }

    function sendSellOrder(address _tokenContract, uint256 _price, uint256 _token_amount) public
    {
        Token memory token = tokenMap.data[_tokenContract];
        require(token.decimals > 0, "This contract address is not supported");

        uint256 _usdt_amount = _token_amount * _price;
        require(_usdt_amount <= 100000 * 10 ** USDT.decimals, "Maximum single transaction amount 100000 USDT");
        require(_price*_usdt_amount > 0, "Error");

        uint256 orderId = orderManager.createOrder(_tokenContract, msg.sender, _price, _token_amount, 0, 1);
        if (orderId > 0)
        {
            IERC20(_tokenContract).transferFrom(
                msg.sender,
                address(this),
                _token_amount
            );
            orderManager.handleMatchOrder(_tokenContract, orderId);
            orderManager.insertOrder(_tokenContract, orderId, msg.sender);
        }
    }


    /**********************************************************/
}