// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

//import "./ERC20Updated.sol";
//import "https://raw.githubusercontent.com/smartcontractkit/chainlink/develop/evm-contracts/src/v0.6/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

interface ERC20Interface {
    function totalSupply() external returns (uint);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract GuessContract is VRFConsumerBase {
    
    address public owner ;
    bytes32 public keyHash;
    uint public fee;
    uint256 randomNumber;
    
    /* stoch contract address */    
    ERC20Interface public stochContractAddress = ERC20Interface(0x6E152BDFcF33D6C096b6DCEe0aA7f038aC57733E);
    
    uint public totalTokenStakedInContract; 
      
    struct StakerInfo {
        bool isStaking;
        uint stakingBalance;
        uint[] choosedNumbers;
        uint maxNumberUserCanChoose;
        uint currentNumbers;
    }
    
    struct numberMapStruct {
        bool isChoosen;
        address userAddress;
    }
    
    mapping(address=>StakerInfo) StakerInfos;
    mapping(uint => numberMapStruct) numerMap;
    

 //////////////////////////////////////////////////////////////////////////////Constructor Function///////////////////////////////////////////////////////////////////////////////////////////////////
     

    constructor(address _vrfCoordinator, address _link) VRFConsumerBase(_vrfCoordinator, _link) public {
        owner = msg.sender;
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311; // hard-coded for Rinkeby
        fee = 10 ** 17; // 0.1 LINK LINK cost (as by chainlink)
    }


//////////////////////////////////////////////////////////////////////////////////////Modifier Definitations////////////////////////////////////////////////////////////////////////////////////////////

    /* onlyAdmin modifier to verify caller to be owner */
    modifier onlyAdmin {
        require (msg.sender == 0x80864Bdad5790eDe144a3E0F07C65A0Dd2b2280B , 'Only Admin has right to execute this function');
        _;
        
    }
    
    /* modifier to verify caller has already staked tokens */
    modifier onlyStaked() {
        require(StakerInfos[msg.sender].isStaking == true);
        _;
    }
    
    
//////////////////////////////////////////////////////////////////////////////////////Staking Function//////////////////////////////////////////////////////////////////////////////////////////////////



    /* function to stake tokens in contract. This will make staker to be eligible for guessing numbers 
    * 100 token => 1 guess
    */
    
     function stakeTokens(uint _amount) public  {
       require(_amount > 0); 
       require ( StakerInfos[msg.sender].isStaking == false, "You have already staked once in this pool.You cannot staked again.Wait for next batch") ;
       require (ERC20Interface(stochContractAddress).transferFrom(msg.sender, address(this), _amount));
       StakerInfos[msg.sender].stakingBalance =  _amount;
       totalTokenStakedInContract = totalTokenStakedInContract.add(_amount);
       StakerInfos[msg.sender].isStaking = true;
       StakerInfos[msg.sender].maxNumberUserCanChoose = _amount.div(100); 
        
    }
    
    
    /* funtion to guess numbers as per tokens staked by the user. User can choose any numbers at a time but not more than max allocated count 
     * All choosen numbers must be in the range of 1 - 1000 
     * One number can be choosed by only one person
    */
    function chooseNumbers(uint[] memory _number) public onlyStaked() returns(uint[] memory){
        require(StakerInfos[msg.sender].maxNumberUserCanChoose > 0);
        require(StakerInfos[msg.sender].currentNumbers < StakerInfos[msg.sender].maxNumberUserCanChoose);
        require(StakerInfos[msg.sender].maxNumberUserCanChoose - StakerInfos[msg.sender].currentNumbers > 0);
        require(_number.length <= StakerInfos[msg.sender].maxNumberUserCanChoose - StakerInfos[msg.sender].choosedNumbers.length);
        require(_number.length <= StakerInfos[msg.sender].maxNumberUserCanChoose - StakerInfos[msg.sender].currentNumbers);
        for(uint i=0;i<_number.length;i++)
        require(_number[i] >= 1 && _number[i] <= 1000);
        uint[] memory rejectedNumbers = new uint[](_number.length);
        uint t=0;
        for(uint i=0;i<_number.length;i++) {
            if (numerMap[_number[i]].isChoosen == true) {
                rejectedNumbers[t] = _number[i];
                t = t.add(1);
            }
            else {
                StakerInfos[msg.sender].currentNumbers = StakerInfos[msg.sender].currentNumbers.add(1);
                StakerInfos[msg.sender].choosedNumbers.push(_number[i]);
                numerMap[_number[i]].isChoosen = true;
                numerMap[_number[i]].userAddress = msg.sender;
            }
        }
        
        return rejectedNumbers;
    }
    
    
    /*  Using this function user can unstake his/her tokens at any point of time.
    *   After unstaking history of user is deleted (choosed numbers, staking balance, isStaking)
    */
    
    function unstakeTokens() public onlyStaked() {
        uint balance = StakerInfos[msg.sender].stakingBalance;
        require(balance > 0, "staking balance cannot be 0 or you cannot stake before pool expiration period");
        require(ERC20Interface(stochContractAddress).transfer(msg.sender, balance));
        totalTokenStakedInContract = totalTokenStakedInContract.sub(StakerInfos[msg.sender].stakingBalance);
        StakerInfos[msg.sender].stakingBalance = 0;
        StakerInfos[msg.sender].isStaking = false;
        StakerInfos[msg.sender].maxNumberUserCanChoose = 0;
        delete StakerInfos[msg.sender].choosedNumbers;
        StakerInfos[msg.sender].currentNumbers = 0;
        for(uint i=0;i<StakerInfos[msg.sender].choosedNumbers.length;i++) {
            numerMap[StakerInfos[msg.sender].choosedNumbers[i]].isChoosen = false;
            numerMap[StakerInfos[msg.sender].choosedNumbers[i]].userAddress = address(0);
        }
        
        
    } 
    
    
    /*
    *   Only admin can call to guess the random number.
    *   Number is generated using chainlink VRF based on the random number seed entered by admin.
    */
    function guessRandomNumber(uint256 userProvidedSeed) public onlyAdmin returns(bytes32) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        uint256 seed = uint256(keccak256(abi.encode(userProvidedSeed, blockhash(block.number)))); // Hash user seed and blockhash
        bytes32 _requestId = requestRandomness(keyHash, fee, seed);
        return _requestId;
    }
    
    
    function chooseWinner() public onlyAdmin returns(address) {
        require(randomNumber != 0);
        require(numerMap[randomNumber].userAddress != address(0));
        address user;
        user = numerMap[randomNumber].userAddress;
        require(ERC20Interface(stochContractAddress).transfer(user, 1000));
        randomNumber = 0;
        return user;
    }
    
