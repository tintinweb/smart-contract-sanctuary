/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "e3");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ow1");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ow2");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "e4");
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }
}

interface IERC721Enumerable {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mintForMiner(address _to) external returns (bool, uint256);
}

interface IWHT {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

contract IGOPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    address payable public devAddress;
    address public IGOPoolFactory;
    IERC20 public ETH;
    mapping(address => mapping(uint256 => bool)) public CanBuyBackList;
    mapping(address => uint256[]) public UserIgoTokenIdList;
    mapping(address => uint256) public UserIgoTokenIdListNum;
    // mapping(uint256 => tokenIdInfo) public TokenIdStatusList;
    // mapping(uint256 => bool) public TokenIdMintStatusList;
    // mapping(uint256 => bool) public TokenIdBuybackStatusList;
    // mapping(uint256 => bool) public TokenIdSwapStatusStatusList;
    mapping(uint256 => tokenIdInfo) public TokenIdSwapStatusStatusList;

    struct tokenIdInfo {
        bool mintStatus;
        bool buybackStatus;
        bool swapStatus;
    }

    struct orderItem_1 {
        uint256 orderId;
        address payable owner;
        IERC721Enumerable nftToken;
        uint256 igoAmount;
        address erc20Token;
        uint256 price;
        bool orderStatus;
        string orderMd5;
        uint256 hasigoAmount;
        uint256 startBlock;
        uint256 endBlock;
    }

    struct orderItem_2 {
        IERC20 swapToken;
        uint256 swapPrice;
        uint256 GetRewardBlockNum;
        uint256 BuyBackNum;
        uint256 swapFee;
        uint256 maxIgoAmount;
    }

    orderItem_1 public OrderDetail1;
    orderItem_2 public OrderDetail2;

    constructor(address _devAddress, address _owner, IERC20 _ETH, uint256 orderId, IERC721Enumerable _nftToken, uint256 _igoAmount, address _erc20Token, uint256 _price, string memory _orderMd5, uint256 _startBlock, uint256 _endBlock) public {
        IGOPoolFactory = msg.sender;
        devAddress = payable(_devAddress);
        ETH = _ETH;
        OrderDetail1.orderId = orderId;
        OrderDetail1.owner = payable(_owner);
        OrderDetail1.nftToken = _nftToken;
        OrderDetail1.igoAmount = _igoAmount;
        OrderDetail1.erc20Token = _erc20Token;
        OrderDetail1.price = _price;
        OrderDetail1.orderStatus = true;
        OrderDetail1.orderMd5 = _orderMd5;
        OrderDetail1.hasigoAmount = 0;
        OrderDetail1.startBlock = _startBlock;
        OrderDetail1.endBlock = _endBlock;
        OrderDetail2.swapFee = 5;
        OrderDetail2.maxIgoAmount = 0;
    }

    function setSwapTokenList(IERC20 _swapToken, uint256 _swapPrice) public onlyOwner {
        OrderDetail2.swapToken = _swapToken;
        OrderDetail2.swapPrice = _swapPrice;
    }

    function setDevAddress(address payable _devAddress) public {
        require(msg.sender == IGOPoolFactory, "e001");
        devAddress = _devAddress;
    }

    function setSwapFee(uint256 _fee) public {
        require(msg.sender == IGOPoolFactory, "e002");
        OrderDetail2.swapFee = _fee;
    }

    function setGetRewardBlockNum(uint256 _blockNum) public onlyOwner {
        OrderDetail2.GetRewardBlockNum = _blockNum;
    }

    function setMaxIgoNum(uint256 _maxIgoAmount) public onlyOwner {
        OrderDetail2.maxIgoAmount = _maxIgoAmount;
    }

