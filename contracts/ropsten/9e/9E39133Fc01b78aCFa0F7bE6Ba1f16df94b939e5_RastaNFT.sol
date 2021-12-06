/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

pragma solidity 0.6.0;

interface IERC20 {
   
    function totalSupply() external view returns (uint256);

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
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
       
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call.value(value)(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract RastaNFT {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct NFTInfo { 
        string url;
        address owner;
        uint256 price;
        uint256 rewardDebt;
        uint256 pendingRewards;
        uint256 depositedAt;
        uint256 claimedAt;
    }

    string public _NFTURL = "https://ipfs.infura.io/ipfs/";
    address private _owner;
    uint256 public totalNFTSupply = 0;
    uint256 public totalSupply;
    uint256 public withdrawalFee;
    uint256 public constant FEE_LIMIT = 1000;
    uint256 public constant MAX_FEE = 10000;

    IERC20 public stakingToken;
    IERC20 public rewardToken;
    address public feeRecipient;

    mapping(uint256 => NFTInfo) private _NFTs;
    mapping(address => uint256[]) private _ownedNFTs;
        mapping(uint256 => uint256) private _ownedNFTIndex;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (address owner, address _stakingToken, address _rewardToken) public {
        _owner = owner;
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function mint(uint256 tokenId, uint256 price, string calldata _tokenURI) external onlyOwner returns (bool) {
        
        NFTInfo storage nft = _NFTs[tokenId];
        nft.url = _tokenURI;
        nft.owner = _owner;
        nft.price = price;

        _ownedNFTs[_owner].push(tokenId);
        _ownedNFTIndex[tokenId] = _ownedNFTs[_owner].length - 1;

        totalNFTSupply++;

        return true;
    }

    function reduceNFT(uint tokenId, address from) private {
        uint256 lastTokenIndex = _ownedNFTs[from].length - 1;
        uint256 tokenIndex = _ownedNFTIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedNFTs[from][lastTokenIndex];

            _ownedNFTs[from][tokenIndex] = lastTokenId; 
            _ownedNFTIndex[lastTokenId] = tokenIndex; 
        }

        _ownedNFTs[from].pop();
    }

    function burn(uint256 tokenId) external onlyOwner returns (bool) {
        require(_NFTs[tokenId].owner == _owner, "!owner");

        reduceNFT(tokenId, _owner);
        
        _NFTs[tokenId].owner = address(0);

        totalNFTSupply--;

        return true;
    }

    function getNFT(uint256 tokenId) public view returns (string memory, address, uint256) {
        return (_NFTs[tokenId].url, _NFTs[tokenId].owner, _NFTs[tokenId].price);
    }

    function NFTOfOwner(address to) public view returns (uint256[] memory) {
        return _ownedNFTs[to];
    }

    function buyNFT(uint256 tokenId, uint256 amount) external {
        require(amount == _NFTs[tokenId].price, "Price is not match");
        
        reduceNFT(tokenId, _owner);
        
        _NFTs[tokenId].owner = msg.sender;
        _NFTs[tokenId].depositedAt = block.timestamp;
        _ownedNFTs[msg.sender].push(tokenId);
        _ownedNFTIndex[tokenId] = _ownedNFTs[msg.sender].length;
        
        uint before = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        amount = stakingToken.balanceOf(address(this)).sub(before);

        totalSupply = totalSupply.add(amount);

        emit Deposit(msg.sender, amount);
    }

    function sellNFT(uint256 tokenId) external {
        require(_NFTs[tokenId].owner == msg.sender, "!not owner");

        reduceNFT(tokenId, msg.sender);

        _NFTs[tokenId].owner = _owner;
        _ownedNFTs[_owner].push(tokenId);
        _ownedNFTIndex[tokenId] = _ownedNFTs[_owner].length;

        uint256 amount = _NFTs[tokenId].price;

        uint256 feeAmount = amount.mul(withdrawalFee).div(MAX_FEE);

        if (feeAmount > 0) stakingToken.safeTransfer(address(_owner), feeAmount);
        stakingToken.safeTransfer(address(msg.sender), amount.sub(feeAmount));
        
        totalSupply = totalSupply.sub(amount);

        emit Withdraw(msg.sender, amount);
    }

    function setWithdrawalFee(uint256 _fee) external onlyOwner {
        require(_fee < FEE_LIMIT, "invalid fee");

        withdrawalFee = _fee;
    }

}