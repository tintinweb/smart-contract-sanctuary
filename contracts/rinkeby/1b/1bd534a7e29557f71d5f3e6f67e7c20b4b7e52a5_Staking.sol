/**
 *Submitted for verification at Etherscan.io on 2021-10-13
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

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "t004");

        (bool success,) = recipient.call{value : amount}("");
        require(success, "t005");
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
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "m002");
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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "m003");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "t008");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "m004");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "t009");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

interface IERC721Enumerable {
    function balanceOf(address account) external view returns (uint256);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "t010");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "t011");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }


    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "t013"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "m006");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "m007");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "t014");
        }
    }
}


interface Chao {
    function claim(address _to, uint256 _num, uint256 _poolId, uint256 _randNum, uint256 _minNum, uint256 _MaxNum) external;
}

contract Staking is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    uint256 private PoolIdNow = 0;
    mapping(address => mapping(uint256 => uint256)) public staking_num;
    mapping(address => mapping(uint256 => uint256[])) public staking_token_id;
    mapping(uint256 => mapping(uint256 => bool)) private staking_token_id_status;
    mapping(address => mapping(uint256 => uint256)) public staking_time;
    mapping(uint256 => PoolInfo) public PoolInfoList;
    IERC721Enumerable public stakingNftAddress;
    IERC20 public RewardAddress;
    Chao public RewardNft;

    struct PoolInfo {
        uint256 poolId;
        bool canStakeNft;
        uint256 stakingLength;
        uint256 RandTotal;
        uint256 RandMin;
        uint256 RandMax;
        uint256 RewardNum;
    }

    // event widthdrawNftEvent(address _user, uint _tokenId, uint rand_num);
    // _RandTotal:800; _RandMin:200;_RandMax:600;
    function addPool(uint256 _stakingLength, uint256 _RandTotal, uint256 _RandMin, uint256 _RandMax, uint256 _RewardNum) public onlyOwner {
        require(_RandTotal >= _RandMin && _RandTotal >= _RandMin && _RandMax > _RandMin, "t015");
        PoolIdNow = PoolIdNow.add(1);
        PoolInfoList[PoolIdNow] = PoolInfo(PoolIdNow, true, _stakingLength, _RandTotal, _RandMin, _RandMax, _RewardNum);
    }

    function updatePool(uint256 _poolId, bool canStakeNft, uint256 _stakingLength, uint256 _RandTotal, uint256 _RandMin, uint256 _RandMax, uint256 _RewardNum) public onlyOwner {
        require(_RandTotal >= _RandMin && _RandTotal >= _RandMin && _RandMax > _RandMin, "t016");
        PoolInfoList[_poolId] = PoolInfo(PoolIdNow, canStakeNft, _stakingLength, _RandTotal, _RandMin, _RandMax, _RewardNum);
    }

    function enableCanStakeNft(uint256 _poolId) public onlyOwner {
        require(PoolInfoList[_poolId].canStakeNft == false && PoolInfoList[_poolId].RewardNum > 0, "t017");
        PoolInfoList[_poolId].canStakeNft = true;
    }

    function disableCanStakeNft(uint256 _poolId) public onlyOwner {
        require(PoolInfoList[_poolId].canStakeNft == true && PoolInfoList[_poolId].RewardNum > 0, "t018");
        PoolInfoList[_poolId].canStakeNft = false;
    }

    // function setStakingNftAddress(IERC721Enumerable stakingNftAddress_) public onlyOwner {
    //     stakingNftAddress = stakingNftAddress_;
    // }

    // function setRewardAddress(IERC20 RewardAddress_) public onlyOwner {
    //     RewardAddress = RewardAddress_;
    // }

    // function setRewardNft(Chao RewardNft_) public onlyOwner {
    //     RewardNft = RewardNft_;
    // }

    function setTokens(IERC721Enumerable stakingNftAddress_, Chao RewardNft_, IERC20 RewardAddress_) public onlyOwner {
        stakingNftAddress = stakingNftAddress_;
        RewardNft = RewardNft_;
        RewardAddress = RewardAddress_;
    }

    // function setRewardAddress(IERC20 RewardAddress_) public onlyOwner {
    //     RewardAddress = RewardAddress_;
    // }

    // function setRewardNft(Chao RewardNft_) public onlyOwner {
    //     RewardNft = RewardNft_;
    // }

    function getStakeNftNum(uint256 _poolId, address _user) public view returns (uint256 num) {
        if (PoolInfoList[_poolId].canStakeNft == false)
            num = 0;
        else if (stakingNftAddress.balanceOf(_user) == 0)
            num = 0;
        else {
            uint256 num2 = stakingNftAddress.balanceOf(_user);
            for (uint256 i = 0; i < num2; i++) {
                if (staking_token_id_status[_poolId][stakingNftAddress.tokenOfOwnerByIndex(_user, i)] == false) {
                    num = num.add(1);
                }
            }
        }
    }

    function getStakeNftList(uint256 _poolId, uint256 _maxNum, address _user) internal view returns (uint256[] memory, uint256) {
        require(PoolInfoList[_poolId].canStakeNft == true, "t019");
        require(stakingNftAddress.balanceOf(_user) > 0, "t020");
        require(stakingNftAddress.isApprovedForAll(_user, address(this)), "t021");
        uint256 num = stakingNftAddress.balanceOf(_user);
        uint256 num2 = 0;
        for (uint256 i = 0; i < num; i++) {
            if (staking_token_id_status[_poolId][stakingNftAddress.tokenOfOwnerByIndex(_user, i)] == false)
            {
                num2 = num2.add(1);
            }
        }
        require(num2 > 0, "t022");
        if (num2 >= _maxNum) {
            num2 = _maxNum;
        }
        uint256[] memory num3 = new uint256[](num2);
        uint256 j = 0;
        for (uint256 i = 0; i < num; i++) {
            if (staking_token_id_status[_poolId][stakingNftAddress.tokenOfOwnerByIndex(_user, i)] == false)
            {
                if (j < num2)
                {
                    num3[j] = stakingNftAddress.tokenOfOwnerByIndex(_user, i);
                    j = j.add(1);
                }
            }
        }
        return (num3, num3.length);
    }

    function stakeNft(uint256 _poolId, uint256 _maxNum) public {
        (uint256[] memory num3,) = getStakeNftList(_poolId, _maxNum, msg.sender);
        for (uint256 i = 0; i < num3.length; i++) {
            if (staking_token_id_status[_poolId][num3[i]] == false)
            {
                staking_token_id[msg.sender][_poolId].push(num3[i]);
                stakingNftAddress.transferFrom(msg.sender, address(this), num3[i]);
                staking_token_id_status[_poolId][num3[i]] = true;
            }
        }
        staking_num[msg.sender][_poolId] = staking_num[msg.sender][_poolId] + num3.length;
        staking_time[msg.sender][_poolId] = block.number;
    }

    function rand(uint256 _length, address _address, uint256 _tokenId) internal view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _address, _tokenId)));
        return random % _length;
    }

    function widthdrawNft(uint256 _poolId) public {
        require(block.number > staking_time[msg.sender][_poolId] + PoolInfoList[_poolId].stakingLength, "t023");
        require(staking_num[msg.sender][_poolId] > 0, "t024");
        for (uint256 i = 0; i < staking_token_id[msg.sender][_poolId].length; i++) {
            stakingNftAddress.transferFrom(address(this), msg.sender, staking_token_id[msg.sender][_poolId][i]);
            uint rand_num = rand(PoolInfoList[_poolId].RandTotal, msg.sender, staking_token_id[msg.sender][_poolId][i]);
            // emit widthdrawNftEvent(msg.sender, staking_token_id[msg.sender][_poolId][i], rand_num);
            if (rand_num > PoolInfoList[_poolId].RandMin && rand_num < PoolInfoList[_poolId].RandMax) {
                RewardNft.claim(msg.sender, 1, _poolId, rand_num, PoolInfoList[_poolId].RandMin, PoolInfoList[_poolId].RandMax);
            }
        }
        uint256 reward_num = PoolInfoList[_poolId].RewardNum.mul(staking_num[msg.sender][_poolId]).mul(10 ** RewardAddress.decimals());
        RewardAddress.safeApprove(address(this), reward_num);
        RewardAddress.safeTransferFrom(address(this), msg.sender, reward_num);
        staking_num[msg.sender][_poolId] = 0;
        staking_time[msg.sender][_poolId] = 0;
        delete staking_token_id[msg.sender][_poolId];
    }

    function widthdrawNftWithoutReward(uint256 _poolId) public {
        // require(block.number > staking_time[msg.sender][_poolId] + PoolInfoList[_poolId].stakingLength, "t025");
        require(staking_num[msg.sender][_poolId] > 0, "t026");
        for (uint256 i = 0; i < staking_token_id[msg.sender][_poolId].length; i++) {
            stakingNftAddress.transferFrom(address(this), msg.sender, staking_token_id[msg.sender][_poolId][i]);
            staking_token_id_status[_poolId][staking_token_id[msg.sender][_poolId][i]] = false;
        }
        staking_num[msg.sender][_poolId] = 0;
        staking_time[msg.sender][_poolId] = 0;
        delete staking_token_id[msg.sender][_poolId];
    }

    // function massTransferFrom(address _to, uint256 _num) public {
    //     uint256 num = stakingNftAddress.balanceOf(msg.sender);
    //     require(num > 0 && _num > 0, "t027");
    //     require(stakingNftAddress.isApprovedForAll(msg.sender, address(this)), "t028");
    //     if (num >= _num) {
    //         num = _num;
    //     }
    //     for (uint256 i = 0; i < num; i++) {
    //         stakingNftAddress.transferFrom(msg.sender, _to, stakingNftAddress.tokenOfOwnerByIndex(msg.sender, 0));
    //     }
    // }

    function getErc20Token(IERC20 _token) public onlyOwner {
        _token.safeApprove(address(this), _token.balanceOf(address(this)));
        _token.safeTransferFrom(address(this), msg.sender, _token.balanceOf(address(this)));
    }
}