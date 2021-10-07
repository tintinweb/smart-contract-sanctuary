/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

pragma solidity ^0.8.4;
 
interface IBollycoinPriceFeed {
     
    function getLatestETHPrice() external view returns(uint256);
    function getLatestBTCPrice() external view returns(uint256);

 
}

interface IERC20 {
    
     /**
     * @dev returns the tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

     /**
     * @dev returns the decimal places of a token
     */
    function decimals() external view returns (uint8);

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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
/*
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
    function msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
     function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }
}
contract PrivateSaleV2 is Context, ReentrancyGuard {
    /**
     * @dev `_usdt` represents the USDT smart contract address.
     * @dev `_usdc` represents the USDC smart contract address.
     * @dev `_busd` represents the BUSD smart contract address.
     * @dev `_bollycoin` represents the Bollycoin token contract.
     * @dev `_settlementWallet` represents the wallet address to which tokens are sent during purcahse.

     * `_admin` is the account that controls the sale.
     */
    address private _usdt;
    address private _usdc;
    address private _busd;
    address private _wbtc;
    address private _bollycoin;
    address private _admin;
    address private _oracle;
    address private _settlementWallet;

    uint256 public bollycoinPrice = 0.1 * 10**18; // 0.1 USD
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
    event Purchase(
        address indexed buyer,
        string uid,
        uint256 amount,
        uint256 valueInPurchaseCurrency,
        bytes32 currency
    );

    constructor(
        address _usdtAddress,
        address _usdcAddress,
        address _busdAddress,
        address _wbtcAddress,
        address _bollyAddress,
        address _oracleAddress,
        address _settlementAddress
        
    ) {
        _admin = _settlementAddress;
        _usdt = _usdtAddress;
        _usdc = _usdcAddress;
        _busd = _busdAddress;
        _bollycoin = _bollyAddress;
        _oracle = _oracleAddress;
         _wbtc = _wbtcAddress;
        _settlementWallet = _settlementAddress;
    }

    /**
     * @dev used to purchase bollycoin using USDT. Tokens are sent to the buyer.
     * @param _amount - The number of bollycoin tokens to purchase
     */
    function purchaseWithUSDT(uint256 _amount, string memory uid)
        public
        nonReentrant
        virtual
        returns (bool)
    {
        uint256 balance = IERC20(_usdt).balanceOf(msgSender());
        uint256 allowance = IERC20(_usdt).allowance(msgSender(), address(this));

        uint256 totalCostInUSDT = (bollycoinPrice) * _amount;
        totalCostInUSDT = totalCostInUSDT / 10**12;
        require(balance >= totalCostInUSDT, "Error: insufficient USDT Balance");
        require(
            allowance >= totalCostInUSDT,
            "Error: allowance less than spending"
        );

        IERC20(_usdt).transferFrom(
            msgSender(),
            _settlementWallet,
            totalCostInUSDT
        );
        IERC20(_bollycoin).transfer(msgSender(), _amount * 10**18);
        emit Purchase(
            msgSender(),
            uid,
            _amount,
            totalCostInUSDT,
            bytes32("USDT")
        );
        return true;
    }

    /**
     * @dev used to purchase bollycoin using USDC. Tokens are sent to the buyer.
     * @param _amount - The number of bollycoin tokens to purchase
     */
    function purchaseWithUSDC(uint256 _amount, string memory uid)
        public
        nonReentrant
        virtual
        returns (bool)
    {
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

        IERC20(_usdc).transferFrom(
            msgSender(),
            _settlementWallet,
            totalCostInUSDC
        );
        IERC20(_bollycoin).transfer(msgSender(), _amount * 10**18);
        emit Purchase(msgSender(), uid, _amount, usdValue, bytes32("USDC"));
        return true;
    }

