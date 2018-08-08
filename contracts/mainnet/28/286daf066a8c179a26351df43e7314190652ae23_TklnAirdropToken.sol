pragma solidity ^0.4.18;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract TklnAirdropToken is ERC20, Ownable{

    string public constant name = "Visit www.tkln.me for more information";
    string public constant symbol = "tkln.me";
    uint8 public constant decimals = 18;

    uint256 public _totalSupply;

    mapping(address => bool) public participants;
    uint256 one_token;
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function TklnAirdropToken() public {
        uint dec = decimals;
        one_token = 10 ** dec;
        admin = msg.sender;
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }

    function doAirDrop(address[] _to) public onlyAdmin {
        uint256 _one_token = one_token;
        _totalSupply = _totalSupply + _one_token * _to.length;
        for (uint i = 0; i < _to.length; i++) {
            address __to = _to[i];
            if(!participants[__to]){
                participants[__to] = true;
            }
            Transfer(address(0), __to, _one_token);
        }
    }

    function balanceOf(address who) public view returns (uint256){
        if(participants[who]){
            return one_token;
        }
        return 0;
    }

    function transfer(address to, uint256 value) public returns (bool){
        return false;
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return 0;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool){
        return false;
    }

    function approve(address spender, uint256 value) public returns (bool){
        return false;
    }
}