/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity 0.5.8;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

contract ERC20AtomicSwapper {

    struct Swap {
        uint256 outAmount;
        uint256 expireHeight;
        bytes32 randomNumberHash;
        uint64  timestamp;
        address sender;
        address recipientAddr;
        address refundRecipientAddr;
    }

    enum States {
        INVALID,
        OPEN,
        COMPLETED,
        EXPIRED
    }

    // Events
    event HTLT(address indexed _sender, bytes32 indexed _swapID, bytes32 _randomNumberHash, uint64 _timestamp, bytes20 _bep2Addr, uint256 _expireHeight, uint256 _outAmount, uint256 _bep2Amount, address _refundRecipientAddr);
    event Refunded(address indexed _sender, address indexed _recipientAddr, bytes32 indexed _swapID, bytes32 _randomNumberHash, address _refundRecipientAddr);
    event Claimed(address indexed _sender, address indexed _recipientAddr, bytes32 indexed _swapID, bytes32 _randomNumberHash, bytes32 _randomNumber);

    // Storage
    mapping (bytes32 => Swap) private swaps;
    mapping (bytes32 => States) private swapStates;

    address public ERC20ContractAddr;
    address public ERC20ApplicationAddr;

    /// @notice Throws if the swap is not open.
    modifier onlyOpenSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.OPEN, "swap is not opened");
        _;
    }

    /// @notice Throws if the swap is already expired.
    modifier onlyAfterExpireHeight(bytes32 _swapID) {
        require(block.number >= swaps[_swapID].expireHeight, "swap is not expired");
        _;
    }

    /// @notice Throws if the expireHeight is reached
    modifier onlyBeforeExpireHeight(bytes32 _swapID) {
        require(block.number < swaps[_swapID].expireHeight, "swap is already expired");
        _;
    }

    /// @notice Throws if the random number is not valid.
    modifier onlyWithRandomNumber(bytes32 _swapID, bytes32 _randomNumber) {
        require(swaps[_swapID].randomNumberHash == sha256(abi.encodePacked(_randomNumber, swaps[_swapID].timestamp)), "invalid randomNumber");
        _;
    }

    /// @param _erc20Contract The ERC20 contract address
    constructor(address _erc20Contract, address _erc20ApplicationAddr) public {
        ERC20ContractAddr = _erc20Contract;
        ERC20ApplicationAddr = _erc20ApplicationAddr;
    }

    /// @notice htlt locks asset to contract address and create an atomic swap.
    ///
    /// @param _randomNumberHash The hash of the random number and timestamp
    /// @param _timestamp Counted by second
    /// @param _heightSpan The number of blocks to wait before the asset can be returned to sender
    /// @param _recipientAddr The ethereum address of the swap counterpart.
    /// @param _bep2SenderAddr the swap sender address on Binance Chain
    /// @param _bep2RecipientAddr The recipient address on Binance Chain
    /// @param _outAmount ERC20 asset to swap out.
    /// @param _bep2Amount BEP2 asset to swap in.
    function htlt(
        bytes32 _randomNumberHash,
        uint64  _timestamp,
        uint256 _heightSpan,
        address _senderAddr,
        address _recipientAddr,
        bytes20 _bep2SenderAddr,
        bytes20 _bep2RecipientAddr,
        uint256 _outAmount,
        uint256 _bep2Amount,
        address _refundRecipientAddr
    ) external returns (bool) {
        bytes32 swapID = calSwapID(_randomNumberHash, _senderAddr, _bep2SenderAddr);
        require(swapStates[swapID] == States.INVALID, "swap is opened previously");
        // Assume average block time interval is 10 second
        // The heightSpan period should be more than 10 minutes and less than one week
        require(_heightSpan >= 60 && _heightSpan <= 60480, "_heightSpan should be in [60, 60480]");
        require(_senderAddr != address(0), "_senderAddr should not be zero");
        require(_recipientAddr != address(0), "_recipientAddr should not be zero");
        require(_outAmount > 0, "_outAmount must be more than 0");
        require(_timestamp > now - 1800 && _timestamp < now + 900, "Timestamp can neither be 15 minutes ahead of the current time, nor 30 minutes later");
        require(_refundRecipientAddr != address(0), "_refundRecipientAddr should not be zero");
        
        // Store the details of the swap.
        Swap memory swap = Swap({
            outAmount: _outAmount,
            expireHeight: _heightSpan + block.number,
            randomNumberHash: _randomNumberHash,
            timestamp: _timestamp,
            sender: _senderAddr,
            recipientAddr: _recipientAddr,
            refundRecipientAddr: _refundRecipientAddr
        });

        swaps[swapID] = swap;
        swapStates[swapID] = States.OPEN;

        // Transfer ERC20 token to the swap contract
        require(ERC20(ERC20ContractAddr).transferFrom(_senderAddr, address(this), _outAmount), "failed to transfer client asset to swap contract address");  

        // Emit initialization event
        emit HTLT(_senderAddr, swapID, _randomNumberHash, _timestamp, _bep2RecipientAddr, swap.expireHeight, _outAmount, _bep2Amount, _refundRecipientAddr);
        return true;
    }

    /// @notice claim claims the previously locked asset.
    ///
    /// @param _swapID The hash of randomNumberHash, swap creator and swap recipient
    /// @param _randomNumber The random number
    function claim(bytes32 _swapID, bytes32 _randomNumber) external onlyOpenSwaps(_swapID) onlyBeforeExpireHeight(_swapID) onlyWithRandomNumber(_swapID, _randomNumber) returns (bool) {
        // Complete the swap.
        swapStates[_swapID] = States.COMPLETED;

        address senderAddr = swaps[_swapID].sender;
        address recipientAddr = swaps[_swapID].recipientAddr;
        uint256 outAmount = swaps[_swapID].outAmount;
        bytes32 randomNumberHash = swaps[_swapID].randomNumberHash;
        // delete closed swap
        delete swaps[_swapID];

        // Pay erc20 token to recipient
        require(ERC20(ERC20ContractAddr).transfer(recipientAddr, outAmount), "Failed to transfer locked asset to recipient");

        // Emit completion event
        emit Claimed(senderAddr, recipientAddr, _swapID, randomNumberHash, _randomNumber);

        return true;
    }

    /// @notice refund refunds the previously locked asset.
    ///
    /// @param _swapID The hash of randomNumberHash, swap creator and swap recipient
    function refund(bytes32 _swapID) external onlyOpenSwaps(_swapID) onlyAfterExpireHeight(_swapID) returns (bool) {
        // Expire the swap.
        swapStates[_swapID] = States.EXPIRED;

        address swapSender = swaps[_swapID].sender;
        uint256 outAmount = swaps[_swapID].outAmount;
        bytes32 randomNumberHash = swaps[_swapID].randomNumberHash;
        address refundRecipientAddr = swaps[_swapID].refundRecipientAddr;
        // delete closed swap
        delete swaps[_swapID];

        // refund erc20 token to swap creator
        require(ERC20(ERC20ContractAddr).transfer(refundRecipientAddr, outAmount), "Failed to transfer locked asset back to swap creator");  

        // Emit expire event
        emit Refunded(msg.sender, swapSender, _swapID, randomNumberHash, refundRecipientAddr);    

        return true;
    }

    /// @notice query an atomic swap by randomNumberHash
    ///
    /// @param _swapID The hash of randomNumberHash, swap creator and swap recipient
    function queryOpenSwap(bytes32 _swapID) external view returns(bytes32 _randomNumberHash, uint64 _timestamp, uint256 _expireHeight, uint256 _outAmount, address _sender, address _recipient, address _refundRecipientAddr) {
        Swap memory swap = swaps[_swapID];
        return (
            swap.randomNumberHash,
            swap.timestamp,
            swap.expireHeight,
            swap.outAmount,
            swap.sender,
            swap.recipientAddr,
            swap.refundRecipientAddr
        );
    }

    /// @notice Checks whether a swap with specified swapID exist
    ///
    /// @param _swapID The hash of randomNumberHash, swap creator and swap recipient
    function isSwapExist(bytes32 _swapID) external view returns (bool) {
        return (swapStates[_swapID] != States.INVALID);
    }

    /// @notice Checks whether a swap is refundable or not.
    ///
    /// @param _swapID The hash of randomNumberHash, swap creator and swap recipient
    function refundable(bytes32 _swapID) external view returns (bool) {
        return (block.number >= swaps[_swapID].expireHeight && swapStates[_swapID] == States.OPEN);
    }

    /// @notice Checks whether a swap is claimable or not.
    ///
    /// @param _swapID The hash of randomNumberHash, swap creator and swap recipient
    function claimable(bytes32 _swapID) external view returns (bool) {
        return (block.number < swaps[_swapID].expireHeight && swapStates[_swapID] == States.OPEN);
    }

    /// @notice Calculate the swapID from randomNumberHash and swapCreator
    ///
    /// @param _randomNumberHash The hash of random number and timestamp.
    /// @param _swapSender The creator of swap.
    /// @param _bep2SenderAddr The sender of swap on Binance Chain.
    function calSwapID(bytes32 _randomNumberHash, address _swapSender, bytes20 _bep2SenderAddr) public pure returns (bytes32) {
        if (_bep2SenderAddr == bytes20(0)) {
            return sha256(abi.encodePacked(_randomNumberHash, _swapSender));
        }
        return sha256(abi.encodePacked(_randomNumberHash, _swapSender, _bep2SenderAddr));
    }
}