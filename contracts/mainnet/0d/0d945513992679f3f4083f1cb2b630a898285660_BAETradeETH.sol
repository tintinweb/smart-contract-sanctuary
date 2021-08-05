/**
 *Submitted for verification at Etherscan.io on 2021-01-13
*/

pragma solidity ^0.7.0;

interface ERC165 {
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

interface IERC1155 /* is ERC165 */ {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function creators(uint256 artwork) external view returns (address);
}


library SafeMath {

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



interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract BAETradeETH {
  using SafeMath for uint256;
  //using SafeERC20 for IUniswapV2Pair;


  modifier onlyOwner {
    assert(msg.sender == owner);
    _;
  }

  mapping (bytes32 => uint256) public orderFills;
  address payable public owner;
  address payable public feeAccount;
  address public baeContract;
  uint256 public fee = 40;
  uint256 public creatorFee = 50;
  mapping (bytes32 => bool) public traded;
  event Order(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Cancel(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade(uint256 tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, address get, address give, bytes32 hash);

  constructor(address baeContract_) {
    owner = 0x486082148bc8Dc9DEe8c9E53649ea148291FF292;
    feeAccount = 0x44e86f37792D4c454cc836b91c84D7fe8224220b;
    baeContract = baeContract_;
  }

  modifier onlyAdmin {
    require(msg.sender == owner, "Not Owner");
    _;
  }

  receive() external payable {

  }

  function changeFee(uint256 _amount) public onlyAdmin{
    fee = _amount;
  }

  function changeCreatorFee(uint256 _amount) public onlyAdmin{
    creatorFee = _amount;
  }

  function invalidateOrder(uint256[5] memory tradeValues, address[2] memory tradeAddresses, uint8 v, bytes32[2] memory rs) public{
    bytes32 orderHash = keccak256(abi.encodePacked(address(this), tradeAddresses[0], tradeValues[0], tradeValues[1], tradeAddresses[1], tradeValues[2], tradeValues[3], tradeValues[4]));
    require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash)), v, rs[0], rs[1]) == tradeAddresses[1], "Invalid Order");
    orderFills[orderHash] = tradeValues[1];
  }

  function isValidOrder(uint256[5] memory tradeValues, address[2] memory tradeAddresses, uint8 v, bytes32[2] memory rs) public view returns(bool) {
    bytes32 orderHash = keccak256(abi.encodePacked(address(this), tradeAddresses[0], tradeValues[0], tradeValues[1], tradeAddresses[1], tradeValues[2], tradeValues[3], tradeValues[4]));
    if(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash)), v, rs[0], rs[1]) != tradeAddresses[1]){
      return false;
    }
    if(IERC1155(baeContract).balanceOf(tradeAddresses[1], tradeValues[0]) < tradeValues[1] - orderFills[orderHash]){
      return false;
    }
    if(tradeValues[3] < block.timestamp){
      return false;
    }
    return true;
  }

  function buyArtworkETH(uint256[6] memory tradeValues, address payable[2] memory tradeAddresses, uint8 v, bytes32[2] memory rs) public payable returns (bool success) {
    require(tradeValues[3] > block.timestamp, "Expired");
    require(tradeAddresses[0] == address(0), "Not an ETH Trade");
    /* amount is in amountBuy terms */
    /* tradeValues
       [0] token
       [1] prints
       [2] price
       [3] expires
       [4] nonce
       [5] amount
     tradeAddressses
       [0] tokenSell
       [1] maker
     */
    bytes32 orderHash = keccak256(abi.encodePacked(address(this), tradeAddresses[0], tradeValues[0], tradeValues[1], tradeAddresses[1], tradeValues[2], tradeValues[3], tradeValues[4]));
    require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash)), v, rs[0], rs[1]) == tradeAddresses[1], "Invalid Order");

    require(orderFills[orderHash].add(tradeValues[5]) <= tradeValues[1], "Trade amount too high");

    require(msg.value >= tradeValues[2].mul(tradeValues[5]), "Insufficent Balance");
    uint256 amount = (tradeValues[2].mul(tradeValues[5]) );
    IERC1155(baeContract).safeTransferFrom(tradeAddresses[1], msg.sender, tradeValues[0], tradeValues[5],"");
    feeAccount.transfer(amount.mul(10).div(1000));
    owner.transfer(amount.mul(fee).div(1000));
    payable(IERC1155(baeContract).creators(tradeValues[0])).transfer(amount.mul(creatorFee).div(1000));
    tradeAddresses[1].transfer(amount.mul(1000 - fee - creatorFee - 10).div(1000));
    msg.sender.transfer(msg.value - amount);

    orderFills[orderHash] = orderFills[orderHash].add(tradeValues[5]);
    emit Trade(tradeValues[0], tradeValues[5], tradeAddresses[0], tradeValues[2].mul(tradeValues[5]), msg.sender, tradeAddresses[1], orderHash);
    return true;
  }


}