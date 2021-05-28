pragma solidity ^0.8.0;

import './Address.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Pair.sol';
import './IUniswapV2Router02.sol';
import './ERC20.sol';

/**
 * @notice ERC20 token with cost basis tracking and restricted loss-taking
 */
contract BUFFDOGE is ERC20 {
  using Address for address payable;

  string public override name = 'BUFFDOGE (buffdoge.online)';
  string public override symbol = 'BUFFDOGE';

  address private constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  uint private constant SUPPLY = 1e12 ether;

  address private _owner;

  address private _pair;

  uint private _openedAt;
  uint private _closedAt;

  mapping (address => uint) private _basisOf;
  mapping (address => uint) public cooldownOf;

  uint private _initialBasis;

  uint private _ath;
  uint private _athTimestamp;

  struct Minting {
    address recipient;
    uint amount;
  }

  /**
   * @notice deploy
   */
  constructor () payable {
    _owner = msg.sender;

    // setup uniswap pair and store address

    _pair = IUniswapV2Factory(
      IUniswapV2Router02(UNISWAP_ROUTER).factory()
    ).createPair(WETH, address(this));

    // prepare to add liquidity

    _approve(address(this), UNISWAP_ROUTER, SUPPLY);

    // prepare to remove liquidity

    IERC20(_pair).approve(UNISWAP_ROUTER, type(uint).max);
  }

  receive () external payable {}

  /**
   * @notice get cost basis for given address
   * @param account address to query
   * @return cost basis
   */
  function basisOf (
    address account
  ) public view returns (uint) {
    uint basis = _basisOf[account];

    if (basis == 0 && balanceOf(account) > 0) {
      basis = _initialBasis;
    }

    return basis;
  }

  /**
   * @notice mint team tokens prior to opening of trade
   * @param mintings structured minting data (recipient, amount)
   */
  function mint (
    Minting[] calldata mintings
  ) external {
    require(msg.sender == _owner, 'ERR: sender must be owner');
    require(_openedAt == 0, 'ERR: already opened');

    uint mintedSupply;

    for (uint i; i < mintings.length; i++) {
      Minting memory m = mintings[i];
      uint amount = m.amount;
      address recipient = m.recipient;

      mintedSupply += amount;
      _balances[recipient] += amount;
      emit Transfer(address(0), recipient, amount);
    }

    _totalSupply += mintedSupply;
  }

  /**
   * @notice open trading
   * @dev sender must be owner
   * @dev trading must not yet have been opened
   */
  function open () external {
    require(msg.sender == _owner, 'ERR: sender must be owner');
    require(_openedAt == 0, 'ERR: already opened');

    _openedAt = block.timestamp;

    // add liquidity, set initial cost basis

    _mint(address(this), SUPPLY - totalSupply());

    _initialBasis = (1 ether) * address(this).balance / balanceOf(address(this));

    IUniswapV2Router02(
      UNISWAP_ROUTER
    ).addLiquidityETH{
      value: address(this).balance
    }(
      address(this),
      balanceOf(address(this)),
      0,
      0,
      address(this),
      block.timestamp
    );
  }

  /**
   * @notice close trading
   * @dev trading must not yet have been closed
   * @dev minimum time since open must have elapsed
   */
  function close () external {
    require(_openedAt != 0, 'ERR: not yet opened');
    require(_closedAt == 0, 'ERR: already closed');
    require(block.timestamp > _openedAt + (1 days), 'ERR: too soon');

    _closedAt = block.timestamp;

    require(
      block.timestamp > _athTimestamp + (1 weeks),
      'ERR: recent ATH'
    );

    (uint token, ) = IUniswapV2Router02(
      UNISWAP_ROUTER
    ).removeLiquidityETH(
      address(this),
      IERC20(_pair).balanceOf(address(this)),
      0,
      0,
      address(this),
      block.timestamp
    );

    _burn(address(this), token);
  }

  /**
   * @notice exchange BUFFDOGE for proportion of ETH in contract
   * @dev trading must have been closed
   */
  function liquidate () external {
    require(_closedAt > 0, 'ERR: not yet closed');
    
    uint balance = balanceOf(msg.sender);

    require(balance != 0, 'ERR: zero balance');

    uint payout = address(this).balance * balance / totalSupply();

    _burn(msg.sender, balance);
    payable(msg.sender).sendValue(payout);
  }

  /**
   * @notice withdraw remaining ETH from contract
   * @dev trading must have been closed
   * @dev minimum time since close must have elapsed
   */
  function liquidateUnclaimed () external {
    require(_closedAt > 0, 'ERR: not yet closed');
    require(block.timestamp > _closedAt + (12 weeks), 'ERR: too soon');
    payable(_owner).sendValue(address(this).balance);
  }

  function _beforeTokenTransfer (
    address from,
    address to,
    uint amount
  ) override internal {
    super._beforeTokenTransfer(from, to, amount);

    // ignore minting and burning
    if (from == address(0) || to == address(0)) return;

    // ignore add/remove liquidity
    if (from == address(this) || to == address(this)) return;
    if (from == UNISWAP_ROUTER || to == UNISWAP_ROUTER) return;

    require(_openedAt > 0);

    require(
      msg.sender == UNISWAP_ROUTER || msg.sender == _pair,
      'ERR: sender must be uniswap'
    );
    require(amount <= 5e9 ether /* revert message not returned by Uniswap */);

    address[] memory path = new address[](2);

    if (from == _pair) {
      require(cooldownOf[to] < block.timestamp /* revert message not returned by Uniswap */);
      cooldownOf[to] = block.timestamp + (5 minutes);

      path[0] = WETH;
      path[1] = address(this);

      uint[] memory amounts = IUniswapV2Router02(UNISWAP_ROUTER).getAmountsIn(
        amount,
        path
      );

      uint balance = balanceOf(to);
      uint fromBasis = (1 ether) * amounts[0] / amount;
      _basisOf[to] = (fromBasis * amount + basisOf(to) * balance) / (amount + balance);

      if (fromBasis > _ath) {
        _ath = fromBasis;
        _athTimestamp = block.timestamp;
      }
    } else if (to == _pair) {
      // blacklist Vitalik Buterin
      require(from != 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B /* revert message not returned by Uniswap */);
      require(cooldownOf[from] < block.timestamp /* revert message not returned by Uniswap */);
      cooldownOf[from] = block.timestamp + (5 minutes);

      path[0] = address(this);
      path[1] = WETH;

      uint[] memory amounts = IUniswapV2Router02(UNISWAP_ROUTER).getAmountsOut(
        amount,
        path
      );

      require(basisOf(from) <= (1 ether) * amounts[1] / amount /* revert message not returned by Uniswap */);
    }
  }
}