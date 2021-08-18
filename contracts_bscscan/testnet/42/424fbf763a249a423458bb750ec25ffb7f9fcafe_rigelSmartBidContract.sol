/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-21
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

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

// @dev using 0.8.0.
// Note: If changing this, Safe Math has to be implemented!

pragma solidity 0.8.6;

contract rigelSmartBidContract is  Context{
    using SafeMathChainlink for uint256;
    IERC20 rigel;
    
    struct biddersInfo {
        uint256 _bidAmount;
        uint timeOut;
        address user;
    } 
    

    struct CreateBid {
        IERC20 token;
        address highestBidder;
        uint256 bidAmount;
        uint timeOut;
        uint256 totalBidding;
        uint256 highestbid;
    }
    
    mapping (uint256 => mapping (address => biddersInfo)) public bidders;
    mapping (uint256 => address[]) public projBidders;
    mapping (address => bool) public isAdminAddress;
    
    address public owner;
    address private devAddress;
    address[] claimers;
 
    uint256 public numberOfRandomAddess;
    uint256 public amountToBeShare;
    address[] holderAccts;
    
    CreateBid[] public createBid;
    
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
    
    /*
     rigel token: 0x9f0227A21987c1fFab1785BA3eBa60578eC1501B
    */

constructor(IERC20 bidToken) {
           
            uint bidTimeOut = block.timestamp.add(400);
            owner = _msgSender();
            isAdminAddress[_msgSender()] = true;
            address dummyAddress = 0x0000000000000000000000000000000000000000;
            devAddress = _msgSender();
            numberOfRandomAddess = 1;
            amountToBeShare = 10E18;
            
            createBid.push(CreateBid({
                token : bidToken,
                highestBidder: dummyAddress,
                timeOut: bidTimeOut,
                bidAmount: 5e18,
                totalBidding: 0,
                highestbid: 0
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
        createBid.push(CreateBid({
            token : bidToken,
            highestBidder : 0x0000000000000000000000000000000000000000,
            timeOut: bidTimeOut,
            bidAmount : _bidAmount,
            totalBidding : 0,
            highestbid : 0
        }));
    }
    
    function submitBid(uint256 _pid, uint256 _quantity) public returns(bytes32 _userHash){
       
        CreateBid storage bid = createBid[_pid];
        biddersInfo storage bidder = bidders[_pid][_msgSender()];
        
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
        }
        
        
        emit bidding(_msgSender(), _quantity, block.timestamp);
        return _userHash;
    }
    
    function claim(uint256 pid) external returns (bool) {
       
            CreateBid storage bid = createBid[pid];
            uint256 _amount = bid.totalBidding.mul(amountToBeShare).div(100E18);
            
            if (claimers.length == 0) {
                if(block.timestamp >= bid.timeOut){
                    uint256 projLength = projBidders[pid].length;
                    
                    for (uint256 i = projLength.sub(numberOfRandomAddess); i < projLength; i++) {
                        
                        claimers.push(projBidders[pid][i]);
                    }
                    for (uint256 i = 0; i < claimers.length; i++) {
                        
                            address wallet = claimers[i];
                            bid.token.transfer(wallet, _amount);
                            emit luckyWinner(wallet, _amount, block.timestamp);
                    }
                }
                return true;
            }else {return false;}
            
            delete claimers;
           assert( claimers.length == 0);
    }
    
    function generateRandomnessAndShare(uint256 _pid) public returns (uint256[] memory expandedValues) {
        CreateBid storage bid = createBid[_pid];
        expandedValues = new uint256[](numberOfRandomAddess);
        for (uint256 i = 0; i < 5; i++) {
            expandedValues[i] = uint256((keccak256(abi.encode(projBidders[_pid].length, i)))).mod(projBidders[_pid].length);
        }
        if (projBidders[_pid].length > 2) {
            uint256 _amount = bid.totalBidding.mul(amountToBeShare).div(100E18);
            holderAccts.push(projBidders[_pid][expandedValues[0]]);
            holderAccts.push(projBidders[_pid][expandedValues[1]]);
            holderAccts.push(projBidders[_pid][expandedValues[2]]);
            
            for (uint i = 0; i < holderAccts.length; i ++) {
                bid.token.transfer(holderAccts[i], _amount);
            }
            emit luckyWinner(address(this), _amount, block.timestamp);
        }
        
        return expandedValues;
    }
    
    function amountShareAmongBidders(uint256 _newAmount) public onlyAdmin {
        amountToBeShare = _newAmount;
    }
    
    function changeNumberOfandAddress(uint256 newNumber) public onlyAdmin {
        numberOfRandomAddess = newNumber;
    }
    
    function getBidTimeOut(uint256 _pid) public view returns(uint256 _timeout) {
        CreateBid storage bid = createBid[_pid];
        return bid.timeOut;
    }

    
    function projID(uint256 _pid) public view returns(uint256) {
        return projBidders[_pid].length;
    }

    function devClaimer(uint256 _pid) public onlydev(){
        CreateBid storage bid = createBid[_pid];
        uint256 devAmount = bid.totalBidding.mul(20E18).div(100E18);
        bid.token.transfer(devAddress, devAmount);
        emit devClaim(_msgSender(), devAmount, block.timestamp);
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

    function setDev( address _devAddress) external onlyOwner () {
       devAddress = _devAddress;
    }
 
}