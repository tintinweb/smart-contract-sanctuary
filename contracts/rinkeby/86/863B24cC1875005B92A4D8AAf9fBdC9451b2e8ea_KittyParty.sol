// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @author The KittyParty Team
/// @title KittyParty Main Contract
/// @dev This is a POC contract and is unsafe, meant for prototyping only at this stage.


contract KittyParty is Ownable {
    uint256 internal fee;

    struct AddressList {
        address[] array; // An unordered list of unique values
        mapping(address => bool) won;
        address[] possible_winners;
        mapping(address => bool) exists; // Tracks if a given value exists in the list
        mapping(address => uint256) index; // Tracks the index of a value
        mapping(address => uint256) balance; //Tracks the  pendingWithdrawals
    }
    // The member list keeps strack of all the memebers, their respective balances in the kitty party contract.
    // Members include the kittens + kitty kreator
    // The kitty kreator would be the first member in the list
    // The number of rounds in the kitty party hence would be equivalent to number of members - 1

    struct StakeInfo {
        uint256 kreatorSecurity;
        uint256 kittenPool;
        address stakeTokenAddress;
        uint256 noOfStakeTokens;
    }

    enum KittyPartyState {
        Verification,
        Collection,
        Staking,
        Payout,
        Completed,
        Trap
    } //Set of valid states for the kitty party contract
    //Verification: The Pre-Round verification is ongoing
    //Collection: Pre-Round verification completed, collection criteria can be checked for
    //Staking: The colection has been completed successfully, the asset can now be staked on respective protocols
    //Payout: The assets are withdrawn from the repective contracts, a winner is chosen at random
    //Completed: THe kitty-party is over
    //Trap: INVALID STATE!!
    KittyPartyState currentState = KittyPartyState.Verification;
    //initial state is verification state

    bool public initialized = false;

    uint8 public roundDuration; //Duration of round in days
    uint256 public amountPerRound = 0; //Amount of eth to be pooled by the kittens
    uint8 public currentRound = 0; //Counter to keep track of the rounds
    bool public staked = false;
    address public winnerAddress;
    uint256 public amountWon;

    AddressList internal memberList;
    StakeInfo internal stakeDetail;
    
    address internal constant UNISWAP_ROUTER_ADDRESS = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff ;
    address internal constant UNISWAP_WETH_DAI_PAIR_ADDRESS = 0x4A35582a710E1F4b2030A3F826DA20BfB6703C09;
    address internal constant DAI_ADDRESS = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    IUniswapV2Router02 public uniswapRouter;
    IERC20 public dai;
    IERC20 public uni_token;


    event KittenInvited(address indexed kitten, address kitty);
    event Deposit(address indexed _from, uint256 _value);
    event Withdraw(address indexed _to, uint256 _value);
    event Verified(bool verificationState, uint8 indexed roundNumber);
    event Completed(bool completedState);
    event Staked(StakeInfo stakeDetails, uint8 roundNumber);
    event WithdrawnFromStaking(uint256 amount, uint8 roundNumber);
    event LotteryComplete(bytes32 requestId);
    event RoundCompleted(uint8 indexed roundNumber);

    event CollectedFromKitten(
        address indexed kittenAddress,
        uint256 amount,
        uint256 roundNumber
    );
    event LotteryWinner(
        address indexed winner,
        uint256 amountWon,
        uint8 roundNumber
    );


    constructor()
    {
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        dai = IERC20(DAI_ADDRESS);
        uni_token = IERC20(UNISWAP_WETH_DAI_PAIR_ADDRESS);
    }


//get the current status of the rounds
function getStatus() public view returns (KittyPartyState){
    return currentState;
}

//Used to initialize the contract, the minimal info required for the contract to function
// requires a list of member addresses, the first addres in the member list should be the address  of the kitty kreator
// the number of rounds would be memberlist length -1
// amount per round would be the amount per round
    function initialize(address[] memory memberAddress, uint256 _amountPerRound, uint8 _roundDuration) 
        public
    {
        require(initialized == false, "Already Initialized");
        for (uint256 i = 0; i < memberAddress.length; i++) {
            inviteKitten(memberAddress[i]);
        }
        amountPerRound = _amountPerRound;
        roundDuration = _roundDuration;
        initialized = true;
    }

    function inviteKitten(address value) public returns (bool success) {
        // Only add 'value' if it does not exist in the list
        if (memberList.exists[value]) return false;
  
        memberList.index[value] = memberList.array.length;
        memberList.exists[value] = true;
        memberList.array.push(value);
        memberList.possible_winners.push(value);
        memberList.balance[value] = 0;

        return true;
    }

    function getList() public view returns (address[] memory) {
        return memberList.array;
    }

    function getLength() public view returns (uint8) {
        return uint8(memberList.array.length - 1);
    }

    function getValueAt(uint256 i) public view returns (address) {
        return memberList.array[i];
    }

    function getIndex(address ad) public view returns (uint256) {
        return memberList.index[ad];
    }

    function isKittyKreator(address candidateKreator) public view  returns (bool) {
        if(
            getValueAt(0) == candidateKreator
            ) return true;
            return false;
    }

    function isKittyPartyActive() public view  returns (bool) {
        if (
            currentState == KittyPartyState.Trap ||
            currentState == KittyPartyState.Completed
        ) return false;
        return true;
    }
    
    function deposit() public payable {
        require(
            memberList.exists[msg.sender],
            "User not registered with the kitty party contract, kindly check with your kitty kreator"
        ); 
        memberList.balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function depositAmount(uint256 amount) public payable {
        require(
            memberList.exists[msg.sender],
            "User not registered with the kitty party contract, kindly check with your kitty kreator"
        );
        memberList.balance[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function depositAmountOnBehalfOfKitten(uint256 amount, address kitten) public payable {        
        require(
            isKittyKreator(msg.sender),
            "You need to be the kitty kreator to deposit on behalf of a kitten"
        );
        memberList.balance[kitten] += amount;
        emit Deposit(kitten, amount);
    }

    function withdraw(uint256 amount) public {
        uint256 currentBalance = memberList.balance[msg.sender];
        require(amount <= currentBalance, "Insufficient Balance");
        memberList.balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function withdrawAll() public {
        uint256 currentBalance = memberList.balance[msg.sender];
        memberList.balance[msg.sender] = 0;
        payable(msg.sender).transfer(currentBalance);
        emit Withdraw(msg.sender, currentBalance);
    }
    
    function completeKittyParty() public {
        currentState = KittyPartyState.Completed;
    }

    function verify() public {
        require(
            memberList.balance[getValueAt(0)] >= amountPerRound,
            "Insufficient Funds, kindly top up the smart contract"
        );
        require(isKittyPartyActive(), "Kitty Party is not Active");
        if (currentRound == getLength()) {
            completeKittyParty();
        }
        currentState = KittyPartyState.Collection;
        emit Verified(true, currentRound);
    }

    function collectFromKittens() public returns (uint256 amountCollected) {
        uint256 amountToBeCollectedFromKitten =
            amountPerRound / getLength();
        for (uint256 i = 1; i <= getLength(); i++) {
            address kittenAddress = getValueAt(i);
            if (
                memberList.balance[kittenAddress] >=
                amountToBeCollectedFromKitten
            ) {
                amountCollected += amountToBeCollectedFromKitten;
                memberList.balance[
                    kittenAddress
                ] -= amountToBeCollectedFromKitten;
                emit CollectedFromKitten(
                    kittenAddress,
                    amountCollected,
                    currentRound
                );
            } else {
                amountCollected += memberList.balance[kittenAddress];
                memberList.balance[kittenAddress] = 0;
                emit CollectedFromKitten(
                    kittenAddress,
                    amountCollected,
                    currentRound
                );
            }
        }
        return amountCollected;
    }

    function collection() public {
        require(
            currentState == KittyPartyState.Collection,
            "Not in collection state"
        );
        stakeDetail.kittenPool = amountPerRound;
        stakeDetail.kreatorSecurity = collectFromKittens();
        stakeDetail.stakeTokenAddress = UNISWAP_WETH_DAI_PAIR_ADDRESS;
        memberList.balance[getValueAt(0)] = memberList.balance[getValueAt(0)] - amountPerRound;
        stakeDetail.noOfStakeTokens = addLiquidityFromEth(stakeDetail.kittenPool + stakeDetail.kreatorSecurity);
        emit Staked(stakeDetail, currentRound);
        currentState = KittyPartyState.Staking;
        staked = true;
    }

    function withdrawFromStaking() public {
        //call the lp contract, transfer the asset back to address(this)
        amountWon = removeLiquidityFromEth(stakeDetail.noOfStakeTokens);
        staked = false;
        //sendToPlatform
        emit WithdrawnFromStaking(amountWon, currentRound);
        if (stakeDetail.kittenPool > stakeDetail.kreatorSecurity) {
            //send .02*amountPerRound to platform
        } else {
            memberList.balance[getValueAt(0)] = 102 * amountPerRound/100;
        }
        amountWon -= 102 * amountPerRound/100;
        currentState = KittyPartyState.Payout;
        runLottery(block.timestamp);
    }

    function completeRound() internal {
        emit RoundCompleted(currentRound);
        currentRound += 1;
    }

    function sendMoneyToWinner() public {
        memberList.balance[winnerAddress] += amountWon;
        memberList.won[winnerAddress] = true;
        delete memberList.possible_winners[getIndex(winnerAddress)];
        emit LotteryWinner(winnerAddress, amountWon, currentRound);
        completeRound();
    }

    function runLottery(uint256 userProvidedSeed)
        public
        returns (bool success)
    {
        uint256 randomness = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, userProvidedSeed)));
        uint256 winnerPoolLength = getLength() - currentRound;
        uint256 randomResult = (randomness % winnerPoolLength) + 1;
        winnerAddress = memberList.possible_winners[randomResult];
        return true;
    }
    
    function getBalance(address ad) public view returns(uint256){
        return memberList.balance[ad];
    }
    
    function addLiquidityFromEth(uint ethAmountIn) public returns(uint) {
        uint ethAmount = ethAmountIn/2;
        uint daiAmount = convertEthToDai(ethAmount);
        require(dai.approve(address(uniswapRouter), daiAmount), 'approve failed.');
        uint amountToken;
        uint amountETH;
        uint liquidity;
        (amountToken, amountETH, liquidity) = uniswapRouter.addLiquidityETH{value: ethAmount}(DAI_ADDRESS, daiAmount,
        daiAmount - 5000000000000000, ethAmount - 100000000000000, address(this), block.timestamp + 15);
        return liquidity;
    }
    
    // TODO: amountTokenMin, amountETHMin, and find a way to keep track of Uni tokens per account
    // Automatically sends back ETH to user
    function removeLiquidityFromEth(uint uniAmountOut) public returns(uint) {
        require(uni_token.approve(address(uniswapRouter), uniAmountOut), 'approve failed.');
        uint amountDai;
        uint amountEth;
        (amountDai, amountEth) = uniswapRouter.removeLiquidityETH(DAI_ADDRESS, uniAmountOut, 0, 0, address(this), block.timestamp + 15);
        amountEth += convertDaiToEth(amountDai);
        // msg.sender.transfer(amountEth);
        return amountEth;
    }
    
    // Assumes that contract already has Dai
    function addLiquidityFromDai(uint daiAmountIn) public {
        uint daiAmount = daiAmountIn/2;
        uint ethAmount = convertDaiToEth(daiAmount);
        require(dai.approve(address(uniswapRouter), daiAmount), 'approve failed.');
        uniswapRouter.addLiquidityETH{ value: ethAmount }(DAI_ADDRESS, daiAmount,
        daiAmount - 5000000000000000, ethAmount, address(this), block.timestamp + 15);
    }
    
    // TODO: amountTokenMin, amountETHMin, and find a way to keep track of Uni tokens per account
    // NOTE: Does NOT automatically send back DAI to user
    function removeLiquidityFromDai(uint uniAmountOut) public {
        require(uni_token.approve(address(uniswapRouter), uniAmountOut), 'approve failed.');
        uint amountDai;
        uint amountEth;
        (amountDai, amountEth) = uniswapRouter.removeLiquidityETH(DAI_ADDRESS, uniAmountOut, 0, 0, address(this), block.timestamp + 15);
        amountDai += convertEthToDai(amountEth);
    }
    
    function convertDaiToEth(uint daiAmount) private returns(uint) {
        // amountOutMin must be retrieved from an oracle of some kind
        uint amountOutMin = getEstimatedETHforDAI(daiAmount)[1];
        require(dai.approve(address(uniswapRouter), daiAmount), 'approve failed.');
        uniswapRouter.swapExactTokensForETH(daiAmount, amountOutMin, getPathForDAItoETH(), address(this), block.timestamp);
        return amountOutMin;
    }
    
    function convertEthToDai(uint ethAmount) private returns(uint) {
        uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        uint amountDai = getEstimatedDAIforETH(ethAmount)[1];
        uniswapRouter.swapETHForExactTokens{ value: ethAmount }(amountDai, getPathForETHtoDAI(), address(this), deadline);
        return amountDai;
        // refund leftover ETH to user
        // (bool success,) = msg.sender.call{ value: address(this).balance }("");
        // require(success, "refund failed");
    }
    
    function getEstimatedETHforDAI(uint daiAmount) public view returns (uint[] memory) {
        return uniswapRouter.getAmountsOut(daiAmount, getPathForDAItoETH());
    }
    
    function getEstimatedDAIforETH(uint ethAmount) public view returns (uint[] memory) {
        return uniswapRouter.getAmountsOut(ethAmount, getPathForETHtoDAI());
    }

    function getPathForETHtoDAI() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = address(DAI_ADDRESS);
        return path;
    }
    
    function getPathForDAItoETH() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(DAI_ADDRESS);
        path[1] = uniswapRouter.WETH();
        return path;
    }
    
    function checkDaiBalance() public view returns (uint256) {
         return dai.balanceOf(address(this));
    }
    
    function checkUniBalance() public view returns (uint256) {
         return uni_token.balanceOf(address(this));
    }
    
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

