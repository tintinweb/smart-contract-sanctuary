// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <=0.8.9;
pragma experimental ABIEncoderV2;
import "./interfaces/IWETH.sol";
import "./interfaces/IBurnableToken.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ISwapContract.sol";
import "./interfaces/IAugustusSwapper.sol";
import "./interfaces/ITokenTransferProxy.sol";
import "./interfaces/IParaswap.sol";
import "./interfaces/lib/Utils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/lib/SafeERC20.sol";
import "hardhat/console.sol";
//skypools - needed for address => tokenBalance
import "./LPToken.sol";

contract SwapContract is Ownable, ReentrancyGuard, ISwapContract {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct spPendingTx {
        bytes32 SwapID; //swap hash for identification of this swap.
        bytes32 DestAddr; //destination BTC address for the swap
        address RefundAddr; //refund address on evm source chain for if the swap fails.
        uint256 AmountWBTC; //outbound amount for this swap.
        uint256 Timestamp; // block timestamp that is set by EVM
    }
    uint256 public expirationTime;

    mapping(uint256 => spPendingTx) public spPendingTXs; //index => pending TX object
    //spPendingTx[] spPendingTXs;
    uint256 public swapCount;
    uint256 public latestRemovedIndex;

    mapping(address => bool) public whitelist;

    address public immutable BTCT_ADDR;
    address public immutable lpToken;

    uint8 public churnedInCount;
    uint8 public tssThreshold;
    uint8 public nodeRewardsRatio;
    uint8 public depositFeesBPS;
    uint8 public withdrawalFeeBPS;
    uint256 public lockedLPTokensForNode;
    uint256 public feesLPTokensForNode;
    uint256 public initialExchangeRate;

    uint256 private immutable convertScale;
    uint256 private immutable lpDecimals;

    mapping(address => uint256) private floatAmountOf;
    mapping(bytes32 => bool) private used; //used TX

    // Node lists
    mapping(address => bytes32) private nodes;
    mapping(address => bool) private isInList;
    address[] private nodeAddrs;

    //skypools - token balance - call using tokens[token address][user address] to get uint256 balance - see function balanceOf
    mapping(address => mapping(address => uint256)) public tokens;
    //keep track of ether in tokens[][]
    address constant ETHER =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant paraswapAddress =
        0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;
    address public immutable wETH;

    /**
     * Events
     */
    event Swap(address from, address to, uint256 amount);
    event Withdraw(
        address token,
        address user,
        uint256 amount,
        uint256 balance,
        uint256 Timestamp
    );
    event Deposit(
        address token,
        address user,
        uint256 amount,
        uint256 balance,
        uint256 Timestamp
    );
    event RewardsCollection(
        address feesToken,
        uint256 rewards,
        uint256 amountLPTokensForNode,
        uint256 currentPriceLP
    );

    event IssueLPTokensForFloat(
        address to,
        uint256 amountOfFloat,
        uint256 amountOfLP,
        uint256 currentPriceLP,
        uint256 depositFees,
        bytes32 txid
    );

    event BurnLPTokensForFloat(
        address token,
        uint256 amountOfLP,
        uint256 amountOfFloat,
        uint256 currentPriceLP,
        uint256 withdrawal,
        bytes32 txid
    );

    event SwapTokensToBTC(
        bytes32 SwapID,
        bytes32 DestAddr,
        address RefundAddr,
        uint256 AmountWBTC,
        uint256 Timestamp
    );

    event SetExpirationTime(uint256 ExpirationTime, uint256 Timestamp);

    event DistributeNodeRewards(uint256 rewardLPTsForNodes);

    modifier priceCheck() {
        uint256 beforePrice = getCurrentPriceLP();
        _;
        require(getCurrentPriceLP() >= beforePrice, "Invalid LPT price");
    }

    constructor(
        address _lpToken,
        address _btct,
        address _wETH,
        uint256 _existingBTCFloat
    ) {
        //set default expiration time for pending TX
        expirationTime = 172800; //2 days
        //init latest removed index and swapCount
        latestRemovedIndex = 0;
        swapCount = 0;
        //set address for wETH
        wETH = _wETH;
        // Set lpToken address
        lpToken = _lpToken;
        // Set initial lpDecimals of LP token
        lpDecimals = 10**IERC20(_lpToken).decimals();
        // Set BTCT address
        BTCT_ADDR = _btct;
        // Set nodeRewardsRatio
        nodeRewardsRatio = 66;
        // Set depositFeesBPS
        depositFeesBPS = 50;
        // Set withdrawalFeeBPS
        withdrawalFeeBPS = 20;
        // Set convertScale
        convertScale = 10**(IERC20(_btct).decimals() - 8);
        // Set initialExchangeRate
        initialExchangeRate = 10**IERC20(_lpToken).decimals();
        // Set lockedLPTokensForNode
        lockedLPTokensForNode = 0;
        // Set feesLPTokensForNode
        feesLPTokensForNode = 0;
        // Set whitelist addresses
        whitelist[_btct] = true;
        whitelist[_lpToken] = true;
        whitelist[address(0)] = true;
        floatAmountOf[address(0)] = _existingBTCFloat;
    }

    /**
     * Transfer part
     */

    /// @dev singleTransferERC20 sends tokens from contract.
    /// @param _destToken The address of target token.
    /// @param _to The address of recipient.
    /// @param _amount The amount of tokens.
    /// @param _totalSwapped The amount of swap.
    /// @param _rewardsAmount The fees that should be paid.
    /// @param _redeemedFloatTxIds The txids which is for recording.
    function singleTransferERC20(
        address _destToken,
        address _to,
        uint256 _amount,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _redeemedFloatTxIds
    ) external override onlyOwner returns (bool) {
        require(whitelist[_destToken], "_destToken is not whitelisted");
        require(
            _destToken != address(0),
            "_destToken should not be address(0)"
        );
        address _feesToken;
        if (_totalSwapped > 0) {
            _swap(address(0), BTCT_ADDR, _totalSwapped);
        } else if (_totalSwapped == 0) {
            _feesToken = BTCT_ADDR;
        }
        if (_destToken == lpToken) {
            _feesToken = lpToken;
        }
        _rewardsCollection(_feesToken, _rewardsAmount);
        _addUsedTxs(_redeemedFloatTxIds);
        _safeTransfer(_destToken, _to, _amount);
        return true;
    }

    /// @dev multiTransferERC20TightlyPacked sends tokens from contract.
    /// @param _destToken The address of target token.
    /// @param _addressesAndAmounts The address of recipient and amount.
    /// @param _totalSwapped The amount of swap.
    /// @param _rewardsAmount The fees that should be paid.
    /// @param _redeemedFloatTxIds The txids which is for recording.
    function multiTransferERC20TightlyPacked(
        address _destToken,
        bytes32[] memory _addressesAndAmounts,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _redeemedFloatTxIds
    ) external override onlyOwner returns (bool) {
        require(whitelist[_destToken], "_destToken is not whitelisted");
        require(
            _destToken != address(0),
            "_destToken should not be address(0)"
        );
        address _feesToken;
        if (_totalSwapped > 0) {
            _swap(address(0), BTCT_ADDR, _totalSwapped);
        } else if (_totalSwapped == 0) {
            _feesToken = BTCT_ADDR;
        }
        if (_destToken == lpToken) {
            _feesToken = lpToken;
        }
        _rewardsCollection(_feesToken, _rewardsAmount);
        _addUsedTxs(_redeemedFloatTxIds);
        for (uint256 i = 0; i < _addressesAndAmounts.length; i++) {
            _safeTransfer(
                _destToken,
                address(uint160(uint256(_addressesAndAmounts[i]))),
                uint256(uint96(bytes12(_addressesAndAmounts[i])))
            );
        }
        return true;
    }

    /// @dev collectSwapFeesForBTC collects fees in the case of swap BTCT to BTC.
    /// @param _destToken The address of target token.
    /// @param _incomingAmount The spent amount. (BTCT)
    /// @param _minerFee The miner fees of BTC transaction.
    /// @param _rewardsAmount The fees that should be paid.
    function collectSwapFeesForBTC(
        address _destToken,
        uint256 _incomingAmount,
        uint256 _minerFee,
        uint256 _rewardsAmount
    ) external override onlyOwner returns (bool) {
        require(_destToken == address(0), "_destToken should be address(0)");
        address _feesToken = BTCT_ADDR;
        if (_incomingAmount > 0) {
            uint256 swapAmount = _incomingAmount.sub(_rewardsAmount).sub(
                _minerFee
            );
            _swap(BTCT_ADDR, address(0), swapAmount.add(_minerFee));
        } else if (_incomingAmount == 0) {
            _feesToken = address(0);
        }
        _rewardsCollection(_feesToken, _rewardsAmount);
        return true;
    }

    /**
     * Float part
     */
    /// @dev recordIncomingFloat mints LP token.
    /// @param _token The address of target token.
    /// @param _addressesAndAmountOfFloat The address of recipient and amount.
    /// @param _zerofee The flag to accept zero fees.
    /// @param _txid The txids which is for recording.
    function recordIncomingFloat(
        address _token,
        bytes32 _addressesAndAmountOfFloat,
        bool _zerofee,
        bytes32 _txid
    ) external override onlyOwner priceCheck returns (bool) {
        require(whitelist[_token], "_token is invalid");
        require(
            _issueLPTokensForFloat(
                _token,
                _addressesAndAmountOfFloat,
                _zerofee,
                _txid
            )
        );
        return true;
    }

    /// @dev recordOutcomingFloat burns LP token.
    /// @param _token The address of target token.
    /// @param _addressesAndAmountOfLPtoken The address of recipient and amount.
    /// @param _minerFee The miner fees of BTC transaction.
    /// @param _txid The txid which is for recording.
    function recordOutcomingFloat(
        address _token,
        bytes32 _addressesAndAmountOfLPtoken,
        uint256 _minerFee,
        bytes32 _txid
    ) external override onlyOwner priceCheck returns (bool) {
        require(whitelist[_token], "_token is invalid");
        require(
            _burnLPTokensForFloat(
                _token,
                _addressesAndAmountOfLPtoken,
                _minerFee,
                _txid
            )
        );
        return true;
    }

    /// @dev distributeNodeRewards sends rewards for Nodes.
    function distributeNodeRewards() external override returns (bool) {
        // Reduce Gas
        uint256 rewardLPTsForNodes = lockedLPTokensForNode.add(
            feesLPTokensForNode
        );
        require(
            rewardLPTsForNodes > 0,
            "totalRewardLPsForNode is not positive"
        );
        bytes32[] memory nodeList = getActiveNodes();
        uint256 totalStaked = 0;
        for (uint256 i = 0; i < nodeList.length; i++) {
            totalStaked = totalStaked.add(
                uint256(uint96(bytes12(nodeList[i])))
            );
        }
        IBurnableToken(lpToken).mint(address(this), lockedLPTokensForNode);
        for (uint256 i = 0; i < nodeList.length; i++) {
            IBurnableToken(lpToken).transfer(
                address(uint160(uint256(nodeList[i]))),
                rewardLPTsForNodes
                    .mul(uint256(uint96(bytes12(nodeList[i]))))
                    .div(totalStaked)
            );
        }
        emit DistributeNodeRewards(rewardLPTsForNodes);
        lockedLPTokensForNode = 0;
        feesLPTokensForNode = 0;
        return true;
    }

    /**
     * Skypools part
     */

    /// @dev Record SkyPools TX - allocate tokens from float to user in tokens[][]
    /// @param _to The address of recipient.
    /// @param _totalSwapped The amount of swap amount.
    /// @param _rewardsAmount The fees that should be paid.
    /// @param _usedTxIds The txids which is for recording this function.
    function recordSkyPoolsTX(
        address _to,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _usedTxIds
    ) external onlyOwner returns (bool) {
        require(_totalSwapped != 0, "_totalSwapped must be non zero");
        require(_rewardsAmount != 0, "_rewardsAmount must be non zero");

        _swap(address(0), BTCT_ADDR, _totalSwapped);

        tokens[BTCT_ADDR][_to] = tokens[BTCT_ADDR][_to].add(_totalSwapped);

        _rewardsCollection(address(0), _rewardsAmount);

        _addUsedTxs(_usedTxIds);

        return true;
    }

    /// @dev balanceOf - return user balance for given token and user for skypools
    /// @param _token The address of target token.
    /// @param _user The address of target user.
    function balanceOf(address _token, address _user)
        public
        view
        returns (uint256)
    {
        return tokens[_token][_user];
    }

    /// @dev spFlow1SimpleSwap - FLOW 1 - execute paraswap TX using simpleSwap, ending tokens sent DIRECTLY to user's wallet
    /// @param _data A struct containing the data for simpleSwap, from the paraswap lib.
    function spFlow1SimpleSwap(Utils.SimpleData calldata _data)
        external
        nonReentrant
    {
        require(
            _data.beneficiary == msg.sender,
            "You can only execute swaps to your own address"
        );

        require(
            tokens[_data.fromToken][_data.beneficiary] >= _data.fromAmount,
            "Balance is not sufficient"
        );
        require(
            _data.fromToken == BTCT_ADDR,
            "fromToken must be the required BTCt token"
        );
        _doSimpleSwap(_data); //no received amount, tokens to go user's wallet

        tokens[_data.fromToken][_data.beneficiary] = tokens[_data.fromToken][
            _data.beneficiary
        ].sub(_data.fromAmount);
    }

    /// @dev spFlow1Uniswap - FLOW 1 - execute paraswap TX using uniswap, ending tokens sent to users allocation in tokens[][] mapping
    /// @param _fork - BOOL to determine if using swapOnUniswap or swapOnUniswapFork paraswap contract methods
    /// @param _factory - param for swapOnUniswapFork
    /// @param _initCode - param for swapOnUniswapFork
    /// @param _amountIn - param for swapOnUniswapFork or swapOnUniswap
    /// @param _amountOutMin - param for swapOnUniswapFork or swapOnUniswap
    /// @param _path - param for swapOnUniswapFork or swapOnUniswap
    function spFlow1Uniswap(
        bool _fork,
        address _factory,
        bytes32 _initCode,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path
    ) external nonReentrant {
        address fromToken = _path[0];
        address endToken = _path[_path.length - 1];

        require(
            tokens[fromToken][msg.sender] >= _amountIn,
            "Balance is not sufficient"
        );

        require(fromToken == BTCT_ADDR, "Must swap from BTC token");
        require(endToken != BTCT_ADDR, "Ending token must be wBTC");
        require(endToken != ETHER, "Use path wBTC -> wETH");

        uint256 preSwapBalance = IERC20(endToken).balanceOf(address(this));

        tokens[fromToken][msg.sender] = tokens[fromToken][msg.sender].sub(
            _amountIn
        );

        //do swap
        if (_fork) {
            _doUniswapFork(
                _factory,
                _initCode,
                _amountIn,
                _amountOutMin,
                _path
            );
        } else {
            _doUniswap(_amountIn, _amountOutMin, _path);
        }

        uint256 receivedAmount = IERC20(endToken).balanceOf(address(this)).sub(
            preSwapBalance
        );

        require(
            receivedAmount >= _amountOutMin,
            "Received amount insufficient"
        );
        require(receivedAmount != 0, "Received amount can not be 0");

        tokens[endToken][msg.sender] = tokens[endToken][msg.sender].add(
            receivedAmount
        );
    }

    /// @dev spFlow2Uniswap - FLOW 1 - execute paraswap TX using uniswap, ending tokens sent to users allocation in tokens[][] mapping
    /// @param _fork - BOOL to determine if using swapOnUniswap or swapOnUniswapFork paraswap contract methods
    /// @param _factory - param for swapOnUniswapFork
    /// @param _initCode - param for swapOnUniswapFork
    /// @param _amountIn - param for swapOnUniswapFork or swapOnUniswap
    /// @param _amountOutMin - param for swapOnUniswapFork or swapOnUniswap
    /// @param _path - param for swapOnUniswapFork or swapOnUniswap
    function spFlow2Uniswap(
        bytes32 _destinationAddressForBTC,
        bool _fork,
        address _factory,
        bytes32 _initCode,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path
    ) external nonReentrant {
        address fromToken = _path[0];
        address endToken = _path[_path.length - 1];

        require(
            tokens[fromToken][msg.sender] >= _amountIn,
            "Balance is not sufficient"
        );
        require(fromToken != BTCT_ADDR);
        require(fromToken != ETHER, "Use path wETH -> wBTC");
        require(endToken == BTCT_ADDR, "Must swap to BTC token");

        uint256 preSwapBalance = IERC20(endToken).balanceOf(address(this));

        tokens[fromToken][msg.sender] = tokens[fromToken][msg.sender].sub(
            _amountIn
        );

        //do swap
        if (_fork) {
            _doUniswapFork(
                _factory,
                _initCode,
                _amountIn,
                _amountOutMin,
                _path
            );
        } else {
            _doUniswap(_amountIn, _amountOutMin, _path);
        }

        uint256 receivedAmount = IERC20(endToken).balanceOf(address(this)).sub(
            preSwapBalance
        );

        require(
            receivedAmount >= _amountOutMin,
            "Received amount insufficient"
        );
        require(receivedAmount != 0, "Received amount can not be 0");

        tokens[endToken][address(this)] = tokens[endToken][address(this)].add(
            receivedAmount
        );

        _spRecordPendingTx(_destinationAddressForBTC, receivedAmount);
    }

    /// @dev spParaSwapToken2BTC - FLOW 2 -> swap ERC20 -> wBTC
    /// @param _destinationAddressForBTC The BTC address to send BTC to.
    /// @param _data simpleData from paraswap API call, param for simpleSwap
    function spFlow2SimpleSwap(
        bytes32 _destinationAddressForBTC,
        Utils.SimpleData calldata _data
    ) external nonReentrant {
        //bytes32 destBytes32 = _stringToBytes32(destinationAddressForBTC);
        //console.log("Converted to bytes32 and back to String:",_bytes32ToString(destBytes32));

        require(_data.fromToken != BTCT_ADDR);
        require(_data.toToken == BTCT_ADDR, "Must swap to BTC token");
        require(
            _data.beneficiary == address(this),
            "You can only execute flow 2 swaps to this contract's address"
        );
        require(
            tokens[_data.fromToken][msg.sender] >= _data.fromAmount,
            "Balance is not sufficient"
        );

        uint256 preSwapBalance = IERC20(_data.toToken).balanceOf(address(this));

        tokens[_data.fromToken][msg.sender] = tokens[_data.fromToken][
            msg.sender
        ].sub(_data.fromAmount);

        _doSimpleSwap(_data);

        uint256 receivedAmount = IERC20(_data.toToken)
            .balanceOf(address(this))
            .sub(preSwapBalance);

        require(
            receivedAmount >= _data.expectedAmount,
            "Received amount insufficient"
        );
        require(receivedAmount != 0, "Received amount can not be 0");

        tokens[_data.toToken][address(this)] = tokens[_data.toToken][
            address(this)
        ].add(receivedAmount);

        _spRecordPendingTx(_destinationAddressForBTC, receivedAmount);
    }

    /// @dev _doUniswapFork - performs paraswap transaction - BALANCE & TOKEN CHECKS MUST OCCUR BEFORE CALLING THIS
    /// @param _factory - param for swapOnUniswapFork
    /// @param _initCode - param for swapOnUniswapFork
    /// @param _amountIn - param for swapOnUniswapFork
    /// @param _amountOutMin - param for swapOnUniswapFork
    /// @param _path - param for swapOnUniswapFork
    function _doUniswapFork(
        address _factory,
        bytes32 _initCode,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path
    ) internal {
        address fromToken = _path[0];

        address proxy = IAugustusSwapper(paraswapAddress)
            .getTokenTransferProxy();

        IERC20(fromToken).safeIncreaseAllowance(proxy, _amountIn);

        IParaswap(paraswapAddress).swapOnUniswapFork(
            _factory,
            _initCode,
            _amountIn,
            _amountOutMin,
            _path
        );
    }

    /// @dev _doUniswap - performs paraswap transaction - BALANCE & TOKEN CHECKS MUST OCCUR BEFORE CALLING THIS
    /// @param _amountIn - param for swapOnUniswap
    /// @param _amountOutMin - param for swapOnUniswap
    /// @param _path - param for swapOnUniswap
    function _doUniswap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path
    ) internal {
        address fromToken = _path[0];

        address proxy = IAugustusSwapper(paraswapAddress)
            .getTokenTransferProxy();

        IERC20(fromToken).safeIncreaseAllowance(proxy, _amountIn);

        IParaswap(paraswapAddress).swapOnUniswap(
            _amountIn,
            _amountOutMin,
            _path
        );
    }

    /// @dev _doSimpleSwap - performs paraswap transaction - BALANCE & TOKEN CHECKS MUST OCCUR BEFORE CALLING THIS
    /// @param _data data from API call that is ready to be sent to paraswap interface
    function _doSimpleSwap(Utils.SimpleData calldata _data) internal {
        address proxy = IAugustusSwapper(paraswapAddress)
            .getTokenTransferProxy();

        IERC20(_data.fromToken).safeIncreaseAllowance(proxy, _data.fromAmount);

        IParaswap(paraswapAddress).simpleSwap(_data);
    }

    /// @dev _spRecordPendingTx - hash a unique swap ID, and add it to the array of pending TXs, and then emit event
    /// @param _destinationAddressForBTC The BTC address to send BTC to.
    /// @param _btctAmount amount in BTC decimal 8.
    function _spRecordPendingTx(
        //string memory _destinationAddressForBTC,
        bytes32 _destinationAddressForBTC,
        uint256 _btctAmount
    ) internal {
        //hash TX data for unique ID
        bytes32 ID = keccak256(
            abi.encodePacked(
                BTCT_ADDR, //specific to current chain
                swapCount,
                _destinationAddressForBTC,
                _btctAmount,
                block.timestamp
            )
        );

        spPendingTXs[swapCount] = spPendingTx(
            ID,
            _destinationAddressForBTC,
            msg.sender,
            _btctAmount,
            block.timestamp
        );

        //clean up expired TXs
        _spCleanUpOldTXs();

        swapCount = swapCount.add(1); //increment TX count after cleaning up pending TXs to not loop over next empty index

        emit SwapTokensToBTC(
            ID,
            _destinationAddressForBTC,
            msg.sender,
            _btctAmount,
            block.timestamp
        );
    }

    /// @dev setExpirationTime - allow node to adjust expiration time
    /// @param _expirationTime new expiration time
    function _setExpirationTime(uint256 _expirationTime) internal {
        expirationTime = _expirationTime;
        emit SetExpirationTime(_expirationTime, block.timestamp);
    }

    /// @dev spGetPendingSwaps - returns array of pending swap data and oldest pending swap
    /// @return data - returns array of pending swap struct objects
    function spGetPendingSwaps()
        external
        view
        returns (spPendingTx[] memory data)
    {
        uint256 index = 0;
        data = new spPendingTx[](swapCount.sub(latestRemovedIndex));
        for (uint256 i = latestRemovedIndex.add(1); i <= swapCount; i++) {
            data[index] = spPendingTXs[index.add(latestRemovedIndex)];
            index = index.add(1);
        }
    }

    /// @dev _spCleanUpOldTXs - call when executing flow 2 swaps, cleans up expired TXs and moves the indices
    function _spCleanUpOldTXs() internal {
        uint256 current = block.timestamp;
        for (uint256 i = latestRemovedIndex; i <= swapCount; i++) {
            if (spPendingTXs[i].Timestamp.add(expirationTime) < current) {
                tokens[BTCT_ADDR][address(this)] = tokens[BTCT_ADDR][
                    address(this)
                ].sub(spPendingTXs[i].AmountWBTC);
                delete spPendingTXs[i];
                latestRemovedIndex = i;
            }
        }
    }

    /// @dev spCleanUpOldTXs - call when executing flow 2 swaps, cleans up expired TXs and moves the indices
    /// @param _loopCount - max times the loop will run
    function spCleanUpOldTXs(uint256 _loopCount) external {
        uint256 max = latestRemovedIndex.add(_loopCount);

        if (max >= swapCount) {
            max = swapCount;
        }

        uint256 current = block.timestamp;
        for (uint256 i = latestRemovedIndex; i <= max; i++) {
            if (spPendingTXs[i].Timestamp.add(expirationTime) < current) {
                tokens[BTCT_ADDR][address(this)] = tokens[BTCT_ADDR][
                    address(this)
                ].sub(spPendingTXs[i].AmountWBTC);
                delete spPendingTXs[i];
                latestRemovedIndex = i;
            }
        }
    }

    /// @dev spDeposit - ERC-20 ONLY - users deposit ERC-20 tokens, balances to be stored in tokens[][]
    /// @param _token The address of the ERC-20 token contract.
    /// @param _amount amount to be deposited.
    function spDeposit(address _token, uint256 _amount)
        external
        payable
        nonReentrant
    {
        if (msg.value == 0) {
            require(_token != ETHER);
            require(_token != BTCT_ADDR);

            uint256 initBalance = IERC20(_token).balanceOf(address(this));

            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

            uint256 endingBalance = IERC20(_token).balanceOf(address(this));

            uint256 received = endingBalance.sub(initBalance);

            tokens[_token][msg.sender] = tokens[_token][msg.sender].add(
                received
            );

            emit Deposit(
                _token,
                msg.sender,
                received,
                tokens[_token][msg.sender],
                block.timestamp
            );
        } else {
            require(msg.value > 0);
            //swap to wETH tokens - contract now holds wETH instead of ether
            IWETH(wETH).deposit{value: msg.value}();

            tokens[wETH][msg.sender] = tokens[wETH][msg.sender].add(msg.value);

            emit Deposit(
                ETHER,
                msg.sender,
                msg.value,
                tokens[wETH][msg.sender],
                block.timestamp
            );
        }
    }

    /// @dev redeemEther for skypools - swap wETH for ether and send to user's wallet
    /// @param _amount amount to withdraw
    function redeemEther(uint256 _amount) external nonReentrant {
        require(tokens[wETH][msg.sender] >= _amount);
        IWETH(wETH).withdraw(_amount);
        tokens[wETH][msg.sender] = tokens[wETH][msg.sender].sub(_amount);
        address payable sender = payable(msg.sender);
        //sender.transfer(_amount);

        (bool sent, bytes memory data) = sender.call{value: _amount}("");

        require(sent, "Failed to send Ether");
        emit Withdraw(
            ETHER,
            msg.sender,
            _amount,
            tokens[wETH][msg.sender],
            block.timestamp
        );
    }

    receive() external payable {
        assert(msg.sender == wETH); // only accept ETH via fallback from the WETH contract
    }

    /// @dev redeemERC20Token for skypools - redeem erc20 token
    /// @param _token The address of target token.
    /// @param _amount The amount to withdraw - call with BTC decimals (8) for BTC
    function redeemERC20Token(address _token, uint256 _amount)
        external
        nonReentrant
    {
        require(tokens[_token][msg.sender] >= _amount, "Insufficient Balance");
        tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
        _safeTransfer(_token, msg.sender, _amount);

        emit Withdraw(
            _token,
            msg.sender,
            _amount,
            tokens[_token][msg.sender],
            block.timestamp
        );
    }

    /**
     * Life cycle part
     */

    /// @dev recordUTXOSweepMinerFee reduces float amount by collected miner fees.
    /// @param _minerFee The miner fees of BTC transaction.
    /// @param _txid The txid which is for recording.
    function recordUTXOSweepMinerFee(uint256 _minerFee, bytes32 _txid)
        public
        override
        onlyOwner
        returns (bool)
    {
        require(!isTxUsed(_txid), "The txid is already used");
        floatAmountOf[address(0)] = floatAmountOf[address(0)].sub(
            _minerFee,
            "BTC float amount insufficient"
        );
        _addUsedTx(_txid);
        return true;
    }

    /// @dev churn transfers contract ownership and set variables of the next TSS validator set.
    /// @param _newOwner The address of new Owner.
    /// @param _rewardAddressAndAmounts The reward addresses and amounts.
    /// @param _isRemoved The flags to remove node.
    /// @param _churnedInCount The number of next party size of TSS group.
    /// @param _tssThreshold The number of next threshold.
    /// @param _nodeRewardsRatio The number of rewards ratio for node owners
    /// @param _withdrawalFeeBPS The amount of wthdrawal fees.
    function churn(
        address _newOwner,
        bytes32[] memory _rewardAddressAndAmounts,
        bool[] memory _isRemoved,
        uint8 _churnedInCount,
        uint8 _tssThreshold,
        uint8 _nodeRewardsRatio,
        uint8 _withdrawalFeeBPS,
        uint256 _expirationTime //set to 0 to keep existing expiration time
    ) external override onlyOwner returns (bool) {
        require(
            _tssThreshold >= tssThreshold && _tssThreshold <= 2**8 - 1,
            "_tssThreshold should be >= tssThreshold"
        );
        require(
            _churnedInCount >= _tssThreshold + uint8(1),
            "n should be >= t+1"
        );
        require(
            _nodeRewardsRatio >= 0 && _nodeRewardsRatio <= 100,
            "_nodeRewardsRatio is not valid"
        );
        require(
            _withdrawalFeeBPS >= 0 && _withdrawalFeeBPS <= 100,
            "_withdrawalFeeBPS is invalid"
        );
        require(
            _rewardAddressAndAmounts.length == _isRemoved.length,
            "_rewardAddressAndAmounts and _isRemoved length is not match"
        );
        if (_expirationTime != 0) {
            _setExpirationTime(_expirationTime);
        }
        transferOwnership(_newOwner);
        // Update active node list
        for (uint256 i = 0; i < _rewardAddressAndAmounts.length; i++) {
            (address newNode, ) = _splitToValues(_rewardAddressAndAmounts[i]);
            _addNode(newNode, _rewardAddressAndAmounts[i], _isRemoved[i]);
        }
        bytes32[] memory nodeList = getActiveNodes();
        if (nodeList.length > 100) {
            revert("Stored node size should be <= 100");
        }
        churnedInCount = _churnedInCount;
        tssThreshold = _tssThreshold;
        nodeRewardsRatio = _nodeRewardsRatio;
        withdrawalFeeBPS = _withdrawalFeeBPS;
        return true;
    }

    /// @dev isTxUsed sends rewards for Nodes.
    /// @param _txid The txid which is for recording.
    function isTxUsed(bytes32 _txid) public view override returns (bool) {
        return used[_txid];
    }

    /// @dev getCurrentPriceLP returns the current exchange rate of LP token.
    function getCurrentPriceLP()
        public
        view
        override
        returns (uint256 nowPrice)
    {
        (uint256 reserveA, uint256 reserveB) = getFloatReserve(
            address(0),
            BTCT_ADDR
        );
        uint256 totalLPs = IBurnableToken(lpToken).totalSupply();
        // decimals of totalReserved == 8, lpDecimals == 8, decimals of rate == 8
        nowPrice = totalLPs == 0
            ? initialExchangeRate
            : (reserveA.add(reserveB)).mul(lpDecimals).div(
                totalLPs.add(lockedLPTokensForNode)
            );
        return nowPrice;
    }

    /// @dev getDepositFeeRate returns deposit fees rate
    /// @param _token The address of target token.
    /// @param _amountOfFloat The amount of float.
    function getDepositFeeRate(address _token, uint256 _amountOfFloat)
        public
        view
        override
        returns (uint256 depositFeeRate)
    {
        uint8 isFlip = _checkFlips(_token, _amountOfFloat);
        if (isFlip == 1) {
            depositFeeRate = _token == BTCT_ADDR ? depositFeesBPS : 0;
        } else if (isFlip == 2) {
            depositFeeRate = _token == address(0) ? depositFeesBPS : 0;
        }
    }

    /// @dev getFloatReserve returns float reserves
    /// @param _tokenA The address of target tokenA.
    /// @param _tokenB The address of target tokenB.
    function getFloatReserve(address _tokenA, address _tokenB)
        public
        view
        override
        returns (uint256 reserveA, uint256 reserveB)
    {
        (reserveA, reserveB) = (floatAmountOf[_tokenA], floatAmountOf[_tokenB]);
    }

    /// @dev getActiveNodes returns active nodes list (stakes and amount)
    function getActiveNodes() public view override returns (bytes32[] memory) {
        uint256 nodeCount = 0;
        uint256 count = 0;
        // Seek all nodes
        for (uint256 i = 0; i < nodeAddrs.length; i++) {
            if (nodes[nodeAddrs[i]] != 0x0) {
                nodeCount = nodeCount.add(1);
            }
        }
        bytes32[] memory _nodes = new bytes32[](nodeCount);
        for (uint256 i = 0; i < nodeAddrs.length; i++) {
            if (nodes[nodeAddrs[i]] != 0x0) {
                _nodes[count] = nodes[nodeAddrs[i]];
                count = count.add(1);
            }
        }
        return _nodes;
    }

    /// @dev _issueLPTokensForFloat
    /// @param _token The address of target token.
    /// @param _transaction The recevier address and amount.
    /// @param _zerofee The flag to accept zero fees.
    /// @param _txid The txid which is for recording.
    function _issueLPTokensForFloat(
        address _token,
        bytes32 _transaction,
        bool _zerofee,
        bytes32 _txid
    ) internal returns (bool) {
        require(!isTxUsed(_txid), "The txid is already used");
        require(_transaction != 0x0, "The transaction is not valid");
        // Define target address which is recorded on the tx data (20 bytes)
        // Define amountOfFloat which is recorded top on tx data (12 bytes)
        (address to, uint256 amountOfFloat) = _splitToValues(_transaction);
        // Calculate the amount of LP token
        uint256 nowPrice = getCurrentPriceLP();
        uint256 amountOfLP = amountOfFloat.mul(lpDecimals).div(nowPrice);
        uint256 depositFeeRate = getDepositFeeRate(_token, amountOfFloat);
        uint256 depositFees = depositFeeRate != 0
            ? amountOfLP.mul(depositFeeRate).div(10000)
            : 0;

        if (_zerofee && depositFees != 0) {
            revert();
        }
        // Send LP tokens to LP
        IBurnableToken(lpToken).mint(to, amountOfLP.sub(depositFees));
        // Add deposit fees
        lockedLPTokensForNode = lockedLPTokensForNode.add(depositFees);
        // Add float amount
        _addFloat(_token, amountOfFloat);
        _addUsedTx(_txid);
        emit IssueLPTokensForFloat(
            to,
            amountOfFloat,
            amountOfLP,
            nowPrice,
            depositFees,
            _txid
        );
        return true;
    }

    /// @dev _burnLPTokensForFloat
    /// @param _token The address of target token.
    /// @param _transaction The address of sender and amount.
    /// @param _minerFee The miner fees of BTC transaction.
    /// @param _txid The txid which is for recording.
    function _burnLPTokensForFloat(
        address _token,
        bytes32 _transaction,
        uint256 _minerFee,
        bytes32 _txid
    ) internal returns (bool) {
        require(!isTxUsed(_txid), "The txid is already used");
        require(_transaction != 0x0, "The transaction is not valid");
        // Define target address which is recorded on the tx data (20bytes)
        // Define amountLP which is recorded top on tx data (12bytes)
        (address to, uint256 amountOfLP) = _splitToValues(_transaction);
        // Calculate the amount of LP token
        uint256 nowPrice = getCurrentPriceLP();
        // Calculate the amountOfFloat
        uint256 amountOfFloat = amountOfLP.mul(nowPrice).div(lpDecimals);
        uint256 withdrawalFees = amountOfFloat.mul(withdrawalFeeBPS).div(10000);
        require(
            amountOfFloat.sub(withdrawalFees) >= _minerFee,
            "Error: amountOfFloat.sub(withdrawalFees) < _minerFee"
        );
        uint256 withdrawal = amountOfFloat.sub(withdrawalFees).sub(_minerFee);
        (uint256 reserveA, uint256 reserveB) = getFloatReserve(
            address(0),
            BTCT_ADDR
        );
        if (_token == address(0)) {
            require(
                reserveA >= amountOfFloat.sub(withdrawalFees),
                "The float balance insufficient."
            );
        } else if (_token == BTCT_ADDR) {
            require(
                reserveB >= amountOfFloat.sub(withdrawalFees),
                "The float balance insufficient."
            );
        }
        // Collect fees before remove float
        _rewardsCollection(_token, withdrawalFees);
        // Remove float amount
        _removeFloat(_token, amountOfFloat);
        // Add txid for recording.
        _addUsedTx(_txid);
        // BTCT transfer if token address is BTCT_ADDR
        if (_token == BTCT_ADDR) {
            // _minerFee should be zero
            _safeTransfer(_token, to, withdrawal);
        }
        // Burn LP tokens
        require(IBurnableToken(lpToken).burn(amountOfLP));
        emit BurnLPTokensForFloat(
            to,
            amountOfLP,
            amountOfFloat,
            nowPrice,
            withdrawal,
            _txid
        );
        return true;
    }

    /// @dev _checkFlips checks whether the fees are activated.
    /// @param _token The address of target token.
    /// @param _amountOfFloat The amount of float.
    function _checkFlips(address _token, uint256 _amountOfFloat)
        internal
        view
        returns (uint8)
    {
        (uint256 reserveA, uint256 reserveB) = getFloatReserve(
            address(0),
            BTCT_ADDR
        );
        uint256 threshold = reserveA
            .add(reserveB)
            .add(_amountOfFloat)
            .mul(2)
            .div(3);
        if (_token == BTCT_ADDR && reserveB.add(_amountOfFloat) >= threshold) {
            return 1; // BTC float insufficient
        }
        if (_token == address(0) && reserveA.add(_amountOfFloat) >= threshold) {
            return 2; // BTCT float insufficient
        }
        return 0;
    }

    /// @dev _addFloat updates one side of the float.
    /// @param _token The address of target token.
    /// @param _amount The amount of float.
    function _addFloat(address _token, uint256 _amount) internal {
        floatAmountOf[_token] = floatAmountOf[_token].add(_amount);
    }

    /// @dev _removeFloat remove one side of the float - redone for skypools using tokens mapping
    /// @param _token The address of target token.
    /// @param _amount The amount of float.
    function _removeFloat(address _token, uint256 _amount) internal {
        floatAmountOf[_token] = floatAmountOf[_token].sub(
            _amount,
            "_removeFloat: float amount insufficient"
        );
    }

    /// @dev _swap collects swap amount to change float.
    /// @param _sourceToken The address of source token
    /// @param _destToken The address of target token.
    /// @param _swapAmount The amount of swap.
    function _swap(
        address _sourceToken,
        address _destToken,
        uint256 _swapAmount
    ) internal {
        floatAmountOf[_destToken] = floatAmountOf[_destToken].sub(
            _swapAmount,
            "_swap: float amount insufficient"
        );
        floatAmountOf[_sourceToken] = floatAmountOf[_sourceToken].add(
            _swapAmount
        );

        emit Swap(_sourceToken, _destToken, _swapAmount);
    }

    /// @dev _safeTransfer executes tranfer erc20 tokens
    /// @param _token The address of target token
    /// @param _to The address of receiver.
    /// @param _amount The amount of transfer.
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_token == BTCT_ADDR) {
            _amount = _amount.mul(convertScale);
        }
        require(IERC20(_token).transfer(_to, _amount));
    }

    /// @dev _rewardsCollection collects tx rewards.
    /// @param _feesToken The token address for collection fees.
    /// @param _rewardsAmount The amount of rewards.
    function _rewardsCollection(address _feesToken, uint256 _rewardsAmount)
        internal
    {
        if (_rewardsAmount == 0) return;
        if (_feesToken == lpToken) {
            feesLPTokensForNode = feesLPTokensForNode.add(_rewardsAmount);
            emit RewardsCollection(_feesToken, _rewardsAmount, 0, 0);
            return;
        }
        // Get current LP token price.
        uint256 nowPrice = getCurrentPriceLP();
        // Add all fees into pool
        floatAmountOf[_feesToken] = floatAmountOf[_feesToken].add(
            _rewardsAmount
        );
        uint256 amountForNodes = _rewardsAmount.mul(nodeRewardsRatio).div(100);
        // Alloc LP tokens for nodes as fees
        uint256 amountLPTokensForNode = amountForNodes.mul(lpDecimals).div(
            nowPrice
        );
        // Add minted LP tokens for Nodes
        lockedLPTokensForNode = lockedLPTokensForNode.add(
            amountLPTokensForNode
        );
        emit RewardsCollection(
            _feesToken,
            _rewardsAmount,
            amountLPTokensForNode,
            nowPrice
        );
    }

    /// @dev _addUsedTx updates txid list which is spent. (single hash)
    /// @param _txid The array of txid.
    function _addUsedTx(bytes32 _txid) internal {
        used[_txid] = true;
    }

    /// @dev _addUsedTxs updates txid list which is spent. (multiple hashes)
    /// @param _txids The array of txid.
    function _addUsedTxs(bytes32[] memory _txids) internal {
        for (uint256 i = 0; i < _txids.length; i++) {
            used[_txids[i]] = true;
        }
    }

    /// @dev _addNode updates a staker's info.
    /// @param _addr The address of staker.
    /// @param _data The data of staker.
    /// @param _remove The flag to remove node.
    function _addNode(
        address _addr,
        bytes32 _data,
        bool _remove
    ) internal returns (bool) {
        if (_remove) {
            delete nodes[_addr];
            return true;
        }
        if (!isInList[_addr]) {
            nodeAddrs.push(_addr);
            isInList[_addr] = true;
        }
        nodes[_addr] = _data;
        return true;
    }

    /// @dev _splitToValues returns address and amount of staked SWINGBYs
    /// @param _data The info of a staker.
    function _splitToValues(bytes32 _data)
        internal
        pure
        returns (address, uint256)
    {
        return (
            address(uint160(uint256(_data))),
            uint256(uint96(bytes12(_data)))
        );
    }

    /// @dev The contract doesn't allow receiving Ether.
    fallback() external {
        revert();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <=0.8.9;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

interface IAugustusSwapper {

    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param referrer referral id
   * @param useReduxToken whether to use redux token or not
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        Path[] path;

    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        MegaSwapPath[] path;
    }

    struct BuyData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        BuyRoute[] route;
    }

    struct Route {
        address payable exchange;
        address targetExchange;
        uint percent;
        bytes payload;
        uint256 networkFee;//Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;//Network fee is associated with 0xv3 trades
        Route[] routes;
    }

    struct BuyRoute {
        address payable exchange;
        address targetExchange;
        uint256 fromAmount;
        uint256 toAmount;
        bytes payload;
        uint256 networkFee;//Network fee is associated with 0xv3 trades
    }

    function getPartnerRegistry() external view returns(address);

    function getWhitelistAddress() external view returns(address);

    function getFeeWallet() external view returns(address);

    function getTokenTransferProxy() external view returns (address);

    function getUniswapProxy() external view returns(address);

    function getVersion() external view returns(string memory);

    /**
   * @dev The function which performs the multi path swap.
   */
    function multiSwap(
        SellData calldata data
    )
        external
        payable
        returns (uint256);

    /**
   * @dev The function which performs the single path buy.
   */
    function buy(
        BuyData calldata data
    )
        external
        payable
        returns (uint256);

    function swapOnUniswap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint8 referrer
    )
        external
        payable;

    function buyOnUniswap(
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path,
        uint8 referrer
    )
        external
        payable;

    function buyOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path,
        uint8 referrer
    )
        external
        payable;

    function swapOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint8 referrer
    )
        external
        payable;


    function simplBuy(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address[] memory callees,
        bytes memory exchangeData,
        uint256[] memory startIndexes,
        uint256[] memory values,
        address payable beneficiary,
        string memory referrer,
        bool useReduxToken
    )
        external
        payable;

    function simpleSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 expectedAmount,
        address[] memory callees,
        bytes memory exchangeData,
        uint256[] memory startIndexes,
        uint256[] memory values,
        address payable beneficiary,
        string memory referrer,
        bool useReduxToken
    )
        external
        payable
        returns (uint256 receivedAmount);

    /**
   * @dev The function which performs the mega path swap.
   * @param data Data required to perform swap.
   */
    function megaSwap(
        MegaSwapSellData memory data
    )
        external
        payable
        returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.6.0 <=0.8.9;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.6.0 <=0.8.9;


