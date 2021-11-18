// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BettingOperator {
    
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    // This is a hash of the json of all the bettingItems
    // Once deployed, the betters and referees depend on this hash to verify their source of truth
    // use EIP 712 for typed structured data
    uint256 public roothashOfbettingItems;
    address public OBPToken;
    //operator
    address public owner;
    address public court;
    //defined an invited referee
    address public referee;
    uint256 public refereeValueAtStake; // OBP token locked for this Operator

    //defined and injected by the deployer
    uint256 public feeToOperator;
    uint256 public feeToReferee;
    uint256 public feeToCourt;
    //available amount to be claimed
    uint256 public unclaimedFeeToOperator;
    uint256 public unclaimedFeeToReferee;
    uint256 public unclaimedFeeToCourt;
    //accepted token
    address public betToken;

    bool public canWithdraw = false;
    //verify by an Referee
    bool public verified = false;
    bool public setreferee = false;
    bool public setbettoken = false;
    //
    mapping (uint256 => Pool) public bettingItems;

    struct Pool{
        //current total bet
        uint256 poolSize;
        //bettor => amount 
        mapping(address => uint256) bettors;
        // exp : PoolSize: (Pool1 : 1000), (Pool2: 1000)
        // then the poolPayout can look like (Pool1: 2000, Pool2: 0), (Pool1: 1500, Pool2: 500) etc
        uint256 payout;
        bool isClosed;
    }    
    // there would be a checking when Referee InjectResult so that the total payout cannot be bigger than the total bet 
    uint256 public totalReleasedPayout;
    // money that is claimed by bettor
    uint256 public totalClaimedPayout;
    uint256 public totalOperatorBet;
    uint256 public maxBetLimit;

    //snapshot upon confiscation
    uint256 public totalUnclaimedPayoutAfterConfiscation;
    
    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'OBP: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor (address _OBPToken, address _owner, uint256 _roothashOfbettingItems, address _court, uint256 _feeToOperator, uint256 _feeToReferee, uint256 _feeToCourt) {
        OBPToken = _OBPToken;
        owner = _owner;
        roothashOfbettingItems = _roothashOfbettingItems;
        court = _court;
        feeToOperator = _feeToOperator;
        feeToReferee = _feeToReferee;
        feeToCourt = _feeToCourt;
    }

    function setBetToken(address _bettoken) onlyOwner external {
        require(setbettoken == false, "setBetToken:: bettoken is already set") ;
        setbettoken = true;
        betToken = _bettoken;
    }
    function setReferee(address _referee) onlyOwner external {
        require(setreferee == false, "setReferee:: referee is already set") ;
        setreferee = true;
        referee = _referee;
    }
    function decodeResult(uint256 _encodedResult) public pure returns(uint112 item, uint112 payout, uint32 lastupdatedtime){
        item = uint112(_encodedResult>> 144);
        payout = uint112(_encodedResult >> 32);
        lastupdatedtime = uint32(_encodedResult);
    }

    modifier onlyReferee() {
        require(msg.sender == referee);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyCourt() {
        require(msg.sender == court);
        _;
    }

    function withdrawOperatorFee(uint256 _amount, address _to)  external onlyOwner {
        require(unclaimedFeeToOperator - _amount >= 0, "withdrawOperatorFee:: THAT IS NO UNCLAIMED AMOUTN");
        unclaimedFeeToOperator -= _amount;
        (bool result) = IERC20(betToken).transfer(_to, _amount);
        require(result, "withdrawOperatorFee: TRANSFER_FAILED");
        // when operator withdraws fee, they are also responsible for settling the fee to the referee as well as the court.
        withdrawRefereeFee(unclaimedFeeToReferee);
        withdrawCourtFee(unclaimedFeeToCourt);

    }

    function withdrawRefereeFee(uint256 _amount) public {
        require(unclaimedFeeToReferee - _amount >= 0, "withdrawRefereeFee:: THAT IS NO UNCLAIMED AMOUTN");
        unclaimedFeeToReferee -= _amount;
        (bool result) = IERC20(betToken).transfer(referee, _amount);
        require(result, "withdrawRefereeFee: TRANSFER_FAILED");
    }

    function withdrawCourtFee(uint256 _amount) public {
        require(unclaimedFeeToCourt - _amount >= 0, "withdrawCourtFee:: THAT IS NO UNCLAIMED AMOUTN");
        unclaimedFeeToCourt -= _amount;
        (bool result) = IERC20(betToken).transfer(court, _amount);      
        require(result, "withdrawCourtFee: TRANSFER_FAILED");
    }


    function checkPoolPayout(uint256 _item) public view returns(uint256) {
        return bettingItems[_item].payout;
    }
    
    function checkPayoutByAddress(address _address, uint256 _item) public view returns(uint256) {
        return bettingItems[_item].bettors[_address] * bettingItems[_item].payout / bettingItems[_item].poolSize;
    }


    function verify(uint256 _refereeValueAtStake, uint256 _maxBet) external onlyReferee {
        require(verified == false, "verify:: ALREADY VERIFIERD");
        verified = true;
        refereeValueAtStake = _refereeValueAtStake;
        maxBetLimit = _maxBet;
    }
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    //directly place bet without going through Router,if the operator is approved for moving yr BetToken.
    // oherwise approve the BettingRouter for the betToken to achieve one-off aproval.
    function placeBet(uint item, uint amount, address bettor, bool isThroughRouter) lock external {
        require(bettingItems[item].isClosed == false, "the betting item is already closed"); 
        require(maxBetLimit - totalOperatorBet > amount, "placeBet:: the maxBet exceeds after taking this bet");
        if (!isThroughRouter) {
            _safeTransferFrom(betToken, bettor, address(this), amount);
        }
        // this line gets the exact amount that is deposited by the bettor
        //1. totalClaimedPayout - money that got drawn by winning bettor
        //2 .totalBet is allBet placed
        //3. unclaimedFee(s) are fee entitled to various parties, they just temporary sits at this address. 
        amount = IERC20(betToken).balanceOf(address(this)) 
        + totalClaimedPayout 
        - totalOperatorBet
        - unclaimedFeeToOperator - unclaimedFeeToReferee - unclaimedFeeToCourt;

        unclaimedFeeToOperator += (amount * feeToOperator) / 10**6;
        unclaimedFeeToReferee += (amount * feeToReferee) / 10**6;        
        unclaimedFeeToCourt += (amount * feeToCourt) / 10**6;

        uint256 Poolamount = amount * ( 10**6 - feeToReferee - feeToOperator - feeToCourt) / 10**6;
        bettingItems[item].bettors[bettor] = Poolamount;
        bettingItems[item].poolSize += Poolamount;
        totalOperatorBet += Poolamount;
    }
    // this is a function to withdraw normally, unless there is OBP compensation, only 1 ERC20 transfer is involved.
    function withdraw(uint item, address _to) external {
        address bettor = msg.sender;
        require(bettingItems[item].isClosed, "the betting item is still open"); 
        require(bettingItems[item].payout > 0, "withdraw:: THERE is no Payout in this item");
        uint256 amount = checkPayoutByAddress(bettor, item);
        uint256 amountOBP = getAmountFromFailedReferee(item, bettor);
        totalClaimedPayout += amount;
        //remove the bet before transferring
        bettingItems[item].bettors[msg.sender] = 0;

        (bool result) = IERC20(betToken).transfer(_to, amount);
        require(result, "withdraw: TRANSFER_FAILED");
        if (amountOBP > 0 ) {
            // this number is non-zero only when OBP is confiscated from referee.
            // if you prefer getting the OBP instead of the payout, pls call withdrawFromFailedReferee(uint256 item, address _to);
            (bool resultToCourt) = IERC20(OBPToken).transfer(court, amountOBP);
            require(resultToCourt, "withdraw: TRANSFER_FAILED"); 
        }
    }

    function injectResult(uint256 item) external onlyReferee {
    (uint112 parsedItem, uint112 parsedPayout,) = decodeResult(item);
    // 0 can be a empty entry pushed from Referee
    if (parsedItem != 0 && bettingItems[item].isClosed == false) {
        // allow an update of payout in case a wrong value is pushed.
        // close is not called in this function for the purpose of changing
        // when an item is closed, bettor starts to claim and there is no way to correct any mistake
        uint256 oldPayout = bettingItems[parsedItem].payout;
        bettingItems[parsedItem].payout = parsedPayout;
        totalReleasedPayout = totalReleasedPayout + parsedPayout - oldPayout;
    }   
    }
    //can be any number of result to be pushed 
    function injectResultBatch(bytes calldata data) external onlyReferee {
        uint256 item;
        //uint256 parsedPayoutLastUpdatedTime;
        bytes memory tmpdata = data;
        for (uint256 i =0; i < tmpdata.length; i+=32) {
            assembly {
                item := mload(add(tmpdata, add(32, i)))
                }
        (uint112 parsedItem, uint112 parsedPayout, uint32 parsedPayoutLastUpdatedTime) = decodeResult(item);
        require(parsedItem >0 , "DEBUGOP");
            // 0 can be a empty entry pushed from Referee
            if (parsedItem != 0 && bettingItems[uint256(item)].isClosed == false) {
                // allow an update of payout in case a wrong value is pushed.
                // close is not called in this function for the purpose of changing
                // when an item is closed, bettor starts to claim and there is no way to correct any mistake
                uint256 oldPayout = bettingItems[parsedItem].payout;
                bettingItems[parsedItem].payout = parsedPayout;
                totalReleasedPayout = totalReleasedPayout + parsedPayout - oldPayout;
            }   
        }
        // assert at last but not in the loop for efficient gas
        require(totalOperatorBet >= totalReleasedPayout ,"injectResult::the released payout is bigger than the total bet");
                // close the item so winner can start claiming:
        //closeItemBatch(data);
    }
    
    function closeItem(uint256 item) external onlyReferee {
        bettingItems[item].isClosed = true;
    }

    function closeItemBatch(bytes calldata data) external onlyReferee {
        uint256 item;
        bytes memory tmpdata = data;
        //this is for closing item only, assuming data is parsed in itemId:payout::timestamp format, skipping every 32 bits that is payout data.
        for (uint i =0; i < tmpdata.length; i+=32) {
            assembly {
                item := mload(add(tmpdata, add(32, i)))
                }
            (uint112 parsedItem, , ) = decodeResult(item);
            bettingItems[parsedItem].isClosed = true;
        }
    }
    function setTotalUnclaimedPayoutAfterConfiscation() external onlyCourt {
        // this is to decide the portion of OBP each unclaimed bettor is eligible for.
        // people who claim their money is not eligible
        totalUnclaimedPayoutAfterConfiscation = totalOperatorBet - totalClaimedPayout;
    }

    function getAmountFromFailedReferee(uint256 item, address bettor) view public returns(uint256) {
        if(totalUnclaimedPayoutAfterConfiscation == 0 ) {return 0;}
        return refereeValueAtStake * bettingItems[item].bettors[bettor] / totalUnclaimedPayoutAfterConfiscation;

    }
    function withdrawFromFailedReferee(uint256 item, address _to) external {
        //OBP is transferred from a failed refererr to this address.
        // once OBP is transferred in, those who hasnt claimed their payout, can decide if they want to claim OBP, or their payout.

        //all bettors WHO HAVENT CLAIMED THEIR PAYOUT get their shares based on their bet.
        // YOU EITHER GET YOUR PAYOUT(NO MATTER U WIN OR LOSS), OR THE OBP compensation.

        // if you get the OBP, your payout is donated to the court.
        // if you get the payout, your OBP is forfeited, and sent back to the court.
        address bettor = msg.sender;
        uint256 _amount = getAmountFromFailedReferee(item, bettor);
        require(_amount > 0, "withdrawFromFailedReferee:: THERE IS NO OBP FOR U");
        // originalBet to be sent to court
        uint256 originalPayout = checkPayoutByAddress(bettor, item);
        //set to 0 first to prevent re-entrance
        bettingItems[item].bettors[bettor] = 0;
        // send bet to court
        if (originalPayout > 0) {
            (bool resultToCourt) = IERC20(betToken).transfer(court, originalPayout);
            require(resultToCourt, "withdraw: TRANSFER_FAILED");
        }
        //take OBP
        (bool result) = IERC20(OBPToken).transfer(_to, _amount);
        require(result, "withdraw: TRANSFER_FAILED");
        

    }




}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./BettingOperator.sol";


