// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
interface iCHI {
    function freeFromUpTo(address from, uint256 value) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface ICoreFlashArb {
      struct Strategy {
        string strategyName;
        bool[] token0Out; // An array saying if token 0 should be out in this step
        address[] pairs; // Array of pair addresses
        uint256[] feeOnTransfers; //Array of fee on transfers 1% = 10
        bool cBTCSupport; // Should the algorithm check for cBTC and wrap/unwrap it
                        // Note not checking saves gas
        bool feeOff; // Allows for adding CORE strategies - where there is no fee on the executor
    }
  function executeStrategy ( uint256 strategyPID ) external;
  function numberOfStrategies (  ) external view returns ( uint256 );
  function strategyProfitInReturnToken ( uint256 strategyID ) external view returns ( uint256 profit );
  function strategyInfo(uint256 strategyPID) external view returns (Strategy memory);
  function mostProfitableStrategyInETH (  ) external view returns ( uint256 profit, uint256 strategyID );
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
interface IKeep3rV1Mini {
    function isKeeper(address) external returns (bool);
    function worked(address keeper) external;
    function totalBonded() external view returns (uint);
    function bonds(address keeper, address credit) external view returns (uint);
    function votes(address keeper) external view returns (uint);
    function isMinKeeper(address keeper, uint minBond, uint earned, uint age) external returns (bool);
    function addCreditETH(address job) external payable;
    function workedETH(address keeper) external;
    function credits(address job, address credit) external view returns (uint);
    function receipt(address credit, address keeper, uint amount) external;
    function ETH() external view returns (address);
    function receiptETH(address keeper, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
//Import OpenZepplin libs
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

//Import job interfaces and helper interfaces
import '../interfaces/Keep3r/IKeep3rV1Mini.sol';
import '../interfaces/ICoreFlashArb.sol';
import "../interfaces/IChi.sol";

//Import Uniswap interfaces
import '../interfaces/Uniswap/IUniswapV2Pair.sol';


contract CoreFlashArbRelayerV2 is Ownable{

    //Custom upkeep modifer with CHI support
    modifier upkeep() {
        uint256 gasStart = gasleft();
        require(RLR.isKeeper(msg.sender), "!relayer");
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        CHI.freeFromUpTo(address(this), (gasSpent + 14154) / 41947);
        //Payout RLR
        RLR.worked(msg.sender);
    }

    IKeep3rV1Mini public RLR;
    ICoreFlashArb public CoreArb;
    iCHI public CHI = iCHI(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    //Init interfaces with addresses
    constructor (address token,address corearb) public {
        RLR = IKeep3rV1Mini(token);
        CoreArb = ICoreFlashArb(corearb);
    }

    //Helper functions for handling sending of reward token
    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function sendERC20(address tokenAddress,address receiver) internal {
        IERC20(tokenAddress).transfer(receiver, getTokenBalance(tokenAddress));
    }

    //Required cause coreflasharb contract doesnt make this easily retrievable
    function getRewardToken(uint strat) public view returns (address) {
        ICoreFlashArb.Strategy memory stratx = CoreArb.strategyInfo(strat);//Get full strat data
        // Eg. Token 0 was out so profit token is token 1
        return stratx.token0Out[0] ? IUniswapV2Pair(stratx.pairs[0]).token1() : IUniswapV2Pair(stratx.pairs[0]).token0();
    }

    //Set new contract address incase core devs change the flash arb contract
    function setCoreArbAddress(address newContract) public onlyOwner {
        CoreArb = ICoreFlashArb(newContract);
    }

    function workable() public view returns (bool) {
        for(uint i=0;i<CoreArb.numberOfStrategies();i++){
            if(CoreArb.strategyProfitInReturnToken(i) > 0)
                return true;
        }
    }

    function profitableCount() public view returns (uint){
        uint count = 0;
        for(uint i=0;i<CoreArb.numberOfStrategies();i++){
            if(CoreArb.strategyProfitInReturnToken(i) > 0)
                count++;
        }
        return count;
    }

    //Return profitable strats array and reward tokens
    function profitableStratsWithTokens() public view returns (uint[] memory,address[] memory){
        uint profitableCountL = profitableCount();
        uint index = 0;

        uint[] memory _profitable = new uint[](profitableCountL);
        address[] memory _rewardToken = new address[](profitableCountL);

        for(uint i=0;i<CoreArb.numberOfStrategies();i++){
            if(CoreArb.strategyProfitInReturnToken(i) > 0){
                _profitable[index] = i;
                _rewardToken[index] = getRewardToken(i);
                index++;
            }

        }
        return (_profitable,_rewardToken);
    }

    function hasMostProfitableStrat() public view returns (bool) {
        (uint256 profit, ) = CoreArb.mostProfitableStrategyInETH();
        return profit > 0;
    }

    function getMostProfitableStrat() public view returns (uint){
        //Get data from interface on profit and strat id
        (, uint256 strategyID) = CoreArb.mostProfitableStrategyInETH();
        return strategyID;
    }

    function getMostProfitableStratWithToken() public view returns (uint,address){
        //Get data from interface on profit and strat id
        (, uint256 strategyID) = CoreArb.mostProfitableStrategyInETH();
        return (strategyID,getRewardToken(strategyID));
    }

    //Used to execute multiple profitable strategies,only use when there are multiple executable strats
    function workBatch(uint[] memory profitable,address[] memory rewardTokens) public upkeep{
        //No need to check for profitablility here as it wont execute if arb isnt profitable
        for(uint i=0;i<profitable.length;i++){
            CoreArb.executeStrategy(profitable[i]);
            //Send strat reward to executor
            sendERC20(rewardTokens[i],msg.sender);
        }
    }

    //Execute single profitable strat
    function work(uint strat,address rewardToken) public upkeep{
        //No need to check for profitablility here as it wont execute if arb isnt profitable
        CoreArb.executeStrategy(strat);
        //Send strat reward to executor
        sendERC20(rewardToken,msg.sender);
    }

    //Added to recover erc20 tokens
    function recoverERC20(address token) public onlyOwner {
        sendERC20(token,owner());
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

