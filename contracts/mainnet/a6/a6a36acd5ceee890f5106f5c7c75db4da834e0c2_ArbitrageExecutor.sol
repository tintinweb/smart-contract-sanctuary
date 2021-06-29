/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

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

contract ArbitrageExecutor {
    address payable public immutable owner;
    address private immutable executor;
    IWETH private constant WETH =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    modifier onlyExecutor() {
        require(msg.sender == executor, "OE");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "OO");
        _;
    }

    receive() external payable {}

    constructor(address _executor) payable {
        owner = payable(msg.sender);
        executor = _executor;
        if (msg.value > 0) WETH.deposit{value: msg.value}();
    }

    function arbWeth(
        uint256 _wethAmountToFirstMarket,
        uint256 _ethAmountToCoinbase,
        address[] memory _targets,
        bytes[] memory _payloads
    ) external payable onlyExecutor {
        require(_targets.length == _payloads.length);
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        WETH.transfer(_targets[0], _wethAmountToFirstMarket);
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = _targets[i].call(
                _payloads[i]
            );
            require(_success);
            _response;
        }

        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(_wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase);
        if (_ethAmountToCoinbase == 0) return;

        uint256 _ethBalance = address(this).balance;
        if (_ethBalance < _ethAmountToCoinbase)
            WETH.withdraw(_ethAmountToCoinbase - _ethBalance);

        (bool success, ) = block.coinbase.call{value: _ethAmountToCoinbase}(
            new bytes(0)
        );
        require(success, "CB");
    }

    function call(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable onlyOwner returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }

    function withdraw(uint256 value) external onlyOwner {
        if (value > address(this).balance) WETH.withdraw(value);

        require(address(this).balance >= value, "NEE");
        (bool success, ) = owner.call{value: value}("");
        require(success, "WF");
    }
}