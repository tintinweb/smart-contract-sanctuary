/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

  
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable{

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

contract Gamestarter is Ownable {

    IERC20 public token;
    uint256 public season = 1;
    mapping(uint256=>uint256) public seasonShare;
    mapping(address=>uint256) public userTotal;
    mapping(address=>uint256) public userReceived;
    mapping(uint256=>bool) public seasonEnabled;
    mapping(address=>mapping(uint256=>bool)) public claimed;

    function setSeason(uint256 _season) public onlyOwner{
        season = _season;
    }

    function setToken(IERC20 _token) public onlyOwner{
        token = _token;
    }

    function setUserTotal(address addr, uint256 total) public onlyOwner{
        userTotal[addr] = total;
    }

    function bulkSetUserTotal(address[] memory addrs, uint256[] memory total) public onlyOwner{
        require(addrs.length == total.length, "Inconsistent length");
        for(uint i = 0;i < addrs.length; i++) {
            address addr = addrs[i];
            uint256 t = total[i];
            userTotal[addr] = t;
        }
    }

    function setSeasonShare(uint256 _season, uint256 _share) public onlyOwner{
        seasonShare[_season] = _share;
    }

    function setSesonEnabled(uint256 _season, bool _flag) public onlyOwner{
        seasonEnabled[_season] = _flag;
    }

    function setClaimed(address addr, uint256 _season,bool _flag) public onlyOwner{
        claimed[addr][_season] = _flag;
    }

    function getCanClaim(uint256 _season) public view returns(uint256){
        uint256 total = userTotal[msg.sender];
        uint256 share = seasonShare[_season];
        return total * share / 1000;
    }

    function isContractaddr(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function claim(uint256 _season) public {
        require(!isContractaddr(msg.sender), "not contract address");
        require(seasonEnabled[_season], "season not use");
        require(!claimed[msg.sender][_season], "Have received");

        uint256 total = userTotal[msg.sender];
        require(total > 0, "No user");

        uint256 share = seasonShare[_season];

        uint256 amount = total * share / 1000;
        token.transfer(msg.sender, amount);

        claimed[msg.sender][_season] = true;
        userReceived[msg.sender] += amount;
    }
}