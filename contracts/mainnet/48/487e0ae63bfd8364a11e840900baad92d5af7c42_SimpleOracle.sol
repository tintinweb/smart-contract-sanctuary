pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/ERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/cryptography/MerkleProof.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';
import './Governable.sol';
import '../interfaces/ICErc20.sol';

contract SafeBox is Governable, ERC20, ReentrancyGuard {
  using SafeMath for uint;
  using SafeERC20 for IERC20;
  event Claim(address user, uint amount);

  ICErc20 public immutable cToken;
  IERC20 public immutable uToken;

  address public relayer;
  bytes32 public root;
  mapping(address => uint) public claimed;

  constructor(
    ICErc20 _cToken,
    string memory _name,
    string memory _symbol
  ) public ERC20(_name, _symbol) {
    _setupDecimals(_cToken.decimals());
    IERC20 _uToken = IERC20(_cToken.underlying());
    __Governable__init();
    cToken = _cToken;
    uToken = _uToken;
    relayer = msg.sender;
    _uToken.safeApprove(address(_cToken), uint(-1));
  }

  function setRelayer(address _relayer) external onlyGov {
    relayer = _relayer;
  }

  function updateRoot(bytes32 _root) external {
    require(msg.sender == relayer || msg.sender == governor, '!relayer');
    root = _root;
  }

  function deposit(uint amount) external nonReentrant {
    uint uBalanceBefore = uToken.balanceOf(address(this));
    uToken.safeTransferFrom(msg.sender, address(this), amount);
    uint uBalanceAfter = uToken.balanceOf(address(this));
    uint cBalanceBefore = cToken.balanceOf(address(this));
    require(cToken.mint(uBalanceAfter.sub(uBalanceBefore)) == 0, '!mint');
    uint cBalanceAfter = cToken.balanceOf(address(this));
    _mint(msg.sender, cBalanceAfter.sub(cBalanceBefore));
  }

  function withdraw(uint amount) public nonReentrant {
    _burn(msg.sender, amount);
    uint uBalanceBefore = uToken.balanceOf(address(this));
    require(cToken.redeem(amount) == 0, '!redeem');
    uint uBalanceAfter = uToken.balanceOf(address(this));
    uToken.safeTransfer(msg.sender, uBalanceAfter.sub(uBalanceBefore));
  }

  function claim(uint totalReward, bytes32[] memory proof) public nonReentrant {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, totalReward));
    require(MerkleProof.verify(proof, root, leaf), '!proof');
    uint send = totalReward.sub(claimed[msg.sender]);
    claimed[msg.sender] = totalReward;
    uToken.safeTransfer(msg.sender, send);
    emit Claim(msg.sender, send);
  }

  function adminClaim(uint amount) external onlyGov {
    uToken.safeTransfer(msg.sender, amount);
  }

  function claimAndWithdraw(
    uint claimAmount,
    bytes32[] memory proof,
    uint withdrawAmount
  ) external {
    claim(claimAmount, proof);
    withdraw(withdrawAmount);
  }
}