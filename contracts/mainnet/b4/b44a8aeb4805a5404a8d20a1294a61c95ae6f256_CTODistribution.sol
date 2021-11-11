/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


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


contract CTODistribution is Ownable{
    IERC20 public constant CTO = IERC20(0xa5e48a6E56e164907263e901B98D9b11CCB46C47);
    mapping(address => uint256) public balance;

    constructor()
    {
        transferOwnership(0xDAc57a2C77a64AEFC171339F2891871d9A298EC5);

        balance[0x707E4A05B3dDC2049387BF7B7CFe82D6F09e986e] = 1464286 * (10 ** (18 - 1));
        balance[0x316D0e55B47ad86443b25EAa088e203482645046] = 75000 * (10 ** 18);
        balance[0xA7060deA79008DEf99508F50DaBDCDe7293c1D8A] = 69741 * (10 ** 18);

        balance[0x3C68319b15Bc0145ce111636f6d8043ACF4D59f6] = 57143 * (10 ** 18);
        balance[0x175dd00579DF16669fC993F8AFA4EE8AA962865A] = 57143 * (10 ** 18);
        balance[0x729Ea64B1393eD633C069aF04b45e1212905b4A9] = 30000 * (10 ** 18);
        balance[0x2C9bC9793AD5c24feD22654Ee13F287329668B55] = 142858 * (10 ** (18 - 1));
        balance[0x2295b2e2F0C8CF5e4E9c2cae33ad4F4cCbc95fD5] = 214286 * (10 ** (18 - 1));

        balance[0xB7d41bb3863E403c29Fe4CA85D31206b6b507630] = 62500 * (10 ** 18);
        balance[0x6D9e32012eC93EBb858F9103B9F7f52eBAb6299F] = 87500 * (10 ** 18);
        balance[0x97CA08d4CA2015545eeb81ca71d1Ac719Fe4A8F6] = 31250 * (10 ** 18);
        balance[0x32c9B7BD4E0aaBDe8C81cBe5d3fE30E01d34329B] = 218750 * (10 ** 18);

        balance[0x16f9cEB2D822ee203a304635d12897dBD2cEeB75] = 31250 * (10 ** 18);
        balance[0xe32341a633FA57CA963D2F2dc78D31D76ee258B7] = 21875 * (10 ** 18);
        balance[0xE88540354a9565300D2E7109d7737508F4155A4d] = 18750 * (10 ** 18);
        balance[0x570DaFD281d70d8d69D19c5A004b0FC3fF52Fd0b] = 18750 * (10 ** 18);
        balance[0x9D400eb10623d34CCEc7aaa9FC347921866B9c86] = 25000 * (10 ** 18);

        balance[0xb87230a8169366051b1732DfB4687F2A041564cf] = 70475 * (10 ** (18 - 1));
        balance[0x67c069523115A6ffE9192F85426cF79f8b4ba7a5] = 862075 * (10 ** (18 - 2));
        balance[0x8786CB3682Cb347AE1226b5A15E991339A877Dfb] = 862075 * (10 ** (18 - 2));
    }


    function addBalance(address _user, uint _amount) external onlyOwner{
        balance[_user] = balance[_user] + _amount;
    }

    function resetBalance(address _user) external onlyOwner{
        balance[_user] = 0;
    }

    function withdraw() external {
        address user = _msgSender();
        uint canWithdraw = balance[user];
        require(canWithdraw > 0, "Insufficient balance");
        balance[user] = 0;
        CTO.transfer(user, canWithdraw);
    }
}