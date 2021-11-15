// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import '@openzeppelin/contracts/access/Ownable.sol';

// MINTER
import "./CryptoPageMinter.sol";

// NFT MARKETS
import "./CryptoPageNFTBank.sol";
import "./CryptoPageNFTMarket.sol";
import "./CryptoPageProfile.sol";

// TOKEN
import "./CryptoPageToken.sol";

import "./interfaces/INFTMINT.sol";



contract PageAdmin is Ownable {

    PageMinter public PAGE_MINTER;
    PageToken public PAGE_TOKEN;
    PageNFTBank public PAGE_NFT_BANK;
    PageNFTMarket public PAGE_NFT_MARKET;
    PageProfile public PAGE_PROFILE;
    INFTMINT public PAGE_NFT;

    constructor() {
        // LAUNCH ADMIN
        PAGE_MINTER = new PageMinter(address(this),msg.sender);
        PAGE_TOKEN = new PageToken();

        // OTHERS

    }


    // INIT
    bool one_time = true;
    address[] private safeAddresses;
    function init( address _PAGE_NFT ) public onlyOwner() {
        require(one_time, "CAN BE CALL ONLY ONCE");

        address _PAGE_MINTER = address(PAGE_MINTER);

        PAGE_NFT = INFTMINT(_PAGE_NFT);

        PAGE_PROFILE = new PageProfile(_PAGE_MINTER);
        PAGE_NFT_BANK = new PageNFTBank(_PAGE_NFT,_PAGE_MINTER);
        PAGE_NFT_MARKET = new PageNFTMarket(_PAGE_NFT,_PAGE_MINTER);

        // SETUP PAGE_TOKEN
        PAGE_MINTER.init(address(PAGE_TOKEN));

        // SET SAFE ADDRESSES
        safeAddresses.push(address(PAGE_NFT_BANK));
        safeAddresses.push(address(PAGE_NFT_MARKET));        
        PAGE_MINTER.addSafe(safeAddresses);

        /*
        PAGE_MINTER.addSafe(address(PAGE_MINTER));
        PAGE_MINTER.addSafe(address(PAGE_NFT_BANK));
        PAGE_MINTER.addSafe(address(PAGE_NFT_MARKET));
        PAGE_MINTER.addSafe(address(PAGE_PROFILE));
        */

        /*
        PAGE_TOKEN = IERCMINT(_PAGE_TOKEN);
        PAGE_NFT = INFTMINT(_PAGE_NFT);

        // PAGE
        PAGE_MINTER.setMinter("NFT_CREATE", address(PAGE_NFT), 20 ** 18, false);
        PAGE_MINTER.setMinter("NFT_CREATE_WITH_COMMENT", address(PAGE_NFT), 100 ** 18, false);
        PAGE_MINTER.setMinter("NFT_CREATE_ADD_COMMENT", address(PAGE_NFT), 80 ** 18, false); // if create without comments, it can be add by this function
        PAGE_MINTER.setMinter("NFT_FIRST_COMMENT", address(PAGE_NFT), 10 ** 18, false);
        PAGE_MINTER.setMinter("NFT_SECOND_COMMENT", address(PAGE_NFT), 3 ** 18, false);
        // PAGE_MINTER.setMinter("BANK_SELL", PAGE_NFT.BANK_ADDRESS, 1 ** 18, true); // On the price effect amount of comments
        // PAGE_MINTER.setMinter("PROFILE_UPDATE", address(PAGE_NFT), 3 ** 18, false);
        */

        one_time = false;
    }

    // ONLY ADMIN
    function removeMinter(string memory _key) public onlyOwner() {
        require(!one_time, "INIT FUNCTION NOT CALLED");
        PAGE_MINTER.removeMinter(_key);
    }
    function setMinter(string memory _key, address _account, uint256 _pageamount) public onlyOwner() {
        require(!one_time, "INIT FUNCTION NOT CALLED");
        PAGE_MINTER.setMinter(_key, _account, _pageamount, false);
    }
    function setTreasuryFee(uint256 _percent) public onlyOwner() {
        require(!one_time, "INIT FUNCTION NOT CALLED");
        PAGE_MINTER.setTreasuryFee(_percent);
    }
    function setTreasuryAddress(address _treasury) public onlyOwner() {
        require(!one_time, "INIT FUNCTION NOT CALLED");
        PAGE_MINTER.setTreasuryAddress(_treasury);
    }
    /* 
    REMOVE FOR SAFETY REASON
    function addSafe( address[] memory _safe ) public onlyOwner() {
        require(!one_time, "INIT FUNCTION NOT CALLED");
        PAGE_MINTER.addSafe(_safe); // memory
    }
    function removeSafe( address _safe ) public onlyOwner() {
        require(!one_time, "INIT FUNCTION NOT CALLED");
        PAGE_MINTER.removeSafe(_safe);
    }
    function changeSafe( address _from, address _to ) public onlyOwner() {
        require(!one_time, "INIT FUNCTION NOT CALLED");
        PAGE_MINTER.changeSafe(_from, _to);
    }
    */
    function setBurnNFTcost( uint256 _pageamount ) public onlyOwner() {
        PAGE_MINTER.setBurnNFT(_pageamount);
    }
    function setNftBaseURL( string memory _url ) public onlyOwner() {
        PAGE_NFT.setBaseURL( _url );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IMINTER.sol";
import "./interfaces/IERCMINT.sol";
// import "./interfaces/INFTMINT.sol";
import "./interfaces/ISAFE.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PageMinter is IMINTER, ISAFE {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    IERCMINT private PAGE;

    address public TreasuryAddress = address(0);
    address public AdminAddress = address(0);
    uint256 public TreasuryFee = 1000; // 100 is 1% || 10000 is 100%

    // MINTERS
    Counters.Counter private _totalMinters;
    Counters.Counter private _minterId;
    string[] public _listMinters;

    struct Minters {
        uint256 id;
        address author;
        uint256 amount;
        bool xmint;
    }
    mapping(string => Minters) public _minters;
    mapping(string => bool) private _keytank;

    /* INIT */
    constructor(address _admin, address _treasury) {   
        AdminAddress = _admin;     
        TreasuryAddress = _treasury; // setTreasuryAddress
    }

    bool private is_init = false;
    function init(address _page) public onlyAdmin() {
        require(!is_init, "can be call only once");
        PAGE = IERCMINT(_page); // PAGE ADDRESS

        /*
        PAGE_MINTER.addSafe(address(PAGE_MINTER));
        PAGE_MINTER.addSafe(address(PAGE_NFT_BANK));
        PAGE_MINTER.addSafe(address(PAGE_NFT_MARKET));
        PAGE_MINTER.addSafe(address(PAGE_PROFILE));
        */

        /*
        PAGE_TOKEN = IERCMINT(_PAGE_TOKEN);
        PAGE_NFT = INFTMINT(_PAGE_NFT);
        
        // PAGE
        PAGE_MINTER.setMinter("NFT_CREATE", address(PAGE_NFT), 20 ** 18, false);
        PAGE_MINTER.setMinter("NFT_CREATE_WITH_COMMENT", address(PAGE_NFT), 100 ** 18, false);
        PAGE_MINTER.setMinter("NFT_CREATE_ADD_COMMENT", address(PAGE_NFT), 80 ** 18, false); // if create without comments, it can be add by this function
        PAGE_MINTER.setMinter("NFT_FIRST_COMMENT", address(PAGE_NFT), 10 ** 18, false);
        PAGE_MINTER.setMinter("NFT_SECOND_COMMENT", address(PAGE_NFT), 3 ** 18, false);
        // PAGE_MINTER.setMinter("BANK_SELL", PAGE_NFT.BANK_ADDRESS, 1 ** 18, true); // On the price effect amount of comments
        // PAGE_MINTER.setMinter("PROFILE_UPDATE", address(PAGE_NFT), 3 ** 18, false);
        */

        is_init = true;
    }

    function _amount_mint(string memory _key, uint256 _address_count) public view override returns (uint256 amount_each, uint256 fee) {
        require(_keytank[_key], "_amount_mint: _key doesn't exists");        
        require(_address_count < 5, "address count > 4");
        require(_address_count > 0, "address count is zero");
        // (address author, uint256 amount) = _minters[_key];
        Minters storage minter = _minters[_key];
        fee = minter.amount.mul(TreasuryFee).div(10000);
        amount_each = (minter.amount - fee).div(_address_count);
    }
    function mint(string memory _key, address [] memory _to) public override{        
        require(is_init, "need to be init by admin");
        require(_keytank[_key], "mint: _key doesn't exists");

        // MINTER ONLY
        Minters storage minter =  _minters[_key];        
        require(minter.amount > 0, "mint: minter.amount can't be 0");
        require(minter.author == msg.sender, "mint: not minter");        

        uint256 address_count = _to.length;
        // require(_addresses[_key] != 0, "Address Amount is 0");
        require(address_count < 5, "address count > 4");
        require(address_count > 0, "address count is zero");

        (uint256 amount_each, uint256 fee) = _amount_mint(_key, address_count);

        // MINT TO ADDRESS
        for(uint256 i; i < address_count; i++){
            PAGE.mint(_to[i], amount_each);
        }

        // FEE TO ADDRESS
        PAGE.mint(TreasuryAddress, fee);
    }

    function mintX(string memory _key, address [] memory _to, uint _multiplier) public override{
        require(is_init, "need to be init by admin");
        require(_keytank[_key], "mintX: _key doesn't exists");

        // MINTER ONLY
        Minters storage minter =  _minters[_key];        
        require(minter.amount > 0, "mint: minter.amount can't be 0");
        require(minter.author == msg.sender, "mint: not minter");
        require(minter.xmint, "xmint: not active");

        uint256 address_count = _to.length;
        // require(_addresses[_key] != 0, "Address Amount is 0");
        require(address_count < 5, "address count > 4");
        require(address_count > 0, "address count is zero");

        (uint256 amount_each, uint256 fee) = _amount_mint(_key, address_count);

        // MINT TO ADDRESS
        for(uint256 i; i < address_count; i++){
            PAGE.mint(_to[i], amount_each.mul(_multiplier));
        }

        // FEE TO ADDRESS
        PAGE.mint(TreasuryAddress, fee.mul(_multiplier));
    }

    // > > > onlyAdmin < < <  
    modifier onlyAdmin() {        
        require(msg.sender == AdminAddress, "onlyAdmin: caller is not the admin");
        _;
    }
    function removeMinter(string memory _key) public onlyAdmin() override {
        require(_keytank[_key], "removeMinter: _key doesn't exists");
        _keytank[_key] = false;
        Minters memory toRemove = _minters[_key];
        delete _listMinters[toRemove.id];
        delete _minters[_key];
        _totalMinters.decrement();
    }
    function setMinter(string memory _key, address _account, uint256 _pageamount, bool _xmint) public onlyAdmin() override {
        if (_keytank[_key]) {
            Minters memory update = _minters[_key];
            update.amount = _pageamount;
            update.author = _account;
            update.xmint = _xmint;
        } else {
            _keytank[_key] = true;
            _minters[_key] = Minters({
                author: _account,
                amount: _pageamount,
                id: _minterId.current(),
                xmint: _xmint
            });
            _listMinters[_minterId.current()] = _key;
            _minterId.increment();
            _totalMinters.increment();
        }
    }
    function setTreasuryFee(uint256 _percent) public onlyAdmin() {
        require(_percent >= 10, "setTreasuryFee: minimum treasury fee percent is 0.1%");
        require(_percent <= 3000, "setTreasuryFee: maximum treasury fee percent is 30%");
        TreasuryFee = _percent;
    }
    function setTreasuryAddress(address _treasury) public onlyAdmin() {
        require(_treasury != address(0), "setTreasuryAddress: is zero address");
        TreasuryAddress = _treasury;
    }

    // GET FUNCTIONS
    function getMinter(string memory _key) public view override returns (
        uint256 id,
        address author,
        uint256 amount,
        bool xmint) {
        require(_keytank[_key], "getMinter: _key doesn't exists");
        Minters memory minter = _minters[_key];
        id = minter.id;
        author = minter.author;
        amount = minter.amount;
        xmint = minter.xmint;
    }

    // PROXY
    function burn( address from, uint256 amount ) public override onlySafe() {
        require(is_init, "need to be init by admin");

        // burn 100% PAGE
        PAGE.xburn(from, amount);

        // recover 10% to Treasury address
        PAGE.mint(TreasuryAddress, amount.mul(TreasuryFee).div(10000));
    }

    // ISAFE
    mapping(address => bool) private safeList;
    function isSafe( address _safe ) public override view returns (bool) {
        return safeList[_safe];
    }
    function addSafe( address[] memory _safe ) public override onlyAdmin() {        
        for(uint256 i; i < _safe.length; i++){
            safeList[_safe[i]] = true;
        }        
    }
    function removeSafe( address _safe ) public override onlyAdmin() {
        safeList[_safe] = false;        
    }
    function changeSafe( address _from, address _to ) public override onlyAdmin() {
        safeList[_from] = false;
        safeList[_to] = true;       
    }
    modifier onlySafe() {        
        require(isSafe(msg.sender), "onlySafe: caller is not in safe list");
        _;
    }

    // DESTROY NFT
    uint256 private CostBurnNFT;
    function setBurnNFT(uint256 _cost) public override onlyAdmin() {
        CostBurnNFT = _cost;
    }
    // VIEW FUNCTIONS
    function getBurnNFT() public override view returns (uint256) {
        return CostBurnNFT;
    }
    function getAdmin() public override view returns (address) {
        return AdminAddress;
    }
    function getPageToken() public override view returns (address) {
        return address(PAGE);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/INFTMINT.sol";
import "./interfaces/IMINTER.sol";
import "./interfaces/IERCMINT.sol";

contract PageNFTBank {
    INFTMINT public PAGE_NFT;
    IMINTER public PAGE_MINTER;
    IERCMINT public PAGE_TOKEN;
    constructor (address _PAGE_NFT, address _PAGE_MINTER) {
        PAGE_NFT = INFTMINT(_PAGE_NFT);
        PAGE_MINTER = IMINTER(_PAGE_MINTER);
        PAGE_TOKEN = IERCMINT(PAGE_MINTER.getPageToken());
    }

    function Buy(uint256 _amount) public {
        require(PAGE_TOKEN.isEnoughOn(msg.sender, _amount), "Not enough tokens");
        PAGE_TOKEN.safeDeposit(msg.sender, address(this), _amount);
    }
    function Sell(uint256) public {
        // MINT
    }

    modifier onlyAdmin() {        
        require(msg.sender == PAGE_MINTER.getAdmin(), "onlyAdmin: caller is not the admin");
        _;
    }

    uint256 private _sell;
    uint256 private _buy;
    function setBuyPrice(uint256) public onlyAdmin() {
        
    }
    function setSellPrice(uint256) public onlyAdmin() {
        
    }
    function getPrice() public view returns(uint256 sell, uint256 buy ) {
        sell = _sell;
        buy = _buy;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/INFTMINT.sol";
import "./interfaces/IMINTER.sol";
import "./interfaces/IERCMINT.sol";

contract PageNFTMarket {
    INFTMINT public PAGE_NFT;
    IMINTER public PAGE_MINTER; 
    IERCMINT public PAGE_TOKEN;
    constructor (address _PAGE_NFT, address _PAGE_MINTER) {
        PAGE_NFT = INFTMINT(_PAGE_NFT);
        PAGE_MINTER = IMINTER(_PAGE_MINTER);
    }

    // DEPOSIT
        
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IMINTER.sol";
import "./interfaces/IERCMINT.sol";

contract PageProfile {
    IMINTER public PAGE_MINTER;
    constructor (address _PAGE_MINTER) {
        PAGE_MINTER = IMINTER(_PAGE_MINTER);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IERCMINT.sol";
import './interfaces/ISAFE.sol';

contract PageToken is ERC20, IERCMINT {

    ISAFE private PAGE_MINTER;
    constructor() ERC20("Crypto Page", "PAGE") {
        // address _IMINTER
        PAGE_MINTER = ISAFE(msg.sender);
    }

    // OPEN
    function burn(uint256 amount) public override {
        _burn(msg.sender, amount);
    }

    function isEnoughOn(address account, uint256 amount) public override view returns (bool) {
        if (balanceOf(account) >= amount) {
            return true;
        } else {
            return false;
        }
    }

    // ADMIN ONLY
    modifier onlyAdmin() {        
        require(msg.sender == address(PAGE_MINTER), "onlyAdmin: caller is not the admin");
        _;
    }
    function mint(address to, uint256 amount) public onlyAdmin() override {
        _mint(to, amount);
    }
    function xburn(address from, uint256 amount) public onlyAdmin() override{
        _burn(from, amount);
    }
    
    modifier onlySafe() {        
        require(PAGE_MINTER.isSafe(msg.sender), "onlySafe: caller is not in safe list");
        _;
    }

    // ISAFE
    function safeDeposit(address from, address to, uint256 amount) public override onlySafe() {
        _transfer(from, to, amount);
    }
    function safeWithdraw(address from, address to, uint256 amount) public override onlySafe() {
        _transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INFTMINT {  
    function burn( uint256 amount ) external ;
    function setBaseURL( string memory url ) external ;
    function getBaseURL() external view returns (string memory) ;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMINTER {
    function _amount_mint(string memory _key, uint256 _address_count) external view returns (uint256 amount_each, uint256 fee);
    function mint(string memory _key, address [] memory _to) external;
    function mintX(string memory _key, address [] memory _to, uint _multiplier) external;
    function burn( address from, uint256 amount  ) external ;
    function removeMinter(string memory _key) external;
    function setMinter(string memory _key, address _account, uint256 _pageamount, bool _xmint) external;
    function getMinter(string memory _key) external view returns (
        uint256 id,
        address author,
        uint256 amount,
        bool xmint);
    // Burn NFT PRICE
    function setBurnNFT(uint256 _cost) external;
    function getBurnNFT() external view returns (uint256);
    function getAdmin() external view returns (address);
    function getPageToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// IERC20

interface IERCMINT {
    function mint( address to, uint256 amount ) external ;
    function xburn(address from, uint256 amount) external ;
    function burn( uint256 amount ) external ;

    function safeDeposit(address from, address to, uint256 amount) external ;
    function safeWithdraw(address from, address to, uint256 amount) external ;

    // IF ENOUGH TOKENS ON BALANCE ??
    function isEnoughOn(address account, uint256 amount) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISAFE {
    // function mint( address to, uint256 amount ) external ;    
    // function burn( uint256 amount ) external ;

    /*
    // is contains address[]
    address[] public safeMiners;
    mapping (address => bool) public Wallets;
    */
    // address[] public safeMiners;

    function isSafe( address _safe ) external view returns (bool) ;
    function addSafe( address[] calldata _safe ) external ;
    function removeSafe( address _safe ) external ;
    function changeSafe( address _from, address _to ) external ;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

