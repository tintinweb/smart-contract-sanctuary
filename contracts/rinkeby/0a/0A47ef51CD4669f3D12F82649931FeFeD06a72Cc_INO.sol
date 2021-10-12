// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IGameDaoNFT.sol";
import "./Pausable.sol";


contract INO is Ownable,Pausable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    /************************发行参数**********************/

    address payable public wallet; // 钱包地址
    address public paymentCurrency; //支付币种
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public NFTContract;
    uint128 public totalTokens;//总销售数量

    struct INOConfig {
        bool hasWhiteList;//是否白名单购买
        bool addressPurchaseLimit; //是否单个地址购买限制 如果true就是addressPurchaseMax 否则不限
        uint8 purchaseNumber; //单次购买最大数量
        uint8 addressPurchaseMax; //单个地址最多购买数量
        uint64 startTime; //开始时间
        uint64 endTime; //结束时间
        uint128 price;//销售价格
    }

    INOConfig public inoConfig;
    mapping(address => uint256)  whiteList; //正式发行白名单-> 每个白名单购买个数

    struct PresaleConfig {
        uint64 presaleStartTime; //预售开始时间
        uint64 presaleEndTime; //预售结束时间
        uint128 presaleAmount; //预售总数量
        uint128 presalePrice;//预售价格
    }
    PresaleConfig public presaleConfig;
    mapping(address => uint256) public presaleList; //预售名单->每个预售名单购买个数

    //保证1 presaleList和whiteList之和要小于presaleAmont和totalTokens  presaleAmont要小于totalTokens


    /************************状态*********************/

    bool private hasInitINOConfig; //是否初始化INO
    bool private hasInitPresaleConfig; //是否初始化预售


    uint256 public totalCommit; //正式发行(不管是不是白名单方式) 实时购买总数量
    uint256 public presaleTotal; //预售 实时购买总数量

    uint256 public whiteListTotal; //白名单whiteList设置的总数
    uint256 public presaleListTotal;//预售presaleList设置的总数

    mapping(address => uint256) public committedMap; //正式发行 实时购买map
    mapping(address => uint256) public presaleMap; //预售 实时购买map

    /************************modifier&constructor*********************/

    //是否需要开启之后才能设置呢
    modifier SetBeforeSale() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");

        if (hasInitPresaleConfig) {
            require(block.timestamp < presaleConfig.presaleStartTime,"set should before presale start time ");
        }

        if (hasInitINOConfig) {
            require(block.timestamp < inoConfig.startTime,"set should before starttime");
        }
        _;
    }

    modifier OwnerSetBeforeINO() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        require(hasInitINOConfig,"not init info config");
        require(block.timestamp < inoConfig.startTime,"ino started");
        _;

    }

    modifier OwnerSetBeforePresale() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        require(hasInitINOConfig,"not init info config");
        require(hasInitPresaleConfig,"not init presale config");
        require(block.timestamp < presaleConfig.presaleStartTime,"presale started");
        _;

    }

    constructor(address payable _wallet,address   _NFTContract,address  _paymentCurrency, uint128 _tokenTokens)  {
        require(_wallet != address(0), "wallet is the zero address");
        require(_NFTContract != address(0), "nft contract is the zero address");
        require(_paymentCurrency != address(0), "paymentCurrency is the zero address");
        if (_paymentCurrency != ETH_ADDRESS) {
            require(IERC20(_paymentCurrency).decimals() > 0, "Payment currency is not ERC20");
        }
        require(_tokenTokens > 0,"invalid totaltokens");
        wallet = _wallet;
        NFTContract = _NFTContract;
        totalTokens = _tokenTokens;

        paymentCurrency = _paymentCurrency;
    }


    /***********************common param*********************/


    function setWallet(address payable _wallet) external SetBeforeSale whenNotPaused {
        require(_wallet != address(0), "wallet is the zero address");
        wallet = _wallet;
    }

    function setNFTContract(address  _NFTContract) external SetBeforeSale whenNotPaused {
        require(_NFTContract != address(0), "nft contract is the zero address");
        NFTContract = _NFTContract;
    }

    function setPaymentCurrency(address  _paymentCurrency) external SetBeforeSale whenNotPaused {
        require(_paymentCurrency != address(0), "paymentCurrency is the zero address");
        paymentCurrency = _paymentCurrency;
    }

    function setTotalTokens( uint128 _tokenTokens) external SetBeforeSale whenNotPaused {
        require(_tokenTokens > 0,"invalid totaltokens");
        totalTokens = _tokenTokens;
    }


    /************************config set*********************/
    //正式发行设置
    function InitSetINOConfig(
        bool _hasWhiteList,
        bool _addressPurchaseLimit,
        uint8 _purchaseNumber,
        uint8 _addressPurchaseMax,
        uint64 _startTime,
        uint64 _endTime,
        uint128 _price) public onlyOwner whenNotPaused
    {
        require(!hasInitINOConfig,"has init ino config"); //只能单独设置
        require(_purchaseNumber > 0,"invalid _purchaseNumber");
        require(_addressPurchaseMax > 0,"invalid _addressPurchaseMax");
        require(_endTime > _startTime && _startTime > 0,"invalid ino time");
        require(_price > 0,"invalid price");


        inoConfig.hasWhiteList = _hasWhiteList;
        inoConfig.addressPurchaseLimit = _addressPurchaseLimit;
        inoConfig.purchaseNumber = _purchaseNumber;
        inoConfig.addressPurchaseMax = _addressPurchaseMax;
        inoConfig.startTime = _startTime;
        inoConfig.endTime = _endTime;
        inoConfig.price = _price;
        hasInitINOConfig = true;
    }


    function InitSetPresaleConfig(
        uint128 _presalePrice,
        uint128 _presaleAmount,
        uint64 _presaleStartTime,
        uint64 _presaleEndTime

    ) public onlyOwner whenNotPaused
    {
        require(!hasInitPresaleConfig,"has init presale config");
        require(hasInitINOConfig,"need init ino config");
        require(_presaleAmount >0 && _presaleAmount <= totalTokens,"invalid _presaleAmount" );
        require(_presaleEndTime > _presaleStartTime && _presaleStartTime>0 && _presaleEndTime < inoConfig.startTime,"invalid presale time" );
        require(_presalePrice > 0,"invalid price");

        presaleConfig.presaleAmount = _presaleAmount;
        presaleConfig.presaleStartTime = _presaleStartTime;
        presaleConfig.presaleEndTime = _presaleEndTime;
        presaleConfig.presalePrice = _presalePrice;
        hasInitPresaleConfig = true;
    }




    /************************ino set*********************/

    //INO的设置 ---- 肯定是在ino之前 但是可以在预售中操作
    function SetHasWhiteList(bool state) public OwnerSetBeforeINO whenNotPaused {
        require(inoConfig.hasWhiteList != state,"same value");
        inoConfig.hasWhiteList = state;
    }


    function SetAddressPurchaseLimit(bool state) public OwnerSetBeforeINO whenNotPaused {
        require(inoConfig.addressPurchaseLimit != state,"same value");
        inoConfig.addressPurchaseLimit = state;
    }


    function SetPurchaseNumber(uint8 _purchaseNumber) public OwnerSetBeforeINO whenNotPaused {
        require(inoConfig.purchaseNumber != _purchaseNumber,"same value");
        inoConfig.purchaseNumber = _purchaseNumber;
    }


    function SetAddressPurchaseMax(uint8 _addressPurchaseMax) public OwnerSetBeforeINO whenNotPaused{
        require(inoConfig.addressPurchaseMax != _addressPurchaseMax,"same value");
        inoConfig.addressPurchaseMax = _addressPurchaseMax;
    }

    function SetPrice(uint128 _price) public OwnerSetBeforeINO {
        require(inoConfig.price != _price,"same value");
        inoConfig.price = _price;
    }


    //提前或者延后一点时间
    function SetINOStartTime(uint64 _startTime) public OwnerSetBeforeINO whenNotPaused{
        require( block.timestamp < _startTime,"invalid ino time");
        require(_startTime < inoConfig.endTime,"invalid ino time");
        if (hasInitPresaleConfig) {
            require(_startTime > presaleConfig.presaleEndTime ,"invalid ino time");
        }

        require(inoConfig.startTime != _startTime,"same value");
        inoConfig.startTime = _startTime;
    }

    //这个可以销售期间设置提前或者延后时间
    function SetINOEndTime(uint64 _endTime) public onlyOwner whenNotPaused{
        require(hasInitINOConfig,"not init info config");
        require(block.timestamp < _endTime && block.timestamp < inoConfig.endTime, "invalid ino time");
        require(_endTime>inoConfig.startTime,"invalid ino time");
        if (hasInitPresaleConfig) {
            require(_endTime > presaleConfig.presaleEndTime ,"invalid ino time");
        }

        require(inoConfig.endTime != _endTime,"same value");
        inoConfig.endTime = _endTime;
    }



    function SetWhiteList(address[] memory _accounts, uint256[] memory _amounts) public OwnerSetBeforeINO whenNotPaused{
        require(inoConfig.hasWhiteList,"only whitelist");
        require(_accounts.length != 0,"invalid _accounts");
        require(_accounts.length == _amounts.length,"_accounts not match _amounts");

        //是可以在预售期间设置这个的 presaleListTotal必须确定才行 不然可能会超过总数
        if(hasInitPresaleConfig) {
            require(block.timestamp > presaleConfig.presaleStartTime,"presaleListTotal unsure");
        }

        for (uint i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 amount = _amounts[i];
            require(account != address(0),"zero address");
            require(amount > 0,"invalid amount");
            uint256 previousPoints = whiteList[account];

            if (amount != previousPoints) {
                whiteList[account] = amount;
                whiteListTotal = whiteListTotal.sub(previousPoints).add(amount);
                require(whiteListTotal + presaleListTotal <= totalTokens);
            }
        }
    }




    /************************presale set*********************/
    //预售设置
    function SetPresaleStartTime(uint64 _presaleStartTime) public OwnerSetBeforePresale whenNotPaused{
        require(block.timestamp < _presaleStartTime,"invalid presale time");
        require(_presaleStartTime < presaleConfig.presaleEndTime,"invlaid  presale time");
        require(presaleConfig.presaleStartTime != _presaleStartTime,"same value");
        presaleConfig.presaleStartTime = _presaleStartTime;
    }


    //这个不允许在预售中设置 也是得在开启预售之前设置。
    function SetPresaleEndTime(uint64 _presaleEndTime) public OwnerSetBeforePresale whenNotPaused{
        require(_presaleEndTime > presaleConfig.presaleStartTime,"invalid presale time");
        require(_presaleEndTime < inoConfig.startTime,"invalid presale time");
        require(presaleConfig.presaleEndTime != _presaleEndTime,"same value");
        presaleConfig.presaleEndTime = _presaleEndTime;
    }

    function SetPresaleAmount(uint128 _presaleAmount) public OwnerSetBeforePresale whenNotPaused{
        require(presaleConfig.presaleAmount != _presaleAmount,"same value");
        presaleConfig.presaleAmount = _presaleAmount;
    }

    function SetPresalePrice(uint128 _presalePrice) public OwnerSetBeforePresale whenNotPaused{
        require(presaleConfig.presalePrice != _presalePrice,"same value");
        presaleConfig.presalePrice = _presalePrice;
    }


    //如果预售时候人没买 那么会延后给别人买
    function SetPresaleList(address[] memory _accounts, uint256[] memory _amounts) public OwnerSetBeforePresale whenNotPaused{
        require(_accounts.length != 0,"invalid _accounts");
        require(_accounts.length == _amounts.length,"_accounts not match _amounts");
        for (uint i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 amount = _amounts[i];
            require(account != address(0),"zero address");
            require(amount > 0,"invalid amount");
            uint256 previousPoints = presaleList[account];

            if (amount != previousPoints) {
                presaleList[account] = amount;
                presaleTotal = presaleTotal.sub(previousPoints).add(amount);
                require(presaleTotal <= totalTokens);
            }
        }
    }



    /************************mint*********************/

    //4个mint
    function MintPresaleETH(uint256 count) public payable whenNotPaused{
        require(hasInitINOConfig,"need init ino config");
        require(hasInitPresaleConfig,"not init presale config");
        require(block.timestamp >= presaleConfig.presaleStartTime && block.timestamp <= presaleConfig.presaleEndTime ,"invalid time");

        require(paymentCurrency == ETH_ADDRESS,"not eth");

        require(wallet != address(0), "wallet not set");
        require(presaleConfig.presalePrice > 0, "presale price not set");
        require(count > 0, "invalid count");

        require(presaleList[address(msg.sender)] > count,"not presale or exceed max presale per account");
        require(presaleList[address(msg.sender)] >= presaleMap[address(msg.sender)] + count,"exceed per account presale");
        require(presaleConfig.presaleAmount >= presaleTotal + count,"not enougt to presale");

        require(uint256(presaleConfig.presalePrice).mul(count) == msg.value,"invalid value");

        presaleTotal+=count;
        presaleMap[address(msg.sender)] += count;
        wallet.transfer(msg.value);

        IGameDaoNFT(NFTContract).mintTo(count,msg.sender);
    }

    function MintPresaleTokens(uint256 count,uint256 amounts) public whenNotPaused{
        require(hasInitINOConfig,"need init ino config");
        require(hasInitPresaleConfig,"not init presale config");
        require(block.timestamp >= presaleConfig.presaleStartTime && block.timestamp <= presaleConfig.presaleEndTime ,"invalid time");

        require(paymentCurrency != ETH_ADDRESS,"is eth");

        require(wallet != address(0), "wallet not set");
        require(presaleConfig.presalePrice > 0, "presale price not set");
        require(amounts > 0 ,"invalid amount");
        require(count > 0, "invalid count");

        require(presaleList[address(msg.sender)] > count,"not presale or exceed max presale per account");
        require(presaleList[address(msg.sender)] >= presaleMap[address(msg.sender)] + count,"exceed per account presale");
        require(presaleConfig.presaleAmount >= presaleTotal + count,"not enougt to presale");

        require(uint256(presaleConfig.presalePrice).mul(count) == amounts,"not enougth to presale");


        presaleTotal+=count;
        presaleMap[address(msg.sender)] += count;
        IERC20(paymentCurrency).safeTransfer(wallet,amounts);

        IGameDaoNFT(NFTContract).mintTo(count,msg.sender);
    }


    function MintETH(uint256  count) public payable whenNotPaused{
        require(hasInitINOConfig,"need init ino config");
        require(block.timestamp >= inoConfig.startTime && block.timestamp <= inoConfig.endTime ,"invalid time");

        require(paymentCurrency == ETH_ADDRESS,"not eth");

        require(wallet != address(0), "wallet not set");
        require(inoConfig.price > 0, "price not set");
        require(count > 0, "invalid count");


        if (inoConfig.addressPurchaseLimit) {
            require(inoConfig.addressPurchaseMax >= committedMap[address(msg.sender)] + count,"exceed per account purchase");
        }

        if (inoConfig.hasWhiteList) {
            require(whiteList[address(msg.sender)] > count,"not whitelist or  exceed max purchase per account");
            require(whiteList[address(msg.sender)] >= committedMap[address(msg.sender)] + count,"exceed per account purchase");
        }

        require(count <= inoConfig.purchaseNumber,"exceed max one time mint number");
        require(presaleTotal + totalCommit + count <= totalTokens,"not enougth to mint" );

        require(uint256(inoConfig.price).mul(count) == msg.value,"invalid amount");


        totalCommit += count;

        committedMap[address(msg.sender)] += count;
        wallet.transfer(msg.value);

        IGameDaoNFT(NFTContract).mintTo(count,msg.sender);
    }

    function MintTokens(uint256 count,uint256 amounts) public whenNotPaused{
        require(hasInitINOConfig,"need init ino config");
        require(block.timestamp >= inoConfig.startTime && block.timestamp <= inoConfig.endTime ,"invalid time");

        require(paymentCurrency != ETH_ADDRESS,"is eth");

        require(wallet != address(0), "wallet not set");
        require(inoConfig.price > 0, " price not set");
        require(count > 0, "invalid count");
        require(amounts>0,"invalid amounts");


        if (inoConfig.addressPurchaseLimit) {
            require(inoConfig.addressPurchaseMax >= committedMap[address(msg.sender)] + count,"exceed per account purchase");
        }

        if (inoConfig.hasWhiteList) {
            require(whiteList[address(msg.sender)] > count,"not whitelist or  exceed max purchase per account");
            require(whiteList[address(msg.sender)] >= committedMap[address(msg.sender)] + count,"exceed per account purchase");
        }

        require(count <= inoConfig.purchaseNumber,"exceed max one time mint number");
        require(presaleTotal + totalCommit + count <= totalTokens,"not enougth to mint" );

        require(uint256(inoConfig.price).mul(count) == amounts,"invalid amount");


        totalCommit += count;

        committedMap[address(msg.sender)] += count;
        IERC20(paymentCurrency).safeTransfer(wallet,amounts);

        IGameDaoNFT(NFTContract).mintTo(count,msg.sender);
    }

}