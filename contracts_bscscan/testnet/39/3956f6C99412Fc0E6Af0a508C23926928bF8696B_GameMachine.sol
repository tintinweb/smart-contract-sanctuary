/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Pausable is Context {

    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function mint(address to) external;
    function totalSupply() external view returns (uint256);
}

abstract contract TokenRecover is Ownable {
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

interface IGuild {
    function guildIdOf(address _account) external view returns (string memory);
}

contract GameMachine is Ownable, Pausable, TokenRecover, ERC721Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Roles for Roles.Role;
    using Counters for Counters.Counter;

    Roles.Role private gameMaster;
    Counters.Counter private itemIdTracker;

    IERC20 public SCBToken;
    IERC20 public FCBToken;
    IERC721 public Factory;
    IGuild public Guild;

    uint256 public NORMAL_BATTLE_FEE = 0.001 * 1E18;
    uint256 public REWARD_LOCKING_DURATION = 950400; // 11 DAYS
    uint256 public REWARD_PENALTY = 30;
    uint256 public CHARACTER_MAX_SUPPLY = 1 * 1E6;
    uint256 public SCB_MINT_COST = 1 * 1E18;
    uint256 public FCB_MINT_COST = 10 * 1E18;
    uint public STAMINA_MAX_CAP = 15;
    uint public STAMINA_PER_BATTLE = 3;
    uint256 public STAMINA_RECHARGE_DURATION = 7200; // 2 HOURS
    address public GAME_MASTER_ADDRESS;
    
    uint public ownerShare = 40;
    uint public borrowerShare = 60;
    uint public LIST_DURATION = 2592000; // 30 DAYS
    uint256 public LIST_FEE = 0.2 * 1E18;
    
    uint public MAX_EVOLUTION_STATE = 2;

    struct Listing {
        address owner;
        address borrower;
        uint256 nftId;
        uint256 timestamp;
        uint256 listingId;
        string guildId;
        bool isWithdraw;
    }

    struct Reward {
        uint256 timestamp;
        uint256 reward;
    }

    struct Inventory {
        uint256 itemId;
        uint256 balance;
    }

    struct Character {
        uint stamina;
        uint256 stamina_timestamp;
        uint evolution_state;
    }

    mapping (address => Reward) public rewardOf;
    mapping (uint256 => uint256) public itemCost;
    mapping (address => mapping (uint256 => Inventory)) public itemBalanceOf;
    mapping (uint256 => Character) public characterOf;
    mapping (address => uint) public rentals;
    
    Listing[] public _listings;
    uint256 public totalListing = 0;

    event Battle(address indexed account, string indexed id, uint256 fee);
    event DistributeReward(address indexed account, string indexed id, uint256 reward);
    event DistributeRentalReward(address indexed account, string indexed id, uint256 listingId, uint256 reward);
    event RewardPenalty(address indexed account, uint256 penalty);
    event ClaimReward(address indexed account, uint256 reward);
    event Listed(address indexed account, uint256 id, string guildId, uint256 listId, uint256 totalListing);
    event RewardClaimed(address indexed account, uint256 reward);
    event Rent(address indexed account, uint256 listId);
    event Restaked(address indexed account, uint256 id, uint256 listId);
    event Withdrawn(address indexed account, uint256 id, uint256 listId);
    event Harvest(address indexed account, uint256 id, uint256 listId, uint256 reward);
    event BuyItemWithReward(address indexed account, uint256 itemId, uint256 quantity, uint256 total);
    event BuyItem(address indexed account, uint256 itemId, uint256 quantity, uint256 total);
    event SpendItem(address indexed account, uint256 itemId, uint256 quantity);
    event MintCharacter(address indexed account, uint256 nftId);
    event Evolve(uint256 id, uint level);

    constructor(address _scb, address _fcb, address _factory, address _gameMaster, address _guild) {
        SCBToken = IERC20(_scb);
        FCBToken = IERC20(_fcb);
        Factory = IERC721(_factory);
        Guild = IGuild(_guild);
        gameMaster.add(_gameMaster);
        gameMaster.add(msg.sender);
        GAME_MASTER_ADDRESS = _gameMaster;
    }

    function setGameMasterAddress(address _address) external onlyOwner {
        GAME_MASTER_ADDRESS = _address;
    }

    function setGuild(address _guild) external onlyOwner {
        Guild = IGuild(_guild);
    }

    function setListDuration(uint _duration) external onlyOwner {
        LIST_DURATION = _duration * 1 seconds;
    }

    function setListFee(uint256 _fee) external onlyOwner {
        LIST_FEE = _fee;
    }

    function setStaminaRechargeDuration(uint256 _duration) external onlyOwner {
        STAMINA_RECHARGE_DURATION = _duration * 1 seconds;
    }

    function setStaminaPerBattle(uint _bar) external onlyOwner {
        STAMINA_PER_BATTLE = _bar;
    }

    function setStaminaMaxCap(uint _max) external onlyOwner {
        STAMINA_MAX_CAP = _max;
    }

    function setSCBMintCost(uint256 _cost) external onlyOwner {
        SCB_MINT_COST = _cost;
    }

    function setFCBMintCost(uint256 _cost) external onlyOwner {
        FCB_MINT_COST = _cost;
    }

    function setCharacterMaxSupply(uint256 _max) external onlyOwner {
        CHARACTER_MAX_SUPPLY = _max;
    }

    function setFactory(address _factory) external onlyOwner {
        Factory = IERC721(_factory);
    }

    function setSCBToken(address _scb) external onlyOwner {
        SCBToken = IERC20(_scb);
    }

    function setFCBToken(address _fcb) external onlyOwner {
        FCBToken = IERC20(_fcb);
    }

    function creatNewItem(uint256 _cost) external onlyOwner {
        itemCost[itemIdTracker.current()] = _cost;
        itemIdTracker.increment();
    }

    function editItem(uint256 _itemId, uint256 _cost) external onlyOwner {
        require(_itemId < itemIdTracker.current(), "Item not exist.");
        itemCost[_itemId] = _cost;
    }

    function getAllItemBalanceOf(address _account) public view returns (Inventory[] memory) {
        Inventory[] memory inv = new Inventory[](itemIdTracker.current());
        uint counter = 0;
        for(uint i=0; i<itemIdTracker.current(); i++) {
            if(itemBalanceOf[_account][i].balance <= 0) continue;
            inv[counter] = itemBalanceOf[_account][i];
            counter++;
        }
        return inv;
    }

    function setRewardPenanlty(uint256 _penanlty) external onlyOwner {
        REWARD_PENALTY = _penanlty;
    }

    function setNormalBattleFee(uint256 _amount) external onlyOwner {
        NORMAL_BATTLE_FEE = _amount;
    }

    function setRewardLockingDuration(uint256 _duration) external onlyOwner {
        REWARD_LOCKING_DURATION = _duration * 1 seconds;
    }

    function setGameMaster(address _account, bool _permission) external onlyOwner {
        if (_permission) {
            gameMaster.add(_account);
        } else {
            gameMaster.remove(_account);
        }
    }

    function isGameMaster(address _account) public view returns (bool) {
        return gameMaster.has(_account);
    }

    function setRentalRewardShare(uint _ownerShare, uint _borrowerShare) external onlyOwner {
        borrowerShare = _borrowerShare;
        ownerShare = _ownerShare;
    }

    function staminaOf(uint256 _nftId) public view returns (uint) {
        if(characterOf[_nftId].stamina_timestamp > block.timestamp) {
            uint256 time_diff = characterOf[_nftId].stamina_timestamp - block.timestamp;
            uint replenish_stamina = time_diff / STAMINA_RECHARGE_DURATION;
            if((replenish_stamina * STAMINA_RECHARGE_DURATION) < time_diff) {
                replenish_stamina += 1;
            }
            uint current_stamina = STAMINA_MAX_CAP - replenish_stamina;
            return current_stamina;
        }
        return STAMINA_MAX_CAP;
    }

    function startBattle(string calldata _id, uint256 _nftId) payable external whenNotPaused {
        require(staminaOf(_nftId) >= STAMINA_PER_BATTLE, "Insufficient stamina.");
        require(msg.value >= NORMAL_BATTLE_FEE, "Insufficient fee");
        (bool success,) = GAME_MASTER_ADDRESS.call{value: NORMAL_BATTLE_FEE}("");
        require(success, "Failed to send Ether");
        require(Factory.ownerOf(_nftId) == msg.sender, "Caller is not NFT Owner.");

        if(block.timestamp > characterOf[_nftId].stamina_timestamp) {
            characterOf[_nftId].stamina_timestamp = block.timestamp + (STAMINA_RECHARGE_DURATION * STAMINA_PER_BATTLE);
        } else {
            characterOf[_nftId].stamina_timestamp = characterOf[_nftId].stamina_timestamp + (STAMINA_RECHARGE_DURATION * STAMINA_PER_BATTLE);
        }
        characterOf[_nftId].stamina = staminaOf(_nftId);
        emit Battle(msg.sender, _id, msg.value);
        
    }

    function distributeReward(address _account, string calldata _id, uint256 _amount) external whenNotPaused {
        require(gameMaster.has(msg.sender), "Need Game Master Role.");
        updateReward(_account, _amount);
        emit DistributeReward(_account, _id, _amount);
    }

    function distributeRentalReward(uint256 _listId, string calldata _id, uint256 _amount) external whenNotPaused {
        require(gameMaster.has(msg.sender), "Need Game Master Role.");
        Listing storage lis = _listings[_listId];
        require(staminaOf(lis.nftId) >= STAMINA_PER_BATTLE, "Insufficient stamina.");
        uint256 owner_reward = _amount * ownerShare / 100;
        uint256 borrower_reward = _amount * borrowerShare / 100;
        updateReward(lis.owner, owner_reward);
        updateReward(lis.borrower, borrower_reward);
        emit DistributeRentalReward(lis.owner, _id, _listId, owner_reward);
        emit DistributeRentalReward(lis.borrower, _id, _listId, borrower_reward);
        if(block.timestamp > characterOf[lis.nftId].stamina_timestamp) {
            characterOf[lis.nftId].stamina_timestamp = block.timestamp + (STAMINA_RECHARGE_DURATION * STAMINA_PER_BATTLE);
        } else {
            characterOf[lis.nftId].stamina_timestamp = characterOf[lis.nftId].stamina_timestamp + (STAMINA_RECHARGE_DURATION * STAMINA_PER_BATTLE);
        }
        characterOf[lis.nftId].stamina = staminaOf(lis.nftId);
    }

    function updateReward(address _account, uint256 _amount) internal {
        if (rewardOf[_account].reward == 0) {
            rewardOf[_account].timestamp = block.timestamp;
        }
        rewardOf[_account].reward = rewardOf[_account].reward + _amount;
    }

    receive() external payable { }

    function withdrawBNB(address _account) external onlyOwner {
        (bool success,) = _account.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    function claimReward() external nonReentrant {
        require(rewardOf[msg.sender].reward > 0, "Unable to claim 0 reward.");
        require(FCBToken.balanceOf(address(this)) >= rewardOf[msg.sender].reward, "Insufficient FCB balance in contract.");
        uint256 reward = rewardOf[msg.sender].reward;
        if((rewardOf[msg.sender].timestamp + REWARD_LOCKING_DURATION) > block.timestamp) {
            uint256 penalty = reward * REWARD_PENALTY / 100;           
            reward = reward - penalty;
            emit RewardPenalty(msg.sender, penalty);
        }
        rewardOf[msg.sender].reward = 0;
        FCBToken.safeTransfer(msg.sender, reward);
        emit ClaimReward(msg.sender, reward);
    }

    function buyItemWithReward(uint256 _itemId, uint256 _quantity) external nonReentrant {
        uint256 total = itemCost[_itemId] * _quantity;
        require(rewardOf[msg.sender].reward >= total, "Insufficient reward.");
        rewardOf[msg.sender].reward = rewardOf[msg.sender].reward - total;
        itemBalanceOf[msg.sender][_itemId].balance = itemBalanceOf[msg.sender][_itemId].balance + _quantity; 
        emit BuyItemWithReward(msg.sender, _itemId, _quantity, total);
    }

    function buyItem(uint256 _itemId, uint256 _quantity) external nonReentrant {
        uint256 total = itemCost[_itemId] * _quantity;
        require(FCBToken.balanceOf(msg.sender) >= total, "Insufficient balance.");
        require(FCBToken.allowance(msg.sender, address(this)) >= total, "Insufficient allowance.");
        itemBalanceOf[msg.sender][_itemId].balance = itemBalanceOf[msg.sender][_itemId].balance + _quantity; 
        FCBToken.safeTransferFrom(msg.sender, address(this), total);
        emit BuyItem(msg.sender, _itemId, _quantity, total);
    }

    function spendItem(uint256 _itemId, uint256 _quantity) external {
        require(itemBalanceOf[msg.sender][_itemId].balance >= _quantity, "Insufficient item balance.");
        itemBalanceOf[msg.sender][_itemId].balance = itemBalanceOf[msg.sender][_itemId].balance - _quantity; 
        emit SpendItem(msg.sender, _itemId, _quantity);
    }

    function mintCharacter() external whenNotPaused {
        require(Factory.totalSupply() < CHARACTER_MAX_SUPPLY, "Hero max supply reached.");
        require(SCBToken.balanceOf(msg.sender) >= SCB_MINT_COST, "Insufficient SCB balance");
        require(SCBToken.allowance(msg.sender, address(this)) >= SCB_MINT_COST, "Insufficient SCB allowance.");
        require(FCBToken.balanceOf(msg.sender) >= FCB_MINT_COST, "Insufficient FCB balance");
        require(FCBToken.allowance(msg.sender, address(this)) >= FCB_MINT_COST, "Insufficient FCB allowance.");
        SCBToken.safeTransferFrom(msg.sender, address(this), SCB_MINT_COST);
        FCBToken.safeTransferFrom(msg.sender, address(this), FCB_MINT_COST);
        uint256 card = Factory.totalSupply();
        characterOf[card].stamina = STAMINA_MAX_CAP;
        characterOf[card].stamina_timestamp = block.timestamp;
        Factory.mint(msg.sender);
        emit MintCharacter(msg.sender,card);
    }

    

    function listNFT(uint256 _id) payable external {
        require(Factory.ownerOf(_id) == msg.sender, "Insufficient balance");
        require(Factory.isApprovedForAll(msg.sender, address(this)), "Insufficient allowance");
        require(msg.value >= LIST_FEE, "Insufficient fee.");
        string memory empty = "";
        require(keccak256(bytes(Guild.guildIdOf(msg.sender))) != keccak256(bytes(empty)), "Guild required.");  
        uint listId = _listings.length;
        _listings.push();
        Listing storage lis = _listings[listId];
        lis.owner = msg.sender;
        lis.nftId = _id;
        lis.timestamp = block.timestamp;
        lis.listingId = listId;
        lis.guildId = Guild.guildIdOf(msg.sender);
        lis.borrower = address(0);
        lis.isWithdraw = false;
        totalListing += 1;
        (bool success,) = address(this).call{value: LIST_FEE}("");
        require(success, "Failed to send Ether");
        Factory.safeTransferFrom(msg.sender, address(this), _id);
        emit Listed(msg.sender, _id, Guild.guildIdOf(msg.sender), listId, totalListing);
    }

    function withdrawNFT(uint256 _listId) external {
        Listing storage lis = _listings[_listId];
        require((lis.timestamp + LIST_DURATION) < block.timestamp, "Listing locked.");
        require(msg.sender == lis.owner, "Caller is not owner.");
        lis.isWithdraw = true;
        totalListing -= 1;
        Factory.safeTransferFrom(address(this), msg.sender, lis.nftId);
        emit Withdrawn(msg.sender, lis.nftId, _listId);
    }

    function restakeNFT(uint256 _listId) payable external {
        Listing storage lis = _listings[_listId];
        require( lis.owner == msg.sender, "Caller is not owner or borrower");
        require((lis.timestamp + LIST_DURATION) < block.timestamp, "Listing locked.");
        lis.isWithdraw = true;
        require(msg.value >= LIST_FEE, "Insufficient fee.");
        string memory empty = "";
        require(keccak256(bytes(Guild.guildIdOf(msg.sender))) != keccak256(bytes(empty)), "Guild required.");
        uint NlistId = _listings.length;
        _listings.push();
        Listing storage Nlis = _listings[NlistId];
        Nlis.owner = msg.sender;
        Nlis.nftId = lis.nftId;
        Nlis.timestamp = block.timestamp;
        Nlis.listingId = NlistId;
        Nlis.guildId = Guild.guildIdOf(msg.sender);
        Nlis.borrower = address(0);
        Nlis.isWithdraw = false;
        totalListing += 1;
        (bool success,) = GAME_MASTER_ADDRESS.call{value: msg.value}("");
        require(success, "Failed to send Ether");
        emit Listed(msg.sender, lis.nftId, Guild.guildIdOf(msg.sender), NlistId, totalListing);
    }


    function rentNFT(uint256 _listId) external {
        Listing storage lis = _listings[_listId];
        require((lis.timestamp + LIST_DURATION) > block.timestamp, "Listing is not available.");
        require(lis.borrower == address(0), "Listing occupied.");
        require(lis.owner != msg.sender, "Caller is listing owner.");
        require(keccak256(bytes(lis.guildId)) == keccak256(bytes(Guild.guildIdOf(msg.sender))), "Guild required."); 
        lis.borrower = msg.sender;
        rentals[msg.sender] += 1;
        emit Rent(msg.sender, _listId);
    }

    function rentalsOf(address _borrower) public view returns (Listing[] memory) {
        Listing[] memory lis = new Listing[](rentals[_borrower]);
        uint counter;
        for(uint i = 0; i < _listings.length; i++) {
            if (_listings[i].borrower != _borrower) continue;
                lis[counter] = _listings[i];
                counter++;
        }
        return lis;
    }

    function getGuildOpenListingCount(string calldata _guild_id) public view returns (uint) {
        uint counter;
        for(uint i = 0; i < _listings.length; i++) {
            if ( (_listings[i].timestamp + LIST_DURATION) < block.timestamp || keccak256(bytes( _listings[i].guildId)) != keccak256(bytes(_guild_id)) || _listings[i].borrower != address(0) ) continue;
            counter++;
        }
        return counter;
    }

    function getGuildRentedListingCount(string calldata _guild_id) public view returns (uint) {
        uint counter;
        for(uint i = 0; i < _listings.length; i++) {
            if ( (_listings[i].timestamp + LIST_DURATION) < block.timestamp || keccak256(bytes( _listings[i].guildId)) != keccak256(bytes(_guild_id)) || _listings[i].borrower == address(0) ) continue;
            counter++;
        }
        return counter;
    }

    function getGuildExpiredListingCount(string calldata _guild_id, address _account) public view returns (uint) {
        uint counter;
        for(uint i = 0; i < _listings.length; i++) {
            if ( (_listings[i].timestamp + LIST_DURATION) > block.timestamp || keccak256(bytes( _listings[i].guildId)) != keccak256(bytes(_guild_id)) || ( _listings[i].borrower != _account && _listings[i].owner != _account ) || ( _listings[i].isWithdraw ) ) continue;
            counter++;
        }
        return counter;
    }


    function openListing(string calldata _guild_id) public view returns (Listing[] memory) {
        Listing[] memory lis = new Listing[](getGuildOpenListingCount(_guild_id));
        uint counter;
        for(uint i = 0; i < _listings.length; i++) {
            if ( (_listings[i].timestamp + LIST_DURATION) < block.timestamp || keccak256(bytes( _listings[i].guildId)) != keccak256(bytes(_guild_id)) || _listings[i].borrower != address(0) ) continue;
            lis[counter] = _listings[i];
            counter++;
        }
        return lis;
    }

    function rentedListing(string calldata _guild_id) public view returns (Listing[] memory) {
        Listing[] memory lis = new Listing[](getGuildRentedListingCount(_guild_id));
        uint counter;
        for(uint i = 0; i < _listings.length; i++) {
            if ( (_listings[i].timestamp + LIST_DURATION) < block.timestamp || keccak256(bytes( _listings[i].guildId)) != keccak256(bytes(_guild_id)) || _listings[i].borrower == address(0) ) continue;
            lis[counter] = _listings[i];
            counter++;
        }
        return lis;
    }

    function expiredListing(string calldata _guild_id, address _account) public view returns (Listing[] memory) {
        Listing[] memory lis = new Listing[](getGuildExpiredListingCount(_guild_id,_account));
        uint counter;
        for(uint i = 0; i < _listings.length; i++) {
            if ( (_listings[i].timestamp + LIST_DURATION) > block.timestamp || keccak256(bytes( _listings[i].guildId)) != keccak256(bytes(_guild_id)) || ( _listings[i].borrower != _account && _listings[i].owner != _account ) || ( _listings[i].isWithdraw ) ) continue;
            lis[counter] = _listings[i];
            counter++;
        }
        return lis;
    }
    
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    function replenishStamina(uint256 _nftId, uint _stamina, uint256 _timestamp) external onlyOwner {
        characterOf[_nftId].stamina = _stamina;
        characterOf[_nftId].stamina_timestamp = _timestamp;
    }
    
    function evolve(uint256 _nftId) external nonReentrant {
        require(gameMaster.has(msg.sender), "Need Game Master Role.");
        require(characterOf[_nftId].evolution_state <= MAX_EVOLUTION_STATE, "Character reached max evolution");
        characterOf[_nftId].evolution_state += 1;
        emit Evolve(_nftId, characterOf[_nftId].evolution_state);
    }
    
    function setMaxEvolutionState(uint _state) external onlyOwner {
        MAX_EVOLUTION_STATE = _state;
    }

}