interface ITokenTransferProxy {

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        external;

    function freeReduxTokens(address user, uint256 tokensToFree) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <=0.8.9;
pragma experimental ABIEncoderV2;

import "./lib/Utils.sol";

interface ISwapContract {

    function singleTransferERC20(
        address _destToken,
        address _to,
        uint256 _amount,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _redeemedFloatTxIds
    ) external returns (bool);

    function multiTransferERC20TightlyPacked(
        address _destToken,
        bytes32[] memory _addressesAndAmounts,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _redeemedFloatTxIds
    ) external returns (bool);

    function collectSwapFeesForBTC(
        address _destToken,
        uint256 _incomingAmount,
        uint256 _minerFee,
        uint256 _rewardsAmount
    ) external returns (bool);

    function recordIncomingFloat(
        address _token,
        bytes32 _addressesAndAmountOfFloat,
        bool _zerofee,
        bytes32 _txid
    ) external returns (bool);

    function recordOutcomingFloat(
        address _token,
        bytes32 _addressesAndAmountOfLPtoken,
        uint256 _minerFee,
        bytes32 _txid
    ) external returns (bool);

    function distributeNodeRewards() external returns (bool);

    function recordSkyPoolsTX(
        address _to,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _usedTxIds
    ) external returns (bool);

    function spFlow1SimpleSwap(Utils.SimpleData calldata _data) external;

