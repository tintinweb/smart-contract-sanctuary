//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

// This contract simply calls multiple targets sequentially, ensuring WETH balance before and after

contract BundleExecutor {
    address private immutable owner; //will be chrome #0
    address private immutable executor; //will be chrome #0
    IWETH private constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    modifier onlyExecutor() {
        require(msg.sender == executor);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _executor) public payable {
        owner = msg.sender;
        executor = _executor;
        if (msg.value > 0) {
            WETH.deposit{value: msg.value}();
        }
    }

    receive() external payable {
    }

    function uniswapWeth(uint256 _wethAmountToFirstMarket, uint256 _ethAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) external onlyExecutor payable {
        require (_targets.length == _payloads.length);
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this)); //eth on the SC (before arb)
        WETH.transfer(_targets[0], _wethAmountToFirstMarket); //send eth directly to the pair SC
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = _targets[i].call(_payloads[i]); //transfer all pairs
            require(_success); _response;
        }

        uint256 _wethBalanceAfter = WETH.balanceOf(address(this)); //check eth on the SC (after arb)
        require(_wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase); //check arb is profitable
        if (_ethAmountToCoinbase == 0) return; //ensure we planned to pay the miner bribe

        uint256 _ethBalance = address(this).balance; //TODO: what is the diff with _wethBalanceAfter
        if (_ethBalance < _ethAmountToCoinbase) {
            WETH.withdraw(_ethAmountToCoinbase - _ethBalance); //we send the arb profit to the EOA...
        }
        block.coinbase.transfer(_ethAmountToCoinbase); //...and the rest to the miner
        // block.coinbase.call{value:_ethAmountToCoinbase}(new bytes(0));
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external onlyOwner payable returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }
}

