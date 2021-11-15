// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BOABridge {
    struct Swap {
        uint256 timelock;
        uint256 value;
        address BOASwapper;
        address recipient;
        bytes32 secretLock;
    }
    
    enum States {
        INVALID,
        OPEN,
        CLOSED,
        EXPIRED
    }
    
    address public BOATokenAddress;
    uint constant public MINIMUM_AMOUNT = 10000000;
    uint constant TIMELOCK = 3 hours;
    address public owner;
    

    uint public required;
    bool public paused = false;
    
    mapping (bytes32 => Swap) private swaps;
    mapping (bytes32 => States) private swapStates;

    event Open(bytes32 _swapID, address _withdrawTrader,bytes32 _secretLock, uint _amount);
    event Expire(bytes32 _swapID);
    event Close(bytes32 _swapID);
    
    
    /*
     *  Modifiers
     */
    
    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier isBOAAddress(bytes calldata _address) {
        
        require(keccak256(_address[:3]) == keccak256(bytes("boa")), "Invalid BOA Address");
        require(_address.length == 63, "Invalid BOA Address length");
        _;
    }


    modifier notPaused() {
        require(!paused, "Contract must not be paused");
        _;
    }

    modifier onlyInvalidSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.INVALID, "Swap must be invalid");
        _;
    }

    modifier onlyOpenSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.OPEN, "Swap must be open");
        _;
    }

    modifier onlyClosedSwaps(bytes32 _swapID) {
        require(swapStates[_swapID] == States.CLOSED, "Swap must be closed");
        _;
    }

    modifier onlyExpirableSwaps(bytes32 _swapID) {
        require(block.timestamp >= swaps[_swapID].timelock, "Swap must be expired");
        _;
    }

    modifier onlyWithSecretKey(bytes32 _swapID, bytes memory _secretKey) {
        // require(_secretKey.length == 63);
        require(swaps[_swapID].secretLock == sha256(_secretKey), "Wrong secret key");
        _;
    }


    function pauseSwaps()
    public
    isOwner()
    {
        paused = true;
    }

    function unPauseSwaps()             
    public
    isOwner()
    {
        paused = false;
    }
    
    function open(bytes32 _swapID, bytes calldata _recipient, bytes32 _secretLock, uint256 _amount) notPaused() isBOAAddress(_recipient) public onlyInvalidSwaps(_swapID) {
        
        require(_amount >= MINIMUM_AMOUNT, "Require transfer greater than minimum");
        
        require(tokenTransfer(msg.sender, address(this), _amount), "Failed to transfer tokens. Check Allowance?");
        
        address _recipientAddr = bytesToAddress(_recipient);
        // Store the details of the swap.
        Swap memory swap = Swap({
            timelock: block.timestamp + TIMELOCK,
            value: _amount,
            BOASwapper: msg.sender,
            recipient: _recipientAddr,
            secretLock: _secretLock
        });
        swaps[_swapID] = swap;
        swapStates[_swapID] = States.OPEN;

        // Trigger open event.
        emit Open(_swapID, _recipientAddr, _secretLock, _amount);
    }

    function close(bytes32 _swapID, bytes memory _secretKey) public onlyOpenSwaps(_swapID)
        onlyWithSecretKey(_swapID, _secretKey) {

        // Close the swap.
        swapStates[_swapID] = States.CLOSED;
        
        // Trigger close event.
        emit Close(_swapID);
    }

    function expire(bytes32 _swapID) public onlyOpenSwaps(_swapID) onlyExpirableSwaps(_swapID) {
        // Expire the swap.
        Swap memory swap = swaps[_swapID];
        swapStates[_swapID] = States.EXPIRED;

        // Transfer the BOA tokens from this contract to the withdrawing trader.
        tokenTransfer(address(this), swap.recipient, swap.value);

        // Trigger expire event.
        emit Expire(_swapID);
    }

    function check(bytes32 _swapID) public view returns (uint256 timelock, uint256 value,
        address withdrawTrader, bytes32 secretLock) {

        Swap memory swap = swaps[_swapID];
        return (swap.timelock, swap.value, swap.recipient, swap.secretLock);
    }
    
    function tokenTransfer(address _from, address _to, uint _amount) internal returns (bool){
        
        IERC20 token = IERC20(BOATokenAddress);

        token.transferFrom(_from, _to, _amount);
        return true;
    }
    
    function bytesToAddress(bytes memory source) public pure returns(address addr) {
        assembly {
            addr := mload(add(source, 0x14))
        }
    }


    
    constructor (address BOATokenAddressArg) {
        
        BOATokenAddress = BOATokenAddressArg;
        owner = msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

