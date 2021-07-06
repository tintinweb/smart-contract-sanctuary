pragma solidity ^0.7.0;

import "Context.sol";
import "ERC20.sol";
import "Ownable.sol";
import "AccessControl.sol";



contract STABLEToken is Context, ERC20, Ownable, AccessControl {

  LiquidityInterface STABLECreationInterface;
  TokenInterface BPT;
  bytes32 MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor() ERC20("Stable","STABLE") {
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      STABLECreationInterface = LiquidityInterface(0x1769da0D1dA5Af3aDEe8eEb362A1C0aF0f3901cF); // Add BalancerTrader address
      BPT = TokenInterface(0x8D3C9B57EdD6f152532945e7e5F0ABF5f010AfE0); // Add Balancer Pool Token address
    }


    function mint(address to, uint256 amount) public {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }
    function createSTABLE(address _tokenIn, uint256 _amountIn, uint256 _slippagePercentage) public returns(uint256) {
        require(STABLECreationInterface.isPoolToken(_tokenIn), "Unsupported token for creation!");
        IERC20 token = IERC20(_tokenIn);
        require(token.allowance(msg.sender, address(STABLECreationInterface)) >= _amountIn, "Amount exceeds allowance to BalancerTrader!");
        uint256 amountBPT = STABLECreationInterface.swapExactPoolTokenForBPT(msg.sender, _tokenIn, _amountIn, _slippagePercentage);
        _mint(msg.sender, amountBPT); // Mints 1:1 STABLE to BPT created
        return amountBPT;
    }
    function destroySTABLE(address _tokenOut, uint256 _amountSTABLE, uint256 _slippagePercentage) public returns(uint256) {
        require(STABLECreationInterface.isPoolToken(_tokenOut), "Output token not supported!");
        require(balanceOf(msg.sender) >= _amountSTABLE, "Amount exceeds balance!");
        _burn(msg.sender, _amountSTABLE);

        BPT.approve(address(STABLECreationInterface), _amountSTABLE);
        uint256 amountOut = STABLECreationInterface.swapExactBPTForPoolToken(msg.sender, _tokenOut, _amountSTABLE, _slippagePercentage); // Estimating _amountSTABLE = amountBPT going in
        return amountOut;

    }
    function grantMinterRole(address _to) public {
        // Check that the calling account has the admin role
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the default admin");
        require(!hasRole(MINTER_ROLE, _to), "Address already has minter role");
        grantRole(MINTER_ROLE, _to);
    }
    function revokeMinterRole(address _from) public {
        // Check that the calling account has the admin role
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the default admin");
        require(hasRole(MINTER_ROLE, _from), "Address does not have minter role");
        revokeRole(MINTER_ROLE, _from);
    }
}

interface LiquidityInterface {
  function isPoolToken(address _token) external view returns(bool);
  function swapExactPoolTokenForBPT(address _user, address _token, uint256 _amount, uint256 _slippagePercentage) external returns (uint256);
  function swapExactBPTForPoolToken(address _user, address _tokenOut, uint256 _BPTAmountIn, uint256 _slippagePercentage) external returns (uint256);
}

interface TokenInterface {
    function balanceOf(address) external returns (uint);
    function allowance(address, address) external returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}