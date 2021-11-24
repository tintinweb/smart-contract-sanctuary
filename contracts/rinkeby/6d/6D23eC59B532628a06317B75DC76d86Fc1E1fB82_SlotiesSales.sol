// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface SlotiesNFT {
    function mintTo(uint256, address) external;
}

contract SlotiesSales is Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32; 

    SlotiesNFT public slotiesNFT;

    /**
        Numbers for SlotiesNFT
     */
    uint256 public constant maxSloties = 200; // 9500

    /**
        Team withdraw fund
     */
    // claimed
    bool internal claimed = false;

    /**
        Pre sale
     */
    address private preSaleAddress;
    mapping(address => uint256) public preSaleAddressToNonce;

    uint256 public constant maxPreSaleSupply = 5; // 2500
    uint256 public maxPreSaleWinnable = 5;
    uint256 public constant preSaleMaxTickets = 3; 
    uint256 public constant preSaleTicketPrice = 0.000008 ether; // 0.08 ether    

    uint256 public totalPreSaleTickets = 0;
    mapping(address => ticket) public preSaleTicketsOf;
    mapping(address => bool) public ticketGuaranteed;

    /**
        Giveaway
     */
    mapping(address => bool) public giveAwayClaimed;

    /**
        Scheduling
     */
    uint256 public preSaleStart = 1638903600; // 1638903600 7 DEC 19PM UTC
    uint256 public constant preSaleDuration = 3600 * 6; // 6 hours
    uint256 public constant saleStartOffset = 3600 * 24; // 24 hours
    bool public saleClosed = false;

    /**
        Ticket
     */
    uint256 public constant ticketPrice = 0.000016 ether; // 0.16 ether
    uint256 public totalTickets = 0;
    mapping(address => ticket) public ticketsOf;
    struct ticket {
        uint256 index; // Incl
        uint256 amount;
    }

    /**
        Security
     */
    uint256 public constant maxMintPerTx = 30;

    /**
        Pre Sale Raffle
     */
    uint256 public preSaleRaffleNumber;
    uint256 public preSaleOffsetInSlot;
    uint256 public preSaleSlotSize;
    uint256 public preSaleLastTargetIndex; // index greater than this is dis-regarded
    mapping(address => result) public preSaleResultOf;

    /**
        Raffle
     */
    uint256 public raffleNumber;
    uint256 public offsetInSlot;
    uint256 public slotSize;
    uint256 public lastTargetIndex; // index greater than this is dis-regarded
    mapping(address => result) public resultOf;
    struct result {
        bool executed;
        uint256 validTicketAmount;
    }

    event SetSlotiesNFT(address slotiesNFT);
    event SetPreSaleStart(uint256 preSaleStart);
    event SetSaleClosed(bool saleClosed);
    event SetPreSaleAddress(address presale);
    event PreSaleMint(address account, uint256 amount, uint256 changes);
    event TakingTickets(address account, uint256 amount, uint256 changes);
    event RunRaffle(uint256 raffleNumber);
    event SetResult(
        address account,
        uint256 validTicketAmount,
        uint256 changes
    );
    event MintSloties(address account, uint256 mintRequestAmount);
    event Withdraw(address to);

    constructor(
        address _sloties,
        address _presale
    ) Ownable() {
        slotiesNFT = SlotiesNFT(_sloties);
        preSaleAddress = _presale;
    }

    modifier whenStarted() {
        require(!saleClosed, "Public sale has been closed");
        require(
            block.timestamp >= preSaleStart + saleStartOffset,
            "Public sale hasn't started"
        );
        _;
    }

    modifier whenPreSaleStarted() {
        require(block.timestamp >= preSaleStart, "Presale Hasn't started");
        require(
            block.timestamp < preSaleStart + preSaleDuration,
            "Presale is closed"
        );
        _;
    }

    function setSlotiesNFT(SlotiesNFT _slotiesNFT) external onlyOwner {
        slotiesNFT = _slotiesNFT;
        emit SetSlotiesNFT(address(_slotiesNFT));
    }

    function setPreSaleStart(uint256 _presaleStart) external onlyOwner {
        preSaleStart = _presaleStart;
        emit SetPreSaleStart(_presaleStart);
    }

    function setSaleClosed(bool _saleClosed) external onlyOwner {
        saleClosed = _saleClosed;
        emit SetSaleClosed(_saleClosed);
    }

    /**
     * @dev sets the address of the presale wallet.
     * Only owner can call this function.
     */
    function setPreSaleAddress(address _address) external onlyOwner {
        preSaleAddress = _address;
        emit SetPreSaleAddress(_address);
    }

    /**
     * Splits a signature to given bytes
     * that the erecover method can use
     * to verify the message and the sender
     * @param sig the signature to split
     */
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    /**
     * takes the message and the signature
     * and verifies that the message is correct
     * and then returns the signer address of the signature
     */
    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function _takingTickets(uint256 _amount, bool isPreSale) internal {
        require(_amount > 0, "Need to take ticket more than 0");

        ticket storage myTicket = isPreSale ? preSaleTicketsOf[msg.sender] : ticketsOf[msg.sender];
        require(myTicket.amount == 0, "Already registered");

        uint256 totalPrice = isPreSale ? preSaleTicketPrice * _amount : ticketPrice * _amount;
        require(totalPrice <= msg.value, "Not enough money");

        if (isPreSale) {
            myTicket.index = totalPreSaleTickets;
            myTicket.amount = _amount;

            totalPreSaleTickets = totalPreSaleTickets + _amount;
        } else {            
            myTicket.index = totalTickets;
            myTicket.amount = _amount;

            totalTickets = totalTickets + _amount;
        }      

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit TakingTickets(msg.sender, _amount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }
    
    function calculateValidTicketAmount(
        uint256 index,
        uint256 amount,
        uint256 _slotSize,
        uint256 _offsetInSlot,
        uint256 _lastTargetIndex
    ) internal pure returns (uint256 validTicketAmount) {
        /**
        /_____fio___\___________________________________/lio\___________
                v   f |         v     |         v     |     l   v     |
        ______slot #n__|___slot #n+1___|____slot #n+2__|____slot #n+3__|
            f : first index (incl.)
            l : last index (incl.)
            v : win ticket
            fio : first index offset
            lio : last index offset
            n, n+1,... : slot index
            
            v in (slot #n+1) is ths firstWinIndex
            v in (slot #n+2) is ths lastWinIndex
        */
        uint256 lastIndex = index + amount - 1; // incl.
        if (lastIndex > _lastTargetIndex) {
            lastIndex = _lastTargetIndex;
        }

        uint256 firstIndexOffset = index % _slotSize;
        uint256 lastIndexOffset = lastIndex % _slotSize;

        uint256 firstWinIndex;
        if (firstIndexOffset <= _offsetInSlot) {
            firstWinIndex = index + _offsetInSlot - firstIndexOffset;
        } else {
            firstWinIndex =
                index +
                _slotSize +
                _offsetInSlot -
                firstIndexOffset;
        }

        // Nothing is selected
        if (firstWinIndex > _lastTargetIndex) {
            validTicketAmount = 0;
        } else {
            uint256 lastWinIndex;
            if (lastIndexOffset >= _offsetInSlot) {
                lastWinIndex = lastIndex + _offsetInSlot - lastIndexOffset;
            } else if (lastIndex < _slotSize) {
                lastWinIndex = 0;
            } else {
                lastWinIndex =
                    lastIndex +
                    _offsetInSlot -
                    lastIndexOffset -
                    _slotSize;
            }

            if (firstWinIndex > lastWinIndex) {
                validTicketAmount = 0;
            } else {
                validTicketAmount =
                    (lastWinIndex - firstWinIndex) /
                    _slotSize +
                    1;
            }
        }
    }


    /** PRESALE RAFFLE */

    function preSaleTakingTickets(uint256 _amount, bool isSpecial, uint256 nonce, bytes memory signature) external payable whenPreSaleStarted {
        require(_amount > 0, "Need to take ticket more than 0");
        require(_amount <= preSaleMaxTickets, "CANNOT BUY MORE THAN 3 TICKETS");

        require(preSaleAddressToNonce[msg.sender] == nonce, "INCORRECT NONCE");
        bytes32 message = keccak256(abi.encodePacked(msg.sender, _amount, isSpecial, nonce, address(this))).toEthSignedMessageHash();
        require(recoverSigner(message, signature) == preSaleAddress, "SIGNATURE NOT FROM PRE SALE WALLET");
        preSaleAddressToNonce[msg.sender] = preSaleAddressToNonce[msg.sender].add(1);

        if (isSpecial) {
            require(!ticketGuaranteed[msg.sender], "TICKET ALREADY BOUGHT");

            ticketGuaranteed[msg.sender] = true;
            maxPreSaleWinnable = maxPreSaleWinnable.sub(1);
            
            if (_amount.sub(1) == 0) {
                return;
            }

            _takingTickets(_amount.sub(1), true);
        } else {
            _takingTickets(_amount, true);
        }
    }

    function runPreSaleRaffle(uint256 _raffleNumber) external onlyOwner {
        require(preSaleRaffleNumber == 0, "raffle number is already set");

        preSaleRaffleNumber = _raffleNumber;

        // Hopefully consider that totalTickets number is more than remainingURS
        // Actually this number can be controlled from team by taking tickets
        preSaleSlotSize = totalPreSaleTickets / maxPreSaleWinnable;
        preSaleOffsetInSlot = _raffleNumber % preSaleSlotSize;
        preSaleLastTargetIndex = preSaleSlotSize * maxPreSaleWinnable - 1;

        emit RunRaffle(_raffleNumber);
    }

     function preSaleCalculateMyResult() external {
        require(preSaleRaffleNumber > 0, "raffle number is not set yet");

        ticket storage myTicket = preSaleTicketsOf[msg.sender];
        require(myTicket.amount > 0 || ticketGuaranteed[msg.sender], "No available ticket");

        result storage myResult = preSaleResultOf[msg.sender];
        require(!myResult.executed, "Already checked");

        uint256 validTicketAmount = myTicket.amount > 0 ? calculateValidTicketAmount(
            myTicket.index,
            myTicket.amount,
            preSaleSlotSize,
            preSaleOffsetInSlot,
            preSaleLastTargetIndex
        ) : 0;

        myResult.validTicketAmount = validTicketAmount;
        myResult.executed = true;

        if (ticketGuaranteed[msg.sender]) {
            myResult.validTicketAmount = myResult.validTicketAmount.add(1);
        }

        uint256 remainingTickets = myTicket.amount > 0 ?  ticketGuaranteed[msg.sender] ? myTicket.amount + 1 - validTicketAmount : myTicket.amount - validTicketAmount : 0;
        uint256 changes = remainingTickets * preSaleTicketPrice;

        emit SetResult(msg.sender, validTicketAmount, changes);
        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    /** PUBLIC SALE RAFFLE */

    function takingTickets(uint256 _amount) external payable whenStarted {        
        _takingTickets(_amount, false);
    }

    function runRaffle(uint256 _raffleNumber) external onlyOwner {
        require(saleClosed, "SALE STILL ACTIVE");
        require(raffleNumber == 0, "raffle number is already set");

        raffleNumber = _raffleNumber;
        uint256 remainingSloties = maxSloties - maxPreSaleSupply;

        // Hopefully consider that totalTickets number is more than remainingURS
        // Actually this number can be controlled from team by taking tickets
        slotSize = totalTickets / remainingSloties;
        offsetInSlot = _raffleNumber % slotSize;
        lastTargetIndex = slotSize * remainingSloties - 1;

        emit RunRaffle(_raffleNumber);
    }

    function calculateMyResult() external {
        require(raffleNumber > 0, "raffle number is not set yet");

        ticket storage myTicket = ticketsOf[msg.sender];
        require(myTicket.amount > 0, "No available ticket");

        result storage myResult = resultOf[msg.sender];
        require(!myResult.executed, "Already checked");

        uint256 validTicketAmount = calculateValidTicketAmount(
            myTicket.index,
            myTicket.amount,
            slotSize,
            offsetInSlot,
            lastTargetIndex
        );

        myResult.validTicketAmount = validTicketAmount;
        myResult.executed = true;

        uint256 remainingTickets = myTicket.amount - validTicketAmount;
        uint256 changes = remainingTickets * ticketPrice;

        emit SetResult(msg.sender, validTicketAmount, changes);
        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function mintSloties() external {
        result storage preResult = preSaleResultOf[msg.sender];
        result storage publicResult = resultOf[msg.sender];
        uint256 validTicketTotal = preResult.validTicketAmount + publicResult.validTicketAmount;

        require(preResult.executed || publicResult.executed, "result is not calculated yet");
        require(validTicketTotal > 0, "No valid tickets");

        uint256 mintRequestAmount = 0;

        if (validTicketTotal > maxMintPerTx) {
            mintRequestAmount = maxMintPerTx;            
            publicResult.validTicketAmount += preResult.validTicketAmount;
            preResult.validTicketAmount = 0;
            publicResult.validTicketAmount -= maxMintPerTx;
        } else {
            mintRequestAmount = validTicketTotal;
            preResult.validTicketAmount = 0;
            publicResult.validTicketAmount = 0;
        }

        slotiesNFT.mintTo(mintRequestAmount, msg.sender);

        emit MintSloties(msg.sender, mintRequestAmount);
    }

    /** GIVEAWAY */
    function claimGiveaway(uint256 _amount, uint256 nonce, bytes memory signature) external {
        require(saleClosed, "SALE NOT CLOSED");
        require(!giveAwayClaimed[msg.sender], "ALREADY CLAIMED");

        require(preSaleAddressToNonce[msg.sender] == nonce, "INCORRECT NONCE");
        bytes32 message = keccak256(abi.encodePacked(msg.sender, _amount, nonce, address(this))).toEthSignedMessageHash();
        require(recoverSigner(message, signature) == preSaleAddress, "SIGNATURE NOT FROM PRE SALE WALLET");
        preSaleAddressToNonce[msg.sender] = preSaleAddressToNonce[msg.sender].add(1);

        giveAwayClaimed[msg.sender] = true;
        slotiesNFT.mintTo(_amount, msg.sender);
    }

    // withdraw eth for sold Sloties
    function withdraw(address payable _to) external onlyOwner {
        require(_to != address(0), "receiver can not be empty address");
        require(!claimed, "Already claimed");
        require(
             maxSloties <= totalTickets + maxPreSaleSupply,
            "Not enough ethers are collected"
        );

        uint256 withdrawalAmount = ticketPrice.mul(maxSloties.sub(maxPreSaleSupply)).add(preSaleTicketPrice.mul(maxPreSaleSupply)); //TODO account for giveaway and premint

        // Send eth to designated receiver
        emit Withdraw(_to);

        claimed = true;
        _to.transfer(withdrawalAmount);
    }

    /**
     * @dev Allows the owner to withdraw ether
     * ONLY TO BE USED IN EMERGENCIES 
     */
    function emergencyWithdrawEth() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "ETH Transfer failed");
    }
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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