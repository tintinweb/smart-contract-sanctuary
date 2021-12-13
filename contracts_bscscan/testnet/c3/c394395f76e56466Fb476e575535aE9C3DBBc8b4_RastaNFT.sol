/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

pragma solidity 0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

  
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract RastaNFT {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct NFTInfo { 
        string url;
        address owner;
        uint256 price;
        uint256 pendingRewards;
        uint256 depositedAt;
        uint256 claimedAt;
        uint256 lastUpdateTime;
        bool rewardStatus;
    }

    address private nftAddr;
    address public _owner;
    address public feeRecipient;
    uint256 public totalNFTSupply = 0;
    uint256 public totalSupply;
    uint256 public totalReward;
    uint256 public claimFee;
    uint256 public penaltyFee;
    uint256 public withdrawalFee;
    uint256 public rewardRate = uint256(0.001 ether);
    uint256 public constant FEE_LIMIT = 1000;
    uint256 public constant MAX_FEE = 10000;
    uint256 public lockupDuration;
    uint256 decimalsDiff;

    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public rewardCycle;
    uint256 public endTime;

    mapping(uint256 => NFTInfo) private _NFTs;
    mapping(address => uint256[]) private _ownedNFTs;
    mapping(uint256 => uint256) private _ownedNFTIndex;

    constructor (address _stakingToken, address _rewardToken, address _nftAddr) public {
        _owner = msg.sender;
        nftAddr = _nftAddr;
        feeRecipient = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);

        if (ERC20(_rewardToken).decimals() < ERC20(_stakingToken).decimals()) {
            decimalsDiff = ERC20(_stakingToken).decimals() - ERC20(_rewardToken).decimals();
        }
    }
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier updateReward(uint256 tokenId) {
        NFTInfo storage nft = _NFTs[tokenId];
        
        if(totalSupply > 0 && nft.rewardStatus == true) {
            uint256 accPerShare = block.timestamp.sub(nft.lastUpdateTime);
            uint256 pending = nft.price.mul(accPerShare).mul(rewardRate).div(totalSupply) ;
            nft.pendingRewards = nft.pendingRewards.add(pending);
        }

        nft.lastUpdateTime = block.timestamp;
        if (nft.claimedAt == 0) nft.claimedAt = block.timestamp;
        _;
    }

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);

    function mint(uint256 tokenId, uint256 price, string calldata _tokenURI) external onlyOwner returns (bool) {
        
        NFTInfo storage nft = _NFTs[tokenId];
        nft.url = _tokenURI;
        nft.owner = nftAddr;
        nft.price = price;
        nft.rewardStatus = false;
        _ownedNFTs[nftAddr].push(tokenId);
        _ownedNFTIndex[tokenId] = _ownedNFTs[nftAddr].length - 1;

        totalNFTSupply++;

        return true;
    }

    function reduceNFT(uint tokenId, address owner) private {
        uint256 lastTokenIndex = _ownedNFTs[owner].length - 1;
        uint256 tokenIndex = _ownedNFTIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedNFTs[owner][lastTokenIndex];

            _ownedNFTs[owner][tokenIndex] = lastTokenId; 
            _ownedNFTIndex[lastTokenId] = tokenIndex; 
        }

        _ownedNFTs[owner].pop();
    }

    function burn(uint256 tokenId) external onlyOwner returns (bool) {
        require(_NFTs[tokenId].owner == nftAddr, "!owner");

        reduceNFT(tokenId, nftAddr);
        
        _NFTs[tokenId].owner = address(0);

        totalNFTSupply--;

        return true;
    }

    function getNFT(uint256 tokenId) external view returns (string memory, address, uint256, uint256) {
        return (_NFTs[tokenId].url, _NFTs[tokenId].owner, _NFTs[tokenId].price, _NFTs[tokenId].claimedAt);
    }

    function NFTOfOwner(address to) public view returns (uint256[] memory) {
        return _ownedNFTs[to];
    }

    function setLockupDuration(uint256 _lockupDuration) external onlyOwner {
        lockupDuration = _lockupDuration;
    }

    function buyNFT(uint256 tokenId) external {
        NFTInfo storage nft = _NFTs[tokenId];
        uint balance = stakingToken.balanceOf(address(msg.sender));

        require(balance >= nft.price, "Price is not match");
        
        reduceNFT(tokenId, nftAddr);
        
        nft.owner = msg.sender;
        nft.depositedAt = block.timestamp;
        nft.lastUpdateTime = block.timestamp;
        nft.rewardStatus = true;
        _ownedNFTs[msg.sender].push(tokenId);
        _ownedNFTIndex[tokenId] = _ownedNFTs[msg.sender].length - 1;

        uint before = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(msg.sender, address(this), nft.price);
        uint256 amount = stakingToken.balanceOf(address(this)).sub(before);

        totalSupply = totalSupply.add(amount);

        emit Deposit(msg.sender, amount);
    }

    function sellNFT(uint256 tokenId) external {
        NFTInfo storage nft = _NFTs[tokenId];

        require(nft.owner == msg.sender, "!not owner");
        
        if (penaltyFee == 0) {
            require(block.timestamp >= nft.depositedAt + lockupDuration, "You cannot withdraw yet!");
        }

        claim(tokenId);

        reduceNFT(tokenId, msg.sender);

        nft.owner = nftAddr;
        nft.rewardStatus = false;
        _ownedNFTs[nftAddr].push(tokenId);
        _ownedNFTIndex[tokenId] = _ownedNFTs[nftAddr].length - 1;

        uint256 amount = nft.price;

        uint256 feeAmount = amount.mul(withdrawalFee).div(MAX_FEE);

        if (feeAmount > 0) stakingToken.safeTransfer(feeRecipient, feeAmount);
        stakingToken.safeTransfer(msg.sender, amount.sub(feeAmount));
        
        totalSupply = totalSupply.sub(amount);

        emit Withdraw(msg.sender, amount);
    }

    function setWithdrawalFee(uint256 _fee) external onlyOwner {
        require(_fee < FEE_LIMIT, "invalid fee");

        withdrawalFee = _fee;
    }

    function claim(uint256 tokenId) public updateReward(tokenId) {
        NFTInfo storage nft = _NFTs[tokenId];

        require (block.timestamp.sub(nft.claimedAt) >= rewardCycle, "!available still");
        
        uint256 claimedAmount = _safeTransferRewards(msg.sender, nft.pendingRewards);
        nft.pendingRewards = nft.pendingRewards.sub(claimedAmount);
        nft.claimedAt = block.timestamp;

        emit Claim(msg.sender, claimedAmount);
    }

    function claimable(uint256 tokenId) external view returns (uint256) {
        NFTInfo storage nft = _NFTs[tokenId];

        if(totalSupply > 0 && nft.rewardStatus == true) {
            uint256 accPerShare = block.timestamp.sub(nft.lastUpdateTime);
            return nft.price.mul(accPerShare).mul(rewardRate).div(totalSupply).add(nft.pendingRewards);
        } else {
            return nft.pendingRewards;
        }
    }
    
    function _safeTransferRewards(address to, uint256 amount) internal returns (uint256) {
        uint256 _bal = rewardToken.balanceOf(address(this));
        require (_bal > 0, "!balance");
        if (amount > _bal) amount = _bal;
        uint256 feeAmount = 0;
        feeAmount = amount.mul(claimFee).div(MAX_FEE);
        if (feeAmount > 0) rewardToken.safeTransfer(feeRecipient, feeAmount);
        rewardToken.safeTransfer(to, amount.sub(feeAmount));
        return amount;
    }
    
    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        require (_rewardRate > 0, "Rewards per block should be greater than 0!");

        rewardRate = _rewardRate;
    }

    function setClaimFee(uint256 _fee) external onlyOwner {
        require(_fee < FEE_LIMIT, "invalid fee");

        claimFee = _fee;
    }

    function setRewardCycle(uint256 _cycle) external onlyOwner {
        rewardCycle = _cycle;
    }

    function setFeeRecipient(address _recipient) external onlyOwner {
        feeRecipient = _recipient;
    }

    function withdrawRewardToken(uint256 amount) external onlyOwner {
        rewardToken.safeTransfer(_owner, amount);
        emit Withdraw(_owner, amount);
    }
}