/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

pragma solidity ^0.4.0;

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
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
    
    //開根號
    function sqrt(uint x) internal pure returns(uint) {
        uint z = (x + 1 ) / 2;
        uint y = x;
        while(z < y){
          y = z;
          z = ( x / z + z ) / 2;
        }
        return y;
     }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {

        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

interface ERC20 {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) external view returns (uint256 balance);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
}

interface ERC721 {
    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract Staking{
    ERC20 public JBL_token;
    ERC721 public NFT_token;

    struct Order {
        address nft_addr;
        uint256 ntt_id;
        uint256 nft_type;
        address user_addr;
        uint256 apy;
        uint256 start_time;
    }
    
    
    // event _withdraw(address _addr, uint256 _value, uint256 _time);
    
    Order[] public Orders;
    uint256 [] private apy_num = [1*10**17,1*10**17,5*10**16,5*10**16,0];//'外野手','內野手','捕手','投手','打擊手'
    // mapping (uint256 => Order) public Orders;
    address public owner;
    
    // Order_id => User_addr
    mapping (uint256 => address) private user_order;
    
    
    constructor ()  public {
        owner = msg.sender; 
        _set_JBL_TOKEN(0x2148c3ed475fc0a4c70269641e6b76c2a4b8c855);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    //pay token
    function _set_JBL_TOKEN(address _tokenAddr) internal onlyOwner{
        require(_tokenAddr != 0);
        JBL_token = ERC20(_tokenAddr);
    }
    
    // 質押
    function Staking_NFT(address _nft_addr,uint256 _nft_id) public returns (uint256) {
        NFT_token = ERC721(_nft_addr);
        NFT_token.transferFrom(msg.sender,address(this),_nft_id);
        
        uint256 OrderId = Orders.length;
        Orders.push(Order(_nft_addr,_nft_id,1,msg.sender,apy_num[1],now));
        
        user_order[OrderId] = msg.sender;
        
        return OrderId;
    }
    
    function get_order_time(uint256 _index)public view returns (uint256) {
        Order storage order = Orders[_index];
        return order.start_time;
    }

    // 贖回
    function Redeem(address _to,address _nft_addr,uint256 _nft_id) public returns (bool){
        require(msg.sender == owner);

        NFT_token = ERC721(_nft_addr);
        NFT_token.transferFrom(address(this),_to,_nft_id);

        return true;
    }
}