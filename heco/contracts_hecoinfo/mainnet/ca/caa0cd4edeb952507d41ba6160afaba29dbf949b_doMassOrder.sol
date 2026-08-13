/**
 *Submitted for verification at hecoinfo.com on 2022-06-01
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
    
    function approve(address spender, uint256 amount) external;
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

interface structK {
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
}


interface NftMarket is structK {
    function swap(uint256 _orderId) external;
    function swapWithEth(uint256 _orderId) external payable;
    function orderItemInfo(uint256 _orderId) external view returns(orderItem memory);
    
}


contract doMassOrder is Ownable, ReentrancyGuard,structK {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    address payable public marketAddress = 0x616c86f45F2a98a51b3Ba9153cf8Cf61c26c3DDC; 
    
    function doAction(uint256[] memory orderIdList,IERC721Enumerable[] memory nftTokenList,uint256[] memory tokenIdList,address[] memory erc20TokenList,uint256[] memory priceList) external payable  {
        uint256 gas0  = msg.value;
        uint256 gasUsed = 0;
        for (uint256 i =0;i<orderIdList.length;i++) {
            uint256 orderId = orderIdList[i];
            IERC721Enumerable nftToken = nftTokenList[i];
            uint256 tokenId = tokenIdList[i];
            address erc20Token = erc20TokenList[i];
            uint256 price = priceList[i];
            if (erc20Token == address(0)) {
            NftMarket(marketAddress).swapWithEth{value : price}(orderId);
            nftToken.transferFrom(address(this),msg.sender,tokenId);
            gasUsed = gasUsed.add(price);
            }
            else  {
            IERC20(erc20Token).approve(marketAddress,price);
            IERC20(erc20Token).transferFrom(msg.sender,address(0),price);
            NftMarket(marketAddress).swap(orderId);
            nftToken.transferFrom(address(this),msg.sender,tokenId);
            }
        }
        uint256 gasLeft = gas0.sub(gasUsed);
        if (gasLeft>0) {
            payable(msg.sender).transfer(gasLeft);
        }
    }
    
     receive() payable external {}
}