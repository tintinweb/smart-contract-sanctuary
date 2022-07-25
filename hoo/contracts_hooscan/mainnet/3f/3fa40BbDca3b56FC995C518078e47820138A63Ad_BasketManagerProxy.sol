/**
 *Submitted for verification at hooscan.com on 2021-07-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
contract CEO {
    address public OwnerAddress;
    address public WaitingAddress;
    uint256 public CreateUpdataTime;
    constructor ()  {//建立合同需要运行的
        OwnerAddress = msg.sender;
        WaitingAddress = msg.sender;
        CreateUpdataTime = 0;
    }
    event UpdateCEOApply(address CEOAddress,uint256 CreateUpdataTime);
    event UpdataConfirm(address CEOAddress);
    
    modifier onlyCEO() { 
        require (isCEO(),"You are not the CEO"); 
        _; 
    }
    
    function isCEO () public view returns (bool){
        return OwnerAddress ==  msg.sender;
    }

    function updateCEOApply (address CEOAddress) public onlyCEO{ //提交更新CEO
        require(CEOAddress != address(0), "GOV: new CEO is address(0)");
        WaitingAddress = CEOAddress;
        CreateUpdataTime = block.timestamp;
        emit UpdateCEOApply(WaitingAddress,CreateUpdataTime);
    }

    function updataConfirm () public  {//等24小时后，
        require( block.timestamp > CreateUpdataTime + (60*60*24) && CreateUpdataTime!=0, "Time has not expired");
        require (WaitingAddress == msg.sender,'You are not to update the address');
        OwnerAddress = WaitingAddress;
        CreateUpdataTime = 0;
        emit UpdataConfirm(OwnerAddress);
    }
}



contract Proxy is CEO,Initializable{

    address public implementation;

    function upgradeTo(address _address) public onlyCEO{
        implementation = _address;
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation_) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation_, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address){
        return implementation;
    }
    
    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

contract saveLogicPoolProxy is Proxy {}

contract mintLogicPoolProxy is Proxy {}

contract sameCoinERC20Proxy is Proxy {}

contract BasketManagerProxy is Proxy {}

contract MassetProxy is Proxy {}