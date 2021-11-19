/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-07
*/

// EverOwn Wrapper contract exmaple

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// If interfaces are needed add them here

// IERC20/IBEP20 standard interface.
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Any contract methods that are required
 */
interface IMetaSatoshi {
    // Any other/different contract wrapper methods if ownership transfer is not via transferOwnership
    function transferOwnership(address payable _address) external;
}

contract Ownable is Context {
    address private _owner;
    address private _buybackOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }
}

// *** Rename this to your proxy wrapper contract
contract MetaSatoshiOWN is Ownable {
    // *** Rename to be an ownership proxy for your token e.g. xxxxOWN
    string private _name = "MetaSatoshiOWN";
    string private _symbol = "MetaSatoshiOWN";

    IMetaSatoshi public token;

    constructor (address _token) {
        token = IMetaSatoshi(payable(_token));
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // *** Releasing the ownership from the wrapper contract back to owner
    function releaseOwnership() public onlyOwner {
        // ****
        // If your contract uses a different ownership technique and that's why you are wrapping
        // change the body of this function to match that
        // ***
        token.transferOwnership(_msgSender());
    }

    // Function to release ETH trapped in wrapper, can be released when ownership returned
    function releaseTrappedETH(address payable toAddress) external onlyOwner {
        require(toAddress != address(0), "toAddress can not be a zero address");
        
        toAddress.transfer(address(this).balance);
    }

    // Function to release tokens trapped in wrapper, can be released when ownership returned
    function releaseTrappedTokens(address tokenAddress, address toAddress) external onlyOwner {
        require(tokenAddress != address(0), "tokenAddress can not be a zero address");
        require(toAddress != address(0), "toAddress can not be a zero address");
        require(IERC20(tokenAddress).balanceOf(address(this)) > 0, "Balance is zero");

        IERC20(tokenAddress).transfer(toAddress, IERC20(tokenAddress).balanceOf(address(this)));
    }

    // To recieve ETH
    receive() external payable {}

    // Fallback function to receive ETH when msg.data is not empty
    fallback() external payable {}
}