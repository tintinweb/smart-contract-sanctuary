/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// File: contracts\@openzeppelin\contracts\token\ERC20\IERC20.sol


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

// File: contracts\utils\AddressIndex.sol

pragma solidity ^0.8.0;

contract AddressIndex {

    address public owner;
    address buoy;
    address bPool;
    address uniswapToken;
    address votingBooth;
    address smartPool;
    address xBuoy;
    address proxy;
    address mine;
    address lottery;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, 'Buoy AddressIndex: Not called by owner');
        _;
    }
    
    //pass ownership to govproxy when addresses set, onlyOwner modifier removed for testing
    function changeOwner(address newaddress) public  {
        owner = newaddress;
    }
    
    function setBuoy(address newaddress) public onlyOwner {
        buoy = newaddress;
    }
    
    function getBuoy() public view returns(address) {
        return(buoy);
    }

    function setUniswap(address newaddress) public onlyOwner {
        uniswapToken = newaddress;
    }
    
    function getUniswap() public view returns(address) {
        return(uniswapToken);
    }

    function setLottery(address newaddress) public onlyOwner {
        lottery = newaddress;
    }
    
    function getLottery() public view returns(address) {
        return(lottery); 
    }

    //controller
    function setSmartPool(address newaddress) public onlyOwner {
        smartPool = newaddress;
    }
    
    function getSmartPool() public view returns(address) {
        return(smartPool);
    }
    
    function setVotingBooth(address newaddress) public onlyOwner {
        votingBooth = newaddress;
    }
    
    function getVotingBooth() public view returns(address) {
        return(votingBooth);
    }
    
    function setXBuoy(address newaddress) public onlyOwner {
        xBuoy = newaddress;
    }
    
    function getXBuoy() public view returns(address) {
        return(xBuoy);
    }
    
    function setProxy(address newaddress) public onlyOwner {
        proxy = newaddress;
    }
    
    function getProxy() public view returns(address) {
        return(proxy);
    }

    function setMine(address newaddress) public onlyOwner {
        mine = newaddress;
    }
    
    function getMine() public view returns(address) {
        return(mine);
    }
        

}

// File: contracts\utils\Interfaces.sol

pragma solidity ^0.8.0;

contract Interfaces { }

//for the buoy ERC20
interface Buoy {
    function mineMint(uint, address) external;
    function lotteryMint(uint, address) external;
}

//for the smart pool
interface SPool {
    function setController(address newOwner) external;
    function setPublicSwap(bool publicSwap) external;
    function removeToken(address token) external;
    function changeOwner(address newOwner) external;
    function changeWeight(uint[] calldata) external;
    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut) external;
    function applyAddToken() external;
    function commitAddToken(
        address token,
        uint balance,
        uint denormalizedWeight
    ) external;
    function updateWeightsGradually(
        uint[] calldata newWeights,
        uint startBlock,
        uint endBlock
    ) external;
}
    
//for uniswap deposit
interface UniswapInterface {
    function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

//for the address interface
interface  IAddressIndex {
    function setBuoy(address newaddress) external;
    function getBuoy() external view returns(address);
    function setUniswap(address newaddress) external;
    function getUniswap() external view returns(address);
    function setBalancerPool(address newaddress) external;
    function getBalancerPool() external view returns(address);
    function setSmartPool(address newaddress) external;
    function getSmartPool() external view returns(address);
    function setXBuoy(address newaddress) external;
    function getXBuoy() external view returns(address);
    function setProxy (address newaddress) external;
    function getProxy() external view returns(address);
    function setMine(address newaddress) external;
    function getMine() external view returns(address);
    function setVotingBooth(address newaddress) external;
    function getVotingBooth() external view returns(address);
    function setLottery(address newaddress) external;
    function getLottery() external view returns(address);
}

//for the xbuoy NFT
interface IBuoy {
    function approve(address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns(address);
    function burn(uint _id) external;
    function setBuoyMine(address newAddress) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function setNFT(uint,uint,uint) external;
    function killNFT(uint) external;
    function viewNFT(uint id) external view returns(
        bool active,
        uint contributed, 
        uint allotment, 
        uint rewards, 
        uint payouts, 
        uint nextClaim,
        address platform);
    function craftNFT(
        address sender, 
        uint contributed, 
        uint allotment, 
        uint rewards, 
        uint payouts, 
        uint nextClaim,
        address platform
        ) external;
}

//for the liquidity staking mine
interface Mine {
    function setStakingActive(bool active) external;
    function setSwapingActive(bool active) external;
    function changeStakingMax(uint[] calldata newMax) external;
    function changeStakingShare(uint[] calldata newShare) external;
}

interface IProxy {
    function _beginAddToken(address token, uint balance, uint weight) external;
    function _beginRemoveToken(address token) external;
    function _setSwapFee(uint _swapFee) external; 
    function _setController(address x) external; 
    function _updateWeights(uint[] calldata x) external; 
    function _setSwapingActive(bool active) external;
}

interface ILottery {
    function setShare(uint[] calldata array) external;
    function setDrawLength(uint) external;
    function setIncrementing(uint uintArray, bool boolArray) external;
}

// File: contracts\Lottery.sol

pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// File: v0.8/dev/VRFRequestIDBase.sol

pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// File: v0.8/dev/VRFConsumerBase.sol

pragma solidity ^0.8.0;


abstract contract VRFConsumerBase is VRFRequestIDBase {


  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;


  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee,
    uint256 _seed
  )
    internal
    returns (
      bytes32 requestId
    )
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
    nonces[_keyHash] = nonces[_keyHash] + 1;
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
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// File: Lottery.sol

pragma solidity ^0.8.0;




contract Lottery is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public increment;
    uint256 public ticketPrice;
    uint256[] public shareSplit; //winner, dono, burn
    uint256 public draws; //counter for draws
    uint256 public drawn; //counter for completed draws
    uint256 public drawLength; //length of draws
    uint256 public checkDate;

