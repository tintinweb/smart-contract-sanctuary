// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Factory {
    function mint(address) external;
}

interface Pass {
    function balanceOf(address) external view returns (uint256);
}

contract URSStore {
    Pass public pass;
    Factory public ursFactory;

    /**
        Store
     */
    address public owner;

    /**
        Numbers for URS Factory
     */
    uint256 public constant maxURS = 10000;

    /**
        Team withdraw fund
     */
    // claimed
    bool internal claimed = false;

    /**
        Team allocated URS
     */
    // URS which is minted by the owner
    uint256 public preMintedURS = 0;
    // MAX URS which owner can mint
    uint256 public constant maxPreMintURS = 50;

    /**
        Mint Pass
     */
    uint256 public newlyMintedURSWithPass = 0;
    uint256 public constant maxURSPerPass = 5;
    mapping(address => uint256) public mintedURSOf;

    /**
        Scheduling
     */
    uint256 public openingHours;
    uint256 public constant operationSecondsForVIP = 3600 * 3; // 3 hours
    uint256 public constant operationSeconds = 3600 * 24; // 24 hours

    /**
        Ticket
     */
    uint256 public constant ticketPrice = 0.08 ether;
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

    event SetPass(address pass);
    event SetURSFactory(address ursFactory);
    event SetOpeningHours(uint256 openingHours);
    event MintWithPass(address account, uint256 amount, uint256 changes);
    event TakingTickets(address account, uint256 amount, uint256 changes);
    event RunRaffle(uint256 raffleNumber);
    event SetResult(
        address account,
        uint256 validTicketAmount,
        uint256 changes
    );
    event MintURS(address account, uint256 mintRequestAmount);
    event Withdraw(address to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

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

    function setPass(Pass _pass) external onlyOwner {
        pass = _pass;
        emit SetPass(address(_pass));
    }

    function setURSFactory(Factory _ursFactory) external onlyOwner {
        ursFactory = _ursFactory;
        emit SetURSFactory(address(_ursFactory));
    }

    function setOpeningHours(uint256 _openingHours) external onlyOwner {
        openingHours = _openingHours;
        emit SetOpeningHours(_openingHours);
    }

    // Do not update newlyMintedURS to prevent withdrawal
    function preMintURS(address to) external onlyOwner {
        require(to != address(0), "receiver can not be empty address");
        require(preMintedURS < maxPreMintURS, "Exceeds max pre-mint URS");
        require(
            block.timestamp <
                openingHours + operationSecondsForVIP + operationSeconds,
            "Not available after ticketing period"
        );
        preMintedURS += 1;
        ursFactory.mint(to);
    }

    function mintWithPass(uint256 _amount) external payable whenVIPOpened {
        require(_amount <= maxMintPerTx, "mint amount exceeds maximum");
        require(_amount > 0, "Need to mint more than 0");

        uint256 mintedURS = mintedURSOf[msg.sender];
        uint256 passAmount = pass.balanceOf(msg.sender);
        require(
            passAmount * maxURSPerPass - mintedURS >= _amount,
            "Not enough Pass"
        );

        uint256 totalPrice = ticketPrice * _amount;
        require(totalPrice <= msg.value, "Not enough money");

        for (uint256 i = 0; i < _amount; i += 1) {
            ursFactory.mint(msg.sender);
        }

        mintedURSOf[msg.sender] = mintedURS + _amount;
        newlyMintedURSWithPass += _amount;

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
        require(raffleNumber == 0, "raffle number is already set");

        raffleNumber = _raffleNumber;
        uint256 remainingURS = maxURS - preMintedURS - newlyMintedURSWithPass;

        // Hopefully consider that totalTickets number is more than remainingURS
        // Actually this number can be controlled from team by taking tickets
        slotSize = totalTickets / remainingURS;
        offsetInSlot = _raffleNumber % slotSize;
        lastTargetIndex = slotSize * remainingURS - 1;

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

    function mintURS() external {
        result storage myResult = resultOf[msg.sender];

        require(myResult.executed, "result is not calculated yet");
        require(myResult.validTicketAmount > 0, "No valid tickets");

        uint256 mintRequestAmount = 0;

        if (myResult.validTicketAmount > maxMintPerTx) {
            mintRequestAmount = maxMintPerTx;
            myResult.validTicketAmount -= maxMintPerTx;
        } else {
            mintRequestAmount = myResult.validTicketAmount;
            myResult.validTicketAmount = 0;
        }

        for (uint256 i = 0; i < mintRequestAmount; i += 1) {
            ursFactory.mint(msg.sender);
        }

        emit MintURS(msg.sender, mintRequestAmount);
    }

    // withdraw eth for sold URS
    function withdraw(address payable _to) external onlyOwner {
        require(_to != address(0), "receiver can not be empty address");
        require(!claimed, "Already claimed");
        require(
            maxURS - maxPreMintURS <= totalTickets + newlyMintedURSWithPass,
            "Not enough ethers are collected"
        );

        uint256 withdrawalAmount = ticketPrice * (maxURS - maxPreMintURS);

        // Send eth to designated receiver
        emit Withdraw(_to);

        claimed = true;
        _to.transfer(withdrawalAmount);
    }
}

