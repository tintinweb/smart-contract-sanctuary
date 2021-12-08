/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//测试从合约中提取任意erc20
contract Test1 {
    
    function transferOut(
        address payable recipient,
        address tokenAddress,
        uint256 quantizedAmount
    ) public {
        //        uint256 amount = fromQuantized(assetType, quantizedAmount);
        uint256 amount = quantizedAmount;
        
        //        address tokenAddress = extractContractAddress(assetType);
        IERC20 token = IERC20(tokenAddress);
        uint256 exchangeBalanceBefore = token.balanceOf(address(this));
        bytes memory callData = abi.encodeWithSelector(
            token.transfer.selector,
            recipient,
            amount
        );
        //        tokenAddress.safeTokenContractCall(callData);
        tokenAddress.call(callData);
        uint256 exchangeBalanceAfter = token.balanceOf(address(this));
        require(exchangeBalanceAfter <= exchangeBalanceBefore, "UNDERFLOW");
        // NOLINTNEXTLINE(incorrect-equality): strict equality needed.
        require(
            exchangeBalanceAfter == exchangeBalanceBefore - amount,
            "INCORRECT_AMOUNT_TRANSFERRED"
        );
    }
}


//测试展示 balanceof totalSupply
contract test2{
    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view virtual returns (uint256) {
        return block.timestamp+1;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        // check if token is actually a contract
        return block.timestamp;
    }
}

//测试代理
contract test3{
    fallback() external payable {
        address _implementation = 0x48FaDEf72AFee5091A05a4133929a26951422F9E;
        require (_implementation != address(0x0), "MISSING_IMPLEMENTATION");

        assembly {
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

        // Call the implementation.
        // out and outsize are 0 for now, as we don't know the out size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

        // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

contract test4{
    function transferIn(
        address payable sendAddr,
        address payable recipient,
        address tokenAddress,
        uint256 quantizedAmount
    ) public {
        //        uint256 amount = fromQuantized(assetType, quantizedAmount);
        uint256 amount = quantizedAmount;

        //        address tokenAddress = extractContractAddress(assetType);
        IERC20 token = IERC20(tokenAddress);
        uint256 exchangeBalanceBefore = token.balanceOf(address(this));
        bytes memory callData = abi.encodeWithSelector(
            token.transferFrom.selector,
            sendAddr,
            recipient,
            amount
        );
        //tokenAddress.safeTokenContractCall(callData);
        tokenAddress.call(callData);
    }
}