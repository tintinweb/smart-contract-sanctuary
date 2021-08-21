/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-08-21
*/

pragma solidity ^0.8.6;
// SPDX-License-Identifier: MIT

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IEnchanterCryptoHub {
    function membership(address member) external view returns (uint256);
    function taxWhiteList(address member) external view returns (bool);
    function buyTax() external view returns (uint256);
    function sellTax() external view returns (uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableSimplified is Context {
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}


abstract contract Chest is OwnableSimplified {
    receive() external payable {}

    function claim(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
        } else {
            IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
        }
    }
}

contract EnchanterCryptoHub is IEnchanterCryptoHub, Chest {
    mapping(address => uint256) public override membership;
    mapping(address => bool) public override taxWhiteList;
    uint256 public override buyTax;
    uint256 public override sellTax;

    function setMembership(address _member, uint256 _value) external onlyOwner {
        membership[_member] = _value;
    }

    function setBuyTax(uint256 _value) external onlyOwner {
        buyTax = _value;
    }

    function setSellTax(uint256 _value) external onlyOwner {
        sellTax = _value;
    }

    function setWhiteList(address _member, bool _value) external onlyOwner {
        taxWhiteList[_member] = _value;
    }
}