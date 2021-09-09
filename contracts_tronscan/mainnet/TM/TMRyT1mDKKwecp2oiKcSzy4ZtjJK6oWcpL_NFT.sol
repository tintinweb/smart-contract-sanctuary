//SourceUnit: abc.sol

// NFT合约
pragma solidity ^0.5.16;


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED2');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED2');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED2');
    }

    function safeTransferETH(address to, uint value) internal {
        // (bool success,) = to.call{value:value}(new bytes(0));
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED2');
    }
}



interface IJustswapExchange {
    // 卖出trx, 换取token
    function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);
}


// NFT卡牌
contract NFT {


    // 参数1: HNFT(ETM)代币合约地址;
    // 参数2: just swap; ETM-TRX配对合约地址;
    // ETM真-TRX: TYe7w3rdgDvYRBT8qnbL8sEjHVoosAvaEj=0xf8aec21da483abc342c524942e2dc1e4a237787c;
    constructor(address _hnftAddress, address _justSwapPair) public {
        hnftAddress = _hnftAddress;
        justSwapPair = _justSwapPair;
    }

    // hnft代币地址(ETM地址)
    address public hnftAddress;
    address public justSwapPair;
    // 0地址, 用于销毁代币的; 考虑的有写合约不能转给0地址, 所有使用99地址
    address public constant zeroAddress = 0x0000000000000000000000000000000000000001;
    // 领取收益事件
    event BuyNipo(address owner, address owner2, uint256 value);



    // 首发购买交易
    function nipoBuyToken(
        address _sellerAddress,
        uint256 _sellerTrxValue,
        uint256 _burnTrxValue
    ) external payable {
        // 开始转账; 用户携带的value是直接全部自动给到合约的, 然后合约再转给卖方, 发送trx是合约;
        TransferHelper.safeTransferETH(_sellerAddress, _sellerTrxValue);
        // 兑换进行销毁的trx;=====================================================================
        (uint256 _tokenNumber) = IJustswapExchange(justSwapPair).trxToTokenSwapInput.value(_burnTrxValue)(1, block.timestamp + 300000);
        TransferHelper.safeTransfer(hnftAddress, zeroAddress, _tokenNumber);

        // 触发买首发事件
        emit BuyNipo(_sellerAddress, msg.sender, msg.value);
    }

    // 首发购买交易
    function nipoBuyToken2(
        address _sellerAddress,
        uint256 _sellerTrxValue,
        uint256 _burnTrxValue
    ) external payable {
        // 开始转账; 用户携带的value是直接全部自动给到合约的, 然后合约再转给卖方, 发送trx是合约;
        TransferHelper.safeTransferETH(_sellerAddress, _sellerTrxValue);
        // 兑换进行销毁的trx;=====================================================================
        (uint256 _tokenNumber) = IJustswapExchange(justSwapPair).trxToTokenSwapInput.value(_burnTrxValue)(1, block.timestamp + 300000);
        TransferHelper.safeTransfer(hnftAddress, zeroAddress, 2);

        // 触发买首发事件
        emit BuyNipo(_sellerAddress, msg.sender, msg.value);
    }

    // 首发购买交易
    function nipoBuyToken3(
        address _sellerAddress,
        uint256 _sellerTrxValue,
        uint256 _burnTrxValue
    ) external payable {
        // 开始转账; 用户携带的value是直接全部自动给到合约的, 然后合约再转给卖方, 发送trx是合约;
        TransferHelper.safeTransferETH(_sellerAddress, _sellerTrxValue);
        // 兑换进行销毁的trx;=====================================================================
        (uint256 _tokenNumber) = IJustswapExchange(justSwapPair).trxToTokenSwapInput.value(_burnTrxValue)(1, block.timestamp + 300000);
        TransferHelper.safeTransfer(hnftAddress, msg.sender, _tokenNumber);

        // 触发买首发事件
        emit BuyNipo(_sellerAddress, msg.sender, msg.value);
    }

    // 首发购买交易
    function nipoBuyToken4(
        address _sellerAddress,
        uint256 _sellerTrxValue,
        uint256 _burnTrxValue
    ) external payable {
        // 开始转账; 用户携带的value是直接全部自动给到合约的, 然后合约再转给卖方, 发送trx是合约;
        TransferHelper.safeTransferETH(_sellerAddress, _sellerTrxValue);
        // 兑换进行销毁的trx;=====================================================================
        (uint256 _tokenNumber) = IJustswapExchange(justSwapPair).trxToTokenSwapInput.value(_burnTrxValue)(1, block.timestamp + 300000);
        // TransferHelper.safeTransfer(hnftAddress, zeroAddress, 2);
        a = _tokenNumber;

        // 触发买首发事件
        emit BuyNipo(_sellerAddress, msg.sender, msg.value);
    }

    uint256 public a;


    function() payable external {}

}