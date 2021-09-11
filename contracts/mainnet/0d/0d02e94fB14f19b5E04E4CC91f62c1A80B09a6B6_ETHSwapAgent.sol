pragma solidity >=0.6.4;

import "./IERC20Query.sol";
import "./Context.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";

contract ETHSwapAgent is Context, Initializable {

    using SafeERC20 for IERC20;

    mapping(address => bool) public registeredERC20;
    mapping(bytes32 => bool) public filledBSCTx;
    address payable public owner;
    uint256 public swapFee;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SwapPairRegister(address indexed sponsor,address indexed erc20Addr, string name, string symbol, uint8 decimals);
    event SwapStarted(address indexed erc20Addr, address indexed fromAddr, uint256 amount, uint256 feeAmount);
    event SwapFilled(address indexed erc20Addr, bytes32 indexed bscTxHash, address indexed toAddress, uint256 amount);

    constructor() public {
    }

    function initialize(uint256 fee, address payable ownerAddr) public initializer {
        swapFee = fee;
        owner = ownerAddr;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier notContract() {
        require(!isContract(msg.sender), "contract is not allowed to swap");
        require(msg.sender == tx.origin, "no proxy contract is allowed");
       _;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    /**
        * @dev Leaves the contract without owner. It will not be possible to call
        * `onlyOwner` functions anymore. Can only be called by the current owner.
        *
        * NOTE: Renouncing ownership will leave the contract without an owner,
        * thereby removing any functionality that is only available to the owner.
        */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Returns set minimum swap fee from ERC20 to BEP20
     */
    function setSwapFee(uint256 fee) onlyOwner external {
        swapFee = fee;
    }

    function registerSwapPairToBSC(address erc20Addr) external returns (bool) {
        require(!registeredERC20[erc20Addr], "already registered");

        string memory name = IERC20Query(erc20Addr).name();
        string memory symbol = IERC20Query(erc20Addr).symbol();
        uint8 decimals = IERC20Query(erc20Addr).decimals();

        require(bytes(name).length>0, "empty name");
        require(bytes(symbol).length>0, "empty symbol");

        registeredERC20[erc20Addr] = true;

        emit SwapPairRegister(msg.sender, erc20Addr, name, symbol, decimals);
        return true;
    }

    function fillBSC2ETHSwap(bytes32 bscTxHash, address erc20Addr, address toAddress, uint256 amount) onlyOwner external returns (bool) {
        require(!filledBSCTx[bscTxHash], "bsc tx filled already");
        require(registeredERC20[erc20Addr], "not registered token");

        filledBSCTx[bscTxHash] = true;
        IERC20(erc20Addr).safeTransfer(toAddress, amount);

        emit SwapFilled(erc20Addr, bscTxHash, toAddress, amount);
        return true;
    }

    function swapETH2BSC(address erc20Addr, uint256 amount) payable external notContract returns (bool) {
        require(registeredERC20[erc20Addr], "not registered token");
        require(msg.value == swapFee, "swap fee not equal");

        IERC20(erc20Addr).safeTransferFrom(msg.sender, address(this), amount);
        if (msg.value != 0) {
            owner.transfer(msg.value);
        }

        emit SwapStarted(erc20Addr, msg.sender, amount, msg.value);
        return true;
    }
}