contract Referee {
    // (contributers => amount)
    //bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transferfrom(address,address,uint256)')));
    constructor(uint256 _arbitrationTime, address _court, address _owner, address _OBPToken) {
        court = _court;
        arbitrationTime = _arbitrationTime;
        owner = _owner;
        OBPToken = _OBPToken;
    }

    // a Result is encoded in uint256 to save storage
    // struct result {
    //     uint112 item;
    //     uint112 payout;
    //     uint32 lastupdatedtime;
    // }
    
    address OBPToken;
    uint256 arbitrationTime;
    //owner decides which operator to safeguard etc, call pushResult etc.
    address owner;
    address court;
    mapping(address => uint) public stakers;

    uint256 public totalStaked;
    uint256 public freezedUnderReferee;
    // operator => amountOBP_instake for safeguarding
    mapping(address => uint) public operatorUnderReferee;
    // bettingOperator => item + payOutResult + payoutLastUpdatedTime
    mapping(address => bytes) public results;


    modifier onlyCourt() {
        require(msg.sender == court);
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function _getCurrentFreezeRatio() internal view returns(uint256 currentFreezeRatio) {
        currentFreezeRatio = (freezedUnderReferee * 1000 / totalStaked);
    }
    
    function encodeResult(uint112 _item, uint112 _payout, uint32 _lastupdatedTime) public pure returns(bytes memory) {
        return abi.encodePacked(_item, _payout, _lastupdatedTime);
    }

    function decodeResult(uint256 _encodedResult) public pure returns(uint112 item, uint112 payout, uint32 lastupdatedtime){
        item = uint112(_encodedResult >> 144);
        payout = uint112(_encodedResult >> 32);
        lastupdatedtime = uint32(_encodedResult);
    }
    function participate(uint256 _amount) external {
        address sender = msg.sender;
        bool success = IERC20(OBPToken).transferFrom(sender, address(this), _amount);
        require(success , 'participate: TRANSFER_FAILED');
        stakers[msg.sender] = _amount;
        totalStaked += _amount;
    }
    function withdraw(address _to, uint256 _amount) external {
        require(stakers[msg.sender] > 0, "withdraw:: YOU HAVE NO STAKE"); 
        require(totalStaked - freezedUnderReferee > _amount, "withdraw::AVAILABLE STAKE FOR WITHDRAW NOT ENOUGH");
        uint256 withdrawAmount;

    // if freezed ratio > 90%, withdraw takes a 1% fee.
        if (_getCurrentFreezeRatio() > 900) {
            withdrawAmount = _amount * 99 / 100;
        } else {
            withdrawAmount = _amount;
        }
        //remove the bet before transferring
        stakers[msg.sender] -= _amount;
        totalStaked -= _amount;
        (bool result) = IERC20(OBPToken).transfer(_to, withdrawAmount);
        require(result, "withdraw: TRANSFER_FAILED");
    }

    function anounceResult(address bettingOperator, bytes calldata data) external onlyOwner {
        results[bettingOperator] = abi.encodePacked(results[bettingOperator], data);
    }

    // select an index in the result mapping and push to the operator
    function pushResult(address bettingOperator, uint256 item_index) external onlyOwner {
        uint256 item;
        bytes memory result = results[bettingOperator];
        uint256 indexBytes = 32*item_index;
        assembly {
                item := mload(add(result, indexBytes))
                }
        (, , uint32 parsedPayoutLastUpdatedTime) = decodeResult(item);
                // only push result that passes the arbitration window
        if (block.timestamp > arbitrationTime + parsedPayoutLastUpdatedTime) {
            BettingOperator(bettingOperator).injectResult(item);
    }
}
    // push the entire result mapping to the operator    
    function pushResultBatch(address bettingOperator) external onlyOwner {//(bytes memory data){
        
        uint256 item;
        bytes memory result = results[bettingOperator];
        //return result.length;
         bytes memory data;
         for (uint256 i = 0; i < result.length; i+=32) {
             assembly {
                 item := mload(add(result, add(32, i)))
                 }
         (uint112 parsedItem, uint112 parsedPayout, uint32 parsedPayoutLastUpdatedTime) = decodeResult(item);
        //         // only push result that passes the arbitration window
            if (block.timestamp > arbitrationTime + parsedPayoutLastUpdatedTime) {
                data = abi.encodePacked(data, item);
            }
            require(parsedItem > 0, "DEBUG: parseItem shd > 0");
         }
        // push result
        
        BettingOperator(bettingOperator).injectResultBatch(data);
    }

    function revokeResult(address bettingOperator, uint256 item) external onlyOwner {
        //wipe out the whole entry, then you can push again, the original result in operator would be overrided as the result is read in a list.
        //for example result in operator {item, payout, lastupdatedtime} = [1,1000, xxxx], [1,0, xxxx] => pool for Item1 would end up with 0.
        results[bettingOperator][item] = 0;
    }

   function closeItem(address bettingOperator, uint256 item) external onlyOwner {
        BettingOperator(bettingOperator).closeItem(item);
   }
    function closeItemBatch(address bettingOperator) external onlyOwner {
        bytes memory result = results[bettingOperator];
        // push result
        BettingOperator(bettingOperator).closeItemBatch(result);
    }
    function verify(address bettingOperator, uint256 _refereeValueAtStake, uint256 maxBet) external onlyOwner {
        freezedUnderReferee += _refereeValueAtStake;
        require(freezedUnderReferee <= totalStaked);
        BettingOperator(bettingOperator).verify(_refereeValueAtStake, maxBet);
        operatorUnderReferee[bettingOperator] = _refereeValueAtStake;
    }

    // this function exposes the referee to confiscation from the court.
    // OBP staked for that operator would be confiscated and transferred to the operator.
    function confiscate(address operator) external onlyCourt {
        uint256 amount = operatorUnderReferee[operator];
        totalStaked -= amount;
        freezedUnderReferee -= amount;
        IERC20(OBPToken).transfer(operator, amount);
    }



}

pragma solidity ^0.8.0;

import './interfaces/IRefereeDeployer.sol';
import './Referee.sol';

contract RefereeDeployer is IRefereeDeployer {
    address public arbitrationTimeSetter;
    uint256 arbitrationTime = 1 seconds;
    address[] public allReferees;

    event RefereesCreated(address operator, uint);
    function allRefereesLength() public view returns (uint) {
        return allReferees.length;
    }

    function refereeCodeHash() public pure returns (bytes memory) {
        return type(Referee).creationCode;
    }

    function refereeByteCode(uint256 _arbitrationTime, address court, address owner, address OBPToken) public pure returns (bytes memory) {
         //return keccak256(abi.encodePacked(_arbitrationTime, court, owner, OBPToken));
         return abi.encodePacked(refereeCodeHash(), abi.encode(_arbitrationTime, court, owner, OBPToken));
     }

     function refereeSalt(uint256 _arbitrationTime, address court, address owner, address OBPToken) public pure returns (bytes32){
         return keccak256(abi.encodePacked(_arbitrationTime, court, owner, OBPToken));
     }

    function getcreatedAddress(address court, address owner, address OBPToken) public view returns(address referee) {
        bytes memory bytecode  = refereeByteCode(arbitrationTime, court, owner, OBPToken);
        bytes32 salt = refereeSalt(arbitrationTime, court, owner, OBPToken);
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );
        return address(uint160(uint(hash)));
    }

    function createReferee(address court, address owner, address OBPToken) external override returns(address referee){
        bytes memory bytecode = refereeByteCode(arbitrationTime, court, owner, OBPToken);
        bytes32 salt = refereeSalt(arbitrationTime, court, owner, OBPToken);
        assembly {
            referee := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        allReferees.push(referee);
        emit RefereesCreated(referee, allReferees.length);
    }

    function setArbitrationWindow(uint256 _arbitrationTime) external override {
        require(msg.sender == arbitrationTimeSetter, 'setArbitrationWindow: FORBIDDEN');
        arbitrationTime = _arbitrationTime;
    }


}

pragma solidity ^0.8.0;

interface IRefereeDeployer {

    function createReferee(address owner, address court, address OBPToken) external returns(address);
    function setArbitrationWindow(uint256 _arbitrationTime) external;

}