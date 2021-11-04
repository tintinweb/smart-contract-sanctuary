// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./LotterySlave.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILotteryMaster.sol";

contract LotteryMaster is Ownable, ILotteryMaster {
    address public wEth;
    IUniswapV2Router02 public swap;
    mapping (address => bool) public slaves;

    constructor(address routerAddress) {
        swap = IUniswapV2Router02(routerAddress);
        wEth = swap.WETH();
    }

    function _buyToken(uint amount, address tokenAddress, address target) private {
        address[] memory path = new address[](2);
        path[0] = wEth;
        path[1] = tokenAddress;
        require(address(this).balance >= swap.getAmountsIn(amount, path)[0], "need more Eth");
        swap.swapExactETHForTokens{value: amount}(
            0,
            path,
            target,
            block.timestamp + 10 minutes
        );
    }

    function _buyTokenWithFee(uint amount, address tokenAddress, address target, uint fee) private {
        address[] memory path = new address[](2);
        path[0] = wEth;
        path[1] = tokenAddress;
        require(address(this).balance >= swap.getAmountsIn(amount * fee / 100, path)[0], "need more Eth");
        swap.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            target,
            block.timestamp + 10 minutes
        );
    }

    function _sendEth(uint amount, address target) private {
        require(address(this).balance >= amount, "Not enought Eth");
        payable(target).transfer(amount);
    }

    function _sendToken(uint amount, address tokenAddress, address target) private {
        IERC20 itoken = IERC20(tokenAddress);
        require(itoken.balanceOf(address(this)) >= amount, "Not enought token");
        itoken.transfer(target, amount);
    }

    function createNewLottery(address payable lotterySlave, uint initialAmount, address tokenAddress, bool fromEth, uint8 tokenFee) public onlyOwner {
        LotterySlave slave = LotterySlave(lotterySlave);
        require(slave.owner() == address(this), "Master is not the owner");
        if(initialAmount != 0) {
            if(tokenAddress == wEth) {
                _sendEth(initialAmount, lotterySlave);
            }
            else {
                if(fromEth){
                    if(tokenFee > 0) {
                        _buyTokenWithFee(initialAmount, tokenAddress, lotterySlave, tokenFee);
                    }
                    else {
                        _buyToken(initialAmount, tokenAddress, lotterySlave);
                    }
                }
                else {
                    _sendToken(initialAmount, tokenAddress, lotterySlave);
                }
            }
        }
        slaves[lotterySlave] = true;
    }

    function feedSlave(address slaveAddress, uint amount, address tokenAddress) public onlyOwner {
        require(slaves[slaveAddress], "Not an lottery");
        if(tokenAddress == wEth){
            _sendEth(amount, slaveAddress);
        }
        else {
            _sendToken(amount, slaveAddress, tokenAddress);
        }
    }

    function buyToken(uint amount, address tokenAddress, uint tokenFee) public onlyOwner {
        if(tokenFee > 0) {
            _buyTokenWithFee(amount,tokenAddress, address(this), tokenFee);
        }
        else {
            _buyToken(amount,tokenAddress, address(this));
        }
    }

    function sellToken(address tokenAddress, uint amount, uint tokenFee) public onlyOwner {
        address[] memory path = new address[](2);
        path[0] = wEth;
        path[1] = tokenAddress;
        require(address(this).balance >= swap.getAmountsIn(amount, path)[0]);
        if(tokenFee > 0) {
            swap.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp + 10 minutes
            );
        }
        else {
            swap.swapExactTokensForETH(
                amount,
                0,
                path,
                address(this),
                block.timestamp + 10 minutes
            );
        }
    }

    function withdrawFound(address slaveAddress, address tokenAddress) public onlyOwner {
        require(slaves[slaveAddress], "Not a slave");
        ILotterySlave slave = ILotterySlave(slaveAddress);
        if(tokenAddress == wEth){
            slave.emergencyWithdraw();
        }
        else {
            slave.emergencyWithdrawToken(tokenAddress);
        }
        
    }

    function emergencyWithdrawFound(address tokenAddress) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        if(tokenAddress == wEth){
            require(address(this).balance > 0, "No Eth available");
            payable(_msgSender()).transfer(address(this).balance);
        }
        else {
            require(token.balanceOf(address(this)) > 0, "No Token available");
            token.transfer(_msgSender(), token.balanceOf(address(this)));
        }
    }

    function addParticipant(address participantAddress, address payable slaveAddress) public onlyOwner {
        require(slaves[slaveAddress], "Not a lottery");
        LotterySlave slave = LotterySlave(slaveAddress);
        slave.addParticipant(participantAddress);
    }

    function removeParticipant(address participantAddress, address payable slaveAddress) public onlyOwner {
        require(slaves[slaveAddress], "Not a lottery");
        LotterySlave slave = LotterySlave(slaveAddress);
        slave.removeParticipant(participantAddress);
    }

    function lotteryEnd() override public {
        require(slaves[_msgSender()], "Not a lottery");
        slaves[_msgSender()] = false;
    }

    function setRewardLottery(address payable slaveAddress, uint amount) public onlyOwner {
        LotterySlave slave = LotterySlave(slaveAddress);
        slave.setAmountOfReward(amount);
    }

    function setOwnerOfSlave(address slaveAddress) public onlyOwner {
        require(slaves[slaveAddress], "Isnt a slave, Master");
        Ownable slave = Ownable(slaveAddress);
        slave.transferOwnership(_msgSender());
    }

    fallback () external payable {}
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILotteryMaster.sol";
import "./interfaces/ILotterySlave.sol";

