/**
 *Submitted for verification at hecoinfo.com on 2022-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;


// interface IERC721Receiver {
//     function onERC721Received(
//         address operator,
//         address from,
//         uint256 tokenId,
//         bytes calldata data
//     ) external returns (bytes4);
// }

// interface IERC721Enumerable {
//     function transferFrom(
//         address from,
//         address to,
//         uint256 tokenId
//     ) external;

//     function ownerOf(uint256 tokenId) external view returns (address owner);

//     function name() external view returns (string memory);

//     function symbol() external view returns (string memory);

//     function tokenURI(uint256 tokenId) external view returns (string memory);

//     function mintForMiner(address _to) external returns (bool, uint256);

//     function MinerList(address _address) external returns (bool);

//     function safeMintFromMap( address to, uint256 tokenType, string[] memory params) external;
//     function balanceOf(address owner) external view returns (uint256 balance);
//     function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
// }

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
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


// contract MassTransferFrom is Ownable,IERC721Receiver {
contract MassTransferFrom is Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    uint256 public fee = 0.05 * (10 ** 18);
    IERC20 public USDT;
    IERC20 public ETH;
    // address public teamAddress;
    // address public devAddress;
    mapping(address=>bool) public whiteList;

    constructor () public {
        // devAddress = msg.sender;
        // teamAddress = _teamAddress;
        whiteList[msg.sender] = true;
        // whiteList[_teamAddress] = true;
    }
    
    function  addWhiteList(address _address) external  onlyOwner {
        whiteList[_address] = true;
    } 
    
    function  removeWhiteList(address _address) external  onlyOwner {
        whiteList[_address] = false;
    } 
    
    // function setFee(uint256 _fee) external onlyOwner {
    //     fee = _fee * (10 ** 16);
    // }

    // function setTeamAddress(address _teamAddress) external onlyOwner {
    //     teamAddress = _teamAddress;
    // }

    // function setDevAddress(address _devAddress) external onlyOwner {
    //     devAddress = _devAddress;
    // }

    // function massSendToken(address[] memory _address_list, IERC20 _token, uint256 _amount_token) external payable {
    //     require(msg.value == fee, "e0");
    //     require(_amount_token > 0, "e1");
    //     if (!whiteList[msg.sender]) {
    //     uint256 devFee = fee.mul(50).div(100);
    //     uint256 teamFee = fee.sub(devFee);
    //     payable(devAddress).transfer(devFee);
    //     payable(teamAddress).transfer(teamFee);
    //     } else {
    //       payable(msg.sender).transfer(msg.value);
    //     }
    //     uint256 addressNum = _address_list.length;
    //     require(_token.balanceOf(msg.sender) >= addressNum.mul(_amount_token), "e2");
    //     for (uint256 i = 0; i < addressNum; i++) {
    //         if (_amount_token > 0) {
    //             _token.safeTransferFrom(msg.sender, _address_list[i], _amount_token);
    //         }
    //     }
    // }

    // function massSendTokenPlus(address[] memory _address_list, IERC20 _token, uint256 _amount_token) external payable {
    //     require(msg.value == fee, "e0");
    //     require(_amount_token > 0, "e1");
    //     uint256 devFee = fee.mul(50).div(100);
    //     uint256 teamFee = fee.sub(devFee);
    //     payable(devAddress).transfer(devFee);
    //     payable(teamAddress).transfer(teamFee);
    //     uint256 tokenAmount = _amount_token.mul(10 ** _token.decimals());
    //     uint256 addressNum = _address_list.length;
    //     require(_token.balanceOf(msg.sender) >= addressNum.mul(tokenAmount), "e2");
    //     for (uint256 i = 0; i < addressNum; i++) {
    //         if (_amount_token > 0) {
    //             _token.safeTransferFrom(msg.sender, _address_list[i], tokenAmount);
    //         }
    //     }
    // }
    
    
    function massSendTokenPlus(address[] memory _address_list, IERC20 _token, uint256 _amount_token) external {
        require(_amount_token > 0, "e1");
        uint256 addressNum = _address_list.length;
        require(_token.balanceOf(msg.sender) >= addressNum.mul(_amount_token), "e2");
        for (uint256 i = 0; i < addressNum; i++) {
            if (_amount_token > 0) {
                _token.safeTransferFrom(msg.sender, _address_list[i], _amount_token);
            }
        }
    }
    
    function massSendGasPlus(address[] memory _address_list,uint256 _gas_amount) external payable {
        require(msg.value == _address_list.length.mul(_gas_amount),"e1");
        for (uint256 i=0;i<_address_list.length;i++) {
            payable(_address_list[i]).transfer(_gas_amount);
        }
    }

    function takeETH() external onlyOwner returns (bool){
        require(address(this).balance > 0);
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }

    function takeErc20Token(IERC20 _token) external onlyOwner returns (bool){
        require(_token.balanceOf(address(this)) > 0);
        _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
        return true;
    }

    receive() payable external {}
}