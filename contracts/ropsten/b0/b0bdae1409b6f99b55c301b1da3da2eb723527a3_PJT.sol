/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity ^0.8.7;

// library SafeMath {
//     function add(uint256 a, uint256 b) internal pure returns(uint256) {
//         uint256 c = a + b;
//         assert(c <= a);
//         return c;
//     }
//     function sub(uint256 a, uint256 b) internal pure returns(uint256) {
//         assert(a >= b);
//         uint256 c = a - b;
//         return c;
//     }
//     function mul(uint256 a, uint256 b) internal pure returns(uint256) {
//         if (a == 0) {
//             return 0;
//         }
//         uint256 c = a * b;
//         assert(c / a == b);
//         return c;
//     }
//     function div(uint256 a, uint256 b) internal pure returns(uint256) {
//         uint256 c = a / b;
//         return c;
//     }
// }

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PJT is Ownable {
    function sendToken(address tokenType, address recipient, uint256 amount) external {
        IERC20 token = IERC20(tokenType);
        // uint256 totalAmount = 0;
        // for (uint256 i = 0 ; i < amount.length ; i++) {
        //     totalAmount += amount[i];
        // }

        // token.approve(address(msg.sender), totalAmount);
        // token.transferFrom(address(msg.sender), address(this), totalAmount);

        token.approve(msg.sender, amount);
        // return token.allowance(msg.sender, address(this));
        token.transferFrom(msg.sender, recipient, amount);

        // token.transfer(recipient, amount);

        // token.transfer(recipient, amount);

        // for (uint256 i = 0; i < array.length; i++) {
        //     token.transfer()
        // }

        // emit Transfer(msg.sender, _owner, amount);
    }
    receive() external payable { }
}