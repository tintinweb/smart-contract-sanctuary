/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IDepositContract {
    function deposit( bytes calldata pubkey, bytes calldata withdrawal_credentials, bytes calldata signature, bytes32 deposit_data_root ) external payable;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface INodokaBridge {
    function deposit(address _token, address _to, uint256 _amount) external payable returns (bool);
}

interface IToken{
    function mint(address payable _to, uint256 _value) external returns (bool);
}

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

pragma solidity ^0.6.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(  address indexed previousOwner, address indexed newOwner );

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() private view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

pragma solidity ^0.6.12;
contract StakingPool is Ownable {

    address public neth;
    address[] private users;
    mapping(address => uint) public balances;
    mapping(bytes => bool) public pubkeysUsed;
    IDepositContract public depositContract = IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);
    address public admin;
    uint public end;
    bool public finalized;
    uint public totalInvested;
    uint public totalChange;
    mapping(address => bool) public changeClaimed;
    
    event NewInvestor (
        address investor
    );

    address public nodoka_bridge;

    constructor(address _neth) public {
        admin = msg.sender;
        end = block.timestamp + 365*3 days;
        neth = _neth;
    }

    function get_users(uint _id)public view returns (address){
       return users[_id];
    }

   function get_count_users() public view returns(uint) {
    return users.length;
    }

    function get_en_balances(address _user)  public view returns (uint){
        return balances[_user];
    }

    function set_neth(address _neth) public onlyOwner{
        neth = _neth;
    }

    function set_nodoka_bridge(address _nodoka_bridge) public onlyOwner{
        nodoka_bridge = _nodoka_bridge;
    }

    function invest() external payable {
        require(block.timestamp < end, 'too late');
        if(balances[msg.sender] == 0) {
            emit NewInvestor(msg.sender);   
        }
        balances[msg.sender] += msg.value;
        users.push(msg.sender);
        IToken(neth).mint(msg.sender, msg.value);
        // INodokaBridge(nodoka_bridge).deposit(address(neth), msg.sender, msg.value);
    }

    function finalize() external {
      require(block.timestamp >= end, 'too early');
      require(finalized == false, 'already finalized');
      finalized = true;
      totalInvested = address(this).balance;
      totalChange = address(this).balance % 32 ether;
    }

    function getChange() external {
      require(finalized == true, 'not finalized');
      require(balances[msg.sender] > 0, 'not an investor');
      require(changeClaimed[msg.sender] == false, 'change already claimed');
      changeClaimed[msg.sender] = true;
      uint amount = totalChange * balances[msg.sender] / totalInvested;
      msg.sender.transfer(amount);
    }
    
    function deposit( bytes calldata pubkey, bytes calldata withdrawal_credentials, bytes calldata signature, bytes32 deposit_data_root )  external {
        require(finalized == true, 'too early');
        require(msg.sender == admin, 'only admin');
        require(address(this).balance >= 32 ether);
        require(pubkeysUsed[pubkey] == false, 'this pubkey was already used');
        depositContract.deposit{value: 32 ether}(
            pubkey, 
            withdrawal_credentials, 
            signature, 
            deposit_data_root
        );
    }
}