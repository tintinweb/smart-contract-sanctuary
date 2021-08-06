/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity ^0.6.8;

pragma experimental ABIEncoderV2;

interface IGasToken {
    function freeFrom(address, uint256) external returns (bool);
}

contract Farts /*is IERC20*/ {

    string public constant name = "BlockFarts"; // Attn Rappers: this rhymes with PopTarts
    string public constant symbol = "FARTS";
    IGasToken public constant GST1 = IGasToken(0x88d60255F917e3eb94eaE199d827DAd837fac4cB);
    IGasToken public constant GST2 = IGasToken(0x0000000000b3F879cb30FE243b4Dfee438691c04);
    IGasToken public constant CHI = IGasToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    uint8 public constant decimals = 12;
    uint256 public constant INFINITE = 0xe00000000000000000000000;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    bool private entered;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address to, uint256 value) external returns (bool) {
        {
            uint256 fromBalance = balanceOf[msg.sender];
            require (fromBalance >= value);
            balanceOf[msg.sender] = fromBalance - value;
        }
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        {
            uint256 fromBalance = balanceOf[from];
            require (fromBalance >= value);
            balanceOf[from] = fromBalance - value;
        }
        {
            uint256 fromAllowance = allowance[from][msg.sender];
            require (fromAllowance >= value);
            if (fromAllowance < INFINITE) {
                allowance[from][msg.sender] = fromAllowance - value;
            }
        }
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function mintWithGasToken(IGasToken gasToken, uint256 burn) external {
        uint256 gas = gasleft();
        require (gasToken == CHI || gasToken == GST2 || gasToken == GST1);
        gasToken.freeFrom(msg.sender, burn);
        balanceOf[msg.sender] += 1000000000000;
        totalSupply += 1000000000000;
        emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, 1000000000000);
        require (gas - gasleft() > block.gaslimit / 5);
    }

    function mintWithCall(address target, bytes calldata data) external {
        uint256 gas = gasleft();
        require (!entered);
        entered = true;
        target.call(data);
        entered = false;
        balanceOf[msg.sender] += 1000000000000;
        totalSupply += 1000000000000;
        emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, 1000000000000);
        require (gas - gasleft() > block.gaslimit / 2);
    }

    // like mintWithCall, but don't revert for insufficient gas use
    function tryMintWithCall(address target, bytes calldata data) external {
        uint256 gas = gasleft();
        require (!entered);
        entered = true;
        target.call(data);
        entered = false;
        if (gas - gasleft() > block.gaslimit / 2) {
            balanceOf[msg.sender] += 1000000000000;
            totalSupply += 1000000000000;
            emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, 1000000000000);
        }
    }

    function mintWithMulticall(address[] calldata targets, bytes[] calldata datas, uint256[] calldata values) external payable {
        uint256 gas = gasleft();
        require (!entered);
        entered = true;
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i].call{value: values[i]}(datas[i]);
        }
        entered = false;
        balanceOf[msg.sender] += 1000000000000;
        totalSupply += 1000000000000;
        emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, 1000000000000);
        require (gas - gasleft() > block.gaslimit / 2);
    }

    function tryMintWithMulticall(address[] calldata targets, bytes[] calldata datas, uint256[] calldata values) external payable {
        uint256 gas = gasleft();
        require (!entered);
        entered = true;
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i].call{value: values[i]}(datas[i]);
        }
        entered = false;
        balanceOf[msg.sender] += 1000000000000;
        if (gas - gasleft() > block.gaslimit / 2) {
            balanceOf[msg.sender] += 1000000000000;
            totalSupply += 1000000000000;
            emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, 1000000000000);
        }
    }

    receive() external payable {}
}