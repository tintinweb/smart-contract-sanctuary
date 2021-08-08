/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _setOwner(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract RoyaltiesSplitterV2 is Ownable{
    address[] private __payees = [
        address(0xdB505E07E03bb9B4Bf2dd69af201546b86A27Def),
        address(0xA1d553AEF57d8619227F996a741f47dcd94CBE18),
        address(0x1c447BD23424903610A2198315831122C99463B9),
        address(0xF1D8d1aF7FF2410E17FDec1B43C0368b6A89655E)
    ];

    uint256[] private __shares = [61530, 3846, 11530, 23070];


    constructor(){
        
    }

    
    receive() external payable {

    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 arrayLength = __payees.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            payable(__payees[i]).transfer((balance * __shares[i]) / 100000);
        }
        balance = address(this).balance;
    }
}