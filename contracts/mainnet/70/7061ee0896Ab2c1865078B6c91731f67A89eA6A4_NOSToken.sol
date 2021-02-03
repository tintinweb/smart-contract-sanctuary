// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract NOSToken is IERC20, Ownable {
    using SafeMath for uint;

    struct FeeConfig {
        uint16 fee; //percentage expressed as number between 0 and 1000
        address destination;
    }

    FeeConfig config;
    uint256 _totalSupply;

    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;

    address public tokenUniswapPair;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    string public name = "NOS nitrous.finance";
    string public symbol = "NOS";

    constructor(uint16 fee, address destination, address _router, address _factory) {
        _totalSupply = 964910 * 1e18;
        balances[msg.sender] = _totalSupply;
        config.fee = fee;
        config.destination = destination;
        router = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(_factory);
    }

    function fee() external view returns (uint16) {
        return config.fee;
    }

    function decimals() external view returns (uint8) {
        return 18;
    }

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        override
        view
        returns (uint256)
    {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        override
        view
        returns (uint256)
    {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function createUniswapPair() public onlyOwner returns (address) {
        require(tokenUniswapPair == address(0), "Token: pool already created");
        tokenUniswapPair = factory.createPair(
            address(router.WETH()),
            address(this)
        );
        return tokenUniswapPair;
    }

    function configureFeeDestination(address destination) public onlyOwner {
        config.destination = destination;
    }

    /*
        1% = 10
        10% = 100
    */
    function configureFee(uint16 _fee) public onlyOwner {
        require(config.fee == 0, "NOS: fee already set");
        require(_fee <= 1000, "NOS: max fee reached");
        config.fee = _fee;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        uint fee;

        if (config.destination != address(0)) {
            fee = (config.fee * amount).div(1000);
            balances[config.destination] = balances[config.destination] + fee;

            if (fee != 0) {
                emit Transfer(sender, config.destination, fee);
            }
        }

        balances[recipient] = balances[recipient].add(amount - fee);
        balances[sender] = balances[sender].sub(amount);
        emit Transfer(sender, recipient, amount);
    }
}