/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

pragma solidity 0.5.14;



library Utils{

    function _isETH(address globalConfig, address _token) public view returns (bool) {
        return IConstant(IGlobalConfig(globalConfig).constants()).ETH_ADDR() == _token;
    }

    function getDivisor(address globalConfig, address _token) public view returns (uint256) {
        if(_isETH(globalConfig, _token)) return IConstant(IGlobalConfig(globalConfig).constants()).INT_UNIT();
        return 10 ** uint256(ITokenRegistry(IGlobalConfig(globalConfig).tokenInfoRegistry()).getTokenDecimals(_token));
    }

}

interface IGlobalConfig {
    function constants() external view returns (address);
    function tokenInfoRegistry() external view returns (address);
}

interface IConstant {
    function ETH_ADDR() external view returns (address);
    function INT_UNIT() external view returns (uint256);
}

interface ITokenRegistry {
    function getTokenDecimals(address) external view returns (uint8);
}