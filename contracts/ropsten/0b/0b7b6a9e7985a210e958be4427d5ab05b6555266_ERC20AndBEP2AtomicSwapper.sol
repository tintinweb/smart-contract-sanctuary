/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.5.10;

contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
}

contract ERC20AndBEP2AtomicSwapper {

    struct Swap {
        uint256 timelock;
        uint256 amount;
        bytes32 secretHashLock;
        bytes32 secretKey;
        address sender;
        address traderAddr;
        address BEP2Addr;
    }

    enum States {
        INVALID,
        OPEN,
        COMPLETED,
        EXPIRED
    }

    // Events
    event SwapInitialization(address indexed _traderAddr, bytes32 _swapID, bytes32 _secretHashLock, uint256 _timelock, address _BEP2Addr, uint256 _amount);
    event SwapExpire(bytes32 _swapID);
    event SwapCompletion(bytes32 _swapID, bytes32 _secretKey);

    // Storage
    mapping (bytes32 => Swap) private swaps;
    mapping (bytes32 => States) private swapStates;
    mapping (bytes32 => uint256) private redeemedAt;

    address public ERC20ContractAddr;
    address public owner;

    /// @notice Throws if the swap is not invalid (i.e. has already been opened)
    modifier onlyInvalidSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.INVALID, "swap opened previously");
        _;
    }

    /// @notice Throws if the swap is not open.
    modifier onlyOpenSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.OPEN, "swap not open");
        _;
    }

    /// @notice Throws if the swap is not expirable.
    modifier onlyExpirableSwaps(bytes32 _swapID) {
        /* solium-disable-next-line security/no-block-members */
        require(now >= swaps[_swapID].timelock, "swap not expirable");
        _;
    }

    /// @notice Throws if the timelock is expired
    modifier onlyBeforeExpireTime(bytes32 _swapID) {
        /* solium-disable-next-line security/no-block-members */
        require(now < swaps[_swapID].timelock, "swap is expired");
        _;
    }

    /// @notice Throws if the secret key is not valid.
    modifier onlyWithSecretKey(bytes32 _swapID, bytes32 _secretKey) {
        require(swaps[_swapID].secretHashLock == sha256(abi.encodePacked(_secretKey)), "invalid secret");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    function setERC20Address(address erc20Contract) public onlyOwner returns (bool) {
        if (erc20Contract != address(0)) {
            ERC20ContractAddr = erc20Contract;
            return true;
        }
        return false;
    }

    /// @notice Initiates the atomic swap.
    ///
    /// @param _swapID The unique atomic swap id.
    /// @param _BEP2Addr The receiver address on Binance Chain
    /// @param _traderAddr The ethereum address of the trader.
    /// @param _secretHashLock The hash of the secret (Hash Lock).
    /// @param _timelock The unix timestamp when the swap expires.
    /// @param _amount The token amount for swap.
    function initiate(
        bytes32 _swapID,
        address _BEP2Addr,
        address _traderAddr,
        bytes32 _secretHashLock,
        uint256 _timelock,
        uint256 _amount
    ) external onlyInvalidSwaps(_swapID) {
        // Transfer ERC20 token to the swap contract
        ERC20(ERC20ContractAddr).transferFrom(msg.sender, address(this), _amount);
        // Store the details of the swap.
        Swap memory swap = Swap({
            timelock: _timelock,
            amount: _amount,
            sender: msg.sender,
            traderAddr: _traderAddr,
            BEP2Addr: _BEP2Addr,
            secretHashLock: _secretHashLock,
            secretKey: 0x0
            });
        swaps[_swapID] = swap;
        swapStates[_swapID] = States.OPEN;

        // Emit initialization event
        emit SwapInitialization(_traderAddr, _swapID, _secretHashLock, _timelock, _BEP2Addr, _amount);
    }

    /// @notice Redeems an atomic swap.
    ///
    /// @param _swapID The unique atomic swap id.
    /// @param _secretKey The secret of the atomic swap.
    function redeem(bytes32 _swapID, bytes32 _secretKey) external onlyBeforeExpireTime(_swapID) onlyOpenSwaps(_swapID) onlyWithSecretKey(_swapID, _secretKey) {
        // Close the swap.
        swaps[_swapID].secretKey = _secretKey;
        swapStates[_swapID] = States.COMPLETED;
        /* solium-disable-next-line security/no-block-members */
        redeemedAt[_swapID] = now;

        // Pay erc20 token to trader
        ERC20(ERC20ContractAddr).transfer(swaps[_swapID].traderAddr, swaps[_swapID].amount);

        // Emit completion event
        emit SwapCompletion(_swapID, _secretKey);
    }

    /// @notice Refunds an atomic swap.
    ///
    /// @param _swapID The unique atomic swap id.
    function refund(bytes32 _swapID) external onlyOpenSwaps(_swapID) onlyExpirableSwaps(_swapID) {
        // Expire the swap.
        swapStates[_swapID] = States.EXPIRED;

        // refund erc20 token to swap creator
        ERC20(ERC20ContractAddr).transfer(swaps[_swapID].sender, swaps[_swapID].amount);

        // Emit expire event
        emit SwapExpire(_swapID);
    }

    /// @notice Audits an atomic swap.
    ///
    /// @param _swapID The unique atomic swap id.
    function auditSwap(bytes32 _swapID) external view returns (uint256 timelock, uint256 amount, address from, address to, address BEP2Addr, bytes32 secretHashLock, bytes32 secretKey) {
        Swap memory swap = swaps[_swapID];
        return (
        swap.timelock,
        swap.amount,
        swap.sender,
        swap.traderAddr,
        swap.BEP2Addr,
        swap.secretHashLock,
        swap.secretKey
        );
    }

    /// @notice Checks whether a swap is refundable or not.
    ///
    /// @param _swapID The unique atomic swap id.
    function refundable(bytes32 _swapID) external view returns (bool) {
        /* solium-disable-next-line security/no-block-members */
        return (now >= swaps[_swapID].timelock && swapStates[_swapID] == States.OPEN);
    }

    /// @notice Checks whether a swap is initiatable or not.
    ///
    /// @param _swapID The unique atomic swap id.
    function initiatable(bytes32 _swapID) external view returns (bool) {
        return (swapStates[_swapID] == States.INVALID);
    }

    /// @notice Checks whether a swap is redeemable or not.
    ///
    /// @param _swapID The unique atomic swap id.
    function redeemable(bytes32 _swapID) external view returns (bool) {
        return (now < swaps[_swapID].timelock && swapStates[_swapID] == States.OPEN);
    }

    /// @notice Query the redeem timestamp
    ///
    /// @param _swapID The unique atomic swap id.
    function redeemaAt(bytes32 _swapID) external view returns (uint256) {
        return redeemedAt[_swapID];
    }

    /// @notice Generates a deterministic swap id using initiate swap details.
    ///
    /// @param _secretHashLock The hash of the secret.
    /// @param _timelock The expiry timestamp.
    function swapID(bytes32 _secretHashLock, uint256 _timelock) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_secretHashLock, _timelock));
    }

    /// @notice Generates the hash of secretKey, only for test
    ///
    /// @param _secretKey The secret.
    function hashSecretKey(bytes32 _secretKey) public pure returns (bytes32) {
        return sha256(abi.encodePacked(_secretKey));
    }
}