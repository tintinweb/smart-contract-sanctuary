// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EPIKPRIME {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _cap;
    bool private _mintingFinished;

    uint256 public updateTimestamp;
    
    address public owner;
    address public implementation;

    constructor (address implementation_) {
        implementation = implementation_;
        owner = msg.sender;
        updateTimestamp = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    function upgradeImplementation(address implementation_) public onlyOwner{
        implementation = implementation_;
    }

    function _fallback(address implementation_) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    fallback() external payable {
        _fallback(implementation);
    }

    receive() external payable {
        _fallback(implementation);
    }
}