    /**
     * @dev used to purchase bollycoin using BUSD. Tokens are sent to the buyer.
     * @param _amount - The number of bollycoin tokens to purchase
     */
    function purchaseWithBUSD(uint256 _amount, string memory uid)
        public
        nonReentrant
        virtual
        returns (bool)
    {
        uint256 balance = IERC20(_busd).balanceOf(msgSender());
        uint256 allowance = IERC20(_busd).allowance(msgSender(), address(this));

        uint256 totalCostInBUSD = (bollycoinPrice) * _amount;
        require(balance >= totalCostInBUSD, "Error: insufficient BUSD Balance");
        require(
            allowance >= totalCostInBUSD,
            "Error: allowance less than spending"
        );

        IERC20(_busd).transferFrom(
            msgSender(),
            _settlementWallet,
            totalCostInBUSD
        );
        IERC20(_bollycoin).transfer(msgSender(), _amount * 10**18);
        emit Purchase(
            msgSender(),
            uid,
            _amount,
            totalCostInBUSD,
            bytes32("BUSD")
        );
        return true;
    }


    /**
     * @dev used to purchase bollycoin using wBTC. Tokens are sent to the buyer.
     * @param _amount - The number of bollycoin tokens to purchase
     */
    function purchaseWithWBTC(uint256 _amount, string memory uid)
        public
        nonReentrant
        virtual
        returns (bool)
    {
        uint256 balance = IERC20(_wbtc).balanceOf(msgSender());
        uint256 allowance = IERC20(_wbtc).allowance(msgSender(), address(this));
        
        uint256 wbtcCmp = IBollycoinPriceFeed(_oracle).getLatestBTCPrice();
        uint256 totalCostInWBTC = (bollycoinPrice) * _amount *10**18 / wbtcCmp / 10**10;
        require(balance >= totalCostInWBTC, "Error: insufficient WBTC Balance");
        require(
            allowance >= totalCostInWBTC,
            "Error: allowance less than spending"
        );

        IERC20(_wbtc).transferFrom(
            msgSender(),
            _settlementWallet,
            totalCostInWBTC
        );
        IERC20(_bollycoin).transfer(msgSender(), _amount * 10**18);
        emit Purchase(
            msgSender(),
            uid,
            _amount,
            totalCostInWBTC,
            bytes32("wBTC")
        );
        return true;
    }
 

    /**
     * @dev used to purchase bollycoin using ETH. ETH is sent to the buyer.
     * @param _amount - The number of bollycoin tokens to purchase
     */
    function purchaseWithETH(uint256 _amount, string memory uid)
        public
        payable
        nonReentrant
        virtual
        returns (bool)
    {
        uint256 ethCmp = IBollycoinPriceFeed(_oracle).getLatestETHPrice();
        uint256 totalCostInETH = (bollycoinPrice) * _amount *10**18 / ethCmp;
        require(
			_msgValue() >= totalCostInETH,
			"Error:Insufficient ETH"
		);
		  

        (bool sent, bytes memory data) = _settlementWallet.call{value: totalCostInETH}("");
        require(sent, "Failed to send ETH"); 		
        IERC20(_bollycoin).transfer(msgSender(), _amount * 10**18);
        emit Purchase(
            msgSender(),
            uid,
            _amount,
            totalCostInETH,
            bytes32("ETH")
        );
        return true;
    }
    /**
     * @dev returns the USDT token address used for purchase.
     */
    function usdt() public view returns (address) {
        return _usdt;
    }

    /**
     * @dev returns the USDC token address used for purchase.
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
     * @dev returns the wBTC token address used for purchase.
     */
     
    function wBTC() public view returns (address) {
        return _wbtc;
    }

    /**
     * @dev returns the admin account used for purchase.
     */
    function admin() public view returns (address) {
        return _admin;
    }

    /**
     * @dev returns the settlement address used for purchase.
     */
    function settlementAddress() public view returns (address) {
        return _settlementWallet;
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
     * @dev updates the wBTC token address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateWBTC(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: address cannot be zero");
        _wbtc = newAddress;
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
        require(newPrice > 0, "Error: price cannot be zero");
        bollycoinPrice = newPrice;
    }

    /**
     * @dev updates the settlement wallet address
     *
     * Requirements:
     * `settlementWallet` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateSettlementWallet(address newAddress)
        public
        virtual
        onlyAdmin
    {
        require(newAddress != address(0), "Error: not a valid address");
        _settlementWallet = newAddress;
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