    function igo(uint256 idoNum) public nonReentrant {
        require(block.number >= OrderDetail1.startBlock && block.number <= OrderDetail1.endBlock, "e008");
        require(OrderDetail1.hasigoAmount.add(idoNum) <= OrderDetail1.igoAmount, "e009");
        if (OrderDetail2.maxIgoAmount > 0) {
            require(UserIgoTokenIdListNum[msg.sender] + idoNum <= OrderDetail2.maxIgoAmount, "e031");
        }
        uint256 allAmount = (OrderDetail1.price).mul(idoNum);
        require(OrderDetail1.orderStatus == true, "e010");
        require(IERC20(OrderDetail1.erc20Token).balanceOf(msg.sender) >= allAmount, "e011");
        uint256 fee = allAmount.mul(OrderDetail2.swapFee).div(100);
        uint256 toUser = allAmount.sub(fee);
        IERC20(OrderDetail1.erc20Token).safeTransferFrom(msg.sender, address(this), toUser);
        IERC20(OrderDetail1.erc20Token).safeTransferFrom(msg.sender, devAddress, fee);
        for (uint256 i = 0; i < idoNum; i++) {
            (,uint256 _token_id) = OrderDetail1.nftToken.mintForMiner(msg.sender);
            // TokenIdMintStatusList[_token_id] = true;
            TokenIdSwapStatusStatusList[_token_id].mintStatus = true;
            CanBuyBackList[msg.sender][_token_id] = true;
            UserIgoTokenIdList[msg.sender].push(_token_id);
            OrderDetail1.hasigoAmount = OrderDetail1.hasigoAmount.add(1);
            UserIgoTokenIdListNum[msg.sender] = UserIgoTokenIdListNum[msg.sender].add(1);
        }
    }

    function igoWithEth(uint256 idoNum) public payable nonReentrant {
        require(block.number >= OrderDetail1.startBlock && block.number <= OrderDetail1.endBlock, "e012");
        require(OrderDetail1.hasigoAmount.add(idoNum) <= OrderDetail1.igoAmount, "e013");
        if (OrderDetail2.maxIgoAmount > 0) {
            require(UserIgoTokenIdListNum[msg.sender] + idoNum <= OrderDetail2.maxIgoAmount, "e032");
        }
        uint256 allAmount = (OrderDetail1.price).mul(idoNum);
        require(OrderDetail1.orderStatus == true, "e014");
        require(msg.value >= allAmount, "e015");
        uint256 fee = allAmount.mul(OrderDetail2.swapFee).div(100);
        uint256 toUser = allAmount.sub(fee);
        payable(address(this)).transfer(toUser);
        devAddress.transfer(fee);
        for (uint256 i = 0; i < idoNum; i++) {
            (,uint256 _token_id) = OrderDetail1.nftToken.mintForMiner(msg.sender);
            // TokenIdMintStatusList[_token_id] = true;
            TokenIdSwapStatusStatusList[_token_id].mintStatus = true;
            CanBuyBackList[msg.sender][_token_id] = true;
            UserIgoTokenIdList[msg.sender].push(_token_id);
            OrderDetail1.hasigoAmount = OrderDetail1.hasigoAmount.add(1);
            UserIgoTokenIdListNum[msg.sender] = UserIgoTokenIdListNum[msg.sender].add(1);
        }
    }

