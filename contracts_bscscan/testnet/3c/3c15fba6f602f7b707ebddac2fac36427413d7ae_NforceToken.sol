/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

pragma solidity 0.5.16;


contract ReentrancyGuard {
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

    constructor () public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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


library SafeMath {

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    /**
        * @dev Returns the subtraction of two unsigned integers, reverting on
        * overflow (when the result is negative).
        *
        * Counterpart to Solidity's `-` operator.
        *
        * Requirements:
        *
        * - Subtraction cannot overflow.
        */
    function subwithlesszero(uint256 a, uint256 b) internal pure returns (uint256)
    {
        if (b > a)
            return 0;
        else
            return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


contract NforceToken is ReentrancyGuard {

    using SafeMath for uint256;

    address private _owner; //owner

    address[] _allAddress; //all address

    mapping(address => uint256) _balance;

    mapping(address => uint256) _storage;

    mapping(address => uint256) _profit;

    uint256 _buyVipPrice = 1500; //buy vip price

    uint256 _allTotalStorage; //all total storage

    uint256 _totalWithdrawalNum; // total withdrawal num

    constructor () public {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'No Owner');
        _;
    }

    function getUserBalance(address _user) view public returns (uint256){
        return _balance[_user];
    }

    function getUserProfit(address _user) view public returns (uint256){
        return _profit[_user];
    }

    function getUserStorage(address _user) view public returns (uint256){
        return _storage[_user];
    }


    function addBalance(address _user, uint256 amount) public onlyOwner {
        _balance[_user] = _balance[_user].add(amount);
    }

    function dedBalance(address _user, uint256 amount) public onlyOwner {
        _balance[_user] = _balance[_user].sub(amount);
    }


    //batch add blance
    function batchAddBlance(address[] memory _user, uint256[] memory _amount) public onlyOwner returns (bool) {

        for (uint32 i = 0; i < _user.length; i++) {
            addBalance(_user[i], _amount[i]);
        }
        return true;
    }

    //batch ded blance
    function batchDedBlance(address[] memory _user, uint256[] memory _amount) public onlyOwner returns (bool) {

        for (uint32 i = 0; i < _user.length; i++) {
            dedBalance(_user[i], _amount[i]);
        }
        return true;
    }


    function addProfit(address _user, uint256 _amount) public onlyOwner
    {
        _profit[_user] = _profit[_user].add(_amount);
    }

    function dedProfit(address _user, uint256 _amount) public onlyOwner
    {
        _profit[_user] = _profit[_user].sub(_amount);
    }


    //batch add Profit
    function batchAddProfit(address[] memory _user, uint256[] memory _amount) public onlyOwner returns (bool) {

        for (uint32 i = 0; i < _user.length; i++) {
            addProfit(_user[i], _amount[i]);
        }
        return true;
    }

    //batch ded Profit
    function batchDedProfit(address[] memory _user, uint256[] memory _amount) public onlyOwner returns (bool) {

        for (uint32 i = 0; i < _user.length; i++) {
            dedProfit(_user[i], _amount[i]);
        }
        return true;
    }


    function addUserStorage(address _user, uint256 _amount) public onlyOwner
    {
        _storage[_user] = _storage[_user].add(_amount);
        _allTotalStorage = _allTotalStorage.add(_amount);
    }

    //releaseUser
    function dedUserStorage(address _user, uint256 _amount) public onlyOwner
    {
        _storage[_user] = _storage[_user].sub(_amount);
        _allTotalStorage = _allTotalStorage.sub(_amount);
    }


    //batch add Storage
    function batchAddStorage(address[] memory _user, uint256[] memory _amount) public onlyOwner returns (bool) {

        for (uint32 i = 0; i < _user.length; i++) {
            addUserStorage(_user[i], _amount[i]);
        }
        return true;
    }


    //batch ded Storage
    function batchDedStorage(address[] memory _user, uint256[] memory _amount) public onlyOwner returns (bool) {

        for (uint32 i = 0; i < _user.length; i++) {
            dedUserStorage(_user[i], _amount[i]);
        }
        return true;
    }


    function getAllStorage() view public returns (uint256){
        return _allTotalStorage;
    }


    function getAllAddressNumber() view public returns (uint256){
        return _allAddress.length;
    }


    function pushAllAddress(address _user) public onlyOwner {
        _allAddress.push(_user);
    }

    function addWithdrawalNum(uint256 _amount) public onlyOwner {
        _totalWithdrawalNum = _totalWithdrawalNum.add(_amount);
        _allTotalStorage = _allTotalStorage.sub(_amount);
    }


    function getTotalWithdrawalNum() view public returns (uint256){
        return _totalWithdrawalNum;
    }

}