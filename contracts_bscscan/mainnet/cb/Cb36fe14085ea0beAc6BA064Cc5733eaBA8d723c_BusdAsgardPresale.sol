// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.5;

import "./SafeERC20.sol";

import "./Ownable.sol";

interface IPresaleAsgard {
    function mint(address account_, uint256 amount_) external;
}

contract BusdAsgardPresale is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount; // Amount BUSD deposited by user
        uint256 debt; // total ASGARD claimed thus pASGARD debt
        bool claimed; // True if a user has claimed ASGARD
    }

    // Tokens to raise (BUSD) and for offer (pASGARD) which can be swapped for (ASGARD)
    IERC20 public BUSD; // for user deposits
    IERC20 public pASGARD;
    IERC20 public ASGARD;

    address public DAO; // Multisig treasury to send proceeds to

    uint256 public price = 1 * 1e18; // 20 BUSD per pASGARD

    uint256 public cap = 1500 * 1e18; // 1500 BUSD cap per whitelisted user

    uint256 public totalRaisedBUSD; // total BUSD raised by sale

    uint256 public totalDebt; // total pASGARD and thus ASGARD owed to users

    bool public started; // true when sale is started

    bool public ended; // true when sale is ended

    bool public claimable; // true when sale is claimable

    bool public claimPresale; // true when pASGARD is claimable

    bool public contractPaused; // circuit breaker

    mapping(address => UserInfo) public userInfo;

    mapping(address => bool) public whitelisted; // True if user is whitelisted

    mapping(address => uint256) public asgardClaimable; // amount of asgard claimable by address

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address token, address indexed who, uint256 amount);
    event Mint(address token, address indexed who, uint256 amount);
    event SaleStarted(uint256 block);
    event SaleEnded(uint256 block);
    event ClaimUnlocked(uint256 block);
    event ClaimPresaleUnlocked(uint256 block);
    event AdminWithdrawal(address token, uint256 amount);

    constructor(
        address _pASGARD,
        address _ASGARD,
        address _BUSD,
        address _DAO
    ) {
        require( _pASGARD != address(0) );
        pASGARD = IERC20(_pASGARD);
        require( _ASGARD != address(0) );
        ASGARD = IERC20(_ASGARD);
        require( _BUSD != address(0) );
        BUSD = IERC20(_BUSD);
        require( _DAO != address(0) );
        DAO = _DAO;
    }

    //* @notice modifer to check if contract is paused
    modifier checkIfPaused() {
        require(contractPaused == false, "contract is paused");
        _;
    }

    /**
     *  @notice set Asgard Token
     *  @param _ASGARD: address of ASGARD
     */
    function setAsgard(address _ASGARD) external onlyOwner {
        require( _ASGARD != address(0) );
        ASGARD = IERC20(_ASGARD);
    }

    /**
     *  @notice set pAsgard Token
     *  @param _pASGARD: address of pASGARD
     */
    function setPAsgard(address _pASGARD) external onlyOwner {
        require( _pASGARD != address(0) );
        pASGARD = IERC20(_pASGARD);
    }

    /**
     *  @notice set price for pASGARD
     *  @param _price: price for pASGARD
     */
    function setPrice(uint256 _price) external onlyOwner {
        require(!started, "Sale has already started");
        price = _price;
    }

    /**
     *  @notice set BUSD cap per user
     *  @param _cap: BUSD cap per user
     */
    function setCap(uint256 _cap) external onlyOwner {
        require(!started, "Sale has already started");
        cap = _cap;
    }

    /**
     *  @notice adds a single whitelist to the sale
     *  @param _address: address to whitelist
     */
    function addWhitelist(address _address) external onlyOwner {
        whitelisted[_address] = true;
    }

    /**
     *  @notice adds multiple whitelist to the sale
     *  @param _addresses: dynamic array of addresses to whitelist
     */
    function addMultipleWhitelist(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 333,"too many addresses");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = true;
        }
    }

    /**
     *  @notice removes a single whitelist from the sale
     *  @param _address: address to remove from whitelist
     */
    function removeWhitelist(address _address) external onlyOwner {
        whitelisted[_address] = false;
    }

    // @notice Starts the sale
    function start() external onlyOwner {
        require(!started, "Sale has already started");
        started = true;
        emit SaleStarted(block.number);
    }

    // @notice Ends the sale
    function end() external onlyOwner {
        require(started, "Sale has not started");
        require(!ended, "Sale has already ended");
        ended = true;
        emit SaleEnded(block.number);
    }

    // @notice lets users claim ASGARD
    // @dev send sufficient ASGARD before calling
    function claimUnlock() external onlyOwner {
        require(ended, "Sale has not ended");
        require(!claimable, "Claim has already been unlocked");
        require(ASGARD.balanceOf(address(this)) >= totalDebt, 'not enough ASGARD in contract');
        claimable = true;
        emit ClaimUnlocked(block.number);
    }


    // @notice lets users claim pASGARD
    function claimPresaleUnlock() external onlyOwner {
        require(claimable, "Claim has not been unlocked");
        require(!claimPresale, "Claim Presale has already been unlocked");
        claimPresale = true;
        emit ClaimPresaleUnlocked(block.number);
    }

    // @notice lets owner pause contract
    function togglePause() external onlyOwner returns (bool){
        contractPaused = !contractPaused;
        return contractPaused;
    }
    /**
     *  @notice transfer ERC20 token to DAO multisig
     *  @param _token: token address to withdraw
     *  @param _amount: amount of token to withdraw
     */
    function adminWithdraw(address _token, uint256 _amount) external onlyOwner {
        IERC20( _token ).safeTransfer( address(msg.sender), _amount );
        emit AdminWithdrawal(_token, _amount);
    }

    /**
     *  @notice it deposits BUSD for the sale
     *  @param _amount: amount of BUSD to deposit to sale (18 decimals)
     */
    function deposit(uint256 _amount) external checkIfPaused {
        require(started, 'Sale has not started');
        require(!ended, 'Sale has ended');
        require(whitelisted[msg.sender] == true, 'msg.sender is not whitelisted user');

        UserInfo storage user = userInfo[msg.sender];

        require(
            cap >= user.amount.add(_amount),
            'new amount above user limit'
            );

        user.amount = user.amount.add(_amount);
        totalRaisedBUSD = totalRaisedBUSD.add(_amount);

        uint256 payout = _amount.mul(1e18).div(price).div(1e9); // pASGARD to mint for _amount

        totalDebt = totalDebt.add(payout);

        BUSD.safeTransferFrom( msg.sender, DAO, _amount );

        IPresaleAsgard( address(pASGARD) ).mint( msg.sender, payout );

        emit Deposit(msg.sender, _amount);
    }
    
    /**
     *  @notice it deposits pASGARD to withdraw ASGARD from the sale
     *  @param _amount: amount of pASGARD to deposit to sale (9 decimals)
     */
    function withdraw(uint256 _amount) external checkIfPaused {
        require(claimable, 'ASGARD is not yet claimable');
        require(_amount > 0, '_amount must be greater than zero');

        UserInfo storage user = userInfo[msg.sender];

        user.debt = user.debt.add(_amount);

        totalDebt = totalDebt.sub(_amount);

        pASGARD.safeTransferFrom( msg.sender, address(this), _amount );

        ASGARD.safeTransfer( msg.sender, _amount );

        emit Mint(address(pASGARD), msg.sender, _amount);
        emit Withdraw(address(ASGARD), msg.sender, _amount);
    }

    // @notice it checks a users BUSD allocation remaining
    function getUserRemainingAllocation(address _user) external view returns ( uint256 ) {
        UserInfo memory user = userInfo[_user];
        return cap.sub(user.amount);
    }
    // @notice it claims pASGARD back from the sale
    function claimPresaleAsgard() external checkIfPaused {
        require(claimPresale, 'pASGARD is not yet claimable');

        UserInfo storage user = userInfo[msg.sender];

        require(user.debt > 0, 'msg.sender has not participated');
        require(!user.claimed, 'msg.sender has already claimed');

        user.claimed = true;

        uint256 payout = user.debt;
        user.debt = 0;

        pASGARD.safeTransfer( msg.sender, payout );

        emit Withdraw(address(pASGARD),msg.sender, payout);
    }

}