    function getWrongTokens(IERC20 _token) public onlyOwner {
        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "e016");
        _token.safeTransfer(msg.sender, amount);
    }

    function swapToken(uint256 _tokenId) public {
        uint256 allAmount = OrderDetail2.swapPrice;
        uint256 fee = allAmount.mul(OrderDetail2.swapFee).div(100);
        uint256 toUser = allAmount.sub(fee);
        OrderDetail1.nftToken.transferFrom(msg.sender, OrderDetail1.owner, _tokenId);
        if (CanBuyBackList[msg.sender][_tokenId] == true) {
            CanBuyBackList[msg.sender][_tokenId] == false;
            OrderDetail2.BuyBackNum = OrderDetail2.BuyBackNum.add(1);
        }
        //TokenIdStatusList[_tokenId].swapStatus = true;
        // TokenIdSwapStatusStatusList[_tokenId] = true;
        TokenIdSwapStatusStatusList[_tokenId].swapStatus = true;
        OrderDetail2.swapToken.safeTransfer(msg.sender, toUser);
        OrderDetail2.swapToken.safeTransfer(devAddress, fee);
    }

    function buyback(uint256[] memory _tokenIdList) public {
        require(block.number < OrderDetail2.GetRewardBlockNum, "e017");
        uint256 buybackNum = _tokenIdList.length;
        uint256 leftrate = uint256(100).sub(OrderDetail2.swapFee);
        uint256 allAmount = (OrderDetail1.price).mul(leftrate).mul(buybackNum).div(100);
        uint256 fee = allAmount.mul(OrderDetail2.swapFee).div(100);
        uint256 toUser = allAmount.sub(fee);
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            require(CanBuyBackList[msg.sender][_tokenIdList[i]] == true, "e018");
        }
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            OrderDetail1.nftToken.transferFrom(msg.sender, OrderDetail1.owner, _tokenIdList[i]);
            CanBuyBackList[msg.sender][_tokenIdList[i]] = false;
            OrderDetail2.BuyBackNum = OrderDetail2.BuyBackNum.add(1);
            //TokenIdStatusList[_tokenIdList[i]].buybackStatus = true;
            // TokenIdBuybackStatusList[_tokenIdList[i]] = true;
            TokenIdSwapStatusStatusList[_tokenIdList[i]].buybackStatus = true;
        }
        if (OrderDetail1.erc20Token != address(0)) {
            IERC20(OrderDetail1.erc20Token).safeTransfer(msg.sender, toUser);
            IERC20(OrderDetail1.erc20Token).safeTransfer(devAddress, fee);
        } else {
            msg.sender.transfer(toUser);
            devAddress.transfer(fee);
        }
    }

    function getReward() public {
        require(block.number > OrderDetail2.GetRewardBlockNum, "e019");
        require(OrderDetail1.owner == msg.sender, "e020");
        uint256 leftrate = uint256(100).sub(OrderDetail2.swapFee);
        uint256 rewardNum = OrderDetail1.hasigoAmount.sub(OrderDetail2.BuyBackNum);
        require(rewardNum > 0, "e021");
        uint256 allAmount = (OrderDetail1.price).mul(leftrate).mul(rewardNum).div(100);
        require(allAmount > 0, "e022");
        uint256 fee = allAmount.mul(OrderDetail2.swapFee).div(100);
        uint256 toUser = allAmount.sub(fee);
        if (OrderDetail1.erc20Token != address(0)) {
            IERC20(OrderDetail1.erc20Token).safeTransfer(msg.sender, toUser);
            IERC20(OrderDetail1.erc20Token).safeTransfer(devAddress, fee);
        } else {
            msg.sender.transfer(toUser);
            devAddress.transfer(fee);
        }
    }

    function cleanEth() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function getTokenInfoByIndex() public view returns (orderItem_1 memory orderItem1, orderItem_2 memory orderItem2, string memory name2, string memory symbol2, uint256 decimals2, uint256 price2, string memory nftName, string memory nftSymbol){
        orderItem1 = OrderDetail1;
        orderItem2 = OrderDetail2;
        if (orderItem1.erc20Token == address(0)) {
            name2 = ETH.name();
            symbol2 = ETH.symbol();
            decimals2 = ETH.decimals();
        } else {
            name2 = IERC20(orderItem1.erc20Token).name();
            symbol2 = IERC20(orderItem1.erc20Token).symbol();
            decimals2 = IERC20(orderItem1.erc20Token).decimals();
        }
        price2 = orderItem1.price.mul(1e18).div(10 ** decimals2);
        nftName = orderItem1.nftToken.name();
        nftSymbol = orderItem1.nftToken.symbol();
    }

    function getUserIdoTokenIdList(address _address) public view returns (uint256[] memory) {
        return UserIgoTokenIdList[_address];
    }

    struct nftInfo {
        string name;
        string symbol;
        string tokenURI;
        address ownerOf;
        tokenIdInfo statusList;
    }

    function getNftInfo(IERC721Enumerable _nftToken, uint256 _tokenId) public view returns (nftInfo memory nftInfo2) {
        nftInfo2 = nftInfo(_nftToken.name(), _nftToken.symbol(), _nftToken.tokenURI(_tokenId), _nftToken.ownerOf(_tokenId), TokenIdSwapStatusStatusList[_tokenId]);
    }

    function massGetNftInfo(IERC721Enumerable _nftToken, uint256[] memory _tokenIdList) public view returns (nftInfo[] memory nftInfolist2) {
        nftInfolist2 = new nftInfo[](_tokenIdList.length);
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            nftInfolist2[i] = getNftInfo(_nftToken, _tokenIdList[i]);
        }
    }

    receive() payable external {}
}

