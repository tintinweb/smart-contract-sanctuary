/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-30
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
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

library SafeMath {

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

// @dev using 0.8.0.
// Note: If changing this, Safe Math has to be implemented!

pragma solidity 0.8.6;
pragma experimental ABIEncoderV2;

contract rigelSmartBidContract is  Ownable{
    using SafeMath for uint256;
    IERC20 rigel;
    
    struct biddersInfo {
        uint256 _bidAmount;
        uint timeOut;
        address user;
    } 
    
    
    struct CreateBid {
        IERC20 token;
        address highestBidder;
        uint256 initiialBiddingAmount;
        uint timeOut;
        uint256 totalBidding;
        uint256 highestbid;
        uint256 numberOfRandomAddress;
        uint256 devPercentage;
        uint256 positionOneSharedPercentage;
        uint256 positionTwoSharedPercentage;
        uint256 positionThreeSharedPercentage;
        uint256 randomUserSharedPercentage;
    }
    
    mapping (uint256 => mapping (address => biddersInfo)) public bidders;
    mapping (uint256 => address[]) public projBidders;
    mapping (address => bool) public isAdminAddress;
    
    address public devAddress;
    address[] temporaryOtherLast3Address;
    
    uint256 public mustNotExceed;
    CreateBid[] public request_data_in_Bidding;
    
    event bidding(
        address indexed userAddress,
        uint256 stakedAmount,
        uint256 Time
    );
    
    event luckyWinner(
        address indexed lWinner,
        uint256 amount,
        uint time
    );
    
    event devClaim(
        address indexed sender,
        uint256 amount,
        uint time
    );
    
    event distribute(
        address indexed firstBidder,
        uint256 firtBidderReward,
        address indexed secondBidder,
        uint256 secondBidderReward,
        address indexed thirdBidder,
        uint256 thirdBidderReward,
        uint time
    );
    
    /*
    
     rigel token: 0x9f0227A21987c1fFab1785BA3eBa60578eC1501B
    */

constructor(
        IERC20 bidToken,
        uint bidTimeOut,
        uint256 _startBidWith,
        uint256 _devPercentage,
        uint256 _positionOneSharedPercentage,
        uint256 _positionTwoSharedPercentage,
        uint256 _positionThreeSharedPercentage,
        uint256 _randomUserSharedPercentage,
        uint256 _numberOfRandomADDRToPick) 
    {
           
        isAdminAddress[_msgSender()] = true;
        address dummyAddress = 0x0000000000000000000000000000000000000000;
        devAddress = _msgSender();
        
        mustNotExceed = 2E18;
        
        request_data_in_Bidding.push(CreateBid({
            token : bidToken,
            highestBidder: dummyAddress,
            timeOut: block.timestamp.add(bidTimeOut),
            initiialBiddingAmount: _startBidWith,
            totalBidding: 0,
            highestbid: 0,
            numberOfRandomAddress : _numberOfRandomADDRToPick,
            devPercentage: _devPercentage,
            positionOneSharedPercentage: _positionOneSharedPercentage,
            positionTwoSharedPercentage: _positionTwoSharedPercentage,
            positionThreeSharedPercentage: _positionThreeSharedPercentage,
            randomUserSharedPercentage: _randomUserSharedPercentage
        }));
    }
    
    modifier onlyAdmin() {
        require(isAdminAddress[_msgSender()], "Caller has to have an admin Priviledge");
        _;
    }
    
    function bidLength() external view returns (uint256) {
        return request_data_in_Bidding.length;
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
    
    function BiddingMustNotBGreaterThan(uint256 _mustNotExceed) public onlyAdmin {
        mustNotExceed = _mustNotExceed;
    }
    
    function addBid(
        IERC20 bidToken,
        uint256 _startBidWith,
        uint _bidTimeOut,
        uint256 _devPercentage,
        uint256 _numberOfRandomADDRToPick,
        uint256 _positionOneSharedPercentage,
        uint256 _positionTwoSharedPercentage,
        uint256 _positionThreeSharedPercentage,
        uint256 _randomUserSharedPercentage
        ) public onlyAdmin {
            
        uint bidTimeOut = block.timestamp.add(_bidTimeOut);
        
        request_data_in_Bidding.push(CreateBid({
            token : bidToken,
            highestBidder : 0x0000000000000000000000000000000000000000,
            timeOut: bidTimeOut,
            initiialBiddingAmount : _startBidWith,
            totalBidding : 0,
            highestbid : 0,
            numberOfRandomAddress : _numberOfRandomADDRToPick,
            devPercentage : _devPercentage,
            positionOneSharedPercentage : _positionOneSharedPercentage,
            positionTwoSharedPercentage : _positionTwoSharedPercentage,
            positionThreeSharedPercentage : _positionThreeSharedPercentage,
            randomUserSharedPercentage : _randomUserSharedPercentage
        }));
    }
    
    function submitBid(uint256 _pid, uint256 _quantity) public{
        CreateBid storage bid = request_data_in_Bidding[_pid];
        
        if (bid.totalBidding == 0) {
            require(_quantity >= bid.initiialBiddingAmount, "BID AMOUNT MUST BE GREATER THAN initial bid amount");
        }
        
        if (bid.totalBidding > 0) {
            require(_quantity > bid.highestbid, "BID MUST BE GREATER THAN HIGHEST BID");
            require(_quantity <= (bid.highestbid.add(mustNotExceed)), "BID AMOUNT MUST BE LESS THAN OR EQUAL TO 2RGP");
            require(block.timestamp < bid.timeOut, "RGP: BIDDING TIME ELLAPSE");
        }
        
        bid.token.transferFrom(_msgSender(), address(this), _quantity);
        updatePool(_pid, _quantity);
        
        projBidders[_pid].push(_msgSender());
        
        emit bidding(_msgSender(), _quantity, block.timestamp);
    }
    
    function DistributeRewardsWithOther3(uint256 pid) public {
        CreateBid storage bid = request_data_in_Bidding[pid];
        require(bid.totalBidding > 0, "All distribution have been made");
        require(block.timestamp > bid.timeOut, "RGP: BIDDING IS STILL IN PROGRESS");
        
        (address FirstTBidder, address secondTBidder, address thirdTBidder) = Top3Bidders(pid);
        (, , , uint256 forRandUser, uint256 devShare, ) = position(pid);
        
        require(FirstTBidder == _msgSender() || secondTBidder == _msgSender() || thirdTBidder == _msgSender() || devAddress == _msgSender(), "Rigel: NOT ELIGIBLE TO CALL");
        
        fundTopBidders(pid);
        
        uint256 projLength = projBidders[pid].length;
        
        
        for(uint256 i = projLength.sub(3 + 1); i >= projLength.sub(3 + bid.numberOfRandomAddress); i--) {
            temporaryOtherLast3Address.push(projBidders[pid][i]);
        }
        
        for (uint256 j = 0; j < temporaryOtherLast3Address.length; j++) {
            address wallet = temporaryOtherLast3Address[j];
            bid.token.transfer(wallet, forRandUser);
            emit luckyWinner(wallet, forRandUser, block.timestamp);
        }
        
        delete temporaryOtherLast3Address;
        
        emit devClaim(_msgSender(), devShare, block.timestamp);
    }
    
    function distributeRewardsWithRandomness(uint256 pid) public returns (uint256[] memory expandedValues) {
        CreateBid storage bid = request_data_in_Bidding[pid];
        require(bid.totalBidding > 0, "All distribution have been made");
        require(block.timestamp > bid.timeOut, "RGP: BIDDING IS STILL IN PROGRESS");
        
        (address FirstTBidder, address secondTBidder, address thirdTBidder) = Top3Bidders(pid);
        (, , , uint256 forRandUser, uint256 devShare, ) = position(pid);
        
        uint256 proj = projBidders[pid].length;
        
        require(FirstTBidder == _msgSender() || secondTBidder == _msgSender() || thirdTBidder == _msgSender() || devAddress == _msgSender(), "Rigel: NOT ELIGIBLE TO CALL");
       
        fundTopBidders(pid);
        
        for (uint256 i = 0; i < bid.numberOfRandomAddress; i++) {
            expandedValues = new uint256[](bid.numberOfRandomAddress);
            expandedValues[i] = uint256((keccak256(abi.encode(proj, i)))).mod(proj.sub(3));
            
            address _wallet = projBidders[pid][i];
            bid.token.transfer(_wallet, forRandUser);
            emit luckyWinner(_wallet, forRandUser, block.timestamp);
            
        }
       
        
        emit devClaim(devAddress, devShare, block.timestamp);
        
        return expandedValues;
    }
    
    function resetBiddingProcess(uint256 _pid, uint _bidTimeOut, uint256 _bidAmount) public onlyAdmin {
        CreateBid storage bid = request_data_in_Bidding[_pid];
        require(bid.totalBidding == 0, "Rigel: Distribute Reward First");
        require(block.timestamp > bid.timeOut, "RGP: CANT RESET BIDDING WHY IT STILL IN PROGRESS");
        
        delete projBidders[_pid];
        
        bid.timeOut = _bidTimeOut;
        bid.initiialBiddingAmount = _bidAmount;
        bid.highestBidder = 0x0000000000000000000000000000000000000000;
        bid.totalBidding = 0;
        bid.highestbid = 0;
    }

    function position(uint256 pid) internal view returns(uint256 positionOne, uint256 positionTwo,  uint256 positionThree , uint256 forRandUser, uint256 devShare, uint256 rand) {
        CreateBid storage bid = request_data_in_Bidding[pid];
        uint256 _positionOne = bid.totalBidding * bid.positionOneSharedPercentage / 100E18;
        
        uint256 _positionTwo = bid.totalBidding * bid.positionTwoSharedPercentage / 100E18;
        
        uint256 _positionThree = bid.totalBidding * bid.positionThreeSharedPercentage / 100E18;
        uint256 RandUser = (bid.totalBidding * bid.randomUserSharedPercentage / 100E18 / bid.numberOfRandomAddress);
        uint256 divforRandUser = (bid.totalBidding * bid.randomUserSharedPercentage / 100E18);
        
        uint256 _devShare = bid.totalBidding * bid.devPercentage / 100E18;
        
        return (_positionOne, _positionTwo, _positionThree, RandUser, _devShare, divforRandUser);
    }
    
    function fundTopBidders(uint256 pid) internal {
        CreateBid storage bid = request_data_in_Bidding[pid];
        (address FirstTBidder, address secondTBidder, address thirdTBidder) = Top3Bidders(pid);
        (uint256 positionOne, uint256 positionTwo, uint256 positionThree, , uint256 devShare, uint256 rand ) = position(pid);
        
        bid.totalBidding = bid.totalBidding - positionOne - positionTwo - positionThree - rand - devShare;
        
        bid.token.transfer(FirstTBidder, positionOne);
        bid.token.transfer(secondTBidder, positionTwo);
        bid.token.transfer(thirdTBidder, positionThree);
        bid.token.transfer(devAddress, devShare);
        
        emit distribute(FirstTBidder, positionOne, secondTBidder, positionTwo, thirdTBidder, positionThree, block.timestamp);
        
    }
    
    function updatePool(uint256 _pid, uint256 _quantity) internal  {
        CreateBid storage bid = request_data_in_Bidding[_pid];
        biddersInfo storage bidder = bidders[_pid][_msgSender()];
        
        bid.highestbid = _quantity;
        bid.highestBidder = _msgSender();
        bid.totalBidding = bid.totalBidding.add(_quantity);
        
        bidder._bidAmount = _quantity;
        bidder.timeOut = block.timestamp;
        bidder.user = _msgSender();
    }

    function Top3Bidders(uint256 pid) public view returns(address FirstTBidder, address secondTBidder, address thirdTBidder) {
        address user1 = projBidders[pid][projBidders[pid].length.sub(1)];
        address user2 = projBidders[pid][projBidders[pid].length.sub(2)];
        address user3 = projBidders[pid][projBidders[pid].length.sub(3)];
        
        return (user1, user2, user3);
    }
    
    function projID(uint256 _pid) public view returns(uint256) {
        return projBidders[_pid].length;
    }
    
    function getTopBid(uint256 _pid) public view returns (address, uint256, uint) {
        CreateBid storage bid = request_data_in_Bidding[_pid];
        return (bid.highestBidder, bid.highestbid, bid.timeOut);
    }
    
    function withdrawTokenFromContract(address tokenAddress, uint256 _amount, address _receiver) external onlyOwner {
        IERC20(tokenAddress).transfer(_receiver, _amount);
    }

    function setDev( address _devAddress) external onlyOwner () {
       devAddress = _devAddress;
    }
 
}