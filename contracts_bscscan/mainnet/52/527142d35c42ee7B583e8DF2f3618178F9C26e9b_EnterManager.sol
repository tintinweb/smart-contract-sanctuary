pragma solidity ^0.4.25;
import "./SafeMath.sol";

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
    function mint(address account, uint amount) external;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface IPlayerManager {
    function RegisterMember(address regAdress, address invitePlayer) external;
}

//0x527142d35c42ee7B583e8DF2f3618178F9C26e9b
contract EnterManager{
    using SafeMath for uint256;
    uint256 amount = 0.0031 * 1e18;

    address public governance;//合约部署人地址
    address public playerBook;//邀请合约
    bool public open = true;//邀请合约
    IERC20 public bnb = IERC20(0xb8c77482e45f1f44de1745f52c74426c631bdd52);

    constructor() public{
        governance = msg.sender;
        playerBook = 0x8BD0E37411f23FE2b183EF07527d63B7AFA598C8;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setAmount(uint256 _amount) public {
        require(msg.sender == governance, "!governance");
        amount = _amount;
    }

    function setOpen(bool _open) public {
        require(msg.sender == governance, "!governance");
        open = _open;
    }

    function setPlayerBook(address book) public {
        require(msg.sender == governance, "!governance");
        playerBook = book;
    }

    function setMiMiContract(address mimi)  public {
        require(msg.sender == governance, "!governance");
        bnb = IERC20(mimi);
    }

    function registerUser(address invitePlayer) public{
        if(playerBook != address(0)){
            bnb.transfer(msg.sender, amount);
            IPlayerManager(playerBook).RegisterMember(msg.sender, invitePlayer);
        }
    }
}