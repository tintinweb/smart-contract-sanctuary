/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

// SPDX-License-Identifier: MIT

/*
 ______   _____   ______  _____  _________     _       _____         _____       ___    _________  _________  ________  _______   ____  ____  
|_   _ `.|_   _|.' ___  ||_   _||  _   _  |   / \     |_   _|       |_   _|    .'   `. |  _   _  ||  _   _  ||_   __  ||_   __ \ |_  _||_  _| 
  | | `. \ | | / .'   \_|  | |  |_/ | | \_|  / _ \      | |           | |     /  .-.  \|_/ | | \_||_/ | | \_|  | |_ \_|  | |__) |  \ \  / /   
  | |  | | | | | |   ____  | |      | |     / ___ \     | |   _       | |   _ | |   | |    | |        | |      |  _| _   |  __ /    \ \/ /    
 _| |_.' /_| |_\ `.___]  |_| |_    _| |_  _/ /   \ \_  _| |__/ |     _| |__/ |\  `-'  /   _| |_      _| |_    _| |__/ | _| |  \ \_  _|  |_    
|______.'|_____|`._____.'|_____|  |_____||____| |____||________|    |________| `.___.'   |_____|    |_____|  |________||____| |___||______|   


  _____  _____  _____   ______  ___  ____  ____  ____      _________    ___   ___  ____   ________  ____  _____  
 |_   _||_   _||_   _|.' ___  ||_  ||_  _||_  _||_  _|    |  _   _  | .'   `.|_  ||_  _| |_   __  ||_   \|_   _| 
   | |    | |    | | / .'   \_|  | |_/ /    \ \  / /      |_/ | | \_|/  .-.  \ | |_/ /     | |_ \_|  |   \ | |   
   | |   _| '    ' | | |         |  __'.     \ \/ /           | |    | |   | | |  __'.     |  _| _   | |\ \| |   
  _| |__/ |\ \__/ /  \ `.___.'\ _| |  \ \_   _|  |_          _| |_   \  `-'  /_| |  \ \_  _| |__/ | _| |_\   |_  
 |________| `.__.'    `.____ .'|____||____| |______|        |_____|   `.___.'|____||____||________||_____|\____| 
 
 */

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



pragma solidity ^0.6.0;

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
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
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
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}
 
pragma solidity ^0.6.0;

interface LinkTokenInterface 
{
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
  
  
}


pragma solidity ^0.6.0;

contract VRFRequestIDBase{


  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

pragma solidity 0.6.6;

abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

contract RandomNumberConsumer is VRFConsumerBase, IERC20{
    
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    
    uint256 private DLTParameters; // [0]uint16 jackpotPercentage;[16]uint16 maintenancePercentage;[32]uint16 _followersRequiredForICodeActive;[64]uint64 iCodeCreationCost; [128]32 tradeLimit; 
                                    //[160] 16 minAmountForHolders; [176]16 reservePercentage; [192]8 lockedState; [200] 16 iCodePercentage; [216] 16 ICodeFollowerPercentage; [232]
    
    uint256 public ICodeCount;
    bool private lotteryManuallyContinued;
    bool private lotterySearchManuallyContinued;
    
    uint256 private currSearchID;
    uint256 private currSearchBalances;
    
    uint256 public lastLottery;
    uint256 public totalHolders;
    
    struct iData
    {
        uint256 iCodeData; //Address , [160]public?,[168] active?, [176]64 iCodeGainsWithdrew ,[240]16 followers?
        uint256 iCodeGainsAvailable;
        //"500","5000","100","100","0","0","10000","0","0","0","100"
    }
    
    
      struct accountInformation
   {
        bytes32 personalICode;
        bytes32 iCodeFollowing;   
        uint256 accData; //[0] uint8 isFollowing; [64]uint8 hasICode;//[128] 8 isLiquidityAddress/[184]8 Non eligible/[232]8 isUsingSecondaryFunction//[240]8 privateacount 
        uint256 index;
   }
   
   
  
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) public _allowances;
    
    mapping (uint256 => address) private _getAddressWithIndex;
    
    mapping (address => accountInformation) private _accountInfo;
    
    mapping (bytes32 => iData) private _iCodeAccount;
    
    mapping (uint256 => uint256) private _balanceDataStructure;
    
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner;
    uint256 private _totalSupply;
    address private _reserveAddress;
    address private _maintenanceFundsAddress;
    uint256 private decimalFactor;
   
      event NewICodeCreated(
        string iCode, 
        address creator,
        uint256 pricePaid
        );    
        
    event LotteryTransfer(
        address fromDigitalLottery,
        address to,
        uint256 value
        );
        
    constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        ) public
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        
        
        _name = "x";
        _symbol = "AAG";
        _decimals = 9;
        _owner = msg.sender;
        decimalFactor = 10 ** 9;
        _reserveAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
        _totalSupply = 77000000 * decimalFactor;
        _balances[_reserveAddress] = _totalSupply.div(2);
        _balances[_owner] = _totalSupply.div(2);
        totalHolders = 5;
        holdersManagement(msg.sender, 0, _balances[msg.sender], 1000);
        lastLottery = now;
        _accountInfo[_reserveAddress].accData += uint256(1<<184);
        _accountInfo[_maintenanceFundsAddress].accData += uint256(1<<184);
        DLTParameters |= 1000<<160;
    }
    //18446744073709551615

