// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface Factory {
    function mint(address) external;
}

interface Pass {
    function balanceOf(address) external view returns (uint256);
}

contract BasementDwellersStore is Ownable {
    Pass public constant pass =
        Pass(0xfaA9fA81f810f7d0417054e7BfC234D006f97aCd);
    Factory public constant bdFactory =
        Factory(0x616dda1823590a345aa6E6440958Df90EF8CAdde);

    // TODO: Use the real one
    Pass public constant bonusPass =
        Pass(0x4DbBC2a745fbe5AE6cd4f3E0De85FA651B54c4C8);

    //Nomanz final
    address private constant core1Address =
        0x105195bE68a677d80303B9962b309A30DEf24783;
    uint256 private constant core1Shares = 62625;

    //Skitzzo final
    address private constant core2Address =
        0x073DfB7bf2A23f13a547FB4898a46d072f6792f8;
    uint256 private constant core2Shares = 26375;

    // final
    address private constant core3Address =
        0x32b9d0167BD2ffaf4Fb6Be5B1CA5cc3FB29b7c40;


    address private constant core4Address =
        0x704c7dA8D117Ff5cf3C3268EeCaB6A80188B2AAc;
    uint256 private constant core4Shares = 7000;

    // final
    address private constant advisor1Address =
        0xD09659effC0DE1855e9D33A4F80Eb4348CA50aF2;
    uint256 private constant advisor1Shares = 4000;


    uint256 private constant baseMod = 100000;

    /**
        Numbers for Basement Dwellers Factory
     */
    uint256 public constant maxDwellers = 10000;

    /**
        Team allocated Dwellers
     */
    // Dwellers which is minted by the owner
    uint256 public preMintedDwellers = 0;
    // MAX Dwellers which owner can mint
    uint256 public constant maxPreMintDwellers = 150;

    /**
        Mint Pass
     */
    uint256 public newlyMintedDwellersWithPass = 0;
    uint256 public constant maxDwellersPerPass = 5;
    mapping(address => uint256) public mintedDwellersOf;

    /**
        Tracking Dweller Sales After Presale
     */
    uint256 public mintedDwellersAfterPresale = 0;

    /**
        Scheduling
     */
    uint256 public openingHours = 1633996800; // Mon Oct 11 2021 17:00:00 PDT
    uint256 public constant operationSecondsForVIP = 3600 * 24; // 24 hours
    uint256 public constant operationSeconds = 3600 * 24; // 24 hours

    /**
        Ticket
     */
    uint256 public constant ticketPrice = 0.069 ether;
    uint256 public totalTickets = 0;
    mapping(address => ticket) public ticketsOf;
    struct ticket {
        uint256 index; // Incl
        uint256 amount;
    }

    /**
        Withdrawal totals
     */
    uint256 public withdrawTotal = 0;

    /**
        Security
     */
    uint256 public constant maxMintPerTx = 30;

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

    bool public isSoldOut = false;
    uint256 public remainingDwellers = 0;

    // event SetPass(address pass);
    // event SetDwellersFactory(address bdFactory);
    event SetOpeningHours(uint256 openingHours);
    event MintWithPass(address account, uint256 amount, uint256 changes);
    event TakingTickets(address account, uint256 amount, uint256 changes);
    event SetRemainingDwellers(uint256 remainingDwellers);
    event RunRaffle(uint256 raffleNumber);
    event SetResult(
        address account,
        uint256 validTicketAmount,
        uint256 changes
    );
    event PurchaseRemainingDwellers(address account, uint256 amount);
    event MintDwellers(address account, uint256 mintRequestAmount);
    event Withdraw(address to);

    constructor() {}

    modifier whenOpened() {
        require(
            block.timestamp >= openingHours + operationSecondsForVIP,
            "Store is not opened"
        );
        require(
            block.timestamp <
                openingHours + operationSecondsForVIP + operationSeconds,
            "Store is closed"
        );
        _;
    }

    modifier whenVIPOpened() {
        require(block.timestamp >= openingHours, "Store is not opened for VIP");
        require(
            block.timestamp < openingHours + operationSecondsForVIP,
            "Store is closed for VIP"
        );
        _;
    }

    modifier onlyOwnerOrTeam() {
        require(
            core1Address == msg.sender || core2Address == msg.sender || core3Address == msg.sender || core4Address == msg.sender || owner() == msg.sender,
            "caller is neither Team Wallet nor Owner"
        );
        _;
    }

    // function setPass(Pass _pass) external onlyOwner {
    //     pass = _pass;
    //     emit SetPass(address(_pass));
    // }

    // function setDwellersFactory(Factory _bdFactory) external onlyOwner {
    //     bdFactory = _bdFactory;
    //     emit SetDwellersFactory(address(_bdFactory));
    // }

    function setOpeningHours(uint256 _openingHours) external onlyOwner {
        openingHours = _openingHours;
        emit SetOpeningHours(_openingHours);
    }

    // Do not update newlyMintedDwellers to prevent withdrawal
    function preMintDwellers(address[] memory recipients) external onlyOwner {
        require(
            block.timestamp <
                openingHours + operationSecondsForVIP + operationSeconds,
            "Not available after ticketing period"
        );
        uint256 totalRecipients = recipients.length;

        require(
            totalRecipients > 0,
            "Number of recipients must be greater than 0"
        );
        require(
            preMintedDwellers + totalRecipients <= maxPreMintDwellers,
            "Exceeds max pre-mint Dwellers"
        );

        for (uint256 i = 0; i < totalRecipients; i++) {
            address to = recipients[i];
            require(to != address(0), "receiver can not be empty address");
            bdFactory.mint(to);
        }

        preMintedDwellers += totalRecipients;
    }

    function mintWithPass(uint256 _amount) external payable whenVIPOpened {
        require(_amount <= maxMintPerTx, "mint amount exceeds maximum");
        require(_amount > 0, "Need to mint more than 0");

        uint256 mintedDwellers = mintedDwellersOf[msg.sender];

        uint256 passAmount = pass.balanceOf(msg.sender);
        uint256 bonusPassAmount = bonusPass.balanceOf(msg.sender);
        passAmount += bonusPassAmount;

        // if (passAmount < bonusPassAmount) {
        //     passAmount = bonusPassAmount;
        // }

        require(
            passAmount * maxDwellersPerPass - mintedDwellers >= _amount,
            "Not enough Pass"
        );

        uint256 totalPrice = ticketPrice * _amount;
        require(totalPrice <= msg.value, "Not enough money");

        for (uint256 i = 0; i < _amount; i += 1) {
            bdFactory.mint(msg.sender);
        }

        mintedDwellersOf[msg.sender] = mintedDwellers + _amount;
        newlyMintedDwellersWithPass += _amount;

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit MintWithPass(msg.sender, _amount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function takingTickets(uint256 _amount) external payable whenOpened {
        require(_amount > 0, "Need to take ticket more than 0");

        ticket storage myTicket = ticketsOf[msg.sender];
        require(myTicket.amount == 0, "Already registered");

        uint256 totalPrice = ticketPrice * _amount;
        require(totalPrice <= msg.value, "Not enough money");

        myTicket.index = totalTickets;
        myTicket.amount = _amount;

        totalTickets = totalTickets + _amount;

        // Refund changes
        uint256 changes = msg.value - totalPrice;
        emit TakingTickets(msg.sender, _amount, changes);

        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function runRaffle(uint256 _raffleNumber) external onlyOwner {
        require(
            block.timestamp >
                openingHours + operationSecondsForVIP + operationSeconds,
            "Store is not closed yet"
        );
        require(raffleNumber == 0, "raffle number is already set");

        raffleNumber = _raffleNumber;

        uint256 _remainingDwellers = maxDwellers -
            preMintedDwellers -
            newlyMintedDwellersWithPass;

        if (totalTickets <= _remainingDwellers) {
            isSoldOut = false;
            remainingDwellers = _remainingDwellers - totalTickets;

            mintedDwellersAfterPresale = totalTickets;
        } else {
            isSoldOut = true;

            slotSize = totalTickets / _remainingDwellers;
            offsetInSlot = _raffleNumber % slotSize;
            lastTargetIndex = slotSize * _remainingDwellers - 1;

            mintedDwellersAfterPresale = _remainingDwellers;
        }

        emit RunRaffle(_raffleNumber);
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

    function calculateMyResult() external {
        require(raffleNumber > 0, "raffle number is not set yet");

        ticket storage myTicket = ticketsOf[msg.sender];
        require(myTicket.amount > 0, "No available ticket");

        result storage myResult = resultOf[msg.sender];
        require(!myResult.executed, "Already checked");

        uint256 validTicketAmount;
        if (!isSoldOut) {
            validTicketAmount = myTicket.amount;
        } else {
            validTicketAmount = calculateValidTicketAmount(
                myTicket.index,
                myTicket.amount,
                slotSize,
                offsetInSlot,
                lastTargetIndex
            );
        }

        myResult.validTicketAmount = validTicketAmount;
        myResult.executed = true;

        uint256 remainingTickets = myTicket.amount - validTicketAmount;
        uint256 changes = remainingTickets * ticketPrice;

        emit SetResult(msg.sender, validTicketAmount, changes);
        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }
    }

    function purchaseRemainingDwellers(uint256 _amount) external payable {
        require(_amount <= remainingDwellers, "Exceeds dwellers max supply");

        uint256 totalPrice = ticketPrice * _amount;
        require(totalPrice <= msg.value, "Not enough money");

        for (uint256 i = 0; i < _amount; i += 1) {
            bdFactory.mint(msg.sender);
        }

        mintedDwellersAfterPresale += _amount;
        remainingDwellers -= _amount;

        uint256 changes = msg.value - totalPrice;
        if (changes > 0) {
            payable(msg.sender).transfer(changes);
        }

        emit PurchaseRemainingDwellers(msg.sender, _amount);
    }

    function mintDwellers() external {
        result storage myResult = resultOf[msg.sender];

        require(myResult.executed, "result is not calculated yet");
        require(myResult.validTicketAmount > 0, "No valid tickets");

        uint256 mintRequestAmount = 0;

        // test if over max mint per tx
        if (myResult.validTicketAmount > maxMintPerTx) {
            mintRequestAmount = maxMintPerTx;
            myResult.validTicketAmount -= maxMintPerTx;
        } else {
            mintRequestAmount = myResult.validTicketAmount;
            myResult.validTicketAmount = 0;
        }

        for (uint256 i = 0; i < mintRequestAmount; i += 1) {
            bdFactory.mint(msg.sender);
        }

        emit MintDwellers(msg.sender, mintRequestAmount);
    }

    // withdraw eth for sold Dwellers
    function withdrawAll() external onlyOwnerOrTeam {
        uint256 maxWithdrawalAmount = ticketPrice *
            (newlyMintedDwellersWithPass + mintedDwellersAfterPresale);

        require(
            maxWithdrawalAmount > withdrawTotal,
            "No Funds Currently To Withdraw"
        );

        uint256 withdrawalAmount = maxWithdrawalAmount - withdrawTotal;

        _splitAll(withdrawalAmount);
        withdrawTotal += withdrawalAmount;
    }

    function _splitAll(uint256 _amount) private {
        uint256 singleShare = _amount / baseMod;
        _withdraw(core1Address, singleShare * core1Shares);
        _withdraw(core2Address, singleShare * core2Shares);
        _withdraw(core4Address, singleShare * core4Shares);
        _withdraw(advisor1Address, singleShare * advisor1Shares);
    }

    function _withdraw(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
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