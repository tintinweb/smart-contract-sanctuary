/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-04
*/

// SPDX-License-Identifier: MIT
interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// pragma solidity ^0.7.0;

library SafeMathChainlink {

  function add( uint256 a, uint256 b) internal  pure returns ( uint256 ) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub( uint256 a, uint256 b ) internal pure returns ( uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (
      uint256
    )
  {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

contract VRFRequestIDBase {

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

interface LinkTokenInterface {
  function balanceOf(address owner) external view returns (uint256 balance);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
}


abstract contract VRFConsumerBase is VRFRequestIDBase {

    using SafeMathChainlink for uint256;

    uint256 constant private USER_SEED_PLACEHOLDER = 0;
    
    LinkTokenInterface  internal LINK;
    address  private vrfCoordinator;
    mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;
        
    constructor(address _vrfCoordinator, address _link) public {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness)  internal virtual;
    
    function requestRandomness(bytes32 _keyHash, uint256 _fee)
        internal
        returns (bytes32 requestId)
          {
            LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
            uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
            nonces[_keyHash] = nonces[_keyHash].add(1);
            return makeRequestId(_keyHash, vRFSeed);
    }
    
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness ) internal  {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
 }
// @dev using 0.8.0.
// Note: If changing this, Safe Math has to be implemented!

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// pragma solidity >=0.7.0 <0.9.0;
// import "https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.7/dev/VRFConsumerBase.sol";

contract rigelSmartBid is VRFConsumerBase, Context{
    using SafeMathChainlink for uint256;
    IERC20 rigel;
    
    struct biddersInfo {
        uint256 _bidAmount;
        uint timeOut;
        address user;
    } 
    
    // struct StoreBidders {
    //     address _addresses;
    // } 
    
    struct CreateBid {
        IERC20 token;
        address highestBidder;
        uint256 bidAmount;
        uint timeOut;
        uint256 totalBidding;
        uint256 highestbid;
        // bool status;
    }
    
    mapping (uint256 => mapping (address => biddersInfo)) public bidders;
    mapping (uint256 => address[]) public projBidders;
    mapping (uint256 => uint256[]) public randomResult;
    mapping(address => bool) public isAdminAddress;
    mapping(uint256 => mapping(bytes32 => address[])) allBiddersInEachBid;
    
    address public vrfCoordinator;
    LinkTokenInterface link;
    address public owner;
    address private devAddress;
    address[] holderAccts;
    
    bytes32 public keyHash;
    
    uint256 public fee;
    // uint256 public randomResult;
    
    CreateBid[] public createBid;
    
    event bidding(
        address indexed userAddress,
        uint256 stakedAmount,
        uint256 Time
    );
    
    event claimer(
        address indexed userAddress,
        uint256 stakedAmount,
        uint256 Time
    );
    // 0xd9145CCE52D386f254917e481eB44e9943F39138
    // 5000000000000000000
//   constructor( IERC20 bidToken, uint _bidTimeOut, uint256 _bidAmount) {
//       uint bidTimeOut = block.timestamp + _bidTimeOut;
//         owner = msg.sender;
//         createBid.push(CreateBid({
//             token : bidToken,
//             timeOut: bidTimeOut,
//             bidAmount: _bidAmount,
//             totalBidding: 0
//         }));
//     }

// 35000000000000000000

    /*
    
     rigel token: 0x9f0227A21987c1fFab1785BA3eBa60578eC1501B
     VRF Coordinator: 0xa555fC018435bef5A13C6c6870a9d4C11DEC329C
     LINK TOKEN: 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06
     KEYHASH: 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186
    
    */
    
    CreateBid store;
constructor(
    IERC20 bidToken,
    address _vrfCoordinator,
    address _link
    ) VRFConsumerBase(
        _vrfCoordinator,
        _link
        ) public {
            vrfCoordinator = _vrfCoordinator;
            LINK = LinkTokenInterface(_link);
            fee = 0.1e18;
            keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
            uint bidTimeOut = block.timestamp.add(600);
            owner = _msgSender();
            isAdminAddress[_msgSender()] = true;
            address dummyAddress = 0x0000000000000000000000000000000000000000;
            // address[] memory path;
            // path[0] = dummyAddress;
            
            createBid.push(CreateBid({
                token : bidToken,
                highestBidder: dummyAddress,
                timeOut: bidTimeOut,
                bidAmount: 5e18,
                totalBidding: 0,
                highestbid: 0
                // status: true
            }));
    }
    
    // Only allow the owner to do specific tasks
    modifier onlyOwner() {
        require(_msgSender() == owner,"RGP: YOU ARE NOT THE OWNER.");
        _;
    }
    
    // Only allow the dev to do specific tasks
    modifier onlydev() {
        require(_msgSender() == devAddress,"RGP: YOU ARE NOT THE DEV.");
        _;
    }
    
    // only allow admin addresses to do specific
    modifier onlyAdmin() {
        require(isAdminAddress[_msgSender()]);
        _;
    }
    
    function bidLength() external view returns (uint256) {
        return createBid.length;
    }
    
    function multipleAdmin(address[] calldata _adminAddress, bool status) external onlyOwner {
        if (status == true) {
           for(uint256 i = 0; i < _adminAddress.length; i++) {
            isAdminAddress[_adminAddress[i]] = status;
            } 
        } else{
            for(uint256 i = 0; i < _adminAddress.length; i++) {
                delete(isAdminAddress[_adminAddress[i]]);
            } 
        }
    }
    
    function addBid(uint256 _bidAmount, IERC20 bidToken,  uint _bidTimeOut) public onlyAdmin {
        uint bidTimeOut = block.timestamp.add(_bidTimeOut);
        address dummyAddress = 0x0000000000000000000000000000000000000000;
        address[] memory path;
        path[0] = dummyAddress;

        createBid.push(CreateBid({
            token : bidToken,
            highestBidder : 0x0000000000000000000000000000000000000000,
            timeOut: bidTimeOut,
            bidAmount : _bidAmount,
            totalBidding : 0,
            highestbid : 0
            // status : true
        }));
    }
    
    function submitBid(uint256 _pid, uint256 _quantity) public returns(bytes32 _userHash){
       
        CreateBid storage bid = createBid[_pid];
        biddersInfo storage bidder = bidders[_pid][_msgSender()];
        
        // if  (block.timestamp > bid.timeOut) {
        //     bid.status = false;
        // }
        
        if (bid.totalBidding == 0) {
            require(_quantity >= bid.bidAmount, "BID AMOUNT MUST BE GREATER THAN 5");
        }
        
        if (bid.totalBidding > 0) {
            require(_quantity > bid.highestbid, "BID MUST BE GREATER THAN HIGHEST BID");
            require(_quantity <= (bid.highestbid.add(2E18)), "BID AMOUNT MUST BE LESS THAN OR EQUAL TO 2RGP");
            require(block.timestamp < bid.timeOut, "RGP: BIDDING TIME ELLAPSE");
        }
        
        if (bidder.user == _msgSender()) {
            UPBid(_pid, _quantity);
        } else {
            bid.token.transferFrom(_msgSender(), address(this), _quantity);
            updatePool(_pid, _quantity);
            
            projBidders[_pid].push(_msgSender());
            
            _userHash = keccak256(abi.encodePacked(_quantity));
            allBiddersInEachBid[_pid][_userHash] = [_msgSender()];
        }
        
        
        emit bidding(_msgSender(), _quantity, block.timestamp);
        return _userHash;
    }
    
        /// Withdraw a bid that was overbid.
    function claim(uint256 _pid) public returns (bytes32 _requestID) {
        CreateBid storage bid = createBid[_pid];
        
        require(block.timestamp > bid.timeOut, "RGP: BIDDING IS STILL ON PROGRESS");
        
        require(bid.highestBidder != 0x0000000000000000000000000000000000000000, "SORRY, INVALID ADDRESS");
        require(bid.highestBidder != address(0), "SORRY, INVALID ADDRESS");
        require(bid.highestBidder == _msgSender(), "SORRY, YOU ARE NOT THE TOP BIDDER");
        
        uint _amount = bid.totalBidding.mul(30E18).div(100E18);
        bid.token.transfer(_msgSender(), _amount);
        bid.totalBidding = bid.totalBidding.sub(_amount);
        emit claimer(_msgSender(), _amount, block.timestamp);
        return requestRandomness(keyHash, fee);
    }
    
    function fulfillRandomness( bytes32 requestId, uint256 randomness) internal override {
        
        uint256 length = createBid.length;
        
        for (uint256 pid = 0; pid < length; ++pid) {
            CreateBid storage bid = createBid[pid];
            address wallet = projBidders[pid][randomness.mod(projBidders[pid].length.sub(1))];
            uint256 _amount = bid.totalBidding.mul(10E18).div(100E18);
            
            randomResult[pid] = [randomness];
            bid.totalBidding = bid.totalBidding.sub(_amount);
            bid.token.transfer(wallet, _amount);
            
            emit claimer(address(this), _amount, block.timestamp);
        }
    }
    
    function getBidTimeOut(uint256 _pid) public view returns(uint256 _timeout) {
        CreateBid storage bid = createBid[_pid];
        return bid.timeOut;
    }

    
    function projID(uint256 _pid) public view returns(uint256) {
        return projBidders[_pid].length;
    }
    
    function outChainRandom(uint256 _pid, uint256[] memory _number) public onlyOwner returns(bool) {
        CreateBid storage bid = createBid[_pid];
        
         for (uint256 i = 0; i < _number.length; i++) {
            address wallet = projBidders[_pid][_number[i]];
            uint256 _amount = bid.totalBidding.mul(10E18).div(100E18);
            
            bid.token.transfer(wallet, _amount);
            emit claimer(address(this), _amount, block.timestamp);
        }
        return true;
    }
    
    function getnextTopFiveBidders(uint256 _pid) public view returns(address[] memory _topFive) {
        // CreateBid storage bid = createBid[_pid];
        _topFive = projBidders[_pid];
        
        // return bid.allBidders;
    }
    
    function devClaimer(uint256 _pid) public onlydev(){
        CreateBid storage bid = createBid[_pid];
        uint256 devAmount = bid.totalBidding.mul(20E18).div(100E18);
        bid.token.transfer(devAddress, devAmount);
        emit claimer(_msgSender(), devAmount, block.timestamp);
    }
    
    function getTopBid(uint256 _pid) public view returns (address, uint256, uint) {
        CreateBid storage bid = createBid[_pid];
        return (bid.highestBidder, bid.highestbid, bid.timeOut);
    }
    
    function totalBid(uint256 _pid) public view returns (uint256 _bidAmount) {
        CreateBid storage bid = createBid[_pid];
        return (bid.totalBidding);
    }
    
    function UPBid(uint256 _pid, uint256 _quantity) internal  {
        biddersInfo storage bidder = bidders[_pid][msg.sender];
        CreateBid storage bid = createBid[_pid];
        
        bidder._bidAmount = bidder._bidAmount.add(_quantity);
        bidder.timeOut = block.timestamp;
        bidder.user = _msgSender();
            
        bid.highestbid = bidder._bidAmount.add(_quantity);
        bid.highestBidder = _msgSender();
        bid.totalBidding = bid.totalBidding.add(_quantity);
    }
    
    function updatePool(uint256 _pid, uint256 _quantity) internal  {
        CreateBid storage bid = createBid[_pid];
        biddersInfo storage bidder = bidders[_pid][_msgSender()];
        
        bid.highestbid = _quantity;
        bid.highestBidder = _msgSender();
        bid.totalBidding = bid.totalBidding.add(_quantity);
        
        bidder._bidAmount = _quantity;
        bidder.timeOut = block.timestamp;
        bidder.user = _msgSender();
    }

    function withdrawBidToken(uint256 _pid, address _to, uint256 _amount) onlyOwner external {
        CreateBid storage bid = createBid[_pid];
        uint256 Balalance = bid.token.balanceOf(address(this));
        if (_amount > Balalance) {
            bid.token.transfer(_to, Balalance);
        } else {
            bid.token.transfer(_to, _amount);
        }
    }
    
    function sendLink(address _to, uint256 _amount) external onlyOwner returns(bool) {
        uint256 _balance = LINK.balanceOf(address(this));
        if (_amount > _balance) {
            LINK.transfer(_to, _balance);
        } else {
            LINK.transfer(_to, _amount);
        }
    }
    
    function withdrawBNB() external onlyOwner {
        _msgSender().transfer(address(this).balance);
    }
    
    function setDev( address _devAddress) external onlyOwner () {
       devAddress = _devAddress;
    }
 
}