// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2020 zapper, nodar, suhail, seb, sumit, apoorv

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract moves liquidity between UniswapV2 and Balancer pools.

pragma solidity ^0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

contract ReentrancyGuard {
    bool private _notEntered;

    constructor() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function decimals() external view returns (uint256);

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

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    // force balances to match reserves
    function skim(address to) external;
}

interface IUniswapV2ZapIn {
    function ZapIn(
        address _toWhomToIssue,
        address _FromTokenContractAddress,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 _amount,
        uint256 _minPoolTokens
    ) external payable returns (uint256);
}

interface IUniswapV2ZapOut {
    function ZapOut(
        address _ToTokenContractAddress,
        address _FromUniPoolAddress,
        uint256 _IncomingLP,
        uint256 _minTokensRec
    ) external payable returns (uint256);
}

interface IBalancerZapIn {
    function EasyZapIn(
        address _FromTokenContractAddress,
        address _ToBalancerPoolAddress,
        uint256 _amount,
        uint256 _minPoolTokens
    ) external payable returns (uint256 tokensBought);
}

interface IBalancerZapOut {
    function EasyZapOut(
        address _ToTokenContractAddress,
        address _FromBalancerPoolAddress,
        uint256 _IncomingBPT,
        uint256 _minTokensRec
    ) external payable returns (uint256);
}

interface IBPool {
    function isBound(address t) external view returns (bool);
}

contract Balancer_UniswapV2_Pipe_V1_3 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    bool public stopped = false;

    IUniswapV2Factory
        private constant UniSwapV2FactoryAddress = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );

    IBalancerZapOut public balancerZapOut;
    IUniswapV2ZapIn public uniswapV2ZapIn;
    IBalancerZapIn public balancerZapIn;
    IUniswapV2ZapOut public uniswapV2ZapOut;

    constructor(
        address _balancerZapIn,
        address _balancerZapOut,
        address _uniswapV2ZapIn,
        address _uniswapV2ZapOut
    ) public {
        balancerZapIn = IBalancerZapIn(_balancerZapIn);
        balancerZapOut = IBalancerZapOut(_balancerZapOut);
        uniswapV2ZapIn = IUniswapV2ZapIn(_uniswapV2ZapIn);
        uniswapV2ZapOut = IUniswapV2ZapOut(_uniswapV2ZapOut);
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    function PipeBalancerUniV2(
        address _FromBalancerPoolAddress,
        uint256 _IncomingBPT,
        address _toUniswapPoolAddress,
        address _toWhomToIssue,
        uint256 _minUniV2Tokens
    ) public nonReentrant stopInEmergency returns (uint256) {
        // Get BPT
        IERC20(_FromBalancerPoolAddress).transferFrom(
            msg.sender,
            address(this),
            _IncomingBPT
        );
        // Approve BalUnZap
        IERC20(_FromBalancerPoolAddress).approve(
            address(balancerZapOut),
            _IncomingBPT
        );

        // Get pair addresses from UniV2Pair
        address token0 = IUniswapV2Pair(_toUniswapPoolAddress).token0();
        address token1 = IUniswapV2Pair(_toUniswapPoolAddress).token1();

        address zapOutToToken = address(0);
        if (IBPool(_FromBalancerPoolAddress).isBound(token0)) {
            zapOutToToken = token0;
        } else if (IBPool(_FromBalancerPoolAddress).isBound(token1)) {
            zapOutToToken = token1;
        }

        // ZapOut from Balancer
        uint256 zappedOutAmt = balancerZapOut.EasyZapOut(
            zapOutToToken,
            _FromBalancerPoolAddress,
            _IncomingBPT,
            0
        );

        uint256 LPTBought;
        if (zapOutToToken == address(0)) {
            // use ETH to ZapIn to UNIV2
            LPTBought = uniswapV2ZapIn.ZapIn.value(zappedOutAmt)(
                _toWhomToIssue,
                address(0),
                token0,
                token1,
                0,
                _minUniV2Tokens
            );
        } else {
            IERC20(zapOutToToken).approve(
                address(uniswapV2ZapIn),
                IERC20(zapOutToToken).balanceOf(address(this))
            );
            LPTBought = uniswapV2ZapIn.ZapIn.value(0)(
                _toWhomToIssue,
                zapOutToToken,
                token0,
                token1,
                zappedOutAmt,
                _minUniV2Tokens
            );
        }

        return LPTBought;
    }

    function PipeUniV2Balancer(
        address _FromUniswapPoolAddress,
        uint256 _IncomingLPT,
        address _ToBalancerPoolAddress,
        address _toWhomToIssue,
        uint256 _minBPTokens
    ) public nonReentrant stopInEmergency returns (uint256) {
        // Get LPT
        IERC20(_FromUniswapPoolAddress).transferFrom(
            msg.sender,
            address(this),
            _IncomingLPT
        );

        // Approve UniUnZap
        IERC20(_FromUniswapPoolAddress).approve(
            address(uniswapV2ZapOut),
            _IncomingLPT
        );

        // Get pair addresses from UniV2Pair
        address token0 = IUniswapV2Pair(_FromUniswapPoolAddress).token0();
        address token1 = IUniswapV2Pair(_FromUniswapPoolAddress).token1();

        address zapOutToToken = address(0);
        if (IBPool(_ToBalancerPoolAddress).isBound(token0)) {
            zapOutToToken = token0;
        } else if (IBPool(_ToBalancerPoolAddress).isBound(token1)) {
            zapOutToToken = token1;
        }

        // ZapOut from Uni
        uint256 tokensRec = uniswapV2ZapOut.ZapOut(
            zapOutToToken,
            _FromUniswapPoolAddress,
            _IncomingLPT,
            0
        );

        // ZapIn to Balancer
        uint256 BPTBought;
        if (zapOutToToken == address(0)) {
            // use ETH to ZapIn to Balancer
            BPTBought = balancerZapIn.EasyZapIn.value(tokensRec)(
                address(0),
                _ToBalancerPoolAddress,
                0,
                _minBPTokens
            );
        } else {
            IERC20(zapOutToToken).approve(address(balancerZapIn), tokensRec);
            BPTBought = balancerZapIn.EasyZapIn.value(0)(
                zapOutToToken,
                _ToBalancerPoolAddress,
                tokensRec,
                _minBPTokens
            );
        }

        IERC20(_ToBalancerPoolAddress).transfer(_toWhomToIssue, BPTBought);

        return BPTBought;
    }

    // Zap Contract Setters
    function setbalancerZapIn(address _balancerZapIn) public onlyOwner {
        balancerZapIn = IBalancerZapIn(_balancerZapIn);
    }

    function setBalancerZapOut(address _balancerZapOut) public onlyOwner {
        balancerZapOut = IBalancerZapOut(_balancerZapOut);
    }

    function setUniswapV2ZapIn(address _uniswapV2ZapIn) public onlyOwner {
        uniswapV2ZapIn = IUniswapV2ZapIn(_uniswapV2ZapIn);
    }

    function setUniswapV2ZapOut(address _uniswapV2ZapOut) public onlyOwner {
        uniswapV2ZapOut = IUniswapV2ZapOut(_uniswapV2ZapOut);
    }

    // fallback to receive ETH
    function() external payable {}

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner(), qty);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        address payable _to = owner().toPayable();
        _to.transfer(contractBalance);
    }
}