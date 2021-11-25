/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// This contract simply calls multiple targets sequentially, ensuring WETH balance before and after

contract FlashBotsMultiCall {
    address private immutable owner;
    address private executor;
    IWETH private constant WETH =
        IWETH(0xc778417E063141139Fce010982780140Aa0cD5Ab);

    modifier onlyExecutor() {
        require(msg.sender == executor, "not executor");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(address _executor) public payable {
        owner = msg.sender;
        executor = _executor;
        if (msg.value > 0) {
            WETH.deposit{value: msg.value}();
        }
    }

    function changeExecutor(address _excutor) external onlyOwner {
        executor = _excutor;
    }

    function withdraw() external onlyOwner {
        WETH.transfer(msg.sender, WETH.balanceOf(address(this)));
        msg.sender.transfer(address(this).balance);
    }

    function balanceOf() external view returns (uint256) {
        return WETH.balanceOf(address(this));
    }

    receive() external payable {}

    function uniswapWeth(
        uint256 _wethAmountToFirstMarket,
        uint256 _ethAmountToCoinbase,
        address[] memory _targets,
        bytes[] memory _payloads
    ) external payable onlyExecutor {
        require(_targets.length == _payloads.length, "Invalid lengths...");
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        require(
            _wethBalanceBefore > _wethAmountToFirstMarket,
            "Balance smaller than amount to send to first market"
        );
        WETH.transfer(_targets[0], _wethAmountToFirstMarket);
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = _targets[i].call(
                _payloads[i]
            );
            require(_success, "no success on call");
            _response;
        }

        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(
            _wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase,
            "balance after smaller than balanceBefore"
        );
        if (_ethAmountToCoinbase == 0) return;

        uint256 _ethBalance = address(this).balance;
        if (_ethBalance < _ethAmountToCoinbase) {
            WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
        }
        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function call(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable onlyOwner returns (bytes memory) {
        require(_to != address(0), "invalid address");
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success, "no success 2");
        return _result;
    }

   
}