contract IGOPoolFactory is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    mapping(uint256 => IGOPool) public orderItemInfo;
    IERC20 public ETH;
    address public devAddress;
    mapping(IERC721Enumerable => uint256[]) public nftAddressOrderList;
    mapping(uint256 => bool) public orderStatusList;
    mapping(address => uint256[]) public userOrderList;
    mapping(string => bool) public orderMd5StatusList;
    uint256 public orderNum = 0;
    mapping(address => bool) public erc20tokenWhiteList;
    mapping(address => bool) public igoWhiteList;

    event createIgoEvent(address _devAddress, address _owner, IERC20 _ETH, uint256 _orderId, IERC721Enumerable _nftToken, uint256 _igoAmount, address _erc20Token, uint256 _price, string _orderMd5, uint256 _startBlock, uint256 _endBlock);
    event createIgoEvent2(IGOPool igoItem);
    constructor(IERC20 _ETH, address _devAddress) public {
        ETH = _ETH;
        devAddress = _devAddress;
        addIgoWhiteList(msg.sender);
        addErc20tokenWhiteList(address(0));
    }

    function addErc20tokenWhiteList(address _addreess) public onlyOwner {
        erc20tokenWhiteList[_addreess] = true;
    }

    function removeErc20tokenWhiteList(address _addreess) public onlyOwner {
        erc20tokenWhiteList[_addreess] = false;
    }

    function addIgoWhiteList(address _addreess) public onlyOwner {
        igoWhiteList[_addreess] = true;
    }

    function removeIgoWhiteList(address _addreess) public onlyOwner {
        igoWhiteList[_addreess] = false;
    }

    function createIGO(IERC721Enumerable _nftToken, uint256 _igoAmount, address _erc20Token, uint256 _price, string memory _orderMd5, uint256 _startBlock, uint256 _endBlock) public {
        require(igoWhiteList[msg.sender] == true, "e002");
        require(orderMd5StatusList[_orderMd5] == false, "e003");
        require(erc20tokenWhiteList[_erc20Token] == true, "e004");
        IGOPool igoitem = new IGOPool(devAddress, msg.sender, ETH, orderNum, _nftToken, _igoAmount, _erc20Token, _price, _orderMd5, _startBlock, _endBlock);
        emit createIgoEvent(devAddress, msg.sender, ETH, orderNum, _nftToken, _igoAmount, _erc20Token, _price, _orderMd5, _startBlock, _endBlock);
        emit createIgoEvent2(igoitem);
        orderItemInfo[orderNum] = igoitem;
        nftAddressOrderList[_nftToken].push(orderNum);
        orderStatusList[orderNum] = true;
        userOrderList[msg.sender].push(orderNum);
        orderNum = orderNum.add(1);
        orderMd5StatusList[_orderMd5] = true;
        igoitem.transferOwnership(msg.sender);
    }

    function setDevAddress(IGOPool _igoItem, address payable _devAddress) public onlyOwner {
        _igoItem.setDevAddress(_devAddress);
    }

    function setSwapFee(IGOPool _igoItem, uint256 _fee) public onlyOwner {
        _igoItem.setSwapFee(_fee);
    }

    function massSetSwapFee(uint256[] memory _igoItem_list, uint256 _fee) public onlyOwner {
        for (uint256 i = 0; i < _igoItem_list.length; i++) {
            orderItemInfo[i].setSwapFee(_fee);
        }
    }

    function massSetDevAddress(uint256[] memory _igoItem_list, address payable _devAddress) public onlyOwner {
        for (uint256 i = 0; i < _igoItem_list.length; i++) {
            orderItemInfo[i].setDevAddress(_devAddress);
        }
    }

    struct tokenIdInfo {
        uint256 poolId;
        bool mintStatus;
        bool buybackStatus;
        bool swapStatus;
    }

    struct tokenIdInfoList {
        tokenIdInfo[] tokenIdInfoListItem;
    }

    function getTokenIdStatusList(IERC721Enumerable _nftToken, uint256 _tokenId) public view returns (tokenIdInfo[] memory) {
        uint256[] memory index_list = nftAddressOrderList[_nftToken];
        tokenIdInfo[] memory x = new tokenIdInfo[](index_list.length);
        for (uint256 i = 0; i < index_list.length; i++) {
            (bool mintStatus,bool buybackStatus,bool swapStatus) = orderItemInfo[index_list[i]].TokenIdSwapStatusStatusList(_tokenId);
            x[i] = tokenIdInfo(index_list[i], mintStatus, buybackStatus, swapStatus);
        }
        return x;
    }

    function massGetTokenIdStatusList(IERC721Enumerable _nftToken, uint256[] memory _tokenIdList) public view returns (tokenIdInfoList[] memory x) {
        x = new tokenIdInfoList[](_tokenIdList.length);
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            x[i] = tokenIdInfoList(getTokenIdStatusList(_nftToken, _tokenIdList[i]));
        }
        return x;
    }

    struct orderItem_1 {
        uint256 orderId;
        address payable owner;
        IERC721Enumerable nftToken;
        uint256 igoAmount;
        address erc20Token;
        uint256 price;
        bool orderStatus;
        string orderMd5;
        uint256 hasigoAmount;
        uint256 startBlock;
        uint256 endBlock;
    }

    struct orderItem_2 {
        IERC20 swapToken;
        uint256 swapPrice;
        uint256 GetRewardBlockNum;
        uint256 BuyBackNum;
        uint256 swapFee;
        uint256 maxIgoAmount;
    }

    struct orderItem_3 {
        orderItem_1 x1;
        orderItem_2 x2;
        string name2;
        string symbol2;
        uint256 decimals2;
        uint256 price2;
        string nftName;
        string nftSymbol;
        IGOPool igoAddress;
    }

    function get(uint256 _index) public view returns (orderItem_3 memory returnIgoInfo) {
        returnIgoInfo.igoAddress = orderItemInfo[_index];
        {
            (uint256 orderId,
            address payable owner,
            IERC721Enumerable nftToken,
            uint256 igoAmount,
            address erc20Token,
            uint256 price,
            bool orderStatus,
            string memory orderMd5,
            uint256 hasigoAmount,
            uint256 startBlock,
            uint256 endBlock) = orderItemInfo[_index].OrderDetail1();
            returnIgoInfo.x1 = orderItem_1(orderId, owner, nftToken, igoAmount, erc20Token, price, orderStatus, orderMd5, hasigoAmount, startBlock, endBlock);
        }
        {
            (IERC20 swapToken,
            uint256 swapPrice,
            uint256 GetRewardBlockNum,
            uint256 BuyBackNum,
            uint256 swapFee,
            uint256 maxIgoAmount) = orderItemInfo[_index].OrderDetail2();
            returnIgoInfo.x2 = orderItem_2(swapToken, swapPrice, GetRewardBlockNum, BuyBackNum, swapFee, maxIgoAmount);
        }
        {
            (,,string memory name2, string memory symbol2, uint256 decimals2, uint256 price2,string memory nftName,string memory nftSymbol) = orderItemInfo[_index].getTokenInfoByIndex();
            returnIgoInfo.name2 = name2;
            returnIgoInfo.symbol2 = symbol2;
            returnIgoInfo.decimals2 = decimals2;
            returnIgoInfo.price2 = price2;
            returnIgoInfo.nftName = nftName;
            returnIgoInfo.nftSymbol = nftSymbol;
        }
    }

    function mass_get(uint256[] memory index_list) public view returns (orderItem_3[] memory returnIgoInfoList) {
        returnIgoInfoList = new orderItem_3[](index_list.length);
        for (uint256 i = 0; i < index_list.length; i++) {
            returnIgoInfoList[i] = get(index_list[i]);
        }
    }

    function getWrongTokens(IERC20 _token) public onlyOwner {
        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "e016");
        _token.safeTransfer(msg.sender, amount);
    }

    function cleanEth() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    receive() payable external {}
}