/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

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

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// This contract simply calls multiple targets sequentially, ensuring WETH balance before and after

contract FlashBotsMultiCall {
    address private owner;
    mapping (address => bool) _whiteListed;
   
    IWETH private constant WETH = IWETH(0xc778417E063141139Fce010982780140Aa0cD5Ab);

    constructor() public payable {
        owner = msg.sender;

        _whiteListed[owner] = true;
        if (msg.value > 0) {
            WETH.deposit{value: msg.value}();
        }
    }

    receive() external payable {
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyWhitelisted() {
        require(_whiteListed[msg.sender]);
        _;
    }

    function includeWhitelist(address addressToWhiteList) public virtual onlyOwner {
        _whiteListed[addressToWhiteList] = true;
    }
 
    function excludeWhitelist(address addressToExclude) public virtual onlyOwner {
        _whiteListed[addressToExclude] = false;
    }

    function executeTxWithFlashbots(uint256 _ethAmountToCoinbase, uint256[] memory _values, address[] memory _targets, bytes[] memory _payloads) external onlyWhitelisted payable {
        require (_targets.length == _payloads.length);
        require (_targets.length == _values.length);

        for (uint256 i = 0; i < _targets.length; i++) {
            if (_values[i] == 0) {
                (bool _success, bytes memory _response) = _targets[i].call(_payloads[i]);
                require(_success, "transaction failed"); _response;
            } else {
                (bool _success, bytes memory _response) = _targets[i].call{value: _values[i]}(_payloads[i]);
                require(_success, "transaction failed"); _response;
            }
        }

        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function withdrawETH(address to) onlyOwner public {
        TransferHelper.safeTransferETH(to, address(this).balance);
    }
    
    function withdrawToken(address token, address to) onlyOwner public {
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
    }
}