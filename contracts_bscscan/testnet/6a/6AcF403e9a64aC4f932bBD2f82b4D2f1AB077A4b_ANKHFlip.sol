// SPDX-License-Identifier: MIT



pragma solidity ^0.8.6;


//////////////////////////// INTERFACES ////////////////////////////
import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IANKH.sol";
import "./interfaces/IANKHD.sol";
//////////////////////////// INTERFACES ////////////////////////////


//////////////////////////// UTILITIES ////////////////////////////
import "./Context.sol";
//////////////////////////// UTILITIES ////////////////////////////


//////////////////////////// LIBRARIES ////////////////////////////
import "./utilities/SafeMath.sol";
import "./utilities/SafeERC20.sol";
import "./utilities/Address.sol";
//////////////////////////// LIBRARIES ////////////////////////////



contract ANKHFlip is Context {



    //////////////////////////// USING STATEMENTS ////////////////////////////
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    //////////////////////////// USING STATEMENTS ////////////////////////////


    //////////////////////////// INFO VARS ////////////////////////////  
    string public nameOfContract = "ANKH Flip";
    uint256 public deployDateUnixTimeStamp = block.timestamp;  // sets the deploy timestamp
    //////////////////////////// INFO VARS ////////////////////////////  



    //////////////////////////// ANKH VARS ////////////////////////////  
    address public ankhContractAddress = 0x8dfC34B0808F45d3486B32F38396C89A21299f03;       // CHANGEIT - set the right contract address
    IERC20 private ankhContractAddressIERC20 = IERC20(ankhContractAddress);
    IANKH private ankhContractAddressIANKH = IANKH(ankhContractAddress);
    //////////////////////////// ANKH VARS ////////////////////////////  
    

    

    //////////////////////////// ACCESS CONTROL ////////////////////////////  
    address public directorAccount = 0x8C7Ad6F014B46549875deAD0f69919d643a50bA3;       // CHANGEIT - Make sure you have the right Director Address
    //////////////////////////// ACCESS CONTROL ////////////////////////////  


    //////////////////////////// DEAD ADDR VARS ////////////////////////////
    address private deadAddressZero = 0x0000000000000000000000000000000000000000; 
    address private deadAddressOne = 0x0000000000000000000000000000000000000001; 
    address private deadAddressdEaD = 0x000000000000000000000000000000000000dEaD;
    //////////////////////////// DEAD ADDR VARS ////////////////////////////



    //////////////////////////// ANKH FLIP VARS ////////////////////////////
    // address public depositWallet = ankhContractAddressIANKH.depositWallet();
    address public depositWallet = 0x7777777777777777777777777777777777777777;  // CHANGEIT - make sure you have the right deposit address
    
    uint256 public maxBetAmount = ankhContractAddressIERC20.totalSupply().div(100000);   // 0.001%
    uint256 public minBetAmount = ankhContractAddressIERC20.totalSupply().div(10**15);   // set to 1 ANKH

    uint256 private randomNumberCounter = 1243;       // CHANGEIT - make it something else at the start


    mapping(address => uint256) private flipWinStreak;
    mapping(address => uint256) private flipLossStreak;
    mapping(address => uint256) private flipTotalWins;
    mapping(address => uint256) private flipTotalLosses;
    mapping(address => bool) private winRecentFlip;

    mapping(address => bool) public isBannedFromAnkhFlipForManipulation;
    mapping(address => uint256) private lastBlockFlippedAnkh;

    bool public isFlipAnkhEnabled = true;

    mapping(address => bool) public isPlayingGame;      // reentrancy
    //////////////////////////// ANKH FLIP VARS ////////////////////////////




    //////////////////////////// EVENTS ////////////////////////////
    event BannedAccountFromAnkhFlipForManipulation(address indexed flipperAddress, uint256 timeOfBan, bool isBanned);
    //////////////////////////// EVENTS ////////////////////////////





    //////////////////////////// ACCESS CONTROL ////////////////////////////
    modifier OnlyDirector() {   // The director is the multisig
        require(_msgSender() == directorAccount, "Caller is not a Director");  
        _;      
    }

    function TransferDirectorAccount(address newDirector) external OnlyDirector()  {   
        directorAccount = newDirector;
    }
    //////////////////////////// ACCESS CONTROL ////////////////////////////













    


    //////////////////////////// ANKH FLIP FUNCTIONS ////////////////////////////

    function SetRandomNumber(uint256 newNum) external OnlyDirector() {
        randomNumberCounter = newNum; 
        randomNumberCounter = randomNumberCounter.add(ankhContractAddressIANKH.randomNumberForGamesViewable());
    }

    function SetMaxBetAmount(uint256 newMaxBetAmount) external OnlyDirector() {
        maxBetAmount = newMaxBetAmount; 
        randomNumberCounter = randomNumberCounter.add(2); 
        randomNumberCounter = randomNumberCounter.add(ankhContractAddressIANKH.randomNumberForGamesViewable());
    }

    function SetMinBetAmount(uint256 newMinBetAmount) external OnlyDirector() {
        minBetAmount = newMinBetAmount; 
        randomNumberCounter = randomNumberCounter.add(3); 
        randomNumberCounter = randomNumberCounter.add(ankhContractAddressIANKH.randomNumberForGamesViewable());
    }

    function enableOrDisableFlipAnkh(bool isEnabled) external OnlyDirector() {
        isFlipAnkhEnabled = isEnabled; 
        randomNumberCounter = randomNumberCounter.add(4); 
        randomNumberCounter = randomNumberCounter.add(ankhContractAddressIANKH.randomNumberForGamesViewable());
    }



    function SetBannedFromAnkhFlipForManipulation(address addressToBanOrUnBan, bool isBanned) external OnlyDirector() {
        isBannedFromAnkhFlipForManipulation[addressToBanOrUnBan] = isBanned; 
        emit BannedAccountFromAnkhFlipForManipulation(addressToBanOrUnBan, GetCurrentBlockTimeStamp(), isBanned);
    }


    function GetFlipLossStreak(address addressToCheck) public view returns(uint256) {
        return flipLossStreak[addressToCheck];
    }

    function GetFlipWinStreak(address addressToCheck) public view returns(uint256) {
        return flipWinStreak[addressToCheck];
    }


    function GetFlipTotalLosses(address addressToCheck) public view returns(uint256) {
        return flipTotalLosses[addressToCheck];
    }

    function GetFlipTotalWins(address addressToCheck) public view returns(uint256) {
        return flipTotalWins[addressToCheck];
    }



    function GetFlipWin(address addressToCheck) public view returns(bool) {
        return winRecentFlip[addressToCheck];
    }



    function FlipAnkh(uint256 betAmount, bool isHeads) external {

        require(isFlipAnkhEnabled, "Flip Ankh must be enabled.");

        address flipperAddress = _msgSender();

        require(!isPlayingGame[flipperAddress], "You are already playing the game in this transaction.");
        isPlayingGame[flipperAddress] = true;

        randomNumberCounter = randomNumberCounter.add(1);
        
        if(randomNumberCounter >= 100000000000000000000000000000000000000000000000000000000000){      
            randomNumberCounter = randomNumberCounter.div(6);
        }

        uint256 lastBlockFlippedAnkhResult = lastBlockFlippedAnkh[flipperAddress];
        lastBlockFlippedAnkh[flipperAddress] = block.number;
        require(lastBlockFlippedAnkhResult != block.number,"You can only play once per block, please wait a little bit to play again. Thank you.");

        require(betAmount > 0, "Bet amount must be greater than 0");
        require(betAmount >= minBetAmount, "Bet amount must be greater than the Minimum, check variable minBetAmount.");
        require(betAmount <= maxBetAmount, "Bet amount must be less than the Maximum, check variable maxBetAmount.");

        uint256 depositAmountTotal = ankhContractAddressIANKH.GetDepositAmountTotal(flipperAddress);

        require(depositAmountTotal > 0, "You have no deposit, please deposit more ANKH");
        require(depositAmountTotal >= betAmount, "You do not have enough ANKH in the Deposit, please deposit more ANKH");

        // cant do this because of gas estimation issues
        // ankhContractAddressIANKH.DecreaseDepositAmountTotal(betAmount, flipperAddress); // need this here because of reentrancy      

        require(!isBannedFromAnkhFlipForManipulation[flipperAddress], "You need to appeal your ban from Ankh Flip. You may have been caught manipulating the system in some way. Please appeal in Telegram or Discord.");
        require(!ankhContractAddressIANKH.isBannedFromAllGamesForManipulation(flipperAddress), "You need to appeal your ban from all games. You may have been caught manipulating the system in some way. Please appeal in Telegram or Discord.");

        // don't uncomment... moved elsewhere
        randomNumberCounter = randomNumberCounter.add(ankhContractAddressIANKH.randomNumberForGamesViewable());

        uint256 headsOrTails = GetHeadsOrTails();
        bool isResultHeads = false; 
        if(headsOrTails == 0){
            isResultHeads = true;
        }

        randomNumberCounter = randomNumberCounter.add(905430957430);  



        if(isHeads == isResultHeads){   // win
            // randomNumberCounter = randomNumberCounter.add(777);

            flipWinStreak[flipperAddress] = flipWinStreak[flipperAddress].add(1);
            if(flipWinStreak[flipperAddress] >= 10){
                // manipulation detected, ban them, manually remove ban if appealed.
                isBannedFromAnkhFlipForManipulation[flipperAddress] = true;
                emit BannedAccountFromAnkhFlipForManipulation(flipperAddress, GetCurrentBlockTimeStamp(), true);
            }

            flipLossStreak[flipperAddress] = 0;
            flipTotalWins[flipperAddress] = flipTotalWins[flipperAddress].add(1);
            
            ankhContractAddressIANKH.IncreaseTotalWinStreak(flipperAddress);

            ankhContractAddressIANKH.IncreaseDepositAmountTotal(betAmount, flipperAddress);

            winRecentFlip[flipperAddress] = true;
        }
        else{   // lose
            // randomNumberCounter = randomNumberCounter.add(4);

            flipLossStreak[flipperAddress] = flipLossStreak[flipperAddress].add(1);
            flipWinStreak[flipperAddress] = 0;
            flipTotalLosses[flipperAddress] = flipTotalLosses[flipperAddress].add(1);

            ankhContractAddressIANKH.IncreaseTotalLossStreak(flipperAddress);

            // can't do this because of gas issues. moved the decrease function to before, so it takes the deposit as you play
            ankhContractAddressIANKH.DecreaseDepositAmountTotal(betAmount, flipperAddress); 

            winRecentFlip[flipperAddress] = false;
        }


        isPlayingGame[flipperAddress] = false;

    }


    // // TODO - Remove this is a test version
    // function FlipAnkhTest(bool isHeads) external {

    //     require(isFlipAnkhEnabled, "Flip Ankh must be enabled.");

    //     address flipperAddress = _msgSender();

    //     require(!isPlayingGame[flipperAddress], "You are already playing the game in this transaction.");
    //     isPlayingGame[flipperAddress] = true;

    //     randomNumberCounter = randomNumberCounter.add(1);
        
    //     if(randomNumberCounter >= 100000000000000000000000000000000000000000000000000000000000){      
    //         randomNumberCounter = randomNumberCounter.div(6);
    //     }

    //     uint256 lastBlockFlippedAnkhResult = lastBlockFlippedAnkh[flipperAddress];
    //     lastBlockFlippedAnkh[flipperAddress] = block.number;
    //     require(lastBlockFlippedAnkhResult != block.number,"You can only play once per block, please wait a little bit to play again. Thank you.");


    //     // randomNumberCounter = randomNumberCounter.add(ankhContractAddressIANKH.randomNumberForGamesViewable());

    //     uint256 headsOrTails = GetHeadsOrTails();
    //     bool isResultHeads = false; 
    //     if(headsOrTails == 0){
    //         isResultHeads = true;
    //     }

    //     // randomNumberCounter = randomNumberCounter.add(905430957430);  
    //     randomNumberCounter = randomNumberCounter.add(905430953437430);  


    //     // randomNumberCounter = (randomNumberCounter.mul(randomNumberCounter).mul(7).add(block.number)).mod(175230);    


    //     // randomNumberCounter = randomNumberCounter.add(3);    

        

    //     if(isHeads == isResultHeads){   // win
    //         // randomNumberCounter = randomNumberCounter.add(777);

    //         flipWinStreak[flipperAddress] = flipWinStreak[flipperAddress].add(1);
    //         if(flipWinStreak[flipperAddress] >= 10){
    //             // manipulation detected, ban them, manually remove ban if appealed.
    //             isBannedFromAnkhFlipForManipulation[flipperAddress] = true;
    //             emit BannedAccountFromAnkhFlipForManipulation(flipperAddress, GetCurrentBlockTimeStamp(), true);
    //         }

    //         flipLossStreak[flipperAddress] = 0;
    //         flipTotalWins[flipperAddress] = flipTotalWins[flipperAddress].add(1);
        

    //         winRecentFlip[flipperAddress] = true;
    //     }
    //     else{   // lose
    //         // randomNumberCounter = randomNumberCounter.add(4);

    //         flipLossStreak[flipperAddress] = flipLossStreak[flipperAddress].add(1);
    //         flipWinStreak[flipperAddress] = 0;
    //         flipTotalLosses[flipperAddress] = flipTotalLosses[flipperAddress].add(1);



    //         winRecentFlip[flipperAddress] = false;
    //     }


    //     isPlayingGame[flipperAddress] = false;

    // }


    // // // TODO - remove 
    // function GetRandomNumber() public view returns (uint256) {
    //     return randomNumberCounter;
    // }


    // // TODO - remove 
    // function GetBalanceOfDepositWallet() public view returns (uint256) {
    //     return ankhContractAddressIERC20.balanceOf(depositWallet);
    // // }


    // // TODO - remove 
    // function GetValueKek() public view returns (uint256) {
    //     uint256 headsOrTails = 2;

    //     uint256 addedUpNumbers = block.number.add(block.timestamp).add(randomNumberCounter).add(ankhContractAddressIERC20.balanceOf(depositWallet));
    //     addedUpNumbers = addedUpNumbers.mod(headsOrTails);
    //     return addedUpNumbers;

    //     // uint256 theAmountFirst = uint256(keccak256(abi.encodePacked(block.timestamp, randomNumberCounter, randomNumberCounter+3))).mod(firstdv);
    //     // return theAmountFirst.mod(headsOrTails);
    //     // return uint256(keccak256(abi.encodePacked(block.number, block.timestamp, randomNumberCounter))).mod(headsOrTails);
    //     // return uint256(keccak256(abi.encodePacked(block.number, block.timestamp, randomNumberCounter, 
    //     //     ankhContractAddressIERC20.balanceOf(depositWallet)))).mod(headsOrTails);
    // }





    function GetHeadsOrTails() internal view returns (uint256) {
        uint256 headsOrTails = 2;
        uint256 addedUpNumbers = (block.number.div(2)).mul(block.timestamp.div(7)).add(randomNumberCounter);
        // uint256 addedUpNumbers = block.number.add(block.timestamp).add(randomNumberCounter).add(ankhContractAddressIERC20.balanceOf(depositWallet));
        addedUpNumbers = addedUpNumbers.mod(headsOrTails);
        return addedUpNumbers;

        // return uint256(keccak256(abi.encodePacked(block.number, block.timestamp, randomNumberCounter, 
        //     ankhContractAddressIERC20.balanceOf(depositWallet)))).mod(headsOrTails);
        // return uint256(keccak256(abi.encodePacked(block.number, block.timestamp, randomNumberCounter))).mod(headsOrTails);
    }

    //     // // TODO - remove this for safety reasons
    // function GetHeadsOrTailsTest() public view returns (uint256) {
    //     return GetHeadsOrTails();
    // }


    // // TODO - remove this for safety reasons
    // function GetHeadsOrTailsTest() public view returns (uint256) {
    //     uint256 headsOrTails = 2;
    //     uint256 addedUpNumbers = block.number.add(block.timestamp).add(randomNumberCounter).add(ankhContractAddressIERC20.balanceOf(depositWallet));
    //     addedUpNumbers = addedUpNumbers.mod(headsOrTails);
    //     return addedUpNumbers;

    //     // return uint256(keccak256(abi.encodePacked(block.number, block.timestamp, randomNumberCounter, 
    //     //     ankhContractAddressIERC20.balanceOf(depositWallet)))).mod(headsOrTails);
    //     // return uint256(keccak256(abi.encodePacked(block.number, block.timestamp, randomNumberCounter))).mod(headsOrTails);
    // }





    function SetDepositAddress(address newAddress) external OnlyDirector() {
        depositWallet = newAddress;
    }

    function SetANKHAddress(address newAddress) external OnlyDirector() {
        address ankhContractAddressAgain = newAddress; 
        IANKHD ankhContractAddressIANKHD = IANKHD(ankhContractAddressAgain);
        randomNumberCounter = ankhContractAddressIANKHD.ADJFKLSDNLKDASGAUJKLSDJFLAK(); 
    }

    


    //////////////////////////// ANKH FLIP FUNCTIONS ////////////////////////////










    //////////////////////////// UTILITY FUNCTIONS ////////////////////////////
    function PayableMsgSenderAddress() private view returns (address payable) {   // gets the sender of the payable address, makes sure it is an address format too
        address payable payableMsgSender = payable(address(_msgSender()));      
        return payableMsgSender;
    }

    function GetCurrentBlockTimeStamp() public view returns (uint256) {
        return block.timestamp;    
    }
    //////////////////////////// UTILITY FUNCTIONS ////////////////////////////


    //////////////////////////// RESCUE FUNCTIONS ////////////////////////////
    function RescueAllBNBSentToContractAddress() external OnlyDirector()  {   
        PayableMsgSenderAddress().transfer(address(this).balance);
        randomNumberCounter = randomNumberCounter.add(9);
    }

    function RescueAmountBNBSentToContractAddress(uint256 amount) external OnlyDirector()  {   
        PayableMsgSenderAddress().transfer(amount);
        randomNumberCounter = randomNumberCounter.add(8);
    }

    function RescueAllTokenSentToContractAddress(IERC20 tokenToWithdraw) external OnlyDirector() {
        tokenToWithdraw.safeTransfer(PayableMsgSenderAddress(), tokenToWithdraw.balanceOf(address(this)));
        randomNumberCounter = randomNumberCounter.add(2);
    }

    function RescueAmountTokenSentToContractAddress(IERC20 tokenToWithdraw, uint256 amount) external OnlyDirector() {
        tokenToWithdraw.safeTransfer(PayableMsgSenderAddress(), amount);
        randomNumberCounter = randomNumberCounter.add(3);
    }
    //////////////////////////// RESCUE FUNCTIONS ////////////////////////////

    






    receive() external payable {}       // Oh it's payable alright.
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


interface IANKH {

    function totalSupply() external view returns (uint256);

    function ankhContractAddress() external view returns (address);

    function routerAddressForDEX() external view returns (address);
    function koffeeSwapPair() external view returns (address);
    
    function isBannedFromAllGamesForManipulation(address) external view returns (bool);


    function depositWallet() external view returns (address);
    function GetDepositAmountTotal(address) external view returns (uint256);


    function IncreaseDepositAmountTotal(uint256, address) external;
    function DecreaseDepositAmountTotal(uint256, address) external;
    function IncreaseTotalWinStreak(address) external;
    function IncreaseTotalLossStreak(address) external;

    function randomNumberForGamesViewable() external view returns (uint256);

    function directorAccount() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


interface IANKHD {
    function ADJFKLSDNLKDASGAUJKLSDJFLAK() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

