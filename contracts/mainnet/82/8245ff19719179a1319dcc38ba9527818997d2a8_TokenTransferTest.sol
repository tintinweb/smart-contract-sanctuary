pragma solidity ^0.4.24;

interface BadERC20 {
    function transfer(address _to, uint256 _value) external;
}

interface GoodERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
}

contract TokenTransferTest {

    uint public GOOD_ERC20 = 1;
    uint public BAD_ERC20 = 2;

    function ()
        payable
        external
    {
        revert();
    }

    function testBadWithGoodInterface(address token,
                                      uint ercType,
                                      address to,
                                      uint value)
        external
    {
        if (ercType == 1) {
            GoodERC20 goodErc20 = GoodERC20(token);
            require(goodErc20.transfer(to, value));
        } else {
            BadERC20 badErc20 = BadERC20(token);
            badErc20.transfer(to, value);
        }
    }

}