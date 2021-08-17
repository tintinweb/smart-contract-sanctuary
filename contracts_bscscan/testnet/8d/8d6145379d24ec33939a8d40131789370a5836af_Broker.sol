/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

interface IWBNB {
    function withdraw(uint) external;
    function deposit() external payable;
}

interface IGekko {
    function gekkoExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract Broker is Ownable {
    address public gekko;
    address public immutable WBNB;

    constructor(address _gekko, address _WBNB) {
        gekko = _gekko;
        WBNB = _WBNB;
    }

    function deposit() external payable {
        IWBNB(WBNB).deposit{value: msg.value}();
        IERC20(WBNB).approve(gekko, msg.value);
    }

    function buy(address tokenBase, uint amountBuy, address tokenBuy,  uint amountOutMin) external onlyOwner returns(bool success) {   
        require(IERC20(WBNB).balanceOf(address(this)) >= amountBuy, "Not enough WBNB in the contract");
        address[] memory path;
        if (tokenBase != WBNB){
            path = new address[](3);
            path[0] = WBNB;
            path[1] = tokenBase;
            path[2] = tokenBuy;
        } else {
            path = new address[](2);
            path[0] = WBNB;
            path[1] = tokenBuy;
        }
        IGekko(gekko).gekkoExactTokensForTokens(
              amountBuy,
              amountOutMin,
              path, 
              address(this),
              block.timestamp + 30
        );
        return true;
    }
    function sell(address token, uint amountSell, uint amountOutMin) external onlyOwner returns(bool success) {   
        require(IERC20(token).balanceOf(address(this)) >= amountSell, "Not enough TOKEN in the contract");
        IERC20(token).approve(gekko, amountSell);
        address[] memory path;
        path = new address[](2);
        path[0] = token;
        path[1] = WBNB;
        IGekko(gekko).gekkoExactTokensForTokens(
              amountSell,
              amountOutMin,
              path, 
              address(this),
              block.timestamp + 30
        );
        return true;
    }
    
    function setGekko(address _newGekko) external onlyOwner returns(bool success){
        gekko = _newGekko;
        return true;
    }
    
    function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        address to = this.owner();
        IERC20(_tokenAddress).transfer(to, balance);
    }
 
   function withdraw() public onlyOwner {
        address self = address(this); // workaround for a possible solidity bug
        payable(this.owner()).transfer(self.balance);
    }
}