/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

contract StakingBase is ReentrancyGuard{
    using SafeMath for uint256;
    
    /* ==== STATE VARIABLES ==== */

    ERC20 public rewardsToken;
    IERC721 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardAmount = 10;
    uint256 public rewardDecimals = 18;
    uint256 public rewardDuration = 10 minutes;
    uint256 public rewardCycle = 10 seconds;
    uint256 public lastUpdateTime = 0;

    uint256 public _totalSupply = 0;

    address private rewardTokenProvider;
    address public admin;

    /* ========== NFT MINING SPECIFIC VARIABLES ========== */
    
    mapping(address => uint256) public _balances;
    mapping(address => mapping(uint256 => uint256)) public _stakedTokens;
    mapping(uint256 => address) public _stakedBy;
    mapping(uint256 => uint256) public _stakedTokensIndex;

    mapping(address => uint256) public _ownerToLastUpdatedTime;
    mapping(uint256 => uint256) public _tokenIdToLastUpdatedTime;
    mapping(uint256 => uint256) public _tokenIndexToLastUpdatedTime;

    mapping(uint256 => uint256) public _tokenIndexToFirstUpdatedTime;
    mapping(uint256 => uint256) public _tokenIdToFirstUpdatedTime;
    mapping(address => uint256) public _tokenOwnerToFirstUpdatedTime;

    /* ========== CONSTRUCTOR ========== */

    constructor (address _stakingToken, address _rewardsToken, address _rewardTokenProvider) {
        admin = msg.sender;
        rewardsToken = ERC20(_rewardsToken);
        stakingToken = IERC721(_stakingToken);
        rewardTokenProvider = _rewardTokenProvider;
        rewardDecimals = rewardsToken.decimals();
    }
    
    /* ========== NFT STAKING SPECIFIC FUNCTIONS ========== */

    function stake(uint256 _tokenId) external {
        stakingToken.transferFrom(msg.sender, address(this), _tokenId);
        _addTokenToOwner(_tokenId, msg.sender);
        emit Staked(_tokenId, msg.sender);
    }

    function unStake(uint256 _tokenId) external {
        require(msg.sender == _stakedBy[_tokenId], "caller is not owner");
        require(_tokenIdToFirstUpdatedTime[_tokenId].add(rewardDuration) < block.timestamp, "it's not time to unstake yet");
        _removeTokenFromOwner(_tokenId, msg.sender);
        stakingToken.transferFrom(address(this), msg.sender, _tokenId);
        emit Unstaked(_tokenId, msg.sender);
    }

    function forceUnStake (uint256 _tokenId) private {
        address _owner = _stakedBy[_tokenId];
        _removeTokenFromOwner(_tokenId, _owner);
        stakingToken.transferFrom(address(this), _owner, _tokenId);
        emit Unstaked(_tokenId, _owner);
    }

    function _addTokenToOwner(uint256 _tokenId, address _owner) internal {
        uint256 length = _balances[_owner];
        _stakedTokens[_owner][length] = _tokenId;
        _stakedTokensIndex[_tokenId] = length;

        _tokenIdToLastUpdatedTime[_tokenId] = block.timestamp;
        _tokenIndexToLastUpdatedTime[length] = block.timestamp;
        _ownerToLastUpdatedTime[_owner] = block.timestamp;

        _tokenIdToFirstUpdatedTime[_tokenId] = block.timestamp;
        _tokenIndexToFirstUpdatedTime[length] = block.timestamp;
        _tokenOwnerToFirstUpdatedTime[_owner] = block.timestamp;

        _totalSupply += 1;
        _balances[_owner] += 1;
        _stakedBy[_tokenId] = _owner;
    }

    function _removeTokenFromOwner(uint256 _tokenId, address _owner) internal {
        uint256 lastTokenIndex = _balances[_owner] - 1;
        uint256 tokenIndex = _stakedTokensIndex[_tokenId];
        if(tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _stakedTokens[_owner][lastTokenIndex];

            _stakedTokens[_owner][tokenIndex] = lastTokenId;
            _stakedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _stakedTokensIndex[_tokenId];
        delete _stakedTokens[_owner][lastTokenIndex];

        _totalSupply -= 1;
        _balances[_owner] -= 1;
        _stakedBy[_tokenId] = address(0);
    }

    function setRewardRate (uint256 _rate) public onlyAdmin{
        rewardRate = _rate;
    }

    function setRewardCycle (uint256 _newCycle) public onlyAdmin {
        rewardCycle = _newCycle;
    }

    function setRewardAmount (uint256 _amount) public onlyAdmin {
        rewardAmount = _amount;
    }

    function setRewardTokenProvider (address _address) public onlyAdmin {
        rewardTokenProvider = _address;
    }

    function rewardLaunch () public{
        _rewardLaunch(msg.sender);
    }

    function _rewardLaunch(address _owner) private {
        require(_balances[_owner] > 0, "you have not any staked token");
        rewardRate = _calculateRewardRate(_owner);
        uint256 amountToReward = rewardAmount.mul(rewardRate).mul(10 ** rewardDecimals);
        rewardsToken.transferFrom(rewardTokenProvider, _owner, amountToReward);
        emit Reward(_owner, rewardAmount.mul(rewardRate));
    }

    function _calculateRewardRate(address _owner) private returns(uint256) {
        uint256 rate = 0;
        uint256 totalPeriod = 0;

        for(uint256 i = 0; i < _balances[_owner]; i++) {
            uint256 period = _tokenIndexToLastUpdatedTime[i];
            
            if(_tokenIndexToFirstUpdatedTime[i].add(rewardDuration) < block.timestamp) {
                totalPeriod += _tokenIndexToFirstUpdatedTime[i].add(rewardDuration).sub(_tokenIndexToLastUpdatedTime[i]); 
                forceUnStake(_stakedTokens[_owner][i]);
            } else {
                if(block.timestamp.sub(period) >= rewardCycle) {
                    totalPeriod += block.timestamp.sub(period);
                    _tokenIndexToLastUpdatedTime[i] = block.timestamp;
                }
            }
        }
        require(totalPeriod >= rewardCycle, "too short staking time");
        rate = totalPeriod.div(rewardCycle);
        return rate;
    }

    /* ========== VIEWS ========== */

    function allowance() public view returns(uint256) {
        uint256 erc20Allowance = rewardsToken.allowance(rewardTokenProvider, address(this));
        return erc20Allowance;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function tokenIdsByOwner( address _owner) public view returns(uint256[] memory) {
        uint256[] memory tokenIds_ = new uint256[](_balances[_owner]);
        for(uint256 i = 0; i < _balances[_owner]; i++) {
            tokenIds_[i] = _stakedTokens[_owner][i];
        }
        return tokenIds_;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function updateAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    /* ========== EVENTS ========== */
    event Staked(uint256 _tokenId, address _owner);
    event Unstaked(uint256 _tokenId, address _owner);
    event Reward(address _address, uint256 _amount);
}