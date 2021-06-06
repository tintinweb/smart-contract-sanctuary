// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "../interfaces/IERC20.sol";
import "../utils/Context.sol";
import "../interfaces/IWhitelist.sol";

contract PrivateSale is Context {
    /**
     * Investment Structure.
     */
    struct Investment {
        uint256 _usdt;
        uint256 _usdc;
        uint256 _busd;
    }
    
    /**
     * @dev `_usdt` represents the usdt smart contract address.
     * `_admin` is the account that controls the sale.
     */
    address private _usdt;
    address private _usdc;
    address private _busd;
    address private _whitelist;
    address private _admin;

    /**
     * @dev stores the total unique investement addresses.
     */
    uint256 private _investors;
    mapping(uint256 => address) private _investor;

    /**
     * @dev stores the usdt invested by each account.
     */
    mapping(address => Investment) private _investment;

    /**
     * @dev checks if the investor already invested.
     */
    mapping(address => bool) private _isInvestor;

    /**
     * @dev checks if `caller` is `_admin`
     * reverts if the `caller` is not the `_admin` account.
     */
    modifier onlyAdmin() {
        require(_admin == msgSender(), "Error: caller not admin");
        _;
    }

    /**
     * @dev is emitted when a successful investment is made.
     */
    event Invest(address indexed from, uint256 amount, bytes32 currency);

    constructor(address _usdtAddress, address _usdcAddress, address _busdAddress, address _whitelistOracle) {
        _admin = msgSender();
        _usdt = _usdtAddress;
        _usdc = _usdcAddress;
        _busd = _busdAddress;
        _whitelist = _whitelistOracle;
    }

    /**
     * @dev invests `_usdtAmount` to the vesting smart contract.
     *
     * Requirements:
     * `_usdtAmount` should be approved by `caller` account.
     * `_usdtAmount` should be greater or equal to balance of `caller` account
     */
    function investUsdt(uint256 _usdtAmount) public virtual returns (bool) {
        require(IWhiteList(_whitelist).whitelisted(msgSender()), "Error: investor not elligible for purchase");

        uint256 balance = IERC20(_usdt).balanceOf(msgSender());
        uint256 allowance = IERC20(_usdt).allowance(msgSender(), address(this));

        require(balance >= _usdtAmount, "Error: insufficient USDT Balance");
        require(
            allowance >= _usdtAmount,
            "Error: allowance less than spending"
        );
        
        if(!_isInvestor[msgSender()]) { 
            _investors += 1; 
            _investor[_investors] = msgSender();
        }
        Investment storage i = _investment[msgSender()];
        i._usdt += _usdtAmount;

        emit Invest(msgSender(), _usdtAmount, bytes32("USDT"));
        IERC20(_usdt).transferFrom(msgSender(), address(this), _usdtAmount);
        return true;
    }

    /**
     * @dev invests `_usdcAmount` to the vesting smart contract.
     *
     * Requirements:
     * `_usdcAmount` should be approved by `caller` account.
     * `_usdcAmount` should be greater or equal to balance of `caller` account
     */
    function investUsdc(uint256 _usdcAmount) public virtual returns (bool) {
        require(IWhiteList(_whitelist).whitelisted(msgSender()), "Error: investor not elligible for purchase");

        uint256 balance = IERC20(_usdc).balanceOf(msgSender());
        uint256 allowance = IERC20(_usdc).allowance(msgSender(), address(this));

        require(balance >= _usdcAmount, "Error: insufficient USDC Balance");
        require(
            allowance >= _usdcAmount,
            "Error: allowance less than spending"
        );
        
        if(!_isInvestor[msgSender()]) { 
            _investors += 1; 
            _investor[_investors] = msgSender();
        }
        Investment storage i = _investment[msgSender()];
        i._usdc += _usdcAmount;

        emit Invest(msgSender(), _usdcAmount, bytes32("USDC"));
        IERC20(_usdc).transferFrom(msgSender(), address(this), _usdcAmount);
        return true;
    }

    /**
     * @dev invests `_busdAmount` to the vesting smart contract.
     *
     * Requirements:
     * `_busdAmount` should be approved by `caller` account.
     * `_busdAmount` should be greater or equal to balance of `caller` account
     */
    function investBusd(uint256 _busdAmount) public virtual returns (bool) {
        require(IWhiteList(_whitelist).whitelisted(msgSender()), "Error: investor not elligible for purchase");

        uint256 balance = IERC20(_busd).balanceOf(msgSender());
        uint256 allowance = IERC20(_busd).allowance(msgSender(), address(this));

        require(balance >= _busdAmount, "Error: insufficient BUSD Balance");
        require(
            allowance >= _busdAmount,
            "Error: allowance less than spending"
        );
        
        if(!_isInvestor[msgSender()]) { 
            _investors += 1; 
            _investor[_investors] = msgSender();
        }
        Investment storage i = _investment[msgSender()];
        i._busd += _busdAmount;

        emit Invest(msgSender(), _busdAmount, bytes32("BUSD"));
        IERC20(_busd).transferFrom(msgSender(), address(this), _busdAmount);
        return true;
    }

    /**
     * @dev returns the amount of usdt invested by `_user`
     */
    function investment(address _user) public view virtual returns (uint256, uint256, uint256) {
        Investment storage i = _investment[_user];
        return(i._usdc, i._usdt, i._busd);
    }

    /**
     * @dev returns the usdt smart contract used for purchase.
     */
    function usdt() public view returns (address) {
        return _usdt;
    }

    /**
     * @dev returns the usdc smart contract used for purchase.
     */
    function usdc() public view returns (address) {
        return _usdc;
    }

    /**
     * @dev returns the busd smart contract used for purchase.
     */
    function busd() public view returns (address) {
        return _busd;
    }

    /**
     * @dev returns the total number of investors.
     */
    function totalInvestors() public view returns (uint256) {
        return _investors;
    }

    /**
     * @dev returns individual investor address.
     */
    function investor(uint256 investorId) public view returns (address) {
        return _investor[investorId];
    }

    /**
     * @dev returns the admin account used for purchase.
     */
    function admin() public view returns (address) {
        return _admin;
    }

    /**
     * @dev transfers ownership to a different account.
     *
     * Requirements:
     * `newAdmin` cannot be a zero address.
     * `caller` should be current admin.
     */
    function transferControl(address newAdmin) public virtual onlyAdmin {
        require(newAdmin != address(0), "Error: owner cannot be zero");
        _admin = newAdmin;
    }

    /**
     * @dev updates the usdt sc address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateUsdt(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: address cannot be zero");
        _usdt = newAddress;
    }

    /**
     * @dev updates the usdc sc address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateUsdc(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: address cannot be zero");
        _usdc = newAddress;
    }

    /**
     * @dev updates the busd sc address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateBusd(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: address cannot be zero");
        _busd = newAddress;
    }

    /**
     * @dev updates the whitelist oracle address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateOracle(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: owner cannot be zero");
        _whitelist = newAddress;
    }

    /**
     * @dev send usdt from SC to any EOA.
     *
     * `caller` should be admin account.
     * `to` cannot be zero address.
     */
    function sendUsdt(address to, uint256 amount)
        public
        virtual
        onlyAdmin
        returns (bool)
    {
        require(to != address(0), "Error: cannot send to zero addresss");
        IERC20(_usdt).transfer(to, amount);
        return true;
    }

    /**
     * @dev send usdc from SC to any EOA.
     *
     * `caller` should be admin account.
     * `to` cannot be zero address.
     */
    function sendUsdc(address to, uint256 amount)
        public
        virtual
        onlyAdmin
        returns (bool)
    {
        require(to != address(0), "Error: cannot send to zero addresss");
        IERC20(_usdc).transfer(to, amount);
        return true;
    }

    /**
     * @dev send busd from SC to any EOA.
     *
     * `caller` should be admin account.
     * `to` cannot be zero address.
     */
    function sendBusd(address to, uint256 amount)
        public
        virtual
        onlyAdmin
        returns (bool)
    {
        require(to != address(0), "Error: cannot send to zero addresss");
        IERC20(_busd).transfer(to, amount);
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IERC20 {
    /**
     * @dev returns the tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev returns the remaining number of tokens the `spender' can spend
     * on behalf of the owner.
     *
     * This value changes when {approve} or {transferFrom} is executed.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev transfers the `amount` of tokens from caller's account
     * to the `recipient` account.
     *
     * returns boolean value indicating the operation status.
     *
     * Emits a {Transfer} event
     */
    function transfer(address recipient, uint256 amount)
        external;

    /**
     * @dev transfers the `amount` on behalf of `spender` to the `recipient` account.
     *
     * returns a boolean indicating the operation status.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

/**
 * Library Like Contract. Not Required for deployment
 */
abstract contract Context {

    function msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function msgData() internal view virtual returns(bytes calldata) {
        this;
        return msg.data;
    }

    function msgValue() internal view virtual returns(uint256) {
        return msg.value;
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/**
 * @dev interface of Whitelist Contract.
 */

interface IWhiteList {
    /**
     * @dev whitelist the `_user` for purchase.
     *
     * Requirements:
     * `_user` should not be a zero address.
     * `_user` should not be already whitelisted.
     *
     * returns a bool to represent the status of the transaction.
     */
    function whitelist(address _user) external returns (bool);

    /**
     * @dev blacklists the `user` from sale.
     *
     * Requirements:
     * `_user` should be whitelisted before.
     * `_user` cannot be a zero address.
     *
     * returns a bool to represent the status of the transaction.
     */
    function blacklist(address _user) external returns (bool);

    /**
     * @dev transfers the control of whitelisting to another wallet.
     *
     * Requirements:
     * `_newGovernor` should not be a zero address.
     * `caller` should be the current governor.
     *
     * returns a bool to represent the status of the transaction.
     */
    function transferGovernor(address _newGovernor) external returns (bool);

    /**
     * @dev returns a bool to represent the whitelisting status of a wallet.
     *
     * true - address is whitelisted and can purchase tokens.
     * false - prevented from sale.
     */
    function whitelisted(address _user) external view returns (bool);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}