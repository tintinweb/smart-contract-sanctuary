/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ProxyS1{

    address internal _implCardGame;
    
    address internal _admin;
    
    address internal _candidateAdmin;
}

abstract contract CardGameS1{
    address internal dev;
    
    address internal candidateDev;
    
     //1.卡合成
     //2. 卡消耗消耗销毁
    struct Attribute{
        Sex identity;
        uint8 grades;
        uint256 regainTime;
        uint8 giveNumber;
        bool giveStatus;
    }
    bytes4 internal  _retval;
    Error internal  _error;
    
    enum Error {
        None,
        RevertWithMessage,
        RevertWithoutMessage,
        Panic
    }
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x5175f878;
    
    mapping (uint256 => Attribute) internal attribute;
    
    enum Sex{
        no,
        man,
        woman
    }
    
    enum GiveLimit{
        zero,
        one,
        two,
        limit
    }
    
}
contract Proxy is ProxyS1  {

    constructor() {
        _admin = msg.sender;
    }
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
     function upgradeTo(address newImplementation) external {
         require(admin() ==msg.sender,"no permission");
         require(isContract(newImplementation),"Not smart contracts");
         _implCardGame = newImplementation;
        
    }
  

    function admin() public view returns(address){
        return _admin;
    }
    
    function unconfirmedAdmin() public view returns(address){
        return _candidateAdmin;
    }

    function updateAdmin(address newAdmin)external {
        require(admin() == msg.sender,"No permission ");
        _candidateAdmin = newAdmin;
    }

    function confirmAdmin() external {
        require(unconfirmedAdmin() == msg.sender,"No permission ");
        _admin = _candidateAdmin;
        _candidateAdmin = address(0);
    }
    
    function _delegate(address implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    
    function implementations()external view  returns(address){
        return  _implementation();
    }
    
    function _implementation() internal view virtual returns (address){
        return _implCardGame;
    }


    function _fallback() internal virtual {
        _delegate(_implementation());
    }


    fallback() external payable virtual {
        _fallback();
    }

    receive() external payable virtual {
        _fallback();
    }
}