    function spFlow1Uniswap(
        bool _fork,
        address _factory,
        bytes32 _initCode,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path
    ) external;

    function spFlow2Uniswap(
        bytes32 _destinationAddressForBTC,
        bool _fork,
        address _factory,
        bytes32 _initCode,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] calldata _path
    ) external;

    function spFlow2SimpleSwap(
        bytes32 _destinationAddressForBTC,
        Utils.SimpleData calldata _data
    ) external;

    function spCleanUpOldTXs(uint256 _loopCount) external;

    function spDeposit(address _token, uint256 _amount) external payable;

    function redeemEther(uint256 _amount) external;

    function redeemERC20Token(address _token, uint256 _amount) external;

    function recordUTXOSweepMinerFee(uint256 _minerFee, bytes32 _txid)
        external
        returns (bool);

    function churn(
        address _newOwner,
        bytes32[] memory _rewardAddressAndAmounts,
        bool[] memory _isRemoved,
        uint8 _churnedInCount,
        uint8 _tssThreshold,
        uint8 _nodeRewardsRatio,
        uint8 _withdrawalFeeBPS,
        uint256 _expirationTime
    ) external returns (bool);

    function isTxUsed(bytes32 _txid) external view returns (bool);

    function getCurrentPriceLP() external view returns (uint256);

