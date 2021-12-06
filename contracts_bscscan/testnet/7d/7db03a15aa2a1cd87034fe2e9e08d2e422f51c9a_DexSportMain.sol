/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;


/// @title Ownable Contract
contract Ownable {
    // Storage slot with the admin of the contract.
    // This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
    // validated in the constructor.
    bytes32 private constant OWNER_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /// Contract constructor
    /// @dev Sets msg sender address as owner address
    constructor() {
        setOwner(msg.sender);
    }

    /// Check that requires msg.sender to be the current owner
    modifier onlyOwner() {
        require(msg.sender == getOwner(), "55f1136901"); // 55f1136901 - sender must be owner
        _;
    }
    
    /// Returns contract owner address
    /// @return owner Owner address
    function getOwner() public view returns (address owner) {
        bytes32 slot = OWNER_SLOT;
        assembly {
            owner := sload(slot)
        }
    }

    

    /// Sets new owner address
    /// @param newOwner New owner address
    function setOwner(address newOwner) internal {
        bytes32 slot = OWNER_SLOT;
        assembly {
            sstore(slot, newOwner)
        }
    }

    /// Transfers the control of the contract to new owner
    /// @dev msg.sender must be the current owner
    /// @param newOwner New owner address
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "f2fde38b01"); // f2fde38b01 - new owner cant be zero address
        setOwner(newOwner);
    }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    bool public paused;

    event Pause();
    event Unpause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "Not paused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}
// struct that contains bet information
struct BetV1 {
    address addr; // address of bet's owner
    // uint256 amount; // amount of bet
    bool paid; // is bet already paid
    uint256 toPay; // amount of bet that user can ask to withdrawal/stake (amount that user has won)
    uint256 reserved_initial; // how much was reserved on bet creation
    uint256 version; // version that bet was made
    address token; // token that was used for bet
}


interface IERC20 {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
}

interface IDAO {
    function isTransferAvailable(uint256 id) external view returns (uint256, address, address);
    function confirmTransfer(uint256 id) external returns (bool);

    function isOwnerChangeAvailable(uint256 id) external view returns (address);
    function confirmOwnerChange(uint256 id) external returns (bool);

    // function isDAOChangeAvailable(uint256 id) external view returns (address);
    // function confirmDAOChange(uint256 id) external returns (bool);
}

