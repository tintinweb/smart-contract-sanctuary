/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
interface IERC20Permit {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function mint(address _to, uint256 _amount) external;
    function burn(address _to, uint256 _amount) external;
}
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint a, uint b) internal pure returns (uint ) {
        return a / b;
    }
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BridgeTo is Ownable {
    using SafeMath for uint256;

    address public dev_adr;

    event Burn(address indexed token, address indexed from, uint256 _amount, uint256 indexed id);
    event Mint(address indexed token, address indexed to, uint256 _amount);

    constructor(address _adr) public {
        dev_adr = _adr;
    }

    //release new token from deposit from other chain
    function mint(address token, address to, uint256 _amount) public onlyOwner {
        IERC20Permit(token).mint(to, _amount);
        emit Mint(token, to, _amount);
    }

    //burn token to withdraw to other chain
    function burn(address token, address from, uint256 _amount, uint256 id, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        IERC20Permit(token).permit(msg.sender, address(this), _amount, deadline, v, r, s);
        IERC20(token).transferFrom(from, address(this), _amount);
        IERC20Permit(token).burn(address(this), _amount);
        emit Burn(token, from, _amount, id);
    }

    function setDev(address newDev) public {
        require(msg.sender == dev_adr, "dev: wut?");
        dev_adr = newDev;
    }
}