    function getDepositFeeRate(address _token, uint256 _amountOfFloat)
        external
        view
        returns (uint256);

    function getFloatReserve(address _tokenA, address _tokenB)
        external
        returns (uint256 reserveA, uint256 reserveB);

    function getActiveNodes() external returns (bytes32[] memory);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.6.0 <=0.8.9;
pragma experimental ABIEncoderV2;

import "./lib/Utils.sol";
import "./IERC20.sol";
interface IParaswap {
    function multiSwap(
        Utils.SellData calldata data
    )
        external
        payable
        returns (uint256);

    function megaSwap(
        Utils.MegaSwapSellData calldata data
    )
        external
        payable
        returns (uint256);

    function protectedMultiSwap(
        Utils.SellData calldata data
    )
        external
        payable
        returns (uint256);

    function protectedMegaSwap(
        Utils.MegaSwapSellData calldata data
    )
        external
        payable
        returns (uint256);

    function protectedSimpleSwap(
        Utils.SimpleData calldata data
    )
        external
        payable
        returns (uint256 receivedAmount);

    function protectedSimpleBuy(
        Utils.SimpleData calldata data
    )
        external
        payable;

    function simpleSwap(
        Utils.SimpleData calldata data
    )
        external
        payable
        returns (uint256 receivedAmount);