/*
Main logic is:
- user logs in into the platform
- user deposits any amount of `usdt` tokens to contract address
-- platform lookup for usdt transfers for contract and if find one, deposits user's balance inside platform(tokens have to be send from user's address)
- user make bets
- platform asking for acquire of bet creation (`newbet` function)
-- if so, we create new record inside contract with bet id, amount, reserve and mark it as unpaid and not available to withdrawal/stake untill bet is not completed
- when platform gets approval for certain bet we mark this bet(`toPayAdmin` function) as `ready to pay`(`amount`) and write down amount that approved by platform for bet
-- if bet wins amount has to be > 0
-- if bet lost amount == 0
- now user can withdrawal(`withdrawal` function) or stake(keep amount on balance, `stakeBets` function) bets that won
-- no action required for bets that lose

- admin(one of voters) can ask for withdrawal funds(transfer request)
-- it can be done only if votes count from approved voters is enough(more than half an active voters count)
*/
contract DexSportMain is Pausable {
    // storage of all bets
    mapping(uint256 => BetV1) public betsV1;
    // count of bets(id for new bet)
    // DEPRECATED: we do not use bet id increment according to platform may has it's own ids
    // uint256 private betsCount;

    // stable token that we use to deposit/withdrawal
    mapping(address => bool) public whitelistedERC20;

    // amount of reserved tokens
    mapping(address => uint256) public reserved;
    // max amount for new bet
    uint256 public maxAmount = 10**24;
    // address for DAO management operations
    address public dao;

    
    event NewMax(uint256 indexed max);
    event NewBet(uint256 indexed id);
    event WithdrawnAdmin(
        address indexed to,
        uint256 amount,
        address indexed token
    );
    event Withdrawn(address indexed to, uint256 amount);
    event PrizeWithdrawn(
        uint256 indexed id,
        uint256 amount,
        address indexed user
    );
    event BetWin(
        uint256 indexed id,
        uint256 amount,
        address indexed user,
        address indexed token
    );
    event BetLose(
        uint256 indexed id,
        uint256 amount,
        address indexed user,
        address indexed token
    );
    event BetStaked(
        uint256 indexed id,
        uint256 amount,
        address indexed user,
        address indexed token
    );

    modifier onlyWhitelist(address token) { 
        require(whitelistedERC20[token], "W"); 
        _; 
    } 

    // getter for IERC20 of some token
    function getIERC(address token) internal pure returns (IERC20) {
        // allow only whitelisted tokens
        return IERC20(token);
    }

    // getter for max amount
    // function getMax() external view returns (uint256) {
    //     return maxAmount;
    // }

    // getter for total reserved funds for some token
    function getReserved(address token) external view returns (uint256) {
        return reserved[token];
    }

    // getter for bet
    // function getBetById(uint256 id)
    //     external
    //     view
    //     whenNotPaused
    //     returns (BetV1 memory)
    // {
    //     return betsV1[id];
    // }

    // setter for max amount
    function setMax(uint256 newMax) external onlyOwner {
        maxAmount = newMax;
        emit NewMax(newMax);
    }

    // any admin can whitelist new erc20 token to use
    function whitelistERC20(address token) external onlyOwner {
        whitelistedERC20[token] = true;
    }
    
    // TODO: reserve should check ERC20 balance?
    // server creates bets and increase reserve according to  token
    function newbet(
        address addr,
        uint256 amount,
        uint256 betId,
        uint256 reserve,
        address tokenAddress
    ) external whenNotPaused onlyOwner onlyWhitelist(tokenAddress) {
        require(getIERC(tokenAddress).balanceOf(
            address(this)
        ) >= reserve, "R"); // bet's reserve couldn't be more than we already have
        require(amount <= maxAmount, "M"); // max exceeded
        require(betsV1[betId].addr == address(0), "B"); // Bet already exists
        BetV1 storage b = betsV1[betId];
        b.addr = addr;
        // b.amount = amount;
        b.paid = false;
        b.toPay = 0;
        b.reserved_initial = reserve;
        b.token = tokenAddress;
        reserved[tokenAddress] = reserved[tokenAddress] + reserve;
        emit NewBet(betId);
    }

    // user asks to withdrawal some bets
    // check that bet is ready for withdrawal, decrese reserve and send tokens back to user
    function withdrawal(uint256[] calldata betIds) external whenNotPaused {
        for (uint256 i = 0; i < betIds.length; i++) {
            BetV1 storage b = betsV1[betIds[i]];
            require(b.addr == msg.sender, "W"); // wrong addr
            require(!b.paid, "A"); // already paid
            require(b.toPay > 0, "N"); // nothing to pay
            b.paid = true;
            reserved[b.token] = reserved[b.token] - b.toPay;
            emit PrizeWithdrawn(betIds[i], b.toPay, b.addr);
        }
        for (uint256 i = 0; i < betIds.length; i++) {
            BetV1 storage b = betsV1[betIds[i]];
            require(
                getIERC(b.token).transfer(msg.sender, b.toPay),
                "T"
            ); // "not transfered"
        }
    }

    // platform sets some bets as won(amount > 0) or lost(amount == 0)
    function toPayAdmin(uint256[] calldata betIds, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(betIds.length == amounts.length, "L"); // length mistmatch
        for (uint256 i = 0; i < betIds.length; i++) {
            BetV1 storage b = betsV1[betIds[i]];
            require(!b.paid, "P"); // already paid
            if (amounts[i] > 0) {
                b.toPay = amounts[i];
                // reserve could be changed over the time, so we write down reserved_initial on bet's creation
                // substract it from reserve and add new value from amounts
                reserved[b.token] = reserved[b.token] - b.reserved_initial + b.toPay;
                emit BetWin(betIds[i], b.reserved_initial, b.addr, b.token);
            } else {
                b.paid = true;
                // just substract reserve
                reserved[b.token] = reserved[b.token] - b.reserved_initial;
                emit BetLose(betIds[i], b.reserved_initial, b.addr, b.token);
            }
            require(reserved[b.token] > 0, "R"); // reserve underflow
        }
    }

    // function to stake bets(keep bet's win amount on balance) and decrese reserve
    function stakeBets(uint256[] calldata betIds) external whenNotPaused {
        for (uint256 i = 0; i < betIds.length; i++) {
            BetV1 storage b = betsV1[betIds[i]];
            require(b.addr == msg.sender, "W"); // wrong addr
            require(b.toPay > 0, "N"); // nothing to pay
            require(!b.paid, "A"); // already paid
            b.paid = true;
            reserved[b.token] = reserved[b.token] - b.toPay;
            emit BetStaked(betIds[i], b.toPay, b.addr, b.token);
        }
    }

    function daoChange(address newDao) external onlyOwner {
        require(dao == address(0), "0"); // 0x0 addr
        require(newDao != address(0), "Z"); // 0x0 addr
        dao = newDao;
    }
    // request to change DAO address
    // function daoChange(uint256 id, address initialDaoAddress) external {
    //     if (dao == address(0)) {
    //         require(initialDaoAddress != address(0), "0"); //0x0 addr
    //         dao = initialDaoAddress;
    //     }
    // }
    //     } else {
    //         dao = IDAO(dao).isDAOChangeAvailable(id);
    //         require(IDAO(dao).confirmDAOChange(id), "N"); // not confirmed
    //     }
    // }

    // request to DAO for change owner
    function ownerChange(uint256 id) external {
        address newOwner = IDAO(dao).isOwnerChangeAvailable(id);
        require(newOwner != address(0), "0"); // address 0x0
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

        assembly {
            sstore(slot, newOwner)
        }
        require(IDAO(dao).confirmOwnerChange(id), "C"); //not confirmed
    }

    // request to DAO for transfer funds
    function transferFunds(uint256 id) external {
        address token;
        uint256 amount;
        address recepient;
        (amount, recepient, token) = IDAO(dao).isTransferAvailable(id);
        emit WithdrawnAdmin(
            recepient,
            amount,
            token
        );
        require(
            amount <=
                getIERC(token).balanceOf(
                    address(this)
                ) -
                    reserved[token],
            "R"
        ); // not enough reserve
        require(
            getIERC(token).transfer(
                recepient,
                amount
            ),
            "C"
        ); // not transfered
        
        require(IDAO(dao).confirmTransfer(id), "N"); // not confirmed
    }
}