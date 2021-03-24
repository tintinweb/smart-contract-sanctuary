// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./UniswapInterface.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract UniswapBought is Ownable {
    // list of authorized address
    mapping(address => bool) authorized;

    // using this to add address who can call the contract
    function addAuthorized(address _a) public onlyOwner {
        authorized[_a] = true;
    }

    // using this to add address who can call the contract
    function deleteAuthorized(address _a) public onlyOwner {
        authorized[_a] = false;
    }

    function isAuthorized(address _a) public view onlyOwner returns (bool) {
        if (owner() == _a) {
            return true;
        } else {
            return authorized[_a];
        }
    }

    modifier onlyAuth() {
        require(isAuthorized(msg.sender));
        _;
    }

    // =========================================================================================
    // Settings uniswap
    // =========================================================================================

    address public constant UNIROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public WETHAddress = UniswapExchangeInterface(UNIROUTER).WETH();
    UniswapExchangeInterface uniswap = UniswapExchangeInterface(UNIROUTER);

    // =========================================================================================
    // Buy and Sell Functions
    // =========================================================================================

    // using this to buy token , first arg is eth value (1 eth = 1*1E18), arg2 is token address
    function buyToken(
        uint256 _value,
        address _token,
        uint256 _mintoken,
        uint256 _blockDeadLine
    ) public onlyAuth returns (uint256) {
        uint256 deadline = block.timestamp + _blockDeadLine; // deadline during 15 blocks
        address[] memory path = new address[](2);
        path[0] = WETHAddress;
        path[1] = _token;
        uint256[] memory amount =
            uniswap.swapExactETHForTokens{value: _value}(
                _mintoken,
                path,
                address(this),
                deadline
            );
        return amount[1];
    }

    // using this to allow uniswap to sell tokens of contract
    function allowUniswapForToken(address _token) public onlyOwner {
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).approve(UNIROUTER, _balance);
    }

    // using this to sell token , first arg is eth value (1 eth = 1*1E18), arg2 is token address
    function sellToken(
        uint256 _amountToSell,
        uint256 _amountOutMin,
        address _token,
        uint256 _blockDeadLine
    ) public onlyAuth returns (uint256) {
        uint256 deadline = block.timestamp + _blockDeadLine; // deadline during 15 blocks
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETHAddress;
        uint256[] memory amount =
            uniswap.swapExactTokensForETH(
                _amountToSell,
                _amountOutMin,
                path,
                address(this),
                deadline
            );
        return amount[1];
    }

    // =========================================================================================
    // Desposit and withdraw functions
    // =========================================================================================

    // using this to send Eth to contract
    fallback() external payable {}

    receive() external payable {}

    // Using this to withdraw eth balance of contract => send to msg.sender
    function withdrawEth() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    // using this to withdraw all tokens in the contract => send to msg.sender
    function withdrawToken(address _token) public onlyOwner() {
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, _balance);
    }
}