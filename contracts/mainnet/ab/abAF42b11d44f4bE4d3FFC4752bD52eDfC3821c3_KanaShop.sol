/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract KanaShop is Ownable {
    address private kanaToken; //KanaToken address

    string public _name = "KanaToken shop";
    string public _symbol = "KanaShop";
    uint8 private _decimalsKana = 8;
    uint8 private _decimalsETH = 18;

    uint256 _priceKanaAmount; //兑换比例；
    uint256 _priceEthAmount; //兑换比例；

    uint256 private _totalSellLimit = 200 * 10**uint256(_decimalsETH); //销售总量限制，200 ETH
    uint256 private _totalsold; //已售出总量；

    int256 _releaseIndex; //已释放数组记录的下标

    struct OrderInfo {
        address addrUser;
        uint256 amount;
        bool release; //是否释放
        uint256 createTime; //购买时间；unixtime；精度，秒；
        uint256 updateTime; //释放时间；unixtime；精度，秒；
    }

    struct OrderList {
        address addrUser;
        uint256[] arrOrderId;
    }

    uint256[] arrOrderTimeStamp; //订单时间戳数据；数组下标就是 orderId
    mapping(uint256 => OrderInfo) private mapOrderInfo; //map<orderId, OrderInfo>
    mapping(address => OrderList) private mapAddressOrderList; //map<address, OrderList>

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event EventBuyKana(address indexed dst, uint256 wad);
    event EventOwnerWithdraw(address indexed owner, uint256 amount);
    event EventSetRawPrice(uint256 amountKana, uint256 amountEth);
    event EventRelease(address indexed addr, uint256 amountKana);

    constructor(address _kToken) public {
        kanaToken = _kToken;
        _totalsold = 0;
        _releaseIndex = -1;

        _priceKanaAmount = 0;
        _priceEthAmount = 0;
    }

    fallback() external payable {
        buyKana();
    }

    receive() external payable {
        buyKana();
    }

    function buyKana() public payable {
        uint256 min = 1 * 10**uint256(_decimalsETH);
        uint256 max = 10 * 10**uint256(_decimalsETH);

        uint256 tsOrder = now; //时间戳；

        //单次购买限额
        require(msg.value >= min && msg.value <= max, "amount limit");

        //单地址购买总额限制
        require(
            balanceOf[msg.sender] + msg.value <= max,
            "address total limit error"
        );

        //销售总量限制
        require(_totalsold + msg.value <= _totalSellLimit, "total sell limit");

        //订单信息
        arrOrderTimeStamp.push(tsOrder);
        uint256 currOrderId = arrOrderTimeStamp.length - 1;

        mapOrderInfo[currOrderId].addrUser = msg.sender;
        mapOrderInfo[currOrderId].amount = msg.value;
        mapOrderInfo[currOrderId].release = false;
        mapOrderInfo[currOrderId].createTime = tsOrder;
        mapOrderInfo[currOrderId].updateTime = tsOrder;

        //订单列表
        mapAddressOrderList[msg.sender].addrUser = msg.sender;
        mapAddressOrderList[msg.sender].arrOrderId.push(currOrderId);

        //金额更新
        balanceOf[msg.sender] += msg.value;
        _totalsold += msg.value;

        emit EventBuyKana(msg.sender, msg.value);
    }

    function getOrdersByAddress(address addrUser)
        public
        view
        returns (
            uint256 totalOrders,
            address[] memory addrUsers,
            uint256[] memory amounts,
            bool[] memory releases,
            uint256[] memory createTimes,
            uint256[] memory updateTimes
        )
    {
        totalOrders = mapAddressOrderList[addrUser].arrOrderId.length;

        address[] memory retAddrUsers = new address[](totalOrders);
        uint256[] memory retAmounts = new uint256[](totalOrders);
        bool[] memory retReleases = new bool[](totalOrders);
        uint256[] memory retCreateTimes = new uint256[](totalOrders);
        uint256[] memory retUpdateTimes = new uint256[](totalOrders);

        for (uint256 i = 0; i < totalOrders; i++) {
            uint256 currOrderId = mapAddressOrderList[addrUser].arrOrderId[i];

            retAddrUsers[i] = mapOrderInfo[currOrderId].addrUser;
            retAmounts[i] = mapOrderInfo[currOrderId].amount;
            retReleases[i] = mapOrderInfo[currOrderId].release;
            retCreateTimes[i] = mapOrderInfo[currOrderId].createTime;
            retUpdateTimes[i] = mapOrderInfo[currOrderId].updateTime;
        }

        addrUsers = retAddrUsers;
        amounts = retAmounts;
        releases = retReleases;
        createTimes = retCreateTimes;
        updateTimes = retUpdateTimes;
    }

    function ownerWithdraw(uint256 wad) public onlyOwner {
        payable(address(this.owner())).transfer(wad);
        emit EventOwnerWithdraw(address(this.owner()), wad);
    }

    function release() public onlyOwner {
        //     return IERC20(kanaToken).balanceOf(address(this));

        require(_priceKanaAmount != 0, "need to set price of kana");
        require(_priceEthAmount != 0, "need to set price of eth");

        uint256 currIndex = uint256(_releaseIndex + 1);
        for (uint256 i = currIndex; i < arrOrderTimeStamp.length; i++) {
            if (true == mapOrderInfo[i].release) continue;

            //兑换计算
            uint256 amountKanaRelease =
                (mapOrderInfo[i].amount * _priceKanaAmount) / _priceEthAmount;

            IERC20(kanaToken).transfer(
                mapOrderInfo[i].addrUser,
                amountKanaRelease
            );
            mapOrderInfo[i].release = true;
            mapOrderInfo[i].updateTime = now;
            currIndex = i;

            emit EventRelease(mapOrderInfo[i].addrUser, amountKanaRelease);
        }

        _releaseIndex = int256(currIndex);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function totalSellLimit() public view returns (uint256) {
        return _totalSellLimit;
    }

    function totalSold() public view returns (uint256) {
        return _totalsold;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function decimalsETH() public view returns (uint8) {
        return _decimalsETH;
    }

    function decimalsKana() public view returns (uint8) {
        return _decimalsKana;
    }

    function setRawPrice(uint256 amountKana, uint256 amountEth)
        public
        onlyOwner
    {
        require(_getRate(amountKana, amountEth) >= 1, "kana price too high");

        _priceKanaAmount = amountKana;
        _priceEthAmount = amountEth;
    }

    function getRawPrice()
        public
        view
        returns (uint256 amountKana, uint256 amountEth)
    {
        amountKana = _priceKanaAmount;
        amountEth = _priceEthAmount;
    }

    function _getRate(uint256 amountKana, uint256 amountEth)
        internal
        view
        returns (uint256)
    {
        require(_decimalsETH >= _decimalsKana, "decimal error");

        return
            (amountKana * 10**uint256(_decimalsETH - _decimalsKana)) /
            amountEth;
    }

    function getRate() public view returns (uint256) {
        return _getRate(_priceKanaAmount, _priceEthAmount);
    }
}