pragma solidity ^0.5.0;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract HappyNewYearCoin is Context, ERC20, ERC20Detailed {
    //HappyNewYearCoin： 代币的全名
    //HPY：代币的简写
    //3: 代币小数点位数，代币的最小单位， 3表示我们可以拥有 0.001单位个代币
    constructor () public ERC20Detailed("HappyNewYearCoin", "HPY", 3) {
        //初始化币，并把所有的币都给部署智能合约的ETH钱包地址
        //10000000000000000：代币的总数量
        _mint(_msgSender(), 10000000000000000 * (10 ** uint256(decimals())));
    }
}