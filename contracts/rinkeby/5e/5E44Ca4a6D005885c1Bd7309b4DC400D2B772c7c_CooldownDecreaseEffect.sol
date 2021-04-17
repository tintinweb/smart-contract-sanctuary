pragma solidity ^0.4.23;

import "./CutiePluginBase.sol";

/// @title Item effect for Blockchain Cuties
/// @author https://BlockChainArchitect.io
contract CooldownDecreaseEffect is CutiePluginBase
{
    function run(
        uint40,
        uint256,
        address
    ) 
        public
        payable
        onlyPlugins
    {
        revert();
    }

    function runSigned(
        uint40 _cutieId,
        uint256 _parameter,
        address /*_owner*/
    ) 
        external
        onlyPlugins
        whenNotPaused
        payable
    {
        uint16 cooldownIndex = coreContract.getCooldownIndex(_cutieId);
        require(cooldownIndex > 0);
        if (cooldownIndex > _parameter)
        {
            cooldownIndex -= uint16(_parameter);
        }
        else
        {
            cooldownIndex = 0;
        }
        coreContract.changeCooldownIndex(_cutieId, cooldownIndex);
    }
}