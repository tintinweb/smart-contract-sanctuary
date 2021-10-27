/**
 *Submitted for verification at arbiscan.io on 2021-10-27
*/

pragma solidity >=0.5.0;

interface ITroller {
    function getAllMarkets() external view returns (ICToken[] memory);
    function oracle() external view returns (IOracle);
    function mintGuardianPaused(address) external view returns (bool);
}

interface ICToken {
    function getCash() external view returns (uint256);
}

interface IOracle {
    function getUnderlyingPrice(ICToken cToken) external view returns (uint256);
}

contract TVL {
    ITroller public troller;
    constructor(ITroller _troller) public {
        troller = _troller;
    }
    function getTVL(uint256 decimals) external view returns (uint256) {
        ICToken[] memory allmarkets = troller.getAllMarkets();
        IOracle oracle = troller.oracle();
        uint256 sum = 0;
        for (uint256 i = 0; i < allmarkets.length; i++) {
            ICToken ctoken = allmarkets[i];
            if (!troller.mintGuardianPaused(address(ctoken))) {
                uint256 price = oracle.getUnderlyingPrice(ctoken);
                uint256 amount = ctoken.getCash();
                sum += amount * price;
            }
        }
        return sum/(10**decimals);
    }
}