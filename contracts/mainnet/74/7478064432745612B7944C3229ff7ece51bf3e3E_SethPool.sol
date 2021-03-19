/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

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

// File: contracts/core/IPool.sol

pragma solidity >=0.4.21 <0.6.0;

contract ICurvePool{
  function deposit(uint256 _amount) public;
  function withdraw(uint256 _amount) public;

  function get_virtual_price() public view returns(uint256);

  function get_lp_token_balance() public view returns(uint256);

  function get_lp_token_addr() public view returns(address);

  function earn_crv() public;

  string public name;
}

contract ICurvePoolForETH{
  function deposit() public payable;
  function withdraw(uint256 _amount) public;

  function get_virtual_price() public view returns(uint256);

  function get_lp_token_balance() public view returns(uint256);

  function get_lp_token_addr() public view returns(address);

  function earn_crv() public;

  string public name;
}

// File: contracts/utils/TokenClaimer.sol

pragma solidity >=0.4.21 <0.6.0;



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
        IERC20 token = IERC20(_token);
        uint balance = token.balanceOf(address(this));

        (bool status,) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", to, balance));
        require(status, "call failed");
        emit ClaimedTokens(_token, to, balance);
  }
}

// File: contracts/core/ethpool/IethPoolBase.sol

pragma solidity >=0.4.21 <0.6.0;






contract PriceInterfaceEth{
  function get_virtual_price() public view returns(uint256);
}

contract CRVGaugeInterfaceEth{
  function deposit(uint256 _value) public;
  function withdraw(uint256 _value) public;
  function claim_rewards(address _address) public;
}

contract MinterInterfaceEth{
  function mint(address gauge_addr) public;
}

contract IethPoolBase is ICurvePoolForETH, TokenClaimer, Ownable{
  address public crv_token_addr;
  address public controller;
  address public vault;
  address public lp_token_addr;
  address public extra_token_addr;

  CRVGaugeInterfaceEth public crv_gauge_addr;
  MinterInterfaceEth public crv_minter_addr;

  uint256 public lp_balance;
  uint256 public deposit_eth_amount;
  uint256 public withdraw_eth_amount;

  modifier onlyController(){
    require((controller == msg.sender)||(vault == msg.sender), "only controller can call this");
    _;
  }

  constructor() public{
    crv_token_addr = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    crv_minter_addr = MinterInterfaceEth(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
  }

  function deposit_eth() internal;

  //@_amount: USDC amount
  function deposit() public payable onlyController{
    uint _amount = msg.value;
    deposit_eth_amount = deposit_eth_amount + _amount;
    deposit_eth();
    uint256 cur = IERC20(lp_token_addr).balanceOf(address(this));
    lp_balance = lp_balance + cur;
    deposit_to_gauge();
  }

  //deposit all lp token to gauage to mine CRV
  function deposit_to_gauge() internal {
    IERC20(lp_token_addr).approve(address(crv_gauge_addr), 0);
    uint256 cur = IERC20(lp_token_addr).balanceOf(address(this));
    IERC20(lp_token_addr).approve(address(crv_gauge_addr), cur);
    crv_gauge_addr.deposit(cur);
    require(IERC20(lp_token_addr).balanceOf(address(this)) == 0, "deposit_to_gauge: unexpected exchanges");
  }

  function withdraw_from_curve(uint256 _amount) internal;

  //@_amount: lp token amount
  function withdraw(uint256 _amount) public onlyController{
      withdraw_from_gauge(_amount);
      require(IERC20(lp_token_addr).balanceOf(address(this)) == _amount, "gauge: amount mismatch");
      withdraw_from_curve(_amount);
      lp_balance = lp_balance - _amount;
      msg.sender.transfer(address(this).balance);
  }

  function withdraw_from_gauge(uint256 _amount) internal{
    require(_amount <= lp_balance, "withdraw_from_gauge: insufficient amount");
    crv_gauge_addr.withdraw(_amount);
  }

  function setController(address _controller, address _vault) public onlyOwner{
    controller = _controller;
    vault = _vault;
  }

  function claimStdToken(address _token, address payable to) public onlyOwner{
    _claimStdTokens(_token, to);
  }

  function earn_crv() public onlyController{
    require(crv_minter_addr != MinterInterfaceEth(0x0), "no crv minter");
    crv_minter_addr.mint(address(crv_gauge_addr));
    IERC20(crv_token_addr).transfer(msg.sender, IERC20(crv_token_addr).balanceOf(address(this)));
    if (extra_token_addr != address(0x0)) {
      crv_gauge_addr.claim_rewards(address(this));
      IERC20(extra_token_addr).transfer(msg.sender, IERC20(extra_token_addr).balanceOf(address(this)));
    }
  }

  function get_lp_token_balance() public view returns(uint256){
    return lp_balance;
  }

  function get_lp_token_addr() public view returns(address){
    return lp_token_addr;
  }

  function() external payable{

  }

}

// File: contracts/utils/SafeMath.sol

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSubR(uint a, uint b, string memory s) public pure returns (uint c) {
        require(b <= a, s);
        c = a - b;
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
    function safeDivR(uint a, uint b, string memory s) public pure returns (uint c) {
        require(b > 0, s);
        c = a / b;
    }
}

// File: contracts/utils/Address.sol

pragma solidity >=0.4.21 <0.6.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/erc20/SafeERC20.sol

pragma solidity >=0.4.21 <0.6.0;




library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeAdd(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeSub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/core/ethpool/SethPool.sol

pragma solidity >=0.4.21 <0.6.0;




contract CurveInterfaceSeth{
  function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) public payable returns(uint256);
  function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_mint_amount) public returns(uint256);
}

contract SethPool is IethPoolBase{
  using SafeERC20 for IERC20;

  CurveInterfaceSeth public pool_deposit;

  constructor() public{
    name = "Seth";
    lp_token_addr = address(0xA3D87FffcE63B53E0d54fAa1cc983B7eB0b74A9c);
    crv_gauge_addr = CRVGaugeInterfaceEth(0x3C0FFFF15EA30C35d7A85B85c0782D6c94e1d238);
    pool_deposit = CurveInterfaceSeth(0xc5424B857f758E906013F3555Dad202e4bdB4567);
  }

  function deposit_eth() internal {
    uint _amount = msg.value;
    uint256[2] memory uamounts = [_amount, 0];
    pool_deposit.add_liquidity.value(_amount)(uamounts, 0);
  }


  function withdraw_from_curve(uint256 _amount) internal{
    require(_amount <= get_lp_token_balance(), "withdraw_from_curve: too large amount");
    require(address(pool_deposit).balance > 0, "money is 0");
    pool_deposit.remove_liquidity_one_coin(_amount, 0, 0);

  }

  function get_virtual_price() public view returns(uint256){
    return PriceInterfaceEth(address(pool_deposit)).get_virtual_price();
  }
}