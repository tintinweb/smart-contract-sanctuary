// Staketoshi f1deltatime investment contract
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

interface IStaketoshiKYC {
    function getKYCStatus(address addr) external view returns(uint8);
}

interface IStaketoshiF1Delta {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 value) external;
    function burn(uint256 value) external;
    function rebase(uint256 epoch, int256 supplyDelta) external;
}


contract StaketoshiF1DeltaCore is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 constant public PERCENTS_DIVIDER = 10000;
    uint256 constant public MIN_BORROW_LIMIT = 1e20;
    uint256 constant public MAX_ALLOWANCE = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    IStaketoshiF1Delta public staketoshiToken;
    IERC20 public revvToken;
    IERC1155 public nftToken;
    IStaketoshiKYC public KYC;

    address public feeAddress;
    uint256 public adminPercent;
    uint256 public sponsorPercent;

    /** Tournament Information */
    struct Tour {
        uint256 tour_id;
        string title;
        uint256[2] duration;
        uint256[2] lock_duration;
        uint256 total_borrowed;
        uint256 total_staked;
        uint256 total_voted;
        uint256 total_admin_rewards;
        uint256 total_sponsor_rewards;
        bool active;
        bool valid;
    }
    mapping(uint256 => Tour) public tours;
    uint256 public currentTourId = 0;

    /** Player Data */
    struct player {
        bool verified;
        uint256 balance;
        uint256 borrowed;
        uint256 total_cycles;
        uint256 total_rewards;
        uint256 latest_tour_id;
        uint256 voting_power;
        bool active;
    }
     // address => player
    mapping(address => player) internal players;
    address[] internal playerIndices;

    /** Sponsor Data */
    struct sponsor {
        uint256 total_cycles;
        uint256 total_staked;
        uint256 total_rewards;
        uint256 latest_tour_id;
        bool active;
    }
    mapping(address => sponsor) internal sponsors;
    address[] internal sponsorIndices;

    /** Player Borrow(ask) Data */
    struct Borrow {
        uint256 id;
        address player;
        uint256 tour_id;      // current Tournament id
        uint256 percent;      // percent for sponsor from reward
        uint256 amount;       // borrow amount
        bool active;
    }
    mapping(uint256 => Borrow) public borrows;
    uint256 currentBorrowId =  0;

    /** Voting */
    struct Vote {
        uint256 amount;
        bool voted;
    }
    // sponsor => player => Vote mapping
    mapping(address => mapping(address => Vote)) public votes;

    // total staked = current staked to pool
    uint256 poolBalance = 0;
    
    // total voted
    uint256 totalVoted = 0;

    /**
        Events
     */
    event addedTournament(uint256 id, string title, uint256[2] duration, uint256[2] lock);
    event newBorrow(uint256 id, address player, uint256 amount, uint256 percent);
    event newStake(address sponsor, address player, uint256 amount, uint256 tour_id);


    constructor(address _token, address _revv, address _nft, address _fee, address _kycContract, uint256 _percent) public {
        staketoshiToken = IStaketoshiF1Delta(_token);
        revvToken       = IERC20(_revv);
        nftToken        = IERC1155(_nft);
        feeAddress      = _fee;
        KYC             = IStaketoshiKYC(_kycContract);
        sponsorPercent  = _percent;
    }

    /**
        Stake $revv to Pool from Sponsor
        _amount: uint256
     */
    function stake(address _player_addr, uint256 _amount) external beforeStarted {
        require(_amount > 0, "invalid amount");
        require(isVerifiedPlayer(_player_addr), "invalid player");

        require(revvToken.transferFrom(msg.sender, address(this), _amount), 'failed to transfer revv token');
        require(_vote(msg.sender, _player_addr, _amount), "failed to vote to player");

        // mint Symbolic token to voter
        staketoshiToken.mint(msg.sender, _amount);

        // update sponsor status
        sponsor memory s = sponsors[msg.sender];
        s.total_staked = s.total_staked.add(_amount);
        if(s.latest_tour_id < currentTourId) {
            s.total_cycles = s.total_cycles.add(1);
            s.latest_tour_id = currentTourId;
        }
    
        // update current tournament status
        Tour memory t = getCurrentTour();
        t.total_staked = t.total_staked.add(_amount);
        t.total_voted = t.total_voted.add(1);

        poolBalance = poolBalance.add(_amount);
        totalVoted  = totalVoted.add(_amount);

        emit newStake(msg.sender, _player_addr, _amount, t.tour_id);
    }

    /**
        Unstake $revv from Pool
     */
    function unstake(uint256 _amount) external afterEnded {
        require(_amount > 0, 'invalid amount');
        require(staketoshiToken.transferFrom(msg.sender, address(0x0), _amount), 'symbolic token transfer failed');

        uint256 amount = _amount;
        if(_amount > revvToken.balanceOf(address(this))) {
            amount = revvToken.balanceOf(address(this));
        }
        require(revvToken.transfer(msg.sender, amount), "revv token transfer failed");
        poolBalance = poolBalance.sub(_amount);
    }


    /**
        private: Vote to player
     */
    function _vote(address _sponsor, address _player, uint256 _amount) private returns(bool) {
        Vote storage v = votes[_sponsor][_player];
        if(v.voted) {
            v.amount = v.amount.add(_amount);
        }else {
            v.amount = _amount;
            v.voted = true;
        }

        players[_player].voting_power = players[_player].voting_power.add(_amount);

        return true;
    } 


    /**
        Add Borrow from Player
        _amount: uint256
     */
    function borrow(uint256 _amount) external  onlyPlayer beforeStarted returns(uint256) {
        require(_amount > 0, 'invalid amount');
        require(_amount <= borrowLimit(msg.sender), 'borrow amount is bigger than limit');
        require(revvToken.allowance(msg.sender, address(this)) == MAX_ALLOWANCE, 'revv token not allowed');
        require(nftToken.isApprovedForAll(msg.sender, address(this)), 'NFT token not allowed');
        require(revvToken.transfer(msg.sender, _amount), "revv token transfer failed");

        currentBorrowId = currentBorrowId.add(1);
        borrows[currentBorrowId].id = currentBorrowId;
        borrows[currentBorrowId].player = msg.sender;
        borrows[currentBorrowId].tour_id = currentTourId;
        borrows[currentBorrowId].percent = sponsorPercent;
        borrows[currentBorrowId].amount = _amount;
        borrows[currentBorrowId].active = true;

        // update player status
        players[msg.sender].borrowed = players[msg.sender].borrowed.add(_amount);
        if(players[msg.sender].latest_tour_id < currentTourId) {
            players[msg.sender].total_cycles = players[msg.sender].total_cycles.add(1);
            players[msg.sender].latest_tour_id = currentTourId;
        }

        // update current tournament status
        Tour memory t = getCurrentTour();
        t.total_borrowed = t.total_borrowed.add(_amount);

        emit newBorrow(currentBorrowId, msg.sender, _amount, sponsorPercent);
    }

    /**
        Calculate Borrowing Limit from player's voting power
     */ 
    function borrowLimit(address _player) view internal returns(uint256) {
        if(totalVoted == 0 || poolBalance == 0) return 0;

        uint256 voting_power = players[_player].voting_power;
    
        if(voting_power <= MIN_BORROW_LIMIT) {
            return MIN_BORROW_LIMIT.mul(poolBalance).div(totalVoted);
        } else {
            return voting_power.mul(poolBalance).div(totalVoted);
        }
    } 

    /**
        Delivery rewards after ends tournament - onlyOwner
     */
    function endTournament() external onlyOwner afterLockEnded {
        Tour memory t = getCurrentTour();
        require(t.valid && t.active == false && t.duration[1] < block.timestamp, "only after all tournament ended");

        // gather rewards from players
        for(uint i = 0; i < playerIndices.length; i++) {
            player memory p = players[playerIndices[i]];
            if(p.verified && p.active && p.borrowed > 0) {
                uint256 reward_this_tour = revvToken.balanceOf(playerIndices[i]).sub(p.balance).sub(p.borrowed);
                uint256 admin_reward = reward_this_tour.mul(adminPercent).div(PERCENTS_DIVIDER);
                uint256 sponsor_reward = (reward_this_tour.sub(admin_reward)).mul(sponsorPercent).div(PERCENTS_DIVIDER);
                
                // transfer rewards + borrowed from player account
                uint256 back_amount = p.borrowed.add(admin_reward).add(sponsor_reward);
                require(revvToken.transferFrom(playerIndices[i], address(this), back_amount), "failed to gather reward");

                // update player status
                p.borrowed = 0;
                p.total_rewards = p.total_rewards.add(reward_this_tour);    
                p.balance = p.balance.add(reward_this_tour.sub(back_amount));

                //update tournament status
                t.total_admin_rewards = t.total_admin_rewards.add(admin_reward);
                t.total_sponsor_rewards = t.total_sponsor_rewards.add(sponsor_reward);
            }
        }

        // transfer admin fee to fee address
        if(t.total_admin_rewards > 0) {
            revvToken.transfer(feeAddress, t.total_admin_rewards);
        }

        // rebase LP token
        staketoshiToken.rebase(block.timestamp, int256(t.total_sponsor_rewards));

        // add pool staked amount
        poolBalance = poolBalance.add(t.total_sponsor_rewards);
        
        // end tournament. after that sponsors can withdraw rewards or carry over
        t.active = false;
    }


    // get latest tournament
    function getCurrentTour() private view returns(Tour memory) {
        return tours[currentTourId];
    }
    
    
    
    // *****************************
    // For Player Account **********
    // *****************************
    function nft_setApprovalForAll(address operator, bool approved) external {
        nftToken.setApprovalForAll(operator, approved);
    }

    function nft_safeTransferFrom(address to, uint256 id, uint256 amount, bytes calldata data) external {
        nftToken.safeTransferFrom(msg.sender, to, id, amount, data);
    }
    
    function nft_safeBatchTransferFrom(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external {
        nftToken.safeBatchTransferFrom(msg.sender, to, ids, amounts, data);
    }

    function withdrawRevv(address to, uint256 amount) public onlyPlayer afterEnded {
        player memory p = players[msg.sender];
        require(p.balance >= amount, "insufficient balance");
        require(revvToken.transferFrom(msg.sender, to, amount), "transfer failed");
        p.balance = p.balance.sub(amount);
    }

    function withdrawETH(address payable to) payable public {
        to.transfer(msg.value);
    }

    
    // *****************************
    // For Admin Account ***********
    // *****************************
    function addTournament(string calldata _title, uint256[2] calldata _duration, uint256[2] calldata _lock) external onlyOwner {
        Tour memory t = getCurrentTour();
        require(!t.valid || t.duration[1] < block.timestamp, "only after all tournament ended");

        currentTourId = currentTourId.add(1);
        tours[currentTourId].tour_id = currentTourId;
        tours[currentTourId].title = _title;
        tours[currentTourId].duration = _duration;
        tours[currentTourId].lock_duration = _lock;
        tours[currentTourId].active = true;
        tours[currentTourId].valid = true;
        
        emit addedTournament(currentTourId, _title, _duration, _lock);
    }

    function changeTourTitle(string calldata _title) external beforeStarted {
        Tour memory t = getCurrentTour();
        t.title = _title;
    }


    function verifyPlayer(address account, bool verified) public returns(bool){
        require(msg.sender == owner() || msg.sender == address(KYC), 'only owner or KYC contract');

        if(!players[account].active) {
            players[account].active = true;
            playerIndices.push(account);
        }
        players[account].verified = verified;

        return true;
    }

    function changePlayer(address _old, address _new, uint256[] memory nftIds) public returns(bool) {
        require(msg.sender == owner() || msg.sender == address(KYC), 'only owner or KYC contract');
        if(isVerifiedPlayer(_old) == false) {
            return true;
        }

        //remove player from players list
        players[_new].verified       = players[_old].verified;
        players[_new].active         = players[_old].active;
        players[_new].total_cycles   = players[_old].total_cycles;
        players[_new].borrowed       = players[_old].borrowed;
        players[_new].balance        = players[_old].balance;
        players[_new].total_rewards  = players[_old].total_rewards;
        players[_new].latest_tour_id = players[_old].latest_tour_id;
        players[_new].voting_power   = players[_old].voting_power;

        players[_old].verified = false;
        players[_old].active = false;

        // move Borrows
        for(uint req_id = 1; req_id <= currentBorrowId; req_id++) {
            if(borrows[req_id].player == _old) {
                borrows[req_id].player = _new;
            }
        }

        // move NFT and revv token
        revvToken.transferFrom(_old, _new, revvToken.balanceOf(_old));
        if(nftIds.length > 0) {
            address[] memory accounts = new address[](nftIds.length);
            for(uint i = 0; i < nftIds.length; i++){
                accounts[i] = _old;
            }
            nftToken.safeBatchTransferFrom(_old, _new, nftIds, nftToken.balanceOfBatch(accounts, nftIds), "");
        }

        return true;
    }

    function isVerifiedPlayer(address account) view public returns(bool) {
        return players[account].verified;
    }

    function playersLength() view public returns(uint256) {
        return playerIndices.length;
    }

    function changeFeeAddress(address account) public onlyOwner {
        require(account != address(0), "New fee address is zero address");
        feeAddress = account;
    }

    function changeAdminPercent(uint256 fee) public onlyOwner {
        require(fee < PERCENTS_DIVIDER, "New admin fee is too large");
        adminPercent = fee;
    }

    function changeSponsorPercent(uint256 fee) public onlyOwner {
        require(fee < PERCENTS_DIVIDER, "New sponsor fee is too large");
        sponsorPercent = fee;
    }

    function changeKYCAddress(address _addr) public onlyOwner {
        require(_addr != address(0), "New KYC address is zero address");
        KYC = IStaketoshiKYC(_addr);
    }

    function isContract(address _addr) view private returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }    

    // Modifiers
    modifier onlyHuman() {
        require(!isContract(address(msg.sender)) && tx.origin == msg.sender, "Only for human.");
        _;
    }

    modifier onlyPlayer() {
        require(isVerifiedPlayer(msg.sender), "Only for verified player.");
        _;
    }

    modifier beforeStarted() {
        Tour memory t = getCurrentTour();
        require(t.valid && t.duration[0] <= block.timestamp && t.lock_duration[0] >= block.timestamp, "Only before started");
        _;
    }

    modifier notLocked() {
        Tour memory t = getCurrentTour();
        require(t.valid 
            && ((t.duration[0] <= block.timestamp && t.lock_duration[0] >= block.timestamp) 
            || (t.duration[1] >= block.timestamp && t.lock_duration[1] <= block.timestamp)), "Only in while not locked");
        _;
    }

    modifier afterLockEnded() {
        Tour memory t = getCurrentTour();
        require(t.valid && t.duration[1] >= block.timestamp && t.lock_duration[1] <= block.timestamp, "Only after lock ended");
        _;
    }

    modifier afterEnded() {
        Tour memory t = getCurrentTour();
        require(t.valid && t.duration[1] >= block.timestamp && t.lock_duration[1] <= block.timestamp && t.active == false, "Only after ended");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

