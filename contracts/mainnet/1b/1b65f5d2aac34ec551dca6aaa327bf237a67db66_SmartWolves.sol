/*
/ _\_ __ ___   __ _ _ __| |_/ / /\ \ \___ | |_   _____  ___
\ \| '_ ` _ \ / _` | '__| __\ \/  \/ / _ \| \ \ / / _ \/ __|
_\ \ | | | | | (_| | |  | |_ \  /\  / (_) | |\ V /  __/\__ \
\__/_| |_| |_|\__,_|_|   \__| \/  \/ \___/|_| \_/ \___||___/
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >= 0.6.12;

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
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

contract SmartWolves {
    using SafeMath for uint;

    uint status;

    uint registrationFee;

    address payable public companyAccount;

    event Enrolled(
        uint8 indexed pool,
        address indexed payerAddress,
        string indexed username,
        uint amount
    );

    event PoolPurchased(
        uint8 indexed pool,
        address indexed payerAddress,
        uint amount,
        string indexed username
    );

    event PayoutSuccess(
        address indexed payee,
        string indexed username,
        uint amount
    );

    event NewDeposit(
        address indexed payer,
        uint amount
    );

    event CompanyAccountChanged(
        address indexed oldAccount,
        address indexed newAccount
    );

    struct User {
        bool status;
        uint8 pool;
        address paymentAddress;
        string userName;
    }

    mapping(uint8 => uint) public pools;

    mapping(string => User) public users;

    constructor(uint _registrationFee) public {
        registrationFee = _registrationFee;
        companyAccount = msg.sender;

        pools[1] = 50000000000000000;
        pools[2] = 200000000000000000;
        pools[3] = 500000000000000000;
        pools[4] = 1000000000000000000;
        pools[5] = 2000000000000000000;
        pools[6] = 5000000000000000000;
        pools[7] = 10000000000000000000;
        pools[8] = 20000000000000000000;
        pools[9] = 30000000000000000000;
        pools[10] = 50000000000000000000;
        pools[11] = 100000000000000000000;
    }

    modifier onlyOwner(){
        require(msg.sender == companyAccount, 'Sorry this can be only by the admin account!');
        _;
    }

    modifier noContract(address _address){
        require(!isContract(_address), 'Payment to a contract is not allowed!');
        _;
    }

    modifier notEnrolledAlready(string memory _username){
        require(users[_username].status == false, 'You seems like have been enrolled already!');
        _;
    }

    function enrol(string calldata _username, uint8 _pool) external payable notEnrolledAlready(_username) {
        require(msg.value >= pools[_pool].add(registrationFee), 'Please send the correct amount!');

        depositAmount(companyAccount, msg.value);
        // Enrol user
        users[_username] = User(true, _pool, msg.sender, _username);
        // Emit event telling that there is a new enrolment
        emit Enrolled(_pool, msg.sender, _username, msg.value);
    }

    function withdrawToUserAccount(address _userAddress, string calldata __userName, uint _amount) external payable onlyOwner noContract(_userAddress) {
        depositAmount(_userAddress, _amount);
        // Emit success payout event
        emit PayoutSuccess(_userAddress, __userName, _amount);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function depositAmount(address _user, uint256 _amount) internal {
        require(address(this).balance >= _amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = _user.call{value : _amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function changeCompanyAccount(address payable _newAccount) external onlyOwner {
        address oldAccount = companyAccount;
        companyAccount = _newAccount;
        emit CompanyAccountChanged(oldAccount, _newAccount);
    }

    function purchasePool(string calldata _username, uint8 _pool) external payable noContract(msg.sender) {
        require(msg.value >= pools[_pool], 'Please send the correct pool upgrade amount!');

        depositAmount(companyAccount, msg.value);
        User storage user = users[_username];
        user.pool = _pool;
        // emit pool purchase event
        emit PoolPurchased(_pool, msg.sender, msg.value, _username);
    }

    receive() external payable {
        emit NewDeposit(msg.sender, msg.value);
    }

    fallback() external payable {
        emit NewDeposit(msg.sender, msg.value);
    }
}