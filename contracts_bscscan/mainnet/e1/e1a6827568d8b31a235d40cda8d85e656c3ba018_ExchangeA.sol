/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

contract Ownable is OwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (address _owner) {
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

}


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function mint(address to, uint256 amount) external returns(bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


interface IUni {

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external payable
    returns (uint[] memory amounts);
    
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) 
    external 
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function WETH() external pure returns (address);
}




contract ExchangeA is Ownable{

    
    enum OrderType {EthForTokens, TokensForEth, TokensForTokens}

    event Received(address, uint);
    event Error(address);

    receive() external payable {
        // if (validUser[msg.sender] == true) {
        //     balance[msg.sender][ETH] += msg.value;
        emit Received(msg.sender, msg.value);
        // } else {
        //     balance[owner][ETH] += msg.value;
        // }
    }

    fallback() external payable {
        revert();
    }

    IUni public Uni;
    address ETH;
    constructor(address _Uni, address _owner) Ownable(_owner) {
        Uni = IUni(_Uni);
        ETH = Uni.WETH();
    }
    
    function getBestQuotation(uint orderType, address[] memory path, uint256 amountIn) public view returns (uint256) {
        uint256[] memory uniAmounts;
        (uniAmounts) = Uni.getAmountsOut(amountIn, path);
        return(uniAmounts[1]);
    }
    
    function executeSwapping(uint orderType, address[] memory path, uint256 assetInOffered, uint256 assetOutExpected, address to, uint256 deadline) external payable onlyOwner returns (uint[] memory){
        uint[] memory swapResult;
        if(OrderType(orderType) == OrderType.EthForTokens) {
             swapResult = Uni.swapExactETHForTokens{value:assetInOffered}(assetOutExpected, path, to, block.timestamp + deadline);
        }
        else if (OrderType(orderType) == OrderType.TokensForEth) {
            TransferHelper.safeApprove(path[0], address(Uni), assetInOffered);
            swapResult = Uni.swapExactTokensForETH(assetInOffered, assetOutExpected, path, to, block.timestamp + deadline);
        }
        else if (OrderType(orderType) == OrderType.TokensForTokens) {
            TransferHelper.safeApprove(path[0], address(Uni), assetInOffered);
            swapResult = Uni.swapExactTokensForTokens(assetInOffered, assetOutExpected, path, to, block.timestamp + deadline);
        }
        return swapResult;
        
    }
}