function ShowVarDLT() public view returns (uint256 a, uint256 b, uint256 c, uint256 d, uint256 e, uint256 f, uint256 i, uint256 j, uint256 k, uint256 l){
    
    a = uint16(calculatePercentageAmount(_balances[_reserveAddress], DLTParameters));
        b = uint16(calculatePercentageAmount(_balances[_reserveAddress], DLTParameters>>16));
        c = uint16(DLTParameters>>32);
        d = uint64(DLTParameters>>64);
        e = uint32(DLTParameters>>128);
        f = (uint256(uint16(DLTParameters>>160)) * 100000);
        i = uint16(calculatePercentageAmount(_balances[_reserveAddress], DLTParameters>>176));
        j = uint8(DLTParameters>>192);
        k = uint16(calculatePercentageAmount(_balances[_reserveAddress], DLTParameters>>200));
        l = uint16(calculatePercentageAmount(_balances[_reserveAddress], DLTParameters>>216));
}

function ShowVarBDS(uint256 column) public view returns (uint256 a, uint256 b, uint256 c, uint256 d){
    
    
        a = uint64(_balanceDataStructure[column]>>0);
        b = uint64(_balanceDataStructure[column]>>64);
        c = uint64(_balanceDataStructure[column]>>128);
        d = uint64(_balanceDataStructure[column]>>192);
}

    
    
        function triggerAddressEligibility(address addr) public{  //Liquidity addresses, routers (etc) won't be able to win the lottery and will all be set uneligible with this function.
        require(msg.sender == _owner);
        uint256 nonEligible = uint8(_accountInfo[addr].accData>>184);//non eligible
        _accountInfo[addr].accData = nonEligible == 0? _accountInfo[addr].accData + uint256(1<<184): 
                                                       _accountInfo[addr].accData - (nonEligible<<184); 
        //if he holds, 
        if(nonEligible == 0 && _balances[addr] >= (uint16(DLTParameters>>160) * 100000)){//minAmountForHolders
            holdersManagement(addr, _balances[addr], 0, (uint256(uint16(DLTParameters>>160)) * 100000));//It's the opposite of what it "should", because "nonEligible" currently used has not been updated(which means it's always the opposite of what it should be, since using this function always sets it true/false)
        }else if(nonEligible == 1 && _balances[addr] >= (uint256(uint16(DLTParameters>>160)) * 100000)){
            holdersManagement(addr, 0, _balances[addr], (uint256(uint16(DLTParameters>>160)) * 100000));//same here. Used as the opposite in purpose.
        }
    }
    
    function setAsLiquidityAddress(address acc) public{ //Liquidity addresses will be marked as such, allowing prices for whoever buys from them and has an active ICode or follows an active ICode.
        require(msg.sender == _owner);
        if(uint8(_accountInfo[acc].accData>>168) == 0){
            _accountInfo[acc].accData += 1<<168;
        }else{
            _accountInfo[acc].accData -= uint256(uint8(_accountInfo[acc].accData>>168))<<168;
        }
    }
    
 function updateBalanceData(uint256 diff, uint256 id, bool add) private{ //Every single holder Balance will be gathered into multiple key-variables, keeping regrouped balance values together and making it possible to find a winner for the Lottery Prices.
     
            uint256[8] memory indx;
            uint256 totalE = id > 15625? (id / 15625) +1: 1;
            uint256 rem = id % 125;
            uint256 aPos = rem > 25? (((rem-1)/ 25 -1)*64) : rem == 0? 192: 0; 
            
            indx[0] = rem == 0? (((id-1) / 125) * 2) + totalE +1 : ((id / 125) * 2) + totalE + (rem > 25? 1: 0);    //a 
            indx[1] = rem < 26? rem == 0? indx[0]-1:indx[0] : indx[0] -1;                                           //b 
            indx[2] = id > 625? (id % 625) > 125? indx[1] - (((id % 625)/125) *2) : indx[1] : 1;                    //c 
            indx[3] = id > 3125? (id % 3125) > 625? indx[2] - (((id % 3125)/625) *10) : indx[2] : 1;                //d 
            indx[4] = id > 15625? ((id-1) / 15625) * 251 : 0;                                                       //e
            indx[5] = id > 78125? ((id-1) / 78125) * 1255 : 0;                                                      //f
            indx[6] = id > 390625? ((id-1) / 390625) * 6275 : 0;                                                    //g
            indx[7] = id > 1953125? ((id-1) / 1953125) * 31375 : 0;                                                 //h
            
            bool[8] memory toSkip;
            uint256[8] memory bData;
            uint256 nxt;
            uint256 pos;
                          
            for(uint i = 0; i < 2; i++){
                for(uint j = 0 + nxt; j < 4 + nxt; j++){
                    pos = j == 0? aPos : ((j-nxt)*64);
                    bData[j] = diff<<pos;
                }
                nxt=4;
            }
            nxt = 0;
            
            for(uint i = 0; i < 2; i++){
                for(uint j = 0 + nxt; j < 4 + nxt; j++){
                    if(toSkip[j] == true){
                        continue;
                    }
                    for(uint o = j +1; o < 4 + nxt; o++){
                        if(toSkip[o] == true){
                            continue;
                        }
                        if(indx[j] == indx[o]){
                            toSkip[o] = true;
                            bData[j] += uint256(uint64(bData[o]>>((o - nxt)*64)))<<((o - nxt)*64);
                        }
                    }
                    
                }
                nxt = 4;
            }
            
            for(uint l = 0; l < 8; l++){
                if(toSkip[l] == true){
                    continue;
                }
                if(add == true){
                    _balanceDataStructure[indx[l]] += bData[l];
                }else{
                    uint256 BDS = _balanceDataStructure[indx[l]];
                    for(uint i = 0; i < 4; i++){
                        uint256 bDataL = uint64(bData[l])>>(64 * i);
                        require(bDataL <= uint64(BDS>>(64 * i)));
                    }
                    _balanceDataStructure[indx[l]] -= bData[l];
                }
            }
    }
      

    function holdersManagement(address accToVer, uint256 bfBalUp, uint256 afBalUp, uint256 minAmt) private{
        if(bfBalUp < minAmt){
            if(afBalUp >= minAmt){
                addHolderAndUpdateBalanceData(totalHolders, accToVer, true, afBalUp);
            }
        }else{
            if(afBalUp < minAmt){
                removeHolderAndUpdateBalanceData(_accountInfo[accToVer].index, _getAddressWithIndex[totalHolders], bfBalUp, totalHolders);
            }else{
                updateBalanceData(afBalUp >= bfBalUp? afBalUp - bfBalUp : bfBalUp - afBalUp, _accountInfo[accToVer].index, afBalUp >= bfBalUp ? true : false);
            }
        }
    }
    
    
    function addHolderAndUpdateBalanceData(uint256 _totalHolders, address holderAddress, bool add, uint256 diff) private{
        uint256 incr;
        if(_getAddressWithIndex[_totalHolders] != address(0)){
            incr++;
            while(_getAddressWithIndex[_totalHolders + incr] != address(0)){//prevents errors (from function revert) such as overlapping one already used ID (Could happen after a failed transfer), which would make the balancedata incorrect
            incr++;
            }
            _getAddressWithIndex[_totalHolders + incr] = holderAddress;
            totalHolders += incr;//adds preventively one holder to "reserve" a slot. However, it can be reverted if the transaction fails, 
            //which is fine since every new holder always checks for the address to be address(0) anyway.
        
        }else{
            _getAddressWithIndex[_totalHolders] = holderAddress;
        }
        
        updateBalanceData(diff, _totalHolders + incr, add);
        
        require(gasleft() > 60500);//faut que ça soit exact environ
        require(_getAddressWithIndex[_totalHolders + incr] == holderAddress);
        _accountInfo[holderAddress].index = _totalHolders + incr;
    }
    
    
    
    function removeHolderAndUpdateBalanceData(uint256 freeIndex, address hAddress, uint256 diff, uint256 totHolders)private{
        totalHolders--;
        
        uint256 bal = _balances[hAddress];
        
        _getAddressWithIndex[freeIndex] = hAddress;
        updateBalanceData(bal, totHolders, false);
            
        if(bal >= diff){
            updateBalanceData(bal - diff, freeIndex, true);
        }else{
            updateBalanceData(diff - bal, freeIndex, false);
        }
        
        require(gasleft() > 37500);
        require(_getAddressWithIndex[totHolders] == hAddress);
        _getAddressWithIndex[totHolders] = address(0);
        _accountInfo[hAddress].index = 0;
    }
  
    
  
    function setDLTParameters(uint256 reservePercentage, uint256 maintenancePercentage, uint256 jackpotPercentage, uint256 iCodeCreationCost, uint256 tradeLimit, 
    uint256 followersRequiredForICodeActive, uint256 iCodePercentage, uint256 ICodeFollowerPercentage) public{
        require(msg.sender == _owner);
       
        require(reservePercentage >= 10 && reservePercentage <= 600);
        require(maintenancePercentage >= 1 && maintenancePercentage <= 500);
        require(jackpotPercentage >= 10 && jackpotPercentage <= 500);
        require(iCodeCreationCost <= 600);
        require(tradeLimit <= 7777);
        require(iCodePercentage <= 500);
        require(ICodeFollowerPercentage <= 500);
        
        uint256 DLTPUpdated;
        
        DLTPUpdated |= jackpotPercentage;
        DLTPUpdated |= maintenancePercentage<<16;
        DLTPUpdated |= followersRequiredForICodeActive<<32;
        DLTPUpdated |= iCodeCreationCost<<64;
        DLTPUpdated |= tradeLimit<<128;
        DLTPUpdated |= uint256(uint16(DLTParameters>>160))<<160;
        DLTPUpdated |= reservePercentage<<176;
        DLTPUpdated |= uint256(uint8(DLTParameters>>192))<<192;
        DLTPUpdated |= iCodePercentage<<200;
        DLTPUpdated |= ICodeFollowerPercentage<<216;
        
        DLTParameters = DLTPUpdated;
    }
    
    
     function calculatePercentageAmount(uint256 value, uint256 percentage)private pure returns (uint256){
        uint256 amount = (value.mul(percentage)).div(10000);
        return amount;
    }
    
    
    /** 
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 userProvidedSeed) private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

    
    function triggerLockState() public {
        require(msg.sender == _owner);
        if(uint8(DLTParameters>>192) == 0){
            DLTParameters += uint256(uint8(1))<<192;
        }else{
            DLTParameters -= uint256(uint8(DLTParameters>>192))<<192;
        }
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override  returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override  returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(uint256(uint8(DLTParameters>>192)) == 0);
        
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
     
     

     
    function _transfer(address sender, address recipient, uint256 amount) internal virtual{//this function is clearly-most likely- optimizable when it comes to not repeating _balances and using uint256 instead
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(sender != _reserveAddress);
        require(amount <= _balances[sender]);
        uint256 DLTP = DLTParameters;
        require(amount <= uint32(DLTP>>128)*decimalFactor, "ERC20: trade exceeding the limit (_buyLimit)");
        if(msg.sender != _owner){
            require(uint8(DLTP>>192) == 0, "Cannot transfer while DLT is in a locked state.");
        }
        uint256 accdataRecipient = _accountInfo[recipient].accData;
        require(uint8(accdataRecipient>>232) == 0);//isUsingSecondaryFunction
        uint256 accDataSender = _accountInfo[sender].accData;
        require(uint8(accDataSender>>232) == 0);//isUsingSecondaryFunction
        
        (uint256 infP, uint256 reserveP) = calculateTransferTax(accDataSender, accdataRecipient, recipient, amount, DLTP);
            
        _balances[sender] = _balances[sender].sub(amount);  
        
        if(uint8(accDataSender>>184) == 0){
            holdersManagement(sender, _balances[sender] + amount, _balances[sender], (uint256(uint16(DLTP>>160)) * 100000));//72hasAutoDataUpdate / minAmountForHolders
        }
        if(uint8(accdataRecipient>>184) == 0){
            holdersManagement(recipient, _balances[recipient], _balances[recipient] + (amount - reserveP), (uint256(uint16(DLTP>>160)) * 100000));
        }
        _balances[_reserveAddress] = _balances[_reserveAddress].add(reserveP - infP);
        _balances[recipient] = _balances[recipient].add(amount - reserveP);
    
        emit Transfer(sender, recipient, amount- reserveP);
        emit Transfer(sender, _reserveAddress, reserveP - infP);
    }
    

    function calculateTransferTax(uint256 accDataSender, uint256 accdataRecipient, address recipient, uint256 amount, uint256 DLTP) private returns (uint256 infP, uint256 reserveP){
        reserveP = (calculatePercentageAmount(amount, uint16(DLTP>>176)));//reservePercentage
        if(uint8(accDataSender>>128) != 0){//isLiquidityAddress
                if(uint8(accdataRecipient) != 0){//isfollowing
                bytes32 iFollowing = _accountInfo[recipient].iCodeFollowing;
                if(uint8(_iCodeAccount[iFollowing].iCodeData>>168) != 0){//active?
                    infP = calculatePercentageAmount(amount, uint16(DLTP>>200));//iCodePercentage
                    _iCodeAccount[iFollowing].iCodeGainsAvailable = _iCodeAccount[iFollowing].iCodeGainsAvailable.add(infP);
                    uint256 iCodeFollowerReduct = calculatePercentageAmount(amount, uint16(DLTP>>216));
                    reserveP = reserveP.sub(iCodeFollowerReduct);
                }
            }
        }
    }
 

     function reserveBurn(uint256 amount) public{
        require(msg.sender == _owner);
        require(_balances[_reserveAddress] - amount > _totalSupply.div(5));

        _balances[_reserveAddress] = _balances[_reserveAddress].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(_reserveAddress, address(0), amount);
    }
    
   
    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
     

   
   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(account != _reserveAddress);
        require(uint8(_accountInfo[msg.sender].accData>>232) == 0);
        _accountInfo[msg.sender].accData += 1<<232;
        holdersManagement(account, _balances[account], _balances[account] - amount, (uint256(uint16(DLTParameters>>160)) * 100000));
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        _accountInfo[msg.sender].accData -= uint256(uint8(_accountInfo[msg.sender].accData>>232))<<232;
        emit Transfer(account, address(0), amount);
    }
    

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        require(uint256(uint8(DLTParameters>>192)) == 0);
        _burn(msg.sender, amount);
    }


    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(owner != _reserveAddress);
        require(spender != _reserveAddress);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
     
    function burnFrom(address account, uint256 amount) public virtual {
        require(uint8(DLTParameters>>192) == 0);
        uint256 decreasedAllowance = allowance(account, msg.sender).sub(amount);

        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }
    
    
    function createNewICode(string memory yourDesiredICode, bool publicICodeDataTrueOrFalse, bool publicAccountInfoTrueOrFalse) public{
        require(uint8(_accountInfo[msg.sender].accData>>64) == 0);//has i code
        require(msg.sender != _reserveAddress);
        require(uint8(_accountInfo[msg.sender].accData>>232) == 0);
        bytes32 iCodeBytes = stringToBytes32(yourDesiredICode);
        require(address(_iCodeAccount[iCodeBytes].iCodeData) == address(0));
        require(uint8(DLTParameters>>192) == 0);//lockedState
        uint256 DLTP = DLTParameters;
           if(uint64(DLTP>>64) > 0){//iCodeCreationCost
            require(_balances[msg.sender] >= uint64(DLTP>>64));
            Transfer(msg.sender, _maintenanceFundsAddress, uint64(DLTP>>64));
        }
        _accountInfo[msg.sender].accData += 1<<232;
        
        if(publicAccountInfoTrueOrFalse == false){
            _accountInfo[msg.sender].accData += 1<<240;
        }
        
        uint256 icData = uint256(msg.sender);
        icData |= publicICodeDataTrueOrFalse == false? 1 <<160 : 0 <<160;
        
        _accountInfo[msg.sender].accData += 1<<64;//has i code
        _iCodeAccount[iCodeBytes].iCodeData = icData;
        _accountInfo[msg.sender].personalICode = iCodeBytes;
        _accountInfo[msg.sender].accData -= uint256(uint8(_accountInfo[msg.sender].accData>>232))<<232;
        NewICodeCreated(yourDesiredICode, publicICodeDataTrueOrFalse? msg.sender:address(0), uint64(DLTP>>64));
    }
   
   
 
    
    
    function enterICode(string memory _code) public{
        require(msg.sender != _reserveAddress);
        bytes32 code = stringToBytes32(_code);
        address iCodeAddress = address(_iCodeAccount[code].iCodeData);
        require(iCodeAddress != address(0));
        require(iCodeAddress != msg.sender);
        require(uint8(_accountInfo[msg.sender].accData>>232) == 0);
        _accountInfo[msg.sender].accData += 1<<232;
        
        bytes32 _iCodeFollowing = _accountInfo[msg.sender].iCodeFollowing;
        uint256 ICD = _iCodeAccount[_iCodeFollowing].iCodeData;
        uint256 _iCodeFollowers = uint256(uint16(ICD>>240));//followers
        uint256 DLTP = DLTParameters;
        
        if(_iCodeFollowers != 0){
            _iCodeAccount[_iCodeFollowing].iCodeData -= 1<<240;//followers
                if(_iCodeFollowers -1 < uint16(DLTP>>32) && uint8(ICD>>168) != 0){//active?
                    _iCodeAccount[_iCodeFollowing].iCodeData -= uint256(uint8(_iCodeAccount[_iCodeFollowing].iCodeData>>168))<<168;
                }
        }
        _accountInfo[msg.sender].iCodeFollowing = code;
        ICD = _iCodeAccount[code].iCodeData;
        
        require(uint16(_iCodeAccount[code].iCodeData>>240) < 65000);
        _iCodeAccount[code].iCodeData += 1<<240;//followers
        if(uint256(uint16(_iCodeAccount[code].iCodeData>>240)) > uint256(uint16(DLTP>>32))){//_followersRequiredForICodeActive
            if(uint256(uint8(_iCodeAccount[code].iCodeData>>168)) == 0){//active?
                _iCodeAccount[code].iCodeData += 1<<168;
            }
            
        }
        _accountInfo[msg.sender].accData -= uint256(uint8(_accountInfo[msg.sender].accData>>232))<<232;
    }
    
    
    function getICodeData(string memory _iCode) public view returns 
    (uint256 _followers, bool _isPublic, uint256 _iCodeGainsWithdrew, uint256 _iCodeGainsAvailable, address _iAddress, bool _active) {
        
        bytes32 iCode = stringToBytes32(_iCode);
        uint256 iCodeDt = _iCodeAccount[iCode].iCodeData;
        if(uint8(iCodeDt>>160) == 1){
            require(msg.sender == address(iCodeDt) || msg.sender == _owner, "Data for this ICode is set private.");
        }
        _iAddress = address(iCodeDt);
        _isPublic = uint8(iCodeDt>>160) == 0? true:false;
        _active = uint8(iCodeDt>>168) == 0? false: true;
        _iCodeGainsWithdrew = uint64(iCodeDt>>176);
        _followers = uint16(iCodeDt>>240);
        _iCodeGainsAvailable = _iCodeAccount[iCode].iCodeGainsAvailable;
    } 
       
    function getAccountInfo(address account) public view returns 
    (bytes32 personalICode_, bytes32 iCodeFollowing_, uint256 index_, bool isEligible_, bool isLiquidityAddress_, bool isUsingSecondaryFunction_){
        accountInformation memory _accInfo = _accountInfo[account];
        if(uint8(_accInfo.accData>>200) == 1){
            require(msg.sender == account || msg.sender == _owner, "Data for this account is set private.");
        }
        personalICode_ = _accInfo.personalICode;
        iCodeFollowing_ = _accInfo.iCodeFollowing;
        index_ = _accInfo.index;
        
        isEligible_ = uint8(_accInfo.accData>>184) == 0 ? true:false;
        isLiquidityAddress_ = uint8(_accInfo.accData>>128) == 0? false:true;
        isUsingSecondaryFunction_ = uint8(_accInfo.accData>>232) == 0? false:true;
    }


    function withdrawICodeGains() public{
        require(uint8(DLTParameters>>192) == 0);
        require(uint8(_accountInfo[msg.sender].accData>>64) == 1);
        require(uint8(_accountInfo[msg.sender].accData>>232) == 0);
        _accountInfo[msg.sender].accData += 1<<232;
        bytes32 code = _accountInfo[msg.sender].personalICode;
        require(_iCodeAccount[code].iCodeGainsAvailable > 0);
        uint256 withdraw = _iCodeAccount[code].iCodeGainsAvailable;
        _iCodeAccount[code].iCodeGainsAvailable = _iCodeAccount[code].iCodeGainsAvailable.sub(withdraw);
        _iCodeAccount[code].iCodeGainsAvailable += withdraw<<176;
        _accountInfo[msg.sender].accData -= uint256(uint8(_accountInfo[msg.sender].accData>>232))<<232;
        Transfer(_reserveAddress, msg.sender, withdraw);
    }
   
    
    function stringToBytes32(string memory source) private pure returns(bytes32){
        bytes memory tempStr = bytes(source);
        require(tempStr.length > 0 && tempStr.length < 33);
        bytes32 tmp;
        assembly {
        tmp := mload(add(source, 32))
        }
        return (tmp);
    }

    function bytes32ToString(bytes32 _bytes32) private pure returns(string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}