    function checkRandomOwner() public view returns(address) {
        require(numerMap[randomNumber].userAddress != address(0), "No matched");
        return numerMap[randomNumber].userAddress;
    }
    
    function checkRandomNumber() view public returns(uint) {
        require(randomNumber != 0, "Random number not generated yet");
        return randomNumber;
    } 
    
    function transferChainTokens(address _me) public onlyAdmin {
        LINK.transfer(_me,LINK.balanceOf(address(this)));
    }
    
    
    function checkLinkBalance() public view onlyAdmin returns(uint) {
        return LINK.balanceOf(address(this));
    }
    
    
    function viewNumbersSelected() view public returns(uint[] memory) {
        return StakerInfos[msg.sender].choosedNumbers;
    }
    
    function maxNumberUserCanSelect() view public returns(uint) {
        return StakerInfos[msg.sender].maxNumberUserCanChoose;
    }
    
    function remainingNumbersToSet() view public returns(uint) {
        return (StakerInfos[msg.sender].maxNumberUserCanChoose - StakerInfos[msg.sender].currentNumbers);
    }
        
    function countNumberSelected() view public returns(uint) {
        return StakerInfos[msg.sender].currentNumbers;
    }
    
    function checkStakingBalance() view public returns(uint) {
       return StakerInfos[msg.sender].stakingBalance; 
    }
    
    function isUserStaking() view public returns(bool) {
        return StakerInfos[msg.sender].isStaking;
    }
    
    
    // fallback function called by chailink contract
       function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomNumber = randomness.mod(1000).add(1);
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./vendor/SafeMathChainlink.sol";

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   * @param _seed seed mixed into the input of the VRF.
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface LinkTokenInterface {
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

// SPDX-License-Identifier: MIT
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