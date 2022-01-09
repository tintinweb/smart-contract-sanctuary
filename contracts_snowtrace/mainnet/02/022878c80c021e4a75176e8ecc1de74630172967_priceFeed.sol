/**
 *Submitted for verification at snowtrace.io on 2022-01-09
*/

interface IJoeFactory{
    function getPair(address, address) external view returns(address);
}

interface IERC20{
    function balanceOf(address) external view returns (uint);
}

// Must only be used for display functions. Subject to manipulation.
contract priceFeed{
    address public mim = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public joeFactory = 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10;

    function assetPrice(address _token) public view returns (uint) {
        address lpPair = IJoeFactory(joeFactory).getPair(address(_token), mim);
        uint den = IERC20(_token).balanceOf(lpPair);
        uint num = IERC20(mim).balanceOf(lpPair);
        uint price = num*1e18/den;
        return price;
    }
}