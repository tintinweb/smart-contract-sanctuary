/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "t001");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "t002");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "t003");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
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

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "m001");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "t006");
        require(isContract(target), "t007");

        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
        require(c >= a, "t010");
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "t012");
        return c;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "t013"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "m007");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "t014");
        }
    }
}

interface IERC721 {
    function balanceOf(address account) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract ClaimErc20 is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    uint256 RewardNum = 5000;
    bool public canClaimErc20 = false;
    mapping(uint256 => bool) public hasClaimStatus;
    IERC20 public RewardAddress = IERC20(0xd947773b93455e3D97fCb8D4A030C5D0D8F3b278);
    IERC721 public NftAddress = IERC721(0xb840EC0DB3b9ab7b920710D6fc21A9D206f994Aa);

    function setRewardNum(uint256 _RewardNum) public onlyOwner {
        RewardNum = _RewardNum;
    }

    function setRewardAddress(IERC20 _RewardAddress) public onlyOwner {
        RewardAddress = _RewardAddress;
    }

    function setNftAddress(IERC721 _NftAddress) public onlyOwner {
        NftAddress = _NftAddress;
    }

    function enableCanClaimErc20() public onlyOwner {
        canClaimErc20 = true;
    }

    function disableCanClaimErc20() public onlyOwner {
        canClaimErc20 = false;
    }

    function claimErc20Token() public {
        uint256 num = NftAddress.balanceOf(msg.sender);
        require(num > 0, "t015");
        require(canClaimErc20 == true, "t016");
        uint256 num2 = 0;
        for (uint256 i = 0; i < num; i++) {
            uint256 _tokenID = NftAddress.tokenOfOwnerByIndex(msg.sender, i);
            if (hasClaimStatus[_tokenID] == false) {
                num2 = num2.add(1);
                hasClaimStatus[_tokenID] = true;
            }
        }
        require(num2 > 0, "t017");
        uint256 reward_num = RewardNum.mul(num2).mul(10 ** RewardAddress.decimals());
        RewardAddress.safeApprove(address(this), reward_num);
        RewardAddress.safeTransferFrom(address(this), msg.sender, reward_num);
    }

    function getClaimErc20TokenNum(address _user) public view returns (uint256){
        uint256 num = NftAddress.balanceOf(_user);
        if (num == 0 || canClaimErc20 == false) {
            return 0;
        }
        uint256 num2 = 0;
        for (uint256 i = 0; i < num; i++) {
            uint256 _tokenID = NftAddress.tokenOfOwnerByIndex(_user, i);
            if (hasClaimStatus[_tokenID] == false) {
                num2 = num2.add(1);
            }
        }
        return num2;
    }

    function getErc20Token(IERC20 _token) public onlyOwner {
        _token.safeApprove(address(this), _token.balanceOf(address(this)));
        _token.safeTransferFrom(address(this), msg.sender, _token.balanceOf(address(this)));
    }
}