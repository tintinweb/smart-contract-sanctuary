/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED

interface IWETH {
    /*
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    */
    function withdraw(uint) external;
}

interface IPAIR {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IERC20 {
    /*
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    */
    function balanceOf(address owner) external view returns (uint);
    //function approve(address spender, uint value) external returns (bool);
}

// https://gastoken.io/
interface Gastoken {
    function free(uint256 value) external returns (bool success);
    // function freeUpTo(uint256 value) public returns (uint256 freed);
    // function freeFrom(address from, uint256 value) public returns (bool success);
    // function freeFromUpTo(address from, uint256 value) public returns (uint256 freed);
}

contract Sandwich {
    // 用来看版本号
    string public constant name = "0x33-v2.0";

    // 固定owner，不然就要从storage中读取，浪费gas
    address private constant OWNER = 0x3376EBC8DCE3453a045A145Ab7b1e728b2ED581e;

    // WETH
    address private constant WETH =  0xc778417E063141139Fce010982780140Aa0cD5Ab;
    //0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // GST2
    address private constant GST2 = 0x0000000000b3F879cb30FE243b4Dfee438691c04;

    //
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address private constant EMPT = 0x0000000000000000000000000000000000000000;

    // 构造函数，空的
    constructor() {
    }    

    // receive ETH，空的
    receive() external payable {}

    // OWNER
    modifier onlyOwner() {
        require(msg.sender == OWNER, "SaV1: sender not owner");
        _;
    }

    //万一有token，提现
    // 这些都是偶尔调用，因此应该不会在正常使用的时候浪费gas的
    // token是ERC20 token address
    function withdrawToken(address token) external onlyOwner returns (uint balance) {
        balance = IERC20(token).balanceOf(address(this));
        if(balance > 0) {
            _safeTransfer(token, msg.sender, balance);
        }
    }

    function withdrawTokenWithAmount(address token, uint amount) external onlyOwner returns (uint balance) {
        balance = IERC20(token).balanceOf(address(this));
        require(balance >= amount);
        _safeTransfer(token, msg.sender, amount);
    }

    function withdrawETH() external onlyOwner returns (uint balance) {
        balance = address(this).balance;
        if(balance > 0) {
            _safeTransferETH(msg.sender, balance);
        }
    }

    function _safeTransferETH(address to, uint256 value) private {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'SaV1: ETH transfer failed');
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SaV1: TRANSFER_FAILED');
    }

    // 下面是正式的函数

    // buy: 用ETH buy token
    function buy(
        uint gst2_to_use, 
        address pair_addr, 
        uint token_pos, 
        uint eth_amount_in, 
        uint token_amount_out,
        bytes32 parent_hash
    ) external onlyOwner {
        bytes32 real_parent_hash = blockhash(block.number - 1);
        require(parent_hash == real_parent_hash);

        if(gst2_to_use > 0) {
            require(Gastoken(GST2).free(gst2_to_use));
        }

        _safeTransfer(WETH, pair_addr, eth_amount_in);

        bytes memory data = new bytes(0);

        if(token_pos == 0) {
            IPAIR(pair_addr).swap(token_amount_out, 0, address(this), data);
        } else {
            IPAIR(pair_addr).swap(0, token_amount_out, address(this), data);
        }

        // done
    }
    
    function test_hash(bytes32 parent_hash) view external onlyOwner returns (bytes32) {
        bytes32 real_parent_hash = blockhash(block.number - 1);
        require(parent_hash == real_parent_hash);
        return real_parent_hash;
    }

    // sell: 
    function sell(
        uint gst2_to_use, 
        address pair_addr, 
        address token_addr, 
        uint token_pos, 
        uint token_amount_in, 
        uint eth_amout_out, 
        uint amount_to_coinbase,
        address coinbase_addr,
        bytes32 parent_hash
        ) external onlyOwner {

        bytes32 real_parent_hash = blockhash(block.number - 1);
        require(parent_hash == real_parent_hash);

        if(gst2_to_use > 0) {
            require(Gastoken(GST2).free(gst2_to_use));
        }

        _safeTransfer(token_addr, pair_addr, token_amount_in);

        bytes memory data = new bytes(0);

        if(token_pos == 0) {
            IPAIR(pair_addr).swap(0, eth_amout_out, address(this), data);
        } else {
            IPAIR(pair_addr).swap(eth_amout_out, 0, address(this), data);
        }

        if(amount_to_coinbase > 0) {
            IWETH(WETH).withdraw(amount_to_coinbase);

            if(coinbase_addr == EMPT) {
                block.coinbase.transfer(amount_to_coinbase);
            } else {
                _safeTransferETH(coinbase_addr, amount_to_coinbase);
            }
        }
    }
}