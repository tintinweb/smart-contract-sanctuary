/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-06-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract Flipmmer is Ownable, ReentrancyGuard {
    bool public paused = false;
    uint256 public fees;

    uint256[] public betAmounts = [1 ether, 5 ether, 10 ether, 100 ether];

    enum CoinSide {
        HEADS,
        TAILS
    }

    constructor(uint256 fees_) {
        fees = fees_;
    }

    receive() external payable {}

    event Flipped(
        address indexed flipper,
        bool indexed win,
        uint256 indexed amount
    );

    function setBetAmounts(uint256[] calldata amounts) external onlyOwner {
        betAmounts = amounts;
    }

    function feeInfo(uint256 amount) internal view returns (uint256) {
        return (amount * fees) / 100_00;
    }

    function withdrawInEth(uint256 amount) external onlyOwner {
        _withdraw(amount * 1 ether);
    }

    function _withdraw(uint256 amount) private {
        (bool sent, ) = payable(owner()).call{ value: amount }('');
        require(sent, 'Failed to send Ether');
    }

    function flip(uint256 guess, uint256 betIndex) public payable nonReentrant {
        require(!paused, 'game is currently paused.');
        require(guess == 1 || guess == 0, 'Invalid guess');
        require(
            betIndex < betAmounts.length && betIndex >= 0,
            "Bet doesn't exists."
        );
        require(msg.value == betAmounts[betIndex], 'Sent is not exact');
        uint256 randomFlip = random();
        if (randomFlip == guess) {
            uint256 winAmount = msg.value * 2;
            uint256 feesD = feeInfo(winAmount);
            uint256 actualWin = winAmount - feesD;
            require(address(this).balance >= actualWin, 'Not enough balance');
            (bool sent, ) = payable(msg.sender).call{ value: actualWin }('');
            require(sent, 'Failed to send Ether');
            emit Flipped(msg.sender, true, actualWin);
        } else {
            emit Flipped(msg.sender, false, 0);
        }
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, owner())
                )
            ) % 2;
    }

    function withdrawAll() external onlyOwner {
        _withdraw(address(this).balance);
    }

    function setPaused(bool state) external onlyOwner {
        paused = state;
    }

    function fetchBetAmounts() public view returns (uint256[] memory) {
        return betAmounts;
    }
}