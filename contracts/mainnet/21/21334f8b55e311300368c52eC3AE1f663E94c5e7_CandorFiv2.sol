/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity ^0.6.9;
//SPDX-License-Identifier: UNLICENSED


library SafeMathChainlink {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

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

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

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


abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));

    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);

    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
} 

contract CandorFiv2 is VRFConsumerBase{
    uint[] private entryArray;
    address[] public userAddresses;
    address public owner;
    uint public totalEntry;
    uint public round;
    address[] public winners;
    uint[] public winningNumbers;
    uint public ticketPrice = 10 * 1e6; // 10$ ticket price (6 decimals)
    uint public poolLimit = 200000 * 1e6; // 200000$ pool limit
    uint public adminFee = 50; // 50% admin fee
    uint[10] public rewardArray = [500,250,100,70,30,10,10,10,10,10]; // Change here (Prize % with an additional 0, for 50% use 500)
    IERC20 public token;
    
    bytes32 internal keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
	uint internal fee;
	uint public randomResult;
	uint public oldRandomResult;
	
    struct User{
        bool isEntered;
        uint totalEntries;
        bool isPicked;
    }
    modifier onlyOwner{
        require(msg.sender == owner,"Only owner allowed");
        _;
    }
    mapping(uint => address) public entryMapping;
    mapping(uint => mapping(address => User)) public userInfo;
    
    event RandomNumberGenerated(bytes32,uint256);
    event EntryComplete(address,uint,uint);
    event WinnerPicked(address[],uint[]);
    
    function setTicketPrice(uint value) external onlyOwner{
       ticketPrice = value; 
    }
    
    function setPoolLimit(uint value) external onlyOwner{
        poolLimit = value;
    }
    
    function setAdminFee(uint value) external onlyOwner{
        adminFee = value;
    }
    
    function withdrawLink(uint value) external onlyOwner {
    	require(LINK.transfer(msg.sender, value), "Unable to transfer");
    }
    
    function transferOwnership(address newOwner) external onlyOwner{
        owner = newOwner;
    }
    
    //Mainnet network
    constructor() VRFConsumerBase (
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,  //VRF Coordinator
	        0x514910771AF9Ca656af840dff83E8264EcF986CA   //LINK token
           ) public {
        fee = 2000000000000000000; // 2 LINK
        owner = msg.sender;
        token = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC contract address
    }
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        emit RandomNumberGenerated(requestId,randomResult);
    }
    
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        winners = new address[](0);
        winningNumbers = new uint[](0);
        return requestRandomness(keyHash, fee, getSeed());
    }
    
    function enterLottery(uint256 amount) external {
        require(amount >= ticketPrice && amount <= (poolLimit / 10),"Invalid amount!"); //Change here
        require(!userInfo[round][msg.sender].isEntered,"Already entered!");
        require(token.allowance(msg.sender,address(this)) >= amount,"Set allowance first!");
        bool success = token.transferFrom(msg.sender,address(this),amount);
        require(success,"Transfer failed");
        require(token.balanceOf(address(this)) <= poolLimit,"Pool already full");
        uint ticketCount = amount.div(ticketPrice);
        require((totalEntry + ticketCount) <= (poolLimit / ticketPrice),"Buy lower amount of tickets");
        userInfo[round][msg.sender].totalEntries = ticketCount;
        userInfo[round][msg.sender].isEntered = true;
        entryArray.push(totalEntry);
        entryMapping[totalEntry] = msg.sender; 
        totalEntry += ticketCount;
        userAddresses.push(msg.sender);
        emit EntryComplete(msg.sender,amount,ticketCount);
    }
    
    function pickWinner() external onlyOwner{
        require(userAddresses.length >= 10,"Atleast 10 participants"); //Change here
        require(totalEntry >= 50,"Minimum 50 tickets sold");
        require(oldRandomResult != randomResult,"Update random number first!");
        uint i;
        uint winner;
        address wonUser;
        uint tempRandom;
        uint totalBalance = token.balanceOf(address(this));
        token.transfer(owner,(totalBalance * adminFee) / 100);
        totalBalance -= (totalBalance * adminFee) / 100;
        while(i<10){ //Change here
            winner = calculateWinner((randomResult % totalEntry));
            wonUser = entryMapping[winner];
            winners.push(wonUser);
            winningNumbers.push(randomResult % totalEntry); 
            token.transfer(wonUser,(totalBalance * rewardArray[i]) / 1000);
            i++;
            tempRandom = uint(keccak256(abi.encodePacked(randomResult, now, i)));
            randomResult = tempRandom;
        }
        emit WinnerPicked(winners,winningNumbers);
        oldRandomResult = randomResult;
        totalEntry = 0;
        entryArray = new uint[](0);
        userAddresses = new address[](0);
        round++;
    }
    
    function getSeed() private view returns(uint) {
		return uint(keccak256(abi.encodePacked(block.difficulty, now, userAddresses)));
	}
	
	function calculateWinner(uint target) internal view returns(uint){
	    uint last = entryArray.length; 
	    uint first = 0;
	    uint mid = 0;
	    if(target <= entryArray[0]){
	        return entryArray[0];
	    }
	    
	    if(target >= entryArray[last-1]){
	        return entryArray[last-1];
	    }
	    
	    while(first < last){
	        mid = (first + last) / 2;
	        
	        if(entryArray[mid] == target){
	            return entryArray[mid];
	        }
	        
	        if(target < entryArray[mid]){
	            if(mid > 0 && target > entryArray[mid - 1]){
	                return entryArray[mid - 1];
	            }
	            
	            last = mid;
	        }
	        else{
	            if(mid < last - 1 && target < entryArray[mid + 1]){
	                return entryArray[mid];
	            }
	            
	            first = mid + 1;
	        }
	    }
	    return entryArray[mid];
	}
	
	function winningChance() public view returns(uint winchance){
	    
	    return(
	        (userInfo[round][msg.sender].totalEntries * 100) / totalEntry);
	}
	
	function lastRoundInfo() external view returns(address[] memory,uint[] memory){
	    return (winners,winningNumbers);
	}
	
	function transferAnyERC20(address _tokenAddress, address _to, uint _amount) public onlyOwner {
	    require(_tokenAddress != address(token),"Not USDC");
        IERC20(_tokenAddress).transfer(_to, _amount);
    }
	
}