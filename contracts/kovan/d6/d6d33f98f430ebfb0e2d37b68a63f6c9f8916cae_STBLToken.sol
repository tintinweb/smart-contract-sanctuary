pragma solidity ^0.7.0;

import "Context.sol";
import "ERC20.sol";
import "Ownable.sol";
import "AccessControl.sol";



contract STBLToken is Context, ERC20, Ownable, AccessControl {

  LiquidityInterface STBLCreationInterface;
  TokenInterface BPT;
  bytes32 MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor() ERC20("Stable","STBL") {
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      STBLCreationInterface = LiquidityInterface(0xE7e70A9b773171D14D8b4B9aCB77287Ac7fbe62F); // Add BalancerTrader address
      BPT = TokenInterface(0x04c4e4770868CE87e7e434228e804c794F217Bc2);
    }


    function mint(address to, uint256 amount) public {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }
    function createSTBL(address _tokenIn, uint256 _amountIn, uint256 _slippagePercentage) public returns(uint256) {
        require(STBLCreationInterface.isPoolToken(_tokenIn), "Unsupported token for creation!");
        IERC20 token = IERC20(_tokenIn);
        require(token.allowance(msg.sender, address(STBLCreationInterface)) >= _amountIn, "Amount exceeds allowance to BalancerTrader!");
        uint256 amountBPT = STBLCreationInterface.swapExactPoolTokenForBPT(msg.sender, _tokenIn, _amountIn, _slippagePercentage);
        _mint(msg.sender, amountBPT); // Mints 1:1 STBL to BPT created
        return amountBPT;
    }
    function destroySTBL(address _tokenOut, uint256 _amountSTBL, uint256 _slippagePercentage) public returns(uint256) {
        require(STBLCreationInterface.isPoolToken(_tokenOut), "Output token not supported!");
        require(balanceOf(msg.sender) >= _amountSTBL, "Amount exceeds balance!");
        _burn(msg.sender, _amountSTBL);

        BPT.approve(address(STBLCreationInterface), _amountSTBL);
        uint256 amountOut = STBLCreationInterface.swapExactBPTForPoolToken(msg.sender, _tokenOut, _amountSTBL, _slippagePercentage); // Estimating _amountSTBL = amountBPT going in
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