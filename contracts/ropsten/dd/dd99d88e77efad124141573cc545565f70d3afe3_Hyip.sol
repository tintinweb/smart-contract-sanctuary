/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

// File: OpenZeppelin/contracts/token/ERC777/IERC777.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destoys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// File: OpenZeppelin/contracts/introspection/IERC1820Registry.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as `account`'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     *  @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     *  @param account Address of the contract for which to update the cache.
     *  @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not.
     *  If the result is not cached a direct lookup on the contract address is performed.
     *  If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     *  {updateERC165Cache} with the contract address.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     *  @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     *  @param account Address of the contract to check.
     *  @param interfaceId ERC165 interface to check.
     *  @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// File: OpenZeppelin/contracts/token/ERC777/IERC777Recipient.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// File: SeekHYIP.sol

// V1.3
// Ypgraded to support token deposit
// Works with ERC 777 token




pragma solidity ^0.5.0;

contract Hyip is IERC777Recipient{
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    IERC777 private _token;
    event DoneDeposit(address operator, address from, address to, uint256 amount, bytes userData, bytes operatorData);
    using SafeMath for uint256;
    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 time;
    }

    struct Player {
        address referral;
        uint256 dividends;
        uint256 last_payout;
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 total_referral_bonus;
        PlayerDeposit[] deposits;
        mapping(uint8 => uint256) referrals_per_level;
        uint256 forRefComp;
    }

    address payable public owner;
    address payable public marketing;

    uint8 public investment_days;
    uint256 public investment_perc;
    uint256 public refCompetitionAmount;
    uint256 public totalCompetitionAmount;
    uint256 public contractStep;
    uint256 public total_investors;
    uint256 public total_invested;
    uint256 public total_withdrawn;
    uint256 public total_referral_bonus;
    uint256 public full_release;
    uint8 public currentRound;
    address[] public allRefs;

    uint8[] public referral_bonuses;
    struct Leaderboard {
            uint256 count;
            address payable addr;
        }

    Leaderboard[10] public topSponsors;
    Leaderboard[10] public previousInfo;

    mapping(address => Player) public players;
    mapping(address => address) public reflist;
    event Deposit(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event Reinvest(address indexed addr, uint256 amount);
    event ReferralPayout(address indexed addr, uint256 amount, uint8 level);

    constructor(address payable marketingAddress, address token) public {
        owner = msg.sender;
        _token = IERC777(token);
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        marketing = marketingAddress;
        investment_days = 210;
        investment_perc = 210;
        refCompetitionAmount = 0;
        totalCompetitionAmount = 0;
        contractStep = 100000000000;
        currentRound = 0;

        referral_bonuses.push(100);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);
        referral_bonuses.push(50);

        full_release = 1600990000; //start date
        for (uint8 i = 0; i< 10; i++)
        {
            topSponsors[i].count = 1;
            topSponsors[i].addr = owner;
        }
    }
    function refCompetition() internal {
        topSponsors[0].addr.transfer(refCompetitionAmount.mul(30).div(100));
        topSponsors[1].addr.transfer(refCompetitionAmount.mul(20).div(100));
        topSponsors[2].addr.transfer(refCompetitionAmount.mul(15).div(100));
        topSponsors[3].addr.transfer(refCompetitionAmount.mul(8).div(100));
        topSponsors[4].addr.transfer(refCompetitionAmount.mul(7).div(100));
        topSponsors[5].addr.transfer(refCompetitionAmount.mul(6).div(100));
        topSponsors[6].addr.transfer(refCompetitionAmount.mul(5).div(100));
        topSponsors[7].addr.transfer(refCompetitionAmount.mul(4).div(100));
        topSponsors[8].addr.transfer(refCompetitionAmount.mul(3).div(100));
        topSponsors[9].addr.transfer(refCompetitionAmount.mul(2).div(100));
        totalCompetitionAmount += refCompetitionAmount;
        previousInfo = topSponsors;
        refCompetitionAmount = 0;
        currentRound++;
        uint256 len = allRefs.length;
        for(uint256 i=0; i<len;i++){
            players[allRefs[i]].forRefComp = 0;
        }
        for (uint8 i = 0; i< 10; i++)
        {
            topSponsors[i].count = 1;
            topSponsors[i].addr = owner;
        }
    }
    function setref(address ref) external {
        require(msg.sender != ref,"Self referring not allowed");
        require(reflist[msg.sender] == address(0), "Referral already set");
        reflist[msg.sender] = ref;
    }
    
    function tokensReceived(address operator, address from, address to, uint256 amount, bytes calldata userData, bytes calldata operatorData) external {
        require(msg.sender == address(_token), "Simple777Recipient: Invalid token");
        if(reflist[from] == address(0)){
            reflist[from] = owner;
        }
        deposit(from,amount,reflist[from]);
    }
    
    function deposit(address sender, uint256 amt, address _referral) internal {
        require(uint256(block.timestamp) > full_release, "Not launched");
        require(amt >= 1e7, "Zero amount");
        require(amt >= 100000000, "Minimal deposit: 100 TOKEN"); //Edit here according to your need
        require(amt <= 1000000000000, "Maximal deposit: 1000000 TOKEN"); //Edit here according to your need
        Player storage player = players[sender];
        require(player.deposits.length < 100,"Max 100 deposits per address");

        _setReferral(sender, _referral);

        player.deposits.push(PlayerDeposit({
            amount: amt,
            totalWithdraw: 0,
            time: uint256(block.timestamp)
        }));

        if(player.total_invested == 0x0){
            total_investors += 1;
        }

        player.total_invested += amt;
        total_invested += amt;

        _referralPayout(sender, amt);

        _token.send(owner,amt.mul(3).div(100),"Owner Share"); // 3% for owner
        _token.send(marketing,amt.mul(6).div(100),"Marketing Share"); // 6% for marketing
        refCompetitionAmount += amt.mul(1).div(100); // 1% for ref competition
        if(refCompetitionAmount >= contractStep){
            refCompetition();
        }

        emit Deposit(sender, amt);
    }

    function _setReferral(address _addr, address _referral) private {
        if(players[_addr].referral == address(0)) {
            players[_addr].referral = _referral;
            players[_referral].forRefComp++;
            uint256 count = allRefs.length;
            bool flag = false;
            for(uint256 i=0;i<count;i++){
                if(allRefs[i]==_referral){
                    flag = true;
                }
            }
            if(!flag){
                allRefs.push(_referral);
            }
            bool check = checkSponsor(_referral);
            for(uint8 i = 0; i < 21; i++) {
                players[_referral].referrals_per_level[i]++;
                _referral = players[_referral].referral;
                if(_referral == address(0)) break;
            }
        }
    }
    function checkSponsor(address _add) private returns(bool) {
        address payable[10] memory initarray;
        uint8 i;
        for(i=0;i<10;i++){
            initarray[i] = topSponsors[i].addr;
        }
        uint256 sponsors = players[_add].forRefComp;
        if(topSponsors[9].count > sponsors ){
            return false;
        }
        address payable tempaddr = address(uint160(_add));
        if(sponsors > topSponsors[0].count){
            topSponsors[0].count = sponsors;
            topSponsors[0].addr = tempaddr;
            for(i=1;i<10;i++){
                topSponsors[i].addr = initarray[i-1];
            }
        }
        else if(sponsors > topSponsors[1].count){
            topSponsors[1].count = sponsors;
            topSponsors[1].addr = tempaddr;
            for(i=2;i<10;i++){
                topSponsors[i].addr = initarray[i-1];
            }
        }
        else if(sponsors > topSponsors[2].count){
            topSponsors[2].count = sponsors;
            topSponsors[2].addr = tempaddr;
            for(i=3;i<10;i++){
                topSponsors[i].addr = initarray[i-1];
            }
        }
        else if(sponsors > topSponsors[3].count){
            topSponsors[3].count = sponsors;
            topSponsors[3].addr = tempaddr;
            for(i=4;i<10;i++){
                topSponsors[i].addr = initarray[i-1];
            }
        }
        else if(sponsors > topSponsors[4].count){
            topSponsors[4].count = sponsors;
            topSponsors[4].addr = tempaddr;
            for(i=5;i<10;i++){
                topSponsors[i].addr = initarray[i-1];
            }
        }
        else if(sponsors > topSponsors[5].count){
            topSponsors[5].count = sponsors;
            topSponsors[5].addr = tempaddr;
            for(i=6;i<10;i++){
                topSponsors[i].addr = initarray[i-1];
            }
        }
        else if(sponsors > topSponsors[6].count){
            topSponsors[6].count = sponsors;
            topSponsors[6].addr = tempaddr;
            for(i=7;i<10;i++){
                topSponsors[i].addr = initarray[i-1];
            }
        }
        else if(sponsors > topSponsors[7].count){
            topSponsors[7].count = sponsors;
            topSponsors[7].addr = tempaddr;
            for(i=8;i<10;i++){
                topSponsors[i].addr = initarray[i-1];
            }
        }
        else if(sponsors > topSponsors[8].count){
            topSponsors[8].count = sponsors;
            topSponsors[8].addr = tempaddr;
            for(i=9;i<10;i++){
                topSponsors[i].addr = initarray[i-1];
            }
        }
        else{
            topSponsors[9].count = sponsors;
            topSponsors[9].addr = tempaddr;
        }
        return true;
    }

    function _referralPayout(address _addr, uint256 _amount) private {
        address payable ref =  address(uint160(players[_addr].referral));
        uint256 bonus;
        for(uint8 i = 0; i < 21; i++) {
            if(ref == address(0)) break;
            if(i== 0){
            bonus = _amount * referral_bonuses[i] / 1000; 
            }
            else{
                bonus = bonus * referral_bonuses[i] / 1000;
            }
            if(bonus < 10000 ) break;
            players[ref].total_referral_bonus += bonus;
            total_referral_bonus += bonus;
            _token.send(ref,bonus,"Referral Bonus");
            emit ReferralPayout(ref, bonus, (i+1));
            ref =  address(uint160(players[ref].referral));
        }
    }

    function withdraw() payable external {
        require(uint256(block.timestamp) > full_release, "Not launched");
        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.dividends > 0, "Zero amount");

        uint256 amount = player.dividends;

        player.dividends = 0;
        player.total_withdrawn += amount;
        total_withdrawn += amount;

        _token.send(msg.sender,amount,"Payout");

        emit Withdraw(msg.sender, amount);
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if(payout > 0) {
            _updateTotalPayout(_addr);
            players[_addr].last_payout = uint256(block.timestamp);
            players[_addr].dividends += payout;
        }
    }


    function _updateTotalPayout(address _addr) private{
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                player.deposits[i].totalWithdraw += dep.amount * (to - from) * investment_perc / investment_days / 8640000;
            }
        }
    }

    function payoutOf(address _addr) view external returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            PlayerDeposit storage dep = player.deposits[i];

            uint256 time_end = dep.time + investment_days * 86400;
            uint256 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint256 to = block.timestamp > time_end ? time_end : uint256(block.timestamp);

            if(from < to) {
                value += dep.amount * (to - from) * investment_perc / investment_days / 8640000;
            }
        }

        return value;
    }

    function getContractInfo() view external returns(uint256 _total_invested, uint256 _total_investors, uint256 _total_withdrawn, uint256 _total_referral_bonus, uint256 contractBalance,uint256 total_bonus) {
        return (total_invested, total_investors, total_withdrawn, total_referral_bonus, address(this).balance, totalCompetitionAmount);
    }

    function getUserInfo(address _addr) view external returns(uint256 for_withdraw, uint256 invested, uint256 withdrawn, uint256 referral_bonus, uint256[8] memory referrals, uint8 position, uint256 bonus) {
        Player storage player = players[_addr];
        uint256 payout = this.payoutOf(_addr);
        for(uint8 i = 0; i < 21; i++) {
            referrals[i] = player.referrals_per_level[i];
        }
        uint8 standing = 0;
        for(uint8 i=0; i<10;i++){
            if(topSponsors[i].addr == _addr){
                standing = i+1;
            }
        }
        return (
            payout + player.dividends,
            player.total_invested,
            player.total_withdrawn,
            player.total_referral_bonus,
            referrals,
            standing,
            refCompetitionAmount
        );
    }

    function getUserDeposits(address _addr) view external returns(uint256[] memory endTimes, uint256[] memory amounts, uint256[] memory totalWithdraws) {
        Player storage player = players[_addr];
        uint256[] memory _endTimes = new uint256[](player.deposits.length);
        uint256[] memory _amounts = new uint256[](player.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](player.deposits.length);

        for(uint256 i = 0; i < player.deposits.length; i++) {
          PlayerDeposit storage dep = player.deposits[i];

          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.totalWithdraw;
          _endTimes[i] = dep.time + investment_days * 86400;
        }
        return (
          _endTimes,
          _amounts,
          _totalWithdraws
        );
    }
    function getUserReferralInfo(address _addr) view external returns( uint256 refs, uint256[] memory refperlevel ){
        uint256 total = 0;
        for(uint8 i=0; i<21;i++){
            refperlevel[i] = players[_addr].referrals_per_level[i];
            total += players[_addr].referrals_per_level[i];
        }
        return(
            total,
            refperlevel
            );
        
    }
    function getContestInfo() view external returns( uint256 amount, address[10] memory  currentadd, address[10] memory previousadd){
        for(uint8 i=0;i<10;i++){
            currentadd[i] = topSponsors[i].addr;
            previousadd[i] = previousInfo[i].addr;
        }
        return(
          refCompetitionAmount,
          currentadd,
          previousadd
        );
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}