/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

pragma solidity >=0.4.22;

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

interface IaToken {
    function balanceOf(address _user) external view returns (uint256);
    function redeem(uint256 _amount) external;
}

interface IAaveLendingPool {
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external;
}

contract AaveExample {
    IERC20 public eth = IERC20(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    IaToken public aToken = IaToken(0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347);
    IAaveLendingPool public aaveLendingPool = IAaveLendingPool(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
    
    event test(uint16);
    
    mapping(address => uint256) public userDepositedDai;
    
    constructor() {
        eth.approve(address(aaveLendingPool), type(uint256).max);
    }
    
    function deposit(uint256 _amount) external {
        emit test(1);
        userDepositedDai[msg.sender] = _amount;
        emit test(2);
        require(eth.transferFrom(msg.sender, address(this), _amount), "ETH Transfer failed!");
        emit test(3);
        aaveLendingPool.deposit(address(eth), _amount, 0);
        emit test(4);
    }
    
    function withdraw(uint256 _amount) external {
        emit test(1);
        require(userDepositedDai[msg.sender] >= _amount, "You cannot withdraw more than deposited!");
        emit test(2);
        aToken.redeem(_amount);
        emit test(3);
        require(eth.transferFrom(address(this), msg.sender, _amount), "ETH Transfer failed!");
        emit test(4);
        userDepositedDai[msg.sender] = userDepositedDai[msg.sender] - _amount;
        emit test(5);
    }
    
    function testFuncExternal() external pure {
        require(false, "Error!");
    }
    
    function testFuncPublic() public pure {
        require(false, "Error!");
    }
}