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
        require(_status != _ENTERED, "e0");
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
        require(isContract(target), "e0");
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
        require(c >= a, "add e0");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "sub e0");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "mul e0");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div e0");
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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}


contract nftOrderPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    address payable public devAddress;
    IERC20 public ETH;
    uint256 public orderNum = 0;
    uint256 public swapFee = 10;

    struct orderItem {
        uint256 orderId;
        address payable owner;
        IERC721Enumerable nftToken;
        uint256 tokenId;
        address erc20Token;
        uint256 price;
        bool orderStatus;
        string orderMd5;
        uint256 time;
        uint256 blocokNum;
        string name;
        string symbol;
        string tokenURI;
    }

    struct massInfoItem {
        orderItem orderItem2;
        string name2;
        string symbol2;
        uint256 decimals2;
        uint256 price2;
        string tokenURI2;
    }

    mapping(uint256 => orderItem) public orderItemInfo;
    mapping(IERC721Enumerable => uint256[]) public nftAddressOrderList;
    mapping(uint256 => bool) public orderStatusList;
    mapping(address => uint256[]) public userOrderList;
    mapping(string => bool) public orderMd5StatusList;
    mapping(string => uint256) public orderMd5List;
    mapping(IERC721Enumerable => mapping(uint256 => uint256)) public nftTokenLastOrderIdList;

    event createNftOrderEvent(uint256 orderId, address owner, IERC721Enumerable nftToken, uint256 tokenId, address erc20Token, uint256 price, bool orderStatus, string orderMd5, uint256 time, uint256 blocokNum);
    event widthDrawEvent(uint256 _orderId, address owner, IERC721Enumerable nftToken, uint256 tokenId);
    event swapEvent(uint256 _orderId, IERC721Enumerable nftToken, uint256 tokenId, address erc20Token, address owner, address buyer, uint256 price, uint256 fee, uint256 toUser);

    constructor(IERC20 _ETH) public {
        devAddress = msg.sender;
        ETH = _ETH;
    }

    function setDevAddress(address payable _devAddress) public {
        require(msg.sender == devAddress || msg.sender == owner(), 'p0');
        devAddress = _devAddress;
    }

    function setSwapFee(uint256 _fee) public onlyOwner {
        swapFee = _fee;
    }

    function getTokenIdSaleStatus(IERC721Enumerable _nftToken, uint256 _tokenId) public view returns (bool, uint256, massInfoItem memory) {
        if (nftTokenLastOrderIdList[_nftToken][_tokenId] > 0) {
            (orderItem memory orderItem2, string memory name2, string memory symbol2, uint256 decimals2, uint256 price2,string memory tokenURI2) = getTokenInfoByIndex(nftTokenLastOrderIdList[_nftToken][_tokenId]);
            return (orderItemInfo[nftTokenLastOrderIdList[_nftToken][_tokenId]].orderStatus, nftTokenLastOrderIdList[_nftToken][_tokenId], massInfoItem(orderItem2, name2, symbol2, decimals2, price2, tokenURI2));
        } else {
            (orderItem memory orderItem2, string memory name2, string memory symbol2, uint256 decimals2, uint256 price2,string memory tokenURI2) = getTokenInfoByIndex(0);
            if (orderItemInfo[nftTokenLastOrderIdList[_nftToken][_tokenId]].nftToken == _nftToken && orderItemInfo[nftTokenLastOrderIdList[_nftToken][_tokenId]].tokenId == _tokenId) {
                return (orderItemInfo[nftTokenLastOrderIdList[_nftToken][_tokenId]].orderStatus, nftTokenLastOrderIdList[_nftToken][_tokenId], massInfoItem(orderItem2, name2, symbol2, decimals2, price2, tokenURI2));
            } else {
                return (false, 0, massInfoItem(orderItem2, name2, symbol2, decimals2, price2, tokenURI2));
            }
        }
    }

    function createNftOrder(IERC721Enumerable _nftToken, uint256 _tokenId, address _erc20Token, uint256 _price, string memory _orderMd5, uint256 _time) public nonReentrant {
        require(orderMd5StatusList[_orderMd5] == false, 'm0');
        _nftToken.transferFrom(msg.sender, address(this), _tokenId);
        orderItemInfo[orderNum] = orderItem(orderNum, msg.sender, _nftToken, _tokenId, _erc20Token, _price, true, _orderMd5, _time, block.number, _nftToken.name(), _nftToken.symbol(), _nftToken.tokenURI(_tokenId));
        emit createNftOrderEvent(orderNum, msg.sender, _nftToken, _tokenId, _erc20Token, _price, true, _orderMd5, _time, block.number);
        nftAddressOrderList[_nftToken].push(orderNum);
        orderStatusList[orderNum] = true;
        orderMd5List[_orderMd5] = orderNum;
        userOrderList[msg.sender].push(orderNum);
        nftTokenLastOrderIdList[_nftToken][_tokenId] = orderNum;
        orderNum = orderNum.add(1);
        orderMd5StatusList[_orderMd5] = true;
    }

    function createNftOrderWithEth(IERC721Enumerable _nftToken, uint256 _tokenId, uint256 _price, string memory _orderMd5, uint256 _time) public nonReentrant {
        require(orderMd5StatusList[_orderMd5] == false, 'm0');
        _nftToken.transferFrom(msg.sender, address(this), _tokenId);
        orderItemInfo[orderNum] = orderItem(orderNum, msg.sender, _nftToken, _tokenId, address(0), _price, true, _orderMd5, _time, block.number, _nftToken.name(), _nftToken.symbol(), _nftToken.tokenURI(_tokenId));
        emit createNftOrderEvent(orderNum, msg.sender, _nftToken, _tokenId, address(0), _price, true, _orderMd5, _time, block.number);
        nftAddressOrderList[_nftToken].push(orderNum);
        orderStatusList[orderNum] = true;
        orderMd5List[_orderMd5] = orderNum;
        userOrderList[msg.sender].push(orderNum);
        nftTokenLastOrderIdList[_nftToken][_tokenId] = orderNum;
        orderNum = orderNum.add(1);
        orderMd5StatusList[_orderMd5] = true;
    }

    function widthDraw(uint256 _orderId) public nonReentrant {
        require(orderStatusList[_orderId] == true, 'f0');
        require(orderItemInfo[_orderId].owner == msg.sender, 'f1');
        orderItemInfo[_orderId].nftToken.transferFrom(address(this), msg.sender, orderItemInfo[_orderId].tokenId);
        orderItemInfo[_orderId].orderStatus = false;
        orderStatusList[_orderId] = false;
        emit widthDrawEvent(_orderId, msg.sender, orderItemInfo[_orderId].nftToken, orderItemInfo[_orderId].tokenId);
    }

    function swap(uint256 _orderId) public nonReentrant {
        require(orderStatusList[_orderId] == true, 'k0');
        //orderItem memory _orderItem = orderItemInfo[_orderId];
        require(IERC20(orderItemInfo[_orderId].erc20Token).balanceOf(msg.sender) >= orderItemInfo[_orderId].price, 'k1');
        uint256 fee = orderItemInfo[_orderId].price.mul(swapFee).div(100);
        uint256 toUser = orderItemInfo[_orderId].price.sub(fee);
        IERC20(orderItemInfo[_orderId].erc20Token).safeTransferFrom(msg.sender, orderItemInfo[_orderId].owner, toUser);
        IERC20(orderItemInfo[_orderId].erc20Token).safeTransferFrom(msg.sender, devAddress, fee);
        orderItemInfo[_orderId].nftToken.transferFrom(address(this), msg.sender, orderItemInfo[_orderId].tokenId);
        orderStatusList[_orderId] = false;
        orderItemInfo[_orderId].orderStatus = false;
        emit swapEvent(_orderId, orderItemInfo[_orderId].nftToken, orderItemInfo[_orderId].tokenId, orderItemInfo[_orderId].erc20Token, orderItemInfo[_orderId].owner, msg.sender, orderItemInfo[_orderId].price, fee, toUser);
    }

    function swapWithEth(uint256 _orderId) public payable nonReentrant {
        require(orderStatusList[_orderId] == true, 'k0');
        require(msg.value >= orderItemInfo[_orderId].price, 'k1');
        uint256 fee = orderItemInfo[_orderId].price.mul(swapFee).div(100);
        uint256 toUser = orderItemInfo[_orderId].price.sub(fee);
        orderItemInfo[_orderId].owner.transfer(toUser);
        devAddress.transfer(fee);
        orderItemInfo[_orderId].nftToken.transferFrom(address(this), msg.sender, orderItemInfo[_orderId].tokenId);
        orderStatusList[_orderId] = false;
        orderItemInfo[_orderId].orderStatus = false;
        emit swapEvent(_orderId, orderItemInfo[_orderId].nftToken, orderItemInfo[_orderId].tokenId, orderItemInfo[_orderId].erc20Token, orderItemInfo[_orderId].owner, msg.sender, orderItemInfo[_orderId].price, fee, toUser);
    }

    function getWrongTokens(IERC20 _token) public onlyOwner {
        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, 'e1');
        _token.safeTransfer(msg.sender, amount);
    }

    function getStatusOkInfoList(uint256[] memory _orderIdList) public view returns (massInfoItem[] memory) {
        uint256 okNum = 0;
        for (uint256 i = 0; i < _orderIdList.length; i++) {
            if (orderItemInfo[_orderIdList[i]].orderStatus == true) {
                okNum = okNum.add(1);
            }
        }
        uint256 k = 0;
        massInfoItem[] memory x = new massInfoItem[](okNum);
        for (uint256 i = 0; i < _orderIdList.length; i++) {
            if (orderItemInfo[_orderIdList[i]].orderStatus == true) {
                (orderItem memory orderItem2, string memory name2, string memory symbol2, uint256 decimals2, uint256 price2,string memory tokenURI2) = getTokenInfoByIndex(_orderIdList[i]);
                x[k] = massInfoItem(orderItem2, name2, symbol2, decimals2, price2, tokenURI2);
                k = k.add(1);
            }
        }
        return x;
    }

    function getStatusOkIdList(uint256[] memory _orderIdList) public view returns (uint256[] memory) {
        uint256 okNum = 0;
        for (uint256 i = 0; i < _orderIdList.length; i++) {
            if (orderItemInfo[_orderIdList[i]].orderStatus == true) {
                okNum = okNum.add(1);
            }
        }
        uint256 k = 0;
        uint256[] memory x = new uint256[](okNum);
        for (uint256 i = 0; i < _orderIdList.length; i++) {
            if (orderItemInfo[_orderIdList[i]].orderStatus == true) {
                x[k] = _orderIdList[i];
                k = k.add(1);
            }
        }
        return x;
    }

    function getTokenInfoByIndex(uint256 index) public view returns (orderItem memory orderItem2, string memory name2, string memory symbol2, uint256 decimals2, uint256 price2, string memory tokenURI2){
        orderItem2 = orderItemInfo[index];
        if (orderItem2.erc20Token == address(0)) {
            name2 = ETH.name();
            symbol2 = ETH.symbol();
            decimals2 = ETH.decimals();
        } else {
            name2 = IERC20(orderItem2.erc20Token).name();
            symbol2 = IERC20(orderItem2.erc20Token).symbol();
            decimals2 = IERC20(orderItem2.erc20Token).decimals();
        }
        price2 = orderItem2.price.mul(1e18).div(10 ** decimals2);
        tokenURI2 = orderItem2.nftToken.tokenURI(orderItem2.tokenId);
    }

    function getTokenInfoByOrderMd5(string memory _orderMd5) public view returns (orderItem memory orderItem2, string memory name2, string memory symbol2, uint256 decimals2, uint256 price2){
        orderItem2 = orderItemInfo[orderMd5List[_orderMd5]];
        if (orderItem2.erc20Token == address(0)) {
            name2 = ETH.name();
            symbol2 = ETH.symbol();
            decimals2 = ETH.decimals();
        } else {
            name2 = IERC20(orderItem2.erc20Token).name();
            symbol2 = IERC20(orderItem2.erc20Token).symbol();
            decimals2 = IERC20(orderItem2.erc20Token).decimals();
        }
        price2 = orderItem2.price.mul(1e18).div(10 ** decimals2);
    }

    function getUserOkOrderIdList(address _user) public view returns (uint256[] memory) {
        uint256[] memory userOrderIdList = userOrderList[_user];
        uint256[] memory userOkOrderIdList = getStatusOkIdList(userOrderIdList);
        return userOkOrderIdList;
    }

    function getUserOkOrderInfoList(address _user) public view returns (massInfoItem[] memory) {
        uint256[] memory userOrderIdList = userOrderList[_user];
        massInfoItem[] memory userOkOrderIdList = getStatusOkInfoList(userOrderIdList);
        return userOkOrderIdList;
    }
}