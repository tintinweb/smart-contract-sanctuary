//SourceUnit: Test.sol

pragma solidity ^0.5.14;



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "Math error");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Math error");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a / b;
        return c;
    }
}

interface IJustswapExchange {
    // 卖出trx, 换取token
    function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);
}



// Token contract
contract Test {
    using SafeMath for uint256;
    address public constant hnftAddress = 0xcF8eCF0c97D86b700E43d8c0D69f6940eD6785Ef;
    address public constant justSwapPair = 0x152B0d70C0fEE3B471f02dA25Ea4B176BC33cdE7;
    bytes4 private constant TRANSFER = bytes4(keccak256(bytes("transfer(address,uint256)")));

    function() payable external {}

    // 接受放地址用户
    // 用户购买挂单
    function userBuyOrder() external payable {
        uint256 _value20 = msg.value.mul(20).div(100);
        // bsc swap 路由合约; 兑换直接给到99地址进行销毁, 00地址不能转入, 01地址不合法
        (uint256 _tokenNumber) = IJustswapExchange(justSwapPair).trxToTokenSwapInput.value(_value20)(0 , block.timestamp + 300000);
        (bool success, ) = hnftAddress.call(
            abi.encodeWithSelector(TRANSFER, 0x0000000000000000000000000000000000000001, _tokenNumber)
        );
        if(!success) {
            revert("NFT: transfer fail 22");
        }
    }


}