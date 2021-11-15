// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./interfaces/IERC20.sol";
import "./utils/Context.sol";
 
contract PrivateSaleV2 is Context {
    
    
    /**
     * @dev `_usdt` represents the USDT smart contract address.
     * @dev `_usdc` represents the USDC smart contract address.
     * @dev `_busd` represents the BUSD smart contract address.
     * @dev `_bollycoin` represents the Bollycoin token contract.
     * `_admin` is the account that controls the sale.
     */
    address private _usdt;
    address private _usdc;
    address private _busd;
    address private _bollycoin;
    address private _admin;
    
    uint256 public bollycoinPrice = 0.1 * 10 ** 18; // 0.1 USD
    /**
     * @dev checks if `caller` is `_admin`
     * reverts if the `caller` is not the `_admin` account.
     */
    modifier onlyAdmin() {
        require(_admin == msgSender(), "Error: caller not admin");
        _;
    }

    /**
     * @dev is emitted when a successful purchase is made.
     */
    event Purchase(address indexed buyer, uint256 amount,uint256 usdValue, bytes32 currency);

    constructor(address _usdtAddress, address _usdcAddress, address _busdAddress, address _bollyAddress) {
        _admin = msgSender();
        _usdt = _usdtAddress;
        _usdc = _usdcAddress;
        _busd = _busdAddress;
        _bollycoin = _bollyAddress;
     }
 
    /**
     * @dev used to purchase bollycoin using USDT. Tokens are sent to the buyer.
     * @param _amount - The number of bollycoin tokens to purchase
     */
    function purchaseWithUSDT(uint256 _amount) public virtual returns (bool) {
        uint256 balance = IERC20(_usdt).balanceOf(msgSender());
        uint256 allowance = IERC20(_usdt).allowance(msgSender(), address(this));
        
   		uint256 usdValue = (bollycoinPrice) * _amount;
 		uint256 totalCostInUSDT = (bollycoinPrice) * _amount;
        totalCostInUSDT = totalCostInUSDT / 10**12;
        require(balance >= totalCostInUSDT, "Error: insufficient USDT Balance");
        require(
            allowance >= totalCostInUSDT,
            "Error: allowance less than spending"
        );

        IERC20(_usdt).transferFrom(msgSender(), address(this), totalCostInUSDT);
        IERC20(_bollycoin).transfer(msgSender(), _amount*10**18);
        emit Purchase(msgSender(), _amount, usdValue, bytes32("USDT"));
        return true;
    }

      
   /**
     * @dev used to purchase bollycoin using USDC. Tokens are sent to the buyer.
     * @param _amount - The number of bollycoin tokens to purchase
     */
    function purchaseWithUSDC(uint256 _amount) public virtual returns (bool) {
        uint256 balance = IERC20(_usdc).balanceOf(msgSender());
        uint256 allowance = IERC20(_usdc).allowance(msgSender(), address(this));
        
  		uint256 usdValue = (bollycoinPrice) * _amount;

 		uint256 totalCostInUSDC = (bollycoinPrice) * _amount;
        totalCostInUSDC = totalCostInUSDC / 10**12;
        require(balance >= totalCostInUSDC, "Error: insufficient USDC Balance");
        require(
            allowance >= totalCostInUSDC,
            "Error: allowance less than spending"
        );

        IERC20(_usdc).transferFrom(msgSender(), address(this), totalCostInUSDC);
        IERC20(_bollycoin).transfer(msgSender(), _amount*10**18);
        emit Purchase(msgSender(), _amount, usdValue, bytes32("USDC"));
        return true;
    }
    
    
   /**
     * @dev used to purchase bollycoin using BUSD. Tokens are sent to the buyer.
     * @param _amount - The number of bollycoin tokens to purchase
     */
    function purchaseWithBUSD(uint256 _amount) public virtual returns (bool) {
        uint256 balance = IERC20(_busd).balanceOf(msgSender());
        uint256 allowance = IERC20(_busd).allowance(msgSender(), address(this));
        
 
 		uint256 totalCostInBUSD = (bollycoinPrice) * _amount;
        require(balance >= totalCostInBUSD, "Error: insufficient BUSD Balance");
        require(
            allowance >= totalCostInBUSD,
            "Error: allowance less than spending"
        );

        IERC20(_busd).transferFrom(msgSender(), address(this), totalCostInBUSD);
        IERC20(_bollycoin).transfer(msgSender(), _amount*10**18);
        emit Purchase(msgSender(), _amount, totalCostInBUSD, bytes32("BUSD"));
        return true;
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
     * @dev returns the bollycoin smart contract used for purchase.
     */
    function bolly() public view returns (address) {
        return _bollycoin;
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
     * @dev updates the bollycoin token address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateBolly(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: address cannot be zero");
        _bollycoin = newAddress;
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
     * @dev updates the bollycoin token price.
     *
     * Requirements:
     * `newPrice` cannot be zero.
     * `caller` should be current admin.
     */
    function updateBollycoinPrice(uint256 newPrice) public virtual onlyAdmin {
        require(newPrice > 0 , "Error: price cannot be zero");
        bollycoinPrice = newPrice;
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
    
     /**
     * @dev withdraw bollycoin from SC to any EOA.
     *
     * `caller` should be admin account.
     * `to` cannot be zero address.
     */
    function withdrawBolly(address to, uint256 amount)
        public
        virtual
        onlyAdmin
        returns (bool)
    {
        require(to != address(0), "Error: cannot send to zero addresss");
        IERC20(_bollycoin).transfer(to, amount);
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