abstract contract LotterySlave is Ownable, ILotterySlave {
    address[] internal _participants;
    mapping(address => bool) public isParticipants;
    uint256 public rewardAmount;
    address internal _adminAddress;

    modifier onlyAdmin() {
        require(_msgSender() == owner() || _msgSender() == _adminAddress);
        _;
    }

    modifier onlyParticipant(address participant){
        require(isParticipants[participant], "isnt a participant");
        _;
    }

    modifier notParticipant(address participant) {
        require(!isParticipants[participant], "already a participant");
        _;
    }

    function emergencyWithdrawToken(address tokenAddress) public override onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    function emergencyWithdraw() public onlyOwner override {
        require(address(this).balance > 0, "no more Eth");
        payable(owner()).transfer(address(this).balance);
    }

    function _endLottery() private {
        ILotteryMaster master = ILotteryMaster(owner());
        master.lotteryEnd();
    }

    function _addParticipant(address participantAddress) internal notParticipant(participantAddress) {
        _participants.push(participantAddress);
        isParticipants[participantAddress] = true;
    }

    function _removeParticipant(address participantAddress) internal onlyParticipant(participantAddress) {
        uint index = _participants.length;
        for(uint i = 0; i < _participants.length && index == _participants.length;i++){
            if(_participants[i] == participantAddress){
                index = i;
            }
        }
        _participants[index] = _participants[_participants.length-1];
        _participants.pop();
        isParticipants[participantAddress] = false;
    }

    function isParticipant(address participant) public view override returns(bool) {
        return isParticipants[participant];
    }

    function setAmountOfReward(uint amount) public virtual override onlyAdmin {
        rewardAmount = amount;
    }

    function addParticipant(address participant) public override onlyAdmin {
        require(participant == address(0x0), "Need to be overrided");
        rewardAmount = rewardAmount;
     }

    function removeParticipant(address participant) public override onlyAdmin {
        require(participant == address(0x0), "Need to be overrided");
        rewardAmount = rewardAmount;
    }

    fallback () external payable {}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILotteryMaster {
    function lotteryEnd() external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ILotteryMaster.sol";

interface ILotterySlave {

    function emergencyWithdrawToken(address tokenAddress) external;

    function emergencyWithdraw() external;

    function isParticipant(address participant) external view returns(bool);

    function setAmountOfReward(uint amount) external;

    function addParticipant(address participant) external;

    function removeParticipant(address participant) external;



}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}