    bool public increasing;

    address burnWallet = 0x000000000000000000000000000000000000dEaD;
    address donationWallet;
    address index;

    mapping(uint => Lotto) public lottoMapping;

    struct Lotto {
        uint drawNumber;
        uint tickets;
        uint ticketPrice;
        uint increment;
        uint buoy;
        uint[] shares;
        address[] players;
        address winner;
        bool increasing;
        bool ended;
    }

    constructor(address x) 
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator //rinkeby
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token //rinkeby
        )
    {
        donationWallet = 0x68C44e70F2CcA1BC55Ce6dcB0267741142Ecf435; //rinkeby
        ticketPrice = 1*(10**18);
        shareSplit = [90,5,5];
        drawLength = 5 minutes;
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311; //rinkeby
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
        drawn = 1;
        index = x;
        timeCheck();
    }

//==================enactable function==================//  Set require voting booth
    function setShare(uint[] calldata array) public {
        require(array[0]+array[1]+array[2] == 100, 'Values do not total 100');
        shareSplit = array;
    }

    function setDrawLength(uint x) public {
        drawLength = x;
    }

    function setIncrementing(uint x, bool y) public {
        increment = x;
        increasing = y;
    }

//======================draw function====================//
    function timeCheck() public {
        if(block.timestamp > checkDate) {
            checkDate = block.timestamp + drawLength;
            draws++;
            lottoMapping[draws].drawNumber = draws;
            lottoMapping[draws].ticketPrice = ticketPrice;
            lottoMapping[draws].increment = increment;
            lottoMapping[draws].increasing = increasing;
            lottoMapping[draws].shares = shareSplit;
        }
    }

    function buyTickets(uint amount) public {
        timeCheck();
        IERC20 buoy = IERC20(IAddressIndex(index).getBuoy());
        uint charge;
        for(uint i; i < amount; i++) {
            charge = charge + lottoMapping[draws].ticketPrice;
            lottoMapping[draws].tickets++;
            uint length = lottoMapping[draws].players.length + 1;
            lottoMapping[draws].players.push(msg.sender);
            if(lottoMapping[draws].increasing == true) {lottoMapping[draws].ticketPrice = lottoMapping[draws].ticketPrice + lottoMapping[draws].increment;}
        }
        lottoMapping[draws].buoy = lottoMapping[draws].buoy + charge;
        buoy.transferFrom(msg.sender, address(this), charge);
    }
    
    function finalizeDraw(uint256 userProvidedSeed) public returns (bytes32 requestId) {
        timeCheck();
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract");
        if(draws > lottoMapping[drawn].drawNumber) {
            return requestRandomness(keyHash, fee, userProvidedSeed);
        }
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint randomResult = randomness % lottoMapping[drawn].players.length;
        lottoMapping[drawn].winner = lottoMapping[drawn].players[randomResult];
    }

    function payout() public {
        require(lottoMapping[drawn].ended == false, 'Draw ended');
        require(lottoMapping[drawn].winner != address(0), 'Winner not yet chosen');
        IERC20 buoy = IERC20(IAddressIndex(index).getBuoy());
        uint winShare = (lottoMapping[drawn].buoy * lottoMapping[drawn].shares[0]) / 100;
        uint donoShare = (lottoMapping[drawn].buoy * lottoMapping[drawn].shares[1]) / 100;
        uint bShare = (lottoMapping[drawn].buoy * lottoMapping[drawn].shares[2]) / 100;
        buoy.transfer(lottoMapping[drawn].winner, winShare);
        buoy.transfer(donationWallet, donoShare);
        buoy.transfer(burnWallet, bShare);
        lottoMapping[drawn].ended = true;
        drawn++;
    }

//=====================View Functions========================//
    function seeShares(uint d) public view returns(uint,uint,uint) {
        uint winShare = lottoMapping[d].shares[0];
        uint donoShare = lottoMapping[d].shares[1];
        uint burnShare = lottoMapping[d].shares[2];
        return(winShare,donoShare,burnShare);
    }

    function seePlayers(uint d) public view returns(address[] memory) {
        uint length = lottoMapping[d].players.length;
        address[] memory players = new address[](length);
        for(uint i; i < length; i++) {
            players[i] = lottoMapping[d].players[i];
        }
        return(players);
    }
}