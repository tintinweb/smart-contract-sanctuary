/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/TrustListTools.sol

pragma solidity >=0.4.21 <0.6.0;

contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}
contract TrustListTools{
  TrustListInterface public trustlist;
  constructor(address _list) public {
    //require(_list != address(0x0));
    trustlist = TrustListInterface(_list);
  }

  modifier is_trusted(address addr){
    require(trustlist.is_trusted(addr), "not a trusted issuer");
    _;
  }

}

// File: contracts/utils/TokenClaimer.sol

pragma solidity >=0.4.21 <0.6.0;

contract TransferableToken{
    function balanceOf(address _owner) public returns (uint256 balance) ;
    function transfer(address _to, uint256 _amount) public returns (bool success) ;
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) ;
}


contract TokenClaimer{

    event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);
    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
  function _claimStdTokens(address _token, address payable to) internal {
        if (_token == address(0x0)) {
            to.transfer(address(this).balance);
            return;
        }
        TransferableToken token = TransferableToken(_token);
        uint balance = token.balanceOf(address(this));

        (bool status,) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", to, balance));
        require(status, "call failed");
        emit ClaimedTokens(_token, to, balance);
  }
}

// File: contracts/erc20/IERC20.sol

pragma solidity >=0.4.21 <0.6.0;

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

// File: contracts/assets/TokenBank.sol

pragma solidity >=0.4.21 <0.6.0;





//This support both native and erc20 token
contract TokenBank is Ownable, TokenClaimer, TrustListTools{

  string public token_name;
  address public erc20_token_addr;

  event withdraw_token(address to, uint256 amount);
  event issue_token(address to, uint256 amount);

  event RecvETH(uint256 v);
  function() external payable{
    emit RecvETH(msg.value);
  }

  constructor(string memory name, address token_contract, address _tlist) TrustListTools(_tlist) public{
    token_name = name;
    erc20_token_addr = token_contract;
  }


  function claimStdTokens(address _token, address payable to)
    public onlyOwner{
      _claimStdTokens(_token, to);
  }

  function balance() public view returns(uint){
    if(erc20_token_addr == address(0x0)){
      return address(this).balance;
    }
    return IERC20(erc20_token_addr).balanceOf(address(this));
  }

  function token() public view returns(address, string memory){
    return (erc20_token_addr, token_name);
  }

  function transfer(address payable to, uint tokens)
    public
    onlyOwner
    returns (bool success){
    require(tokens <= balance(), "not enough tokens");
    if(erc20_token_addr == address(0x0)){
      to.transfer(tokens);
      emit withdraw_token(to, tokens);
      return true;
    }
    (bool status,) = erc20_token_addr.call(abi.encodeWithSignature("transfer(address,uint256)", to, tokens));
    require(status, "call erc20 transfer failed");
    emit withdraw_token(to, tokens);
    return true;
  }

  function issue(address payable _to, uint _amount)
    public
    is_trusted(msg.sender)
    returns (bool success){
      require(_amount <= balance(), "not enough tokens");
      if(erc20_token_addr == address(0x0)){
        _to.transfer(_amount);
        emit issue_token(_to, _amount);
        return true;
      }
      (bool status,) = erc20_token_addr.call(abi.encodeWithSignature("transfer(address,uint256)", _to, _amount));
      require(status, "call erc20 transfer failed");
      emit issue_token(_to, _amount);
      return true;
    }
}


contract TokenBankFactory {
  event CreateTokenBank(string indexed name, address addr);

  function newTokenBank(string memory name, address token_contract, address tlist) public returns(address){
    TokenBank addr = new TokenBank(name, token_contract, tlist);
    emit CreateTokenBank(name, address(addr));
    addr.transferOwnership(msg.sender);
    return address(addr);
  }
}