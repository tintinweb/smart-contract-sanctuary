/*--------------------------------------------------------PRuF0.7.1
__/\\\\\\\\\\\\\ _____/\\\\\\\\\ _______/\\../\\ ___/\\\\\\\\\\\\\\\
 _\/\\\/////////\\\ _/\\\///////\\\ ____\//..\//____\/\\\///////////__
  _\/\\\.......\/\\\.\/\\\.....\/\\\ ________________\/\\\ ____________
   _\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\/_____/\\\____/\\\.\/\\\\\\\\\\\ ____
    _\/\\\/////////____\/\\\//////\\\ ___\/\\\___\/\\\.\/\\\///////______
     _\/\\\ ____________\/\\\ ___\//\\\ __\/\\\___\/\\\.\/\\\ ____________
      _\/\\\ ____________\/\\\ ____\//\\\ _\/\\\___\/\\\.\/\\\ ____________
       _\/\\\ ____________\/\\\ _____\//\\\.\//\\\\\\\\\ _\/\\\ ____________
        _\/// _____________\/// _______\/// __\///////// __\/// _____________
         *-------------------------------------------------------------------*/

/*-----------------------------------------------------------------
 *  TO DO
 *
 *-----------------------------------------------------------------
 * PRESALE CONTRACT
 *---------------------------------------------------------------*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

import "./PRUF_INTERFACES.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract PRESALE is ReentrancyGuard, Pausable, AccessControl {
    using SafeMath for uint256;

    //----------------------------ROLE DFINITIONS 
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");

    address internal UTIL_TKN_Address;
    UTIL_TKN_Interface internal UTIL_TKN;

    address payable public payment_address;

    uint256 public airdropAmount = 1 ether; // in tokens
    uint256 public presaleLimit; //in eth
    uint256 public presaleCount; //in eth

    struct whiteListedAddress {
        uint256 tokensPerEth;
        uint256 minEth;
        uint256 maxEth;
    }

    mapping(address => whiteListedAddress) private whiteList;

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(WHITELIST_ROLE, _msgSender());
        _setupRole(AIRDROP_ROLE, _msgSender());

        whiteList[address(0)].tokensPerEth = 100000 ether; //100,000 tokens per ETH default    
        whiteList[address(0)].minEth = 100000000000000000; // 0.1 eth minimum default (10,000 tokens)
        whiteList[address(0)].maxEth = 10 ether; // 10 eth maximum default (1,000,000 tokens)              
    }

    //------------------------------------------------------------------------MODIFIERS

    /*
     * @dev Verify user credentials
     * Originating Address:
     *      is Admin
     */
    modifier isAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "PP:MOD: must have DEFAULT_ADMIN_ROLE"
        );
        _;
    }

    /*
     * @dev Verify user credentials
     * Originating Address:
     *      is Pauser
     */
    modifier isPauser() {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "PP:MOD: must have PAUSER_ROLE"
        );
        _;
    }

    /*
     * @dev Verify user credentials
     * Originating Address:
     *      is Airdrop
     */
    modifier isAirdrop() {
        require(
            hasRole(AIRDROP_ROLE, _msgSender()),
            "PP:MOD: must have AIRDROP_ROLE"
        );
        _;
    }

    /*
     * @dev Verify user credentials
     * Originating Address:
     *      is Whitelist
     */
    modifier isWhitelist() {
        require(
            hasRole(WHITELIST_ROLE, _msgSender()),
            "PP:MOD: must have WHITELIST_ROLE"
        );
        _;
    }

    event REPORT(address addr, uint256 amount);

    //----------------------External Admin functions / onlyowner ---------------------//

    /*
     * @dev Set address of PRUF_TKN contract to interface with
     * TESTING: ALL REQUIRES, ACCESS ROLE
     */
    function ADMIN_setTokenContract(address _address) external isAdmin {
        require(
            _address != address(0),
            "PP:STC: token contract address cannot be zero"
        );
        //^^^^^^^checks^^^^^^^^^

        UTIL_TKN_Address = _address;
        UTIL_TKN = UTIL_TKN_Interface(UTIL_TKN_Address);
        //^^^^^^^effects^^^^^^^^^
    }

    /*
     * @dev Set Payment address to send eth to
     * TESTING: ALL REQUIRES, ACCESS ROLE
     */
    function ADMIN_setPaymentAddress(address payable _address)
        external
        isAdmin
    {
        require(
            _address != address(0),
            "PP:ASPA: payment address cannot be zero"
        );
        //^^^^^^^checks^^^^^^^^^

        payment_address = _address;

        //^^^^^^^effects^^^^^^^^^
    }

    /*
     * @dev Set airdropAmount
     * TESTING: ALL REQUIRES, ACCESS ROLE, sets airdrop amount for all airdrop functions
     */
    function ADMIN_setAirDropAmount(uint256 _airdropAmount) external isAdmin {
        require(_airdropAmount != 0, "PP:SAA: airdrop amount cannot be zero");
        //^^^^^^^checks^^^^^^^^^
        airdropAmount = _airdropAmount;
        //^^^^^^^effects^^^^^^^^^
    }

    /*
     * @dev Set presale limit, reset presale counter
     * TESTING: ALL REQUIRES, ACCESS ROLE, presale limit works, presale limit can be reset for new presale
     */
    function ADMIN_setPresaleLimit(uint256 _presaleLimit) external isAdmin {
        //^^^^^^^checks^^^^^^^^^
        presaleLimit = _presaleLimit;
        presaleCount = 0;
        //^^^^^^^effects^^^^^^^^^
    }

    /*
     * @dev Set address of PRUF_TKN contract to interface with
     * Set default condition at address(0). Addresses not appearing on the whitelist will fall under these terms.
     * TESTING: ACCESS ROLE, Also test that setting params for 0 address sets default behavior for non-whitelisted addresses
     */
    function whitelist(
        address _addr,
        uint256 _tokensPerEth,
        uint256 _minEth,
        uint256 _maxEth
    ) external isWhitelist {
        whiteListedAddress memory _whiteList;

        //^^^^^^^checks^^^^^^^^^

        _whiteList.tokensPerEth = _tokensPerEth; //build new whiteList entry
        _whiteList.minEth = _minEth;
        _whiteList.maxEth = _maxEth;

        whiteList[_addr] = _whiteList; //store new whiteList entry

        //^^^^^^^effects^^^^^^^^^
    }

    /*
     * @dev checks airdrop state for an address
     * TESTING: Returns both instantiated and default (uninstantiated addresses) Uninstantiated addresses should return default (0 address) values
     *
     */
    function checkWhitelist(address _addr)
        external
        virtual
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        //min tokens, max tokens, tokens per eth, ETH (wei) to buy maxEth

        whiteListedAddress memory _whiteList = whiteList[_addr];

        if (_whiteList.tokensPerEth == 0) {
            _whiteList = whiteList[address(0)];
        }

        return (_whiteList.minEth, _whiteList.maxEth, _whiteList.tokensPerEth);
        //^^^^^^^effects^^^^^^^^^
    }

    //--------------------------------------External functions--------------------------------------------//

    /*
     * @dev Mint airdropAmount to a list of addresses
     * TESTING: ALL REQUIRES, ACCESS ROLE, PAUSABLE
     */
    function AIRDROP_Mint14(
        address _a,
        address _b,
        address _c,
        address _d,
        address _e,
        address _f,
        address _g,
        address _h,
        address _i,
        address _j,
        address _k,
        address _l,
        address _m,
        address _n
    ) external isAirdrop whenNotPaused {
        //^^^^^^^checks^^^^^^^^^

        UTIL_TKN.mint(_a, airdropAmount);
        UTIL_TKN.mint(_b, airdropAmount);
        UTIL_TKN.mint(_c, airdropAmount);
        UTIL_TKN.mint(_d, airdropAmount);
        UTIL_TKN.mint(_e, airdropAmount);
        UTIL_TKN.mint(_f, airdropAmount);
        UTIL_TKN.mint(_g, airdropAmount);
        UTIL_TKN.mint(_h, airdropAmount);
        UTIL_TKN.mint(_i, airdropAmount);
        UTIL_TKN.mint(_j, airdropAmount);
        UTIL_TKN.mint(_k, airdropAmount);
        UTIL_TKN.mint(_l, airdropAmount);
        UTIL_TKN.mint(_m, airdropAmount);
        UTIL_TKN.mint(_n, airdropAmount);
        //^^^^^^^Interactions^^^^^^^^^
    }

    

    /*
     * @dev Mint airdropAmount to a list of addresses
     * TESTING: ALL REQUIRES, ACCESS ROLE, PAUSABLE
     */
    function AIRDROP_Mint5(
        address _a,
        address _b,
        address _c,
        address _d,
        address _e
    ) external isAirdrop whenNotPaused {
        //^^^^^^^checks^^^^^^^^^

        UTIL_TKN.mint(_a, airdropAmount);
        UTIL_TKN.mint(_b, airdropAmount);
        UTIL_TKN.mint(_c, airdropAmount);
        UTIL_TKN.mint(_d, airdropAmount);
        UTIL_TKN.mint(_e, airdropAmount);
        //^^^^^^^Interactions^^^^^^^^^
    }


    /*
     * @dev Mint a set airdropAmount to an address
     * TESTING: ALL REQUIRES, ACCESS ROLE, PAUSABLE
     */
    function AIRDROP_Mint1(address _a)
        external
        isAirdrop
        whenNotPaused
    {
        //^^^^^^^checks^^^^^^^^^

        UTIL_TKN.mint(_a, airdropAmount);
        //^^^^^^^Interactions^^^^^^^^^
    }

    /*
     * @dev Mint PRUF to an addresses as caller.tokensPerEth * ETH recieved
     * TESTING: ALL REQUIRES, ACCESS ROLE, PAUSABLE, individual presale allowance can be exhausted, overall presale allotment can be exhausted
     *          amount minted conforms to tokensPerEth setting, min buy is enforced
     */
    function BUY_PRUF() public payable nonReentrant whenNotPaused { 

        whiteListedAddress memory _whiteList = whiteList[msg.sender];

        if (_whiteList.tokensPerEth == 0) {  //loads the default (addr 0) info into the address if address is not specificly whitelisted
            whiteList[msg.sender] = whiteList[address(0)];
            _whiteList = whiteList[msg.sender];
        }

        uint256 amountToMint = msg.value.mul(
            _whiteList.tokensPerEth.div(1 ether)
        ); //in wei

        require(
                amountToMint != 0,
            "PP:PP: Amount to mint is zero"
        );
        require(
            msg.value >= _whiteList.minEth,
            "PP:PP: Insufficient ETH sent to meet minimum purchase requirement"
        );
        require(
            msg.value <= _whiteList.maxEth,
            "PP:PP: Purchase request exceeds allowed purchase Amount"
        );
        require(
                amountToMint.add(presaleCount) <= presaleLimit,
            "PP:PP: Purchase request exceeds total presale limit"
        );
        //^^^^^^^checks^^^^^^^^^

        presaleCount = amountToMint.add(presaleCount);

        whiteList[msg.sender].maxEth = _whiteList.maxEth.sub(msg.value); //reduce max purchasable by purchased amount
        whiteList[msg.sender].minEth = 0; //Remove minimum , as minimum buy is already met.
        //^^^^^^^effects^^^^^^^^^

        UTIL_TKN.mint(msg.sender, amountToMint);
        emit REPORT(_msgSender(), amountToMint);
        //^^^^^^^Interactions^^^^^^^^^
    }

    /*
     * @dev withdraw to specified payment address
     * TESTING: WORKS
     */
    function withdraw() external isAdmin nonReentrant {
        require(
            payment_address != address(0),
            "PP:W: payment address cannot be zero."
        );
        payment_address.transfer(address(this).balance);
    }

    /*
     * @dev return balance of contract
     * TESTING: WORKS
     */
    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Triggers stopped state. (pausable)
     * * TESTING: ACCESS ROLE
     */
    function pause() external isPauser {
        _pause();
    }

    /**
     * @dev Returns to normal state. (pausable)
     * TESTING: ACCESS ROLE
     */
    function unpause() external isPauser {
        _unpause();
    }

    /**
     * @dev Ether received will initiate the mintPRUF function
     * TESTING: Sending naked eth calls presale function correctly
     */
    receive() external payable {
        BUY_PRUF();
    }

    //--------------------------------------------------------------------------------------INTERNAL functions
}
