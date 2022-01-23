/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// helper methods for interacting with BEP20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}
interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
}
interface IPancakeRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
}
interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DustPan is Context, Ownable {
    IPancakeRouter02 immutable Router = IPancakeRouter02(router);
    IPancakeFactory immutable Factory = IPancakeFactory(factory);
    address immutable WBNB;
    address router;
    address factory;
    //fee percent is fee/10000. ex: fee = 500, fee percent = 5%
    uint fee;
    uint maxFee = 1000;
    uint collectedFees;

    constructor(address _router, uint _fee) public {
        WBNB = IPancakeRouter02(_router).WETH();
        router = _router;
        factory = IPancakeRouter02(_router).factory();
        fee = _fee;
        collectedFees = 0;
    }
    

    event routerAddressChanged(address _router);
    event factoryAddressChanged(address _factory);
    event feeChanged(uint _fee);
    event feesCollected(uint _collectedFees);

    receive() external payable {}
    
    function setRouterAddress(address _router) external onlyOwner() {
        router = _router;

        emit routerAddressChanged(_router);
    }

    function setFactoryAddress(address _factory) external onlyOwner() {
        factory = _factory;

        emit factoryAddressChanged(_factory);
    }

    function setFee(uint _fee) external onlyOwner() {
        require(_fee < maxFee, "these fees are too damn high!");
        fee = _fee;

        emit feeChanged(_fee);
    }

    function collectFees() external onlyOwner() {
        TransferHelper.safeTransferBNB(owner(), collectedFees);

        emit feesCollected(collectedFees);
    
        collectedFees = 0;
    }

    //returns the wbnb pair addresses for each token being swapped
    function findPairs(address _token) internal view returns (address) {
        address _pair = Factory.getPair(_token, WBNB);
        require (_pair != address(0), 'pair must exist');

        return _pair;
    }

    function getReserveAmounts(address _pair) internal view returns (uint112, uint112) {
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, ) = IPancakePair(_pair).getReserves();

        return (reserve0, reserve1);
    }

    //returns expected amounts out in wbnb for each token
    function currentTokenValueInWBNB(address _token) internal view returns (uint) {
        address pair = findPairs(_token);
        uint _value;
        uint amountIn = IERC20(_token).balanceOf(_msgSender());
        (uint112 reserve0, uint112 reserve1) = getReserveAmounts(pair);
        _value = Router.getAmountOut(amountIn, reserve0, reserve1);

        return _value;
    }

    function approveSpenders(address _token) internal {
        IERC20(_token).approve(address(this), IERC20(_token).balanceOf(_msgSender()));
        IERC20(_token).approve(router, IERC20(_token).balanceOf(_msgSender()));
    }

    //swaps entire balance of tokens selected for wbnb
    //supply the max slippage required for your trade, take highest token transfer fee + regular slippage
    //ex. if safemoon is your highest fee on transfer token, then 10% + 2% recommended slippage = 12
    function swapDustForBnb(address[] calldata _tokens, uint _maxSlippage) external {
        address[] memory path = new address[](2);
        path[1] = WBNB;
        uint counter = 0;
        uint amountOut = 0;
        uint feesTaken;
        uint amountReturned;
        require (_maxSlippage < 100, 'slippage must be less than 100');

        for (uint i = 0; i < _tokens.length; i++) {
            approveSpenders(_tokens[i]);
            uint value = currentTokenValueInWBNB(_tokens[i]);
            uint amountIn = IERC20(_tokens[i]).balanceOf(_msgSender());
            uint amountOutMin = value * ((100 - _maxSlippage) / 100);

            path[0] = _tokens[i];
            uint[] memory amounts = new uint[](path.length);
            amounts = Router.swapExactTokensForETH(amountIn, amountOutMin, path, address(this), block.timestamp);
            amountOut = amountOut + amounts[amounts.length - 1];
            counter++;
        }

        feesTaken = amountOut * (fee / 10000);
        collectedFees = collectedFees + feesTaken;
        amountReturned = amountOut - feesTaken;
        TransferHelper.safeTransferBNB(_msgSender(), amountReturned);
    }
}