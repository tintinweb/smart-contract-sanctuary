pragma solidity ^0.4.13;

contract OracleInterface {
    struct PriceData {
        uint ARTTokenPrice;
        uint blockHeight;
    }

    mapping(uint => PriceData) public historicPricing;
    uint public index;
    address public owner;
    uint8 public decimals;

    function setPrice(uint price) public returns (uint _index) {}

    function getPrice() public view returns (uint price, uint _index, uint blockHeight) {}

    function getHistoricalPrice(uint _index) public view returns (uint price, uint blockHeight) {}

    event Updated(uint indexed price, uint indexed index);
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20Interface is ERC20Basic {
    uint8 public decimals;
}

contract HasNoTokens {

 /**
  * @dev Reject all ERC223 compatible tokens
  * @param from_ address The address that is transferring the tokens
  * @param value_ uint256 the amount of the specified token
  * @param data_ Bytes The data passed from the caller.
  */
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

contract DutchAuction is Ownable, HasNoEther, HasNoTokens {

    using SafeMath for uint256;

    /// @notice Auction Data
    uint public min_shares_to_sell;
    uint public max_shares_to_sell;
    uint public min_share_price;
    uint public available_shares;

    bool private fundraise_defined;
    uint public fundraise_max;

    /// @notice Auction status
    state public status = state.pending;
    enum state { pending, active, ended, decrypted, success, failure }

    /// @notice Events
    event Started(uint block_number);
    event BidAdded(uint index);
    event Ended(uint block_number);
    event BidDecrypted(uint index, bool it_will_process);
    event FundraiseDefined(uint min_share_price, uint max);
    event BidBurned(uint index);
    event Decrypted(uint blocknumber, uint bids_decrypted, uint bids_burned);
    event Computed(uint index, uint share_price, uint shares_count);
    event Assigned(uint index, uint shares, uint executed_amout, uint refunded);
    event Refunded(uint index, uint refunded);
    event Success(uint raised, uint share_price, uint delivered_shares);
    event Failure(uint raised, uint share_price);

    event Execution(address destination,uint value,bytes data);
    event ExecutionFailure(address destination,uint value,bytes data);

    /// @notice Token assignment data
    uint public final_share_price;
    uint public computed_fundraise;
    uint public final_fundraise;
    uint public computed_shares_sold;
    uint public final_shares_sold;
    uint public winner_bids;
    uint public assigned_bids;
    uint public assigned_shares;

    /// @notice Bidding data
    struct BidData {
        uint origin_index;
        uint bid_id;
        address investor_address;
        uint share_price;
        uint shares_count;
        uint transfer_valuation;
        uint transfer_token;
        uint asigned_shares_count;
        uint executed_amount;
        bool closed;
    }
    uint public bids_sorted_count;
    uint public bids_sorted_refunded;
    mapping (uint => BidData) public bids_sorted; //Is sorted

    uint public bids_burned_count;
    mapping (uint => uint) public bids_burned;

    uint public bids_ignored_count;
    uint public bids_ignored_refunded;
    mapping (uint => BidData) public bids_ignored;


    uint public bids_decrypted_count;
    mapping (uint => uint) public bids_decrypted;
    uint private bids_reset_count;

    struct Bid {
        // https://ethereum.stackexchange.com/questions/3184/what-is-the-cheapest-hash-function-available-in-solidity#3200
        bytes32 bid_hash;
        uint art_price;
        uint art_price_index;
        bool exist;
        bool is_decrypted;
        bool is_burned;
        bool will_compute;
    }
    uint public bids_count;
    mapping (uint => Bid) public bids;

    uint public bids_computed_cursor;

    uint public shares_holders_count;
    mapping (uint => address) public shares_holders;
    mapping (address => uint) public shares_holders_balance;

    /// @notice External dependencies

    OracleInterface oracle;
    uint public oracle_price_decimals_factor;
    ERC20Interface art_token_contract;
    uint public decimal_precission_difference_factor;

    /// @notice Set up the dutch auction
    /// @param _min_shares_to_sell The minimum amount of asset shares to be sold
    /// @param _max_shares_to_sell The maximum amount of asset shares to be sold
    /// @param _available_shares The total share amount the asset will be divided into
    /// @param _oracle Address of the ART/USD price oracle contract
    /// @param _art_token_contract Address of the ART token contract
    constructor(
        uint _min_shares_to_sell,
        uint _max_shares_to_sell,
        uint _available_shares,
        address _oracle,
        address _art_token_contract
    ) public {
        require(_max_shares_to_sell > 0);
        require(_max_shares_to_sell >= _min_shares_to_sell);
        require(_available_shares >= _max_shares_to_sell);
        require(_oracle != address(0x0));
        owner = msg.sender;
        min_shares_to_sell = _min_shares_to_sell;
        max_shares_to_sell = _max_shares_to_sell;
        available_shares = _available_shares;
        oracle = OracleInterface(_oracle);
        uint256 oracle_decimals = uint256(oracle.decimals());
        oracle_price_decimals_factor = 10**oracle_decimals;
        art_token_contract = ERC20Interface(_art_token_contract);
        uint256 art_token_decimals = uint256(art_token_contract.decimals());
        decimal_precission_difference_factor = 10**(art_token_decimals.sub(oracle_decimals));
    }

    /// @notice Allows configuration of the final parameters needed for
    /// auction end state calculation. This is only allowed once the auction
    /// has closed and no more bids can enter
    /// @param _min_share_price Minimum price accepted for individual asset shares
    /// @param _fundraise_max Maximum cap for fundraised capital
    function setFundraiseLimits(uint _min_share_price, uint _fundraise_max) public onlyOwner{
        require(!fundraise_defined);
        require(_min_share_price > 0);
        require(_fundraise_max > 0);
        require(status == state.ended);
        fundraise_max = _fundraise_max;
        min_share_price = _min_share_price;
        emit FundraiseDefined(min_share_price,fundraise_max);
        fundraise_defined = true;
    }

    /// @notice Starts the auction
    function startAuction() public onlyOwner{
        require(status == state.pending);
        status = state.active;
        emit Started(block.number);
    }

    /// @notice Ends the auction, preventing new bids from entering
    function endAuction() public onlyOwner{
        require(status == state.active);
        status = state.ended;
        emit Ended(block.number);
    }

    /// @notice Append an encrypted bid to the auction. This allows the contract
    /// to keep a count on how many bids it has, while staying ignorant of the 
    /// bid contents.
    function appendEncryptedBid(bytes32 _bid_hash, uint price_index) public onlyOwner returns (uint index){
        require(status == state.active);
        uint art_price;
        uint art_price_blockHeight;
        (art_price, art_price_blockHeight) = oracle.getHistoricalPrice(price_index);
        bids[bids_count] = Bid(_bid_hash, art_price, price_index, true, false, false, false);
        index = bids_count;
        emit BidAdded(bids_count++);
    }

    /// @notice Helper function for calculating a bid&#39;s hash.
    function getBidHash(uint nonce, uint bid_id, address investor_address, uint share_price, uint shares_count) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(nonce, bid_id, investor_address, share_price, shares_count));
    }

    /// @notice Allows the "burning" of a bid, for cases in which a bid was corrupted and can&#39;t be decrypted.
    /// "Burnt" bids do not participate in the final calculations for auction participants
    /// @param _index Indicates the index of the bid to be burnt
    function burnBid(uint _index) public onlyOwner {
        require(status == state.ended);
        require(bids_sorted_count == 0);
        require(bids[_index].exist == true);
        require(bids[_index].is_decrypted == false);
        require(bids[_index].is_burned == false);
        
        bids_burned[bids_burned_count] = _index;
        bids_burned_count++;
        
        bids_decrypted[bids_decrypted_count] = _index;
        bids_decrypted_count++;

        bids[_index].is_burned = true;
        emit BidBurned(_index);
    }

    /// @notice Appends the bid&#39;s data to the contract, for use in the final calculations
    /// Once all bids are appended, the auction is locked and changes its state to "decrypted"
    /// @dev Bids MUST be appended in order of asset valuation,
    /// since the contract relies on off-chain sorting and checks if the order is correct
    /// @param _nonce Bid parameter
    /// @param _index Bid&#39;s index inside the contract
    /// @param _bid_id Bid parameter
    /// @param _investor_address Bid parameter - address of the bid&#39;s originator
    /// @param _share_price Bid parameter - estimated value of the asset&#39;s share price
    /// @param _shares_count Bid parameter - amount of shares bid for
    /// @param _transfered_token Bid parameter - amount of ART tokens sent with the bid
    function appendDecryptedBid(uint _nonce, uint _index, uint _bid_id, address _investor_address, uint _share_price, uint _shares_count, uint _transfered_token) onlyOwner public {
        require(status == state.ended);
        require(fundraise_defined);
        require(bids[_index].exist == true);
        require(bids[_index].is_decrypted == false);
        require(bids[_index].is_burned == false);
        require(_share_price > 0);
        require(_shares_count > 0);
        require(_transfered_token >= convert_valuation_to_art(_shares_count.mul(_share_price),bids[_index].art_price));
        
        if (bids_sorted_count > 0){
            BidData memory previous_bid_data = bids_sorted[bids_sorted_count-1];
            require(_share_price <= previous_bid_data.share_price);
            if (_share_price == previous_bid_data.share_price){
                require(_index > previous_bid_data.origin_index);
            }
        }
        
        require(
            getBidHash(_nonce, _bid_id,_investor_address,_share_price,_shares_count) == bids[_index].bid_hash
        );
        
        uint _transfer_amount = _share_price.mul(_shares_count);
        
        BidData memory bid_data = BidData(_index, _bid_id, _investor_address, _share_price, _shares_count, _transfer_amount, _transfered_token, 0, 0, false);
        bids[_index].is_decrypted = true;
        
        if (_share_price >= min_share_price){
            bids[_index].will_compute = true;
            bids_sorted[bids_sorted_count] = bid_data;
            bids_sorted_count++;
            emit BidDecrypted(_index,true);
        }else{
            bids[_index].will_compute = false;
            bids_ignored[bids_ignored_count] = bid_data;
            bids_ignored_count++;
            emit BidDecrypted(_index,false);
        }
        bids_decrypted[bids_decrypted_count] = _index;
        bids_decrypted_count++;
        if(bids_decrypted_count == bids_count){
            emit Decrypted(block.number, bids_decrypted_count.sub(bids_burned_count), bids_burned_count);
            status = state.decrypted;
        }
    }

    /// @notice Allows appending multiple decrypted bids (in order) at once.
    /// @dev Parameters are the same as appendDecryptedBid but in array format.
    function appendDecryptedBids(uint[] _nonce, uint[] _index, uint[] _bid_id, address[] _investor_address, uint[] _share_price, uint[] _shares_count, uint[] _transfered_token) public onlyOwner {
        require(_nonce.length == _index.length);
        require(_index.length == _bid_id.length);
        require(_bid_id.length == _investor_address.length);
        require(_investor_address.length == _share_price.length);
        require(_share_price.length == _shares_count.length);
        require(_shares_count.length == _transfered_token.length);
        require(bids_count.sub(bids_decrypted_count) > 0);
        for (uint i = 0; i < _index.length; i++){
            appendDecryptedBid(_nonce[i], _index[i], _bid_id[i], _investor_address[i], _share_price[i], _shares_count[i], _transfered_token[i]);
        }
    }

    /// @notice Allows resetting the entire bid decryption/appending process
    /// in case a mistake was made and it is not possible to continue appending further bids.
    function resetAppendDecryptedBids(uint _count) public onlyOwner{
        require(status == state.ended);
        require(bids_decrypted_count > 0);
        require(_count > 0);
        if (bids_reset_count == 0){
            bids_reset_count = bids_decrypted_count;
        }
        uint count = _count;
        if(bids_reset_count < count){
            count = bids_reset_count;
        }

        do {
            bids_reset_count--;
            bids[bids_decrypted[bids_reset_count]].is_decrypted = false;
            bids[bids_decrypted[bids_reset_count]].is_burned = false;
            bids[bids_decrypted[bids_reset_count]].will_compute = false;
            count--;
        } while(count > 0);
        
        if (bids_reset_count == 0){
            bids_sorted_count = 0;
            bids_ignored_count = 0;
            bids_decrypted_count = 0;
            bids_burned_count = 0;
        }
    }

    /// @notice Performs the computation of auction winners and losers.
    /// Also, determines if the auction is successful or failed.
    /// Bids which place the asset valuation below the minimum fundraise cap
    /// as well as bids below the final valuation are marked as ignored or "loser" respectively
    /// and do not count towards the process.
    /// @dev Since this function is resource intensive, computation is done in batches
    /// of `_count` bids, so as to not encounter an OutOfGas exception in the middle
    /// of the process.
    /// @param _count Amount of bids to be processed in this run.
    function computeBids(uint _count) public onlyOwner{
        require(status == state.decrypted);
        require(_count > 0);
        uint count = _count;
        // No bids
        if (bids_sorted_count == 0){
            status = state.failure;
            emit Failure(0, 0);
            return;
        }
        //bids_computed_cursor: How many bid already processed
        //bids_sorted_count: How many bids can compunte
        require(bids_computed_cursor < bids_sorted_count);
        
        //bid: Auxiliary variable
        BidData memory bid;

        do{
            //bid: Current bid to compute
            bid = bids_sorted[bids_computed_cursor];
            //if only one share of current bid leave us out of fundraise limitis, ignore the bid
            //computed_shares_sold: Sumarize shares sold
            if (bid.share_price.mul(computed_shares_sold).add(bid.share_price) > fundraise_max){
                if(bids_computed_cursor > 0){
                    bids_computed_cursor--;
                }
                bid = bids_sorted[bids_computed_cursor];
                break;
            }
            //computed_shares_sold: Sumarize cumpued shares
            computed_shares_sold = computed_shares_sold.add(bid.shares_count);
            //computed_fundraise: Sumarize fundraise
            computed_fundraise = bid.share_price.mul(computed_shares_sold);
            emit Computed(bid.origin_index, bid.share_price, bid.shares_count);
            //Next bid
            bids_computed_cursor++;
            count--;
        }while(
            count > 0 && //We have limite to compute
            bids_computed_cursor < bids_sorted_count && //We have more bids to compute 
            (
                computed_fundraise < fundraise_max && //Fundraise is more or equal to max
                computed_shares_sold < max_shares_to_sell //Assigned shares are more or equal to max
            )
        );

        if (
            bids_computed_cursor == bids_sorted_count ||  //All bids computed
            computed_fundraise >= fundraise_max ||//Fundraise is more or equal to max
            computed_shares_sold >= max_shares_to_sell//Max shares raised
        ){
            
            final_share_price = bid.share_price;
            
            //More than max shares
            if(computed_shares_sold >= max_shares_to_sell){
                computed_shares_sold = max_shares_to_sell;//Limit shares
                computed_fundraise = final_share_price.mul(computed_shares_sold);
                winner_bids = bids_computed_cursor;
                status = state.success;
                emit Success(computed_fundraise, final_share_price, computed_shares_sold);
                return;            
            }

            //Max fundraise is raised
            if(computed_fundraise.add(final_share_price.mul(1)) >= fundraise_max){//More than max fundraise
                computed_fundraise = fundraise_max;//Limit fundraise
                winner_bids = bids_computed_cursor;
                status = state.success;
                emit Success(computed_fundraise, final_share_price, computed_shares_sold);
                return;
            }
            
            //All bids computed
            if (bids_computed_cursor == bids_sorted_count){
                if (computed_shares_sold >= min_shares_to_sell){
                    winner_bids = bids_computed_cursor;
                    status = state.success;
                    emit Success(computed_fundraise, final_share_price, computed_shares_sold);
                    return;
                }else{
                    status = state.failure;
                    emit Failure(computed_fundraise, final_share_price);
                    return;
                }
            }
        }
    }

    /// @notice Helper function that calculates the valuation of the asset
    /// in terms of an ART token quantity.
    function convert_valuation_to_art(uint _valuation, uint _art_price) view public returns(uint amount){
        amount = ((
                _valuation.mul(oracle_price_decimals_factor)
            ).div(
                _art_price
            )).mul(decimal_precission_difference_factor);
    }

    /// @notice Performs the refund of the ignored bids ART tokens
    /// @dev Since this function is resource intensive, computation is done in batches
    /// of `_count` bids, so as to not encounter an OutOfGas exception in the middle
    /// of the process.
    /// @param _count Amount of bids to be processed in this run.
    function refundIgnoredBids(uint _count) public onlyOwner{
        require(status == state.success || status == state.failure);
        uint count = _count;
        if(bids_ignored_count < bids_ignored_refunded.add(count)){
            count = bids_ignored_count.sub(bids_ignored_refunded);
        }
        require(count > 0);
        uint cursor = bids_ignored_refunded;
        bids_ignored_refunded = bids_ignored_refunded.add(count);
        BidData storage bid;
        while (count > 0) {
            bid = bids_ignored[cursor];
            if(bid.closed){
                continue;
            }
            bid.closed = true;
            art_token_contract.transfer(bid.investor_address, bid.transfer_token);
            emit Refunded(bid.origin_index, bid.transfer_token);
            cursor ++;
            count --;
        }
    }

    /// @notice Performs the refund of the "loser" bids ART tokens
    /// @dev Since this function is resource intensive, computation is done in batches
    /// of `_count` bids, so as to not encounter an OutOfGas exception in the middle
    /// of the process.
    /// @param _count Amount of bids to be processed in this run.
    function refundLosersBids(uint _count) public onlyOwner{
        require(status == state.success || status == state.failure);
        uint count = _count;
        if(bids_sorted_count.sub(winner_bids) < bids_sorted_refunded.add(count)){
            count = bids_sorted_count.sub(winner_bids).sub(bids_sorted_refunded);
        }
        require(count > 0);
        uint cursor = bids_sorted_refunded.add(winner_bids);
        bids_sorted_refunded = bids_sorted_refunded.add(count);
        BidData memory bid;
        while (count > 0) {
            bid = bids_sorted[cursor];
            if(bid.closed){
                continue;
            }
            bids_sorted[cursor].closed = true;
            art_token_contract.transfer(bid.investor_address, bid.transfer_token);
            emit Refunded(bid.origin_index, bid.transfer_token);
            cursor ++;
            count --;
        }
    }

    /// @notice Calculates how many shares are assigned to a bid.
    /// @param _shares_count Amount of shares bid for.
    /// @param _transfer_valuation Unused parameter
    /// @param _final_share_price Final share price calculated from all winning bids
    /// @param _art_price Price of the ART token
    /// @param transfer_token Amount of ART tokens transferred with the bid
    function calculate_shares_and_return(uint _shares_count, uint _share_price, uint _transfer_valuation, uint _final_share_price, uint _art_price, uint transfer_token) view public 
        returns(
            uint _shares_to_assign,
            uint _executed_amount_valuation,
            uint _return_amount
        ){
        if(assigned_shares.add(_shares_count) > max_shares_to_sell){
            _shares_to_assign = max_shares_to_sell.sub(assigned_shares);
        }else{
            _shares_to_assign = _shares_count;
        }
        _executed_amount_valuation = _shares_to_assign.mul(_final_share_price);
        if (final_fundraise.add(_executed_amount_valuation) > fundraise_max){
            _executed_amount_valuation = fundraise_max.sub(final_fundraise);
            _shares_to_assign = _executed_amount_valuation.div(_final_share_price);
            _executed_amount_valuation = _shares_to_assign.mul(_final_share_price);
        }
        uint _executed_amount = convert_valuation_to_art(_executed_amount_valuation, _art_price);
        _return_amount = transfer_token.sub(_executed_amount);
    }


    /// @notice Assign the asset share tokens to winner bid&#39;s authors
    /// @dev Since this function is resource intensive, computation is done in batches
    /// of `_count` bids, so as to not encounter an OutOfGas exception in the middle
    /// of the process.
    /// @param _count Amount of bids to be processed in this run.
    function assignShareTokens(uint _count) public onlyOwner{
        require(status == state.success);
        uint count = _count;
        if(winner_bids < assigned_bids.add(count)){
            count = winner_bids.sub(assigned_bids);
        }
        require(count > 0);
        uint cursor = assigned_bids;
        assigned_bids = assigned_bids.add(count);
        BidData storage bid;

        while (count > 0) {
            bid = bids_sorted[cursor];
            uint _shares_to_assign;
            uint _executed_amount_valuation;
            uint _return_amount;
            (_shares_to_assign, _executed_amount_valuation, _return_amount) = calculate_shares_and_return(
                bid.shares_count,
                bid.share_price,
                bid.transfer_valuation,
                final_share_price,
                bids[bid.origin_index].art_price,
                bid.transfer_token
            );
            bid.executed_amount = _executed_amount_valuation;
            bid.asigned_shares_count = _shares_to_assign;
            assigned_shares = assigned_shares.add(_shares_to_assign);
            final_fundraise = final_fundraise.add(_executed_amount_valuation);
            final_shares_sold = final_shares_sold.add(_shares_to_assign);
            if(_return_amount > 0){
                art_token_contract.transfer(bid.investor_address, _return_amount);
            }
            bid.closed = true;
            if (shares_holders_balance[bid.investor_address] == 0){
                shares_holders[shares_holders_count++] = bid.investor_address;
            }
            emit Assigned(bid.origin_index,_shares_to_assign, _executed_amount_valuation, _return_amount);
            shares_holders_balance[bid.investor_address] = shares_holders_balance[bid.investor_address].add(_shares_to_assign);
            cursor ++;
            count --;
        }
    }

    /**
    * @dev Return share balance of sender
    * @return uint256 share_balance
    */
    function getShareBalance() view public returns (uint256 share_balance){
        require(status == state.success);
        require(winner_bids == assigned_bids);
        share_balance = shares_holders_balance[msg.sender];
    }

    /**
    * @dev Reclaim all (Except ART) ERC20Basic compatible tokens
    * @param token ERC20Basic The address of the token contract
    */
    function reclaimToken(ERC20Basic token) external onlyOwner {
        require(token != art_token_contract);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }

    function reclaim_art_token() external onlyOwner {
        require(status == state.success || status == state.failure);
        require(winner_bids == assigned_bids);
        uint256 balance = art_token_contract.balanceOf(this);
        art_token_contract.transfer(owner, balance); 
    }

    /// @notice Proxy function which allows sending of transactions
    /// in behalf of the contract
    function executeTransaction(
        address destination,
        uint value,
        bytes data
    )
        public
        onlyOwner
    {
        if (destination.call.value(value)(data))
            emit Execution(destination,value,data);
        else
            emit ExecutionFailure(destination,value,data);
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}