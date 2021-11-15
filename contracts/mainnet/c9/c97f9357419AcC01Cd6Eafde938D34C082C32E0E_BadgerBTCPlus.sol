// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IRebalancer.sol";
import "./interfaces/ICompositePlus.sol";
import "./Plus.sol";

/**
 * @title Composite plus token.
 *
 * A composite plus token is backed by a basket of plus token. The composite plus token,
 * along with its underlying tokens in the basket, should have the same peg.
 */
contract CompositePlus is ICompositePlus, Plus, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    event Minted(address indexed user, address[] tokens, uint256[] amounts, uint256 mintShare, uint256 mintAmount);
    event Redeemed(address indexed user, address[] tokens, uint256[] amounts, uint256 redeemShare, uint256 redeemAmount, uint256 fee);

    event RebalancerUpdated(address indexed rebalancer, bool enabled);
    event MinLiquidityRatioUpdated(uint256 oldRatio, uint256 newRatio);
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event Rebalanced(uint256 underlyingBefore, uint256 underlyingAfter, uint256 supply);

    // The underlying plus tokens that constitutes the composite plus token.
    address[] public override tokens;
    // Mapping: Token address => Whether the token is an underlying token.
    mapping(address => bool) public override tokenSupported;
    // Mapping: Token address => Whether minting with token is paused
    mapping(address => bool) public mintPaused;

    // Mapping: Address => Whether this is a rebalancer contract.
    mapping(address => bool) public rebalancers;
    // Liquidity ratio = Total supply / Total underlying
    // Liquidity ratio should larger than 1 in most cases except a short period after rebalance.
    // Minimum liquidity ratio sets the upper bound of impermanent loss caused by rebalance.
    uint256 public minLiquidityRatio;


    /**
     * @dev Initlaizes the composite plus token.
     */
    function initialize(string memory _name, string memory _symbol) public initializer {
        __PlusToken__init(_name, _symbol);
        __ReentrancyGuard_init();
    }

    /**
     * @dev Returns the total value of the plus token in terms of the peg value.
     * All underlying token amounts have been scaled to 18 decimals and expressed in WAD.
     */
    function _totalUnderlyingInWad() internal view virtual override returns (uint256) {
        uint256 _amount = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            // Since all underlying tokens in the baskets are plus tokens with the same value peg, the amount
            // minted is the amount of all plus tokens in the basket added.
            // Note: All plus tokens, single or composite, have 18 decimals.
            _amount = _amount.add(IERC20Upgradeable(tokens[i]).balanceOf(address(this)));
        }

        // Plus tokens are in 18 decimals, need to return in WAD.
        return _amount.mul(WAD);
    }

    /**
     * @dev Returns the amount of composite plus tokens minted with the tokens provided.
     * @dev _tokens The tokens used to mint the composite plus token.
     * @dev _amounts Amount of tokens used to mint the composite plus token.
     */
    function getMintAmount(address[] calldata _tokens, uint256[] calldata _amounts) external view override returns(uint256) {
        require(_tokens.length == _amounts.length, "invalid input");
        uint256 _amount = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(!mintPaused[_tokens[i]], "token paused");
            require(tokenSupported[_tokens[i]], "token not supported");
            if (_amounts[i] == 0) continue;

            // Since all underlying tokens in the baskets are plus tokens with the same value peg, the amount
            // minted is the amount of all tokens to mint added.
            // Note: All plus tokens, single or composite, have 18 decimals.
            _amount = _amount.add(_amounts[i]);
        }

        return _amount;
    }

    /**
     * @dev Mints composite plus tokens with underlying tokens provided.
     * @dev _tokens The tokens used to mint the composite plus token. The composite plus token must have sufficient allownance on the token.
     * @dev _amounts Amount of tokens used to mint the composite plus token.
     */
    function mint(address[] calldata _tokens, uint256[] calldata _amounts) external override nonReentrant {
        require(_tokens.length == _amounts.length, "invalid input");

        // Rebase first to make index up-to-date
        rebase();
        uint256 _amount = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(tokenSupported[_tokens[i]], "token not supported");
            require(!mintPaused[_tokens[i]], "token paused");
            if (_amounts[i] == 0) continue;

            _amount = _amount.add(_amounts[i]);
            // Transfers the token into pool.
            IERC20Upgradeable(_tokens[i]).safeTransferFrom(msg.sender, address(this), _amounts[i]);
        }

        uint256 _share = _amount.mul(WAD).div(index);
        uint256 _oldShare = userShare[msg.sender];
        uint256 _newShare = _oldShare.add(_share);
        uint256 _totalShares = totalShares.add(_share);
        totalShares = _totalShares;
        userShare[msg.sender] = _newShare;

        emit UserShareUpdated(msg.sender, _oldShare, _newShare, _totalShares);
        emit Minted(msg.sender, _tokens, _amounts, _share, _amount);

        emit Transfer(address(0x0), msg.sender, _amount);
    }

    /**
     * @dev Returns the amount of tokens received in redeeming the composite plus token.
     * @param _amount Amounf of composite plus to redeem.
     * @return Addresses and amounts of tokens returned as well as fee collected.
     */
    function getRedeemAmount(uint256 _amount) external view override returns (address[] memory, uint256[] memory, uint256, uint256) {
        require(_amount > 0, "zero amount");

        // Special handling of -1 is required here in order to fully redeem all shares, since interest
        // will be accrued between the redeem transaction is signed and mined.
        uint256 _share;
        if (_amount == uint256(int256(-1))) {
            _share = userShare[msg.sender];
            _amount = _share.mul(index).div(WAD);
        } else {
            _share  = _amount.mul(WAD).div(index);
        }

        // Withdraw ratio = min(liquidity ratio, 1 - redeem fee)
        // Liquidity ratio is in WAD and redeem fee is in 0.01%
        uint256 _withdrawAmount1 = _amount.mul(liquidityRatio()).div(WAD);
        uint256 _withdrawAmount2 = _amount.mul(MAX_PERCENT - redeemFee).div(MAX_PERCENT);
        uint256 _withdrawAmount = MathUpgradeable.min(_withdrawAmount1, _withdrawAmount2);
        uint256 _fee = _amount.sub(_withdrawAmount);

        address[] memory _redeemTokens = tokens;
        uint256[] memory _redeemAmounts = new uint256[](_redeemTokens.length);
        uint256 _totalSupply = totalSupply();
        for (uint256 i = 0; i < _redeemTokens.length; i++) {
            uint256 _balance = IERC20Upgradeable(_redeemTokens[i]).balanceOf(address(this));
            if (_balance == 0)   continue;

            _redeemAmounts[i] = _balance.mul(_withdrawAmount).div(_totalSupply);
        }

        return (_redeemTokens, _redeemAmounts, _share, _fee);
    }

    /**
     * @dev Redeems the composite plus token. In the current implementation only proportional redeem is supported.
     * @param _amount Amount of composite plus token to redeem. -1 means redeeming all shares.
     */
    function redeem(uint256 _amount) external override nonReentrant {
        require(_amount > 0, "zero amount");

        // Rebase first to make index up-to-date
        rebase();

        // Special handling of -1 is required here in order to fully redeem all shares, since interest
        // will be accrued between the redeem transaction is signed and mined.
        uint256 _share;
        if (_amount == uint256(int256(-1))) {
            _share = userShare[msg.sender];
            _amount = _share.mul(index).div(WAD);
        } else {
            _share  = _amount.mul(WAD).div(index);
        }

        // Withdraw ratio = min(liquidity ratio, 1 - redeem fee)
        uint256 _withdrawAmount1 = _amount.mul(liquidityRatio()).div(WAD);
        uint256 _withdrawAmount2 = _amount.mul(MAX_PERCENT - redeemFee).div(MAX_PERCENT);
        uint256 _withdrawAmount = MathUpgradeable.min(_withdrawAmount1, _withdrawAmount2);
        uint256 _fee = _amount.sub(_withdrawAmount);

        address[] memory _redeemTokens = tokens;
        uint256[] memory _redeemAmounts = new uint256[](_redeemTokens.length);
        uint256 _totalSupply = totalSupply();
        for (uint256 i = 0; i < _redeemTokens.length; i++) {
            uint256 _balance = IERC20Upgradeable(_redeemTokens[i]).balanceOf(address(this));
            if (_balance == 0)   continue;

            _redeemAmounts[i] = _balance.mul(_withdrawAmount).div(_totalSupply);
            IERC20Upgradeable(_redeemTokens[i]).safeTransfer(msg.sender, _redeemAmounts[i]);
        }

        // Updates the balance
        uint256 _oldShare = userShare[msg.sender];
        uint256 _newShare = _oldShare.sub(_share);
        totalShares = totalShares.sub(_share);
        userShare[msg.sender] = _newShare;

        emit UserShareUpdated(msg.sender, _oldShare, _newShare, totalShares);
        emit Redeemed(msg.sender, _redeemTokens, _redeemAmounts, _share, _amount, _fee);

        emit Transfer(msg.sender, address(0x0), _amount);
    }

    /**
     * @dev Updates the mint paused state of a token.
     * @param _token Token to update mint paused.
     * @param _paused Whether minting with that token is paused.
     */
    function setMintPaused(address _token, bool _paused) external onlyStrategist {
        require(tokenSupported[_token], "not supported");
        require(mintPaused[_token] != _paused, "no change");

        mintPaused[_token] = _paused;
        emit MintPausedUpdated(_token, _paused);
    }

    /**
     * @dev Adds a new rebalancer. Only governance can add new rebalancers.
     */
    function addRebalancer(address _rebalancer) external onlyGovernance {
        require(_rebalancer != address(0x0), "rebalancer not set");
        require(!rebalancers[_rebalancer], "rebalancer exist");

        rebalancers[_rebalancer] = true;
        emit RebalancerUpdated(_rebalancer, true);
    }

    /**
     * @dev Remove an existing rebalancer. Only strategist can remove existing rebalancers.
     */
    function removeRebalancer(address _rebalancer) external onlyStrategist {
        require(rebalancers[_rebalancer], "rebalancer exist");

        rebalancers[_rebalancer] = false;
        emit RebalancerUpdated(_rebalancer, false);
    }

    /**
     * @dev Udpates the minimum liquidity ratio. Only governance can update minimum liquidity ratio.
     */
    function setMinLiquidityRatio(uint256 _minLiquidityRatio) external onlyGovernance {
        require(_minLiquidityRatio <= WAD, "overflow");
        require(_minLiquidityRatio <= liquidityRatio(), "ratio too big");
        uint256 _oldRatio = minLiquidityRatio;

        minLiquidityRatio = _minLiquidityRatio;
        emit MinLiquidityRatioUpdated(_oldRatio, _minLiquidityRatio);
    }

    /**
     * @dev Adds a new plus token to the basket. Only governance can add new plus token.
     * @param _token The new plus token to add.
     */
    function addToken(address _token) external onlyGovernance {
        require(_token != address(0x0), "token not set");
        require(!tokenSupported[_token], "token exists");

        tokenSupported[_token] = true;
        tokens.push(_token);

        emit TokenAdded(_token);
    }

    /**
     * @dev Removes a plus token from the basket. Only governance can remove a plus token.
     * Note: A token cannot be removed if it's balance is not zero!
     * @param _token The plus token to remove from the basket.
     */
    function removeToken(address _token) external onlyGovernance {
        require(tokenSupported[_token], "token not exists");
        require(IERC20Upgradeable(_token).balanceOf(address(this)) == 0, "nonzero balance");

        uint256 _tokenSize = tokens.length;
        uint256 _tokenIndex = _tokenSize;
        for (uint256 i = 0; i < _tokenSize; i++) {
            if (tokens[i] == _token) {
                _tokenIndex = i;
                break;
            }
        }
        // We must have found the token!
        assert(_tokenIndex < _tokenSize);

        tokens[_tokenIndex] = tokens[_tokenSize - 1];
        tokens.pop();
        delete tokenSupported[_token];
        // Delete the mint paused state as well
        delete mintPaused[_token];

        emit TokenRemoved(_token);
    }

    /**
     * @dev Return the total number of tokens.
     */
    function tokenSize() external view returns (uint256) {
        return tokens.length;
    }

    /**
     * @dev Returns the list of plus tokens.
     */
    function tokenList() external view override returns (address[] memory) {
        return tokens;
    }

    /**
     * @dev Rebalances the basket, e.g. for a better yield. Only strategist can perform rebalance.
     * @param _tokens Address of the tokens to withdraw from the basket.
     * @param _amounts Amounts of the tokens to withdraw from the basket.
     * @param _rebalancer Address of the rebalancer contract to invoke.
     * @param _data Data to invoke on rebalancer contract.
     */
    function rebalance(address[] memory _tokens, uint256[] memory _amounts, address _rebalancer, bytes calldata _data) external onlyStrategist {
        require(rebalancers[_rebalancer], "invalid rebalancer");
        require(_tokens.length == _amounts.length, "invalid input");

        // Rebase first to make index up-to-date
        rebase();
        uint256 _underlyingBefore = _totalUnderlyingInWad();

        for (uint256 i = 0; i < _tokens.length; i++) {
            require(tokenSupported[_tokens[i]], "token not supported");
            if (_amounts[i] == 0)   continue;

            IERC20Upgradeable(_tokens[i]).safeTransfer(_rebalancer, _amounts[i]);
        }
        // Invokes rebalancer contract.
        IRebalancer(_rebalancer).rebalance(_tokens, _amounts, _data);

        // Check post-rebalance conditions.
        uint256 _underlyingAfter = _totalUnderlyingInWad();
        uint256 _supply = totalSupply();
        // _underlyingAfter / _supply > minLiquidityRatio
        require(_underlyingAfter > _supply.mul(minLiquidityRatio), "too much loss");

        emit Rebalanced(_underlyingBefore, _underlyingAfter, _supply);
    }

    /**
     * @dev Checks whether a token can be salvaged via salvageToken().
     * @param _token Token to check salvageability.
     */
    function _salvageable(address _token) internal view override returns (bool) {
        // For composite plus, all tokens in the basekt cannot be salvaged!
        return !tokenSupported[_token];
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IPlus.sol";

/**
 * @title Plus token base contract.
 *
 * Plus token is a value pegged ERC20 token which provides global interest to all holders.
 * It can be categorized as single plus token and composite plus token:
 * 
 * Single plus token is backed by one ERC20 token and targeted at yield generation.
 * Composite plus token is backed by a basket of ERC20 token and targeted at better basket management.
 */
abstract contract Plus is ERC20Upgradeable, IPlus {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Emitted each time the share of a user is updated.
     */
    event UserShareUpdated(address indexed account, uint256 oldShare, uint256 newShare, uint256 totalShares);
    event Rebased(uint256 oldIndex, uint256 newIndex, uint256 totalUnderlying);
    event Donated(address indexed account, uint256 amount, uint256 share);

    event GovernanceUpdated(address indexed oldGovernance, address indexed newGovernance);
    event StrategistUpdated(address indexed strategist, bool allowed);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event RedeemFeeUpdated(uint256 oldFee, uint256 newFee);
    event MintPausedUpdated(address indexed token, bool paused);

    uint256 public constant MAX_PERCENT = 10000; // 0.01%
    uint256 public constant WAD = 1e18;

    /**
     * @dev Struct to represent a rebase hook.
     */
    struct Transaction {
        bool enabled;
        address destination;
        bytes data;
    }
    // Rebase hooks
    Transaction[] public transactions;

    uint256 public totalShares;
    mapping(address => uint256) public userShare;
    // The exchange rate between total shares and BTC+ total supply. Express in WAD.
    // It's equal to the amount of plus token per share.
    // Note: The index will never decrease!
    uint256 public index;

    address public override governance;
    mapping(address => bool) public override strategists;
    address public override treasury;

    // Governance parameters
    uint256 public redeemFee;

    // EIP 2612: Permit
    // Credit: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    /**
     * @dev Initializes the plus token contract.
     */
    function __PlusToken__init(string memory _name, string memory _symbol) internal initializer {
        __ERC20_init(_name, _symbol);
        index = WAD;
        governance = msg.sender;
        treasury = msg.sender;

        uint _chainId;
        assembly {
            _chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(_name)),
                keccak256(bytes('1')),
                _chainId,
                address(this)
            )
        );
    }

    function _checkGovernance() internal view {
        require(msg.sender == governance, "not governance");
    }

    modifier onlyGovernance() {
        _checkGovernance();
        _;
    }

    function _checkStrategist() internal view {
        require(msg.sender == governance || strategists[msg.sender], "not strategist");
    }

    modifier onlyStrategist {
        _checkStrategist();
        _;
    }

    /**
     * @dev Returns the total value of the plus token in terms of the peg value in WAD.
     * All underlying token amounts have been scaled to 18 decimals, then expressed in WAD.
     */
    function _totalUnderlyingInWad() internal view virtual returns (uint256);

    /**
     * @dev Returns the total value of the plus token in terms of the peg value.
     * For single plus, it's equal to its total supply.
     * For composite plus, it's equal to the total amount of single plus tokens in its basket.
     */
    function totalUnderlying() external view override returns (uint256) {
        return _totalUnderlyingInWad().div(WAD);
    }

    /**
     * @dev Returns the total supply of plus token. See {IERC20Updateable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return totalShares.mul(index).div(WAD);
    }

    /**
     * @dev Returns the balance of plus token for the account. See {IERC20Updateable-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return userShare[account].mul(index).div(WAD);
    }

    /**
     * @dev Returns the current liquidity ratio of the plus token in WAD.
     */
    function liquidityRatio() public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        return _totalSupply == 0 ? WAD : _totalUnderlyingInWad().div(_totalSupply);
    }

    /**
     * @dev Accrues interest to increase index.
     */
    function rebase() public override {
        uint256 _totalShares = totalShares;
        if (_totalShares == 0)  return;

        // underlying is in WAD, and index is also in WAD
        uint256 _underlying = _totalUnderlyingInWad();
        uint256 _oldIndex = index;
        uint256 _newIndex = _underlying.div(_totalShares);

        // _newIndex - oldIndex is the amount of interest generated for each share
        // _oldIndex might be larger than _newIndex in a short period of time. In this period, the liquidity ratio is smaller than 1.
        if (_newIndex > _oldIndex) {
            // Index can never decrease
            index = _newIndex;

            for (uint256 i = 0; i < transactions.length; i++) {
                Transaction storage transaction = transactions[i];
                if (transaction.enabled) {
                    (bool success, ) = transaction.destination.call(transaction.data);
                    require(success, "rebase hook failed");
                }
            }
            
            // In this event we are returning underlyiing() which can be used to compute the actual interest generated.
            emit Rebased(_oldIndex, _newIndex, _underlying.div(WAD));
        }
    }

    /**
     * @dev Allows anyone to donate their plus asset to all other holders.
     * @param _amount Amount of plus token to donate.
     */
    function donate(uint256 _amount) public override {
        // Rebase first to make index up-to-date
        rebase();
        // Special handling of -1 is required here in order to fully donate all shares, since interest
        // will be accrued between the donate transaction is signed and mined.
        uint256 _share;
        if (_amount == uint256(int256(-1))) {
            _share = userShare[msg.sender];
            _amount = _share.mul(index).div(WAD);
        } else {
            _share  = _amount.mul(WAD).div(index);
        }

        uint256 _oldShare = userShare[msg.sender];
        uint256 _newShare = _oldShare.sub(_share, "insufficient share");
        uint256 _newTotalShares = totalShares.sub(_share);
        userShare[msg.sender] = _newShare;
        totalShares = _newTotalShares;

        emit UserShareUpdated(msg.sender, _oldShare, _newShare, _newTotalShares);
        emit Donated(msg.sender, _amount, _share);

        // Donation is similar to redeem except that the asset is left in the pool.
        emit Transfer(msg.sender, address(0x0), _amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     */
    function _transfer(address _sender, address _recipient, uint256 _amount) internal virtual override {
        require(_sender != _recipient, "recipient cannot be sender");
        // Rebase first to make index up-to-date
        rebase();
        uint256 _shareToTransfer = _amount.mul(WAD).div(index);

        uint256 _oldSenderShare = userShare[_sender];
        uint256 _newSenderShare = _oldSenderShare.sub(_shareToTransfer, "insufficient share");
        uint256 _oldRecipientShare = userShare[_recipient];
        uint256 _newRecipientShare = _oldRecipientShare.add(_shareToTransfer);
        uint256 _totalShares = totalShares;

        userShare[_sender] = _newSenderShare;
        userShare[_recipient] = _newRecipientShare;

        emit UserShareUpdated(_sender, _oldSenderShare, _newSenderShare, _totalShares);
        emit UserShareUpdated(_recipient, _oldRecipientShare, _newRecipientShare, _totalShares);

        emit Transfer(_sender, _recipient, _amount);
    }

    /**
     * @dev Gassless approve.
     */
    function permit(address _owner, address _spender, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(_deadline >= block.timestamp, 'expired');
        bytes32 _digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, nonces[_owner]++, _deadline))
            )
        );
        address _recoveredAddress = ecrecover(_digest, _v, _r, _s);
        require(_recoveredAddress != address(0) && _recoveredAddress == _owner, 'invalid signature');
        _approve(_owner, _spender, _value);
    }

    /*********************************************
     *
     *    Governance methods
     *
     **********************************************/

    /**
     * @dev Updates governance. Only governance can update governance.
     */
    function setGovernance(address _governance) external onlyGovernance {
        address _oldGovernance = governance;
        governance = _governance;
        emit GovernanceUpdated(_oldGovernance, _governance);
    }

    /**
     * @dev Updates strategist. Both governance and strategists can update strategist.
     */
    function setStrategist(address _strategist, bool _allowed) external onlyStrategist {
        require(_strategist != address(0x0), "strategist not set");

        strategists[_strategist] = _allowed;
        emit StrategistUpdated(_strategist, _allowed);
    }

    /**
     * @dev Updates the treasury. Only governance can update treasury.
     */
    function setTreasury(address _treasury) external onlyGovernance {
        require(_treasury != address(0x0), "treasury not set");

        address _oldTreasury = treasury;
        treasury = _treasury;
        emit TreasuryUpdated(_oldTreasury, _treasury);
    }

    /**
     * @dev Updates the redeem fee. Only governance can update redeem fee.
     */
    function setRedeemFee(uint256 _redeemFee) external onlyGovernance {
        require(_redeemFee <= MAX_PERCENT, "redeem fee too big");
        uint256 _oldFee = redeemFee;

        redeemFee = _redeemFee;
        emit RedeemFeeUpdated(_oldFee, _redeemFee);
    }

    /**
     * @dev Used to salvage any ETH deposited to BTC+ contract by mistake. Only strategist can salvage ETH.
     * The salvaged ETH is transferred to treasury for futher operation.
     */
    function salvage() external onlyStrategist {
        uint256 _amount = address(this).balance;
        address payable _target = payable(treasury);
        (bool _success, ) = _target.call{value: _amount}(new bytes(0));
        require(_success, 'ETH salvage failed');
    }

    /**
     * @dev Checks whether a token can be salvaged via salvageToken().
     * @param _token Token to check salvageability.
     */
    function _salvageable(address _token) internal view virtual returns (bool);

    /**
     * @dev Used to salvage any token deposited to plus contract by mistake. Only strategist can salvage token.
     * The salvaged token is transferred to treasury for futhuer operation.
     * @param _token Address of the token to salvage.
     */
    function salvageToken(address _token) external onlyStrategist {
        require(_token != address(0x0), "token not set");
        require(_salvageable(_token), "cannot salvage");

        IERC20Upgradeable _target = IERC20Upgradeable(_token);
        _target.safeTransfer(treasury, _target.balanceOf(address(this)));
    }

    /**
     * @dev Add a new rebase hook.
     * @param _destination Destination contract for the reabase hook.
     * @param _data Transaction payload for the rebase hook.
     */
    function addTransaction(address _destination, bytes memory _data) external onlyGovernance {
        transactions.push(Transaction({enabled: true, destination: _destination, data: _data}));
    }

    /**
     * @dev Remove a rebase hook.
     * @param _index Index of the transaction to remove.
     */
    function removeTransaction(uint256 _index) external onlyGovernance {
        require(_index < transactions.length, "index out of bounds");

        if (_index < transactions.length - 1) {
            transactions[_index] = transactions[transactions.length - 1];
        }

        transactions.pop();
    }

    /**
     * @dev Updates an existing rebase hook transaction.
     * @param _index Index of transaction. Transaction ordering may have changed since adding.
     * @param _enabled True for enabled, false for disabled.
     */
    function updateTransaction(uint256 _index, bool _enabled) external onlyGovernance {
        require(_index < transactions.length, "index must be in range of stored tx list");
        transactions[_index].enabled = _enabled;
    }

    /**
     * @dev Returns the number of rebase hook transactions.
     */
    function transactionSize() external view returns (uint256) {
        return transactions.length;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "../../CompositePlus.sol";

/**
 * @title BadgerBTC+ token contract.
 * 
 * BadgerBTC+ is a composite plus that is backed by single pluses which are backed by
 * Badger's Sett.
 */
contract BadgerBTCPlus is CompositePlus {

    /**
     * @dev Initializes the BadgerBTC+ contract.
     */
    function initialize() public initializer {
        CompositePlus.initialize("Badger BTC Plus", "BadgerBTC+");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IPlus.sol";

/**
 * @title Interface for composite plus token.
 * Composite plus is backed by a basket of plus with the same peg.
 */
interface ICompositePlus is IPlus {
    /**
     * @dev Returns the address of the underlying token.
     */
    function tokens(uint256 _index) external view returns (address);

    /**
     * @dev Returns the list of plus tokens.
     */
    function tokenList() external view returns (address[] memory);

    /**
     * @dev Checks whether a token is supported by the basket.
     */
    function tokenSupported(address _token) external view returns (bool);

    /**
     * @dev Returns the amount of composite plus tokens minted with the tokens provided.
     * @dev _tokens The tokens used to mint the composite plus token.
     * @dev _amounts Amount of tokens used to mint the composite plus token.
     */
    function getMintAmount(address[] calldata _tokens, uint256[] calldata _amounts) external view returns(uint256);

     /**
     * @dev Mints composite plus tokens with underlying tokens provided.
     * @dev _tokens The tokens used to mint the composite plus token. The composite plus token must have sufficient allownance on the token.
     * @dev _amounts Amount of tokens used to mint the composite plus token.
     */
    function mint(address[] calldata _tokens, uint256[] calldata _amounts) external;

    /**
     * @dev Returns the amount of tokens received in redeeming the composite plus token.
     * @param _amount Amounf of composite plus to redeem.
     * @return Addresses and amounts of tokens returned as well as fee collected.
     */
    function getRedeemAmount(uint256 _amount) external view returns (address[] memory, uint256[] memory, uint256, uint256);

    /**
     * @dev Redeems the composite plus token. In the current implementation only proportional redeem is supported.
     * @param _amount Amount of composite plus token to redeem. -1 means redeeming all shares.
     */
    function redeem(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @title Interface for plus token.
 * Plus token is a value pegged ERC20 token which provides global interest to all holders.
 */
interface IPlus {
    /**
     * @dev Returns the governance address.
     */
    function governance() external view returns (address);

    /**
     * @dev Returns whether the account is a strategist.
     */
    function strategists(address _account) external view returns (bool);

    /**
     * @dev Returns the treasury address.
     */
    function treasury() external view returns (address);

    /**
     * @dev Accrues interest to increase index.
     */
    function rebase() external;

    /**
     * @dev Returns the total value of the plus token in terms of the peg value.
     */
    function totalUnderlying() external view returns (uint256);

    /**
     * @dev Allows anyone to donate their plus asset to all other holders.
     * @param _amount Amount of plus token to donate.
     */
    function donate(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @title Interface of BTC+ pools rebalancer.
 */
interface IRebalancer {

    /**
     * @dev Performs rebalance after receiving the requested tokens.
     * @param _tokens Address of the tokens received from BTC+ pools.
     * @param _amounts Amounts of the tokens received from BTC+ pools.
     * @param _data Data to invoke on rebalancer contract.
     */
    function rebalance(address[] calldata _tokens, uint256[] calldata _amounts, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

