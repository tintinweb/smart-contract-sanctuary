//SourceUnit: BtGetAsset.sol

pragma solidity ^0.5.13;
import './Common.sol';
contract BtGetAsset is Common{

    PublicOfferPrice[] publicOfferPriceList;

    mapping(uint256 => AssetRecord) recordMap;

    mapping(address => uint256[]) userRecordMap;

    uint256 _assetRecordId;

    struct PublicOfferPrice {
        uint256 amount;   // example 30000 * 10 ** 18
        uint256 price;    // example 7 * 10 ** 17
    }

    struct AssetRecord {
        uint256 id;
        address userAddress;
        uint256 price;     // example 7 * 10 ** 17
        uint256 amount;
        uint256 surplusAmount;
        uint256 time;
        uint256 signTime;
    }

    function getOfferPrice() public view returns(uint256[] memory amountList, uint256[] memory priceList) {
        amountList = new uint256[](publicOfferPriceList.length);
        priceList = new uint256[](publicOfferPriceList.length);
        for (uint256 i = 0; i < publicOfferPriceList.length; i ++) {
            amountList[i] = publicOfferPriceList[i].amount;
            priceList[i] = publicOfferPriceList[i].price;
        }
    }

    function setOfferPrice(uint256[] memory amountList, uint256[] memory priceList) public onlyAdmin returns(uint256) {
        require(amountList.length == priceList.length, "error01");
        publicOfferPriceList.length = 0;
        for (uint256 i = 0; i < amountList.length; i ++) {
            publicOfferPriceList.push(PublicOfferPrice(amountList[i], priceList[i]));
        }
        return SUCCESS;
    }

    function addAsset(uint256 amount) public returns(uint256) {
        TRC20 usdtToken = TRC20(usdt_contract);
        require(publicOfferPriceList.length > 0, "error02");
        uint256 price = publicOfferPriceList[publicOfferPriceList.length - 1].price;
        for (uint256 i = 0; i < publicOfferPriceList.length; i ++) {
            if (amount >= publicOfferPriceList[i].amount) {
                price = publicOfferPriceList[i].price;
                break;
            }
        }
        uint usdtAmount = amount * price; // 价格 10 ** 6
        assert(usdtToken.transferFrom(msg.sender, receive_address, usdtAmount) == true);
        _assetRecordId++;
        userRecordMap[msg.sender].push(_assetRecordId);
        uint256 allAmount = amount * 10 ** 18;
        uint256 releaseTokenAmount = allAmount * 15 / 100;
        recordMap[_assetRecordId] = AssetRecord(_assetRecordId, msg.sender, price, allAmount - releaseTokenAmount, allAmount - releaseTokenAmount, now, now);
        TRC20 token = TRC20(token_address);
        assert(token.transferFrom(send_address, msg.sender, releaseTokenAmount) == true);
        return SUCCESS;
    }

    function userRecord(address userAddress, uint256 page, uint256 limit) public view returns(uint[5][] memory arList) {
        arList = new uint[5][](limit);
        for (uint i = 0; i < limit; i ++) {
            if ((i + 1 + (page - 1) * limit) <= userRecordMap[userAddress].length) {
                AssetRecord memory record = recordMap[userRecordMap[userAddress][userRecordMap[userAddress].length - (page - 1) * limit - i  - 1]];
                arList[i][0] = record.id;
                arList[i][1] = record.amount;
                arList[i][2] = record.surplusAmount;
                arList[i][3] = record.price;
                arList[i][4] = record.time;
            }
        }
    }

    function getAsset(uint256 id) public returns(uint256) {
        AssetRecord storage record = recordMap[id];
        require(record.id > 0, "error03");
        require(msg.sender == record.userAddress, "error01");
        uint getDays = ((now + 28800) / (24 * 60 * 60) - (record.signTime + 28800) / (24 * 60 * 60));
        if (getDays <= 0) {
            return NODATA;
        }
        if (record.amount <= 0) {
            return NODATA;
        }
        uint256 releaseAmount = (record.amount / 120) * getDays;
        if (releaseAmount >= record.surplusAmount) {
            releaseAmount = record.surplusAmount;
            record.surplusAmount = 0;
        } else {
            record.surplusAmount = record.surplusAmount - releaseAmount;
        }
        record.signTime = now;
        uint256 releaseTokenAmount = releaseAmount / record.price;
        TRC20 token = TRC20(token_address);
        assert(token.transferFrom(send_address, msg.sender, releaseTokenAmount) == true);
        return SUCCESS;
    }
}


//SourceUnit: Common.sol

pragma solidity ^0.5.13;

import './TRC20.sol';

contract Common {

    // 管理员地址
    mapping(address => bool) internal managerAddressList;

    address internal minter;

    // USDT合约地址
    address constant usdt_contract = address(0x41A614F803B6FD780986A42C78EC9C7F77E6DED13C);

    address internal receive_address = address(0x419AAFF826A7B85910800F99F900519D15451A0AA8);

    address constant token_address = address(0x41460FFBA315092714C1D62F0C1A8D0EBA77398A50);

    address internal send_address = address(0x419AAFF826A7B85910800F99F900519D15451A0AA8);

    // 返回代码常量：成功（0）
    uint constant SUCCESS = 0;

    // 返回代码常量：没权限（2）
    uint constant NOAUTH = 2002;

    // 数据不存在
    uint constant NODATA = 2003;

    // 数据已存在
    uint constant DATA_EXIST = 2004;

    modifier onlyAdmin() {
        require(
            msg.sender == minter || managerAddressList[msg.sender],
            "Only admin can call this."
        );
        _;
    }

    // 设置管理员地址
    function setManager(address userAddress) onlyAdmin public returns(uint){
        managerAddressList[userAddress] = true;
        return SUCCESS;
    }

    function setReceive(address userAddress) onlyAdmin public returns(uint){
        receive_address = address(userAddress);
        return SUCCESS;
    }

    function getReceive() onlyAdmin public returns(address){
        return receive_address;
    }

    function setSend(address userAddress) onlyAdmin public returns(uint){
        send_address = address(userAddress);
        return SUCCESS;
    }

    function getSend() onlyAdmin public returns(address){
        return send_address;
    }

    // 提取trx
    function drawTrx(address drawAddress, uint amount) onlyAdmin public returns(uint) {
        address(uint160(drawAddress)).transfer(amount * 10 ** 6);
        return SUCCESS;
    }

    // 提取其他代币
    function drawCoin(address contractAddress, address drawAddress, uint amount) onlyAdmin public returns(uint) {
        TRC20 token = TRC20(contractAddress);
        uint256 decimal = 10 ** uint256(token.decimals());
        token.transfer(drawAddress, amount * decimal);
        return SUCCESS;
    }

    constructor() public {
        minter = msg.sender;
    }
}


//SourceUnit: TRC20.sol

pragma solidity ^0.5.13;

contract TRC20 {

  function transferFrom(address from, address to, uint value) external returns (bool ok);

  function decimals() public view returns (uint8);

  function transfer(address _to, uint256 _value) public;

  function balanceOf(address account) external view returns (uint256);
}