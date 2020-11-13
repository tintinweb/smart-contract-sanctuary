pragma solidity ^0.5.0;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract AIB2020 is Context, ERC20, ERC20Detailed {
    //Zhang0PeterCoin： 代币的全名
    //ZPC：代币的简写
    //3: 代币小数点位数，代币的最小单位， 3表示我们可以拥有 0.001单位个代币
    constructor () public ERC20Detailed("AIB on ERC20 V1", "AIB", 8) {
        //初始化币，并把所有的币都给部署智能合约的ETH钱包地址
        //233：代币的总数量
        _mint(_msgSender(), 21000000 * (10 ** uint256(decimals())));
    }
}
