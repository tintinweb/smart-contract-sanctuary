/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

pragma solidity ^0.8.0;




/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

    function burn(uint256 amount) external;

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
}

/*
The MIT License (MIT)

Copyright (c) 2016-2019 zOS Global Limited

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// It is not actually an interface regarding solidity because interfaces can only have external functions
abstract contract DepositLockerInterface {
    function slash(address _depositorToBeSlashed) public virtual;
}


/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "The function can only be called by the owner"
        );
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/*
  The DepositLocker contract locks the deposits for all of the winning
  participants of the auction.

  When the auction is running, the auction contract registers participants that
  have successfully bid with the registerDepositor function. The DepositLocker
  contracts keeps track of the number of participants and also keeps track if a
  participant address can withdraw the deposit.

  All of the participants have to pay the same amount when the auction ends.
  The auction contract will deposit the sum of all amounts with a call to
  deposit.

  This is the base contract, how exactly the deposit can be received, withdrawn and burned
  is left to be implemented in the derived contracts.
*/

abstract contract BaseDepositLocker is DepositLockerInterface, Ownable {
    bool public initialized = false;
    bool public deposited = false;

    /* We maintain two special addresses:
       - the slasher, that is allowed to call the slash function
       - the depositorsProxy that registers depositors and deposits a value for
         all of the registered depositors with the deposit function. In our case
         this will be the auction contract.
    */

    address public slasher;
    address public depositorsProxy;
    uint public releaseTimestamp;

    mapping(address => bool) public canWithdraw;
    uint numberOfDepositors = 0;
    uint valuePerDepositor;

    event DepositorRegistered(
        address depositorAddress,
        uint numberOfDepositors
    );
    event Deposit(
        uint totalValue,
        uint valuePerDepositor,
        uint numberOfDepositors
    );
    event Withdraw(address withdrawer, uint value);
    event Slash(address slashedDepositor, uint slashedValue);

    modifier isInitialised() {
        require(initialized, "The contract was not initialized.");
        _;
    }

    modifier isDeposited() {
        require(deposited, "no deposits yet");
        _;
    }

    modifier isNotDeposited() {
        require(!deposited, "already deposited");
        _;
    }

    modifier onlyDepositorsProxy() {
        require(
            msg.sender == depositorsProxy,
            "Only the depositorsProxy can call this function."
        );
        _;
    }

    fallback() external {}

    function registerDepositor(address _depositor)
        public
        isInitialised
        isNotDeposited
        onlyDepositorsProxy
    {
        require(
            canWithdraw[_depositor] == false,
            "can only register Depositor once"
        );
        canWithdraw[_depositor] = true;
        numberOfDepositors += 1;
        emit DepositorRegistered(_depositor, numberOfDepositors);
    }

    function deposit(uint _valuePerDepositor)
        public
        payable
        isInitialised
        isNotDeposited
        onlyDepositorsProxy
    {
        require(numberOfDepositors > 0, "no depositors");
        require(_valuePerDepositor > 0, "_valuePerDepositor must be positive");

        uint depositAmount = numberOfDepositors * _valuePerDepositor;
        require(
            _valuePerDepositor == depositAmount / numberOfDepositors,
            "Overflow in depositAmount calculation"
        );

        valuePerDepositor = _valuePerDepositor;
        deposited = true;
        _receive(depositAmount);
        emit Deposit(depositAmount, valuePerDepositor, numberOfDepositors);
    }

    function withdraw() public isInitialised isDeposited {
        require(
            block.timestamp >= releaseTimestamp,
            "The deposit cannot be withdrawn yet."
        );
        require(canWithdraw[msg.sender], "cannot withdraw from sender");

        canWithdraw[msg.sender] = false;
        _transfer(payable(msg.sender), valuePerDepositor);
        emit Withdraw(msg.sender, valuePerDepositor);
    }

    function slash(address _depositorToBeSlashed)
        public
        override
        isInitialised
        isDeposited
    {
        require(
            msg.sender == slasher,
            "Only the slasher can call this function."
        );
        require(canWithdraw[_depositorToBeSlashed], "cannot slash address");
        canWithdraw[_depositorToBeSlashed] = false;
        _burn(valuePerDepositor);
        emit Slash(_depositorToBeSlashed, valuePerDepositor);
    }

    function _init(
        uint _releaseTimestamp,
        address _slasher,
        address _depositorsProxy
    ) internal {
        require(!initialized, "The contract is already initialised.");
        require(
            _releaseTimestamp > block.timestamp,
            "The release timestamp must be in the future"
        );

        releaseTimestamp = _releaseTimestamp;
        slasher = _slasher;
        depositorsProxy = _depositorsProxy;
        initialized = true;
        owner = address(0);
    }

    /// Hooks for derived contracts to receive, transfer and burn the deposits
    function _receive(uint amount) internal virtual;

    function _transfer(address payable recipient, uint amount) internal virtual;

    function _burn(uint amount) internal virtual;
}


