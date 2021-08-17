/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

abstract contract UpgradedContract {
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function newbet(
        address addr,
        uint256 amount,
        uint256 bet_id,
        uint256 reserve
    ) public virtual;

    function withdrawal(uint256[] calldata bet_ids) public payable virtual;
}

struct Bet {
    address addr;
    uint256 amount;
    uint256 bet_id;
    bool paid;
    uint256 to_pay;
}

contract DexBets is Ownable, Pausable {
    // stable usd token
    IERC20 usdt;

    address public upgradedAddress;
    bool public deprecated;

    uint256 reserved;
    uint256 max_amount = 10000000000000000000;

    constructor(address usdt_address) {
        usdt = IERC20(usdt_address);
    }

    function getMax() public view returns (uint256) {
        return max_amount;
    }

    function getReserved() public view returns (uint256) {
        return reserved;
    }

    function setMax(uint256 newMax) public onlyOwner {
        max_amount = newMax;
    }

    mapping(uint256 => Bet) public bets;

    // server creates bets
    function newbet(
        address addr,
        uint256 amount,
        uint256 bet_id,
        uint256 reserve
    ) public whenNotPaused onlyOwner {
        require(amount <= max_amount);
        if (deprecated) {
            UpgradedContract(upgradedAddress).newbet(
                addr,
                amount,
                bet_id,
                reserve
            );
        } else {
            Bet storage b = bets[bet_id];
            b.addr = addr;
            b.amount = amount;
            b.paid = false;
            b.to_pay = reserve;
            reserved = reserved + reserve;
            emit NewBet(bet_id);
        }
    }

    // user withdrawals bets
    function withdrawal(uint256[] calldata bet_ids)
        public
        payable
        whenNotPaused
    {
        if (deprecated) {
            UpgradedContract(upgradedAddress).withdrawal(bet_ids);
        } else {
            uint256 total_amount = 0;
            for (uint256 i = 0; i < bet_ids.length; i++) {
                Bet storage b = bets[bet_ids[i]];
                require(b.addr == msg.sender);
                require(b.paid == false);
                require(b.to_pay > 0);
                b.paid = true;
                total_amount = total_amount + b.to_pay;
                emit PrizeWithdrawn(bet_ids[i], b.to_pay, b.addr);
            }
            usdt.transfer(msg.sender, total_amount);
            reserved = reserved - total_amount;
            emit Withdrawn(msg.sender, total_amount);
        }
    }

    // server set to_pay for ids
    function toPayAdmin(uint256[] calldata bet_ids, uint256[] calldata amounts)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < bet_ids.length; i++) {
            Bet storage b = bets[bet_ids[i]];
            if (amounts[i] > 0) {
                b.to_pay = amounts[i];
                emit BetWin(bet_ids[i], b.amount, b.addr);
            } else {
                b.paid = true;
                reserved = reserved - b.amount;
                emit BetLoose(bet_ids[i], b.amount, b.addr);
            }
        }
    }

    // stake winner amount
    function stakeBets(uint256[] calldata bet_ids) public onlyOwner {
        for (uint256 i = 0; i < bet_ids.length; i++) {
            Bet storage b = bets[bet_ids[i]];
            require(b.paid == false);
            b.paid = true;
            reserved = reserved - b.amount;
            emit BetStaked(bet_ids[i], b.amount, b.addr);
        }
    }

    // function withdrawal for admin
    function withdrawalAdmin(address recipient, uint256 amount)
        public
        onlyOwner
    {
        require(amount <= usdt.balanceOf(address(this)) - reserved);
        usdt.transfer(recipient, amount);
        emit WithdrawnAdmin(recipient, amount);
    }

    // deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) external onlyOwner {
        require(_upgradedAddress != address(0), "ZERO_ADDRESS");
        require(!deprecated, "already deprecated");
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    event NewBet(uint256 id);
    event Deprecate(address newAddress);
    event WithdrawnAdmin(address to, uint256 amount);
    event Withdrawn(address to, uint256 amount);
    event PrizeWithdrawn(uint256 id, uint256 amount, address user);
    event BetWin(uint256 id, uint256 amount, address user);
    event BetLoose(uint256 id, uint256 amount, address user);
    event BetStaked(uint256 id, uint256 amount, address user);
}