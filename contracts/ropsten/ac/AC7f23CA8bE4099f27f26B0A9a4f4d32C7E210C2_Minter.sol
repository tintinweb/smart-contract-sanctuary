/**
 *Submitted for verification at Etherscan.io on 2021-01-31
*/

pragma solidity 0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }	
}

contract Ownable is Context {
    address private _owner;
    address public admin;
    address public dev;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function setDev(address _dev) public onlyOwner {
        dev = _dev;
    }
    
    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == _owner);
        _;
    }
    
    modifier onlyDev {
        require(msg.sender == dev || msg.sender == admin || msg.sender == _owner);
        _;
    }    
}

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

   function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract ContractConn{
    function transfer(address _to, uint256 _value) virtual public;
    function balanceOf(address who) virtual public view returns (uint256);
}



contract Minter is Ownable {

    using SafeMath for uint256;
    
    uint256 public userMinted = 0;   

    mapping (uint256 => bool) public claimedOrderId;
    
    ContractConn public zild;   
    
    event MinterRevenue(uint256 orderId, address who,uint256 amount);
    
    //event EventHash(string name,bytes32 hash); // todo : delete
    //event EventAddress(string name,address addr); // todo : delete

    constructor(address _token) public {
        zild = ContractConn(_token);
    }    

    function claim(uint256 orderId, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public  {
        require(deadline >= block.timestamp, "expired order");
        require(claimedOrderId[orderId] == false, "already claimed");
      
        bytes32 hash1 = keccak256(
            abi.encodePacked(
                address(this),
                msg.sender,
                orderId,
                amount,
                deadline
            )
        );

        //emit EventHash('hash1',hash1); // todo : delete

        bytes32 hash2 = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                hash1
            )
        );

        //emit EventHash('hash2',hash2); // todo : delete

        address signer = ecrecover(hash2, v, r, s);
        //emit EventAddress('signer',signer); // todo : delete

        require(  signer != address(0) && signer == dev, "invalid signer");

        zild.transfer(msg.sender,amount);
        userMinted = userMinted.add(amount);
        
        claimedOrderId[orderId] = true;
        emit MinterRevenue(orderId, msg.sender, amount);
    }

    // for special case
    function claimByAdmin(uint256 orderId, address _to, uint256 amount) public onlyAdmin {        
        if(orderId > 0 ) {
            require(claimedOrderId[orderId] == false, "already claimed");
            claimedOrderId[orderId] = true;
        }

        zild.transfer(_to,amount);
        userMinted = userMinted.add(amount);
        emit MinterRevenue(orderId, _to,amount);
    }

}