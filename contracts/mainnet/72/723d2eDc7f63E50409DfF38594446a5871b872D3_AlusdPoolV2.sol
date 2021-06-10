/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

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













contract PriceInterfaceERC20{
  function get_virtual_price() public view returns(uint256);
  //function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) public;
  //function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) public;
}

contract CRVGaugeInterfaceERC20{
  function deposit(uint256 _value) public;
  function withdraw(uint256 _value) public;
}

contract MinterInterfaceERC20{
  function mint(address gauge_addr) public;
}

contract IUSDCPoolBase is ICurvePool, TokenClaimer, Ownable{
  address public usdc;
  address public dai;
  address public usdt;
  address public busd;
  address public tusd;

  address public crv_token_addr;
  address public controller;
  address public vault;
  address public lp_token_addr;

  CRVGaugeInterfaceERC20 public crv_gauge_addr;
  MinterInterfaceERC20 public crv_minter_addr;

  uint256 public lp_balance;
  uint256 public deposit_usdc_amount;
  uint256 public withdraw_usdc_amount;

  modifier onlyController(){
    require((controller == msg.sender)||(vault == msg.sender), "only controller or vault can call this");
    _;
  }

  constructor() public{
    usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    //dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    //usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    //busd = address(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    //tusd = address(0x0000000000085d4780B73119b644AE5ecd22b376);

    crv_token_addr = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    crv_minter_addr = MinterInterfaceERC20(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
  }

  function deposit_usdc(uint256 _amount) internal;

  //@_amount: USDC amount
  function deposit(uint256 _amount) public{
    deposit_usdc_amount = deposit_usdc_amount + _amount;
    deposit_usdc(_amount);
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
    withdraw_from_curve(_amount);
    lp_balance = lp_balance - _amount;
    IERC20(usdc).transfer(msg.sender, IERC20(usdc).balanceOf(address(this)));
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
    require(crv_minter_addr != MinterInterfaceERC20(0x0), "no crv minter");
    crv_minter_addr.mint(address(crv_gauge_addr));
    IERC20(crv_token_addr).transfer(msg.sender, IERC20(crv_token_addr).balanceOf(address(this)));
  }

  function get_lp_token_balance() public view returns(uint256){
    return lp_balance;
  }

  function get_lp_token_addr() public view returns(address){
    return lp_token_addr;
  }
}


contract CurveInterfaceAlusd{
  function add_liquidity(address _pool, uint256[4] memory _deposit_amounts, uint256 _min_mint_amount) public returns(uint256);
  function remove_liquidity_one_coin(address _pool, uint256 _burn_amount, int128 i, uint256 _min_amount) public returns(uint256);
}

contract CRVGaugeInterfaceERC20_alusd{
  function deposit(uint256 _value) public;
  function withdraw(uint256 _value) public;
  function claim_rewards() public;
}


contract AlusdPoolV2 is ICurvePool, TokenClaimer, Ownable{
  address public usdc;
  address public extra_token_addr;
  address public lp_token_addr;
  address public crv_token_addr;

  address public controller;
  address public vault;

  CRVGaugeInterfaceERC20_alusd public crv_gauge_addr;
  MinterInterfaceERC20 public crv_minter_addr;
  
  CurveInterfaceAlusd public pool_deposit;
  address public meta_pool_addr;

  uint256 public lp_balance;
  uint256 public deposit_usdc_amount;
  uint256 public withdraw_usdc_amount;

  uint256 public transfer_amount;

  modifier onlyController(){
    require((controller == msg.sender)||(vault == msg.sender), "only controller or vault can call this");
    _;
  }

  constructor() public{
    name = "Alusd";

    usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    extra_token_addr = address(0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF);

    crv_token_addr = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    crv_minter_addr = MinterInterfaceERC20(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    crv_gauge_addr = CRVGaugeInterfaceERC20_alusd(0x9582C4ADACB3BCE56Fea3e590F05c3ca2fb9C477);
    pool_deposit = CurveInterfaceAlusd(0xA79828DF1850E8a3A3064576f380D90aECDD3359);
    meta_pool_addr = address(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c);
    lp_token_addr = address(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c);

    transfer_amount = 0;
  }

  //@_amount: USDC amount
  function deposit(uint256 _amount) public{
    deposit_usdc_amount = deposit_usdc_amount + _amount;
    deposit_usdc(_amount);
    uint256 cur = IERC20(lp_token_addr).balanceOf(address(this));
    lp_balance = lp_balance + cur;
    deposit_to_gauge();
  }

  //@_amount: USDC amount
  function deposit_usdc(uint256 _amount) internal {
    IERC20(usdc).transferFrom(msg.sender, address(this), _amount);
    IERC20(usdc).approve(address(pool_deposit), 0);
    IERC20(usdc).approve(address(pool_deposit), _amount);
    uint256[4] memory uamounts = [0,0, _amount, 0];
    pool_deposit.add_liquidity(
        meta_pool_addr,
        uamounts, 
        0
    );
  }

  //deposit all lp token to gauage to mine CRV
  function deposit_to_gauge() internal {
    IERC20(lp_token_addr).approve(address(crv_gauge_addr), 0);
    uint256 cur = IERC20(lp_token_addr).balanceOf(address(this));
    IERC20(lp_token_addr).approve(address(crv_gauge_addr), cur);
    crv_gauge_addr.deposit(cur);
    require(IERC20(lp_token_addr).balanceOf(address(this)) == 0, "deposit_to_gauge: unexpected exchanges");
  }

  //@_amount: lp token amount
  function withdraw(uint256 _amount) public onlyController{
    withdraw_from_gauge(_amount);
    withdraw_from_curve(_amount);
    lp_balance = lp_balance - _amount;
    IERC20(usdc).transfer(msg.sender, IERC20(usdc).balanceOf(address(this)));
  }

  function withdraw_from_gauge(uint256 _amount) internal{
    require(_amount <= lp_balance, "withdraw_from_gauge: insufficient amount");
    crv_gauge_addr.withdraw(_amount);
  }

  function withdraw_from_curve(uint256 _amount) internal {
    require(_amount <= get_lp_token_balance(), "withdraw_from_curve: too large amount");
    IERC20(lp_token_addr).approve(address(pool_deposit), _amount);
    pool_deposit.remove_liquidity_one_coin(
        meta_pool_addr,
        _amount,
        2,
        0
    );
  }

  function earn_crv() public onlyController{
    require(crv_minter_addr != MinterInterfaceERC20(0x0), "no crv minter");
    crv_minter_addr.mint(address(crv_gauge_addr));
    IERC20(crv_token_addr).transfer(msg.sender, IERC20(crv_token_addr).balanceOf(address(this)));
    if (extra_token_addr != address(0x0)) {
      crv_gauge_addr.claim_rewards();
      uint256 b = IERC20(extra_token_addr).balanceOf(address(this));
      if (b > transfer_amount) {
        IERC20(extra_token_addr).transfer(msg.sender, b);
      }
    }
  }

  function set_transfer_amount(uint256 _new) public onlyOwner {
    transfer_amount = _new;
  }

  function setController(address _controller, address _vault) public onlyOwner{
    controller = _controller;
    vault = _vault;
  }
  function claimStdToken(address _token, address payable to) public onlyOwner{
    _claimStdTokens(_token, to);
  }
  function get_lp_token_balance() public view returns(uint256){
    return lp_balance;
  }
  function get_lp_token_addr() public view returns(address){
    return lp_token_addr;
  }
  function get_virtual_price() public view returns(uint256) {
    return PriceInterfaceERC20(address(meta_pool_addr)).get_virtual_price();
  }
}