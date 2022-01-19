/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT @GoPocketStudio
pragma solidity 0.7.5;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes memory) {
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
contract Ownable is Context {
    address public _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

}

library UintLibrary {
    function toString(uint256 i) internal pure returns (string memory c) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(uint8(48 + i % 10));
            i /= 10;
        }
        c = string(bstr);
    }
}

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;

        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

     /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
    }
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    
    function WETH() external pure returns (address);
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract SwapTest is Ownable{

    using StringLibrary for string;
    using UintLibrary for uint256;
    using Address for address;

    uint256 constant MAX_ALLOWANCE = ~uint256(0);

    constructor() {
    }

    function reverseArray(address[] memory path) public pure returns (address[] memory reversedPath){
        reversedPath = new address[](path.length);
        for(uint8 i = 0; i < path.length; i++){
            reversedPath[i] = path[path.length - i - 1];
        }
    }
    
    function getBalances(address[] memory path) internal view returns (uint256 balance0, uint256 balance1){
        IERC20 token0 = IERC20(path[0]);
        balance0 = token0.balanceOf(address(this));
        IERC20 token1 = IERC20(path[path.length - 1]);
        balance1 = token1.balanceOf(address(this));
    }
    
    function approveTokens(address[] memory path, address _routerAddress) internal {
        IERC20 token0 = IERC20(path[0]);
        token0.approve(_routerAddress, MAX_ALLOWANCE);
        IERC20 token1 = IERC20(path[path.length - 1]);
        token1.approve(_routerAddress, MAX_ALLOWANCE);
    }
    
    function testSwapTokensForTokens(uint amountBuyIn, address[] calldata path, address _routerAddress) external {
        require(amountBuyIn > 0, "amountBuyIn must > 0");
        require(path.length >= 2, "path.length must >= 2");
        
        approveTokens(path, _routerAddress);
        IUniswapV2Router uniswapV2Router = IUniswapV2Router(_routerAddress);
        
        //get origin balance of Token0 & Token1
        (, uint256 originToken1Balance) = getBalances(path);
        //calc expected buy amount out
        uint256[] memory amountBuyOuts = uniswapV2Router.getAmountsOut(amountBuyIn, path);
        uint256 expectedBuyOut = amountBuyOuts[amountBuyOuts.length - 1];
        //build result string
        string memory result = "[";
        result = result.append(expectedBuyOut.toString());
        result = result.append(",");
        //swap from path[0] to path[-1]
        try uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountBuyIn, 0, path, address(this), block.timestamp + 600) {

        } catch {
            result = result.append("-1");
            result = result.append("]");
            require(false, result);
        }
        (uint256 swapOnceToken0Balance , uint256 swapOnceToken1Balance) = getBalances(path);
        uint256 realBuyOut = swapOnceToken1Balance - originToken1Balance;
        result = result.append(realBuyOut.toString());
        if (realBuyOut > 0) {
            result = result.append(",");
        } else {
            result = result.append("]");
            require(false, result);
        }

        address[] memory reversedPath = reverseArray(path);
        //calc expected sell amount out
        uint256[] memory amountSellOuts = uniswapV2Router.getAmountsOut(realBuyOut, reversedPath);
        uint256 expectedSellOut = amountSellOuts[amountSellOuts.length - 1];
        result = result.append(expectedSellOut.toString());
        result = result.append(",");
        //swap from path[-1] to path[0]
        try uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(realBuyOut, 0, reversedPath, address(this), block.timestamp + 600) {

        } catch {
            result = result.append("-1");
            result = result.append("]");
            require(false, result);
        }
        (uint256 swapTwiceToken0Balance , ) = getBalances(path);
        uint256 realSellOut = swapTwiceToken0Balance - swapOnceToken0Balance;

        result = result.append(realSellOut.toString());
        result = result.append("]");
        require(false, result);
    }
    
    function testSwapETHForTokens(uint amountBuyIn, address[] calldata path, address _routerAddress) external {
        require(amountBuyIn > 0, "amountBuyIn must > 0");
        require(path.length >= 2, "path.length must >= 2");
        
        IUniswapV2Router uniswapV2Router = IUniswapV2Router(_routerAddress);
        address WETH = uniswapV2Router.WETH();
        require(path[0] == WETH, "path[0] must be WETH");
        approveTokens(path, _routerAddress);
        
        IERC20 token1 = IERC20(path[path.length - 1]);

        //get origin balance of Token0 & Token1
        uint256 originToken0Balance = address(this).balance;
        require(originToken0Balance > amountBuyIn, "Insufficient Balance Of ETH");
        uint256 originToken1Balance = token1.balanceOf(address(this));
        //calc expected buy amount out 
        uint256[] memory amountBuyOuts = uniswapV2Router.getAmountsOut(amountBuyIn, path);
        uint256 expectedBuyOut = amountBuyOuts[amountBuyOuts.length - 1];
        //build result string
        string memory result = "[";
        result = result.append(expectedBuyOut.toString());
        result = result.append(",");
        //swap from path[0] to path[-1]
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountBuyIn}(0, path, address(this), block.timestamp + 600);
        // try  {

        // } catch {
        //     result = result.append("-1");
        //     result = result.append("]");
        //     require(false, result);
        // }
        uint256 swapOnceToken0Balance = address(this).balance;
        uint256 swapOnceToken1Balance = token1.balanceOf(address(this));
        uint256 realBuyOut = swapOnceToken1Balance - originToken1Balance;
        result = result.append(realBuyOut.toString());
        if (realBuyOut > 0) {
            result = result.append(",");
        } else {
            result = result.append("]");
            require(false, result);
        }

        address[] memory reversedPath = reverseArray(path);
        //calc expected sell amount out
        uint256[] memory amountSellOuts = uniswapV2Router.getAmountsOut(realBuyOut, reversedPath);
        uint256 expectedSellOut = amountSellOuts[amountSellOuts.length - 1];
        result = result.append(expectedSellOut.toString());
        result = result.append(",");
        //swap from path[-1] to path[0]
        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(realBuyOut, 0, reversedPath, address(this), block.timestamp + 600) {

        } catch {
            result = result.append("-1");
            result = result.append("]");
            require(false, result);
        }
        uint256 swapTwiceToken0Balance = address(this).balance;
        uint256 realSellOut = swapTwiceToken0Balance - swapOnceToken0Balance;

        result = result.append(realSellOut.toString());
        result = result.append("]");
        require(false, result);
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        address(_owner).toPayable().transfer(balance);
    }
    
    function withdraw(address tokenAddress, uint256 amount) public onlyOwner{
        IERC20 token = IERC20(tokenAddress);
        token.transfer(_owner, amount);
    }
    
    receive() external payable {
        
    }
}