    function simpleBuy(
        Utils.SimpleData calldata data
    )
        external
        payable;

    function swapOnUniswap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        payable;

    function swapOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        payable;

    function buyOnUniswap(
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    )
        external
        payable;

    function buyOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    )
        external
        payable;

    function swapOnUniswapV2Fork(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address weth,
        uint256[] calldata pools
    )
        external
        payable;

    function buyOnUniswapV2Fork(
        address tokenIn,
        uint256 amountInMax,
        uint256 amountOut,
        address weth,
        uint256[] calldata pools
    )
        external
        payable;

    function swapOnZeroXv2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes calldata payload
    )
    external
    payable;

    function swapOnZeroXv4(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes calldata payload
    )
    external
    payable;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <=0.8.9;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner. (This is a BEP-20 token specific.)
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <=0.8.9;

import "./IERC20.sol";

interface IBurnableToken is IERC20 {
    function mint(address target, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);

    function mintable() external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.6.0 <=0.8.9;

import "../IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.6.0 <=0.8.9;

library Utils {
    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee;
        Route[] route;
    }

    struct Route {
        uint256 index;//Adapter at which index needs to be used
        address targetExchange;
        uint percent;
        bytes payload;
        uint256 networkFee;//Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;//Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <=0.8.9;

import "./BurnableToken.sol";

contract LPToken is BurnableToken {
    constructor(uint8 _decimals) {
        _initialize("Swingby BTC LP Token", "sbBTC", _decimals, 0, true);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <=0.8.9;

import "./interfaces/IBurnableToken.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BurnableToken is Context, Ownable, IBurnableToken {
    using SafeMath for uint256;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 private tokenTotalSupply;
    string private tokenName;
    string private tokenSymbol;
    uint8 private tokenDecimals;
    bool private isMintable;

    /**
     * @dev sets initials supply and the owner
     */
    function _initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _amount,
        bool _mintable
    ) internal {
        tokenName = _name;
        tokenSymbol = _symbol;
        tokenDecimals = _decimals;
        isMintable = _mintable;
        _mint(owner(), _amount);
    }

    /**
     * @dev Returns if the token is mintable or not
     */
    function mintable() public override view returns (bool) {
        return isMintable;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return tokenDecimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return tokenSymbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return tokenName;
    }

    /**
     * @dev Returns the bep token owner. (This is a BEP-20 token specific.)
     */

    function getOwner() public override view returns (address) {
        return owner();
    }

    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return tokenTotalSupply;
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev See {ERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {ERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        override
        view
        returns (uint256)
    {
        return allowances[owner][spender];
    }

    /**
     * @dev See {ERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {ERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     * - `_mintable` must be true
     */
    function mint(address target, uint256 amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        require(isMintable, "This token is not mintable");
        _mint(target, amount);
        return true;
    }

    /**
     * @dev Burn `amount` tokens and decreasing the total supply.
     */
    function burn(uint256 amount) public override returns (bool) {
        _burn(_msgSender(), amount);
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balances[sender] = balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        tokenTotalSupply = tokenTotalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        balances[account] = balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        tokenTotalSupply = tokenTotalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            allowances[account][_msgSender()].sub(
                amount,
                "ERC20: burn amount exceeds allowance"
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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
library SafeMath {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}