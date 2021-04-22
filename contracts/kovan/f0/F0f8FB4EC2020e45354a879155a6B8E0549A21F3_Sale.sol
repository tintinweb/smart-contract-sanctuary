// SPDX-License-Identifier: UNLICENSED

pragma solidity <=0.8.4;

library SafeMath {
    
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "multiplication overflow");

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.8.4;

import "./SafeMath.sol";

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ERC721TokenReceiver
{
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);
}

interface AggregatorV3Interface {

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns(string memory);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to) external;
}

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

}

contract Sale is ReentrancyGuard, ERC721TokenReceiver {

    IERC721 public niftyPunks;

    address public admin;
    uint256 public price;           // In-terms of USD = $ 1 = 100000000
    uint256 public sold;
    uint256 public blindGifts;
    address[3] public leaderboard;
    uint256 public limit;
    uint8 public discount;

    mapping(bytes => address) private oracles;
    mapping(bytes => address) private contracts;
    mapping(address => uint256) public totalPurchased;
    mapping(address => bool) public discounted;

    event Purchase(address indexed purchaser, uint256 amount);

    modifier hasAccess(){
        require(msg.sender == admin);
        _;
    }

    modifier isZero(address _addr) {
        require(_addr != address(0));
        _;
    }

    constructor(address punksContract_, uint256 initialPrice_){
        admin = msg.sender;
        niftyPunks = IERC721(punksContract_);
        price = initialPrice_;
    }

    function updateDiscountedWallet(address _user, bool _isDiscounted) public virtual isZero(_user) hasAccess returns(bool) {
        discounted[_user] = _isDiscounted;
        return true;
    }

    function updateDiscount(uint8 _discount) public virtual hasAccess returns(bool) {
        discount = _discount;
        return true;
    }

    function mintBlindGift(address _to, uint256 _total) public virtual hasAccess nonReentrant returns(bool){
        for(uint256 i=0; i < _total; i++){
            niftyPunks.mint(_to);
            blindGifts += 1;
        }
        return true;
    }

    function buyWithEth(uint256 _punks) public virtual payable nonReentrant returns(bool) {
        require(resolveToken("ETH", msg.sender,  _punks, 18) <= msg.value,"Underflow Error");
        require(_punks <= limit,"Max Mint Limit Per Transaction");
        for(uint256 i = 0; i < _punks; i++){
            sold+= 1;
            totalPurchased[msg.sender] += 1;
            niftyPunks.mint(msg.sender);
        }
        payable(admin)
        .transfer(
            SafeMath.div(
            SafeMath.mul(msg.value,95),100)
        );
        resolveRank(msg.sender);
        emit Purchase(msg.sender, _punks);
        return true;
    }

    function buyWithBnB(uint256 _amount, uint256 _punks) public virtual nonReentrant returns(bool){
        require(resolveToken("BNB", msg.sender, _punks , 18) <= _amount, "Underflow Error");
        require(_punks <= limit,"Max Mint Limit Per Transaction");
        require(IERC20(contracts[bytes("BNB")]).balanceOf(msg.sender) >= _amount, "Insufficient Balance");
        require(IERC20(contracts[bytes("BNB")]).allowance(msg.sender,address(this)) >= _amount, "Allowance Error");
        for(uint256 i = 0; i < _punks; i++){
            sold+= 1;
            totalPurchased[msg.sender] += 1;
            niftyPunks.mint(msg.sender);
        }
        IERC20(contracts[bytes("BNB")])
        .transferFrom(
            msg.sender, 
            admin, 
            SafeMath.div(SafeMath.mul(_amount,95),100)
        );
        resolveRank(msg.sender);
        emit Purchase(msg.sender, _punks);
        return true;
    }

    function buyWithUSDC(uint256 _amount, uint256 _punks) public virtual nonReentrant returns(bool){
        require(resolveStableCoins(_punks, 6) <= _amount, "Underflow Error");
        require(_punks <= limit,"Max Mint Limit Per Transaction");
        require(IERC20(contracts[bytes("USDC")]).balanceOf(msg.sender) >= _amount, "Insufficient Balance");
        require(IERC20(contracts[bytes("USDC")]).allowance(msg.sender,address(this)) >= _amount, "Allowance Error");
        for(uint256 i = 0; i < _punks; i++){
            sold+= 1;
            totalPurchased[msg.sender] += 1;
            niftyPunks.mint(msg.sender);
        }
        IERC20(contracts[bytes("USDC")])
        .transferFrom(
            msg.sender, 
            admin,
            SafeMath.div(SafeMath.mul(_amount,95),100)
        );
        resolveRank(msg.sender);
        emit Purchase(msg.sender, _punks);
        return true;
    }

    function resolveRank(address user) private {
        uint256 total = totalPurchased[user];
        if(total > totalPurchased[leaderboard[0]]){
            address second = leaderboard[0];
            address third = leaderboard[1];
            leaderboard[0] = user;
            leaderboard[1] = second;
            leaderboard[2] = third;
        }
        else if(total > totalPurchased[leaderboard[1]]){
            leaderboard[2] = leaderboard[1];
            leaderboard[1] = user;
        }
        else if(total > totalPurchased[leaderboard[2]]){
            leaderboard[2] = user;
        }
    }

    function resolveStableCoins(uint256 _decimal, uint256 totalPunks) public virtual view returns(uint256){
        uint256 nftPrice = SafeMath.div(price, 10 ** 8);
        uint256 costPerPunk = SafeMath.mul(nftPrice, 10 ** _decimal);
        return SafeMath.mul(costPerPunk, totalPunks);
    }

    function distribute() public hasAccess nonReentrant returns(bool) {
        uint256 eth = SafeMath.div(address(this).balance,3);
        uint256 usdc = SafeMath.div(IERC20(contracts[bytes("USDC")]).balanceOf(address(this)),3);
        uint256 bnb = SafeMath.div(IERC20(contracts[bytes("BNB")]).balanceOf(address(this)),3);
        for(uint256 i=0; i<3; i++){
            if(leaderboard[i] != address(0)){
                payable(leaderboard[i]).transfer(eth);
                IERC20(contracts["USDC"]).transferFrom(address(this), leaderboard[i], usdc);
                IERC20(contracts["BNB"]).transferFrom(address(this), leaderboard[i], bnb);
            }
        }
        return true;
    }

    function resolveToken(string memory _token, address user, uint256 totalPunks ,uint256 _decimal) public virtual view returns(uint256){
        uint256 tokenPrice = uint256(fetchPrice(_token));                         // 8 - decimal token price
        uint256 costPerPunk = SafeMath.div(SafeMath.mul(price,10 ** _decimal),tokenPrice);
        
        uint256 discountedPrice = 0;
        if(discounted[user] && discount != 0){
         discountedPrice = SafeMath.mul(costPerPunk, uint256(discount));
         discountedPrice = SafeMath.div(discountedPrice, 100);
        }
        return SafeMath.mul(costPerPunk,totalPunks);
    }
    
    function setPrice(uint256 _price) public hasAccess returns(bool){
        price = _price;
        return true;
    }

    function setOracle(address _oracle, string memory _token) public hasAccess isZero(_oracle) returns(bool){
        oracles[bytes(_token)] = _oracle;
        return true; 
    }

    function setContract(address _contract, string memory _token) public hasAccess isZero(_contract) returns(bool){
        contracts[bytes(_token)] = _contract;
        return true; 
    }

    function fetchPrice(string memory _token) public virtual view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(oracles[bytes(_token)]).latestRoundData();
        return price;
    }

    function fetchOracle(string memory _token) public virtual view returns (address){
        return oracles[bytes(_token)];
    }

    function fetchContract(string memory _token) public virtual view returns (address){
        return contracts[bytes(_token)];
    }

    function drain(uint256 tokenId) public virtual hasAccess returns(bool){
        niftyPunks.safeTransferFrom(address(this), admin, tokenId);
        return true;
    }

    function transferOwnership(address _newAdmin) public hasAccess returns(bool){
        require(_newAdmin != address(0),"Invalid Address");
        admin = _newAdmin;
        return true;
    }
    
    function setLimit(uint256 _limit) public hasAccess returns(bool){
        require(_limit > 0 && _limit < 100, "Limit Out of Bounds");
        limit = _limit;
        return true;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        pure
        override
        returns(bytes4)
    {
        _operator;
        _from;
        _tokenId;
        _data;
        return 0x150b7a02;
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}