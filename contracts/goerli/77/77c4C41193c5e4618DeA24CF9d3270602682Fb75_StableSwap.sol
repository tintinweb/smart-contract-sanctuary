pragma solidity 0.6.2;

// for remix.
/*
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0/contracts/utils/EnumerableSet.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0/contracts/token/ERC20/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.2.0/contracts/utils/ReentrancyGuard.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/dda62473e2da448bc9cb8f4514dadda4aeede5f4/contracts/interfaces/IUniswapV2Router02.sol";
*/

// for hardhat.
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Router02.sol";

import "./TokenERC20.sol";

// TODO: add event.
// TODO: migrate.

contract StableSwap is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // stable coin whitelist.
    EnumerableSet.AddressSet private _whitelist;
    // balance of each stable token.
    mapping(address => uint256) public balanceOf;
    // swap path used by feedback.
    address[] public feedbackPath;

    // address of the SS LP token.
    TokenERC20 public lp;
    // address of the SS token.
    TokenERC20 public ss;
    // address of swap router.
    IUniswapV2Router02 public router;

    // swap fee.
    uint256 public fee;
    // locked state.
    bool public locked;

    modifier inWhitelist(address _target) {
        require(
            _whitelist.contains(_target),
            "whitelist doesn't contain token"
        );
        _;
    }

    modifier unlocked() {
        require(!locked, "stable swap has been locked");
        _;
    }

    constructor(address _ss, address _router) public Ownable() {
        require(_ss != address(0), "ss is the zero address");
        require(_router != address(0), "router is the zero address");
        lp = new TokenERC20("Stable Swap LP", "SSLP", 18);
        ss = TokenERC20(_ss);
        router = IUniswapV2Router02(_router);
    }

    // update router.
    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), "router is the zero address");
        router = IUniswapV2Router02(_router);
    }

    // update locked.
    function setLocked(bool _locked) external onlyOwner {
        locked = _locked;
    }

    // update fee.
    function setFee(uint256 _fee) external onlyOwner {
        require(_fee <= 10000, "fee is too large");
        fee = _fee;
    }

    // update path for token.
    function setPath(address[] calldata _path) external onlyOwner {
        require(
            _path.length >= 2 &&
                _whitelist.contains(_path[0]) &&
                _path[_path.length - 1] == address(ss),
            "invalid token path"
        );
        feedbackPath = _path;
    }

    function getPathLength() external view returns (uint256) {
        return feedbackPath.length;
    }

    // operate whitelist.
    function addWhitelist(address _token) external onlyOwner returns (bool) {
        require(_token != address(0), "token is the zero address");
        require(ERC20(_token).decimals() <= 18, "invalid token decimals");
        ERC20(_token).safeApprove(address(router), uint256(-1));
        return _whitelist.add(_token);
    }

    function getWhitelistLength() external view returns (uint256) {
        return _whitelist.length();
    }

    function isWhitelist(address _token) external view returns (bool) {
        return _whitelist.contains(_token);
    }

    function getWhitelist(uint256 _index) external view returns (address) {
        require(_index <= _whitelist.length() - 1, "index out of bounds");
        return _whitelist.at(_index);
    }

    // core logic.
    function _getLiquidityAmount(address _target, uint256 _amount)
        private
        view
        returns (uint256 liquidity)
    {
        liquidity = _amount;
        uint8 decimals = ERC20(_target).decimals();
        if (decimals < 18) {
            liquidity = liquidity.mul(10**uint256(18 - decimals));
        }
    }

    function _getTokenAmount(address _target, uint256 _liquidity)
        private
        view
        returns (uint256 amount)
    {
        amount = _liquidity;
        uint8 decimals = ERC20(_target).decimals();
        if (decimals < 18) {
            amount = amount.div(10**uint256(18 - decimals));
        }
    }

    function deposit(
        address _target,
        uint256 _amount,
        address _to
    ) external unlocked nonReentrant inWhitelist(_target) {
        ERC20(_target).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 liquidity = _getLiquidityAmount(_target, _amount);
        balanceOf[_target] = balanceOf[_target].add(liquidity);
        lp.mint(_to, liquidity);
    }

    function withdraw(uint256 _liquidity, address _to) external nonReentrant {
        require(lp.balanceOf(msg.sender) >= _liquidity, "insufficient balance");
        uint256 length = _whitelist.length();
        uint256 totalSupply = lp.totalSupply();
        for (uint256 i = 0; i < length; i++) {
            address target = _whitelist.at(i);
            uint256 targetBalance = balanceOf[target];
            uint256 targetLiquidity =
                _liquidity.mul(targetBalance).div(totalSupply);
            if (targetLiquidity > 0) {
                ERC20(target).safeTransfer(
                    _to,
                    _getTokenAmount(target, targetLiquidity)
                );
                balanceOf[target] = targetBalance.sub(targetLiquidity);
            }
        }
        lp.burnFrom(msg.sender, _liquidity);
    }

    function skim(address _to) external nonReentrant {
        // skim each stable token.
        uint256 length = _whitelist.length();
        for (uint256 i = 0; i < length; i++) {
            address target = _whitelist.at(i);
            uint256 amount =
                ERC20(target).balanceOf(address(this)).sub(
                    _getTokenAmount(target, balanceOf[target])
                );
            if (amount > 0) {
                ERC20(target).safeTransfer(_to, amount);
            }
        }
        // skim ss.
        ss.transfer(_to, ss.balanceOf(address(this)));
    }

    function getSwapResult(
        address _source,
        address _target,
        uint256 _amount,
        bool _calcFee
    )
        external
        view
        inWhitelist(_source)
        inWhitelist(_target)
        returns (
            uint256 liquidity,
            uint256 amount,
            uint256 amountFee,
            uint256 amountOut
        )
    {
        (liquidity, amount, amountFee, amountOut) = _getSwapResult(
            _source,
            _target,
            _amount,
            _calcFee
        );
    }

    function _getSwapResult(
        address _source,
        address _target,
        uint256 _amount,
        bool _calcFee
    )
        private
        view
        returns (
            uint256 liquidity,
            uint256 amount,
            uint256 amountFee,
            uint256 amountOut
        )
    {
        require(_source != _target, "identical token address");
        liquidity = _getLiquidityAmount(_source, _amount);
        amount = _getTokenAmount(_target, liquidity);
        amountFee = _calcFee ? amount.mul(fee).div(10000) : 0;
        amountOut = amount.sub(amountFee);
    }

    function _swap(
        address _source,
        address _target,
        uint256 _amount,
        address _to
    )
        private
        returns (
            uint256 liquidity,
            uint256 amount,
            uint256 amountFee,
            uint256 amountOut
        )
    {
        bool internalCall = _to == address(this);
        (liquidity, amount, amountFee, amountOut) = _getSwapResult(
            _source,
            _target,
            _amount,
            !internalCall
        );
        uint256 targetBalance = balanceOf[_target];
        require(
            targetBalance >= liquidity &&
                ERC20(_target).balanceOf(address(this)) >= amount,
            "insufficient target balance"
        );
        if (internalCall) {
            require(
                ERC20(_source).balanceOf(address(this)) >= _amount,
                "insufficient source balance"
            );
        } else {
            ERC20(_source).safeTransferFrom(msg.sender, address(this), _amount);
            ERC20(_target).safeTransfer(_to, amountOut);
        }
        balanceOf[_source] = balanceOf[_source].add(liquidity);
        balanceOf[_target] = targetBalance.sub(liquidity);
    }

    function swap(
        address _source,
        address _target,
        uint256 _amount,
        address _to
    ) external unlocked nonReentrant inWhitelist(_source) inWhitelist(_target) {
        require(_to != address(this), "invalid address");
        uint256 amountFee;
        (, , amountFee, ) = _swap(_source, _target, _amount, _to);
        if (amountFee > 0) {
            address[] memory path = feedbackPath;
            require(path.length >= 2, "invalid path");
            address tokenFeedback = path[0];
            uint256 amountFeedback = amountFee;
            if (_target != tokenFeedback) {
                (, , , amountFeedback) = _swap(
                    _target,
                    tokenFeedback,
                    amountFee,
                    address(this)
                );
            }

            if (amountFeedback > 0) {
                uint256[] memory amounts =
                    router.swapExactTokensForTokens(
                        amountFeedback,
                        0,
                        path,
                        address(this),
                        block.timestamp
                    );
                require(
                    path.length == amounts.length &&
                        amounts[0] == amountFeedback,
                    "swap failed, unequal length or feedback amount"
                );
                uint256 amountSS = amounts[amounts.length - 1];
                if (amountSS > 0) {
                    ss.burn(amounts[amounts.length - 1]);
                }
            }
        }
    }
}