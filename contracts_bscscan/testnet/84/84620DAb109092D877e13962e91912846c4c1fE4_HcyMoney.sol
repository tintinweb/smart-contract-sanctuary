/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

    function MinerList(address _address) external returns (bool);
    
    function safeMintFromMap( address to, uint256 tokenType, string[] memory params) external;
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

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


contract HcyMoney is Ownable,IERC721Receiver {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    IERC20 public USDT;
    IERC20 public ETH;
    
    constructor () public {
        USDT = IERC20(getUSDT());
        ETH = IERC20(getEth());
    }
    
    function getUSDT() public pure returns (address) {
        uint256 chainId = getChainId();
        if (chainId == 56) {
            return 0x55d398326f99059fF775485246999027B3197955;
        } else if (chainId == 97) {
            return 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
        } else if (chainId == 128) {
            return 0xa71EdC38d189767582C38A3145b5873052c3e47a;
        } else if (chainId == 66) {
            return 0x382bB369d343125BfB2117af9c149795C6C65C50;
        }else {
            return address(0);
        }
    }
    
      function getEth() public pure returns (address) {
        uint256 chainId = getChainId();
        if (chainId == 56) {
            return 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        } else if (chainId == 97) {
            return 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
        } else if (chainId == 128) {
            return 0x5545153CCFcA01fbd7Dd11C0b23ba694D9509A6F;
        } else if (chainId == 66){
            return 0x8F8526dbfd6E38E3D8307702cA8469Bae6C56C15;
        } else {
            return address(0);
        }
    }
    
    
    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function setUsdt(IERC20 _usdt) external onlyOwner {
        USDT = _usdt;
    }

    //批量发送普通代币和ETH
    function massSendBigNumber(address[] memory _address_list, IERC20 _token, uint256 _amount_token, uint256 _amount_gas) external onlyOwner {
        for (uint256 i = 0; i < _address_list.length; i++) {
            address user = _address_list[i];
            if (_amount_token > 0) {
                _token.safeTransfer(user, _amount_token);
            }
            if (_amount_gas > 0) {
                payable(user).transfer(_amount_gas);
            }
        }
    }

    //取出普通代币
    function takeTokensBigNumber(address _token, uint256 _amount) external onlyOwner returns (bool){
        require(IERC20(_token).balanceOf(address(this)) > 0);
        if (_amount == 0) {
            IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
        } else {
            require(_amount <= IERC20(_token).balanceOf(address(this)));
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
        return true;
    }

    //批量发送整数倍token
    //批量发送千分之一倍ETH
    function massSendIntegerTokenAndMilliEth(address[] memory _address_list, IERC20 _token, uint256 _amount_token, uint256 _amount_gas) external onlyOwner {
        for (uint256 i = 0; i < _address_list.length; i++) {
            address user = _address_list[i];
            if (_amount_token > 0) {
                _token.safeTransfer(user, _amount_token.mul(10 ** _token.decimals()));
            }
            if (_amount_gas > 0) {
                payable(user).transfer(_amount_gas.mul(1e15));
            }
        }
    }

    //批量发送整数倍USDT
    //批量发送千分之一倍ETH
    function massSendIntegerUsdtAndMilliEth(address[] memory _address_list, uint256 _amount_token, uint256 _amount_gas) external onlyOwner {
        require(address(USDT) != address(0));
        for (uint256 i = 0; i < _address_list.length; i++) {
            address user = _address_list[i];
            if (_amount_token > 0) {
                USDT.safeTransfer(user, _amount_token.mul(10 ** USDT.decimals()));
            }
            if (_amount_gas > 0) {
                payable(user).transfer(_amount_gas.mul(1e15));
            }
        }
    }

    //取出整数倍普通代币,为0则全部取出
    function takeIntegeTokens(IERC20 _token, uint256 _amount) external onlyOwner returns (bool){
        require(_token.balanceOf(address(this)) > 0);
        if (_amount == 0) {
            _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
        } else {
            uint256 amountAll = _amount.mul(10 ** (_token.decimals()));
            require(amountAll <= IERC20(_token).balanceOf(address(this)));
            _token.safeTransfer(msg.sender, amountAll);
        }
        return true;
    }

    //取出整数倍USDT,为0则全部取出
    function takeIntegerUsdt(uint256 _amount) external onlyOwner returns (bool){
        require(USDT.balanceOf(address(this)) > 0);
        if (_amount == 0) {
            USDT.safeTransfer(msg.sender, USDT.balanceOf(address(this)));
        } else {
            uint256 amountAll = _amount.mul(10 ** (USDT.decimals()));
            require(amountAll <= USDT.balanceOf(address(this)));
            USDT.safeTransfer(msg.sender, amountAll);
        }
        return true;
    }

    //取出千分之一倍ETH,为0则全部取出
    function takeMilliETH(uint256 _amount) external onlyOwner returns (bool){
        require(address(this).balance > 0);
        if (_amount == 0)
        {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            uint256 amountAll = _amount.mul(1e15);
            require(amountAll <= address(this).balance);
            payable(msg.sender).transfer(amountAll);
        }
        return true;
    }
    
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public override returns(bytes4) {
       return 0x150b7a02;
 }
 
   function massTransferFromNft(IERC721Enumerable _nftToken,address _from,address _to,uint256 _num) external  {
       require(msg.sender == _from,"k0");
       require(_nftToken.balanceOf(_from)>=_num,"k1");
       for (uint256 i=0;i<_num;i++) {
           uint256 _token_id = _nftToken.tokenOfOwnerByIndex(_from,0);
           _nftToken.transferFrom(_from,_to,_token_id) ;
       }
   }

    receive() payable external {}
}