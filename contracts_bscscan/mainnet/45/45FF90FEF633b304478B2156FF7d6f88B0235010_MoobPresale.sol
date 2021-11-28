// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.5;

import "./SafeERC20.sol";

import "./Ownable.sol";

interface IPresaleMoob {
    function mint(address account_, uint256 amount_) external;
}

contract MoobPresale is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount; // Amount usd deposited by user
        uint256 debt; // total MOOB claimed thus pMOOB debt
        bool claimed; // True if a user has claimed MOOB
    }

    IERC20 public pMOOB;
    IERC20 public MOOB;

    address public DAO;
    address public DEV;

    uint256 public price = 20 * 1e18; // 20 usd per pMOOB

    uint256 public cap = 1500 * 1e18; // 1500 usd cap per whitelisted user

    uint256 public totalRaisedUSD; // total usd raised by sale

    uint256 public totalDebt; // total pMOOB and thus MOOB owed to users

    bool public started; // true when sale is started

    bool public ended; // true when sale is ended

    bool public claimable; // true when sale is claimable

    bool public claimPresale; // true when pMOOB is claimable

    bool public contractPaused; // circuit breaker

    mapping(address => UserInfo) public userInfo;

    mapping(address => bool) public whitelisted; // True if user is whitelisted
    mapping(address => bool) public tokens; // True if token is {BUSD, USDC, USDT, DAI}

    mapping(address => uint256) public moobClaimable; // amount of moob claimable by address

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address token, address indexed who, uint256 amount);
    event Mint(address token, address indexed who, uint256 amount);
    event SaleStarted(uint256 block);
    event SaleEnded(uint256 block);
    event ClaimUnlocked(uint256 block);
    event ClaimPresaleUnlocked(uint256 block);
    event AdminWithdrawal(address token, uint256 amount);

    constructor(
        address _pMOOB,
        address _MOOB,
        address _DAO,
        address _DEV
    ) {
        require(_pMOOB != address(0));
        pMOOB = IERC20(_pMOOB);
        require(_MOOB != address(0));
        MOOB = IERC20(_MOOB);
        require(_DAO != address(0));
        DAO = _DAO;
        require(_DEV != address(0));
        DEV = _DEV;
    }

    //* @notice modifer to check if contract is paused
    modifier checkIfPaused() {
        require(contractPaused == false, "contract is paused");
        _;
    }

    /**
     *  @notice set Moob Token
     *  @param _MOOB: address of MOOB
     */
    function setMoob(address _MOOB) external onlyOwner {
        require(_MOOB != address(0));
        MOOB = IERC20(_MOOB);
    }

    /**
     *  @notice set pMoob Token
     *  @param _pMOOB: address of pMOOB
     */
    function setPMoob(address _pMOOB) external onlyOwner {
        require(_pMOOB != address(0));
        pMOOB = IERC20(_pMOOB);
    }

    /**
     *  @notice set price for pMOOB
     *  @param _price: price for pMOOB
     */
    function setPrice(uint256 _price) external onlyOwner {
        require(!started, "Sale has already started");
        price = _price;
    }

    /**
     *  @notice set USD cap per user
     *  @param _cap: USD cap per user
     */
    function setCap(uint256 _cap) external onlyOwner {
        require(!started, "Sale has already started");
        cap = _cap;
    }

     /**
     *  @notice adds a token to deposit for presale
     *  @param _address: address of token
     */
    function addToken(address _address) external onlyOwner {
        tokens[_address] = true;
    }

    /**
     *  @notice adds multiple tokens to deposit for presale
     *  @param _addresses: addresses of tokens
     */
    function addMultipleTokens(address[] calldata _addresses) 
        external 
        onlyOwner 
    {
        require(_addresses.length <= 4, "too many addresses");
        for (uint256 i = 0; i < _addresses.length; i++) {
            tokens[_addresses[i]] = true;
        }
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
    function addMultipleWhitelist(address[] calldata _addresses)
        external
        onlyOwner
    {
        require(_addresses.length <= 333, "too many addresses");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = true;
        }
    }

    /**
     *  @notice removes a token
     *  @param _address: address to remove
     */
    function removeToken(address _address) external onlyOwner {
        tokens[_address] = false;
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

    // @notice lets users claim MOOB
    // @dev send sufficient MOOB before calling
    function claimUnlock() external onlyOwner {
        require(ended, "Sale has not ended");
        require(!claimable, "Claim has already been unlocked");
        require(
            MOOB.balanceOf(address(this)) >= totalDebt,
            "not enough MOOB in contract"
        );
        claimable = true;
        emit ClaimUnlocked(block.number);
    }

    // @notice lets users claim pMOOB
    function claimPresaleUnlock() external onlyOwner {
        require(claimable, "Claim has not been unlocked");
        require(!claimPresale, "Claim Presale has already been unlocked");
        claimPresale = true;
        emit ClaimPresaleUnlocked(block.number);
    }

    // @notice lets owner pause contract
    function togglePause() external onlyOwner returns (bool) {
        contractPaused = !contractPaused;
        return contractPaused;
    }

    /**
     *  @notice transfer ERC20 token to DAO multisig
     *  @param _token: token address to withdraw
     *  @param _amount: amount of token to withdraw
     */
    function adminWithdraw(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(address(msg.sender), _amount);
        emit AdminWithdrawal(_token, _amount);
    }

    /**
     *  @notice it deposits USD for the sale
     *  @param _reserve: address of token to deposit to sale (18 decimals)
     *  @param _amount: amount of token to deposit to sale (18 decimals)
     */
    function deposit(address _reserve, uint256 _amount) external checkIfPaused {
        require(tokens[_reserve] == true,
            "Token is not correct.");
        require(started, "Sale has not started");
        require(!ended, "Sale has ended");
        require(
            whitelisted[msg.sender] == true,
            "msg.sender is not whitelisted user"
        );

        UserInfo storage user = userInfo[msg.sender];

        require(cap >= user.amount.add(_amount), "new amount above user limit");

        user.amount = user.amount.add(_amount);
        totalRaisedUSD = totalRaisedUSD.add(_amount);

        uint256 payout = _amount.mul(1e18).div(price).div(1e9); // pMOOB to mint for _amount

        totalDebt = totalDebt.add(payout);

        uint256 fee = _amount.div(10);
        uint256 sendAmount = _amount.sub(fee);

        IERC20(_reserve).safeTransferFrom(msg.sender, DAO, sendAmount);
        IERC20(_reserve).safeTransferFrom(msg.sender, DEV, fee);

        IPresaleMoob(address(pMOOB)).mint(msg.sender, payout);

        emit Deposit(msg.sender, _amount);
    }

    /**
     *  @notice it deposits pMOOB to withdraw MOOB from the sale
     *  @param _amount: amount of pMOOB to deposit to sale (9 decimals)
     */
    function withdraw(uint256 _amount) external checkIfPaused {
        require(claimable, "MOOB is not yet claimable");
        require(_amount > 0, "_amount must be greater than zero");

        UserInfo storage user = userInfo[msg.sender];

        user.debt = user.debt.add(_amount);

        totalDebt = totalDebt.sub(_amount);

        pMOOB.safeTransferFrom(msg.sender, address(this), _amount);

        MOOB.safeTransfer(msg.sender, _amount);

        emit Mint(address(pMOOB), msg.sender, _amount);
        emit Withdraw(address(MOOB), msg.sender, _amount);
    }

    // @notice it checks a users USD allocation remaining
    function getUserRemainingAllocation(address _user)
        external
        view
        returns (uint256)
    {
        UserInfo memory user = userInfo[_user];
        return cap.sub(user.amount);
    }

    // @notice it claims pMOOB back from the sale
    function claimPresaleMoob() external checkIfPaused {
        require(claimPresale, "pMOOB is not yet claimable");

        UserInfo storage user = userInfo[msg.sender];

        require(user.debt > 0, "msg.sender has not participated");
        require(!user.claimed, "msg.sender has already claimed");

        user.claimed = true;

        uint256 payout = user.debt;
        user.debt = 0;

        pMOOB.safeTransfer(msg.sender, payout);

        emit Withdraw(address(pMOOB), msg.sender, payout);
    }
}