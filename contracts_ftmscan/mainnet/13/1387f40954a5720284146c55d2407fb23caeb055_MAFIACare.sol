/**
 *Submitted for verification at FtmScan.com on 2021-12-31
*/

/**

Making FANTOM safer! Community & Peer review & KYC services & tools for FTM Chain!

Website: https://defymafia.com
Telegram: https://t.me/defymafia

A contract that holds funds for taking care of $MAFIA holders in the event they get rugged in any FTM tokens.

*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

contract MAFIACare is Ownable {

    IERC20 constant WFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);

    function compensateVictim(address account) external onlyOwner {
        require(WFTM.balanceOf(address(this)) >= 10 ether, "At least 10 FTM needed!");
        WFTM.transfer(account, 10);
    }
    receive() external payable{
    }
}