/*
  The TokenDepositLocker contract locks ERC20 token deposits

  For more information see DepositLocker.sol
*/

contract TokenDepositLocker is BaseDepositLocker {
    IERC20 public token;

    function init(
        uint _releaseTimestamp,
        address _slasher,
        address _depositorsProxy,
        IERC20 _token
    ) external onlyOwner {
        BaseDepositLocker._init(_releaseTimestamp, _slasher, _depositorsProxy);
        require(
            address(_token) != address(0),
            "Token contract can not be on the zero address!"
        );
        token = _token;
    }

    function _receive(uint amount) internal override {
        require(msg.value == 0, "Token locker contract does not accept ETH");
        // to receive erc20 tokens, we have to pull them
        token.transferFrom(msg.sender, address(this), amount);
    }

    function _transfer(address payable recipient, uint amount)
        internal
        override
    {
        token.transfer(recipient, amount);
    }

    function _burn(uint amount) internal override {
        token.burn(amount);
    }
}

abstract contract BaseValidatorAuction is Ownable {
    uint constant MAX_UINT = ~uint(0);

    // auction constants set on deployment
    uint public auctionDurationInDays;
    uint public startPrice;
    uint public minimalNumberOfParticipants;
    uint public maximalNumberOfParticipants;

    AuctionState public auctionState;
    BaseDepositLocker public depositLocker;
    mapping(address => bool) public whitelist;
    mapping(address => uint) public bids;
    address[] public bidders;
    uint public startTime;
    uint public closeTime;
    uint public lowestSlotPrice;

    event BidSubmitted(
        address bidder,
        uint bidValue,
        uint slotPrice,
        uint timestamp
    );
    event AddressWhitelisted(address whitelistedAddress);
    event AuctionDeployed(
        uint startPrice,
        uint auctionDurationInDays,
        uint minimalNumberOfParticipants,
        uint maximalNumberOfParticipants
    );
    event AuctionStarted(uint startTime);
    event AuctionDepositPending(
        uint closeTime,
        uint lowestSlotPrice,
        uint totalParticipants
    );
    event AuctionEnded(
        uint closeTime,
        uint lowestSlotPrice,
        uint totalParticipants
    );
    event AuctionFailed(uint closeTime, uint numberOfBidders);

    enum AuctionState {
        Deployed,
        Started,
        DepositPending, /* all slots sold, someone needs to call depositBids */
        Ended,
        Failed
    }

    modifier stateIs(AuctionState state) {
        require(
            auctionState == state,
            "Auction is not in the proper state for desired action."
        );
        _;
    }

    constructor(
        uint _startPriceInWei,
        uint _auctionDurationInDays,
        uint _minimalNumberOfParticipants,
        uint _maximalNumberOfParticipants,
        BaseDepositLocker _depositLocker
    ) {
        require(
            _auctionDurationInDays > 0,
            "Duration of auction must be greater than 0"
        );
        require(
            _auctionDurationInDays < 100 * 365,
            "Duration of auction must be less than 100 years"
        );
        require(
            _minimalNumberOfParticipants > 0,
            "Minimal number of participants must be greater than 0"
        );
        require(
            _maximalNumberOfParticipants > 0,
            "Number of participants must be greater than 0"
        );
        require(
            _minimalNumberOfParticipants <= _maximalNumberOfParticipants,
            "The minimal number of participants must be smaller than the maximal number of participants."
        );
        require(_startPriceInWei > 0, "The start price has to be > 0");
        require(
            // To prevent overflows
            _startPriceInWei < 10**30,
            "The start price is too big."
        );

        startPrice = _startPriceInWei;
        auctionDurationInDays = _auctionDurationInDays;
        maximalNumberOfParticipants = _maximalNumberOfParticipants;
        minimalNumberOfParticipants = _minimalNumberOfParticipants;
        depositLocker = _depositLocker;

        lowestSlotPrice = MAX_UINT;

        emit AuctionDeployed(
            startPrice,
            auctionDurationInDays,
            _minimalNumberOfParticipants,
            _maximalNumberOfParticipants
        );
        auctionState = AuctionState.Deployed;
    }

    receive() external payable stateIs(AuctionState.Started) {
        bid();
    }

    function bid() public payable stateIs(AuctionState.Started) {
        require(block.timestamp > startTime, "It is too early to bid.");
        require(
            block.timestamp <= startTime + auctionDurationInDays * 1 days,
            "Auction has already ended."
        );
        uint slotPrice = currentPrice();
        require(whitelist[msg.sender], "The sender is not whitelisted.");
        require(!isSenderContract(), "The sender cannot be a contract.");
        require(
            bidders.length < maximalNumberOfParticipants,
            "The limit of participants has already been reached."
        );

        require(bids[msg.sender] == 0, "The sender has already bid.");
        uint bidAmount = _getBidAmount(slotPrice);
        require(bidAmount > 0, "The bid amount has to be > 0");
        bids[msg.sender] = bidAmount;
        bidders.push(msg.sender);
        if (slotPrice < lowestSlotPrice) {
            lowestSlotPrice = slotPrice;
        }

        depositLocker.registerDepositor(msg.sender);
        emit BidSubmitted(msg.sender, bidAmount, slotPrice, block.timestamp);

        if (bidders.length == maximalNumberOfParticipants) {
            transitionToDepositPending();
        }
        _receiveBid(bidAmount);
    }

    function startAuction() public onlyOwner stateIs(AuctionState.Deployed) {
        require(
            depositLocker.initialized(),
            "The deposit locker contract is not initialized"
        );

        auctionState = AuctionState.Started;
        startTime = block.timestamp;

        emit AuctionStarted(block.timestamp);
    }

    function depositBids() public stateIs(AuctionState.DepositPending) {
        auctionState = AuctionState.Ended;
        _deposit(lowestSlotPrice, lowestSlotPrice * bidders.length);
        emit AuctionEnded(closeTime, lowestSlotPrice, bidders.length);
    }

    function closeAuction() public stateIs(AuctionState.Started) {
        require(
            block.timestamp > startTime + auctionDurationInDays * 1 days,
            "The auction cannot be closed this early."
        );
        assert(bidders.length < maximalNumberOfParticipants);

        if (bidders.length >= minimalNumberOfParticipants) {
            transitionToDepositPending();
        } else {
            transitionToAuctionFailed();
        }
    }

    function addToWhitelist(address[] memory addressesToWhitelist)
        public
        onlyOwner
        stateIs(AuctionState.Deployed)
    {
        for (uint32 i = 0; i < addressesToWhitelist.length; i++) {
            whitelist[addressesToWhitelist[i]] = true;
            emit AddressWhitelisted(addressesToWhitelist[i]);
        }
    }

    function withdraw() public {
        require(
            auctionState == AuctionState.Ended ||
                auctionState == AuctionState.Failed,
            "You cannot withdraw before the auction is ended or it failed."
        );

        if (auctionState == AuctionState.Ended) {
            withdrawAfterAuctionEnded();
        } else if (auctionState == AuctionState.Failed) {
            withdrawAfterAuctionFailed();
        } else {
            assert(false); // Should be unreachable
        }
    }

    function currentPrice()
        public
        view
        virtual
        stateIs(AuctionState.Started)
        returns (uint)
    {
        assert(block.timestamp >= startTime);
        uint secondsSinceStart = (block.timestamp - startTime);
        return priceAtElapsedTime(secondsSinceStart);
    }

    function priceAtElapsedTime(uint secondsSinceStart)
        public
        view
        returns (uint)
    {
        // To prevent overflows
        require(
            secondsSinceStart < 100 * 365 days,
            "Times longer than 100 years are not supported."
        );
        uint msSinceStart = 1000 * secondsSinceStart;
        uint relativeAuctionTime = msSinceStart / auctionDurationInDays;
        uint decayDivisor = 746571428571;
        uint decay = relativeAuctionTime**3 / decayDivisor;
        uint price =
            (startPrice * (1 + relativeAuctionTime)) /
                (1 + relativeAuctionTime + decay);
        return price;
    }

    function withdrawAfterAuctionEnded() internal stateIs(AuctionState.Ended) {
        require(
            bids[msg.sender] > lowestSlotPrice,
            "The sender has nothing to withdraw."
        );

        uint valueToWithdraw = bids[msg.sender] - lowestSlotPrice;
        assert(valueToWithdraw <= bids[msg.sender]);

        bids[msg.sender] = lowestSlotPrice;

        _transfer(payable(msg.sender), valueToWithdraw);
    }

    function withdrawAfterAuctionFailed()
        internal
        stateIs(AuctionState.Failed)
    {
        require(bids[msg.sender] > 0, "The sender has nothing to withdraw.");

        uint valueToWithdraw = bids[msg.sender];

        bids[msg.sender] = 0;

        _transfer(payable(msg.sender), valueToWithdraw);
    }

    function transitionToDepositPending()
        internal
        stateIs(AuctionState.Started)
    {
        auctionState = AuctionState.DepositPending;
        closeTime = block.timestamp;
        emit AuctionDepositPending(closeTime, lowestSlotPrice, bidders.length);
    }

    function transitionToAuctionFailed()
        internal
        stateIs(AuctionState.Started)
    {
        auctionState = AuctionState.Failed;
        closeTime = block.timestamp;
        emit AuctionFailed(closeTime, bidders.length);
    }

    function isSenderContract() internal view returns (bool isContract) {
        uint32 size;
        address sender = msg.sender;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            size := extcodesize(sender)
        }
        return (size > 0);
    }

    /// Hooks for derived contracts to process bids
    function _receiveBid(uint amount) internal virtual;

    function _transfer(address payable recipient, uint amount) internal virtual;

    function _deposit(uint slotPrice, uint totalValue) internal virtual;

    function _getBidAmount(uint slotPrice) internal view virtual returns (uint);
}

contract TokenValidatorAuction is BaseValidatorAuction {
    IERC20 public bidToken;

    constructor(
        uint _startPriceInWei,
        uint _auctionDurationInDays,
        uint _minimalNumberOfParticipants,
        uint _maximalNumberOfParticipants,
        TokenDepositLocker _depositLocker,
        IERC20 _bidToken
    )
        BaseValidatorAuction(
            _startPriceInWei,
            _auctionDurationInDays,
            _minimalNumberOfParticipants,
            _maximalNumberOfParticipants,
            _depositLocker
        )
    {
        bidToken = _bidToken;
    }

    function _receiveBid(uint amount) internal override {
        require(msg.value == 0, "Auction does not accept ETH for bidding");
        bidToken.transferFrom(msg.sender, address(this), amount);
    }

    function _transfer(address payable recipient, uint amount)
        internal
        override
    {
        bidToken.transfer(recipient, amount);
    }

    function _deposit(uint slotPrice, uint totalValue) internal override {
        bidToken.approve(address(depositLocker), totalValue);
        depositLocker.deposit(slotPrice);
    }

    function _getBidAmount(uint slotPrice)
        internal
        pure
        override
        returns (uint)
    {
        return slotPrice;
    }
}

// SPDX-License-Identifier: MIT